//
//  KVStoreTrackProxy.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

extension Const.KV {
    static let byteLimit = 1024
}

/// KVStore 性能监控
final class KVStoreTrackProxy: KVStoreProxy {
    // 埋点上报策略
    enum Strategy: Int {
        case `default`
        case disabled
    }

    static var type: KVStoreProxyType { .track }
    var wrapped: KVStore

    var biz: String
    var scene: String = "unknown"
    var strategy: Strategy = .default

    private let config: KVStoreConfig

    init(wrapped: KVStore, config: KVStoreConfig) {
        self.wrapped = wrapped
        self.config = config
        self.biz = config.domain.root.isolationId
    }

    // MARK: KVStore Impl

    func value<T: Codable>(forKey key: String) -> T? {
        return track(.getValue, key: key) {
            let value: T? = wrapped.value(forKey: key)
#if DEBUG || ALPHA
            // 检查要读取的类型 T 和实际存储的类型是否一致
            checkTypeConsistent(key: key, value: value)
            // 检查读取的类型，若 T 为 Optional，说明返回类型为 Optional<Optional<...>>，可能存在问题
            checkNestedOptional(key: key, type: T.self)
#endif
            return value
        }
    }

    func set<T: Codable>(_ value: T, forKey key: String) {
        track(.setValue, key: key) {
#if DEBUG || ALPHA
            checkExceeded(key: key, value: value)
#endif
            wrapped.set(value, forKey: key)
        }
    }

    func object<O: NSCodingObject>(forKey key: String) -> O? {
        return track(.getObject) {
            return _forward_get_object(to: wrapped, forKey: key)
        }
    }

    func setObject<O: NSCodingObject>(_ obj: O, forKey key: String) {
        track(.setObject) {
            _forward_set_object(to: wrapped, forKey: key, object: obj)
        }
    }

    func register(defaults: [String: Any]) {
        track(.registerDefaults) {
            wrapped.register(defaults: defaults)
        }
    }

    func migrate(values: [String: Any]) {
        track(.migrateValues) {
            wrapped.migrate(values: values)
        }
    }

    func contains(key: String) -> Bool {
        return track(.containsKey, key: key) {
            return wrapped.contains(key: key)
        }
    }

    func removeValue(forKey key: String) {
        track(.removeValue, key: key) {
            wrapped.removeValue(forKey: key)
        }
    }

    func clearAll() {
        track(.clearAll) {
            wrapped.clearAll()
        }
    }

    func allKeys() -> [String] {
        return track(.getAllKeys) {
            return wrapped.allKeys()
        }
    }

    func allValues() -> [String: Any] {
        return track(.getAll) {
            return wrapped.allValues()
        }
    }

    // MARK: Track Action

    private func track<T>(_ action: KVStoreAction, key: String? = nil, block: () -> T) -> T {
        guard strategy != .disabled, LarkStorageFG.trackEvent else {
            return block()
        }
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let end = CFAbsoluteTimeGetCurrent()
            let event = TrackerEvent(
                name: "lark_storage_key_value_action",
                metric: [
                    "latency": (end - start) * 1000
                ],
                category: [
                    "is_main_thread": Thread.isMainThread,
                    "base_type": config.type.rawValue,
                    "action": action.rawValue,
                    "biz": biz,
                    "scene": scene
                ],
                extra: [:]
            )
            DispatchQueue.global().async {
                Dependencies.post(event)
            }
        }
        return block()
    }

