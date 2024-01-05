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
}

public class FolderWatcherEvent: NSObject {
    let type: FolderWatcherEventTypes
    let fileName: String
    let fileNewName: String?
    var fileID: UInt = 0

    init(type: FolderWatcherEventTypes, fileName: String, fileNewName: String? = nil) {
        self.type = type
        self.fileName = fileName
        self.fileNewName = fileNewName
    }

    public override var description: String {
        let flagValue = description(for: type)
        if let fileNewName = fileNewName {
            return "\(flagValue): \(fileName) -> \(fileNewName)"
        } else {
            return "\(flagValue): \(fileName)"
        }
    }

    private func description(for type: FolderWatcherEventTypes) -> String {
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
