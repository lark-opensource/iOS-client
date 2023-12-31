//
//  SCStorage.swift
//  LarkSecurityComplianceInfra
//
//  Created by AlbertSun on 2023/1/3.
//

import Foundation
import LarkStorage

/// KV存储API
public protocol SCKeyValueStorage {
    func set<T: Codable>(_ value: T, forKey key: String)
    func value<T: Codable>(forKey key: String) -> T?
    func contains(key: String) -> Bool
    func removeObject(forKey key: String)
    /// 对当前space&domain清理存储
    func clearAll()

    /// 同 UserDefaults#register(defaults:)，数据不落盘
    func register(defaults: [String: Any])

    func bool(forKey key: String) -> Bool

    func integer(forKey key: String) -> Int

    func float(forKey key: String) -> Float

    func double(forKey key: String) -> Double

    func string(forKey key: String) -> String?

    func data(forKey key: String) -> Data?

    func date(forKey key: String) -> Date?
}

// 存储相关子场景，用于区分Child Domain
public enum SncBiz: DomainConvertible {
    case common
    case securityPolicy(subBiz: String? = nil)
    case securityAudit
    case pasteProtect
    case appLock
    case strategyEngine
    case privacyMonitor
    case sensitivityControl

    public func asDomain() -> Domain {
        let snc = Domain.biz.snc
        switch self {
        case .common:
            return snc.asDomain()
        case .securityPolicy(let subBiz):
            if let subBiz {
                return snc.child("SecurityPolicy").child(subBiz)
            } else {
                return snc.child("SecurityPolicy")
            }
        case .securityAudit:
            return snc.child("SecurityAudit")
        case .pasteProtect:
            return snc.child("PasteProtect")
        case .appLock:
            return snc.child("AppLock")
        case .strategyEngine:
            return snc.child("StrategyEngine")
        case .privacyMonitor:
            return snc.child("PrivacyMonitor")
        case .sensitivityControl:
            return snc.child("PSDA")
        }
    }

    public var isolationId: String {
        switch self {
        case .common:
            return "SecurityCompliance"
        case .securityPolicy(let subBiz):
            if let subBiz {
                return "SecurityPolicy" + "." + subBiz
            } else {
                return "SecurityPolicy"
            }
        case .securityAudit:
            return "SecurityAudit"
        case .pasteProtect:
            return "PasteProtect"
        case .appLock:
            return "AppLock"
        case .strategyEngine:
            return "StrategyEngine"
        case .privacyMonitor:
            return "PrivacyMonitor"
        case .sensitivityControl:
            return "PSDA"
        }
    }
}

public struct SCKeyValueTrackConfig {
    public let biz: SncBiz
    public let scene: String = ""
}

/// 对外暴露的键值对工具
public struct SCKeyValue {

    /// 全局的UserDefault
    public static func globalUserDefault(business: SncBiz = .common, usingTracker trackInfo: SCKeyValueTrackConfig? = nil) -> SCKeyValueStorage {
        let ukdv = KVStores.udkv(space: .global, domain: business)

        if let trackConfig = trackInfo {
            return SCKeyValueStorageImp(store: ukdv.usingTracker(biz: trackConfig.biz.isolationId, scene: trackConfig.scene))
        } else {
            return SCKeyValueStorageImp(store: ukdv)
        }
    }

    /// 单个用户的UserDefault
    public static func userDefault(userId: String, business: SncBiz = .common, usingTracker trackInfo: SCKeyValueTrackConfig? = nil) -> SCKeyValueStorage {
        let ukdv = KVStores.udkv(space: .user(id: userId), domain: business)

        if let trackConfig = trackInfo {
            return SCKeyValueStorageImp(store: ukdv.usingTracker(biz: trackConfig.biz.isolationId, scene: trackConfig.scene))
        } else {
            return SCKeyValueStorageImp(store: ukdv)
        }
    }

    /// 全局的MMKV
    public static func globalMMKV(business: SncBiz = .common, usingTracker trackInfo: SCKeyValueTrackConfig? = nil) -> SCKeyValueStorage {
        let mmkv = KVStores.mmkv(space: .global, domain: business)

        if let trackConfig = trackInfo {
            return SCKeyValueStorageImp(store: mmkv.usingTracker(biz: trackConfig.biz.isolationId, scene: trackConfig.scene))
        } else {
            return SCKeyValueStorageImp(store: mmkv)
        }
    }

