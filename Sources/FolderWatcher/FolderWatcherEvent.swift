//
//  FolderWatcherEvent.swift
//  SSFolderWatcher
//
//  Created by Sergey Slobodenyuk on 2024-01-06.
//

import Foundation

public enum FolderWatcherEventTypes: Int {
    case created
    case deleted
    case changed
    case renamed
    
    public var description: String {
        switch self {
        case .changed:
            return "changed"
        case .created:
            return "created"
        case .deleted:
            return "deleted"
        case .renamed:
            return "renamed"
        }
    }
}

public struct FolderWatcherEvent {
    public let type: FolderWatcherEventTypes
    public let fileName: String
    public let fileNewName: String?
    public let fileID: UInt

    // TODO: make demo init
    public init(type: FolderWatcherEventTypes, fileID: UInt, fileName: String, fileNewName: String? = nil) {
        self.type = type
        self.fileID = fileID
        self.fileName = fileName
        self.fileNewName = fileNewName
    }

    public var description: String {
        let flagValue = description(for: type)
        if let fileNewName = fileNewName {
            return "\(flagValue): \(fileName) -> \(fileNewName)"
        } else {
            return "\(flagValue): \(fileName)"
        }
    }

    private func description(for type: FolderWatcherEventTypes) -> String {
        // TODO call enum
        switch type {
        case .changed:
            return "changed"
        case .created:
            return "created"
        case .deleted:
            return "deleted"
        case .renamed:
            return "renamed"
        }
    }
}

extension FolderWatcherEvent: Hashable {
    
}
