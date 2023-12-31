//
//  KVMigrationTaskManagerTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/11/4.
//

import Foundation
import XCTest
import EEAtomic
@testable import LarkStorageCore
@testable import LarkStorage

/// 测试 `KVMigrationTask` 核心接口
final class KVMigrationTaskManagerTests: KVMigrationTestCase {

    static var oldEnableAssertionFailure = false

    override class func setUp() {
        super.setUp()
        oldEnableAssertionFailure = AssertReporter.enableAssertionFailure
        AssertReporter.enableAssertionFailure = false
    }

    override class func tearDown() {
        AssertReporter.enableAssertionFailure = oldEnableAssertionFailure
    }

    /// 基础功能测试：注册 `KVMigrationConfig` 拿到正确的 `KVMigrationTask`
    func testBasic() {
        let taskManager = KVMigrationTaskManager()
        taskManager.enableCache = false // disable cache

        func checkWithSeeds(good: KVMigrationSeed, bads: [KVMigrationSeed]) {
            // 注册前，task 为空
            XCTAssertNil(taskManager.task(forSeed: good))
            // 注册
            Registry.registerMigration(forDomain: good.domain) { space in
                guard space == good.space else { return [] }
                switch good.mode {
                case .normal:
                    return [.from(userDefaults: .standard, to: good.type, items: [])]
                case .shared:
                    return [.from(userDefaults: .appGroup, to: good.type, items: [])]
                }
            }
            // 注册后，task 有效
            XCTAssertNotNil(taskManager.task(forSeed: good))
            bads.forEach { bad in
                XCTAssertNil(taskManager.task(forSeed: bad))
            }
        }

        do {
            let domain = classDomain.randomChild()
            let good = KVMigrationSeed(space: .global, domain: domain, mode: .normal, type: .udkv)
            let userSpace = Space.randomUser()
            let sharedMode = KVStoreMode.shared
            let bads: [KVMigrationSeed] = [
                .init(space: .global, domain: domain, mode: .normal, type: .mmkv),
                .init(space: .global, domain: domain, mode: sharedMode, type: .udkv),
                .init(space: .global, domain: domain, mode: sharedMode, type: .mmkv),
                .init(space: userSpace, domain: domain, mode: .normal, type: .udkv),
                .init(space: userSpace, domain: domain, mode: .normal, type: .mmkv),
                .init(space: userSpace, domain: domain, mode: sharedMode, type: .udkv),
                .init(space: userSpace, domain: domain, mode: sharedMode, type: .mmkv),
            ]
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
        let taskManager = KVMigrationTaskManager()
        taskManager.enableCache = true

        /** **step 1: prepare config** */
        let domains = Array(0..<20).map { classDomain.child("Child\($0)") }
        // 保存正常的白名单，不影响其他单测
        let oldWhiteList = Dependencies.backgroundTaskWhiteList
        defer { Dependencies.backgroundTaskWhiteList = oldWhiteList }
        // 只有白名单里的 domain 才能生成 allTask
        Dependencies.backgroundTaskWhiteList = [classDomain]

        let suiteName = UUID().uuidString
        for domain in domains {
            Registry.registerMigration(forDomain: domain) { space in
                switch space {
                case .global: return [
                    // global 不加配置，因为容易和其他测试 testCases 逻辑互相干扰
                ]
                case .user: return [
                    // to: .udkv; mode: normal
                    .from(userDefaults: .standard, to: .udkv, items: []),
                    .from(userDefaults: .suiteName(suiteName), to: .udkv, items: []),
                    // to: .mmkv; mode: normal
                    .from(userDefaults: .standard, to: .mmkv, items: []),
                    .from(userDefaults: .suiteName(suiteName), to: .mmkv, items: []),
                    // to: .udkv; mode: shared
                    .from(userDefaults: .appGroup, to: .udkv, items: []),
                    // to: .mmkv; mode: shared
                    .from(userDefaults: .appGroup, to: .mmkv, items: []),
                ]
                }
            }
        }

        /** **step 2: access concurrently** */
        let spacePrefix = UUID().uuidString
        let spaces: [Space] = Array(0..<5).map { i -> Space in .user(id: "\(spacePrefix)\(i)") }
        let expectedSeeds: [KVMigrationSeed] =
            spaces
                .flatMap { space -> [(Space, Domain)] in
                    domains.map { (space, $0) }
                }
                .flatMap { pair -> [(Space, Domain, KVStoreMode)] in
                    let (space, domain) = pair
                    return [
                        (space, domain, .normal),
                        (space, domain, .shared)
                    ]
                }
                .flatMap { thripe -> [KVMigrationSeed] in
                    let (space, domain, mode) = thripe
                    return [
                        .init(space: space, domain: domain, mode: mode, type: .udkv),
                        .init(space: space, domain: domain, mode: mode, type: .mmkv),
                    ]
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
                    XCTAssertEqual(tasks.count, expectedSeeds.count)
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                exp2.fulfill()
            }
        }
        wait(for: [exp1, exp2], timeout: 120)
        let cost = CFAbsoluteTimeGetCurrent() - begin
        log.debug("\(typeName) test costing: \(cost) s")
    }

}
