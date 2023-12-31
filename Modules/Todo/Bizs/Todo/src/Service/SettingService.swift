//
//  SettingService.swift
//  Todo
//
//  Created by 白言韬 on 2021/2/24.
//

import Foundation
import RxSwift
import RxCocoa

struct SettingState: RxStoreState {
    /// 截止提醒相对于截止时间的偏移
    /// - 0 表示 `截止时间 == 提醒时间`，
    /// - 30 表示：提前 30 分钟
    var dueReminderOffset: Int64

    /// 是否启用每日提醒
    var enableDailyRemind: Bool

    /// 列表视图排序设置, 取不到值时 ListViewSortType 默认为 dueTime
    var listViewSettings: [Rust.ListViewType: Rust.ListViewSetting]

    /// 列表 badge 配置
    var listBadgeConfig: Rust.ListBadgeConfig

    /// Todo自定义用户引导
    var listLaunchScreen: [Rust.ListLaunchScreen]

    init(
        dueReminderOffset: Int64,
        enableDailyRemind: Bool,
        listViewSettings: [Rust.ListViewType: Rust.ListViewSetting],
        listBadgeConfig: Rust.ListBadgeConfig,
        listLaunchScreen: [Rust.ListLaunchScreen]
    ) {
        self.dueReminderOffset = dueReminderOffset
        self.enableDailyRemind = enableDailyRemind
        self.listViewSettings = listViewSettings
        self.listBadgeConfig = listBadgeConfig
        self.listLaunchScreen = listLaunchScreen
    }
}

struct SettingAction: RxStoreAction {
    var logInfo: String { "" }
}

extension SettingState {
    init(pb: Rust.TodoSetting) {
        var listViewSettings = [Rust.ListViewType: Rust.ListViewSetting]()
        for item in pb.tabViewSettings {
            listViewSettings[item.view] = item
        }
        self = SettingState(
            dueReminderOffset: Int64(pb.dueReminderOffset),
            enableDailyRemind: pb.enableDailyRemind,
            listViewSettings: listViewSettings,
            listBadgeConfig: pb.badgeConfig,
            listLaunchScreen: pb.launchScreen
        )
    }

    func toPb() -> Rust.TodoSetting {
        var pb = Rust.TodoSetting()
        var tabViewSettings = [Rust.ListViewSetting]()
        for item in listViewSettings.enumerated() {
            var setting = Rust.ListViewSetting()
            setting.view = item.element.key
            setting.sortType = item.element.value.sortType
            tabViewSettings.append(setting)
        }
        pb.tabViewSettings = tabViewSettings
        pb.enableDailyRemind = self.enableDailyRemind
        pb.badgeConfig = self.listBadgeConfig
        pb.dueReminderOffset = Int32(self.dueReminderOffset)
        pb.launchScreen = self.listLaunchScreen
        return pb
    }

    static let `default` = SettingState(
        dueReminderOffset: 30,
        enableDailyRemind: false,
        listViewSettings: [:],
        listBadgeConfig: .init(),
        listLaunchScreen: [Rust.ListLaunchScreen]()
    )
}

struct SettingUpdateOption: OptionSet {
    let rawValue: UInt
    init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    static let memory = SettingUpdateOption(rawValue: 1 << 0)
    static let remote = SettingUpdateOption(rawValue: 1 << 1)
}

/// 集中管理整个 Todo 业务的 Setting 相关逻辑
protocol SettingService: AnyObject {
    /// 尝试拉取新数据，如果已经是最新数据，则直接结束
    func fetchDataIfNeeded()

    /// 强制拉取新数据
    func forceFetchData()

    /// 获得设置项对应值
    func value<V>(forKeyPath keyPath: WritableKeyPath<SettingState, V>) -> V

    /// 获得一个可以监听的设置项对应值对象
    func observe<V>(forKeyPath keyPath: WritableKeyPath<SettingState, V>) -> Observable<V>

    /// 更新设置项对应值，并同步到 server
    /// - Parameters:
    ///   - onError: 在这里做更新失败的回退逻辑（设置项建议乐观更新）
    func update<V>(_ value: V, forKeyPath keyPath: WritableKeyPath<SettingState, V>, onError: (() -> Void)?)

    /// 只更新内存中的设置项对应值，不会同步到 server
    func updateCache<V>(_ value: V, forKeyPath keyPath: WritableKeyPath<SettingState, V>)

    // 临时处理，为了方便后面找回之前下掉的代码
    var defaultDueTimeDayOffset: Int64 { get }

    var defaultStartTimeDayOffset: Int64 { get }
}
