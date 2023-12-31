//
//  SBMigrationThreadSafeTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/11/15.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

/// 测试线程安全
final class SBMigrationThreadSafeTests: XCTestCase {

    /// 对于含有迁移配置的 `IsoPath`，构建实例时，会触发其数据迁移操作；
    /// 本测试多线程并发构建 `IsoPath`，验证不会死锁
    func _testMigrating() throws {
        let space: Space = .global
        let domain = classDomain.child("TestMigrating_" + UUID().uuidString.prefix(7))
        let rootType: RootPathType.Normal = .library

        let dirNames = Array((1..<1000).map(String.init))
        // prepare data
        do {
            let rootPathName = "TestMigrating"
            let rootPath: AbsPath = rootType.absPath + rootPathName
            let fm = FileManager()
            if rootPath.exists {
                try fm.removeItem(atPath: rootPath.absoluteString)
            }
            try fm.createDirectory(atPath: rootPath.absoluteString, withIntermediateDirectories: true)
            for dirName in dirNames {
                let dirPath = rootPath + dirName
                try fm.createDirectory(atPath: dirPath.absoluteString, withIntermediateDirectories: true)
                let filePath = dirPath + "\(dirName).txt"
                fm.createFile(atPath: filePath.absoluteString, contents: dirName.data(using: .utf8)!)
            }

            SBMigrationRegistry.registerMigration(forDomain: domain) { _space in
                guard space == _space else { return [:] }
                return [
                    rootType: .partial(
                        fromRoot: rootPath,
                        strategy: .moveOrDrop(allows: .intialization),
                        items: dirNames.map { .init($0) }
                    )
                ]
            }
        }

        // access concurrently
        do {
            let begin = CFAbsoluteTimeGetCurrent()
            let exp = expectation(description: "testMigrating")
            let dispatchGroup = DispatchGroup()
            for _ in 0..<1000 {
                dispatchGroup.enter()
                DispatchQueue.global().async {
                    let root = IsoPath.in(space: space, domain: domain).build(rootType)
                    for dirName in dirNames {
                        let dirPath = root + dirName
                        let filePath = dirPath + "\(dirName).txt"

                        XCTAssert(dirPath.exists)
                        XCTAssert(filePath.exists)

                        if case .standard = dirPath.base.type,
                           case .standard = filePath.base.type
                        { /* ok */ }
                        else {
                            XCTFail("unexpected")
                        }
                    }
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                exp.fulfill()
            }
            wait(for: [exp], timeout: 100)
            let cost = CFAbsoluteTimeGetCurrent() - begin
            log.debug("\(typeName) test costing: \(cost) s")
        }
    }

}
