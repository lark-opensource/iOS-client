//
//  SettingStorage.swift
//  LarkSetting
//
//  Created by 王元洵 on 2022/7/29.
//

import Foundation
import LKCommonsLogging
import LarkCombine
import RxSwift
import EEAtomic
import ThreadSafeDataStructure
import LarkContainer

//swiftlint:disable no_space_in_method_call

/// 预加载逻辑
public func preloadDefaultSetting() { SettingStorage.preload() }

enum SettingStorage {
    private static let logger = Logger.log(SettingStorage.self, category: "SettingStorage")
    private static let defaultSettingFilePath = Bundle.main.url(forResource: "lark_settings", withExtension: "")
    private static let onceToken = AtomicOnce()
    private static let queue = DispatchQueue(label: "settings.keyCollectorQueue.serialQueue", qos: .background)

    // 所有的静态setting，以user id作为key
    private static var staticMemoryCache: SafeDictionary<String, [String: Any]> = [:] + .readWriteLock
    // 所有的setting，以user id作为key
    private static var memoryCache: SafeDictionary<String, [String: String]> = [:] + .readWriteLock
    internal static var commonSettings = CommonSettings()
    private static var _defaultSetting: [String: Any]?
    internal static var defaultSetting: [String: Any] {
        onceToken.once {
            do {
                guard let filePath = defaultSettingFilePath else {
                    throw SettingError.localSettingDefaultDataNotFound
                }
                // lint:disable:next lark_storage_check - bundle 读场景，无需检查
                let data = try Data(contentsOf: filePath)

                let json = try JSONSerialization.jsonObject(with: data, options: [])
                guard let settingDic = json as? [String: Any] else { throw SettingError.parseLocalSettingDataFailed }
                _defaultSetting = settingDic
            } catch {
                logger.error("[setting] init SettingStorage failed", error: error)
                assertionFailure("[setting] init SettingStorage failed")
            }
        }
        return _defaultSetting ?? [:]
    }

    private static func notifySettingUpdate(with id: String) {
        settingRxSubject.onNext(id)
        settingCombineSubject.send(id)
    }

    static func settingDic(with id: String) -> [String: Any] {
        memoryCache[id] ?? {
            logger.warn("[setting] memory cache no hit for id: \(id)")
            if !id.isEmpty && !memoryCache.keys.contains(id) {
                memoryCache[id] = DiskCache.object(of: [String: String].self, key: "setting" + id) ?? [:]
            }
            return memoryCache[id] ?? [:]
        }()
    }

    // MARK: parse setting value to dict or type

