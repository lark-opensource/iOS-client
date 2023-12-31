//
//  KVStoreMigrateProxy.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import EEAtomic

// 每完成一个 key 的迁移，就往 store 里添加一条记录，该记录的 key = key + migratedSuffix
let migratedSuffix = ".migrated_in_lark_storage"

/// Migrate Proxy
final class KVStoreMigrateProxy: KVStoreProxy {
    static var type: KVStoreProxyType { .migrate }
    var wrapped: KVStore
    private let config: KVStoreConfig

    // 由全局配置扫描而来的迁移数据源
    @SafeLazy private var sharedSyncHelper: KVStoreMigrateSyncHelper?
    // 手动配置的迁移数据源
    @AtomicObject private var customSyncHelper: KVStoreMigrateSyncHelper?

    internal var disabled = false

    // 若没有自定义的数据源，则使用全局配置的数据源
    internal var syncHelper: KVStoreMigrateSyncHelper? {
        guard !disabled else { return nil }
        return customSyncHelper ?? sharedSyncHelper
    }

    init(wrapped: KVStore, config: KVStoreConfig) {
        self.config = config
        self.wrapped = wrapped
        self._sharedSyncHelper = SafeLazy {
            KVMigrationTaskManager.shared
                .task(forSeed: config)
                .map(KVStoreMigrateSyncHelper.init)
        }
    }

    // 手动设置迁移配置（不从注册逻辑读取），适合动态场景或启动时对启动性能敏感
    // shouldMerge 参数表示是否和之前的配置合并
    func configCustom(
        _ configs: [KVMigrationConfig],
        strategy: KVMigrationStrategy,
        shouldMerge: Bool
    ) {
        // 取出 task ，合并后构建新的 syncHelper，该操作需要保证原子性
        $customSyncHelper.withLocking { helper in
            var configs = configs
            if shouldMerge, let task = helper?.task {
                KVStores.assert(
                    task.strategy == strategy,
                    "appending different strategy, domain: \(config.domain)",
                    event: .migration
                )
                configs = KVMigrationRegistry.mergeConfigs(task.configs, configs)
            }
            helper = .init(task: KVMigrationTask(
                seed: config, strategy: strategy, configs: configs
            ))
        }
    }

    // 是否已经迁移
    private func hasMigrated(forKey key: String) -> Bool {
        return wrapped.contains(key: key + migratedSuffix)
    }

    // 标记迁移
    private func setMigrated(forKey key: String) {
        wrapped.set(true, forKey: key + migratedSuffix)
    }

    // MARK: KVStore

    func value<T: Codable>(forKey key: String) -> T? {
        guard let source = syncHelper?.syncSource(forKey: key) else {
            return wrapped.value(forKey: key)
        }

        if !hasMigrated(forKey: key) {
            // do migrate by coping
            // 若 source 存在 cipher，则直接平移底层 Data
            if let oldCipher = source.cipher, let data: Data = source.value() {
                self.setRaw(data: data, forKey: key, oldCipher: oldCipher)
                trackEffectiveMigration(scene: .getValue)
            } else if let v: T = source.value() {
                wrapped.set(v, forKey: key)
                trackEffectiveMigration(scene: .getValue)
            } else {
                // 防御：可能出现 FG 回退时写入了 nil(或删除了key) 的场景
                // 这样写可以保证重新迁移后与旧存储始终一致
                wrapped.removeValue(forKey: key)
            }
            setMigrated(forKey: key)
            log.info("finish migrating \(KVStoreLogProxy.encoded(for: key))")
        } else {
            log.info("\(KVStoreLogProxy.encoded(for: key)) has already be migrated")
        }

        return wrapped.value(forKey: key)
    }

    func set<T: Codable>(_ value: T, forKey key: String) {
        wrapped.set(value, forKey: key)

        // 同步数据到 migration from 中
        if let syncHelper, let source = syncHelper.syncSource(forKey: key) {
            // .move 策略不需要回写数据
            if syncHelper.task.strategy == .sync {
                // 若 source 存在 cipher，则直接读取底层 Data 并回写
                if let oldCipher = source.cipher {
                    source.set(self.rawData(forKey: key, oldCipher: oldCipher))
                } else {
                    source.set(value)
                }
            }
            // 但是 .move 策略需要设置迁移标记，否则下次读取会从 from 里读
            setMigrated(forKey: key)
            log.info("sync set: \(KVStoreLogProxy.encoded(for: key))")
        }
    }

