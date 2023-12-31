//
//  KVMigrationConfig.swift
//  LarkStorage
//
//  Created by 7Up on 2022/11/3.
//

import Foundation
import EEAtomic

/**
 KVMigrationValueType 应为 Codable 或 NSCodingObject
 但不知道如何将两个类型放在一起，所以写为 Any
 */
public typealias KVMigrationValueType = Any


/// 迁移配置
public struct KVMigrationConfig {
    // swiftlint:disable nesting
    public enum From: Equatable {
        public enum UserDefaults: Equatable {
            /// path/to/sandbox/Library/Preferences/{bundleIdentifier}.plist
            case standard
            /// path/to/sandbox/Library/Preferences/{suiteName}.plist
            case suiteName(String)
            /// path/to/sharedContainer/Library/Preferences/{appGroupIdentifier}.plist
            case appGroup
        }
        case userDefaults(UserDefaults)

        public enum MMKV: Equatable {
            /// path/to/sandbox/{root}/{mmapId}
            case custom(mmapId: String, rootPath: String)
        }
        case mmkv(MMKV)
    }

    public typealias To = KVStoreType

    public enum KeyMatcher {
        // 表示把 oldKey 的数据迁移到 newKey
        public struct SimpleItem {
            public var oldKey: String
            public var newKey: String
            public var type: KVMigrationValueType.Type?

            public init(oldKey: String, newKey: String, type: KVMigrationValueType.Type? = nil) {
                self.oldKey = oldKey
                self.newKey = newKey
                self.type = type
            }
            public init(key: String, type: KVMigrationValueType.Type? = nil) {
                self.oldKey = key
                self.newKey = key
                self.type = type
            }
            public static func key(_ key: String, type: KVMigrationValueType.Type? = nil) -> Self {
                Self(oldKey: key, newKey: key, type: type)
            }
        }

        /// 指定要迁移的 items
        case simple([SimpleItem])

        /// 根据 prefix 匹配
        /// eg: prefix(pattern: "abc") 表示前缀为 "abc" 的 key 会尝试在访问前迁移数据
        case prefix(pattern: String, type: KVMigrationValueType.Type? = nil)

        /// 根据 suffix 匹配
        /// eg: suffix(pattern: "def") 表示后缀为 "def" 的 key 会尝试在访问前迁移数据
        case suffix(pattern: String, type: KVMigrationValueType.Type? = nil)

        /// 根据 prefix 匹配，但迁移后删除prefix
        /// eg: dropPrefix(pattern: "abc|") 如果原key为"abc|def"，迁移后的key为"def"
        case dropPrefix(pattern: String, type: KVMigrationValueType.Type? = nil)

        /// 所有 values
        case allValues
    }
    // swiftlint:enable nesting

    /// 迁移的源头
    public var from: From
    /// 迁移的目标
    public var to: To
    /// 迁移目标的 mode
    public var mode: KVStoreMode
    /// 描述要迁移的 key 的配置
    public var keyMatcher: KeyMatcher

    /// 迁移源使用的加密套件，nil 表示不加密
    var cipherSuite: KVCipherSuite?

    internal init(
        from: From,
        to: To,
        mode: KVStoreMode? = nil,
        keyMatcher: KeyMatcher,
        cipherSuite: KVCipherSuite? = nil
    ) {
        self.from = from
        self.to = to
        self.keyMatcher = keyMatcher
        self.cipherSuite = cipherSuite
        // 保持接口兼容性，若未提供 mode，则默认使用迁移源的 mode
        self.mode = if let mode { mode } else {
            if case .userDefaults(let ud) = from, case .appGroup = ud {
                KVStoreMode.shared
            } else {
                KVStoreMode.normal
            }
        }
    }

    public static func from(
        userDefaults: From.UserDefaults,
        to: To = .udkv,
        mode: KVStoreMode? = nil,
        cipherSuite: KVCipherSuite? = nil,
        items: [KeyMatcher.SimpleItem]
    ) -> Self {
        Self(from: .userDefaults(userDefaults), to: to, mode: mode, keyMatcher: .simple(items), cipherSuite: cipherSuite)
    }

