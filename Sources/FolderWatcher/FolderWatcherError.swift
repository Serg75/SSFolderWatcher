//
//  FolderWatcherError.swift
//  SSFolderWatcher
//
//  Created by Sergey Slobodenyuk on 2024-01-09.
//

import Foundation

public enum FolderWatcherError: Error {
    case watchingUrlNotExist
    case watchingUrlIsNotFolder
    case streamCreateFailed
    case streamStartFailed
}