    func object<O: NSCodingObject>(forKey key: String) -> O? {
        guard let source = syncHelper?.syncSource(forKey: key) else {
            return _forward_get_object(to: wrapped, forKey: key)
        }

        if !hasMigrated(forKey: key) {
            // do migrate by coping
            if let oldCipher = source.cipher, let data: Data = source.value() {
                self.setRaw(data: data, forKey: key, oldCipher: oldCipher)
                trackEffectiveMigration(scene: .getValue)
            } else if let obj: O = source.object() {
                _forward_set_object(to: wrapped, forKey: key, object: obj)
                trackEffectiveMigration(scene: .getValue)
            } else {
                // 防御：可能出现 FG 回退时写入了 nil(或删除了key) 的场景
                // 这样写可以保证重新迁移后与旧存储始终一致
                wrapped.removeValue(forKey: key)
            }
            setMigrated(forKey: key)
            log.info("finish migrating \(KVStoreLogProxy.encoded(for: key))")
        } else {
            log.info("\(KVStoreLogProxy.encoded(for: key)) has already be migrated")
        }

        return _forward_get_object(to: wrapped, forKey: key)
    }

    func setObject<O: NSCodingObject>(_ obj: O, forKey key: String) {
        _forward_set_object(to: wrapped, forKey: key, object: obj)

        // 同步数据到 migration from 中
        if let syncHelper, let source = syncHelper.syncSource(forKey: key) {
            if syncHelper.task.strategy == .sync {
                if let oldCipher = source.cipher {
                    source.set(self.rawData(forKey: key, oldCipher: oldCipher))
                } else {
                    source.setObject(obj)
                }
            }
            setMigrated(forKey: key)
            log.info("sync set: \(KVStoreLogProxy.encoded(for: key))")
        }
    }

    func contains(key: String) -> Bool {
        if let source = syncHelper?.syncSource(forKey: key), !hasMigrated(forKey: key) {
            let ret = source.hasValue()
            if ret {
                trackEffectiveMigration(scene: .contains)
            }
            return ret
        } else {
            return wrapped.contains(key: key)
        }
    }

    func removeValue(forKey key: String) {
        wrapped.removeValue(forKey: key)

        if let source = syncHelper?.syncSource(forKey: key) {
            log.info("sync remove: \(KVStoreLogProxy.encoded(for: key))")
            source.removeValue()
        }
    }

    func allValues() -> [String: Any] {
        var ret = wrapped.allValues()
        guard let helper = syncHelper else {
            return ret
        }

        // 是否上报「有效迁移」
        var needTrack = false
        defer {
            if needTrack {
                trackEffectiveMigration(scene: .allValues)
            }
        }
        for key in helper.allKeys() {
            if hasMigrated(forKey: key) { continue }

            // 和 migrations 里的信息进行 merge
            if let source = helper.syncSource(forKey: key), let v = source.anyValue() {
                ret[key] = v
                needTrack = true
            }
        }
        return ret
    }

    func clearAll() {
        wrapped.clearAll()
        guard let helper = syncHelper else { return }
        for key in helper.allKeys() {
            // 移除 migrations 里的信息
            helper.syncSource(forKey: key)?.removeValue()
        }
    }

    func clearMigrationMarks() {
        let migrationKeys = { [unowned self] in
            let helperAllKeys = self.syncHelper?
                .allKeys(checkAvailable: false)
                .map { $0 + migratedSuffix } ?? []
            if let _: KVStoreCryptoProxy = self.wrapped.findProxy() {
                return helperAllKeys
            }
            let existAllKeys = self.wrapped.allKeys().filter { $0.hasSuffix(migratedSuffix) }
            let result = helperAllKeys + existAllKeys
#if DEBUG || ALPHA
            log.info("clear migration keys: [\(result.joined(separator: ", "))]")
#else
            log.info("clear migration keys count: \(result.count)")
#endif
            return result
        }

        log.info("clearMigrationMarks for domain: \(config.domain)")
        if let syncHelper {
            if syncHelper.task.status.value != .rollback {
                migrationKeys().forEach(wrapped.removeValue(forKey:))
                syncHelper.task.status.value = .rollback
                log.info("set task status to rollback for domain")
            }
        } else {
            // 若无法判断 task 状态，则兜底直接清除
            migrationKeys().forEach(wrapped.removeValue(forKey:))
        }
    }

