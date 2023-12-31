//
//  APIDefinition.swift
//  LarkOpenPlatform
//
//  Created by yinyuan on 2019/9/17.
//

import Foundation

//public enum APIUrlHost: String {
//    case online = "open.feishu.cn"
//    case staging = "open.feishu-staging.cn"
//    case oversea = "open.larksuite.com"
//    case overseaStaging = "open.larksuite-staging.com"
//
//    case minaOnline = "mina.bytedance.com"
//    case minaStaging = "mina-staging.bytedance.net"
//
//    case internalOverseaOnline = "internal-api.larksuite.com"
//    case internalOverseaStaging = "internal-api.larksuite-staging.com"
//}

public let MESSAGE_CARD_REQUEST_ENGINE_SOURCE = "MessageCard"

public enum MinaAPIUrlPrefix: String {
    case online = "/open-apis/mina"
    case appplus_release = "/lark/appcenter"
    case appplus_staging = "/appcenter"
    case appplus_prelease = "/fleamarket"
    case empty = ""
}

public enum APIUrlPath: String {
    case getChatIdByOpenId = "/open-apis/mina/applink/getchatid-byopenid"
    case getChatIdByOpenChatId = "/open-apis/mina/applink/getchatid-byopenchatid"
    case terminalUploadSettings = "/terminalinfo/upload/settings"
    case terminalUpload = "/terminalinfo/upload"
    case messageCardBindTriggerCode = "/lark/card/api/bindTriggerCode"
    case updateKeyBoardItemsList = "/app_center/PullPlusMenuApp"
    case appLinkH5AppInfo = "/app_center/app_info"
    case appLinkH5AppInfoWithOffline = "/lark/app_interface/app_link/web/info"
    /// 通过applink长链生成applink短链
    case generateShortAppLink = "/open-apis/applink/shortlink/v1/generate"
    /// 加号菜单获取快捷操作应用列表
    case getPlusMenuList = "/lark/app_explorer/api/GetPlusMenuList"
    /// 加号菜单更新用户外化展示配置接口
    case configPlusMenuUserDisplay = "/lark/workplace/api/user_display_config/plus_menu"
    /// MessageAction获取快捷操作列表
    case getMsgActionList = "/lark/app_explorer/api/GetMsgActionList"
    /// MessageAction获取消息内容
    case getMsgListContent = "/open-apis/mina/api/mget_message_content"
    /// 获取应用能力信息
    case getShareAppInfo = "/lark/app_interface/api/app_share/info"
    /// 获取头像应用
    case getAvatarList = "/lark/app_explorer/api/GetAvatarAppList"

    // MARK: message action & plus menu v1
    /// 消息快捷操作「外化展示」接口
    case getMsgActionExternalItems = "/lark/app_explorer/api/GetMsgActionExternalItems"
    /// 加号菜单「外化展示」接口
    case getPlusMenuExternalItems = "/lark/app_explorer/api/GetPlusMenuExternalItems"
    /// 消息快捷操作「更多应用」接口
    case getMsgActionListV1 = "/lark/app_explorer/api/v1/GetMsgActionList"
    /// 加号菜单「更多应用」接口
    case getPlusMenuListV1 = "/lark/app_explorer/api/v1/GetPlusMenuList"
    /// 更新消息快捷操作|加号菜单 用户常用配置
    case updateUserCommonApps = "/lark/app_explorer/api/UpdateUserCommonApps"

    // MARK: group bot
    /// 获得已经添加到群的机器人
    case getGroupBotListPageData = "/lark/bot/api/pull_chat_bots"
    /// 获得可添加到群的机器人，同时附带已添加到群的机器人
    case getAddBotPageData = "/lark/bot/api/pull_chat_candidate_bots"
    /// 搜索可添加到群的机器人
    case searchBotData = "/lark/bot/api/search_v2"
    /// 添加机器人入群
    case addBotToGroup = "/open-apis/chatbot/api/SetBotAddConf"
    /// 从群内移出机器人
    case deleteBotFromGroup = "/open-apis/chatbot/api/DeleteBotResource"
    ///获得webhook机器人详情
    case getWebhookBotInfo = "/open-apis/chatbot/api/GetWebhookBotInfo"
    ///获得应用机器人详情
    case getAppBotInfo = "/open-apis/chatbot/api/fetch_bot_conf_resource"
    ///更新webhook机器人设置
    case updateWebhookBotInfo = "/open-apis/chatbot/api/UpdateWebhookBotInfo"
    /// 更新应用机器人设置
    case updateAppBotInfo = "/open-apis/chatbot/api/UpdateAppBotInfo"
    
    ///获得web Bot的信息
    case getWebBotInfo = "/lark/app_interface/app/info/get"
    
    ///更新通知
    case updateNotification = "/lark/app_interface/app/notification_type/update"

    // MARK: DarkMode Message Card CSS Style
    case getMessageCardStyle = "/lark/card/api/GetCardStyle"
    /// 拉取 极速打卡 配置
    case getSpeedClockInConfig = "/attendance/v2/clock_in/get_top_speed_clock_in_config"
    /// 触发 极速打卡
    case speedClockIn = "/attendance/v2/clock_in/top_speed_clock_in"
    /// 获得NativeApp可见性
    case getNativeAppGuideInfo = "/lark/app_interface/api/CheckNativeGuideInfo"
    /// empty
    case empty = ""
}

public enum APIParamKey: String {
    case app_id
    case open_id
    case ttcode
    case location
    case wifi
    case timestamp
    case user_id
    case message_id
    case trigger_code
    case open_chat_id
    case larkVersion
    case locale
    case appIdH5 = "appId"
    case shortLink
    case check_mender
    case need_chatable
    case need_meta_info
    case notification_type
    case businessTag
    case cursorInfo
    case message_ids
    case cli_id
    case platform
    case lark_version
    case link
    case token
    case expiration
    case deviceID
    /// 加号菜单更新用户外化展示配置。scope: unknown:0 close:1 recommend:2
    case displayType
    /// appID for 更新用户常用配置
    case common_app_ids
    /// scene for 更新用户常用配置
    case scene
    // MARK - group bot
    /// bot id
    case bot_id
    /// chat id
    case chat_id
    /// query string
    case query
    /// jsonString，后端过时的请求参数key
    case jsonString
    /// i18n
    case i18n
    /// 新卡片action
    case jsonstr
    case common
    case action
    /// https://lobster.byted.org/napp/230/method/156896641114981
    case GrayReq
    case TranCardType
    /// 急速打卡重构 参数
    case mw_tenant_id
    case mw_user_id
    case device_trace_id
    case gps
    case wifi_mac_address
    case scan_wifi_list
    case cli_ids
    case request_timestamp
    case risk_info
}

public enum APIHeaderKey: String {
    case Content_Type = "Content-Type"
    case X_Session_ID = "X-Session-ID"
    case Cookie = "Cookie"
    case Session = "Session"
    case RequestIDOP = "x-request-id-op"
    case RequestID = "x-request-id"
    case LogID = "x-tt-logid"
    case LobLogID = "lob-logid"
}

public enum APICookieKey: String {
    case session
}

/// 服务端定义的平台类型
enum PlatformType: Int {
    case pc = 0
    case mobile = 1
    case windows = 2
    case mac = 3
    case iphone = 4
    case androidMobile = 5
    case androidPad = 6
    case iPad = 7
    case unknown = 10000
}
