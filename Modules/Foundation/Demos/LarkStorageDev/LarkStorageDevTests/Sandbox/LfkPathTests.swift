//
//  LfkPathTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

class LfkPathTests: XCTestCase {

    func testAbsoluteString() {
        let base: LfkPath = "/b/a/s/e"
        XCTAssertEqual(base.absoluteString, "/b/a/s/e")
    }

    func testAppendingRelativePath() {
        let base: LfkPath = "/b/a/s/e"
        XCTAssertEqual(base.appendingRelativePath("z").rawValue, "/b/a/s/e/z")
        XCTAssertEqual((base + "z").rawValue, "/b/a/s/e/z")
    }

    func testDeletingLastPathComponent() {
        XCTAssertEqual(LfkPath("/a/b").deletingLastPathComponent.rawValue, "/a")
        XCTAssertEqual(LfkPath("/a/b/").deletingLastPathComponent.rawValue, "/a")
        XCTAssertEqual(LfkPath("/a").deletingLastPathComponent.rawValue, "/")
        XCTAssertEqual(LfkPath("/a/").deletingLastPathComponent.rawValue, "/")
        XCTAssertEqual(LfkPath("/").deletingLastPathComponent.rawValue, "/")
        XCTAssertEqual(LfkPath("a").deletingLastPathComponent.rawValue, "")
        XCTAssertEqual(LfkPath("a/b").deletingLastPathComponent.rawValue, "a")
    }

}
