//
//  IsoPathTests.swift
//  LarkCacheDevEEUnitTest
//
//  Created by 7Up on 2022/11/24.
//

import Foundation
import XCTest
@testable import LarkCache
import LarkStorage

final class IsoPathTests: XCTestCase {

    // 测试 `String#relativePath(to:)` 接口
    func testRelativePaths() {
        XCTAssert("/a/b/c".relativePath(to: "/a/b") == "c")
        XCTAssert("/a/b/c/d".relativePath(to: "/a/b") == "c/d")
    }

    /// 测试 String -> IsoPath
    func testIsoPath() {
        let isoPath = IsoPath.global.in(domain: Domain.biz.core.child("IsoPathTests")).build(.cache)
        let newCache = CacheManager.shared.cache(rootPath: isoPath, cleanIdentifier: "IsoPathTests")
        do {
            let p = isoPath + "a/b"
            let t = newCache.isoPath(fromRawPath: p.absoluteString)
            XCTAssert(t?.absoluteString == p.absoluteString)
        }
        do {
            let p = isoPath + "/"
            let t = newCache.isoPath(fromRawPath: p.absoluteString)
            XCTAssert(t?.absoluteString == p.absoluteString)
        }
        do {
            let p = isoPath + ""
            let t = newCache.isoPath(fromRawPath: p.absoluteString)
            XCTAssert(t?.absoluteString == p.absoluteString)
        }
    }

}
