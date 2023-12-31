//
//  ThemeLaunchTask.swift
//  LarkMine
//
//  Created by 姚启灏 on 2021/6/28.
//

import Foundation
import BootManager
import LarkStorage
import LarkFeatureGating
import UniverseDesignTheme

final class ThemeLaunchTask: FlowBootTask, Identifiable { // Global
    static var identify = "ThemeLaunchTask"

    private static let themekey = KVKey<Int?>("UDThemeManager.store")
    private lazy var globalStore = KVStores.udkv(
        space: .global,
        domain: Domain.biz.core.child("Theme")
    )
    // NOTE:
    // theme 相关 kv 从 UserDefaults 迁移至 KVStorage/KeyValue，需要做数据迁移。
    // 标准做法是把相关数据迁移配置写在 LarkStorage/KVMigrationRegistry+Lark.swift 中
    // 但考虑到 ThemeLaunchTask 的访问时机非常早，额外调 `usingMigration` 简化迁移链路，降低性能损耗
    .usingMigration(config: .from(userDefaults: .standard, items: ["UDThemeManager.store"]))

    override func execute(_ context: BootContext) {
        if #available(iOS 13.0, *),
           globalStore[ThemeLaunchTask.themekey] == nil {
            let style = UIUserInterfaceStyle.unspecified
            UDThemeManager.setUserInterfaceStyle(style)
            globalStore[ThemeLaunchTask.themekey] = style.rawValue
        }
    }
}
