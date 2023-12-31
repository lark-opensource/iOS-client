//
//  IsoPath+MapTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/12/28.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

final class IsoPathMapTests: XCTestCase {

    func _testMapOk(root: IsoPath) throws {
        do {
            let mapped = try root.map { $0 }
            XCTAssert(mapped.base.config.key == root.base.config.key)
            XCTAssert(mapped.absoluteString == root.absoluteString)
        }
        do {
            let mapped = try root.map { $0 + "/" }
            XCTAssert(mapped.base.config.key == root.base.config.key)
            XCTAssert(mapped.absoluteString == root.absoluteString)
        }
        do {
            let mapped = try root.map { $0 + "/A" }
            XCTAssert(mapped.base.config.key == root.base.config.key)
            XCTAssert(mapped.absoluteString == (root + "A").absoluteString)
        }
        do {
            let mapped = try root.map { $0 + "/A/B" }
            XCTAssert(mapped.base.config.key == root.base.config.key)
            XCTAssert(mapped.absoluteString == (root + "A/B").absoluteString)
        }

        let origin = root + "A/B/C"
        do {
            let mapped = try origin.map { $0 + "/a/b" }
            XCTAssert(mapped.base.config.key == root.base.config.key)
        }
        do {
            let mapped = try origin.map { old in
                var new = old
                new.removeLast(2)
                return new
            }
            XCTAssert(mapped.base.config.key == root.base.config.key)
        }
        do {
            let mapped = try origin.map { old in
                var new = old
                new.removeLast(6)
                return new
            }
            XCTAssert(mapped.base.config.key == root.base.config.key)
        }
    }

    func testMapOk() throws {
        let userSpace = Space.user(id: String(UUID().uuidString.prefix(10)))
        let domain = Domain("IsoPathMapTests").child(String(UUID().uuidString.prefix(5)))
        let typedUser = IsoPath.in(space: userSpace, domain: domain)
        let typedGlboal = IsoPath.in(space: .global, domain: domain)

        try _testMapOk(root: typedUser.build(.document))
        try _testMapOk(root: typedUser.build(.library))
        try _testMapOk(root: typedUser.build(.cache))
        try _testMapOk(root: typedUser.build(.temporary))

        try _testMapOk(root: typedGlboal.build(.document))
        try _testMapOk(root: typedGlboal.build(.library))
        try _testMapOk(root: typedGlboal.build(.cache))
        try _testMapOk(root: typedGlboal.build(.temporary))
    }

    func _testMapErr(root: IsoPath) throws {
        do {
            _ = try root.map { $0 + "suffix" }
            XCTFail("unexpected")
        } catch { }
        // TODO: 待补充更多 case
    }

    func testMapErr() throws {
        let userSpace = Space.user(id: String(UUID().uuidString.prefix(10)))
        let domain = Domain("IsoPathMapTests").child(String(UUID().uuidString.prefix(5)))
        let typedUser = IsoPath.in(space: userSpace, domain: domain)
        let typedGlboal = IsoPath.in(space: .global, domain: domain)

        try _testMapErr(root: typedUser.build(.document))
        try _testMapErr(root: typedUser.build(.library))
        try _testMapErr(root: typedUser.build(.cache))
        try _testMapErr(root: typedUser.build(.temporary))

        try _testMapErr(root: typedGlboal.build(.document))
        try _testMapErr(root: typedGlboal.build(.library))
        try _testMapErr(root: typedGlboal.build(.cache))
        try _testMapErr(root: typedGlboal.build(.temporary))
    }

}
