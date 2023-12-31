//
//  SBMigrationStrategyTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/11/14.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

/// 测试迁移配置 whole
final class SBMigrationStrategyTests: SBMigrationTests {

    typealias Checker = () throws -> Void

    // MARK: Whole Matcher

    func wholeTest(strategy: SBMigrationStrategy) throws -> [Checker] {
        let strategyStr: String
        switch strategy {
        case .redirect: strategyStr = "WholeRedirect"
        case .moveOrDrop: strategyStr = "WholeMoveOrDrop"
        }
        let domain = classDomain.child(strategyStr).child("Whole_" + UUID().uuidString.prefix(7))
        let rootPathName = strategyStr

        var globalConfigs = [RootPathType.Normal: SBMigrationConfig]()
        var userConfigs = [RootPathType.Normal: SBMigrationConfig]()
        var checkers = [Checker]()

        // prepare data
        func prepareData(for type: RootPathType.Normal, space: Space) throws {
            let rootPath: AbsPath
            switch space {
            case .global:
                rootPath = type.absPath + rootPathName
                // insert config
                globalConfigs[type] = .whole(fromRoot: rootPath, strategy: strategy)
            case .user(let uid):
                rootPath = type.absPath + "User_\(uid)/\(rootPathName)"
                // insert config
                userConfigs[type] = .whole(fromRoot: rootPath, strategy: strategy)
            }
            let fm = FileManager.default
            if rootPath.exists {
                try fm.removeItem(atPath: rootPath.absoluteString)
            }
            try fm.createDirectory(atPath: rootPath.absoluteString, withIntermediateDirectories: true)

            let filePath = rootPath + "file.txt"
            let writeData = self.textData(for: type)
            XCTAssertTrue(fm.createFile(atPath: filePath.absoluteString, contents: writeData))

            checkers.append {
                let testPath = IsoPath.in(space: space, domain: domain).build(type) + "file.txt"

                // 1. 验证 testPath 内部类型
                switch strategy {
                case .redirect:
                    if case .custom = testPath.base.type {
                        // expected
                    } else {
                        XCTFail("unexpected")
                    }
                case .moveOrDrop(let allows):
                    if allows.contains(.intialization) {
                        if case .standard = testPath.base.type {
                            // expected
                        } else {
                            XCTFail("unexpected")
                        }
                    } else {
                        if case .custom = testPath.base.type {
                            // expected
                        } else {
                            XCTFail("unexpected")
                        }
                    }
                }

                // 验证文件存在
                XCTAssert(testPath.exists)

                // 验证文件路径
                switch strategy {
                case .redirect:
                    XCTAssert(testPath.absoluteString == filePath.absoluteString)
                case .moveOrDrop(let allows):
                    if allows.contains(.intialization) {
                        XCTAssert(testPath.absoluteString != filePath.absoluteString)
                    } else {
                        XCTAssert(testPath.absoluteString == filePath.absoluteString)
                    }
                }

                // 验证数据相同
                let readData = try Data.read(from: testPath)
                XCTAssert(readData == writeData)
            }
        }

        let userSpace = Space.user(id: UUID().uuidString)

        try prepareData(for: .document, space: .global)
        try prepareData(for: .library, space: .global)
        try prepareData(for: .cache, space: .global)
        try prepareData(for: .temporary, space: .global)

        try prepareData(for: .document, space: userSpace)
        try prepareData(for: .library, space: userSpace)
        try prepareData(for: .cache, space: userSpace)
        try prepareData(for: .temporary, space: userSpace)

        Registry.registerMigration(forDomain: domain) { space in
            switch space {
            case .global: return globalConfigs
            case .user: return userConfigs
            }
        }
        return checkers
    }

    // MARK: Partial Matcher

