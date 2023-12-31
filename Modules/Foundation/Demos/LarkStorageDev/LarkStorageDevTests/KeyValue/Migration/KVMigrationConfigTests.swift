//
//  KVMigrationConfigTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/11/4.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage
@testable import LarkStorageAssembly

/// 测试 `KVMigrationConfig` 核心接口
final class KVMigrationConfigTests: KVMigrationTestCase {

    typealias Config = KVMigrationConfig

    static var oldEnableAssertionFailure = false

    override class func setUp() {
        super.setUp()
        // 将 assertionFailure 给关掉，避免 block 测试流程
        oldEnableAssertionFailure = AssertReporter.enableAssertionFailure
        AssertReporter.enableAssertionFailure = false
    }

    override class func tearDown() {
        super.tearDown()
        AssertReporter.enableAssertionFailure = oldEnableAssertionFailure
    }

    // 测试 `KVMigrationConfig#safeFromStore()` 接口
    func testSafeFromStore() {
        // KeyMatcher.simple 对应的 udkv config 的 store 都有效
        do {
            let uuid = UUID().uuidString

            let conf1: Config = .from(userDefaults: .standard, items: [])
            XCTAssertNotNil(conf1.safeFromStore()?.disposed(self))

            let conf2: Config = .from(userDefaults: .appGroup, items: [])
            XCTAssertNotNil(conf2.safeFromStore()?.disposed(self))

            let conf3: Config = .from(userDefaults: .suiteName(""), items: [])
            XCTAssertNotNil(conf3.safeFromStore()?.disposed(self))

            let conf4: Config = .from(userDefaults: .suiteName("conf5" + uuid), items: [])
            XCTAssertNotNil(conf4.safeFromStore()?.disposed(self))
        }

        // KeyMatcher.prefix 对应的 udkv config 的 store 都有效
        do {
            let uuid = UUID().uuidString
            let pattern = "prefix"

            let conf1: Config = .from(userDefaults: .standard, prefixPattern: pattern)
            XCTAssertNotNil(conf1.safeFromStore()?.disposed(self))

            let conf2: Config = .from(userDefaults: .appGroup, prefixPattern: pattern)
            XCTAssertNotNil(conf2.safeFromStore()?.disposed(self))

            let conf3: Config = .from(userDefaults: .appGroup, prefixPattern: pattern)
            XCTAssertNotNil(conf3.safeFromStore()?.disposed(self))

            let conf4: Config = .from(userDefaults: .suiteName(""), prefixPattern: pattern)
            XCTAssertNotNil(conf4.safeFromStore()?.disposed(self))

            let conf5: Config = .from(userDefaults: .suiteName("conf5" + uuid), prefixPattern: pattern)
            XCTAssertNotNil(conf5.safeFromStore()?.disposed(self))
        }

        // KeyMatcher.allValues 搭配 userDefaults.suiteName 模式下才有效，且 suiteName 有效
        do {
            let uuid = UUID().uuidString

            let conf1: Config = .allValuesFromUserDefaults(named: "")
            XCTAssertNil(conf1.safeFromStore()?.disposed(self))

            let conf2: Config = .allValuesFromUserDefaults(named: uuid)
            XCTAssertNotNil(conf2.safeFromStore()?.disposed(self))
        }

        guard let rootPath = KVStores.mmkvRootPath(with: .normal) else {
            XCTFail("failed to get mmkvRootPath")
            return
        }

        // 测试mmkv config的store是否正常
        do {
            let uuid = UUID().uuidString

            // let conf1 = Config.from(mmkv: .custom(mmapId: "", rootPath: rootPath), items: [])
            let conf2 = Config.from(mmkv: .custom(mmapId: "conf2" + uuid, rootPath: rootPath), items: ["some_key"])
            let conf3 = Config.init(
                from: .mmkv(.custom(mmapId: "conf3" + uuid, rootPath: rootPath)),
                to: .mmkv,
                keyMatcher: .allValues
            )
            // XCTAssertNil(conf1.safeFromStore()?.disposed(self))
            XCTAssertNil(conf2.safeFromStore()?.disposed(self))
            XCTAssertNil(conf3.safeFromStore()?.disposed(self))

            let conf4 = Config.from(mmkv: .custom(mmapId: "conf4" + uuid, rootPath: rootPath), items: [])
            let conf5 = Config.from(mmkv: .custom(mmapId: "conf5" + uuid, rootPath: rootPath), items: [
                .init(oldKey: "oldkey", newKey: "newkey", type: Data.self)
            ])
            let conf6 = Config.from(mmkv: .custom(mmapId: "conf6" + uuid, rootPath: rootPath), prefixPattern: "prefix", type: Data.self)
            XCTAssertNotNil(conf4.safeFromStore()?.disposed(self))
            XCTAssertNotNil(conf5.safeFromStore()?.disposed(self))
            XCTAssertNotNil(conf6.safeFromStore()?.disposed(self))
        }
    }

