//
//  KVMigrateTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage
@testable import LarkStorageAssembly

class KVMigrationProxyTests: KVMigrationTestCase {

    static var oldEnableAssertionFailure = false
    static var oldEnableCache = false

    override class func setUp() {
        super.setUp()
        // 将 assertionFailure 给关掉，避免 block 测试流程
        oldEnableAssertionFailure = AssertReporter.enableAssertionFailure
        oldEnableCache = KVMigrationTaskManager.shared.enableCache
        AssertReporter.enableAssertionFailure = false
        KVMigrationTaskManager.shared.enableCache = false
    }

    override class func tearDown() {
        AssertReporter.enableAssertionFailure = oldEnableAssertionFailure
        KVMigrationTaskManager.shared.enableCache = oldEnableCache
    }

    func testSimpleSync() {
        let domain = classDomain.child("TestSimple").uuidChild()
        let storeConf = KVStoreConfig(space: .global, domain: domain, type: .mmkv)
        let (oldKey, newKey) = ("old_answer", "new_answer")
        let migConf = KVMigrationConfig(
            from: .userDefaults(.suiteName(UUID().uuidString)),
            to: storeConf.type,
            keyMatcher: .simple([oldKey ~> newKey])
        )
        let fromStore = migConf.safeFromStore()!.disposed(self)
        fromStore[oldKey] = 42

        // test contains(key:)/value(forKey:)
        // 注册迁移前，toStore 不含有旧数据
        XCTAssertFalse(KVStores.store(with: storeConf).disposed(self).contains(key: newKey))

        Registry.registerMigration(forDomain: domain) { space in
            guard case storeConf.space = space else { return [] }
            return [migConf]
        }
        let toStore = KVStores.store(with: storeConf).disposed(self)
        XCTAssert(toStore.contains(key: newKey))
        XCTAssert(toStore.integer(forKey: newKey) == 42)

        // 修改 toStore 的值，fromStore 的值也跟着同步
        toStore[newKey] = 43
        XCTAssert(fromStore[oldKey] == 43)

        // 移除 toStore 的值，fromStore 的值也没了
        toStore.removeValue(forKey: newKey)
        XCTAssertFalse(fromStore.contains(key: oldKey))

        // 给 toStore 重新赋值，fromStore 的值也有了
        toStore[newKey] = 73
        XCTAssert(fromStore[oldKey] == 73)
    }