    // MARK: Track Event

    private enum EffectiveMigrationScene: String {
        case getValue
        case contains
        case allValues
    }

    // 上报有效的迁移，用以后续下掉迁移逻辑的依据
    // 所谓有效的迁移，指的是 source 有数据，而 self 没数据
    private func trackEffectiveMigration(scene: EffectiveMigrationScene) {
        let event = TrackerEvent(
            name: "lark_storage_key_value_migration",
            metric: [:],
            category: [
                "root_domain": config.domain.root.isolationId,
                "scene": scene.rawValue
            ],
            extra: [:]
        )
        DispatchQueue.global(qos: .utility).async {
            Dependencies.post(event)
        }
    }

}

internal final class KVStoreMigrateSyncHelper {
    let task: KVMigrationTask

    private typealias SimpleItem = (
        item: KVMigrationConfig.KeyMatcher.SimpleItem,
        conf: KVMigrationConfig
    )
    private let lock = UnfairLock()
    private var simpleParts: [String: SimpleItem] = [:]
    private var prefixParts: [String: KVMigrationConfig] = [:] // key 表示 prefixPattern
    private var suffixParts: [String: KVMigrationConfig] = [:] // key 表示 suffixPattern
    private var dropPrefixParts: [String: KVMigrationConfig] = [:] // key 表示 prefixPattern
    private var allValuesParts: [KVMigrationConfig] = []

    // 是否可用。如果整个迁移过程已结束，就无须同步
    var available: Bool {
        // 用于`clearMigrationMarks`优化，详见文档：
        // https://bytedance.feishu.cn/docx/TtNEd1iRyoT9V2xwayqcxogSnuR
        if task.status.value == .rollback {
            task.status.value = .idle
        }
        return task.status.value < .finished
    }

    init(task: KVMigrationTask) {
        self.task = task

        for conf in task.configs {
            switch conf.keyMatcher {
            case .simple(let items):
                for item in items {
                    KVStores.assert(
                        simpleParts[item.newKey] == nil,
                        "simpleSources[\(item.newKey)] should be nil",
                        event: .migration
                    )
                    simpleParts[item.newKey] = (item, conf)
                }
            case .prefix(let pattern, _):
                prefixParts[pattern] = conf
            case .suffix(let pattern, _):
                suffixParts[pattern] = conf
            case .dropPrefix(let pattern, _):
                dropPrefixParts[pattern] = conf
            case .allValues:
                allValuesParts.append(conf)
            }
        }
    }

    func syncSource(forKey key: String) -> KVMigrationSyncSource? {
        guard available else { return nil }
        lock.lock(); defer {lock.unlock() }

        if let v = simpleParts[key] {
            return .init(key: v.item.oldKey, config: v.conf)
        }

        for (pre, conf) in prefixParts {
            if key.hasPrefix(pre) {
                return .init(key: key, config: conf)
            }
        }

        for (pre, conf) in suffixParts {
            if key.hasSuffix(pre) {
                return .init(key: key, config: conf)
            }
        }

        // NOTE: 可能存在性能问题
        for (pre, conf) in dropPrefixParts {
            let fromKey = pre + key
            guard let fromStore = conf.safeFromStore(),
                  fromStore.contains(key: fromKey)
            else {
                continue
            }
            return .init(key: fromKey, config: conf)
        }

        if let conf = allValuesParts.first {
            return .init(key: key, config: conf)
        }
        return nil
    }

    func allKeys(checkAvailable: Bool = true) -> [String] {
        // 清除迁移标记时需要调用 allKeys 但不需要检查 available 标记
        guard !checkAvailable || available else { return [] }
        lock.lock(); defer {lock.unlock() }

        var ret = Array(simpleParts.keys)
        for (pre, conf) in prefixParts {
            guard let keys = conf.safeFromStore()?.allKeys() else {
                continue
            }
            ret += keys.filter { $0.hasPrefix(pre) }
        }
        for (pre, conf) in suffixParts {
            guard let keys = conf.safeFromStore()?.allKeys() else {
                continue
            }
            ret += keys.filter { $0.hasSuffix(pre) }
        }
        for (pre, conf) in dropPrefixParts {
            guard let keys = conf.safeFromStore()?.allKeys() else {
                continue
            }
            ret += keys
                .filter { $0.hasPrefix(pre) }
                .map { String($0.dropFirst(pre.count)) }
        }
        for conf in allValuesParts {
            guard let keys = conf.safeFromStore()?.allKeys() else {
                continue
            }
            ret += keys
        }
        return ret
    }
}