    /// 单个用户的MMKV
    public static func MMKV(userId: String, business: SncBiz = .common, usingTracker trackInfo: SCKeyValueTrackConfig? = nil) -> SCKeyValueStorage {
        let mmkv = KVStores.mmkv(space: .user(id: userId), domain: business)

        if let trackConfig = trackInfo {
            return SCKeyValueStorageImp(store: mmkv.usingTracker(biz: trackConfig.biz.isolationId, scene: trackConfig.scene))
        } else {
            return SCKeyValueStorageImp(store: mmkv)
        }
    }

    /// aes加密的全局UserDefault aes加密
    public static func globalUserDefaultEncrypted(business: SncBiz = .common, usingTracker trackInfo: SCKeyValueTrackConfig? = nil) -> SCKeyValueStorage {
        let ukdv = KVStores.udkv(space: .global, domain: business).usingCipher(suite: .aes)

        if let trackConfig = trackInfo {
            return SCKeyValueStorageImp(store: ukdv.usingTracker(biz: trackConfig.biz.isolationId, scene: trackConfig.scene))
        } else {
            return SCKeyValueStorageImp(store: ukdv)
        }
    }

    /// aes加密的单个用户UserDefault
    public static func userDefaultEncrypted(userId: String, business: SncBiz = .common, usingTracker trackInfo: SCKeyValueTrackConfig? = nil) -> SCKeyValueStorage {
        let ukdv = KVStores.udkv(space: .user(id: userId), domain: business).usingCipher(suite: .aes)

        if let trackConfig = trackInfo {
            return SCKeyValueStorageImp(store: ukdv.usingTracker(biz: trackConfig.biz.isolationId, scene: trackConfig.scene))
        } else {
            return SCKeyValueStorageImp(store: ukdv)
        }
    }

    /// aes加密的单个用户MMKV
    public static func MMKVEncrypted(userId: String, business: SncBiz = .common, usingTracker trackInfo: SCKeyValueTrackConfig? = nil) -> SCKeyValueStorage {
        let mmkv = KVStores.mmkv(space: .user(id: userId), domain: business).usingCipher(suite: .aes)

        if let trackConfig = trackInfo {
            return SCKeyValueStorageImp(store: mmkv.usingTracker(biz: trackConfig.biz.isolationId, scene: trackConfig.scene))
        } else {
            return SCKeyValueStorageImp(store: mmkv)
        }
    }

    /// aes加密的全局MMKV
    public static func globalMMKVEncrypted(business: SncBiz = .common, usingTracker trackInfo: SCKeyValueTrackConfig? = nil) -> SCKeyValueStorage {
        let mmkv = KVStores.mmkv(space: .global, domain: business).usingCipher(suite: .aes)

        if let trackConfig = trackInfo {
            return SCKeyValueStorageImp(store: mmkv.usingTracker(biz: trackConfig.biz.isolationId, scene: trackConfig.scene))
        } else {
            return SCKeyValueStorageImp(store: mmkv)
        }
    }
}

// MARK: NSUserDefault

private struct SCKeyValueStorageImp: SCKeyValueStorage {
    let store: KVStore

    func set<T>(_ value: T, forKey key: String) where T: Decodable, T: Encodable {
        store.set(value, forKey: key)
    }

    func value<T>(forKey key: String) -> T? where T: Decodable, T: Encodable {
        let result: T?
        result = store.value(forKey: key)
        return result
    }

    func contains(key: String) -> Bool {
        store.contains(key: key)
    }

    func removeObject(forKey key: String) {
        store.removeValue(forKey: key)
    }

    func string(forKey key: String) -> String? {
        store.value(forKey: key)
    }

    func data(forKey key: String) -> Data? {
        store.value(forKey: key)
    }

    func integer(forKey key: String) -> Int {
        store.value(forKey: key) ?? 0
    }

    func float(forKey key: String) -> Float {
        store.value(forKey: key) ?? 0.0
    }

    func double(forKey key: String) -> Double {
        store.value(forKey: key) ?? 0.0
    }

    func bool(forKey key: String) -> Bool {
        store.value(forKey: key) ?? false
    }

    func date(forKey key: String) -> Date? {
        store.value(forKey: key)
    }

    func clearAll() {
        store.clearAll()
    }

    /// 同 UserDefaults#register(defaults:)，数据不落盘
    func register(defaults: [String: Any]) {
        store.register(defaults: defaults)
    }
}
