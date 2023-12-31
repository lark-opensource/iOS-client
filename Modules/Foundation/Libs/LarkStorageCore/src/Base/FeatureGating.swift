//
//  FeatureGating.swift
//  LarkStorage
//
//  Created by 李昊哲 on 2023/8/2.
//

import Foundation
import EEAtomic

/// 存放 LarkStorage 内的 FG 调用
public enum LarkStorageFG {
    // MARK: - 配置部分

#if DEBUG || ALPHA
    /// 用于配置 FG 行为
    enum Config {
        /// 屏蔽掉流式加密
        static var disableStreamCrypto = false

        /// 单测场景可控制 Int64 互通，ALPHA 场景强制开启
        static var enableEquivalentInteger = true
    }
#endif

    // MARK: - KeyValue 部分

    /// 开启 Int 与 Int64 互通，为了保证 MMKV 读写对称，使用静态 FG
    internal static var equivalentInteger: Bool {
#if DEBUG || ALPHA
        return Config.enableEquivalentInteger
#else
        return LarkStorageFGCached.staticValue(forKey: .equivalentInteger)
#endif
    }

    /// 开启KV后台迁移任务
    public static var keyValueBGTask: Bool {
        return LarkStorageFGCached.dynamicValue(forKey: .keyValueBGTask)
    }

    /// MMKV 使用 LRUCache 管理
    public static var mmkvUseLruCache: Bool {
        return LarkStorageFGCached.staticValue(forKey: .mmkvUseLruCache)
    }

    // MARK: - Sandbox 部分

    /// 开启自动解密
    static var decryptRead: Bool {
        return LarkStorageFGCached.dynamicValue(forKey: .decryptRead)
    }

    /// 流式加密
    static var streamCrypto: Bool {
#if DEBUG
        guard !Config.disableStreamCrypto else { return false }
#endif
        return LarkStorageFGCached.dynamicValue(forKey: .streamCrypto)
    }

    /// 开启沙盒后台迁移任务
    public static var sandboxBGTask: Bool {
        return LarkStorageFGCached.dynamicValue(forKey: .sandboxBGTask)
    }

    // MARK: - 通用部分

    /// 是否计算并上报埋点数据
    static var trackEvent: Bool {
        return LarkStorageFGCached.dynamicValue(forKey: .trackEvent)
    }

    /// 自动解密
    static var enableAutoDecrypt: Bool {
        return LarkStorageFGCached.dynamicValue(forKey: .enableAutoDecrypt)
    }
}

/// 管理缓存的 FG 值，此 FG 没有较大的性能损耗
public enum LarkStorageFGCached {
    /// FG 更新时，需要遍历所有的 CachedKey，故收敛至此并遵循 CaseIterable
    public enum Key: String, CaseIterable {
        case decryptRead = "ios.lark_storage.enable_decrypt_read"
        case equivalentInteger = "ios.lark_storage.key_value.equivalent_integer"
        case keyValueBGTask = "ios.lark_storage.key_value.bg_task"
        case sandboxBGTask = "ios.lark_storage.sandbox.bg_task"
        case streamCrypto = "ios.lark_storage.sandbox.streamcipher"
        case trackEvent = "ios.lark_storage.track_event"
        case mmkvUseLruCache = "ios.lark_storage.mmkv_use_lru_cache"
        case enableAutoDecrypt = "ios.lark_storage.auto_decrypt_for_file_reading"
    }

    /// 硬盘缓存，保证启动阶段有FG可用，为了避免 KVStore 内部递归，使用系统 UserDefaults
    private static let diskCache = UserDefaults(suiteName: "LarkStorageFG") ?? .standard

    /// 内存缓存，保证FG稳定
    private static var memoryCache = [String: Bool]()
    private static var memoryCacheLock = UnfairLock()

    /// LarkStorageFG 调用此方法获取稳定的 FG 值
    static func staticValue(forKey key: LarkStorageFGCached.Key) -> Bool {
        let key = key.rawValue
        memoryCacheLock.lock(); defer { memoryCacheLock.unlock() }
        if let value = memoryCache[key] {
            return value
        }
        // 从磁盘获取缓存值，若未缓存默认为 false
        let value = diskCache.bool(forKey: key)
        memoryCache[key] = value
        return value
    }

    /// LarkStorageFG 调用此方法获取动态的 FG 值
    static func dynamicValue(forKey key: LarkStorageFGCached.Key) -> Bool {
        return diskCache.bool(forKey: key.rawValue)
    }

    /// LarkStorageAssembly 中监听 FG 更新时机，并调用此函数更新缓存
    public static func update(_ value: Bool, forKey key: LarkStorageFGCached.Key) {
        let key = key.rawValue
        diskCache.set(value, forKey: key)
        // 保证 App 生命周期内，memoryLayer 的值不发生变化
        memoryCacheLock.withLocking {
            if memoryCache[key] == nil {
                memoryCache[key] = value
            }
        }
    }
}