    func partialTest(strategy: SBMigrationStrategy) throws -> [Checker] {
        let strategyStr: String
        switch strategy {
        case .redirect: strategyStr = "PartialRedirect"
        case .moveOrDrop: strategyStr = "PartialMoveOrDrop"
        }
        let domain = classDomain.child(strategyStr).child("Partial_" + UUID().uuidString.prefix(7))
        let rootPathName = strategyStr

        var globalConfigs = [RootPathType.Normal: SBMigrationConfig]()
        var userConfigs = [RootPathType.Normal: SBMigrationConfig]()
        var checkers = [Checker]()

        // prepare data
        func prepareData(for type: RootPathType.Normal, space: Space) throws {
            let rootPath: AbsPath
            switch space {
            case .global:
                rootPath = type.absPath + rootPathName
            case .user(let uid):
                rootPath = type.absPath + rootPathName + uid
            }
            let fm = FileManager.default
            if rootPath.exists {
                try fm.removeItem(atPath: rootPath.absoluteString)
            }
            try fm.createDirectory(atPath: rootPath.absoluteString, withIntermediateDirectories: true)

            let doCheck = { (old_A: AbsPath, old_a: AbsPath, new_A: IsoPath, new_a: IsoPath, textData: Data) throws in
                // 验证 new_A/new_a 内部类型
                switch strategy {
                case .redirect:
                    if case .custom = new_A.base.type,
                       case .custom = new_a.base.type
                    { /* ok */ }
                    else {
                        XCTFail("unexpected")
                    }
                case .moveOrDrop(let allows):
                    if allows.contains(.intialization) {
                        if case .standard = new_A.base.type,
                           case .standard = new_a.base.type
                        { /* ok */ }
                        else {
                            XCTFail("unexpected")
                        }
                    } else {    // same as redirect
                        if case .custom = new_A.base.type,
                           case .custom = new_a.base.type
                        { /* ok */ }
                        else {
                            XCTFail("unexpected")
                        }
                    }
                }

                // 验证 new_A/new_a 存在
                XCTAssert(new_A.exists)
                XCTAssert(new_a.exists)

                // 比较 old_A/new_A, old_a/new_a
                switch strategy {
                case .redirect:
                    XCTAssert(old_A.absoluteString == new_A.absoluteString)
                    XCTAssert(old_a.absoluteString == new_a.absoluteString)
                case .moveOrDrop(let allows):
                    if allows.contains(.intialization) {
                        XCTAssert(old_A.absoluteString != new_A.absoluteString)
                        XCTAssert(old_a.absoluteString != new_a.absoluteString)
                    } else {
                        XCTAssert(old_A.absoluteString == new_A.absoluteString)
                        XCTAssert(old_a.absoluteString == new_a.absoluteString)
                    }
                }

                // 验证数据
                let newData = try Data.read(from: new_a)
                XCTAssert(textData == newData)
            }

            /// prepare data:
            ///
            /// └── fromRoot/
            ///     ├── A/a.txt             -> global; ~> A
            ///     ├── B/b.txt             -> global; ~> B
            ///     ├── {userId}/C/c.txt    -> user;   ~> C
            ///     └── {userId}/D/c.txt    -> user;   ~> D

            switch space {
            case .global:
                let A = rootPath + "A"
                try fm.createDirectory(atPath: A.absoluteString, withIntermediateDirectories: true)
                let a = A + "a.txt"
                XCTAssertTrue(fm.createFile(atPath: a.absoluteString, contents: "a".data(using: .utf8)!))

                let B = rootPath + "B"
                try fm.createDirectory(atPath: B.absoluteString, withIntermediateDirectories: true)
                let b = B + "b.txt"
                XCTAssertTrue(fm.createFile(atPath: b.absoluteString, contents: "b".data(using: .utf8)!))

                // insert config
                globalConfigs[type] = .partial(fromRoot: rootPath, strategy: strategy, items: ["A", "B"])

                checkers.append {
                    let APath = IsoPath.in(space: space, domain: domain).build(type) + "A"
                    let aPath = APath + "a.txt"
                    try doCheck(A, a, APath, aPath, "a".data(using: .utf8)!)

                    let BPath = IsoPath.in(space: space, domain: domain).build(type) + "B"
                    let bPath = BPath + "b.txt"
                    try doCheck(B, b, BPath, bPath, "b".data(using: .utf8)!)
                }
            case .user:
                let C = rootPath + "C"
                try fm.createDirectory(atPath: C.absoluteString, withIntermediateDirectories: true)
                let c = C + "c.txt"
                XCTAssertTrue(fm.createFile(atPath: c.absoluteString, contents: "c".data(using: .utf8)!))

                let D = rootPath + "D"
                try fm.createDirectory(atPath: D.absoluteString, withIntermediateDirectories: true)
                let d = D + "d.txt"
                XCTAssertTrue(fm.createFile(atPath: d.absoluteString, contents: "d".data(using: .utf8)!))

                userConfigs[type] = .partial(fromRoot: rootPath, strategy: strategy, items: ["C", "D"])

                checkers.append {
                    let CPath = IsoPath.in(space: space, domain: domain).build(type) + "C"
                    let cPath = CPath + "c.txt"
                    try doCheck(C, c, CPath, cPath, "c".data(using: .utf8)!)

                    let DPath = IsoPath.in(space: space, domain: domain).build(type) + "D"
                    let dPath = DPath + "d.txt"
                    try doCheck(D, d, DPath, dPath, "d".data(using: .utf8)!)
                }
            }
        }

        let userSpace = Space.user(id: UUID().uuidString)

        try prepareData(for: .document, space: .global)
        try prepareData(for: .library, space: .global)
        try prepareData(for: .cache, space: .global)
        try prepareData(for: .temporary, space: .global)

        try prepareData(for: .document, space: userSpace)
        try prepareData(for: .library, space: userSpace)
        try prepareData(for: .cache, space: userSpace)
        try prepareData(for: .temporary, space: userSpace)

        Registry.registerMigration(forDomain: domain) { space in
            switch space {
            case .global: return globalConfigs
            case .user: return userConfigs
            }
        }
        return checkers
    }

    /// 测试 redirect 策略
    /// 测试说明：
    ///   1. 在非标准路径准备数据
    ///   2. 使用 IsoPath 解析得到的 inner 为 .iso(IsolateSandbox.Path) 类型
    ///   3. 使用 IsoPath 能读取出数据，且路径指引到非标准路径
    func testRedirect() throws {
        try wholeTest(strategy: .redirect).forEach { try $0() }
        // try partialTest(strategy: .redirect).forEach { try $0() }
    }

    /// 测试 moveOrDrop 策略
    /// 测试说明：
    ///   1. 在非标准路径准备数据
    ///   2. 使用 IsoPath 解析得到的 inner 为 .iso(IsolateSandbox.Path) 类型
    ///   3. 使用 IsoPath 能读取出数据，且路径指引到标准路径
    func testMoveOrDrop() throws {
        try wholeTest(strategy: .moveOrDrop(allows: .intialization)).forEach { try $0() }
        try wholeTest(strategy: .moveOrDrop(allows: .background)).forEach { try $0() }
        try partialTest(strategy: .moveOrDrop(allows: .intialization)).forEach { try $0() }
        try partialTest(strategy: .moveOrDrop(allows: .background)).forEach { try $0() }
    }
}