    /// 测试 `KVMigrationConfig#copyAll(to:)` 接口，针对UDKV的部分
    /// 说明：
    ///   - 迁移配置里的 key-values 才会被 copy；没有注册进去的 key-values 不受影响
    func testCopyAllUDKV() {
        let toStore = KVStores.udkv(space: .global, domain: classDomain).disposed(self)

        typealias Checker = () -> Void
        // 往 fromStore 里新增一些迁移配置之外的数据；
        // `copyAll` 操作对它们应该没有影响，也即 `copyAll(to: toStore)` 之后，toStore 里不应该有这些数据。
        // 不适用于 `KeyMatcher.allValues` 场景
        func checkExtraData(fromStore: KVStore) -> [Checker] {
            var checkers = [Checker]()

            let kv1 = (key: KVKey(UUID().uuidString, default: 0), val: 73)
            fromStore[kv1.key] = kv1.val
            checkers.append { XCTAssertFalse(toStore.contains(key: kv1.key)) }

            let kv2 = (key: KVKey(UUID().uuidString, default: ""), val: "73")
            fromStore[kv2.key] = kv2.val
            checkers.append { XCTAssertFalse(toStore.contains(key: kv2.key)) }

            return checkers
        }

        // keyMatcher: simpleItems
        do {
            func testSimpleItems(suiteName: String?, from: Config.From.UserDefaults) {
                toStore.clearAll()

                let fromStore = (suiteName != nil ? UDKVStore(suiteName: suiteName!)! : UDKVStore())
                    .disposed(self)
                KVItems.saveAllCases(in: fromStore)
                KVObjects.saveAllCases(in: fromStore)
                KVItems.checkAllCases(in: fromStore)
                KVObjects.checkAllCases(in: fromStore)

                let checkers = checkExtraData(fromStore: fromStore)
                defer { checkers.forEach { $0() } }

                let suffix = UUID().uuidString  // key 迁移：newKey = oldKey + suffix
                let buildItem = { $0 ~> ($0 + suffix) }
                let conf: Config = .from(
                    userDefaults: from,
                    items: KVItems.allKeys.map(buildItem) + KVObjects.allKeys.map(buildItem)
                )

                // copy 前：toStore 为空
                KVItems.checkAllCasesNil(in: toStore, keyMap: { $0 + suffix })
                KVObjects.checkAllCasesNil(in: toStore, keyMap: { $0 + suffix })
                conf.copyAll(to: toStore)
                // copy 后：toStore 中有预期的数据
                KVItems.checkAllCases(in: toStore, keyMap: { $0 + suffix })
                KVObjects.checkAllCases(in: toStore, keyMap: { $0 + suffix })
            }

            // from: UserDefaults.standard
            testSimpleItems(suiteName: nil, from: .standard)

            // from: UserDefaults.suiteName("xxx")
            let validSuiteName = UUID().uuidString
            testSimpleItems(suiteName: validSuiteName, from: .suiteName(validSuiteName))

            // from: UserDefaults.suiteName("")
            let emptySuiteName = ""
            testSimpleItems(suiteName: emptySuiteName, from: .suiteName(emptySuiteName))

            // from: UserDefaults.appGroup("xxx")
            testSimpleItems(suiteName: Dependencies.appGroupId, from: .appGroup)
        }

        // keyMatcher: prefixPattern
        do {
            func testPrefixPattern(suiteName: String?, from: Config.From.UserDefaults) {
                toStore.clearAll()
                let fromStore = (suiteName != nil ? UDKVStore(suiteName: suiteName!)! : UDKVStore())
                    .disposed(self)
                let prefix = UUID().uuidString
                let keyMap = { (key: String) in prefix + key }
                KVItems.saveAllCases(in: fromStore, keyMap: keyMap)
                KVObjects.saveAllCases(in: fromStore, keyMap: keyMap)
                KVItems.checkAllCases(in: fromStore, keyMap: keyMap)
                KVObjects.checkAllCases(in: fromStore, keyMap: keyMap)

                let checkers = checkExtraData(fromStore: fromStore)
                defer { checkers.forEach { $0() } }

                let conf: Config = .from(userDefaults: from, prefixPattern: prefix)

                // copy 前：toStore 为空
                KVItems.checkAllCasesNil(in: toStore, keyMap: keyMap)
                KVObjects.checkAllCasesNil(in: toStore, keyMap: keyMap)
                conf.copyAll(to: toStore)
                // copy 后：toStore 中有预期的数据
                KVItems.checkAllCases(in: toStore, keyMap: keyMap)
                KVObjects.checkAllCases(in: toStore, keyMap: keyMap)
            }

            // from: UserDefaults.standard
            testPrefixPattern(suiteName: nil, from: .standard)

            // from: UserDefaults.suiteName("xxx")
            let validSuiteName = UUID().uuidString
            testPrefixPattern(suiteName: validSuiteName, from: .suiteName(validSuiteName))

            // from: UserDefaults.suiteName("")
            let emptySuiteName = ""
            testPrefixPattern(suiteName: emptySuiteName, from: .suiteName(emptySuiteName))

            // from: UserDefaults.appGroup("xxx")
            testPrefixPattern(suiteName: Dependencies.appGroupId, from: .appGroup)
        }

        // keyMatcher: allValues
        do {
            func testAllValues(suiteName: String?, from: Config.From.UserDefaults, expectFail: Bool) {
                toStore.clearAll()
                let fromStore: KVStore
                if let suiteName {
                    fromStore = UDKVStore(suiteName: suiteName)!.disposed(self)
                } else {
                    fromStore = UDKVStore().disposed(self)
                }
                let prefix = UUID().uuidString
                let suffix = UUID().uuidString
                let keyMap = { (key: String) in prefix + key + suffix }
                KVItems.saveAllCases(in: fromStore, keyMap: keyMap)
                KVObjects.saveAllCases(in: fromStore, keyMap: keyMap)
                KVItems.checkAllCases(in: fromStore, keyMap: keyMap)
                KVObjects.checkAllCases(in: fromStore, keyMap: keyMap)

                let conf = Config(from: .userDefaults(from), to: .udkv, keyMatcher: .allValues)

                // copy 前：toStore 为空
                KVItems.checkAllCasesNil(in: toStore, keyMap: keyMap)
                KVObjects.checkAllCasesNil(in: toStore, keyMap: keyMap)
                conf.copyAll(to: toStore)
                if expectFail { // 拷贝失败
                    KVItems.checkAllCasesNil(in: toStore, keyMap: keyMap)
                    KVObjects.checkAllCasesNil(in: toStore, keyMap: keyMap)
                } else {        // 拷贝成功
                    KVItems.checkAllCases(in: toStore, keyMap: keyMap)
                    KVObjects.checkAllCases(in: toStore, keyMap: keyMap)
                }
            }

            // from: UserDefaults.standard
            testAllValues(suiteName: nil, from: .standard, expectFail: true)

            // from: UserDefaults.suiteName("xxx")
            let validSuiteName = UUID().uuidString
            testAllValues(suiteName: validSuiteName, from: .suiteName(validSuiteName), expectFail: false)

            // from: UserDefaults.suiteName("")
            let emptySuiteName = ""
            testAllValues(suiteName: emptySuiteName, from: .suiteName(emptySuiteName), expectFail: true)

            // from: UserDefaults.appGroup("xxx")
            testAllValues(suiteName: Dependencies.appGroupId, from: .appGroup, expectFail: true)
        }

        let toStoreCrypted = toStore.usingCipher(suite: .aes)
        // keyMatcher: simpleItems - crypted
        do {
            log.debug("start to test simpleItems - crypted")
            func testSimpleItemsCrypted(suiteName: String, from: Config.From.UserDefaults) {
                toStoreCrypted.clearAll()

                let base = UDKVStore(suiteName: suiteName)!.disposed(self)
                let cipher = KVCipherManager.shared.cipher(forSuite: .aes)!
                let fromStore = KVStoreCryptoProxy(wrapped: base, cipher: cipher)
                KVItems.saveAllCases(in: fromStore)
                KVObjects.saveAllCases(in: fromStore)
                KVItems.checkAllCases(in: fromStore)
                KVObjects.checkAllCases(in: fromStore)

                let checkers = checkExtraData(fromStore: fromStore)
                defer { checkers.forEach { $0() } }

                let suffix = UUID().uuidString  // key 迁移：newKey = oldKey + suffix
                let buildItem = { key, type in
                    KVMigrationConfig.KeyMatcher.SimpleItem(oldKey: key, newKey: key + suffix, type: type)
                }
                let conf: Config = .from(
                    userDefaults: from,
                    cipherSuite: .aes,
                    items: KVItems.mapWithKeyAndType(buildItem) + KVObjects.mapWithKeyAndType(buildItem)
                )

                // copy 前：toStore 为空
                KVItems.checkAllCasesNil(in: toStoreCrypted, keyMap: { $0 + suffix })
                KVObjects.checkAllCasesNil(in: toStoreCrypted, keyMap: { $0 + suffix })
                conf.copyAll(to: toStoreCrypted)
                // copy 后：toStore 中有预期的数据
                KVItems.checkAllCases(in: toStoreCrypted, keyMap: { $0 + suffix })
                KVObjects.checkAllCases(in: toStoreCrypted, keyMap: { $0 + suffix })

            }

            // from: UserDefaults.suiteName("xxx")
            let validSuiteName = UUID().uuidString
            testSimpleItemsCrypted(suiteName: validSuiteName, from: .suiteName(validSuiteName))
        }

        // 暂时不支持加密的allValues迁移
        // keyMatcher: allValues - crypted
        // do {
        //     func testAllValues(suiteName: String, from: Config.From.UserDefaults) {
        //         toStore.clearAll()
        //
        //         let base = UDKVStore(suiteName: suiteName)!
        //         let cipher = KVCipherManager.shared.cipher(forSuite: .aes)!
        //         let fromStore = KVStoreCryptoProxy(wrapped: base, cipher: cipher)
        //         let prefix = UUID().uuidString
        //         let suffix = UUID().uuidString
        //         let keyMap = { (key: String) in prefix + key + suffix }
        //         KVItems.saveAllCases(in: fromStore, keyMap: keyMap)
        //         KVItems.checkAllCases(in: fromStore, keyMap: keyMap)
        //
        //         let conf = Config(
        //             from: .userDefaults(from),
        //             to: .udkv,
        //             keyMatcher: .allValues,
        //             cipher: cipher
        //         )
        //
        //         // copy 前：toStore 为空
        //         KVItems.checkAllCasesNil(in: toStore, keyMap: keyMap)
        //         conf.copyAll(to: toStore)
        //         KVItems.checkAllCases(in: toStore, keyMap: keyMap)
        //     }
        //
        //     // from: UserDefaults.suiteName("xxx")
        //     let validSuiteName = UUID().uuidString
        //     testAllValues(suiteName: validSuiteName, from: .suiteName(validSuiteName))
        // }
    }

