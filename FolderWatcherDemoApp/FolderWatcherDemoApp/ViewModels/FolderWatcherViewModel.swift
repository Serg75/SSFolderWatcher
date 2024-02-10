//
//  FolderWatcherViewModel.swift
//  FolderWatcherDemoApp
//
//  Created by Sergey Slobodenyuk on 2024-01-15.
//

import Foundation
import AppKit
import SSFolderWatcher

struct GroupedEvent: Hashable, Identifiable {
    let id = UUID()
    let event: FolderWatcherEvent
    let isOddGroup: Bool
}

class FolderWatcherViewModel: ObservableObject {
    @Published var watchingPath: String = ""
    @Published var isWatching: Bool = false
    @Published var events: [GroupedEvent] = []
    
    private var isOddGroup = false

    private var folderWatcher: FolderWatcher?

    func selectPath() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false

        openPanel.begin { response in
            if response == NSApplication.ModalResponse.OK,
               let selectedURL = openPanel.url {
                self.watchingPath = selectedURL.path
            }
        }
    }

    func toggleWatching() {
        if isWatching {
            stopWatching()
        } else {
            startWatching()
        }
    }

    func startWatching() {
        guard !watchingPath.isEmpty else { return }

        folderWatcher = FolderWatcher { [weak self] newEvents in
            DispatchQueue.main.async {
                self?.isOddGroup.toggle()
                self?.events.append(contentsOf: newEvents.map({ event in
                    GroupedEvent(event: event, isOddGroup: self?.isOddGroup ?? false)
                }))
            }
        }

        do {
            try folderWatcher?.startWatching(url: URL(fileURLWithPath: watchingPath))
            isWatching = true
        } catch {
            print("Error starting folder watcher: \(error.localizedDescription)")
        }
    }

    func stopWatching() {
        folderWatcher?.stopWatching()
        isWatching = false
    }

    func clearEvents() {
        events.removeAll()
    }
}
