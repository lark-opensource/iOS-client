//
//  KVStores+Extension.swift
//  LarkExtensionServices
//
//  Created by zhangwei on 2023/9/27.
//

import Foundation
import LarkStorageCore

extension KVKeys {
    public struct Extension {
        // 对应 value 类型：`[[String: Any]]`，不能用 `KVKey` 表达
        public static let trackerEvent = "lark.extenisons.events"

        public static let currentFocusStatusID = KVKey<Int64?>("currentFocusStatusID")

        public struct HTTP {
            public static let trackTime = KVKey<TimeInterval?>("HTTP.trackTime")
            public static let trackError = KVKey<Bool?>("HTTP.trackError")
            // 对应 value 类型：`[String: Any]`，不能用 `KVKey` 表达
            public static let trackDict = "HTTP.trackDict"
        }
    }
}

extension KVStores {
    public struct Extension {
        public static func globalShared() -> KVStore {
            typealias Keys = KVKeys.Extension
            return KVStores.udkv(space: .global, domain: Domain.biz.core.child("Extension"), mode: .shared)
                .simplified()
                .usingMigration(
                    config: .from(
                        userDefaults: .appGroup,
                        items: [
                            .init(key: Keys.trackerEvent),
                            .init(key: Keys.currentFocusStatusID.raw),
                            .init(key: Keys.HTTP.trackDict),
                            .init(key: Keys.HTTP.trackTime.raw),
                            .init(key: Keys.HTTP.trackError.raw),
                        ]
                    ),
                    strategy: .sync
                )
        }

        public static func userShared(id: String) -> KVStore {
            return KVStores.udkv(space: .user(id: id), domain: Domain.biz.core.child("Extension"), mode: .shared)
        }
    }
}

public extension KVPublic {
    /// 跨进程共享的、用户无关的数据 app config 数据
    struct SharedAppConfig {
        static let domain = Domain.biz.core.child("SharedAppConfig")
        public typealias T = GlobalShared

        private static let keyPrefix = "com.bytedance.ee."
        private static let migration = (
            config: KVMigrationConfig.from(
                userDefaults: .appGroup,
                items: [
                    "\(keyPrefix)domain" ~> "domainMap",
                    "\(keyPrefix)applogURL" ~> "applogUrl",
                    "\(keyPrefix)currentAppID" ~> "appId",
                    "\(keyPrefix)currentAppName" ~> "appName",
                    "\(keyPrefix)currentEnv" ~> "envType",
                    "\(keyPrefix)currentUnit" ~> "envUnit",
                    "\(keyPrefix)currentXTTEnv" ~> "x-tt-env",
                    "\(keyPrefix)isLark" ~> "isLark",
                ]
            ),
            strategy: KVMigrationStrategy.sync
        )

        public static let domainMap = KVKey<[String: [String]]?>("domainMap")
            .config(domain: domain, type: T.self, migration: migration)

        public static let applogUrl = KVKey<String?>("applogUrl")
            .config(domain: domain, type: T.self, migration: migration)

        public static let appId = KVKey<String?>("appId")
            .config(domain: domain, type: T.self, migration: migration)

        public static let appName = KVKey<String?>("appName")
            .config(domain: domain, type: T.self, migration: migration)

        public static let envType = KVKey<Int?>("envType")
            .config(domain: domain, type: T.self, migration: migration)

        public static let envUnit = KVKey<String?>("envUnit")
            .config(domain: domain, type: T.self, migration: migration)

        public static let ttenv = KVKey<String?>("x-tt-env")
            .config(domain: domain, type: T.self, migration: migration)

        public static let isLark = KVKey<Bool?>("isLark")
            .config(domain: domain, type: T.self, migration: migration)

        /// tea 上报间隔时间: https://cloud.bytedance.net/appSettings-v2/detail/config/197028/detail/status
        public static let teaUploadDiffTimeInterval = KVKey<Double?>("tea_upload_time_interval")
            .config(domain: domain, type: T.self)
        
        /// tea 上报间隔条数: https://cloud.bytedance.net/appSettings-v2/detail/config/197028/detail/status
        public static let teaUploadDiffNumber = KVKey<Int?>("tea_upload_number")
            .config(domain: domain, type: T.self)

        /// 是否能写日志: https://cloud.bytedance.net/appSettings-v2/detail/config/197028/detail/status
        public static let logEnable = KVKey<Bool?>("log_enable")
            .config(domain: domain, type: T.self)

        /// 日志缓存条数: https://cloud.bytedance.net/appSettings-v2/detail/config/197028/detail/status
        public static let logBufferSize = KVKey<Int?>("log_max_buffer_size")
            .config(domain: domain, type: T.self)
    }
}
