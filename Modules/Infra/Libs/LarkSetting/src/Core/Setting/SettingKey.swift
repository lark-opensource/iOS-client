//
//  SettingKey.swift
//  LarkSetting
//
//  Created by ByteDance on 2023/7/31.
//

import Foundation
import LKCommonsLogging

public protocol SettingKeyConvertible {
    var key: StaticString { get }
}

public struct UserSettingKey: SettingKeyConvertible {
    public let key: StaticString

    private init(_ key: StaticString) {
        self.key = key
    }

    public static func make(userKeyLiteral key: StaticString) -> UserSettingKey {
        return UserSettingKey(key)
    }

    public var stringValue: String {
        return key.description
    }
}

extension UserSettingKey: SettingsKeyLoader {
    static func loadKeys() -> [String] {
        let autoKeys = load(from: "AutoUserSettingKeys")
        let manualKeys = load(from: "ManualUserSettingKeys")
        return autoKeys + manualKeys
    }
}

public struct GlobalSettingKey: SettingKeyConvertible {
    public let key: StaticString

    private init(_ key: StaticString) {
        self.key = key
    }

    public static func make(golbalKeyLiteral key: StaticString) -> GlobalSettingKey {
        return GlobalSettingKey(key)
    }

    public var stringValue: String {
        return key.description
    }
}

protocol SettingsKeyLoader {
    static func load(from resource: String) -> [String]
}

extension SettingsKeyLoader {
    static func load(from resource: String) -> [String] {
       guard let path = Bundle.main.path(forResource: resource, ofType: "plist") else {
           return []
       }
       // lint:disable:next lark_storage_check - 从 Bundle 读数据，不涉及加解密，无需做统一存储检查
       guard let array = NSArray(contentsOfFile: path) as? [String] else {
           return []
       }

       return array
   }
}

public class SettingKeyCollector {

    public static let shared = SettingKeyCollector()

    static let logger = Logger.log(SettingKeyCollector.self, category: "SettingKeyCollector")

    static let queue = DispatchQueue(label: "setting.SettingKeyCollector.queue", qos: .background)

    static let storageKey = "setting_keys"

    static let defaultSettingKeys: Set<String> = {
        let keysSet = Set<String>(SettingStorage.defaultSetting.keys)
        let userSettingKeys = UserSettingKey.loadKeys()
        logger.debug("plist setting key: \(userSettingKeys.count), default setting key: \(keysSet.count)")
        return keysSet.union(userSettingKeys)
    }()

    public init() {}

    var settingKeysInMemory: [String]?

    let lock = NSLock()

    func readFromDisk(id: String) -> [String]? {
        return DiskCache.object(of: [String].self, key: Self.storageKey)
    }

    public func getSettingKeysUsed(id: String) -> [String] {
        let startTime = Date()
        var usedSettingKeys: [String]?
        lock.lock()
        if settingKeysInMemory == nil {
            if let settingKeysInDisk = readFromDisk(id: id) {
                settingKeysInMemory = settingKeysInDisk
            }else {
                settingKeysInMemory = Array(SettingStorage.settingDic(with: id).keys)
                asyncCollectUsedSettingKeys(keys: settingKeysInMemory ?? [])
            }
        }
        usedSettingKeys = settingKeysInMemory
        lock.unlock()
        let allKeys = Array(Self.defaultSettingKeys.union(usedSettingKeys ?? []))
        let endTime = Date()
        Self.logger.debug("getSettingKeysUsed: \(id), cost: \(endTime.timeIntervalSince(startTime) * 1000)ms")
        return allKeys
    }

    func asyncCollectUsedSettingKeys(keys: [String]) {
        Self.queue.async {
            var updateInDsik: [String]?
            Self.shared.lock.lock()
            Self.shared.settingKeysInMemory = Array(Set(Self.shared.settingKeysInMemory ?? []).union(keys))
            updateInDsik = Self.shared.settingKeysInMemory ?? []
            Self.shared.lock.unlock()
            if let updated = updateInDsik {
                DiskCache.setObject(of: updated, key: Self.storageKey)
            }
        }
    }
}
