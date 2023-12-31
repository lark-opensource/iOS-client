//
//  WPEvent.swift
//  LarkWorkplace
//  产品功能埋点
//  Created by 李论 on 2020/7/1.
//

import UIKit
import LKCommonsLogging
import LKCommonsTracker

/// 用于user_id 和 tenant_id 加密
private let reportSalt1 = "08a441"
private let reportSalt2 = "42b91e"
/// 数据加密
/// - Parameter str: 要加密的数据
func secreatString(str: String) -> String {
    let md5 = (str + reportSalt2).md5()
    let sha1 = (reportSalt1 + md5).sha1()
    return sha1
}

/// 工作台业务埋点
enum WPEvent: String {
    // enum枚举值不应该带下划线，业务考虑优化
    // swiftlint:disable identifier_name
    /// 打开工作台
    case appcenter_view
    /// 点击工作台搜索
    case appcenter_search
    /// 点击顶部导航获取应用（现在的应用目录）
    case appcenter_tap_appdirectory
    /// 点击顶部导航设置
    @available(*, deprecated, message: "use WorkplaceTrackEventName")
    case appcenter_click_settings
    /// 排序页面中删除应用
    case appcenter_my_deleteapp
    /// 排序页面中调整应用顺序
    case appcenter_adjustorder
    /// 分类页面 - “添加”应用点击
    case appcenter_addapp
    /// 分类页面 - “取消添加“点击
    case appcenter_deleteapp

    /// Widget使用-点击widget标题/icon进入应用
    case widget_icon_click
    /// Widget使用-点击展开/收起
    case widget_unfold_click
    /// Widget使用-点击自定义按钮
    case widget_custom_click
    /// Widget使用-点击widget内容区域
    case widget_content_click

    /// Block 标题点击
    case Workspace_block_icon_click
    /// Block 展开/收起点击
    case Workspace_block_unfold_click
    /// Block 自定义按钮点击
    case Workspace_block_custom_click
    /// Block 内容区域点击
    case Workspace_block_content_click
    /// Block 加载成功
    case Workspace_block_open
    /// Block 渲染结果（是否成功）
    case Workspace_block_rendering
    /// Block 渲染渲染成功加载时长
    case Workspace_block_rendering_time
    /// 应用设置菜单“编辑”点击
    case appcenter_set_edit_bookmark
    /// 应用设置菜单“关于”点击
    case appcenter_set_edit_about
    /// 工作台渲染时长
    case appcenter_rendering_time
    /// 工作台对内存的占用情况
    case appcenter_memory
    /// 单个Widget渲染是否成功
    case widget_rendering
    /// 单个Widget渲染时长
    case widget_rendering_time
    /// 打开应用上报热度
    case origin_logevent_log_hourly
    /// widget应用曝光
    case appcenter_widgetopen
    /// 应用中心打开应用
    case appcenter_call_app
    /// 工作台打开长按菜单
    @available(*, deprecated, message: "use WorkplaceTrackEventName")
    case openplatform_workspace_appcard_action_menu_view
    // swiftlint:enable identifier_name
}

/// 模板化工作台业务埋点事件字段名
enum WPEventValueKey: String {
    // enum枚举值不应该带下划线，业务考虑优化
    // swiftlint:disable identifier_name
    @available(*, deprecated, message: "use WorkplaceTrackEventKey.item_id")
    case item_id
    /// 应用名称
    case appname
    /// 应用Id
    @available(*, deprecated, message: "use WorkplaceTrackEventKey.app_id")
    case app_id
    /// 是否是常用应用
    case commonly
    /// 应用类型
    case application_type
    /// badge状态
    case badge_status
    /// badge数量
    case badge_number
    /// 打开H5应用的操作leixing
    case openh5_type
    /// 是否在辅助窗口打开
    case is_aux_window
    // swiftlint:enable identifier_name
}

/// 上报事件元信息
final class WPEventReport {
    static let logger = Logger.log(WPEventReport.self)

    var name: String
    private let userId: String?
    private let tenantId: String?
    private var extraInfo: [AnyHashable: Any] = [:]

    init(name: String, userId: String? = nil, tenantId: String? = nil) {
        self.name = name
        self.userId = userId
        self.tenantId = tenantId
    }

    @discardableResult
    func set(key: AnyHashable, value: Any?) -> WPEventReport {
        if let value = value {
            extraInfo[key] = value
        } else {
            extraInfo.removeValue(forKey: key)
        }
        return self
    }

    func post() {
        /// 所有事件加上用户ID和租户ID
        if WorkplaceScope.userScopeCompatibleMode {
            // 原逻辑自己加了 user_id & tenant_id, 和 Android 确认实际应该都是依赖基建的字段（user_unique_id）。
            // 这里看起来是原来加的无用逻辑，跟随用户态隔离灰度一起下掉。
            set(key: "user_id", value: "\(secreatString(str: userId ?? ""))")
            set(key: "tenant_id", value: "\(secreatString(str: tenantId ?? ""))")
        }
        Tracker.post(TeaEvent(name, userID: userId, params: extraInfo))
        Self.logger.info("workplace tea event \(name) extraInfo \(extraInfo) post")
    }
}
