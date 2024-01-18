//
//  FolderWatcher.swift
//  SSFolderWatcher
//
//  Created by Sergey Slobodenyuk on 2024-01-06.
//

import Foundation
import CoreServices

public class FolderWatcher {
    
    public typealias FolderWatcherCallback = ([FolderWatcherEvent]) -> Void
    public typealias FolderWatcherCheckExtension = (String) -> Bool

    private let notificationLatency: CFTimeInterval = 1.0   // latency in seconds
    private let eventStreamFlags: FSEventStreamCreateFlags = FSEventStreamCreateFlags(
        kFSEventStreamCreateFlagFileEvents)    // we need file-level notifications

    private var eventStream: FSEventStreamRef?
    private var eventsQueue: DispatchQueue
    
    private static var eventsQueueNum = 0   // we can run multiple Folder Watchers

    private var folderURL: URL!
    private var callback: FolderWatcherCallback
    private var checkExtension: FolderWatcherCheckExtension?
    private var supportedExtensions: [String: Bool] = [:]
    private var files: [String: UInt] = [:]

    public init(callback: @escaping FolderWatcherCallback,
                checkExtension: FolderWatcherCheckExtension? = nil) {
        
        self.eventsQueue = DispatchQueue(label: FolderWatcher.eventQueueName(),
                                         attributes: [])
        self.callback = callback
        self.checkExtension = checkExtension
    }

    deinit {
        stopWatching()
    }

    public func startWatching(url: URL) throws {
        
        var isDir: ObjCBool = false
        
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else {
            throw FolderWatcherError.watchingUrlNotExist
        }

        guard isDir.boolValue else {
            throw FolderWatcherError.watchingUrlIsNotFolder
        }

        self.folderURL = url
        self.files = watchingFiles()

        disposeEventStream()
        eventStream = createEventStream()
        guard eventStream != nil else {
            throw FolderWatcherError.streamCreateFailed
        }

        FSEventStreamSetDispatchQueue(eventStream!, eventsQueue)

        if !FSEventStreamStart(eventStream!) {
            throw FolderWatcherError.streamStartFailed
        }
    }

    public func stopWatching() {
        disposeEventStream()
    }

    public var isWatching: Bool {
        return eventStream != nil
    }
    
    
    //MARK: - FSEvents callback function

    
    private let innerCallback: FSEventStreamCallback = { (
        streamRef: ConstFSEventStreamRef,
        clientCallBackInfo: UnsafeMutableRawPointer?,
        numEvents: Int,
        eventPaths: UnsafeMutableRawPointer,
        eventFlags: UnsafePointer<FSEventStreamEventFlags>,
        eventIds: UnsafePointer<FSEventStreamEventId>) in
        
        guard let contextInfo = clientCallBackInfo else {
            // TODO: throw error
            print("Folder Watcher: missing pointer to the clientCallBackInfo")
            return
        }

        let `self` = Unmanaged<FolderWatcher>.fromOpaque(contextInfo).takeUnretainedValue()
        
        var outEvents: [FolderWatcherEvent] = []
        var pathsByID: [UInt: [String]] = [:]
        var errors: [UInt: [String]] = [:]
        var singles: [UInt: String] = [:]

        let paths = eventPaths.bindMemory(to: UnsafeMutablePointer<CChar>.self, capacity: numEvents)

        // debug
        print("FSEvent changes: \(numEvents)")

        // finding related events by file ID
        for i in 0..<numEvents {
            let path = String(cString: paths[i])
            let url = URL(fileURLWithPath: path)
            let name = url.lastPathComponent

            guard (eventFlags[i] & FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsFile)) != 0 else {
                // we are listening only files
                continue
            }

            // TODO: check deep nesting
            guard url.deletingLastPathComponent().path == self.folderURL.path else {
                // we ignore nested folders
                continue
            }

            guard self.isSupportedFile(path) else {
                // skip unsupported files
                continue
            }

            // if the file existed previously, get its ID from the saved list
            var fileID = self.files[name]
            if fileID == nil {
                // file didn't exist - getting its ID from a real file
                fileID = self.fileID(forFile: path)
            }

            // group files by IDs
            if pathsByID[fileID!] == nil {
                pathsByID[fileID!] = [path]
            } else {
                pathsByID[fileID!]!.append(path)
            }
        }

