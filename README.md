# SSFolderWatcher

SSFolderWatcher is a lightweight Swift package designed for macOS that facilitates monitoring file changes in a specified directory. Built on the FSEvents API, FolderWatcher is well-suited for scenarios with a large number of files, thanks to its efficient approach.

## Features

- **FSEvents API**: Utilizes the FSEvents API for efficient and real-time monitoring of file system changes.
- **Lightweight Algorithm**: Employs a lightweight algorithm, avoiding the need to scan the entire directory on every event, making it suitable for directories with a very large number of files.
- **Event Types**: Creation, deletion, modification and renaming.
- **Deterministic Event Detection**: Provides a deterministic algorithm to detect real event types, especially when multiple FSEvents are grouped together.
- **Root Directory Monitoring**: Watches files in the root directory, ignoring changes in subdirectories.
- **Hidden File Exclusion**: Ignores hidden files, providing a cleaner and more focused monitoring experience.
- **File Extension Filtering**: Allows filtering of watched files based on specified file extensions.

## Usage

```swift
import FolderWatcher

// Create a FolderWatcher instance
let folderWatcher = FolderWatcher { events in
    // Handle file change events
    for event in events {
        print("File \(event.fileName) changed. Type: \(event.type)")
    }
}

// Start watching a specified directory
let directoryURL = URL(fileURLWithPath: "/path/to/watched/directory")
try? folderWatcher.startWatching(url: directoryURL)

// ...

// Stop watching
folderWatcher.stopWatching()

Installation

To integrate FolderWatcher into your Xcode project, add it as a Swift Package dependency using the URL of this repository.

License

FolderWatcher is available under the MIT license. See the LICENSE file for more details.
