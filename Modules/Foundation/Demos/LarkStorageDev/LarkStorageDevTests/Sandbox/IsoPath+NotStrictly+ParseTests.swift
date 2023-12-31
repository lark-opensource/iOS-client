//
//  IsoPath+NotStrictly+ParseTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2023/2/3.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

// 测试 IsoPath.notStrctly.parse 接口
final class IsoPathNotStrictlyParseTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        _IsoPathParserRegistry.registerBuiltInPathParser()
    }

    func testParseCache() throws {
        func _innerTest(_ absPath: AbsPath) throws {
            let isoPath = try IsoPath.notStrictly.parse(fromCache: absPath)
            XCTAssert(isoPath.absoluteString == absPath.absoluteString)
        }
        try _innerTest(.cache)
        try _innerTest(.cache + "/")
        try _innerTest(.cache + "/a")
        try _innerTest(.cache + "/a/b")
        try _innerTest(.cache + "/a/b/c")
    }

    func testParseTemporary() throws {
        func _innerTest(_ absPath: AbsPath) throws {
            let isoPath = try IsoPath.notStrictly.parse(fromTemporary: absPath)
            XCTAssert(isoPath.absoluteString == absPath.absoluteString)
        }
        try _innerTest(.temporary)
        try _innerTest(.temporary + "/")
        try _innerTest(.temporary + "/a")
        try _innerTest(.temporary + "/a/b")
        try _innerTest(.temporary + "/a/b/c")
    }

    func testCache() throws {
        let cachePath = IsoPath.notStrictly.cache()
        XCTAssert(cachePath.absoluteString == AbsPath.cache.absoluteString)
        XCTAssert(cachePath.absoluteString == LfkPath.cachePath.rawValue)
    }

    func testTemporary() throws {
        let temporaryPath = IsoPath.notStrictly.temporary()
        XCTAssert(temporaryPath.absoluteString == AbsPath.temporary.absoluteString)
        XCTAssert(temporaryPath.absoluteString == LfkPath.userTemporary.rawValue)
    }

}