    /// 测试 `KVMigrationConfig#copyAll(to:)` 接口，针对MMKV的部分
    /// 说明：
    ///   - 迁移配置里的 key-values 才会被 copy；没有注册进去的 key-values 不受影响
    func testCopyAllMMKV() {
        let toStore = KVStores.mmkv(space: .global, domain: classDomain).disposed(self)

        typealias Checker = () -> Void
        // 往 fromStore 里新增一些迁移配置之外的数据；
        // `copyAll` 操作对它们应该没有影响，也即 `copyAll(to: toStore)` 之后，toStore 里不应该有这些数据。
        // 不适用于 `KeyMatcher.allValues` 场景
        func checkExtraData(fromStore: KVStore) -> [Checker] {
            var checkers = [Checker]()

            let kv1 = (key: KVKey(UUID().uuidString, default: 0), val: 73)
            fromStore[kv1.key] = kv1.val
            checkers.append { XCTAssertFalse(toStore.contains(key: kv1.key)) }

            let kv2 = (key: KVKey(UUID().uuidString, default: ""), val: "73")
            fromStore[kv2.key] = kv2.val
            checkers.append { XCTAssertFalse(toStore.contains(key: kv2.key)) }

            return checkers
        }

        // keyMatcher: simpleItems
        do {
            toStore.clearAll()

            let mmapId = "simpleItems" + UUID().uuidString.prefix(5)
            guard let rootPath = KVStores.mmkvRootPath(with: .normal) else {
                XCTFail("failed to get mmkvRootPath")
                return
            }
            let fromStore = MMKVStore(mmapId: mmapId, rootPath: rootPath).disposed(self)

            KVItems.saveAllCases(in: fromStore)
            KVObjects.saveAllCases(in: fromStore)
            KVItems.checkAllCases(in: fromStore)
            KVObjects.checkAllCases(in: fromStore)

            let checkers = checkExtraData(fromStore: fromStore)
            defer { checkers.forEach { $0() } }

            let suffix = UUID().uuidString  // key 迁移：newKey = oldKey + suffix
            let buildItem = { (key, type: Any.Type) in
                KVMigrationConfig.KeyMatcher.SimpleItem(
                    oldKey: key, newKey: key + suffix, type: type as? KVMigrationValueType.Type
                )
            }
            let conf: Config = .from(
                mmkv: .custom(mmapId: mmapId, rootPath: rootPath),
                items: KVItems.mapWithKeyAndType(buildItem) + KVObjects.mapWithKeyAndType(buildItem)
            )

            // copy 前：toStore 为空
            KVItems.checkAllCasesNil(in: toStore, keyMap: { $0 + suffix })
            KVObjects.checkAllCasesNil(in: toStore, keyMap: { $0 + suffix })
            conf.copyAll(to: toStore)
            // copy 后：toStore 中有预期的数据
            KVItems.checkAllCases(in: toStore, keyMap: { $0 + suffix })
            KVObjects.checkAllCases(in: toStore, keyMap: { $0 + suffix })
        }

        // keyMatcher: prefixPattern
        do {
            toStore.clearAll()

            let mmapId = "prefixPattern" + UUID().uuidString
            guard let rootPath = KVStores.mmkvRootPath(with: .normal) else {
                XCTFail("failed to get mmkvRootPath")
                return
            }
            let fromStore = MMKVStore(mmapId: mmapId, rootPath: rootPath).disposed(self)

            let checkers = checkExtraData(fromStore: fromStore)
            defer { checkers.forEach { $0() } }

            func testKVItem<T: KVMigrationValueType>(_ item: KVItem<T>) {
                let prefix = item.key
                let newKeys = (0..<5).map { _ in UUID().uuidString }

                newKeys.forEach { newKey in
                    let oldKey = prefix + newKey
                    fromStore.set(item.value, forKey: oldKey)
                }

                let conf = Config.from(
                    mmkv: .custom(mmapId: mmapId, rootPath: rootPath),
                    dropPrefixPattern: prefix,
                    type: T.self
                )

                // copy 前：toStore 为空
                newKeys.forEach { newKey in
                    XCTAssertNil(toStore.value(forKey: newKey) as T?)
                }
                conf.copyAll(to: toStore)
                // copy 后：toStore 中有预期的数据
                newKeys.forEach { newKey in
                    XCTAssertNotNil(toStore.value(forKey: newKey) as T?)
                }
            }

            testKVItem(KVItems.bool)
            testKVItem(KVItems.int)
            testKVItem(KVItems.double)
            testKVItem(KVItems.float)
            testKVItem(KVItems.string)
            testKVItem(KVItems.data)

            func testKVObject<O: KVMigrationValueType>(_ item: KVObject<O>) {
                let prefix = item.key
                let newKeys = (0..<5).map { _ in UUID().uuidString }

                newKeys.forEach { newKey in
                    let oldKey = prefix + newKey
                    fromStore.setObject(item.object, forKey: oldKey)
                }

                let conf = Config.from(
                    mmkv: .custom(mmapId: mmapId, rootPath: rootPath),
                    dropPrefixPattern: prefix,
                    type: O.self
                )

                // copy 前：toStore 为空
                newKeys.forEach { newKey in
                    XCTAssertNil(toStore.object(forKey: newKey) as O?)
                }
                conf.copyAll(to: toStore)
                // copy 后：toStore 中有预期的数据
                newKeys.forEach { newKey in
                    let value = toStore.object(forKey: newKey) as O?
                    XCTAssertNotNil(value)
                }
            }

            testKVObject(KVObjects.array)
            testKVObject(KVObjects.dict)
//            testKVObject(KVObjects.product)
        }

        // keyMatcher: simpleItems - crypted
        let toStoreCrypted = toStore.usingCipher(suite: .aes)
        do {
            toStoreCrypted.clearAll()

            let mmapId = "simpleItemsCrypted" + UUID().uuidString
            guard let rootPath = KVStores.mmkvRootPath(with: .normal) else {
                XCTFail("failed to get mmkvRootPath")
                return
            }
            let base = MMKVStore(mmapId: mmapId, rootPath: rootPath).disposed(self)
            let cipher = KVCipherManager.shared.cipher(forSuite: .aes)!
            let fromStore = KVStoreCryptoProxy(wrapped: base, cipher: cipher)

            KVItems.saveAllCases(in: fromStore)
            KVObjects.saveAllCases(in: fromStore)
            KVItems.checkAllCases(in: fromStore)
            KVObjects.checkAllCases(in: fromStore)

            let checkers = checkExtraData(fromStore: fromStore)
            defer { checkers.forEach { $0() } }

            let suffix = UUID().uuidString  // key 迁移：newKey = oldKey + suffix
            let buildItem = { (key, type: Any.Type) in
                KVMigrationConfig.KeyMatcher.SimpleItem(
                    oldKey: key, newKey: key + suffix, type: type
                )
            }
            let conf: Config = .from(
                mmkv: .custom(mmapId: mmapId, rootPath: rootPath),
                cipherSuite: .aes,
                items: KVItems.mapWithKeyAndType(buildItem) + KVObjects.mapWithKeyAndType(buildItem)
            )

            // copy 前：toStore 为空
            KVItems.checkAllCasesNil(in: toStoreCrypted, keyMap: { $0 + suffix })
            KVObjects.checkAllCasesNil(in: toStoreCrypted, keyMap: { $0 + suffix })
            conf.copyAll(to: toStoreCrypted)
            // copy 后：toStore 中有预期的数据
            KVItems.checkAllCases(in: toStoreCrypted, keyMap: { $0 + suffix })
            KVObjects.checkAllCases(in: toStoreCrypted, keyMap: { $0 + suffix })
        }
        // keyMatcher: simpleItems - crypted - fromUserDefaults
        do {
            log.debug("start to test simpleItems - crypted - fromUserDefaults")
            func testSimpleItemsCrypted(suiteName: String, from: Config.From.UserDefaults) {
                toStoreCrypted.clearAll()

                let base = UDKVStore(suiteName: suiteName)!.disposed(self)
                let cipher = KVCipherManager.shared.cipher(forSuite: .aes)!
                let fromStore = KVStoreCryptoProxy(wrapped: base, cipher: cipher)
                KVItems.saveAllCases(in: fromStore)
                KVObjects.saveAllCases(in: fromStore)
                KVItems.checkAllCases(in: fromStore)
                KVObjects.checkAllCases(in: fromStore)

                let checkers = checkExtraData(fromStore: fromStore)
                defer { checkers.forEach { $0() } }

                let suffix = UUID().uuidString  // key 迁移：newKey = oldKey + suffix
                let buildItem = { key, type in
                    KVMigrationConfig.KeyMatcher.SimpleItem(oldKey: key, newKey: key + suffix, type: type)
                }
                let conf: Config = .from(
                    userDefaults: from,
                    to: .mmkv,
                    cipherSuite: .aes,
                    items: KVItems.mapWithKeyAndType(buildItem) + KVObjects.mapWithKeyAndType(buildItem)
                )

                // copy 前：toStore 为空
                KVItems.checkAllCasesNil(in: toStoreCrypted, keyMap: { $0 + suffix })
                KVObjects.checkAllCasesNil(in: toStoreCrypted, keyMap: { $0 + suffix })
                conf.copyAll(to: toStoreCrypted)
                // copy 后：toStore 中有预期的数据
                KVItems.checkAllCases(in: toStoreCrypted, keyMap: { $0 + suffix })
                KVObjects.checkAllCases(in: toStoreCrypted, keyMap: { $0 + suffix })

            }

            // from: UserDefaults.suiteName("xxx")
            let validSuiteName = UUID().uuidString
            testSimpleItemsCrypted(suiteName: validSuiteName, from: .suiteName(validSuiteName))
        }
    }