        // now we have all files grouped by file ID
        for (fileID, paths) in pathsByID {

            // we are interested in unique names
            let uniquePaths = Array(Set(paths))
            
            if uniquePaths.count == 1 {
                // only one name with this file ID
                singles[fileID] = uniquePaths.first!
                continue
            }

            if uniquePaths.count > 2 {
                // found more than 2 different names for this file ID
                errors[fileID] = uniquePaths
                continue
            }

            if fileID == 0 {
                // file ID is unknown
                errors[fileID] = uniquePaths
                continue
            }

            // here we have paths.count == 2
            // file renaming detection...
            
            let basePath = self.basePathIfTemporaryRenamed(path1: uniquePaths.first!,
                                                           path2: uniquePaths.last!)
            if basePath != nil {
                singles[fileID] = basePath
                continue
            }

            if let event = self.detectRenameEvent(firstPath: uniquePaths.first!,
                                                  secondPath: uniquePaths.last!) {
                // file renaming detected
                outEvents.append(event)
            }
        }

        // sometimes the file ID is changed during renaming when the file is opened in the editor.
        // so we ignore file IDs
        if singles.count == 2 {
            let values = Array(singles.values)
            let basePath = self.basePathIfTemporaryRenamed(path1: values.first!,
                                                           path2: values.last!)
            
            if basePath != nil {
                
                // we found temporary renaming - get rid of temp name
                singles = singles.filter { $0.value == basePath }
                
            } else {
                
                if let event = self.detectRenameEvent(firstPath: values.first!,
                                                      secondPath: values.last!) {
                    // file renaming detected
                    outEvents.append(event)
                    singles.removeAll()
                }
            }
        }

        // detect other types of event
        for (fileID, path) in singles {
            let name = URL(fileURLWithPath: path).lastPathComponent
            let fileExists = FileManager.default.fileExists(atPath: path)
            let fileDidExist = self.files[name] != nil

            if !fileDidExist && fileExists {

                // file creation detected
                let event = FolderWatcherEvent(type: .created, fileID: fileID, fileName: name)
                outEvents.append(event)

            } else if fileDidExist && !fileExists {

                // file deletion detected
                let event = FolderWatcherEvent(type: .deleted, fileID: fileID, fileName: name)
                outEvents.append(event)

            } else if fileDidExist && fileExists {

                // file change detected
                let event = FolderWatcherEvent(type: .changed, fileID: fileID, fileName: name)
                outEvents.append(event)

            } else {

                // found a ghost - the file didn't exist before, it doesn't exist now.
                // it should be a temporary file created by a file editor

            }
        }

        if !errors.isEmpty {
            // TODO: inform caller about errors
            print("Errors found in FCEvents!")
            for (fileID, paths) in errors {
                print("- File ID \(fileID): \(paths.count) in files:")
                for path in paths {
                    print("  - \(path)")
                }
            }
        }

        // commit changes to files here
        for event in outEvents {
            self.commitEvent(event, fileID: event.fileID)
        }

        // debug
        print("Detected \(outEvents.count) events:")
        for event in outEvents {
            print("- \(event.description)")
        }

