//
//  SBMigrationTaskManagerTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/11/14.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

final class SBMigrationTaskManagerTests: XCTestCase {

    typealias Config = SBMigrationConfig
    typealias Registry = SBMigrationRegistry

    /// 基础功能测试：注册 `SBMigrationConfig` 拿到正确的 `SBMigrationTask`
    func testBasic() {
        let taskManager = SBMigrationTaskManager()
        taskManager.enableCache = false // disable cache

        func checkWithSeeds(good: SBMigrationSeed, bads: [SBMigrationSeed]) {
            // 注册前，task 为空
            XCTAssertNil(taskManager.task(forSeed: good))
            // 注册
            Registry.registerMigration(forDomain: good.domain) { space in
                guard space == good.space else { return [:] }
                guard case .normal(let nType) = good.rootType else { return [:] }
                return [nType: .whole(fromRoot: nType.absPath, strategy: .redirect)]
            }
            // 注册后，task 有效
            XCTAssertNotNil(taskManager.task(forSeed: good))
            bads.forEach { bad in
                XCTAssertNil(taskManager.task(forSeed: bad))
            }
        }

        // 0 <= index < 8
        func prepareData(index: Int) -> (good: SBMigrationSeed, bads: [SBMigrationSeed]) {
            let domain = classDomain.randomChild()
            let userSpace = Space.randomUser()
            var all: [SBMigrationSeed] = [
                .init(space: .global, domain: domain, rootType: .normal(.document)),
                .init(space: .global, domain: domain, rootType: .normal(.library)),
                .init(space: .global, domain: domain, rootType: .normal(.cache)),
                .init(space: .global, domain: domain, rootType: .normal(.temporary)),
                .init(space: userSpace, domain: domain, rootType: .normal(.document)),
                .init(space: userSpace, domain: domain, rootType: .normal(.library)),
                .init(space: userSpace, domain: domain, rootType: .normal(.cache)),
                .init(space: userSpace, domain: domain, rootType: .normal(.temporary))
            ]
            let good = all[index]
            all.remove(at: index)
            return (good, all)
        }

        for i in 0..<8 {
            let (good, bads) = prepareData(index: i)
            checkWithSeeds(good: good, bads: bads)
        }
    }

    /// 测试所维护的 tasks 的线程安全
    /// 说明：
    ///    - 高频并发访问 `task(forSeed:)` 和 `allTasks(forSpaces:)` 接口；
    /// 预期：
    ///    - 不崩、不卡死
    ///    - `task` 的数量符合预期
    ///    - 每个 seed 对应的 `task` 只创建一次
    func _testThreadSafe() {
        let taskManager = SBMigrationTaskManager()
        taskManager.enableCache = true

        /** **step 1: prepare config** */
        let domains = Array(0..<10).map { classDomain.child("Child\($0)") }
        for domain in domains {
            Registry.registerMigration(forDomain: domain) { space in
                switch space {
                case .global: return [
                    .document: .whole(fromRoot: AbsPath.document, strategy: .redirect),
                    .library: .whole(fromRoot: AbsPath.library, strategy: .redirect),
                    .cache: .whole(fromRoot: AbsPath.cache, strategy: .redirect),
                    .temporary: .whole(fromRoot: AbsPath.temporary, strategy: .redirect)
                ]
                case .user(let uid): return [
                    .document: .whole(fromRoot: AbsPath.document + uid, strategy: .redirect),
                    .library: .whole(fromRoot: AbsPath.library + uid, strategy: .redirect),
                    .cache: .whole(fromRoot: AbsPath.cache + uid, strategy: .redirect),
                    .temporary: .whole(fromRoot: AbsPath.temporary + uid, strategy: .redirect)
                ]
                }
            }
        }

        /** **step 2: access concurrently** */
        let spacePrefix = UUID().uuidString
        let spaces: [Space] = Array(0..<5).map { i -> Space in .user(id: "\(spacePrefix)\(i)") }
        let expectedSeeds: [SBMigrationSeed] =
            spaces
                .flatMap { space -> [(Space, Domain)] in
                    domains.map { (space, $0) }
                }
                .flatMap { pair -> [(Space, Domain, RootPathType)] in
                    let (space, domain) = pair
                    return [
                        (space, domain, .normal(.document)),
                        (space, domain, .normal(.library)),
                        (space, domain, .normal(.cache)),
                        (space, domain, .normal(.temporary))
                    ]
                }
                .map { thripe -> SBMigrationSeed in
                    let (space, domain, type) = thripe
                    return .init(space: space, domain: domain, rootType: type)
                }

        let begin = CFAbsoluteTimeGetCurrent()
        let exp1 = expectation(description: "task(forSeed:)")
        do { // task(forSeed:)
            let dispatchGroup = DispatchGroup()
            for _ in 0..<5000 {
                dispatchGroup.enter()
                let randomIndex = Int.random(in: 0..<expectedSeeds.count)
                let seed = expectedSeeds[randomIndex]
                DispatchQueue.global().async {
                    let task = taskManager.task(forSeed: seed)
                    XCTAssertNotNil(task)
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                exp1.fulfill()
            }
        }
        let exp2 = expectation(description: "allTasks(forSpaces:)")
        do { // allTasks(forSpaces:)
            let dispatchGroup = DispatchGroup()
            for _ in 0..<1000 {
                dispatchGroup.enter()
                DispatchQueue.global().async {
                    let tasks = taskManager.allTasks(forSpaces: spaces)
                        .filter { $0.seed.domain.isDescendant(of: self.classDomain) }
                    XCTAssert(tasks.count == expectedSeeds.count)
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                exp2.fulfill()
            }
        }
        wait(for: [exp1, exp2], timeout: 40)
        let cost = CFAbsoluteTimeGetCurrent() - begin
        log.debug("\(typeName) test costing: \(cost) s")
    }
}