    /// 测试 `KVMigrationConfig#cleanAll()` 接口, 针对UDKV的部分
    /// 说明：
    ///   - 迁移配置里的 key-values 才会被清理；没有注册进去的 key-values 不受影响
    func testCleanAllUDKV() {
        typealias Checker = () -> Void

        // 往 store 里新增一些迁移配置之的数据，`cleanAll` 操作不应该对它们有影响，
        // 也即 `cleanAll` 后，这些数据仍然在；不适用于 `KeyMatcher.allValues` 场景
        func checkExtraData(store: KVStore) -> [Checker] {
            var checkers = [Checker]()

            let kv1 = (key: KVKey(UUID().uuidString, default: 0), val: 73)
            store[kv1.key] = kv1.val
            checkers.append { XCTAssert(store.contains(key: kv1.key) && store[kv1.key] == kv1.val) }

            let kv2 = (key: KVKey(UUID().uuidString, default: ""), val: "73")
            store[kv2.key] = kv2.val
            checkers.append { XCTAssert(store.contains(key: kv2.key) && store[kv2.key] == kv2.val) }

            return checkers
        }
        // keyMatcher: simpleItems
        do {
            func testSimpleItems(suiteName: String?, from: Config.From.UserDefaults) {
                let fromStore: KVStore
                if let suiteName {
                    fromStore = UDKVStore(suiteName: suiteName)!.disposed(self)
                } else {
                    fromStore = UDKVStore().disposed(self)
                }
                KVItems.saveAllCases(in: fromStore)
                KVObjects.saveAllCases(in: fromStore)
                KVItems.checkAllCases(in: fromStore)
                KVObjects.checkAllCases(in: fromStore)

                // 再存储一些值，不注册到 config 中，cleanAll 后，不受影响
                let extraCheckers = checkExtraData(store: fromStore)
                defer { extraCheckers.forEach { $0() } }

                let suffix = UUID().uuidString  // key 迁移：newKey = oldKey + suffix
                let buildItem = { $0 ~> ($0 + suffix) }
                Config.from(
                    userDefaults: from,
                    items: KVItems.allKeys.map(buildItem)  + KVObjects.allKeys.map(buildItem)
                ).cleanAll()
                KVItems.checkAllCasesNil(in: fromStore, keyMap: { $0 + suffix })
                KVObjects.checkAllCasesNil(in: fromStore, keyMap: { $0 + suffix })
            }

            // from: UserDefaults.standard
            testSimpleItems(suiteName: nil, from: .standard)

            // from: UserDefaults.suiteName("xxx")
            let validSuiteName = UUID().uuidString
            testSimpleItems(suiteName: validSuiteName, from: .suiteName(validSuiteName))

            // from: UserDefaults.suiteName("")
            let emptySuiteName = ""
            testSimpleItems(suiteName: emptySuiteName, from: .suiteName(emptySuiteName))

            // from: UserDefaults.appGroup("xxx")
            testSimpleItems(suiteName: Dependencies.appGroupId, from: .appGroup)
        }

        // keyMatcher: prefixPattern
        do {
            func testPrefixPattern(suiteName: String?, from: Config.From.UserDefaults) {
                let fromStore: KVStore
                if let suiteName {
                    fromStore = UDKVStore(suiteName: suiteName)!.disposed(self)
                } else {
                    fromStore = UDKVStore().disposed(self)
                }
                let prefix = UUID().uuidString
                let keyMap = { (key: String) in prefix + key }
                KVItems.saveAllCases(in: fromStore, keyMap: keyMap)
                KVObjects.saveAllCases(in: fromStore, keyMap: keyMap)
                KVItems.checkAllCases(in: fromStore, keyMap: keyMap)
                KVObjects.checkAllCases(in: fromStore, keyMap: keyMap)

                // 再存储一些值，不注册到 config 中，cleanAll 后，不受影响
                let extraCheckers = checkExtraData(store: fromStore)
                defer { extraCheckers.forEach { $0() } }

                Config.from(userDefaults: from, prefixPattern: prefix).cleanAll()
                KVItems.checkAllCasesNil(in: fromStore, keyMap: keyMap)
                KVObjects.checkAllCasesNil(in: fromStore, keyMap: keyMap)
            }

            // from: UserDefaults.standard
            testPrefixPattern(suiteName: nil, from: .standard)

            // from: UserDefaults.suiteName("xxx")
            let validSuiteName = UUID().uuidString
            testPrefixPattern(suiteName: validSuiteName, from: .suiteName(validSuiteName))

            // from: UserDefaults.suiteName("")
            let emptySuiteName = ""
            testPrefixPattern(suiteName: emptySuiteName, from: .suiteName(emptySuiteName))

            // from: UserDefaults.appGroup("xxx")
            testPrefixPattern(suiteName: Dependencies.appGroupId, from: .appGroup)
        }

        // keyMatcher: suffixPattern
        do {
            func testSuffixPattern(suiteName: String?, from: Config.From.UserDefaults) {
                let fromStore: KVStore
                if let suiteName {
                    fromStore = UDKVStore(suiteName: suiteName)!.disposed(self)
                } else {
                    fromStore = UDKVStore().disposed(self)
                }
                let suffix = UUID().uuidString
                let keyMap = { (key: String) in key + suffix }
                KVItems.saveAllCases(in: fromStore, keyMap: keyMap)
                KVObjects.saveAllCases(in: fromStore, keyMap: keyMap)
                KVItems.checkAllCases(in: fromStore, keyMap: keyMap)
                KVObjects.checkAllCases(in: fromStore, keyMap: keyMap)

                // 再存储一些值，不注册到 config 中，cleanAll 后，不受影响
                let extraCheckers = checkExtraData(store: fromStore)
                defer { extraCheckers.forEach { $0() } }

                Config.from(userDefaults: from, suffixPattern: suffix).cleanAll()
                KVItems.checkAllCasesNil(in: fromStore, keyMap: keyMap)
                KVObjects.checkAllCasesNil(in: fromStore, keyMap: keyMap)
            }

            // from: UserDefaults.standard
            testSuffixPattern(suiteName: nil, from: .standard)

            // from: UserDefaults.suiteName("xxx")
            let validSuiteName = UUID().uuidString
            testSuffixPattern(suiteName: validSuiteName, from: .suiteName(validSuiteName))

            // from: UserDefaults.suiteName("")
            let emptySuiteName = ""
            testSuffixPattern(suiteName: emptySuiteName, from: .suiteName(emptySuiteName))

            // from: UserDefaults.appGroup("xxx")
            testSuffixPattern(suiteName: Dependencies.appGroupId, from: .appGroup)
        }

        // keyMatcher: allValues
        do {
            func testAllValues(suiteName: String?, from: Config.From.UserDefaults, expectFail: Bool) {
                let fromStore: KVStore
                if let suiteName {
                    fromStore = UDKVStore(suiteName: suiteName)!.disposed(self)
                } else {
                    fromStore = UDKVStore().disposed(self)
                }
                let prefix = UUID().uuidString
                let suffix = UUID().uuidString
                let keyMap = { (key: String) in prefix + key + suffix }
                KVItems.saveAllCases(in: fromStore, keyMap: keyMap)
                KVObjects.saveAllCases(in: fromStore, keyMap: keyMap)
                KVItems.checkAllCases(in: fromStore, keyMap: keyMap)
                KVObjects.checkAllCases(in: fromStore, keyMap: keyMap)

                Config(from: .userDefaults(from), to: .udkv, keyMatcher: .allValues).cleanAll()
                if expectFail { // 清除失败
                    KVItems.checkAllCases(in: fromStore, keyMap: keyMap)
                    KVObjects.checkAllCases(in: fromStore, keyMap: keyMap)
                } else {        // 清除成功
                    KVItems.checkAllCasesNil(in: fromStore, keyMap: keyMap)
                    KVObjects.checkAllCasesNil(in: fromStore, keyMap: keyMap)
                }
            }

            // from: UserDefaults.standard
            testAllValues(suiteName: nil, from: .standard, expectFail: true)

            // from: UserDefaults.suiteName("xxx")
            let validSuiteName = UUID().uuidString
            testAllValues(suiteName: validSuiteName, from: .suiteName(validSuiteName), expectFail: false)
            // plist 文件预期也会被清理掉
            let plistPath = AbsPath.library + "Preferences/\(validSuiteName).plist"
            XCTAssertFalse(plistPath.exists)

            // from: UserDefaults.suiteName("")
            let emptySuiteName = ""
            testAllValues(suiteName: emptySuiteName, from: .suiteName(emptySuiteName), expectFail: true)

            // from: UserDefaults.appGroup
            testAllValues(suiteName: Dependencies.appGroupId, from: .appGroup, expectFail: true)
        }
    }

