//
//  PathTypeTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/12/30.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

final class PathTypeTests: XCTestCase {

    func testRawComponents() {
        // starts with "/"
        XCTAssert(["/", "a", "b", "c"] == AbsPath("a/b/c").rawComponents())
        XCTAssert(["/", "a", "b", "c"] == AbsPath("a/b/c/").rawComponents())
        XCTAssert(["/", "a", "b", "c"] == AbsPath("a//b//c/").rawComponents())
        XCTAssert(["/", "a", "b", "c"] == AbsPath("a//b//c//").rawComponents())

        XCTAssert(["/", "a", "b", "c"] == AbsPath("/a/b/c").rawComponents())
        XCTAssert(["/", "a", "b", "c"] == AbsPath("/a/b/c/").rawComponents())
        XCTAssert(["/", "a", "b", "c"] == AbsPath("//a//b//c//").rawComponents())

        XCTAssert(["/", "a", "b", "c"] == AbsPath("/a/./b//c//").rawComponents())
        XCTAssert(["/", "b", "c"] == AbsPath("/a/../b//c//").rawComponents())
    }

    func testRelativeComponents() {
        do {
            let base = AbsPath("/a/b/c")
            let test = AbsPath("/a/b/c")
            XCTAssert(test.relativeComponents(to: base) == [])
        }
        do {
            let base = AbsPath("/a/b/c")
            let test = AbsPath("/a/b/c/d/e")
            XCTAssert(test.relativeComponents(to: base) == ["d", "e"])
        }
    }

    func testRelativePath() {
        do {
            let base = AbsPath("/a/b/c")
            let test = AbsPath("/a/b/c")
            XCTAssert(test.relativePath(to: base) == "")
        }
        do {
            let base = AbsPath("/a/b/c")
            let test = AbsPath("/a/b/c/")
            XCTAssert(test.relativePath(to: base) == "")
        }
        do {
            let base = AbsPath("/a/b/c")
            let test = AbsPath("/a/b/c/d")
            XCTAssert(test.relativePath(to: base) == "d")
        }
        do {
            let base = AbsPath("/a/b/c")
            let test = AbsPath("/a/b/c/d/e")
            XCTAssert(test.relativePath(to: base) == "d/e")
        }
    }

}
