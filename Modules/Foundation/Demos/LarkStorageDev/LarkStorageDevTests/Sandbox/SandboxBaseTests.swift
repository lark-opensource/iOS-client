//
//  SandboxBaseTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

// MARK: - Convenience

extension SandboxType {
    func fileExists(atPath path: RawPath) -> Bool {
        return fileExists(atPath: path, isDirectory: nil)
    }

    func createFile(
        atPath path: RawPath,
        contents: Data? = nil
    ) throws {
        try createFile(atPath: path, contents: contents, attributes: nil)
    }

    func createDirectory(
        atPath path: RawPath,
        withIntermediateDirectories createIntermediates: Bool = true
    ) throws {
        try createDirectory(
            atPath: path,
            withIntermediateDirectories: createIntermediates,
            attributes: nil
        )
    }
}

/// 测试 SandboxBase 接口
class SandboxBaseTests: XCTestCase {

    lazy var rootDir: AbsPath = {
        AbsPath.builtInPath(for: .library) + typeName
    }()
    var sandbox = SandboxBase<AbsPath>()

    override func setUpWithError() throws {
        try super.setUpWithError()
        if rootDir.exists {
            try sandbox.removeItem(atPath: rootDir)
        }
        try sandbox.createDirectory(atPath: rootDir)
    }

    func testFileExists() throws {
        let dir = rootDir + "testFileExists"
        XCTAssertFalse(sandbox.fileExists(atPath: dir))
        try prepareDir(with: [dir])
        var isDir = false
        XCTAssert(sandbox.fileExists(atPath: dir, isDirectory: &isDir) && isDir)

        let file = dir + "readme.md"
        XCTAssertFalse(sandbox.fileExists(atPath: file))
        try sandbox.createFile(atPath: file)
        XCTAssertTrue(sandbox.fileExists(atPath: file))
    }

    func testCreateFile() throws {
        let filePath = rootDir + "testCreateFile.txt"
        XCTAssert(!sandbox.fileExists(atPath: filePath))
        try sandbox.createFile(atPath: filePath)
        XCTAssert(sandbox.fileExists(atPath: filePath))

        // TODO: 还需要测试其他参数 contents, attributes
    }

    func testCreateDirectory() throws {
        let dir = rootDir + "testCreateDirectory"

        XCTAssert(!sandbox.fileExists(atPath: dir))
        try sandbox.createDirectory(atPath: dir)
        XCTAssert(sandbox.fileExists(atPath: dir))

        do {
            try sandbox.createDirectory(
                atPath: dir,
                withIntermediateDirectories: false
            )
            XCTFail("must throw exception")
        } catch {
            log.error("Create directory fail ok, err: \(error)")
        }

        do {
            try sandbox.createDirectory(
                atPath: dir,
                withIntermediateDirectories: true
            )
        } catch {
            XCTFail("must throw exception")
        }
    }

    func testRemoveItem() throws {
        let dirPath = rootDir + "testRemoveItem"
        let filePath = dirPath + "file.txt"
        let otherFilePath = dirPath + "other.txt"

        XCTAssertFalse(sandbox.fileExists(atPath: dirPath))
        XCTAssertFalse(sandbox.fileExists(atPath: filePath))

        try sandbox.createDirectory(atPath: dirPath)
        XCTAssertTrue(sandbox.fileExists(atPath: dirPath))
        try sandbox.createFile(atPath: filePath)
        XCTAssertTrue(sandbox.fileExists(atPath: filePath))
        try sandbox.createFile(atPath: otherFilePath)
        XCTAssertTrue(sandbox.fileExists(atPath: otherFilePath))

        // delete file at `filePath`
        try sandbox.removeItem(atPath: filePath)
        XCTAssertFalse(sandbox.fileExists(atPath: filePath))
        // delete dir at `dirPath`
        try sandbox.removeItem(atPath: dirPath)
        XCTAssertFalse(sandbox.fileExists(atPath: otherFilePath))
        XCTAssertFalse(sandbox.fileExists(atPath: dirPath))
    }

    func testMoveItem() throws {
        let fromDir = rootDir + "testMoveItem/from"
        let toDir = rootDir + "testMoveItem/to"
        let fileName = "file.txt"

        XCTAssertFalse(sandbox.fileExists(atPath: fromDir))
        XCTAssertFalse(sandbox.fileExists(atPath: toDir))
        try sandbox.createDirectory(atPath: fromDir)
        try sandbox.createDirectory(atPath: toDir)

        let fileFromPath = fromDir + fileName
        try sandbox.createFile(atPath: fileFromPath)
        XCTAssertTrue(sandbox.fileExists(atPath: fileFromPath))

        let expectedPath = toDir + fileName
        XCTAssertFalse(sandbox.fileExists(atPath: expectedPath))
        try sandbox.moveItem(atPath: fileFromPath, toPath: expectedPath)
        XCTAssertTrue(sandbox.fileExists(atPath: expectedPath))
        XCTAssertFalse(sandbox.fileExists(atPath: fileFromPath))
    }

    func testAttributes() {
        // TODO: 待补充
    }

    func testSubpaths() throws {
        try prepareDir(with: [
            rootDir + "a",
            rootDir + "b",
            rootDir + "c"
        ])
        try prepareDir(with: [
            rootDir + "a/a1/a2",
            rootDir + "b/b1/b2",
            rootDir + "c/c1/c2"
        ])
        let outputPaths = try sandbox.subpathsOfDirectory(atPath: rootDir)
        let expected: [String] = [
            "a",
            "a/a1",
            "a/a1/a2",
            "b",
            "b/b1",
            "b/b1/b2",
            "c",
            "c/c1",
            "c/c1/c2"
        ]
        let arr1 = expected.sorted()
        let arr2 = outputPaths.sorted()
        XCTAssertEqual(arr1, arr2)
    }

    func testContents() throws {
        try prepareDir(with: [
            rootDir + "a",
            rootDir + "b",
            rootDir + "c"
        ])
        // 加些干扰项
        try prepareDir(with: [
            rootDir + "a/a1/a2",
            rootDir + "b/b1/b2",
            rootDir + "c/c1/c2"
        ])
        let expected = ["a", "b", "c"]
        let outputPaths = try sandbox.contentsOfDirectory(atPath: rootDir)
        let arr1 = expected.sorted()
        let arr2 = outputPaths.sorted()
        XCTAssertEqual(arr1, arr2)
    }

    private func prepareDir(with paths: [AbsPath]) throws {
        for p in paths {
            try sandbox.createDirectory(atPath: p)
        }
    }

}
