//
//  Keys.swift
//  LarkSplash
//
//  Created by 王元洵 on 2021/5/17.
//

import Foundation
import LarkStorage

extension KVStores {
    static var splash: KVStore {
        Self.udkv(space: .global, domain: Domain.biz.core.child("Splash"))
            // NOTE:
            // splash 相关 kv 从 UserDefaults 迁移至 KVStorage/KeyValue，需要做数据迁移。
            // 标准做法是把相关数据迁移配置写在 LarkStorage/KVMigrationRegistry+Lark.swift 中
            // 但考虑到 splash kv 的访问时机非常早，额外调 `usingMigration` 简化迁移链路，降低性能损耗
            .usingMigration(config: .from(userDefaults: .standard, items: [
                // 描述存量数据迁移，新增 kv 无需添加
                "LarkSplash.hasSplashData" ~> "hasSplashData",
                "LarkSplash.lastSplashDataTime" ~> "lastSplashDataTime",
                "LarkSplash.lastSplashAdID" ~> "lastSplashAdID"
            ]))
    }
}

extension KVKeys {
    struct Splash {
        static let hasSplashData = KVKey("hasSplashData", default: false)
        static let lastSplashDataTime = KVKey<TimeInterval?>("lastSplashDataTime")
        static let lastSplashAdID = KVKey<Int64?>("lastSplashAdID")
    }
}
