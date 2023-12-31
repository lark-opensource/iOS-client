//
//  OPNetworkUtil.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2023/11/14.

import Foundation
import ECOInfra
import LarkSetting
import LKCommonsLogging
import OPFoundation

final class OPNetworkUtil {
    typealias ECONetworkReqComponents = (url: String, header: [String: String], params: [String: Any], context: OpenECONetworkContext)
    
    /// 卡片使用ECONetwork FG开关
    static func cardUseECONetworkEnabled() -> Bool {
        return OPUserScope.userResolver().fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.card.use.econetwork.enable"))
    }
    /// 开放业务使用ECONetwork FG开关
    static func basicUseECONetworkEnabled() -> Bool {
        return OPUserScope.userResolver().fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.basic.use.econetwork.enable"))
    }
    
    private static func domain(_ alias: DomainKey) -> String {
        return DomainSettingManager.shared.currentSetting[alias]?.first ?? ""
    }
    
    private static func url(with host: String, path: String) -> String? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        if let url = components.url {
            return url.absoluteString
        }
        return nil
    }
    /// 旧版消息卡片样式数据接口
    /// - Method: POST
    static func getCardStyleURL() -> String? {
        return url(with: domain(.openMsgCard), path: APIUrlPath.getMessageCardStyle.rawValue)
    }
    /// 消息卡片与小程序等容器互动接口
    /// - Method: POST
    static func getCardBindTriggerCodeURL() -> String? {
        return url(with: domain(.openMsgCard), path: APIUrlPath.messageCardBindTriggerCode.rawValue)
    }
    /// +号菜单外化展示接口
    /// - Method: POST
    static func getPlusMenuExternalItemsURL() -> String? {
        return url(with: domain(.openAppcenter3), path: APIUrlPath.getPlusMenuExternalItems.rawValue)
    }
    /// +号菜单更多应用接口
    /// - Method: POST
    static func getPlusMenuListV1URL() -> String? {
        return url(with: domain(.openAppcenter3), path: APIUrlPath.getPlusMenuListV1.rawValue)
    }
    /// 消息快捷操作外化展示接口
    /// - Method: POST
    static func getMsgActionExternalItemsURL() -> String? {
        return url(with: domain(.openAppcenter3), path: APIUrlPath.getMsgActionExternalItems.rawValue)
    }
    /// 消息快捷操作更多应用接口
    /// - Method: POST
    static func getMsgActionListV1URL() -> String? {
        return url(with: domain(.openAppcenter3), path: APIUrlPath.getMsgActionListV1.rawValue)
    }
    /// 更新消息快捷操作|+号菜单用户常用配置接口
    /// - Method: POST
    static func getUpdateUserCommonAppsURL() -> String? {
        return url(with: domain(.openAppcenter3), path: APIUrlPath.updateUserCommonApps.rawValue)
    }
    /// 获取添加至群聊机器人接口
    /// - Method: POST
    static func getGroupBotListPageDataURL() -> String? {
        return url(with: domain(.openAppInterface), path: APIUrlPath.getGroupBotListPageData.rawValue)
    }
    /// 机器人添加至群聊接口
    /// - Method: POST
    static func getAddBotToGroupURL() -> String? {
        return url(with: domain(.open), path: APIUrlPath.addBotToGroup.rawValue)
    }
    /// 获取可以添加至群聊机器人&已添加至群聊机器人接口
    /// - Method: POST
    static func getAddBotPageDataURL() -> String? {
        return url(with: domain(.openAppInterface), path: APIUrlPath.getAddBotPageData.rawValue)
    }
    /// 搜多可以添加至群聊机器人接口
    /// - Method: POST
    static func getSearchBotDataURL() -> String? {
        return url(with: domain(.openAppInterface), path: APIUrlPath.searchBotData.rawValue)
    }
    /// 更新Webhook机器人设置接口
    /// - Method: POST
    static func getUpdateWebhookBotInfoURL() -> String? {
        return url(with: domain(.open), path: APIUrlPath.updateWebhookBotInfo.rawValue)
    }
    /// 更新应用机器人设置接口
    /// - Method: POST
    static func getUpdateAppBotInfoURL() -> String? {
        return url(with: domain(.open), path: APIUrlPath.updateAppBotInfo.rawValue)
    }
    /// 从群聊中移除机器人接口
    /// - Method: POST
    static func getDelBotFromGroupURL() -> String? {
        return url(with: domain(.open), path: APIUrlPath.deleteBotFromGroup.rawValue)
    }
    /// 获取应用能力信息接口
    /// - Method: POST
    static func getShareAppInfoURL() -> String? {
        return url(with: domain(.internalApi), path: APIUrlPath.getShareAppInfo.rawValue)
    }
    /// AppLink长链生成短链接口
    /// - Method: POST
    static func getAppLinkShortLinkV1URL() -> String? {
        return url(with: domain(.open), path: APIUrlPath.generateShortAppLink.rawValue)
    }
    /// 获得Webhook机器人详情
    /// - Method: POST
    static func getWebhookBotInfoURL() -> String? {
        return url(with: domain(.open), path: APIUrlPath.getWebhookBotInfo.rawValue)
    }
    /// 获得应用机器人详情
    /// - Method: POST
    static func getAppBotInfoURL () -> String? {
        return url(with: domain(.open), path: APIUrlPath.getAppBotInfo.rawValue)
    }
    
    static func reportLog(_ log: Log, response: ECOInfra.ECONetworkResponse<[String: Any]>?) -> String {
        guard let response = response else {
            log.error("network util report response log failed")
            return ""
        }
        let path = response.request.url?.path ?? ""
        let headerFields = response.response.allHeaderFields
        var logID = headerFields[APIHeaderKey.LogID.rawValue] as? String
        if logID.isEmpty {
            logID = headerFields[APIHeaderKey.LobLogID.rawValue] as? String
        }
        let code = response.response.statusCode
        log.info("network util report request \(path), response status code: \(code), logid: \(logID ?? "")")
        return logID ?? ""
    }
}