internal final class KVMigrationSyncSource {
    let key: String
    let config: KVMigrationConfig
    lazy var store = config.safeFromStore()

    let cipher: KVCipher?
    var hasCipher: Bool { cipher != nil }

    init(key: String, config: KVMigrationConfig) {
        self.config = config

        // 若提供了 cipher 就使用哈希计算后的 key
        if let suite = config.cipherSuite,
           let cipher = KVCipherManager.shared.cipher(forSuite: suite)
        {
            self.key = cipher.hashed(forKey: key)
            self.cipher = cipher
        } else {
            self.key = key
            self.cipher = nil
        }
    }

    private func log(_ message: String, debug: String? = nil) {
#if DEBUG || ALPHA
        KVStores.logger.info("migrateSource(\(KVStoreLogProxy.encoded(for: key))): \(message), debug: \(debug)")
#else
        KVStores.logger.info("migrateSource(\(KVStoreLogProxy.encoded(for: key))): \(message)")
#endif
    }

    func value<T: Codable>() -> T? {
        guard let s = store else {
            return nil
        }
        let ret: T? = s.value(forKey: key)
        log("getValue", debug: "key: \(key) ret: \(ret)")
        return ret
    }

    func object<O: NSCodingObject>() -> O? {
        guard let s = store else {
            return nil
        }
        let ret: O? = s.object(forKey: key)
        log("getObject", debug: "key: \(key) ret: \(ret)")
        return ret
    }

    func anyValue() -> Any? {
        guard let store else { return nil }
        switch type(of: store).type {
        case .udkv:
            return (store as? UDKVStore)?.userDefaults.object(forKey: key)
        case .mmkv:
            return store.allValues()[key]
        }
    }

    func set<T: Codable>(_ value: T) {
        log("setValue", debug: "key: \(key) value: \(value)")
        // 同步回写的时候，如果是数组/字典/数值，直接存储，不进行 encode 处理
        if let nsdict = value as? NSDictionary {
            store?.setObject(nsdict, forKey: key)
        } else if let nsarr = value as? NSArray {
            store?.setObject(nsarr, forKey: key)
        } else if let nsnum = value as? NSNumber {
            store?.setObject(nsnum, forKey: key)
        } else {
            store?.set(value, forKey: key)
        }
    }

    func setObject<O: NSCodingObject>(_ obj: O) {
        log("setObject", debug: "key: \(key) object: \(obj)")
        store?.setObject(obj, forKey: key)
    }

    func hasValue() -> Bool {
        let ret = store?.contains(key: key) ?? false
        log("hasValue: \(ret)")
        return ret
    }

    func removeValue() {
        log("removeValue")
        store?.removeValue(forKey: key)
    }
}

extension KVStore {
    /// 手动设置迁移配置（而不是从注册中读取），适合动态或对性能敏感场景
    /// - Parameters:
    ///   - configs: 迁移配置
    ///   - strategy: 迁移策略
    /// - Returns: KVStore
    @discardableResult
    public func usingMigration(configs: [KVMigrationConfig], strategy: KVMigrationStrategy = .move, shouldMerge: Bool = false) -> KVStore {
        if let proxy: KVStoreMigrateProxy = findProxy() {
            proxy.disabled = false
            proxy.configCustom(configs, strategy: strategy, shouldMerge: shouldMerge)
        } else {
            KVStores.assertionFailure()
        }
        return self
    }

    @discardableResult
    public func usingMigration(config: KVMigrationConfig, strategy: KVMigrationStrategy = .move, shouldMerge: Bool = false) -> KVStore {
        return usingMigration(configs: [config], strategy: strategy, shouldMerge: shouldMerge)
    }

    /// 清除迁移标记
    public func clearMigrationMarks() {
        guard let proxy: KVStoreMigrateProxy = findProxy() else {
            return
        }
        proxy.clearMigrationMarks()
    }
}