    /// 测试 value(forKey:)/contains(key:)/allValues 接口
    func testGetValue() {
        let userSpace = Space.randomUser()
        let baseDomain = classDomain.randomChild()

        typealias Params = (from: KVMigrationConfig.From, to: KVStoreConfig)
        let genParams = { () -> [Params] in
            let froms: [KVMigrationConfig.From] = [
                .userDefaults(.suiteName(UUID().uuidString)),
                .userDefaults(.standard),
                .userDefaults(.appGroup)
            ]
            return froms
                .flatMap { from -> [(KVMigrationConfig.From, KVStoreType)] in
                    // 进程共享暂时不支持 MMKV
                    if from == .userDefaults(.appGroup) {
                        return [(from, .udkv)]
                    } else {
                        return [(from, .udkv), (from, .mmkv)]
                    }
                }
                .flatMap { (from, type) -> [(KVMigrationConfig.From, KVStoreConfig)] in
                    let genDomain: () -> Domain = { baseDomain.uuidChild() }
                    let mode: KVStoreMode = (from == .userDefaults(.appGroup)) ? .shared : .normal
                    return [
                        // (from, .init(space: .global, domain: genDomain(), mode: mode, type: type)),
                        (from, .init(space: userSpace, domain: genDomain(), mode: mode, type: type))
                    ]
                }
        }

        // keyMatcher: simpleItems
        do {
            func testSimpleItems(from: KVMigrationConfig.From, to: KVStoreConfig) {
                let fromPrefix = UUID().uuidString  // 隔离单测间数据：oldKey = prefix + rawKey
                let toSuffix = UUID().uuidString  // key 迁移：newKey = rawKey + suffix

                let buildItem = { (fromPrefix + $0) ~> ($0 + toSuffix) }
                let conf = KVMigrationConfig(
                    from: from,
                    to: to.type,
                    keyMatcher: .simple(
                        KVItems.allKeys.map(buildItem) + KVObjects.allKeys.map(buildItem)
                    )
                )
                // 1. prepare data
                guard let fromStore = conf.safeFromStore()?.disposed(self) else { return }
                let fromKeyMap = { (key: String) in fromPrefix + key }
                KVItems.saveAllCases(in: fromStore, keyMap: fromKeyMap)
                KVObjects.saveAllCases(in: fromStore, keyMap: fromKeyMap)
                KVItems.checkAllCases(in: fromStore, keyMap: fromKeyMap)
                KVObjects.checkAllCases(in: fromStore, keyMap: fromKeyMap)

                let toKeyMap: KeyMap = { $0 + toSuffix }

                // 2. check before registering migration
                //    fromStore 中的数据无法从 toStore 中取到
                var toStore = KVStores.store(with: to).disposed(self)
                KVItems.checkAllCasesNil(in: toStore, keyMap: toKeyMap)
                KVObjects.checkAllCasesNil(in: toStore, keyMap: toKeyMap)

                // 3. do register migration
                Registry.registerMigration(forDomain: to.domain) { space in
                    guard space == to.space else { return [] }
                    return [conf]
                }

                // 4. check after registering migration
                //    fromStore 中的数据可从 toStore 中取到
                toStore = KVStores.store(with: to).disposed(self)
                KVItems.checkAllCases(in: toStore, keyMap: toKeyMap)
                KVObjects.checkAllCases(in: toStore, keyMap: toKeyMap)
            }

            for param in genParams() {
                testSimpleItems(from: param.from, to: param.to)
            }
        }

        // keyMatcher: prefixPattern
        do {
            func testPrefixPattern(from: KVMigrationConfig.From, to: KVStoreConfig) {
                let prefix = UUID().uuidString
                let keyMap: KeyMap = { prefix + $0 }

                let conf = KVMigrationConfig(
                    from: from,
                    to: to.type,
                    keyMatcher: .prefix(pattern: prefix)
                )
                // 1. prepare data
                guard let fromStore = conf.safeFromStore()?.disposed(self) else { return }
                KVItems.saveAllCases(in: fromStore, keyMap: keyMap)
                KVObjects.saveAllCases(in: fromStore, keyMap: keyMap)
                KVItems.checkAllCases(in: fromStore, keyMap: keyMap)
                KVObjects.checkAllCases(in: fromStore, keyMap: keyMap)

                // 2. check before registering migration
                //    fromStore 中的数据无法从 toStore 中取到
                var toStore = KVStores.store(with: to).disposed(self)
                KVItems.checkAllCasesNil(in: toStore, keyMap: keyMap)
                KVObjects.checkAllCasesNil(in: toStore, keyMap: keyMap)

                // 3. do register migration
                Registry.registerMigration(forDomain: to.domain) { space in
                    guard space == to.space else { return [] }
                    return [conf]
                }

                // 4. check after registering migration
                //    fromStore 中的数据可从 toStore 中取到
                toStore = KVStores.store(with: to).disposed(self)
                KVItems.checkAllCases(in: toStore, keyMap: keyMap)
                KVObjects.checkAllCases(in: toStore, keyMap: keyMap)
            }

            for param in genParams() {
                testPrefixPattern(from: param.from, to: param.to)
            }
        }

        // keyMatcher: simpleItems - crypted
        do {
            log.debug("start to test simpleItems - crypted")
            func testSimpleItems(from: KVMigrationConfig.From, to: KVStoreConfig) {
                let suffix = String(UUID().uuidString.prefix(5))  // key 迁移：newKey = oldKey + suffix

                let cipher = KVCipherManager.shared.cipher(forSuite: .aes)!
                let buildItem = { key, type in
                    KVMigrationConfig.KeyMatcher.SimpleItem(oldKey: key, newKey: key + suffix, type: type)
                }
                let conf = KVMigrationConfig(
                    from: from,
                    to: to.type,
                    keyMatcher: .simple(
                        KVItems.mapWithKeyAndType(buildItem) + KVObjects.mapWithKeyAndType(buildItem)
                    ),
                    cipherSuite: .aes
                )
                // 1. prepare data
                guard let fromStore = conf.safeFromStore()?.disposed(self) else { return }
                let fromStoreCrypted = KVStoreCryptoProxy(wrapped: fromStore, cipher: cipher)
                KVItems.saveAllCases(in: fromStoreCrypted)
                KVObjects.saveAllCases(in: fromStoreCrypted)
                KVItems.checkAllCases(in: fromStoreCrypted)
                KVObjects.checkAllCases(in: fromStoreCrypted)

                let keyMap: KeyMap = { $0 + suffix }

                // 2. check before registering migration
                //    fromStore 中的数据无法从 toStore 中取到
                var toStore = KVStores.store(with: to).disposed(self).usingCipher(suite: .aes)

                KVItems.checkAllCasesNil(in: toStore, keyMap: keyMap)
                KVObjects.checkAllCasesNil(in: toStore, keyMap: keyMap)

                // 3. do register migration
                Registry.registerMigration(forDomain: to.domain) { space in
                    guard space == to.space else { return [] }
                    return [conf]
                }

                // 4. check after registering migration
                //    fromStore 中的数据可从 toStore 中取到
                toStore = KVStores.store(with: to).disposed(self).usingCipher(suite: .aes)
                let context = "from: \(from), to: \(to)"
                KVItems.checkAllCases(in: toStore, keyMap: keyMap, context: context)
                KVObjects.checkAllCases(in: toStore, keyMap: keyMap, context: context)
            }

            for param in genParams() {
                testSimpleItems(from: param.from, to: param.to)
            }
        }
    }

