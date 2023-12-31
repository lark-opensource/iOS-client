//
//  PathOperationTests.swift
//  LarkFileKitDevEEUnitTest
//
//  Created by Supeng on 2020/10/13.
//

import Foundation
import XCTest
@testable import LarkFileKit

let handler = TestHandler()

class PathOperationTests: XCTestCase {

    var path: Path!

    class override func setUp() {
        super.setUp()
        FileTrackInfoHandlerRegistry.register(handler: handler)
    }

    class override func tearDown() {
        FileTrackInfoHandlerRegistry.handlers = []
        super.tearDown()
    }

    override func setUp() {
        super.setUp()
        path = Path.userTemporary + "PathOperationTests"
    }

    override func tearDown() {
        try? path.deleteFile()
        super.tearDown()
    }

    func testExists() throws {
        XCTAssertFalse(path.exists)
        try path.createFile()
        XCTAssertTrue(path.exists)
    }

    func testCreateFile() throws {
        XCTAssertNoThrow(try path.createFile())
        let tempPath: Path = ""
        XCTAssertThrowsError(try tempPath.createFile())

        try path.deleteFile()

        // 验证createFile(data:）可以正确传入data
        try path.createFile(data: "123".data(using: .utf8))
        let data: Data = try path.read()
        XCTAssertEqual(data, "123".data(using: .utf8))

        try path.deleteFile()
        try path.createFileIfNeeded(data: "123".data(using: .utf8))
        let data1: Data = try path.read()
        XCTAssertEqual(data1, "123".data(using: .utf8))

        // 验证如果文件已经存在，再调用createFileIfNeeded不起作用
        XCTAssertNoThrow(try path.createFileIfNeeded(data: "abc".data(using: .utf8)))
        XCTAssertEqual(data, "123".data(using: .utf8))
    }

    func testTouch() throws {
        XCTAssertFalse(path.exists)
        try path.touch()
        XCTAssertTrue(path.exists)

        let modificationDate = path.modificationDate
        XCTAssertNotNil(modificationDate)

        try path.touch(true)
        let newModificationDate = path.modificationDate
        XCTAssertNotNil(newModificationDate)

        XCTAssertTrue(newModificationDate!.compare(modificationDate!) == .orderedDescending)
    }

    func testCreateDirectory() throws {
        try path.createDirectory()
        XCTAssertTrue(path.isDirectory)

        let tempPath = path + "temp1" + "temp2"
        XCTAssertThrowsError(try tempPath.createDirectory(withIntermediateDirectories: false))

        //createDirectoryIfNeeded可以多次调用，只有第一次生效
        XCTAssertThrowsError(try tempPath.createDirectoryIfNeeded(withIntermediateDirectories: false))
        XCTAssertNoThrow(try tempPath.createDirectoryIfNeeded())
        XCTAssertNoThrow(try tempPath.createDirectoryIfNeeded())

        XCTAssertTrue(tempPath.exists)
    }

    func testMoveFile() throws {
        let destinationPath = Path.userTemporary + "destinationPath"

        // 源path没有文件的时候，报错
        XCTAssertThrowsError(try path.moveFile(to: destinationPath))

        // 目标path有文件的时候，报错
        try path.touch()
        try destinationPath.touch()
        XCTAssertThrowsError(try path.moveFile(to: destinationPath))

        // 正常move流程
        try destinationPath.deleteFile()

        XCTAssertTrue(path.exists)
        XCTAssertFalse(destinationPath.exists)

        try path.moveFile(to: destinationPath)

        XCTAssertFalse(path.exists)
        XCTAssertTrue(destinationPath.exists)

        // 目标path不合法的时候，报错
        try destinationPath.moveFile(to: path)
        let illegalDestinationPath: Path = "awfejawiofjawoiejfoawjfaowefjawoqef"

        XCTAssertThrowsError(try path.moveFile(to: illegalDestinationPath))
    }

    func testCopyFile() throws {
        let destinationPath = Path.userTemporary + "destinationPath"

        // 源path没有文件的时候，报错
        XCTAssertThrowsError(try path.copyFile(to: destinationPath))

        // 目标path有文件的时候，报错
        try path.touch()
        try destinationPath.touch()
        XCTAssertThrowsError(try path.copyFile(to: destinationPath))

        // 正常copy流程
        try destinationPath.deleteFile()

        XCTAssertTrue(path.exists)
        XCTAssertFalse(destinationPath.exists)

        try path.copyFile(to: destinationPath)

        XCTAssertTrue(path.exists)
        XCTAssertTrue(destinationPath.exists)

        try destinationPath.deleteFile()

        // 目标path不合法的时候，报错
        let illegalDestinationPath: Path = "awfejawiofjawoiejfoawjfaowefjawoqef"
        XCTAssertThrowsError(try path.copyFile(to: illegalDestinationPath))
    }

    func testForceMoveFile() throws {
        let destinationPath = Path.userTemporary + "destinationPath"
        try destinationPath.createFile()

        try path.createFile()

        XCTAssertNoThrow(try path.forceMoveFile(to: destinationPath))
    }

    func testForceCopyFile() throws {
        let destinationPath = Path.userTemporary + "destinationPath"
        try destinationPath.createFile()

        try path.createFile()

        XCTAssertNoThrow(try path.forceCopyFile(to: destinationPath))
    }

    func testArchiveAndUnArchive() {
        XCTAssertTrue(path.archieve(rootObject: ["123"]))

        XCTAssert(handler.trackInfos.last!.operation == .archive)
        XCTAssert(handler.trackInfos.last!.size == path.fileSize!)

        let result = path.unArchieve() as? [String]
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, ["123"])
    }
}
