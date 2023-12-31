//
//  PathAttributeTests.swift
//  LarkFileKitDevEEUnitTest
//
//  Created by Supeng on 2020/10/10.
//

import Foundation
import XCTest
@testable import LarkFileKit

class PathAttributeTestsTests: XCTestCase {
    var dir: Path!
    var file: Path!

    override func setUp() {
        super.setUp()
        dir = .userTemporary + "TestDir"
        file = dir + "test.txt"
    }

    override func tearDown() {
        try? dir.deleteFile()
        try? file.deleteFile()
        super.tearDown()
    }

    func testAbsolute() {
        let path1: Path = "/temp"
        let path2: Path = "temp"
        XCTAssertTrue(path1.isAbsolute)
        XCTAssertFalse(path2.isAbsolute)

        XCTAssertEqual(path1, path1.absolute)
        XCTAssertNotEqual(path2, Path.current + path2.absolute)
    }

    func testStandardlize() {
        let path: Path = "~"
        XCTAssertEqual(path.standardized.rawValue, (path.rawValue as NSString).standardizingPath)
    }

    func testCreationDate() throws {
        XCTAssertNil(dir.creationDate)
        try dir.createDirectory()
        XCTAssertNotNil(dir.creationDate)

        let date = Date()
        let interval = dir.creationDate!.timeIntervalSince(date)
        XCTAssertTrue(abs(interval) < 1)
    }

    func testModificationDate() throws {
        XCTAssertNil(dir.modificationDate)
        try dir.createDirectory()
        XCTAssertNotNil(dir.modificationDate)

        let date = Date()
        let interval = dir.modificationDate!.timeIntervalSince(date)
        XCTAssertTrue(abs(interval) < 1)
    }

    func testDirectory() throws {
        XCTAssertFalse(dir.isDirectory)
        XCTAssertFalse(dir.isDirectoryFile)
        try dir.createDirectory()
        XCTAssertTrue(dir.isDirectory)
        XCTAssertTrue(dir.isDirectoryFile)
    }

    func testIsAny() throws {
        XCTAssertFalse(dir.isAny)
        try dir.createDirectory()
        XCTAssertTrue(dir.isAny)
    }

    func testFileSize() throws {
        try? file.deleteFile()
        XCTAssertNil(file.fileSize)

        let textFile = TextFile(path: file)
        let text = "123456789"
        try dir.createDirectory()
        try textFile.write(text)
        XCTAssertNotNil(file.fileSize)
        XCTAssertEqual(file.fileSize!, UInt64(text.count))

        let dir1 = dir + "folder1"
        try dir1.createDirectory()

        let file1 = dir1 + "testfile1"

        let textFile1 = TextFile(path: file1)
        try textFile1.write(text)

        let nonExistsPath = dir1 + "nonExistsPath"
        XCTAssertEqual(nonExistsPath.recursizeFileSize, 0)
        XCTAssertEqual(file.fileSize ?? 0, file.recursizeFileSize)
        XCTAssertEqual(dir.recursizeFileSize, dir.fileSize! + file.fileSize! + dir1.fileSize! + file1.fileSize!)
    }

    func testUrl() throws {
        try dir.createDirectory()
        XCTAssertEqual(dir.url.absoluteString, "file://" + dir.safeRawValue + Path.separator)
        XCTAssertEqual(file.url.absoluteString, "file://" + file.safeRawValue)
    }

    func testAttribute() throws {
        try dir.createDirectory()
        var date = Date()
        date.addTimeInterval(-1_000)
        try dir.setAttribute(.creationDate, value: date)

        let createDate = dir.attributes[FileAttributeKey.creationDate] as? Date
        XCTAssertEqual(createDate!, date)

        try dir.deleteFile()
        XCTAssertThrowsError(try dir.setAttribute(.creationDate, value: date))
    }
}
