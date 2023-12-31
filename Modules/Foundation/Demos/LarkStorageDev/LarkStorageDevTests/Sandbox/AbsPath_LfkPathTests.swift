//
//  AbsPath_LfkPathTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

/// 测试 AbsPath 和 LfkPath 的兼容性
class AbsPath_LfkPathTests: XCTestCase {

    lazy var rootDir: AbsPath = { AbsPath.builtInPath(for: .library) + typeName }()
    let sandbox = SandboxBase<AbsPath>()

    override func setUpWithError() throws {
        try super.setUpWithError()
        if rootDir.exists {
            try sandbox.removeItem(atPath: rootDir)
        }
        try sandbox.createDirectory(atPath: rootDir)
    }

    func testCommonPath() {
        let assertEqual = { (p1: AbsPath, p2: LfkPath) in
            XCTAssertEqual(p1.rawValue, p2.rawValue)
        }
        assertEqual(.document, .documentsPath)
        assertEqual(.cache, .cachePath)
        assertEqual(.temporary, .userTemporary)
    }

    func testExistsAndIsDirectory() throws {
        let assertExists = { (path: AbsPath, expected: Bool) in
            XCTAssertEqual(path.exists, expected)
            XCTAssertEqual(LfkPath(path.rawValue).exists, expected)
        }
        let assertDirectory = { (path: AbsPath, expected: Bool) in
            XCTAssertEqual(path.isDirectory, expected)
            XCTAssertEqual(LfkPath(path.rawValue).isDirectory, expected)
        }
        assertExists(rootDir, true)
        assertDirectory(rootDir, true)

        let filePath = rootDir + "testExistsAndIsDirectory.txt"
        assertExists(filePath, false)
        try sandbox.createFile(atPath: filePath)
        assertExists(filePath, true)
        assertDirectory(filePath, false)
    }

    func testFileSize() throws {
        let data = String(repeating: "hello", count: 1024).data(using: .utf8)

        let filePath = rootDir + "testFileSize.data"
        try sandbox.createFile(atPath: filePath, contents: data)

        let size1 = filePath.fileSize!
        let size2 = LfkPath(filePath.rawValue).fileSize!
        XCTAssert(size1 > 0 && size2 > 0)
        XCTAssert(size1 == size2)
        log.debug("testFileSize. size1: \(size1), size2: \(size2)")
    }

    func testRecursiveFileSize() throws {
        let data = String(repeating: "hello", count: 1024).data(using: .utf8)
        let testDir = rootDir + "testRecursiveFileSize"
        try sandbox.createDirectory(atPath: testDir)

        let dataDirs: [AbsPath] = [
            testDir + "a",
            testDir + "a/a1/",
            testDir + "a/a1/a2",
            testDir + "b",
            testDir + "b/b1/",
            testDir + "b/b1/b2",
        ]
        try dataDirs.forEach {
            try sandbox.createDirectory(atPath: $0)
        }
        try dataDirs.forEach { dir in
            try sandbox.createFile(atPath: dir + "file.data", contents: data)
        }
        let size1 = testDir.recursiveFileSize()
        let size2 = LfkPath(testDir.rawValue).recursizeFileSize
        XCTAssert(size1 > 0 && size2 > 0)
        XCTAssert(size1 == size2)
        log.debug("testRecursiveFileSize. size1: \(size1), size2: \(size2)")
    }

    func testChildren() throws {
        let testDir = rootDir + "testChildren"
        try [
            testDir + "a",
            testDir + "b",
            testDir + "c"
        ].forEach { try sandbox.createDirectory(atPath: $0) }
        try [
            testDir + "a/a1/a2",
            testDir + "b/b1/b2",
            testDir + "c/c1/c2"
        ].forEach { try sandbox.createDirectory(atPath: $0) }

        let arr1 = rootDir
            .children(recursive: true)
            .map(\.rawValue)
            .sorted()
        let arr2 = LfkPath(rootDir.rawValue)
            .children(recursive: true)
            .map(\.rawValue)
            .sorted()
        XCTAssertEqual(arr1, arr2)

        let arr3 = rootDir
            .children(recursive: false)
            .map(\.rawValue)
            .sorted()
        let arr4 = LfkPath(rootDir.rawValue)
            .children(recursive: false)
            .map(\.rawValue)
            .sorted()
        XCTAssertEqual(arr3, arr4)
    }

}