    /// 测试 `KVMigrationConfig#cleanAll()` 接口, 针对MMKV的部分
    /// 说明：
    ///   - 迁移配置里的 key-values 才会被清理；没有注册进去的 key-values 不受影响
    func testCleanAllMMKV() {
        typealias Checker = () -> Void

        // 往 store 里新增一些迁移配置之的数据，`cleanAll` 操作不应该对它们有影响，
        // 也即 `cleanAll` 后，这些数据仍然在；不适用于 `KeyMatcher.allValues` 场景
        func checkExtraData(store: KVStore) -> [Checker] {
            var checkers = [Checker]()

            let kv1 = (key: KVKey(UUID().uuidString, default: 0), val: 73)
            store[kv1.key] = kv1.val
            checkers.append { XCTAssert(store.contains(key: kv1.key) && store[kv1.key] == kv1.val) }

            let kv2 = (key: KVKey(UUID().uuidString, default: ""), val: "73")
            store[kv2.key] = kv2.val
            checkers.append { XCTAssert(store.contains(key: kv2.key) && store[kv2.key] == kv2.val) }

            return checkers
        }
        // keyMatcher: simpleItems
        do {
            let mmapId = "simpleItems" + UUID().uuidString
            guard let rootPath = KVStores.mmkvRootPath(with: .normal) else {
                XCTFail("failed to get mmkvRootPath")
                return
            }
            let fromStore = MMKVStore(mmapId: mmapId, rootPath: rootPath).disposed(self)

            KVItems.saveAllCases(in: fromStore)
            KVObjects.saveAllCases(in: fromStore)
            KVItems.checkAllCases(in: fromStore)
            KVObjects.checkAllCases(in: fromStore)

            // 再存储一些值，不注册到 config 中，cleanAll 后，不受影响
            let extraCheckers = checkExtraData(store: fromStore)
            defer { extraCheckers.forEach { $0() } }

            let suffix = UUID().uuidString  // key 迁移：newKey = oldKey + suffix
            let buildItem = { (key: String, type: Any.Type) in
                KVMigrationConfig.KeyMatcher.SimpleItem(
                    oldKey: key, newKey: key + suffix, type: type
                )
            }
            Config.from(
                mmkv: .custom(mmapId: mmapId, rootPath: rootPath),
                items: KVItems.mapWithKeyAndType(buildItem) + KVObjects.mapWithKeyAndType(buildItem)
            ).cleanAll()

            KVItems.checkAllCasesNil(in: fromStore, keyMap: { $0 + suffix })
            KVObjects.checkAllCasesNil(in: fromStore, keyMap: { $0 + suffix })
        }

        // keyMatcher: prefixPattern
        do {
            let mmapId = "prefixPattern" + UUID().uuidString
            guard let rootPath = KVStores.mmkvRootPath(with: .normal) else {
                XCTFail("failed to get mmkvRootPath")
                return
            }
            let fromStore = MMKVStore(mmapId: mmapId, rootPath: rootPath).disposed(self)

            // 再存储一些值，不注册到 config 中，cleanAll 后，不受影响
            let extraCheckers = checkExtraData(store: fromStore)
            defer { extraCheckers.forEach { $0() } }

            func testKVItem<T: KVMigrationValueType>(_ item: KVItem<T>) {
                let prefix = item.key
                let newKeys = (0..<5).map { _ in UUID().uuidString }

                newKeys.forEach { newKey in
                    let oldKey = prefix + newKey
                    fromStore.set(item.value, forKey: oldKey)
                }

                Config.from(
                    mmkv: .custom(mmapId: mmapId, rootPath: rootPath),
                    prefixPattern: prefix,
                    type: Data.self
                ).cleanAll()

                newKeys.forEach { newKey in
                    XCTAssertNil(fromStore.value(forKey: newKey) as Data?)
                }
            }

            testKVItem(KVItems.bool)
            testKVItem(KVItems.int)
            testKVItem(KVItems.double)
            testKVItem(KVItems.float)
            testKVItem(KVItems.string)
            testKVItem(KVItems.data)
        }
    }
}
