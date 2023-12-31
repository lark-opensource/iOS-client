//   
//  KVMigrationRegistryTests.swift
//  LarkStorageDevTests
//
//  Created by 李昊哲 on 2023/2/16.
//  

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

class KVMigrationRegistryTests: KVMigrationTestCase {

    func testMergeConfigs() {
        func test(
            old: [KVMigrationConfig],
            new: [KVMigrationConfig],
            expect: [KVMigrationConfig]
        ) {
            let res = KVMigrationRegistry
                .mergeConfigs(old, new)
                .map(KVMigrationConfigWrapper.init)
            XCTAssertEqual(res.count, expect.count)
            let expectSet = Set(expect.map(KVMigrationConfigWrapper.init))
            XCTAssertEqual(Set(res), expectSet)
        }

        // 测试 items 合并
        test(
            old: [
                .from(userDefaults: .standard, items: ["key1", "key2"]),
                .from(userDefaults: .suiteName("suite1"), items: ["key1", "key2"]),
                .from(mmkv: .custom(mmapId: "id1", rootPath: "root1"), items: ["key1"]),
            ],
            new: [
                .from(userDefaults: .standard, items: ["key2", "key3"]),
                .from(userDefaults: .suiteName("suite1"), items: ["key2", "key3"]),
                .from(mmkv: .custom(mmapId: "id1", rootPath: "root1"), items: ["key3"]),
                .from(mmkv: .custom(mmapId: "id2", rootPath: "root1"), items: ["key1"]),
            ],
            expect: [
                .from(userDefaults: .standard, items: ["key1", "key2", "key3"]),
                .from(userDefaults: .suiteName("suite1"), items: ["key1", "key2", "key3"]),
                .from(mmkv: .custom(mmapId: "id1", rootPath: "root1"), items: ["key1", "key3"]),
                .from(mmkv: .custom(mmapId: "id2", rootPath: "root1"), items: ["key1"]),
            ]
        )

        // 测试不同种类的合并
        test(
            old: [
                .from(userDefaults: .standard, items: ["key1"]),
                .from(userDefaults: .standard, prefixPattern: "prefix1"),
                .from(userDefaults: .suiteName("suite1"), items: ["key1"]),
                .from(userDefaults: .suiteName("suite1"), prefixPattern: "prefix2"),
                .from(mmkv: .custom(mmapId: "id1", rootPath: "root1"), dropPrefixPattern: "drop1", type: Int.self),
            ],
            new: [
                .from(userDefaults: .standard, items: ["key2"]),
                .from(userDefaults: .standard, prefixPattern: "prefix2"),
                .from(userDefaults: .standard, suffixPattern: "prefix2"),
                .from(userDefaults: .suiteName("suite1"), items: ["key2"]),
                .from(userDefaults: .suiteName("suite1"), suffixPattern: "prefix3"),
                .from(userDefaults: .suiteName("suite2"), prefixPattern: "prefix3"),
                .from(mmkv: .custom(mmapId: "id1", rootPath: "root1"), prefixPattern: "prefix1", type: Int.self),
            ],
            expect: [
                .from(userDefaults: .standard, items: ["key1", "key2"]),
                .from(userDefaults: .standard, prefixPattern: "prefix1"),
                .from(userDefaults: .standard, prefixPattern: "prefix2"),
                .from(userDefaults: .standard, suffixPattern: "prefix2"),
                .from(userDefaults: .suiteName("suite1"), items: ["key1", "key2"]),
                .from(userDefaults: .suiteName("suite1"), prefixPattern: "prefix2"),
                .from(userDefaults: .suiteName("suite1"), suffixPattern: "prefix3"),
                .from(userDefaults: .suiteName("suite2"), prefixPattern: "prefix3"),
                .from(mmkv: .custom(mmapId: "id1", rootPath: "root1"), prefixPattern: "prefix1", type: Int.self),
                .from(mmkv: .custom(mmapId: "id1", rootPath: "root1"), dropPrefixPattern: "drop1", type: Int.self),
            ]
        )

        // 测试相同配置的去重
        test(
            old: [
                .from(userDefaults: .standard, items: ["key1"]),
                .from(userDefaults: .standard, prefixPattern: "prefix1"),
                .from(userDefaults: .suiteName("suite1"), items: ["key1"]),
                .from(userDefaults: .suiteName("suite1"), prefixPattern: "prefix2"),
                .from(mmkv: .custom(mmapId: "id1", rootPath: "root1"), prefixPattern: "prefix1", type: Int.self),
                .from(mmkv: .custom(mmapId: "id1", rootPath: "root1"), dropPrefixPattern: "drop1", type: Int.self),
            ],
            new: [
                .from(userDefaults: .standard, items: ["key1"]),
                .from(userDefaults: .standard, prefixPattern: "prefix1"),
                .from(userDefaults: .suiteName("suite1"), prefixPattern: "prefix2"),
                .from(mmkv: .custom(mmapId: "id1", rootPath: "root1"), prefixPattern: "prefix1", type: Int.self),
            ],
            expect: [
                .from(userDefaults: .standard, items: ["key1"]),
                .from(userDefaults: .standard, prefixPattern: "prefix1"),
                .from(userDefaults: .suiteName("suite1"), items: ["key1"]),
                .from(userDefaults: .suiteName("suite1"), prefixPattern: "prefix2"),
                .from(mmkv: .custom(mmapId: "id1", rootPath: "root1"), prefixPattern: "prefix1", type: Int.self),
                .from(mmkv: .custom(mmapId: "id1", rootPath: "root1"), dropPrefixPattern: "drop1", type: Int.self),
            ]
        )
    }

}

private typealias MigrationTestItem = (domain: DomainType, configs: [KVMigrationConfig])

private struct MigrationWrapper: Hashable, CustomDebugStringConvertible {
    let domain: DomainType
    let configSet: Set<KVMigrationConfigWrapper>

    var debugDescription: String {
        return "(domain: \(domain), configs: \(configSet))"
    }

    init(from: MigrationTestItem) {
        self.domain = from.domain
        self.configSet = Set(from.configs.map(KVMigrationConfigWrapper.init))
    }

    init(wrapped: KVMigrationRegistry.Item) {
        self.domain = wrapped.domain
        self.configSet = Set(wrapped
            .provider(.global)
            .map(KVMigrationConfigWrapper.init)
        )
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.domain.isolationId == rhs.domain.isolationId &&
        lhs.configSet == rhs.configSet
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.domain.isolationId)
        hasher.combine(self.configSet)
    }
}
