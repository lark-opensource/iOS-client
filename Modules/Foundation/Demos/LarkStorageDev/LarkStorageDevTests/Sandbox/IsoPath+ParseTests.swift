//
//  IsoPath+ParseTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/12/28.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

/// 测试 IsoPath.parse 相关接口w
final class IsoPathParseTests: XCTestCase {

    /// 测试 `Parser.rootType(for:)`
    func testParseRootType() {
        let homeStr = AbsPath.home.absoluteString
        XCTAssert(IsoPath.Parser.rootType(for: homeStr) == nil)

        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Document") == nil)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Documentss") == nil)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/documents") == nil)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Documents") == .document)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Documents/") == .document)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Documents/A") == .document)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Documents/A/B") == .document)

        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Librar") == nil)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Libraryy") == nil)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/library") == nil)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Library") == .library)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Library/") == .library)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Library/A") == .library)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Library/A/B") == .library)

        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Library/Cache") == .library)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Library/Cachess") == .library)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Library/caches") == .library)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Library/Caches") == .cache)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Library/Caches/") == .cache)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Library/Caches/A") == .cache)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Library/Caches/A/B") == .cache)

        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/tm") == nil)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/tmpp") == nil)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/Tmp") == nil)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/tmp") == .temporary)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/tmp/") == .temporary)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/tmp/A") == .temporary)
        XCTAssert(IsoPath.Parser.rootType(for: homeStr + "/tmp/A/B") == .temporary)
    }

    func _testParseOk(root: IsoPath) throws {
        let (space, domain) = (root.base.config.space, root.base.config.domain)

        do {
            let absStr = root.absoluteString
            let test = try IsoPath.parse(from: absStr, space: space, domain: domain)
            XCTAssert(test.absoluteString == absStr)
            XCTAssert(test.base.config.key == root.base.config.key)
        }

        do {
            let absStr = root.absoluteString + "/A"
            let test = try IsoPath.parse(from: absStr, space: space, domain: domain)
            XCTAssert(test.absoluteString == absStr, "lhs: \(test.absoluteString), rhs: \(absStr)")
            XCTAssert(test.base.config.key == root.base.config.key)
        }

        do {
            let absStr = root.absoluteString + "/A/B"
            let test = try IsoPath.parse(from: absStr, space: space, domain: domain)
            XCTAssert(test.absoluteString == absStr, "lhs: \(test.absoluteString), rhs: \(absStr)")
            XCTAssert(test.base.config.key == root.base.config.key)
        }
    }

    /// Parse succeed. 标准路径
    func testParseOk() throws {
        let userSpace = Space.user(id: String(UUID().uuidString.prefix(10)))
        let domain = Domain("IsoPathParseTests").child(String(UUID().uuidString.prefix(5)))
        let typedUser = IsoPath.in(space: userSpace, domain: domain)
        let typedGlboal = IsoPath.in(space: .global, domain: domain)

        try _testParseOk(root: typedUser.build(.document))
        try _testParseOk(root: typedUser.build(.library))
        try _testParseOk(root: typedUser.build(.cache))
        try _testParseOk(root: typedUser.build(.temporary))

        try _testParseOk(root: typedGlboal.build(.document))
        try _testParseOk(root: typedGlboal.build(.library))
        try _testParseOk(root: typedGlboal.build(.cache))
        try _testParseOk(root: typedGlboal.build(.temporary))
    }

    func _testParseOk2(root: AbsPath, space: Space, domain: Domain) throws {
        do {
            let absStr = root.absoluteString
            let test = try IsoPath.parse(from: absStr, space: space, domain: domain)
            XCTAssert(test.absoluteString == absStr)
            XCTAssert(test.base.config.space == space)
            XCTAssert(test.base.config.domain.isSame(as: domain))
        }

        do {
            let absStr = root.absoluteString + "/A"
            let test = try IsoPath.parse(from: absStr, space: space, domain: domain)
            XCTAssert(test.absoluteString == absStr, "lhs: \(test.absoluteString), rhs: \(absStr)")
            XCTAssert(test.base.config.space == space)
            XCTAssert(test.base.config.domain.isSame(as: domain))
        }

        do {
            let absStr = root.absoluteString + "/A/B"
            let test = try IsoPath.parse(from: absStr, space: space, domain: domain)
            XCTAssert(test.absoluteString == absStr, "lhs: \(test.absoluteString), rhs: \(absStr)")
            XCTAssert(test.base.config.space == space)
            XCTAssert(test.base.config.domain.isSame(as: domain))
        }
    }

    /// Parse succeed. 自定义 parser
    func testParseOk2() throws {
        let userSpace = Space.user(id: String(UUID().uuidString.prefix(10)))
        let glboalSpace = Space.global
        let domain = Domain("IsoPathParseTests").child(String(UUID().uuidString.prefix(5)))
        let rootParts: Array<AbsPath> = [
            .document + domain.isolationChain(with: "-"),
            .temporary + domain.isolationChain(with: "-"),
            .cache + domain.isolationChain(with: "-"),
            .library + domain.isolationChain(with: "-")
        ]
        IsoPath.Parser.register(forDomain: domain) { (space, absPath) in
            for rootPart in rootParts {
                if absPath.absoluteString.hasPrefix(rootPart.absoluteString) {
                    return IsoPath.Parser.TestSuccess(rootPart: rootPart)
                }
            }
            return nil
        }
        try _testParseOk2(root: rootParts[0], space: userSpace, domain: domain)
        try _testParseOk2(root: rootParts[1], space: userSpace, domain: domain)
        try _testParseOk2(root: rootParts[2], space: userSpace, domain: domain)
        try _testParseOk2(root: rootParts[3], space: userSpace, domain: domain)

        try _testParseOk2(root: rootParts[0], space: glboalSpace, domain: domain)
        try _testParseOk2(root: rootParts[1], space: glboalSpace, domain: domain)
        try _testParseOk2(root: rootParts[2], space: glboalSpace, domain: domain)
        try _testParseOk2(root: rootParts[3], space: glboalSpace, domain: domain)
    }

    /// Parse failed
    func testParseErr() throws {
        let userSpace = Space.user(id: String(UUID().uuidString.prefix(10)))
        let domain = Domain("IsoPathParseTests").child(String(UUID().uuidString.prefix(5)))

        // ParseError.invalidPath
        do {
            let absPath = ""
            _ = try IsoPath.parse(from: absPath, space: userSpace, domain: domain)
            XCTFail("unexpected")
        } catch IsoPath.ParseError.invalidPath { }
        do {
            let absPath = "a/b/c"
            _ = try IsoPath.parse(from: absPath, space: userSpace, domain: domain)
            XCTFail("unexpected")
        } catch IsoPath.ParseError.invalidPath { }
        do {
            var absPath = AbsPath.home.absoluteString
            absPath = String(absPath[..<absPath.index(before: absPath.endIndex)])
            _ = try IsoPath.parse(from: absPath, space: userSpace, domain: domain)
            XCTFail("unexpected")
        } catch IsoPath.ParseError.invalidPath { }

        // ParseError.unknownRootType
        do {
            let absPath = AbsPath.home.absoluteString + "/A"
            _ = try IsoPath.parse(from: absPath, space: userSpace, domain: domain)
            XCTFail("unexpected")
        } catch IsoPath.ParseError.unknownRootType { }
        do {
            let absPath = AbsPath.home.absoluteString + "/A/B"
            _ = try IsoPath.parse(from: absPath, space: userSpace, domain: domain)
            XCTFail("unexpected")
        } catch IsoPath.ParseError.unknownRootType { }

        // ParseError.outsidePath
        do {
            let absPath = AbsPath.home.absoluteString + "/Library"
            _ = try IsoPath.parse(from: absPath, space: userSpace, domain: domain)
            XCTFail("unexpected")
        } catch IsoPath.ParseError.outsidePath { }
        do {
            let absPath = AbsPath.home.absoluteString + "/Library/A/B"
            _ = try IsoPath.parse(from: absPath, space: userSpace, domain: domain)
            XCTFail("unexpected")
        } catch IsoPath.ParseError.outsidePath { }
    }

}
