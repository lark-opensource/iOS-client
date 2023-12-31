//
//  AppCenterMonitorEvent.swift
//  LarkWorkplace
//
//  Created by 武嘉晟 on 2019/11/4.
//

import Foundation

// swiftlint:disable identifier_name

/// 用于性能埋点
enum AppCenterMonitorEvent {
    enum TemplateBadgeScene: Int {
        case fromRustLocal = 1
        case fromRustNet = 2
        case fromCache = 3
        case fromNetwork = 4
    }

    enum BadgeKey: String {
        case badge_brief
        case scene
        case sequence_id
    }
    /// 主页实打实的网络数据请求 不论来源
    static let appcenter_main_page_request = "appcenter_main_page_request"
    static let appcenter_build_home_model = "appcenter_build_home_model"

    /// 从不同数据源加载badgeNode的地方都需要
    /// - 小程序/h5 updateBadge api中最后pull node时
    /// - 小程序/h5 reportBadge api从rust获取node时
    /// - 从工作台缓存中加载badgeNode时
    /// - 从工作台服务端加载badgeNode时
    /// - 主导航从rust层加载badgeNode时
    /// scene
    /// - FromRustLocal=1
    /// - FromRustNet=2
    /// - FromWorkplaceCache=3
    /// - FromWorkplaceServer=4
    /// badge_brief：组成的标准json字符串
    ///     [{badgeId: xxx, version, xxx, appId:xxx, type:xxx, num:xxx,show:xxx}]
    /// result_type（通用）
    /// error_msg（通用）
    static let op_app_badge_pull_node = "op_app_badge_pull_node"
    /// 业务监听来自rust层badgeNode的地方都需要
    /// scene
    ///  - FromWorkplace=1
    ///  - FromNavigateTab=2
    /// badge_brief（同上）
    /// result_type（通用）
    /// error_msg（通用）
    static let op_app_badge_node_push = "op_app_badge_node_push"
    /// 客户端native向rust层保存badgeNode的地方都需要
    /// scene
    /// - FromWorkplace=1
    /// badge_brief（同上）
    /// result_type（通用）
    /// error_msg（通用）
    static let op_app_badge_save_node = "op_app_badge_save_node"

    /// 客户端native向rust层更新badgeNode的地方都需要
    /// 使用场景：
    /// - 小程序/h5 updateBadge api更新badge_num
    /// - 小程序/h5 设置页、关于页更新need_show
    /// - 工作台badge开关批量页面更新need_show
    /// 相关参数：
    /// - scene
    ///   - FromAppSetting=1
    ///   - FromAppAbout=2
    ///   - FromWorkplaceSetting=3
    ///   - FromUpdateBadgeAPI=4
    /// - badge_brief（同上）
    /// - result_type（通用）
    /// - error_msg（通用）
    static let op_app_badge_update_notice_node = "op_app_badge_update_notice_node"

    /// 工作台内badge开关列表
    /// - badge_setting_brief：{appId:xxx,status:xxx}例如
    /// [{appId:cli_123,status:true},{appId:cli_456,status:false)]
    /// - result_type（通用）
    /// - error_msg（通用）
    static let op_app_badge_setting_list = "op_app_badge_setting_list"
}

// swiftlint:enable identifier_name
