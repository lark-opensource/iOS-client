//
//  IsolateSandboxTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

class IsolateSandboxTests: XCTestCase {

    // MARK: Path Tests
    
    func testAbsoluteString() {
        
    }
    
    func testAppending() {
        
    }

}

class IsolateSandboxPathTests: XCTestCase {

    func testAppendingRelativePath() {
        func assertAppending(root: String, relative: String, append: String, result: String, file: StaticString = #filePath, line: UInt = #line) {
            let p = path(root, relative).appendingRelativePath(append)
            XCTAssert(p.absoluteString == result, "path: \(p.absoluteString), expected: \(result)", file: file, line: line)
        }

        assertAppending(root: "/", relative: "", append: "a", result: "/a")
        assertAppending(root: "/", relative: "/", append: "a", result: "/a")
        assertAppending(root: "/a", relative: "b", append: "c", result: "/a/b/c")
        assertAppending(root: "/a", relative: "/b/", append: "c", result: "/a/b/c")
    }

    func testDeletingLastComponent() {
        func assertDeleting(root: String, relative: String, result: String, file: StaticString = #filePath, line: UInt = #line) {
            let p = path(root, relative).deletingLastPathComponent
            XCTAssert(p.absoluteString == result, "path: \(p.absoluteString), expected: \(result)", file: file, line: line)
        }

        assertDeleting(root: "/", relative: "a/b.file", result: "/a")
        assertDeleting(root: "/", relative: "a/b/", result: "/a")
        assertDeleting(root: "/", relative: "a", result: "/")
        assertDeleting(root: "/", relative: "/a", result: "/")

        assertDeleting(root: "/a/b", relative: "/c", result: "/a/b")
        assertDeleting(root: "/a/b", relative: "/", result: "/a/b")
        assertDeleting(root: "/a/b", relative: "", result: "/a/b")
    }

    private func path(_ root: String, _ relative: String = "") -> IsolateSandboxPath {
        let config = IsolatePathConfig(space: .global, domain: Domain("1"), rootType: .normal(.library))
        return .init(rootPart: AbsPath(root), relativePart: relative, type: .standard, config: config)
    }

}