#if DEBUG || ALPHA
    /// 用于 `value(forKey:)` 函数内检查读取的类型是否为嵌套 Optional，并上报埋点
    private func checkNestedOptional(key: String, type: Codable.Type) {
        guard type is KVOptional.Type else {
            return
        }

        KVStores.assert(
            false,
            "get value with nested optional type",
            event: .nestedOptional,
            extra: [
                "key": key,
                "biz": biz,
                "type": String(describing: type),
            ]
        )
        // fatalError("get value with nested optional type, key: \(key), biz: \(biz), type: \(String(describing: type))")
    }

    /// 用于 `value(forKey:)` 函数内检查读写类型是否一致，并上报埋点
    private func checkTypeConsistent<T: Codable>(key: String, value: T?) {
        // 若包含 key 但读出值为空，说明底层解码失败，可能类型不一致
        guard value == nil && contains(key: key) else {
            return
        }

        // 调用底层接口获取实际值类型，忽略 MMKV，因为 MMKV 无类型
        var actualType: Any.Type?

        let (base, proxies) = allComponents()
        if let base = base as? UDKVStore,
           let rekeyProxy = proxies.compactMap({ $0 as? KVStoreRekeyProxy }).first
        {
            let encodedKey = rekeyProxy.encodedKey(from: key)
            guard let object = base.userDefaults.object(forKey: encodedKey) else {
                return
            }
            actualType = Swift.type(of: object)
        }

        // 若读取类型与实际类型不一致，则上报埋点
        // 若类型一致，说明是其他原因导致的解码失败，例如业务更改数据的字段等，这里不做检查
        let readType = T.self
        guard readType != actualType else {
            return
        }

        KVStores.assert(
            false,
            "the type of writing and reading are not consistent",
            event: .inconsistentType,
            extra: [
                "key": key,
                "biz": biz,
                "read_type": String(describing: T.self),
                "actual_type": String(describing: actualType),
            ]
        )
        // fatalError("types of writing and reading are not consistent, key: \(key), biz: \(biz), read_type: \(String(describing: T.self)), actual_type: \(String(describing: actualType))")
    }

    /// 检查写入的值编码后有没有超过 1024 大小
    private func checkExceeded<T: Codable>(key: String, value: T) {
        // 如果是Basic类型，却不是String、Data，说明是其他基础类型，不需要判断超限
        if T.self is KVStoreBasicType.Type {
            if let value = value as? String, value.count >= Const.KV.byteLimit {
                postExceededEvent(size: value.count, key: key)
            } else if let value = value as? Data, value.count >= 1024 {
                postExceededEvent(size: value.count, key: key)
            }
        } else {
            let wrapper = KVStoreCryptoProxy.JsonWrapper(value: value)
            if let data = try? JSONEncoder().encode(wrapper), data.count >= Const.KV.byteLimit {
                postExceededEvent(size: data.count, key: key)
            }
        }
    }

    private func postExceededEvent(size: Int, key: String) {
        let event = TrackerEvent(
            name: "lark_storage_key_value_exceeded",
            metric: [ "size": size ],
            category: [
                "base_type": config.type.rawValue,
                "biz": biz,
                "scene": scene
            ],
            extra: [ "key": key ]
        )
        DispatchQueue.global().async {
            Dependencies.post(event)
        }
    }
#endif
}

public extension KVStore {

    /// 使用监控
    /// - Parameters:
    ///   - biz: 对应 Slardar 埋点的 category["biz"]，如果不传，则使用 domain.root.isolateId
    ///   - scene: 对应 Slardar 埋点的 category["scene"]，如果不传，则使用 "unknown"
    /// - Returns: KVStore
    func usingTracker(biz: String? = nil, scene: String?) -> KVStore {
        let doConfig = { (proxy: KVStoreTrackProxy) in
            if let biz = biz { proxy.biz = biz }
            if let scene = scene { proxy.scene = scene }
        }
        // 在原来的 TrackProxy 上配置
        if let proxy: KVStoreTrackProxy = findProxy() {
            doConfig(proxy)
            return self
        }
        if let logProxy: KVStoreLogProxy = findProxy() {
            // 新建 proxy
            let trackProxy = KVStoreTrackProxy(wrapped: self, config: logProxy.config)
            doConfig(trackProxy)
            return trackProxy
        } else {
            KVStores.assertionFailure()
            return self
        }
    }

}