    // 测试 `usingMigration` 挂载单个配置和多个配置是否正常
    func testUsingMigration() {
        let domain = classDomain.funcChild().uuidChild()

        // test single config
        do {
            let value = UUID().uuidString
            let oldKey = String(UUID().uuidString.prefix(7))
            let newKey = String(UUID().uuidString.prefix(7))

            // prepare data
            let config: KVMigrationConfig =
                .from(userDefaults: .suiteName(UUID().uuidString), items: [
                    .init(oldKey: oldKey, newKey: newKey)
                ])
            let fromStore = config.safeFromStore()?.disposed(self)
            XCTAssertNotNil(fromStore)
            if let fromStore {
                fromStore.set(value, forKey: oldKey)
            }
            // test data
            let store = KVStores
                .udkv(space: .global, domain: domain)
                .usingMigration(config: config, strategy: .move)
                .disposed(self)
            let testValue: String? = store.value(forKey: newKey)
            XCTAssert(testValue == value)
        }

        // test multiple configs
        do {
            // prepare data
            let keyValues = (0..<10).map { _ in
                let oldKey = String(UUID().uuidString.prefix(7))
                let newKey = String(UUID().uuidString.prefix(7))
                let value = UUID().uuidString
                return (oldKey, newKey, value)
            }
            let configs: [KVMigrationConfig] = keyValues.map { (oldKey, newKey, value) in
                // set old data
                let conf = KVMigrationConfig.from(
                    userDefaults: .suiteName(UUID().uuidString),
                    items: [oldKey ~> newKey]
                )
                conf.safeFromStore()?.disposed(self).set(value, forKey: oldKey)
                return conf
            }
            // test data
            let store = KVStores.udkv(space: .global, domain: domain)
                .usingMigration(configs: configs, strategy: .sync)
                .disposed(self)
            keyValues.forEach { (_, newKey, value) in
                XCTAssertEqual(store.value(forKey: newKey), value)
            }
        }
    }

