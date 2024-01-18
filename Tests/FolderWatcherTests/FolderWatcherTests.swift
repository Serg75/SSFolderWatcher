import XCTest
@testable import SSFolderWatcher

final class FolderWatcherTests: XCTestCase {
    
    // Helper function to provide a unique test folder URL
    func folderURL() -> URL {
        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask).first!
        let testFolderURL = documentsDirectory.appendingPathComponent("FolderWatcherTests")
        try? FileManager.default.createDirectory(at: testFolderURL,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
        return testFolderURL
    }
    
    override func tearDown() {
        super.tearDown()
        
        // Clean up test folder
        let testFolderURL = folderURL()
        try? FileManager.default.removeItem(at: testFolderURL)
    }

    func testInitialization() {
        let folderWatcher = FolderWatcher(callback: { _ in })
        XCTAssertNotNil(folderWatcher)
    }
    
    func testStartAndStopWatching() {
        let folderWatcher = FolderWatcher(callback: { _ in })
        
        do {
            try folderWatcher.startWatching(url: folderURL())
        } catch {
            XCTFail("Failed to start watching: \(error)")
        }
        XCTAssertTrue(folderWatcher.isWatching)
        
        folderWatcher.stopWatching()
        XCTAssertFalse(folderWatcher.isWatching)
    }
    
    func testEventDetectionCreation() {
        let expectation = XCTestExpectation(description: "Event detected")
        
        let folderWatcher = FolderWatcher { events in
            XCTAssertEqual(events.count, 1)
            XCTAssertEqual(events.first?.type, .created)
            XCTAssertEqual(events.first?.fileName, "testFile.txt")
            expectation.fulfill()
        }
        
        let testFolder = folderURL()
        
        XCTAssertNoThrow(try folderWatcher.startWatching(url: testFolder))
        
        // Simulate file creation event
        let filePath = testFolder.appendingPathComponent("testFile.txt").path
        FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
        
        wait(for: [expectation], timeout: 2.0)
        
        folderWatcher.stopWatching()
    }
    
    func testEventDetectionDeletion() {
        let expectation = XCTestExpectation(description: "Event detected")

        let folderWatcher = FolderWatcher { events in
            XCTAssertEqual(events.count, 1)
            XCTAssertEqual(events.first?.type, .deleted)
            XCTAssertEqual(events.first?.fileName, "testFile.txt")
            expectation.fulfill()
        }

        let testFolder = folderURL()

        let filePath = testFolder.appendingPathComponent("testFile.txt").path
        FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)

        XCTAssertNoThrow(try folderWatcher.startWatching(url: testFolder))

        // Simulate file deletion event
        try? FileManager.default.removeItem(atPath: filePath)

        wait(for: [expectation], timeout: 2.0)

        folderWatcher.stopWatching()
    }

    func testEventDetectionModification() {
        let expectation = XCTestExpectation(description: "Event detected")

        let folderWatcher = FolderWatcher { events in
            XCTAssertEqual(events.count, 1)
            XCTAssertEqual(events.first?.type, .changed)
            XCTAssertEqual(events.first?.fileName, "testFile.txt")
            expectation.fulfill()
        }

        let testFolder = folderURL()

        let filePath = testFolder.appendingPathComponent("testFile.txt").path
        FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)

        XCTAssertNoThrow(try folderWatcher.startWatching(url: testFolder))

        // Simulate file modification event
        FileManager.default.createFile(atPath: filePath, contents: "Updated content".data(using: .utf8), attributes: nil)

        wait(for: [expectation], timeout: 2.0)

        folderWatcher.stopWatching()
    }

    func testEventDetectionRenaming() {
        let expectation = XCTestExpectation(description: "Event detected")

        let folderWatcher = FolderWatcher { events in
            XCTAssertEqual(events.count, 1)
            XCTAssertEqual(events.first?.type, .renamed)
            XCTAssertEqual(events.first?.fileName, "testFile.txt")
            XCTAssertEqual(events.first?.fileNewName, "renamedFile.txt")
            expectation.fulfill()
        }

        let testFolder = folderURL()

        let originalFilePath = testFolder.appendingPathComponent("testFile.txt").path
        let newFilePath = testFolder.appendingPathComponent("renamedFile.txt").path
        FileManager.default.createFile(atPath: originalFilePath, contents: nil, attributes: nil)

        XCTAssertNoThrow(try folderWatcher.startWatching(url: testFolder))

        // Simulate file renaming event
        try? FileManager.default.moveItem(atPath: originalFilePath, toPath: newFilePath)

        wait(for: [expectation], timeout: 2.0)

        folderWatcher.stopWatching()
    }

}