    public static func from(
        userDefaults: From.UserDefaults,
        to: To = .udkv,
        mode: KVStoreMode? = nil,
        prefixPattern: String
    ) -> Self {
        Self(from: .userDefaults(userDefaults), to: to, mode: mode, keyMatcher: .prefix(pattern: prefixPattern, type: nil))
    }
    
    public static func from(
        userDefaults: From.UserDefaults,
        to: To = .udkv,
        mode: KVStoreMode? = nil,
        suffixPattern: String
    ) -> Self {
        Self(from: .userDefaults(userDefaults), to: to, mode: mode, keyMatcher: .suffix(pattern: suffixPattern, type: nil))
    }

    public static func from(
        userDefaults: From.UserDefaults,
        to: To = .udkv,
        mode: KVStoreMode? = nil,
        dropPrefixPattern: String
    ) -> Self {
        Self(from: .userDefaults(userDefaults), to: to, mode: mode, keyMatcher: .dropPrefix(pattern: dropPrefixPattern, type: nil))
    }

    public static func allValuesFromUserDefaults(
        named suiteName: String,
        to: To = .udkv,
        mode: KVStoreMode? = nil
    ) -> Self {
        Self(from: .userDefaults(.suiteName(suiteName)), to: to, mode: mode, keyMatcher: .allValues)
    }

    public static func from(
        mmkv: From.MMKV,
        to: To = .mmkv,
        mode: KVStoreMode? = nil,
        cipherSuite: KVCipherSuite? = nil,
        items: [KeyMatcher.SimpleItem]
    ) -> Self {
        Self(from: .mmkv(mmkv), to: to, mode: mode, keyMatcher: .simple(items), cipherSuite: cipherSuite)
    }

    public static func from(
        mmkv: From.MMKV,
        to: To = .mmkv,
        mode: KVStoreMode? = nil,
        prefixPattern: String,
        type: KVMigrationValueType.Type
    ) -> Self {
        Self(from: .mmkv(mmkv), to: to, mode: mode, keyMatcher: .prefix(pattern: prefixPattern, type: type))
    }

    public static func from(
        mmkv: From.MMKV,
        to: To = .mmkv,
        mode: KVStoreMode? = nil,
        dropPrefixPattern: String,
        type: KVMigrationValueType.Type
    ) -> Self {
        Self(from: .mmkv(mmkv), to: to, mode: mode, keyMatcher: .dropPrefix(pattern: dropPrefixPattern, type: type))
    }
}

/// 支持 `~>` 语法生成 `SimpleItem`

infix operator ~>
public func ~> (_ lhs: String, _ rhs: String) -> KVMigrationConfig.KeyMatcher.SimpleItem {
    return .init(oldKey: lhs, newKey: rhs)
}

extension KVMigrationConfig.KeyMatcher.SimpleItem: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(key: value)
    }
}

// MARK: Sync/Clean All

extension KVMigrationConfig {