    // 测试 `usingMigration` merge 模式下的功能性和并发性
    func _testUsingMigrationWithMerge() {
        let keyValues = (0..<500).map { _ in
            let oldKey = String(UUID().uuidString.prefix(7))
            let newKey = String(UUID().uuidString.prefix(7))
            let value = UUID().uuidString
            return (oldKey, newKey, value)
        }

        // prepare data
        for (oldKey, _, value) in keyValues {
            UserDefaults.standard.set(value, forKey: oldKey)
        }

        let group = DispatchGroup()
        let exp = expectation(description: "usingMigration(configs:strategy:shouldMerge:)")

        let domain = classDomain.uuidChild()
        let store = KVStores.udkv(space: .global, domain: domain).disposed(self)

        let begin = CFAbsoluteTimeGetCurrent()
        for (oldKey, newKey, expectValue) in keyValues {
            // test data
            DispatchQueue.global().async(group: group) {
                store.usingMigration(
                    config: .from(userDefaults: .standard, items: [oldKey ~> newKey]),
                    shouldMerge: true
                )
                let value = store.string(forKey: newKey)
                XCTAssertEqual(value, expectValue)
            }
        }

        group.notify(queue: DispatchQueue.main) {
            exp.fulfill()
        }
        self.wait(for: [exp], timeout: 80)
        let cost = CFAbsoluteTimeGetCurrent() - begin
        log.debug("\(typeName) testAppendingMigration costing: \(cost) s")

        // clear data
        for (oldKey, _, _) in keyValues {
            UserDefaults.standard.removeObject(forKey: oldKey)
        }
    }

    // 测试 `clearMigrationMarks` 的功能性和并发性
    func _testClearMigrationMarks() throws {
        let suiteName = String(UUID().uuidString.prefix(5))
        let domain = classDomain.funcChild().child(suiteName)
        let key = String(UUID().uuidString.prefix(7))
        let value = UUID().uuidString
        let cryptoSuiteName = String(UUID().uuidString.prefix(5))
        let cryptoKey = String(UUID().uuidString.prefix(7))
        let cryptoValue = UUID().uuidString

        // 准备加密套件
        guard let cipher = KVCipherManager.shared.cipher(forSuite: .aes) else {
            XCTFail("failed to obtain cipher")
            return
        }
        let cryptoKeyHashed = cipher.hashed(forKey: cryptoKey)
        let cryptoValueCrypted = try cipher.encrypt(try cipher.encode(value: cryptoValue))

        // 1. 首先 UserDefaults 设置数据，并且 toStore 目前读不出该值
        let userDefaults = UserDefaults(suiteName: suiteName)!
        let cryptoUserDefaults = UserDefaults(suiteName: cryptoSuiteName)!

        userDefaults.set(value, forKey: key)
        cryptoUserDefaults.set(cryptoValueCrypted, forKey: cryptoKeyHashed)
        var toStore = KVStores.udkv(space: .global, domain: domain).disposed(self)
        var cryptoToStore = KVStores.mmkv(space: .global, domain: domain).disposed(self).usingCipher(suite: .aes)
        XCTAssertNil(toStore.string(forKey: key))
        XCTAssertNil(cryptoToStore.string(forKey: cryptoKey))

        // 2. 注册迁移配置
        Registry.registerMigration(forDomain: domain) { space in
            guard space == .global else { return [] }
            return [
                .from(userDefaults: .suiteName(suiteName), items: [
                    .init(key: key)
                ]),
                .from(
                    userDefaults: .suiteName(cryptoSuiteName),
                    to: .mmkv,
                    cipherSuite: .aes,
                    items: [
                        .init(key: cryptoKey)
                    ]
                )
            ]
        }

        // 重新创建 KVStore，触发迁移配置的读取
        toStore = KVStores.udkv(space: .global, domain: domain).disposed(self)
        cryptoToStore = KVStores.mmkv(space: .global, domain: domain).disposed(self).usingCipher(suite: .aes)

        // 强制开启 clearMigrationMarks 的优化
        guard let migrateProxy: KVStoreMigrateProxy = toStore.findProxy(),
              let cryptoMigrateProxy: KVStoreMigrateProxy = cryptoToStore.findProxy()
        else {
            XCTFail()
            return
        }

        // 3. 首先正常触发一次迁移
        XCTAssertEqual(toStore.string(forKey: key), value)
        XCTAssertEqual(cryptoToStore.string(forKey: cryptoKey), cryptoValue)

        // 4. UserDefaults 写入新值，此时 toStore 无法读出该值
        let newValue = UUID().uuidString
        let cryptoNewValue = UUID().uuidString
        let cryptoNewValueCrypted = try cipher.encrypt(try cipher.encode(value: cryptoNewValue))
        userDefaults.set(newValue, forKey: key)
        cryptoUserDefaults.set(cryptoNewValueCrypted, forKey: cryptoKeyHashed)

        XCTAssertNotEqual(toStore.string(forKey: key), newValue)
        XCTAssertNotEqual(cryptoToStore.string(forKey: cryptoKey), cryptoNewValue)

        // 5. 测试并发 clearMigrationMarks
        let begin = CFAbsoluteTimeGetCurrent()
        let exp = expectation(description: "KVConfigTests#int")
        let dispatchGroup = DispatchGroup()
        for _ in 0..<500 {
            DispatchQueue.global().async(group: dispatchGroup) {
                toStore.clearMigrationMarks()
                cryptoToStore.clearMigrationMarks()
                guard let helper = migrateProxy.syncHelper,
                      let cryptoHelper = cryptoMigrateProxy.syncHelper
                else {
                    XCTFail()
                    return
                }
                // 确认状态被修改为 rollback
                XCTAssertEqual(helper.task.status.value, .rollback)
                XCTAssertEqual(cryptoHelper.task.status.value, .rollback)
            }
        }
        dispatchGroup.notify(queue: .main) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 20)
        let cost = CFAbsoluteTimeGetCurrent() - begin
        log.debug("\(typeName) test costing: \(cost) s")

