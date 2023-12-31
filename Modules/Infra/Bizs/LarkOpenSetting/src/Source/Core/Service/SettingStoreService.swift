//
//  SettingStoreService.swift
//  LarkOpenSetting
//
//  Created by panbinghua on 2022/8/3.
//

import UIKit
import Foundation
import LarkStorage

public final class SettingStoreService {

    public func store(space: Space,
               domain: DomainType,
               mode: KVStoreMode = .normal) -> KVStore {
        let store = KVStores.udkv(space: space, domain: domain, mode: mode)
        return SettingKVStore(realStore: store)
    }
    public func userSpace(domain: DomainType) -> KVStore {
        let id = userIdProvider()
        let store = KVStores.udkv(space: .user(id: id), domain: domain)
        return SettingKVStore(realStore: store)
    }
    public func global(domain: DomainType) -> KVStore {
        let store = KVStores.udkv(space: .global, domain: domain)
        return SettingKVStore(realStore: store)
    }

//    public func appGroup(domain: DomainType): KVStore {
//        #if DEBUG
//        let appGrounpName = "group.com.bytedance.ee.lark.yzj"
//        #else
//        let appGrounpName = Bundle.main.infoDictionary?["EXTENSION_GROUP"] as? String ?? ""
//        #endif
//        let id = userIdProvider()
//        let store = KVStores.udkv(withSpace: .global, domain: domain, mode: .shared(appGroupId: appGrounpName))
//        return SettingKVStore(realStore: store)
//    }

    private var userIdProvider: () -> String
    public init(userIdProvider: @escaping (() -> String) = { "" }) {
        self.userIdProvider = userIdProvider
    }

    // MARK: log
    static let logQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "SettingKVStore.log"
        queue.qualityOfService = .background
        return queue
    }()

    static private var _log: (_ info: LogInfo) -> Void = { _ in }

    static public func registerLogHandler(handler: @escaping (_ info: LogInfo) -> Void) {
        Self._log = handler
    }

    static public func log(_ info: LogInfo) { // 给外部调用
        SettingStoreService.logQueue.addOperation {
            SettingStoreService._log(info)
        }
    }
}

enum ActionType: String {
    case get
    case set
    case register
    case contains
    case removeValue
    case clearAll
    case allKeys
    case allValues
    case synchronize
}

public struct LogInfo: CustomStringConvertible {
    public let action: String
    public let duration: TimeInterval
    public let isMainThread: String
    public let isMissed: String?
    public let key: String?

    init(type: ActionType, duration: TimeInterval, isMainThread: Bool, key: String? = nil, isMissed: Bool? = nil) {
        self.action = type.rawValue
        self.duration = duration
        self.isMainThread = isMainThread ? "true" : "false"
        self.isMissed = isMissed.map { $0 ? "true" : "false" }
        self.key = key
    }

    public var description: String {
        "Setting StoreInfo: \(action) \(key ?? ""): duration: \(duration * 1_000)ms isMainThread: \(isMainThread) isMissed: \(isMissed ?? "NA")"
    }
}

final public class SettingKVStore: KVStore {
    public func migrate(values: [String: Any]) {
        self.store.migrate(values: values)
    }

    public func value<T: Codable>(forKey key: String) -> T? {
        let start = CACurrentMediaTime()
        let res = self.store.value(forKey: key) as T?
        defer {
            let isMissed = res == nil
            let end = CACurrentMediaTime()
            let isMainThread = Thread.isMainThread
            SettingStoreService.logQueue.addOperation {
                SettingStoreService.log(LogInfo(
                    type: .get,
                    duration: end - start,
                    isMainThread: isMainThread,
                    key: key,
                    isMissed: isMissed
                ))
            }
        }
        return res
    }

    public func set<T: Codable>(_ value: T, forKey key: String) {
        return action(.set, key) {
            return self.store.set(value, forKey: key)
        }
    }

    public func register(defaults: [String: Any]) {
        return action(.register) {
            return self.store.register(defaults: defaults)
        }
    }

    public func contains(key: String) -> Bool {
        return action(.contains, key) {
            return self.store.contains(key: key)
        }
    }

    public func removeValue(forKey key: String) {
        return action(.removeValue, key) {
            return self.store.removeValue(forKey: key)
        }
    }

    public func clearAll() {
        return action(.clearAll) {
            return self.store.clearAll()
        }
    }

    public func synchronize() {
        return action(.synchronize) {
            return self.store.synchronize()
        }
    }

    public func allKeys() -> [String] {
        return action(.allKeys) {
            return self.store.allKeys()
        }
    }

    public func allValues() -> [String: Any] {
        return action(.allValues) {
            return self.store.allValues()
        }
    }

    private let store: KVStore

    public init(realStore: KVStore) {
        self.store = realStore
    }

    private func action<R>(_ type: ActionType, _ key: String? = nil, _ action: () -> R) -> R {
        let start = CACurrentMediaTime()
        defer {
            let end = CACurrentMediaTime()
            let isMainThread = Thread.isMainThread
            SettingStoreService.log(LogInfo(
                type: type,
                duration: end - start,
                isMainThread: isMainThread,
                key: key
            ))
        }
        return action()
    }

    public func clearMigrationMarks() {
        self.store.clearMigrationMarks()
    }
}