        if !outEvents.isEmpty {
            self.callback(outEvents)
        }
    }


    //MARK: - private API


    private class func eventQueueName() -> String {
        return "com.folderWatcher.eventsQueue\(FolderWatcher.eventsQueueNum += 1)"
    }

    private func createEventStream() -> FSEventStreamRef? {

        let info = Unmanaged.passUnretained(self).toOpaque()
        
        var context = FSEventStreamContext(version: 0,
                                           info: info,
                                           retain: nil,
                                           release: nil,
                                           copyDescription: nil)

        let pathsToWatch = [folderURL.path] as CFArray
        // we ignore historical events
        let lastEventId = FSEventStreamEventId(kFSEventStreamEventIdSinceNow)
        
        return FSEventStreamCreate(nil,
                                   innerCallback,
                                   &context,
                                   pathsToWatch,
                                   lastEventId,
                                   notificationLatency,
                                   eventStreamFlags)
    }

    private func disposeEventStream() {
        if let eventStream = eventStream {
            FSEventStreamStop(eventStream)
            FSEventStreamInvalidate(eventStream)
            FSEventStreamRelease(eventStream)
            self.eventStream = nil
        }
    }

    private func detectRenameEvent(firstPath: String, secondPath: String) -> FolderWatcherEvent? {
        let firstName = URL(fileURLWithPath: firstPath).lastPathComponent
        let secondName = URL(fileURLWithPath: secondPath).lastPathComponent

        // check if we have file renaming instead of changing two files at the same time
        let fileManager = FileManager.default
        let firstExists = fileManager.fileExists(atPath: firstPath)
        let secondExists = fileManager.fileExists(atPath: secondPath)
        let firstDidExist = files[firstName] != nil
        let secondDidExist = files[secondName] != nil

        guard firstExists != secondExists && 
                firstExists != firstDidExist &&
                secondExists != secondDidExist else {
            return nil
        }

        if basePathIfTemporaryRenamed(path1: firstPath, path2: secondPath) != nil {
            return nil
        }

        return FolderWatcherEvent(type: .renamed,
                                  fileID: 0,
                                  fileName: firstExists ? secondName : firstName,
                                  fileNewName: firstExists ? firstName : secondName)
    }

    private func basePathIfTemporaryRenamed(path1: String, path2: String) -> String? {
        
        let (longPath, shortPath) = 
            path1.count > path2.count ? (path1, path2) : (path2, path1)

        if longPath.hasPrefix(shortPath) {
            let tail = longPath.suffix(from: shortPath.endIndex)
            if tail.count > 10 && tail.hasPrefix(".sb-") {
                if FileManager.default.fileExists(atPath: shortPath) {
                    return shortPath
                }
            }
        }
        return nil
    }

    private func commitEvent(_ event: FolderWatcherEvent, fileID: UInt) {
        switch event.type {
        case .created:
            files[event.fileName] = fileID
        case .deleted:
            files[event.fileName] = nil
        case .renamed:
            files[event.fileNewName!] = files[event.fileName]
            files[event.fileName] = nil
        default:
            break
        }
    }

    private func watchingFiles() -> [String: UInt] {

        do {
            let subpaths = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
            var files: [String: UInt] = [:]

            for name in subpaths {
                let path = folderURL.appendingPathComponent(name).path
                var isDir: ObjCBool = false

                if !FileManager.default.fileExists(atPath: path, isDirectory: &isDir) || isDir.boolValue {
                    continue
                }

                let supported = isSupportedFile(path)
                if supported {
                    let id = fileID(forFile: path)
                    files[name] = id
                }
            }

            return files
        } catch {
            return [:]
        }
    }

    private func fileID(forFile filePath: String) -> UInt {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
            return attributes[.systemFileNumber] as? UInt ?? 0
        } catch {
            return 0
        }
    }

    private func isSupportedFile(_ filePath: String) -> Bool {
        let fileURL = URL(fileURLWithPath: filePath)
        let fileName = fileURL.lastPathComponent

        guard !fileName.hasPrefix(".") else {
            return false
        }

        let fileExtension = fileURL.pathExtension
        if let isSupported = supportedExtensions[fileExtension] {
            return isSupported
        }

        let isExtensionSupported = checkExtension?(fileExtension) ?? true

        supportedExtensions[fileExtension] = isExtensionSupported
        
        return isExtensionSupported
    }
}
