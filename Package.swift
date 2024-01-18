// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "SSFolderWatcher",
    products: [
        .library(
            name: "SSFolderWatcher",
            targets: ["SSFolderWatcher"]),
    ],
    targets: [
        .target(
            name: "SSFolderWatcher",
            path: "Sources"),
        .testTarget(
            name: "SSFolderWatcherTests",
            dependencies: ["SSFolderWatcher"],
            path: "Tests"),
    ]
)
