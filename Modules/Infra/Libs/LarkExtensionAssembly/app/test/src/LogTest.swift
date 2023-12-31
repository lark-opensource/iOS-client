//
//  LogTest.swift
//  LarkExtensionAssemblyDevEEUnitTest
//
//  Created by 王元洵 on 2021/4/2.
//

import Foundation
import XCTest
@testable import LarkExtensionAssembly
@testable import LarkExtensionServices

class CleanLogTests: XCTestCase {
    private let src: URL = {
        var tempDir = NSTemporaryDirectory()
        tempDir.removeLast()
        return URL(fileURLWithPath: tempDir).appendingPathComponent("testLogSrc")
    }()
    private let dst: URL = {
        var tempDir = NSTemporaryDirectory()
        tempDir.removeLast()
        return URL(fileURLWithPath: tempDir).appendingPathComponent("testLogDst")
    }()

    override func tearDown() {
        do {
            try FileManager.default.removeItem(at: src)
            try FileManager.default.removeItem(at: dst)
        } catch {
            assertionFailure("should not happen in tearing down")
        }

        super.tearDown()
    }

    override func setUp() {
        super.setUp()

        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: src.path) {
            do {
                try fileManager.createDirectory(at: src, withIntermediateDirectories: true)
            } catch {
                assert(true)
            }
        }
        if !fileManager.fileExists(atPath: dst.path) {
            do {
                try fileManager.createDirectory(at: dst, withIntermediateDirectories: true)
            } catch {
                assert(true)
            }
        }
    }

    func testMoveAndClean() {
        ExtensionLogCleaner.extensionlogURL = src
        ExtensionLogCleaner.mainAppLogURL = dst
        for i in 1...10 {
            let fileName = src.appendingPathComponent(i.description)
            FileManager.default.createFile(atPath: fileName.path, contents: "testLog".data(using: .utf8))
        }

        ExtensionLogCleaner.moveAndClean()

        do {
            var paths = try FileManager.default.contentsOfDirectory(atPath: src.path)
            XCTAssertEqual(paths.count, 1)
            XCTAssertEqual(paths.first, "9")
            paths = try FileManager.default.contentsOfDirectory(atPath: dst.path)
            XCTAssertEqual(paths.count, 5)
            XCTAssertEqual(paths[0], "9")
            XCTAssertEqual(paths[1], "7")
            XCTAssertEqual(paths[2], "6")
            XCTAssertEqual(paths[3], "8")
            XCTAssertEqual(paths[4], "5")
        } catch {
            XCTAssert(true)
        }
    }

    func testMoveAndCleanWithServices() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let logger = FileLogHandler()
        logger.maxBufferSize = 0
        logger.logDirPath = src.path
        logger.log(eventMessage: "log")

        let expectation = XCTestExpectation(description: "test")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else {
                XCTAssert(true)
                return
            }

            do {
                ExtensionLogCleaner.moveAndClean()
                var paths = try FileManager.default.contentsOfDirectory(atPath: self.src.path)
                XCTAssertEqual(paths.count, 1)
                XCTAssertEqual(paths.first, "\(dateFormatter.string(from: Date()))")
                paths = try FileManager.default.contentsOfDirectory(atPath: self.dst.path)
                XCTAssertEqual(paths.count, 1)
                XCTAssertEqual(paths.first, "\(dateFormatter.string(from: Date()))")
                expectation.fulfill()
            } catch {
                XCTAssert(true)
            }
        }
        wait(for: [expectation], timeout: 2)
    }
}