    private static func parseSettingValue<T: Decodable>(
        _ value: Any,
        type: T.Type,
        key: String,
        decodeStrategy: JSONDecoder.KeyDecodingStrategy,
        id: String = ""
    ) throws -> T {
        if let v = value as? T {
            logger.info("[setting] return setting, key: \(key) id: \(id)")
            return v
        } else {
            do {
                let data: Data
                if let stringValue = value as? String {
                    data = stringValue.data(using: .utf8) ?? Data()
                } else {
                    data = try JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed])
                }
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = decodeStrategy
                let value = try decoder.decode(T.self, from: data)

                logger.info("[setting] return setting, key: \(key) id: \(id)")
                return value
            } catch {
                logger.error("[setting] parsing setting key failed with id: \(id)",
                                  additionalData: ["type": String(describing: T.self), "key": key],
                                  error: error)
                throw error
            }
        }
    }

    private static func parseSettingDict(value: Any) throws -> [String: Any] {
        let dictValue: Any
        if let stringValue = value as? String {
            let data = stringValue.data(using: .utf8) ?? Data()
            dictValue = try JSONSerialization.jsonObject(with: data, options: [])
        } else { dictValue = value }

        guard let settingDic = dictValue as? [String: Any] else { throw SettingError.parseLocalSettingDataFailed }
        return settingDic
    }

    // MARK: get single setting value

    private static func settingValue(with id: String, and key: String, useDefault: Bool = false) throws -> Any {
        if useDefault {
            if let value = defaultSetting[key] { return value }else {
                let error = SettingError.settingKeyNotFound
                logger.error(
                    "[setting] get default setting key failed with id: \(id)",
                    additionalData: ["key": key],
                    error: error
                )
                throw error
            }
        }
        let userSettings = settingDic(with: id)
        guard let value = userSettings[key] else {
            let error = SettingError.settingKeyNotFound
            logger.error(
                "[setting] get setting key failed with id: \(id)",
                additionalData: ["key": key],
                error: error
            )
            if !(id.isEmpty || id == UserStorageManager.placeholderUserID) {
                settingDatasource?.refetchSingleSetting(with: id, and: key)
            }
            if let defaultSettingValue = defaultSetting[key] {
                logger.debug("[setting] using default setting value, id:\(id), key:\(key)")
                return defaultSettingValue
            }else {
                throw error
            }
        }
        return value
    }

    private static func staticSettingValue(with id: String, and key: String) throws -> Any {
        let staticValue: Any
        if let value = staticMemoryCache[id]?[key] {
            staticValue = value
        } else if let value = settingDic(with: id)[key] {
            staticValue = value
            staticMemoryCache[id] = (staticMemoryCache[id] ?? [:]).merging([key: value]) { $1 }
        } else {
            let error = SettingError.settingKeyNotFound
            logger.error("[setting] get static setting key failed id: \(id)",
                              additionalData: ["key": key],
                              error: error)
            settingDatasource?.refetchSingleSetting(with: id, and: key)
            if let defaultValue = defaultSetting[key] {
                logger.debug("[setting] get static using default setting value, id:\(id), key:\(key)")
                staticMemoryCache[id] = (staticMemoryCache[id] ?? [:]).merging([key: defaultValue]) { $1 }
                staticValue = defaultValue
            }else {
                throw error
            }
        }
        return staticValue
    }
}

// MARK: internal interfaces
extension SettingStorage {
    static let settingRxSubject = PublishSubject<String>()
    static let settingCombineSubject = PassthroughSubject<String, SettingError>()
    static var settingDatasource: SettingDatasource?

    static func update(_ newSetting: [String: String], id: String) {
        memoryCache[id] = newSetting
        logger.info("[setting] update setting memory cache with id: \(id)")
        DiskCache.setObject(of: newSetting, key: "setting" + id)
        notifySettingUpdate(with: id)
        SettingKeyCollector.shared.asyncCollectUsedSettingKeys(keys: Array(newSetting.keys))
    }

    // MARK: realtime interfaces

    static func setting<T: Decodable>(
        with id: String,
        type: T.Type,
        key: String,
        decodeStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase,
        useDefaultSetting: Bool = false
    ) throws -> T {
        try parseSettingValue(
            try settingValue(with: id, and: key, useDefault: useDefaultSetting),
            type: type,
            key: key,
            decodeStrategy: decodeStrategy,
            id: id
        )
    }

    static func setting(with id: String, and key: String) throws -> [String: Any] {
        try parseSettingDict(value: try settingValue(with: id, and: key))
    }

    static func allSettingKeys(with id: String) -> [String] { Array(settingDic(with: id).keys) }

    // MARK: static interfaces

    static func staticSetting<T: Decodable>(
        with id: String,
        type: T.Type,
        key: String,
        decodeStrategy: JSONDecoder.KeyDecodingStrategy,
        useDefaultSetting: Bool
    ) throws -> T {
        try parseSettingValue(
            try staticSettingValue(with: id, and: key),
            type: type,
            key: key,
            decodeStrategy: decodeStrategy,
            id: id
        )
    }

