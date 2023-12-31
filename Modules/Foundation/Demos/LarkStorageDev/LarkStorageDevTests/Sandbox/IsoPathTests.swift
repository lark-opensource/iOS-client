//
//  IsoPathTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

/// 测试 `IsoPath` 也即 `Path<IsolateSandbox>` 接口
class IsoPathTests: XCTestCase {

    // TODO: 待补充

    func testAppendingRelativePath() {
        func assertAppending(path: IsoPath, append: String, result: String, file: StaticString = #filePath, line: UInt = #line) {
            let p = path.appendingRelativePath(append)
            let message = "base: \(p.base), path: \(p.absoluteString), expected: \(result)"
            XCTAssert(p.absoluteString == result, message, file: file, line: line)
        }

        let checkItems = [
            (root: "/", relative: "", append: "a", result: "/a"),
            (root: "/", relative: "/", append: "a", result: "/a"),
            (root: "/a", relative: "b", append: "c", result: "/a/b/c"),
            (root: "/a", relative: "/b/", append: "c", result: "/a/b/c"),
        ]

        checkItems
            .flatMap { (root, relative, append, result) in
                [(make(root: root, relative: relative), append, result)]
            }
            .forEach { (path, append, result) in
                assertAppending(path: path, append: append, result: result)
            }
    }

    func testDeletingLastPathComponent() {
        func assertDeleting(path: IsoPath, result: String, file: StaticString = #filePath, line: UInt = #line) {
            let p = path.deletingLastPathComponent
            let message = "base: \(p.base), path: \(p.absoluteString), expected: \(result)"
            XCTAssert(p.absoluteString == result, message, file: file, line: line)
        }

        let checkItems = [
            (root: "/", relative: "a/b.file", result: "/a"),
            (root: "/", relative: "a/b/", result: "/a"),
            (root: "/", relative: "a", result: "/"),
            (root: "/", relative: "/a", result: "/"),

            (root: "/a/b", relative: "/c", result: "/a/b"),
            (root: "/a/b", relative: "/", result: "/a/b"),
            (root: "/a/b", relative: "", result: "/a/b"),
        ]

        checkItems
            .flatMap { (root, relative, result) in
                [(make(root: root, relative: relative), result)]
            }
            .forEach{ (path, result) in
                assertDeleting(path:path, result:result)
            }
    }

    private func make(root: String, relative: String) -> IsoPath {
        let sandbox = SandboxBase<IsolateSandboxPath>()
        let base = IsolateSandboxPath(
            rootPart: AbsPath(root),
            relativePart: relative,
            type: .standard,
            config: .init(space: .global, domain: Domain("12"), rootType: .normal(.library))
        )
        return .init(base: base, sandbox: sandbox)
    }

}
