//
//  KVConfig+Lark.swift
//  LarkStorage
//
//  Created by 7Up on 2022/11/8.
//

import Foundation

// MARK: - KVConfigs.Public
/// 管理一些跨模块（public）的 KVConfig

public extension KVConfigs {
    struct Public {
        /// As phantom type. 表示「用户维度」或「全局维度」
        public struct User {}
        public struct Global {}
        /// 公用的 KV。deviceID、ttenv 等，存量数据不迁移
        public struct GlobalCommon { }

        /// 进程共享且用户无关的 key-value
        public struct GlobalShared {}
        // 进程共享的 Key。minimumMode 等，暂时不迁移
        public struct GlobalSharedCommon {}

        public struct Config<Value: KVValue, S> {
            public let key: KVKey<Value>
            public let domain: DomainType
            public let spaceType: S.Type
            public let migration: (config: KVMigrationConfig, strategy: KVMigrationStrategy)?
        }
    }
}

public typealias KVPublic = KVConfigs.Public

public extension KVConfig {

    /// 构建用户维度的 `KVConfig`
    init(wrapped: KVPublic.Config<Value, KVPublic.User.Type>, userId: String) {
        let store = KVStores.udkv(space: .user(id: userId), domain: wrapped.domain)
        self.init(key: wrapped.key, store: store)
    }

    /// 构建用户维度的 `KVConfig`，取当前用户 Id 为 userId
    ///
    /// - Parameters:
    ///   - key: IsolatableKey
    init(wrapped: KVPublic.Config<Value, KVPublic.User.Type>) {
        let userId = KVStores.getCurrentUserId?() ?? ""
        let store = KVStores.udkv(space: .user(id: userId), domain: wrapped.domain)
        self.init(key: wrapped.key, store: store)
    }

    /// 构建全局的 `KVConfig`
    init(wrapped: KVPublic.Config<Value, KVPublic.Global.Type>) {
        let store = KVStores.udkv(space: .global, domain: wrapped.domain)
        self.init(key: wrapped.key, store: store)
    }

    /// 构建 GlobalCommon 的 `KVConfig`
    init(wrapped: KVPublic.Config<Value, KVPublic.GlobalCommon.Type>) {
        let config = KVStoreConfig(
            space: .global,
            domain: wrapped.domain,
            mode: .normal,
            type: .udkv
        )
        let innerStore = UDKVStore()
        innerStore.useNSKeyedUnarchiver = false
        let store = KVStores.attachingProxies([], config: config, to: innerStore)
        self.init(key: wrapped.key, store: store)
    }

    /// 构建 GlobalShared 的 `KVConfig`
    init(wrapped: KVPublic.Config<Value, KVPublic.GlobalShared.Type>) {
        var store = KVStores.udkv(space: .global, domain: wrapped.domain, mode: .shared)
        if let migration = wrapped.migration {
            store = store.usingMigration(config: migration.config, strategy: migration.strategy)
        }
        self.init(key: wrapped.key, store: store)
    }

    /// 构建 GlobalSharedCommon 的 `KVConfig`
    init(wrapped: KVPublic.Config<Value, KVPublic.GlobalSharedCommon.Type>) {
        let config = KVStoreConfig(
            space: .global,
            domain: wrapped.domain,
            mode: .shared,
            type: .udkv
        )
        let store: KVStore
        if let innerStore = UDKVStore(suiteName: Dependencies.appGroupId) {
            innerStore.useNSKeyedUnarchiver = false
            store = KVStores.attachingProxies([], config: config, to: innerStore)
        } else {
            store = KVStoreFailProxy(wrapped: UDKVStore(), config: config)
        }
        self.init(key: wrapped.key, store: store)
    }

}

public extension KVPublic.Config {

    // MARK: Get/Set with userId

    func value(forUser userId: String) -> Value where S == KVPublic.User.Type {
        return KVConfig(wrapped: self, userId: userId).value
    }

    func setValue(_ value: Value, forUser userId: String) where S == KVPublic.User.Type {
        var conf = KVConfig(wrapped: self, userId: userId)
        conf.value = value
    }