    static func commonSetting<T: Decodable>(
        key: String,
        type: T.Type,
        decodeStrategy: JSONDecoder.KeyDecodingStrategy
    ) throws -> T {
        let value = try parseSettingValue(
            try commonSettings.commonSettingValue(key: key),
            type: type,
            key: key,
            decodeStrategy: decodeStrategy
        )
        Self.logger.debug("commonSetting, key: \(key), value: \(value)")
        return value
    }

    static func staticSetting(with id: String, and key: String) throws -> [String: Any] {
        try parseSettingDict(value: try staticSettingValue(with: id, and: key))
    }

    static func updateSettingValue(_ newValue: String, with id: String, and key: String) {
        memoryCache[id]?[key] = newValue

        guard let stringDict = memoryCache[id] else { return }
        DiskCache.setObject(of: stringDict, key: "setting" + id)
        notifySettingUpdate(with: id)
        SettingKeyCollector.shared.asyncCollectUsedSettingKeys(keys: [key])
    }

    static func preload() { _ = defaultSetting }

    static func userSettingKeyNeedFetched(with id: String) -> [String] {
        return SettingKeyCollector.shared.getSettingKeysUsed(id: id)
    }

    static func commonSettingKeyNeedFetched() -> [String] {
        return Array(SettingKeyCollector.defaultSettingKeys)
    }
}


class CommonSettings {

    private static let logger = Logger.log(CommonSettings.self, category: "CommonSettings")

    private var inner: [String: Any]?
    private var rwLock = pthread_rwlock_t()

    init() {
        pthread_rwlock_init(&rwLock, nil)
    }

    deinit {
        pthread_rwlock_destroy(&rwLock)
    }

    // common setting 无用户态配置
    private var commonSettingMemoryCache: [String: Any] {
        var cache: [String: Any]?
        pthread_rwlock_rdlock(&rwLock)
        if let _inner = inner { cache = _inner }
        pthread_rwlock_unlock(&rwLock)

        if cache == nil {
            pthread_rwlock_wrlock(&rwLock)
            if inner == nil {
                inner = SettingStorage.defaultSetting.merging(
                    DiskCache.object(of: [String: String].self, key: "common_setting") ?? [:]
                ) { $1 }
                Self.logger.debug("init commonSettings success, merge defaultSetting")
            }
            cache = inner
            pthread_rwlock_unlock(&rwLock)
        }
        return cache ?? [:]
    }

    internal func updateCommonSetting(_ newCommonSettings: [String: String]) {
        pthread_rwlock_wrlock(&rwLock)
        inner = newCommonSettings
        pthread_rwlock_unlock(&rwLock)

        Self.logger.info("[setting] update newCommonSetting memory cache: \(newCommonSettings.keys)")
        DiskCache.setObject(of: newCommonSettings, key: "common_setting")
    }

    /// 获取无用户态配置
    internal func commonSettingValue(key: String) throws -> Any {
        if let value = commonSettingMemoryCache[key] { return value }
        let error = SettingError.settingKeyNotFound
        Self.logger.error("[setting] get common setting key failed.", additionalData: ["key": key], error: error)
        throw error
    }
}

#if ALPHA

// MARK: Single k-v insertion, mainly used for debug
extension SettingStorage {
    /// 获取，返回值为Bool、Int、Double、String、[String] 或 [String: Any]
    static func getSettingValue(with id: String, and key: String) throws -> Any? {
        (try? setting(with: id, type: Bool.self, key: key)) ??
        (try? setting(with: id, type: Int.self, key: key)) ??
        (try? setting(with: id, type: Double.self, key: key)) ??
        (try? setting(with: id, type: [String].self, key: key)) ??
        (try? setting(with: id, and: key)) ??
        (try? setting(with: id, type: String.self, key: key))
    }

    /// 删除
    static func deleteSettingKey(with id: String, and key: String) {
        memoryCache[id]?.removeValue(forKey: key)

        guard let stringDict = memoryCache[id] as? [String: String] else { return }
        DiskCache.setObject(of: stringDict, key: "setting" + id)
        notifySettingUpdate(with: id)
    }
}

#endif
