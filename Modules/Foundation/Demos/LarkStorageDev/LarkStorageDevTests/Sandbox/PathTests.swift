//
//  PathTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

class PathTests: XCTestCase {

    private typealias TestSandbox = SandboxBase<AbsPath>
    private typealias TestPath = _Path<TestSandbox>

    private let sandbox = TestSandbox()
    private lazy var rootDir: TestPath = {
        let base = AbsPath.builtInPath(for: .library) + typeName
        return TestPath(base: base, sandbox: self.sandbox)
    }()

    override func setUpWithError() throws {
        try super.setUpWithError()
        if rootDir.exists {
            try rootDir.removeItem()
        }
        if !rootDir.exists {
            try rootDir.createDirectory()
        }
    }

    // MARK: Create/Remove, Path.exists, Path.isDirectory

    func testCreateRemove() throws {
        let testDir = rootDir + "testCreateRemove"

        // create testDir
        XCTAssert(!testDir.exists && !testDir.isDirectory)
        try testDir.createDirectory()
        XCTAssert(testDir.exists && testDir.isDirectory)

        // create/remove empty file
        do {
            let testFile = testDir + "empty.data"
            XCTAssert(!testFile.exists)
            try testFile.createFile()
            XCTAssert(testFile.exists && !testFile.isDirectory)

            // remove file
            try testFile.removeItem()
            XCTAssert(!testFile.exists)
        }

        // create/remove file with data
        do {
            let data = String(repeating: "hello", count: 1024).data(using: .utf8)
            let testFile = testDir + "hello.data"
            XCTAssert(!testFile.exists)
            try testFile.createFile(with: data)
            XCTAssert(testFile.exists && !testFile.isDirectory)

            // remove file
            try testFile.removeItem()
            XCTAssert(!testFile.exists)
        }

        // remove testDir
        try testDir.removeItem()
        XCTAssert(!testDir.exists && !testDir.isDirectory)
    }

    // MARK: File Size

    func testFileSize() throws {
        let data = String(repeating: "hello", count: 1024).data(using: .utf8)

        let filePath = rootDir + "file.data"
        try filePath.createFile(with: data)

        let size1 = filePath.fileSize!
        let size2 = LfkPath(filePath.absoluteString).fileSize!
        XCTAssert(size1 > 0 && size2 > 0)
        XCTAssert(size1 == size2)
    }

    func testRecursiveFileSize() throws {
        let data = String(repeating: "hello", count: 1024).data(using: .utf8)
        let testDir = rootDir + "testRecursiveFileSize"
        try testDir.createDirectory()

        let dataDirs: [TestPath] = [
            testDir + "a",
            testDir + "a/a1/",
            testDir + "a/a1/a2",
            testDir + "b",
            testDir + "b/b1/",
            testDir + "b/b1/b2",
        ]
        try dataDirs.forEach {
            try $0.createDirectory()
        }
        try dataDirs.forEach { dir in
            let filePath = dir + "file.data"
            try filePath.createFile(with: data)
        }
        let size1 = testDir.recursiveFileSize()
        let size2 = LfkPath(testDir.absoluteString).recursizeFileSize
        XCTAssert(size1 > 0 && size2 > 0)
        XCTAssert(size1 == size2)
    }

    func testEnumerate() throws {
        // prepare env
        let testDir = rootDir + "testEnumerate"
        try [
            testDir + "a",
            testDir + "b",
            testDir + "c"
        ].forEach { try $0.createDirectory() }
        try [
            testDir + "a/a1/a2",
            testDir + "b/b1/b2",
            testDir + "c/c1/c2"
        ].forEach { try $0.createDirectory() }

        // test enumerate comparing with `LfkPath`
        let assertEnumerate = { (path: TestPath, recursive: Bool) in
            let arr1 = path
                .children(recursive: recursive)
                .map(\.absoluteString)
                .sorted()
            let arr2 = LfkPath(path.absoluteString)
                .children(recursive: recursive)
                .map(\.absoluteString)
                .sorted()
            XCTAssertEqual(arr1, arr2)
        }
        assertEnumerate(rootDir, true)
        assertEnumerate(rootDir, false)
    }

}