    // MARK: Get/Set using currentUserId
    // TODO: 待所有业务全部接入用户态后，需要明确指定 userId，该接口需去掉

    func value() -> Value where S == KVPublic.User.Type {
        return KVConfig(wrapped: self).value
    }

    func setValue(_ value: Value) where S == KVPublic.User.Type {
        var conf = KVConfig(wrapped: self)
        conf.value = value
    }

    // MARK: Get/Set in global space

    func value() -> Value where S == KVPublic.Global.Type {
        return KVConfig(wrapped: self).value
    }

    func setValue(_ value: Value) where S == KVPublic.Global.Type {
        var conf = KVConfig(wrapped: self)
        conf.value = value
    }

    func value() -> Value where S == KVPublic.GlobalCommon.Type {
        return KVConfig(wrapped: self).value
    }

    func setValue(_ value: Value) where S == KVPublic.GlobalCommon.Type {
        var conf = KVConfig(wrapped: self)
        conf.value = value
    }

    func value() -> Value where S == KVPublic.GlobalShared.Type {
        return KVConfig(wrapped: self).value
    }

    func setValue(_ value: Value) where S == KVPublic.GlobalShared.Type {
        var conf = KVConfig(wrapped: self)
        conf.value = value
    }

    func value() -> Value where S == KVPublic.GlobalSharedCommon.Type {
        return KVConfig(wrapped: self).value
    }

    func setValue(_ value: Value) where S == KVPublic.GlobalSharedCommon.Type {
        var conf = KVConfig(wrapped: self)
        conf.value = value
    }

}

public extension KVKey {
    /// 对指定的 `KVKey` 进行隔离约束：指定 domain，以及 Space 类型（`Global` or `User` or `Common`）
    func config<S>(domain: DomainType, type: S = KVPublic.User.self) -> KVPublic.Config<Value, S> {
        return .init(key: self, domain: domain, spaceType: S.self, migration: nil)
    }

    typealias Migration = (config: KVMigrationConfig, strategy: KVMigrationStrategy)
    /// 对指定的 `KVKey` 进行隔离约束：指定 domain、space 类型、migration 信息
    func config<S>(domain: DomainType, type: S, migration: Migration) -> KVPublic.Config<Value, S> {
        return .init(key: self, domain: domain, spaceType: S.self, migration: migration)
    }
}

// MARK: - KVPublic.Common

public extension KVPublic {

    /// 管理一些全局的、公共的 `KVConfig`，譬如 ttenv、deviceId 等
    struct Common {
        static let domain = Domain.keyValue.child("GlobalCommon")
        public typealias T = GlobalCommon

        /// key: "x-tt-env"
        public static let ttenv = KVKey<String?>("x-tt-env")
            .config(domain: domain, type: T.self)

        /// key: "AppleLanguages"
        public static let appleLanguages = KVKey("AppleLanguages", default: [String]())
            .config(domain: domain, type: T.self)

        /// key: "AppleLocale"
        public static let appleLocale = KVKey<String?>("AppleLocale")
            .config(domain: domain, type: T.self)

        /// key: "SystemLanguageIsSelected"
        public static let systemLanguageIsSelected = KVKey("SystemLanguageIsSelected", default: false)
            .config(domain: domain, type: T.self)

        /// key: "lark.ios.device.score"
        public static let deviceScore = KVKey<Double?>("lark.ios.device.score")
            .config(domain: domain, type: T.self)
    }

    /// 管理一些存放 FG 的 config
    struct FG {
        static let domain = Domain.keyValue.child("FeatureGating")
        public typealias T = GlobalCommon

        /// key: "com.lark.lcmonitor"
        public static let lcMonitor = KVKey("com.lark.lcmonitor", default: false)
            .config(domain: domain, type: T.self)

        /// key: "com.lark.fetchfeed"
        public static let enableFetchFeed = KVKey("com.lark.fetchFeed", default: false)
            .config(domain: domain, type: T.self)