    func safeFromStore() -> KVStoreBase? {
        switch from {
        case .userDefaults(let ud):
            var ret: UDKVStore?
            // KeyMatcher.allValues 场景，fromStore 不可配置为全局的 .standard 或者跨进程共享的 UserDefaults
            let assertTip = "KeyMatcher.allValues only available for From.UserDefaults.suiteName"
            let cipherAssertTip = "KVCipher only available for From.UserDefaults.suiteName"
            switch ud {
            case .standard:
                if case .allValues = keyMatcher {
                    KVStores.assert(false, assertTip, event: .migration)
                    return nil
                }
                if cipherSuite != nil {
                    KVStores.assert(false, cipherAssertTip, event: .migration)
                    return nil
                }
                ret = UDKVStore()
            case .appGroup:
                if case .allValues = keyMatcher {
                    KVStores.assert(false, assertTip, event: .migration)
                    return nil
                }
                if cipherSuite != nil {
                    KVStores.assert(false, cipherAssertTip, event: .migration)
                    return nil
                }
                ret = UDKVStore(suiteName: Dependencies.appGroupId)
            case .suiteName(let suiteName):
                if case .allValues = keyMatcher, suiteName.isEmpty {
                    KVStores.assert(false, assertTip, event: .migration)
                    return nil
                }
                ret = UDKVStore(suiteName: suiteName)
            }
            // 对于 fromStore，关闭掉对 `NSCodingObject` 的 archiver/unarchiver 处理
            ret?.useNSKeyedUnarchiver = false
            KVStores.assert(ret != nil, "store should not be nil", event: .migration)
            return ret
        case .mmkv(let mm):
            var ret: MMKVStore?
            // KeyMatcher.allValues 场景，fromStore 不可配置为全局的 .standard
            switch mm {
            case .custom(let mmapId, let rootPath):
                let assertTip = "KeyMatcher item type is required for From.MMKV"
                switch keyMatcher {
                case .simple(let items):
                    for item in items {
                        if item.type == nil {
                            KVStores.assert(false, assertTip, event: .migration)
                            return nil
                        }
                    }
                case .prefix(_, let type), .dropPrefix(_, let type):
                    if type == nil {
                        KVStores.assert(false, assertTip, event: .migration)
                        return nil
                    }
                case .suffix(_, let type):
                    if type == nil {
                        KVStores.assert(false, assertTip, event: .migration)
                        return nil
                    }
                case .allValues:
                    KVStores.assert(false, "KeyMatcher.allValues is unavailable for From.MMKV", event: .migration)
                    return nil
                }
                ret = MMKVStore(mmapId: mmapId, rootPath: rootPath)
                ret?.useRawStorage = true
            }
            KVStores.assert(ret != nil, "store should not be nil", event: .migration)
            return ret
        }
    }

    // 复制 KVMigrationConfig 所对应的数据到指定 Store
    func copyAll(to toStore: KVStore) {
        guard let fromStore = safeFromStore() else { return }

        var allValues = [String: Any]()
        let enableMigrate = { (key: String) -> Bool in
            let markKey = key + migratedSuffix
            if !toStore.contains(key: markKey) {
                allValues[markKey] = true
                return true
            } else {
                return false
            }
        }

        // 若提供了 cipher，就直接平移迁移底层 Data
        if let cipherSuite, let cipher = KVCipherManager.shared.cipher(forSuite: cipherSuite) {
            if case .simple(let items) = keyMatcher {
                for item in items where enableMigrate(item.newKey) {
                    // 从 fromStore 中取出 data 平移至 toStore
                    let hashedKey = cipher.hashed(forKey: item.oldKey)
                    // TODO: 考虑会不会有业务的加密数据为 NSData 等
                    if let data = fromStore.data(forKey: hashedKey) {
                        toStore.setRaw(data: data, forKey: item.newKey, oldCipher: cipher)
                    }
                }
            }
            toStore.migrate(values: allValues)
            return
        }

        let asMMKV = { (store: KVStoreBase) -> KVStoreBase? in
            return type(of: store).type == .mmkv ? store : nil
        }

        switch keyMatcher {
        case .simple(let items):
            for item in items where enableMigrate(item.newKey) {
                if let udkv = fromStore as? UDKVStore,
                    let val = udkv.userDefaults.object(forKey: item.oldKey) {
                    allValues[item.newKey] = val
                } else if let mmkv = asMMKV(fromStore) {
                    let val = loadMMKVValue(mmkv, forKey: item.oldKey, type: item.type)
                    allValues[item.newKey] = val
                }
            }
        case .prefix(let pattern, let type):
            if let udkv = fromStore as? UDKVStore {
                for (key, value) in udkv.allValues() {
                    guard key.hasPrefix(pattern), enableMigrate(key) else { continue }
                    allValues[key] = value
                }
            } else if let mmkv = asMMKV(fromStore) {
                for key in mmkv.allKeys() {
                    guard key.hasPrefix(pattern), enableMigrate(key) else { continue }
                    allValues[key] = loadMMKVValue(mmkv, forKey: key, type: type)
                }
            }
        case .suffix(let pattern, let type):
            if let udkv = fromStore as? UDKVStore {
                for (key, value) in udkv.allValues() {
                    guard key.hasSuffix(pattern), enableMigrate(key) else { continue }
                    allValues[key] = value
                }
            } else if let mmkv = asMMKV(fromStore) {
                for key in mmkv.allKeys() {
                    guard key.hasSuffix(pattern), enableMigrate(key) else { continue }
                    allValues[key] = loadMMKVValue(mmkv, forKey: key, type: type)
                }
            }
        case .dropPrefix(let pattern, let type):
            if let udkv = fromStore as? UDKVStore {
                for (key, value) in udkv.allValues() {
                    guard key.hasPrefix(pattern) else { continue }
                    let newKey = String(key.dropFirst(pattern.count))
                    guard !newKey.isEmpty, enableMigrate(key) else { continue }
                    allValues[newKey] = value
                }
            } else if let mmkv = asMMKV(fromStore) {
                for key in mmkv.allKeys() {
                    guard key.hasPrefix(pattern) else { continue }
                    let newKey = String(key.dropFirst(pattern.count))
                    guard !newKey.isEmpty, enableMigrate(key) else { continue }
                    allValues[newKey] = loadMMKVValue(mmkv, forKey: key, type: type)
                }
            }
        case .allValues:
            for (key, value) in fromStore.allValues() {
                guard enableMigrate(key) else { continue }
                allValues[key] = value
            }
        }
        toStore.migrate(values: allValues)
    }

