//
//  KVStoreLogProxy.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import EEAtomic

extension KVStoreAction {
    private static let nonSideEffectActions: [KVStoreAction] = [
        .getValue,
        .getObject,
        .containsKey,
        .getAll,
        .getAllKeys
    ]

    var hasNonSideEffect: Bool { Self.nonSideEffectActions.contains(self) }
}

/// KVStore 日志监控
final class KVStoreLogProxy: KVStoreProxy {
    // 日志上报策略
    enum Strategy: Int {
        case `default`
        case disabled
    }

    struct LogRecord {
        var action: KVStoreAction
        var timestamp: CFTimeInterval
    }

    static var type: KVStoreProxyType { .log }
    var wrapped: KVStore
    let config: KVStoreConfig
    var strategy: Strategy = .default

    // 记录 key 的最后一次 type1 log，用来做限频，限频说明：
    // - 对所有 action 划分为 nonSideEffect action 和 sideEffect action
    // - 如果两个 nonSideEffect action 之间没有 sideEffect action，
    //   且相隔时间不超过 10s，则第二个 action 不打日志
    private static let type1LogRecordLock = UnfairLock()
    private static let type1LogTimeLimit: CFTimeInterval = 10
    private static var type1LogRecords: [KVStoreConfig: [String: LogRecord]] = [:]

    private let domainInfo: String

    init(wrapped: KVStore, config: KVStoreConfig) {
        self.wrapped = wrapped
        self.config = config
        self.domainInfo = config.domain.isolationChain(with: ".")
    }

    // MARK: KVStore Impl

    func value<T: Codable>(forKey key: String) -> T? {
        let ret: T? = wrapped.value(forKey: key)
        doType1Log(.getValue, key: key, value: ret)
        return ret
    }

    func set<T: Codable>(_ value: T, forKey key: String) {
        wrapped.set(value, forKey: key)
        doType1Log(.setValue, key: key, value: value)
    }

    func object<O: NSCodingObject>(forKey key: String) -> O? {
        let ret: O? = _forward_get_object(to: wrapped, forKey: key)
        doType1Log(.getObject, key: key, value: ret)
        return ret
    }

    func setObject<O: NSCodingObject>(_ obj: O, forKey key: String) {
        _forward_set_object(to: wrapped, forKey: key, object: obj)
        doType1Log(.setObject, key: key, value: obj)
    }

    func contains(key: String) -> Bool {
        let ret = wrapped.contains(key: key)
        doType1Log(.containsKey, key: key, value: ret)
        return ret
    }

    func removeValue(forKey key: String) {
        wrapped.removeValue(forKey: key)
        doType1Log(.removeValue, key: key, value: nil)
    }

    func register(defaults: [String: Any]) {
        wrapped.register(defaults: defaults)
        doType2Log(
            .registerDefaults,
            extra: ["keys": defaults.keys.map(Self.encoded(for:)).joined(separator: ",")],
            debug: defaults.mapValues { "\($0)" }
        )
    }

    func clearAll() {
        wrapped.clearAll()
        doType2Log(.clearAll)
    }

    func allKeys() -> [String] {
        let ret = wrapped.allKeys()
        doType2Log(
            .getAllKeys,
            extra: ["keys": ret.map(Self.encoded(for:)).joined(separator: ",")]
        )
        return ret
    }

    func allValues() -> [String: Any] {
        let ret = wrapped.allValues()
        doType2Log(
            .getAll,
            extra: ["keys": ret.keys.map(Self.encoded(for:)).joined(separator: ",")],
            debug: ret.mapValues { "\($0)" }
        )
        return ret
    }

    /// 对 key 进行 encode 处理
    @inline(__always)
    static func encoded(for key: String) -> String {
#if DEBUG || ALPHA
        return "\(key)" // 插值重新生成 key，防御上层传入 key 可能得野指针问题
#else
        // 长度超过 2 个字符的 key，对其进行 encode 处理
        let threshold = 2
        guard key.count > threshold else { return "\(key)" }
        return "(\(key.count - threshold))\(key.suffix(threshold))"
#endif
    }

    // 针对 get/set/contains/remove 高频接口的日志
    @inline(__always)
    private func doType1Log(_ action: KVStoreAction, key: String, value: Any?) {
        if case .disabled = strategy { return }

        if !shouldDoType1Log(action, key) { return }

        let extra: [String: String]
#if DEBUG || ALPHA
        extra = ["key": Self.encoded(for: key), "value": "\(value)"]
#else
        extra = ["key": Self.encoded(for: key)]
#endif
        _doLog_(action, extra: extra)
    }

    @inline(__always)
    private func shouldDoType1Log(_ action: KVStoreAction, _ key: String) -> Bool {
        let recordKey = "\(key)"
        let now = CFAbsoluteTimeGetCurrent()

        Self.type1LogRecordLock.lock()
        if action.hasNonSideEffect,
           let records = Self.type1LogRecords[config],
           let record = records[recordKey],
           record.action.hasNonSideEffect,
           now - record.timestamp < Self.type1LogTimeLimit
        {
            Self.type1LogRecordLock.unlock()
            return false
        } else {
            var records = Self.type1LogRecords[config] ?? [:]
            records[recordKey] = .init(action: action, timestamp: now)
            Self.type1LogRecords[config] = records
            Self.type1LogRecordLock.unlock()
            return true
        }
    }

    // 针对 allKeys/register/clear 等非高频接口的日志
    @inline(__always)
    private func doType2Log(
        _ action: KVStoreAction,
        extra: @autoclosure () -> [String: String]? = nil,
        debug: @autoclosure () -> [String: String]? = nil
    ) {
        if case .disabled = strategy { return }

        if !action.hasNonSideEffect {
            Self.type1LogRecordLock.lock()
            var records = Self.type1LogRecords[config] ?? [:]
            records.removeAll()
            Self.type1LogRecords[config] = records
            Self.type1LogRecordLock.unlock()
        }

        let extraDict: [String: String]?
#if DEBUG || ALPHA
        extraDict = debug()
#else
        extraDict = extra()
#endif
        _doLog_(action, extra: extraDict)
    }

    @inline(__always)
    private func _doLog_(_ action: KVStoreAction, extra: [String: String]? = nil) {
        log.info("action: \(action.rawValue), space: \(config.space.isolationId), domain: \(domainInfo)", additionalData: extra)
    }
}