        /// key: "lark.evil.method.open"
        public static let evilMethodOpen = KVKey("lark.evil.method.open", default: false)
            .config(domain: domain, type: T.self)

        /// key: "lark.heimdallr.uitracker.optimization.enable"
        public static let uitrackerOptimizationEnable = KVKey("lark.heimdallr.uitracker.optimization.enable", default: false)
            .config(domain: domain, type: T.self)

        /// key: "lark.ios.cold.start.lite.enable"
        public static let coldStartLiteEnable = KVKey("lark.ios.cold.start.lite.enable", default: false)
            .config(domain: domain, type: T.self)

        /// key: "lark.oom.detector.open"
        public static let oomDetectorOpen = KVKey("lark.oom.detector.open", default: false)
            .config(domain: domain, type: T.self)

        /// key: "spacekit.performance.detector.open"
        public static let spacePerformanceDetector = KVKey("spacekit.performance.detector.open", default: false)
            .config(domain: domain, type: T.self)
        
        /// key: "lark.ios.start.cpu.report.enable"
        public static let startCpuReportEnable = KVKey("lark.ios.start.cpu.report.enable", default: false)
            .config(domain: domain, type: T.self)
    }

    /// 通知提示音相关
    ///  用到的模块：LarkSDK, LarkPushTokenUploader
    struct Notify {
        static let domain = Domain.biz.core.child("Notify")

        public static let notifySounds = KVKey<[String: String]?>("notifySounds")
            .config(domain: domain, type: Global.self)
    }

    struct Core {
        static let domain = Domain.biz.core

        public static let minimumMode = KVKey("minimumMode", default: false)
            .config(domain: domain, type: GlobalSharedCommon.self)
    }

    struct Setting {
        static let domain = Domain.biz.infra

        public static let rustLogSecretKey = KVKey("rustLogSecretKey", default: [String: String]()).config(domain: domain, type: Global.self)
    }

    struct NotificationDiagnosis {
        static let domain = Domain.biz.core.child("NotificationDiagnosis")
        private static let migration = (
            config: KVMigrationConfig.from(userDefaults: .appGroup, items: ["NotificationDiagnosisMessage"]),
            strategy: KVMigrationStrategy.sync
        )

        public static let message = KVKey("NotificationDiagnosisMessage", default: "")
            .config(domain: domain, type: GlobalShared.self, migration: migration)
    }

    struct EmotionKeyboard {
        public typealias T = GlobalShared
        private static let domain = Domain.biz.messenger.child("EmotionKeyboard")
        private static let migration = (
            config: KVMigrationConfig.from(
                userDefaults: .appGroup,
                items: [
                    "EmotionKeyboardDefaultLanguage" ~> "defaultLanguage",
                    "EmotionKeyboardDefaultEmojiKeys" ~> "defaultEmojiKeys",
                    "EmotionKeyboardDefaultEmojiDataMap" ~> "defaultEmojiDataMap",
                    "EmotionKeyboardMruEmojiKeys" ~> "mruEmojiKeys",
                    "EmotionKeyboardRecentEmojiKeys" ~> "recentEmojiKeys",
                ]
            ),
            strategy: KVMigrationStrategy.sync
        )

        public static let defaultLanguage = KVKey<String?>("defaultLanguage")
            .config(domain: domain, type: T.self, migration: migration)

        public static let defaultEmojiKeys = KVKey<[String]?>("defaultEmojiKeys")
            .config(domain: domain, type: T.self, migration: migration)

        public static let defaultEmojiDataMap = KVKey<[String: Data]?>("defaultEmojiDataMap")
            .config(domain: domain, type: T.self, migration: migration)

        public static let mruEmojiKeys = KVKey<[String]?>("mruEmojiKeys")
            .config(domain: domain, type: T.self, migration: migration)

        public static let recentEmojiKeys = KVKey<[String]?>("recentEmojiKeys")
            .config(domain: domain, type: T.self, migration: migration)

        public static func synchronize() {
            KVStores.udkv(space: .global, domain: domain, mode: .shared).synchronize()
        }
    }

}
