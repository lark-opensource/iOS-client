//
//  TeaReporter.swift
//  LarkOpenPlatform
//
//  Created by  bytedance on 2020/10/7.
//

import Foundation
import LKCommonsTracker
import LarkAccountInterface
import LarkContainer

class TeaReporter {
    /// 通用加密密钥
    private static let report_salt1 = "08a441"
    private static let report_salt2 = "42b91e"
    /// 在快捷操作的导索页内点击「获取」按钮
    public static let key_appplus_click_get = "appplus_click_get"
    /// 在快捷操作的导索页内点击查看应用介绍
    public static let key_appplus_click_get_detail = "appplus_click_get_detail"
    /// 在快捷操作的导索页内点击文章链接
    public static let key_appplus_click_link = "appplus_click_link"
    /// 在快捷操作的导索页内点击关闭按钮
    public static let key_appplus_click_close = "appplus_click_close"
    /// 在加号面板点击加号图标获取更多应用
    public static let key_appplus_click_more = "appplus_click_more"
    /// 在加号面板点击应用
    public static let key_appplus_click_app = "appplus_click_app"
    /// 在聊天界面里点击+号进入加号面板
    public static let key_appplus_click_menu = "appplus_click_menu"
    /// 加号菜单中外化展示开关的点击量
    public static let key_appplus_click_switch = "appplus_click_switch"
    /// https://bytedance.feishu.cn/docs/doccn1DvAf9Jz0fCB3yl11hEape#
    /// 点击Message Action
    /// 入口点击
    public static let key_action_click_menu = "action_click_menu"
    /// 点击action
    public static let key_action_click_app = "action_click_app"
    /// 点击更多/快捷操作
    public static let key_action_click_more = "action_click_more"
    /// 点击关闭
    public static let key_action_click_close = "action_click_close"
    /// 点击获取
    public static let key_action_click_get = "action_click_get"
    /// 点击应用介绍
    public static let key_action_click_get_detail = "action_click_get_detail"
    /// 点击文章链接
    public static let key_action_click_link = "action_click_link"
    // MARK: - Group Bot
    // 产品埋点字段参见（from @jijiashu）：https://data.bytedance.net/byteio/et/event/schema?filter=%7B%22keyword%22%3A%22groupbot_%22%2C%22show_discard%22%3Afalse%2C%22register%22%3Atrue%2C%22myself%22%3Afalse%2C%22page%22%3A1%2C%22page_size%22%3A20%2C%22event_index%22%3A1617176351214%7D&subAppId=1161
    /// 访问群机器人列表
    public static let key_groupbot_visit_botlist = "groupbot_visit_botlist"
    /// 访问添加群机器列表
    public static let key_groupbot_visit_addbot = "groupbot_visit_addbot"
    /// 访问群机器人详情
    public static let key_groupbot_visit_detail = "groupbot_visit_detail"
    /// 成功添加机器人
    public static let key_groupbot_addbot_success = "groupbot_addbot_success"
    /// 在列表中点击未安装应用的获取按钮
    public static let key_groupbot_click_addbot_get = "groupbot_click_addbot_get"
    /// 点击添加群机器搜索框
    public static let key_groupbot_click_addbot_search = "groupbot_click_addbot_search"
    /// 查看搜索机器人结果
    public static let key_groupbot_vist_searchresult = "groupbot_vist_searchresult"
    
    /// 上报事件名
    private var eventKey: String
    /// 上报参数
    private var params: [ParamKey: Any] = [:]

    init(eventKey: String) {
        self.eventKey = eventKey
    }

    /// 通用加密方法
    private static func encrypt(str: String) -> String {
        let md5 = (str + report_salt2).md5()
        let sha1 = (report_salt1 + md5).sha1()
        return sha1
    }

    /// 携带用户信息
    public func withUserInfo(resolver: UserResolver) -> TeaReporter {
        guard let userService = try? resolver.resolve(assert: PassportUserService.self) else {
            return self
        }
        let userId = resolver.userID
        let tenantId = userService.userTenant.tenantID
        params[.tenantIdEnc] = TeaReporter.encrypt(str: tenantId)
        params[.userIdEnc] = TeaReporter.encrypt(str: userId)
        return self
    }

    /// 携带设备类型
    public func withDeviceType() -> TeaReporter {
        if UIDevice.current.userInterfaceIdiom == .pad {
            params[.platform] = "iPad"
        } else {
            params[.platform] = "iOS"
        }
        return self
    }

    /// 添加上报参数
    public func withInfo(params: [ParamKey: Any]) -> TeaReporter {
        let newParams = self.params.merging(params) { (_, new) in new }
        self.params = newParams
        return self
    }
    /// 格式化上报的参数
    private func formateReportParams() -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in self.params {
            result.updateValue(value, forKey: key.rawValue)
        }
        return result
    }

    /// 业务事件上报
    public func report() {
        Tracker.post(TeaEvent(self.eventKey,
                              params: self.formateReportParams()))
    }
}

enum ParamKey: String {
    /// 租户ID（加密）
    case tenantIdEnc = "tenant_id_enc"
    /// 用户ID（加密）
    case userIdEnc = "user_id_enc"
    /// 终端类型
    case platform = "platform"
    /// 用户名
    case appId = "app_id"
    /// 应用来源
    case from = "from"
    /// 应用来源
    case message_type = "message_type"
    /// 类型
    case type = "type"

    // MARK: - Group Bot
    /// 是否外部群
    case isExternal = "is_external"
    /// 可添加机器人的数量
    case botsNum = "botsNum"
    /// 推荐的（未获取的）机器人数量
    case recommendBotsNum = "recommendBotsNum"
    /// query 关键词
    case query = "query"
    /// 机器人应用名
    case appName = "appname"
    /// 机器人应用ID
    case appID = "appId"
    /// 机器人应用类型：自建/商店/自定义机器人
    case botType = "botType"
}