        // 6. 此时 toStore 可以重新迁移，并且 task 状态被修改回非 rollback
        let result = toStore.string(forKey: key)
        let cryptoResult = cryptoToStore.string(forKey: cryptoKey)
        XCTAssertEqual(result, newValue)
        XCTAssertEqual(cryptoResult, cryptoNewValue)
        guard let helper = migrateProxy.syncHelper,
              let cryptoHelper = cryptoMigrateProxy.syncHelper
        else {
            XCTFail()
            return
        }

        XCTAssertNotEqual(helper.task.status.value, .rollback)
        XCTAssertNotEqual(cryptoHelper.task.status.value, .rollback)

        // 结束后清除数据
        try? UserDefaults.removeFile(userDefaults, suiteName: suiteName)
        try? UserDefaults.removeFile(cryptoUserDefaults, suiteName: cryptoSuiteName)
    }

    // 测试针对整个 domain 的 clearMigrationMarks
    // TODO: 该单测会被其他单测的数据干扰，先屏蔽，暂时没想到好的优化方案
    func _testClearMigrationMarksForAllSpace() throws {
        // 1. 准备一些 domain，生成一些 space
        let primarySuiteNames = (0..<3).map { _ in String(UUID().uuidString.prefix(7)) }
        let cryptoSuiteNames = (0..<3).map { _ in String(UUID().uuidString.prefix(7)) }
        let otherSuiteNames = (0..<3).map { _ in String(UUID().uuidString.prefix(7)) }

        let primaryUserDefaults = primarySuiteNames.map { UserDefaults(suiteName: $0)! }
        let cryptoUserDefaults = cryptoSuiteNames.map { UserDefaults(suiteName: $0)! }
        let otherUserDefaults = otherSuiteNames.map { UserDefaults(suiteName: $0)! }

        let spaces = [Space.global] + (0..<3).map { _ in Space.uuidUser(type: typeName) }
        let primaryDomains = primarySuiteNames.map { classDomain.funcChild().child($0) }
        let cryptoDomains = cryptoSuiteNames.map { classDomain.funcChild().child($0) }
        let otherDomains = otherSuiteNames.map { classDomain.funcChild().child($0) }

        let primaryStores = primaryDomains.flatMap { domain in spaces.flatMap { space in
            [
                KVStores.udkv(space: space, domain: domain).disposed(self),
                KVStores.mmkv(space: space, domain: domain).disposed(self),
            ]
        }}
        let cryptoStores = cryptoDomains.flatMap { domain in spaces.flatMap { space in
            [
                KVStores.udkv(space: space, domain: domain).disposed(self).usingCipher(suite: .aes),
                KVStores.mmkv(space: space, domain: domain).disposed(self).usingCipher(suite: .aes),
            ]
        }}
        let otherStores = otherDomains.flatMap { domain in spaces.flatMap { space in
            [
                KVStores.udkv(space: space, domain: domain).disposed(self),
                KVStores.mmkv(space: space, domain: domain).disposed(self),
            ]
        }}

        // 2. 注册迁移
        let key = String(UUID().uuidString.prefix(7))
        for (suiteName, domain) in zip(primarySuiteNames + otherSuiteNames, primaryDomains + otherDomains) {
            Registry.registerMigration(forDomain: domain) { space in
                [
                    .from(userDefaults: .suiteName(suiteName), items: [.init(key: key)]),
                    .from(userDefaults: .suiteName(suiteName), to: .mmkv, items: [.init(key: key)])
                ]
            }
        }
        for (suiteName, domain) in zip(cryptoSuiteNames, cryptoDomains) {
            Registry.registerMigration(forDomain: domain) { space in
                [
                    .from(userDefaults: .suiteName(suiteName), cipherSuite: .aes, items: [.init(key: key)]),
                    .from(userDefaults: .suiteName(suiteName), to: .mmkv, cipherSuite: .aes, items: [.init(key: key)])
                ]
            }
        }

        // 3. 准备旧数据
        let oldValue = UUID().uuidString
        for userDefaults in (primaryUserDefaults + otherUserDefaults) {
            userDefaults.set(oldValue, forKey: key)
        }
        // 3.1 准备旧的加密数据
        let cipher = KVCipherManager.shared.cipher(forSuite: .aes)!
        let hashedKey = cipher.hashed(forKey: key)
        let cryptedOldValue = try cipher.encrypt(try cipher.encode(value: oldValue))
        for userDefaults in cryptoUserDefaults {
            userDefaults.set(cryptedOldValue, forKey: hashedKey)
        }

        // 4. 确定能够正常迁移
        for store in (primaryStores + cryptoStores + otherStores) {
            XCTAssertEqual(store.value(forKey: key), oldValue)
        }

        // 5. 清除迁移标记
        primaryDomains.forEach(KVStores.clearMigrationMarks(forDomain:))
        cryptoDomains.forEach(KVStores.clearMigrationMarks(forDomain:))

        // 6. 准备新数据
        let newValue = UUID().uuidString
        for userDefaults in (primaryUserDefaults + otherUserDefaults) {
            userDefaults.set(newValue, forKey: key)
        }
        // 6.1 准备新的加密数据
        let cryptedNewValue = try cipher.encrypt(try cipher.encode(value: newValue))
        for userDefaults in cryptoUserDefaults {
            userDefaults.set(cryptedNewValue, forKey: hashedKey)
        }

        // 7. 确定清除迁移标记的 domain 能够重新迁移，其他 domain 不受影响
        for store in primaryStores + cryptoStores {
            XCTAssertEqual(store.value(forKey: key), newValue)
        }
        for store in otherStores {
            XCTAssertEqual(store.value(forKey: key), oldValue)
        }

        // 8. 结束后清除数据
        // 清除 UserDefaults
        try? zip(
            primaryUserDefaults + cryptoUserDefaults + otherUserDefaults,
            primarySuiteNames + cryptoSuiteNames + otherSuiteNames
        ).forEach(UserDefaults.removeFile(_:suiteName:))
    }

}