    // 清除 KVMigrationConfig 所对应的数据
    func cleanAll() {
        guard let store = safeFromStore() else { return }

        // 若提供了 cipher，就根据哈希算法删除 fromStore 的对应值
        if let cipherSuite, let cipher = KVCipherManager.shared.cipher(forSuite: cipherSuite) {
            if case .simple(let items) = keyMatcher {
                for item in items {
                    let hashedKey = cipher.hashed(forKey: item.oldKey)
                    store.removeValue(forKey: hashedKey)
                }
            }
            return
        }

        switch keyMatcher {
        case .simple(let items):
            for item in items {
                store.removeValue(forKey: item.oldKey)
            }
        case .prefix(let pattern, _), .dropPrefix(let pattern, _):
            let keys = store.allValues().keys.filter { $0.hasPrefix(pattern) }
            for key in keys {
                store.removeValue(forKey: key)
            }
        case .suffix(let pattern, _):
            let keys = store.allValues().keys.filter { $0.hasSuffix(pattern) }
            for key in keys {
                store.removeValue(forKey: key)
            }
        case .allValues:
            store.clearAll()
            // `allValues` 场景，将文件也给删掉；不过不能仅删除文件，有内存缓存，
            // 上面的 `store.clearAll()` 也是有必要的
            if let udStore = store as? UDKVStore, !udStore.suiteName.isEmpty {
                let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
                let path = NSString.path(withComponents: [libraryPath, "Preferences", udStore.suiteName + ".plist"])
                let manager = FileManager.default
                if manager.fileExists(atPath: path) {
                    try? manager.removeItem(atPath: path)
                }
            }
        }
    }

    func loadMMKVValue(_ mmkv: KVStoreBase, forKey key: String, type: KVMigrationValueType.Type?) -> Any? {
        guard let type = type else {
            KVStores.assert(false, "KeyMatcher item type is required for From.MMKV", event: .migration)
            return nil
        }

        if type is Bool.Type {
            return mmkv.loadValue(forKey: key) as Bool?
        } else if type is Int.Type {
            return mmkv.loadValue(forKey: key) as Int?
        } else if type is Int64.Type {
            return mmkv.loadValue(forKey: key) as Int64?
        } else if type is Float.Type {
            return mmkv.loadValue(forKey: key) as Float?
        } else if type is Double.Type {
            return mmkv.loadValue(forKey: key) as Double?
        } else if type is String.Type {
            return mmkv.loadValue(forKey: key) as String?
        } else if type is Date.Type {
            return mmkv.loadValue(forKey: key) as Date?
        } else if type is Data.Type {
            return mmkv.loadValue(forKey: key) as Data?
        } else if type is NSDictionary.Type {
            return mmkv.loadValue(forKey: key) as NSDictionary?
        } else if type is NSArray.Type {
            return mmkv.loadValue(forKey: key) as NSArray?
        }

        KVStores.assertionFailure("unexpected type: \(type)")
        return nil
    }
}
