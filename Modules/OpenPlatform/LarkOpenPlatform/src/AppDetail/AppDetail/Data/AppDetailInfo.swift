//
//  AppDetailInfo.swift
//  LarkAppCenter
//
//  Created by yuanping on 2019/4/17.
//

import SwiftyJSON
import LarkLocalizations
import RustPB
import Swinject
import LarkOPInterface
import LarkSetting

enum AppSceneType: Int {
    case Enterprise = 0 // 企业自建应用
    case External = 1 // ISV应用
    case Personal = 2 // ISV个人应用
}

// 机器人聊天类型
enum AppDetailChatType: Int {
    case InterActiveBot = 1 // 交互Bot
    case NotifyBot = 2 // 只发通知消息的bot
    case InChatBot = 3 // 群内机器人，custom等通知机器人
    case HistoryMessage = 4 // 查看历史消息
}

enum NotificationType: Int {
    case None = 0
    case Open = 1
    case Close = 2
}

public struct ScopeInfo: Codable {
     var scopeID: Int64
     var scopeDesc: String
     enum CodingKeys: String, CodingKey {
         case scopeID = "scope_id"
         case scopeDesc = "desc"
     }
 }

struct AppDetailInfo {
    @FeatureGatingValue(key: "openplatform.basic.updatewebhookbotinfo.disable")
    static var isWebHookDisable: Bool
    
    struct I18nText: Codable {
        var value: String?
        var i18nValue: [String: String]?
    }

    static let jsonKeyData = "data"
    static let jsonKeyDataExtraInfo = "extraInfo"
    static let jsonKeyDataIsWebHook = "isWebHook"
    var appId: String
    var botId: String
    var titlesOfInter: [String: JSON] // 国际化标题
    var title: String
    var descriptionsOfInter: [String: JSON]
    var description: String
    var appType: Int? // 每一位含义不同，二进制的1 2 8分别代表 小程序 h5 bot，可能出现组合，类似1001就是拥有小程序+bot
    var appSceneType: Int?
    var avatarKey: String
    var avatar: String
    var developerInfosOfInter: [String: JSON]
    var developerInfo: String
    var developerDisplayName: I18nText?  // 开发者别名
    var appStatus: Int?
    var showFeedback: Bool
    var directionsOfInter: [String: JSON]
    var direction: String // 使用说明
    var clauseUrlOfInter: [String: JSON]
    var clauseUrl: String // 合同条款
    var privacyUrlOfInter: [String: JSON]
    var privacyUrl: String // 隐私条款
    var version: String
    var tenantId: Int64?
    var appUrl: String // 打开小程序和H5的url
    var developerId: String
    var chatable: Bool?
    var chatType: Int?
    var isOnCall: Bool? // 是否是值班号
    var notificationType: NotificationType  ///通知类型 0 - 无此能力  1 - 开启  2 - 关闭
    var canApplyVisibility: Bool? // 应用不可见时，是否可申请
    /// 国际化帮助文档
    var helpsOfInter: [String: JSON]
    /// 默认帮助文档
    var helpDoc: String
    var i18nBotInviterName: [String: JSON]?   // 机器人邀请者名字i18n
    var botInviterName: String?               // 机器人邀请者名字
    var botInviterDisplayName: I18nText?      // 机器人邀请者别名
    var botInviterID: String?                 // 机器人邀请者id，如果有则允许点击跳转会话
    var extraInfo: AbstractBotExtraInfo?
    var isWebHook: Bool?
    var appReviewInfo: AppReviewInfo?
    var h5Applink: String?
    var receiveMessageSetting: ReceiveMessageType?
    var scopeInfo: [ScopeInfo]?

    init(json: JSON, shouldDecodeGroupBotExtraInfo: Bool = false) {
        appId = json["data"]["cli_id"].stringValue
        botId = json["data"]["bot_id"].stringValue
        titlesOfInter = json["data"]["i18n_names"].dictionaryValue
        title = json["data"]["name"].stringValue
        helpsOfInter = json["data"]["i18n_help_file"].dictionaryValue
        helpDoc = json["data"]["help_file"].stringValue
        descriptionsOfInter = json["data"]["i18n_descriptions"].dictionaryValue
        description = json["data"]["description"].stringValue
        appType = json["data"]["app_type"].int
        appSceneType = json["data"]["app_scene_type"].int
        avatarKey = json["data"]["avatar_url"].stringValue
        avatar = json["data"]["avatar_key"].stringValue
        developerInfosOfInter = json["data"]["i18n_developer_info"].dictionaryValue
        developerInfo = json["data"]["developer_info"].stringValue
        appStatus = json["data"]["status"].int
        showFeedback = json["data"]["open_feedback"].boolValue
        direction = json["data"]["directions"].stringValue
        directionsOfInter = json["data"]["i18n_directions"].dictionaryValue
        clauseUrl = json["data"]["clause_url"].stringValue
        clauseUrlOfInter = json["data"]["i18n_clause_urls"].dictionaryValue
        privacyUrl = json["data"]["privacy_url"].stringValue
        privacyUrlOfInter = json["data"]["i18n_privacy_urls"].dictionaryValue
        version = json["data"]["app_version"].stringValue
        tenantId = json["data"]["tenant_id"].int64
        appUrl = json["data"]["app_url"].stringValue
        developerId = json["data"]["developer_id"].stringValue
        chatable = json["data"]["chatable"].bool
        chatType = json["data"]["chat_type"].int
        isOnCall = json["data"]["is_oncall"].bool
        canApplyVisibility = json["data"]["can_apply_visibility"].bool
        i18nBotInviterName = json["data"]["i18n_bot_inviter_name"].dictionary
        botInviterName = json["data"]["bot_inviter_name"].string
        botInviterID = json["data"]["bot_inviter_id"].string
        h5Applink = json["data"]["h5_app_link"].string
        if !Self.isWebHookDisable {        
            isWebHook = json[AppDetailInfo.jsonKeyData][AppDetailInfo.jsonKeyDataIsWebHook].bool
        }
        let receiveMessageType: Int = Int(json["data"]["bot_mute_status"].int64 ?? -1)
        receiveMessageSetting = ReceiveMessageType.init(rawValue: receiveMessageType)
        let originalDeveloperName = json["data"]["developer_display_name"]
        if let data = try? originalDeveloperName.rawData() {
            let decoder = JSONDecoder()
            developerDisplayName = try? decoder.decode(I18nText.self, from: data)
        }
        let originalBotInviterName = json["data"]["bot_inviter_display_name"]
        if let data = try? originalBotInviterName.rawData() {
            let decoder = JSONDecoder()
            botInviterDisplayName = try? decoder.decode(I18nText.self, from: data)
        }
        let botScopeList = json["data"]["bot_auth_info"]
        if let data = try? botScopeList.rawData() {
            let decoder = JSONDecoder()
            scopeInfo = try? decoder.decode([ScopeInfo].self, from: data)
        }
        
        /// 0 - 无此能力  1 - 开启  2 - 关闭
        if let notiType = json["data"]["notification_type"].int {
            switch notiType {
            case 0:
                notificationType = .None
            case 1:
                notificationType = .Open
            case 2:
                notificationType = .Close
            default:
                notificationType = .None
            }
        } else {
            notificationType = .None
        }
        if shouldDecodeGroupBotExtraInfo {
            // 添加额外机器人信息
            extraInfo = Self.decodeExtraInfo(json: json)

            /** 产品要求：和线上现有逻辑保持逻辑一致，先不展示添加者信息，只展示开发者信息
            // 补充添加者相关内容
            if (botInviterName?.isEmpty ?? true) {
                botInviterName = extraInfo?.inviterName
            }
            if (botInviterID?.isEmpty ?? true) {
                botInviterID = extraInfo?.inviterID
            }
            */
        }
    }

    static func decodeExtraInfo(json: JSON) -> AbstractBotExtraInfo? {
        let isWebhook = json[AppDetailInfo.jsonKeyData][AppDetailInfo.jsonKeyDataIsWebHook].bool ?? false
        let decoder = JSONDecoder()
        if let data = try? json[AppDetailInfo.jsonKeyData][AppDetailInfo.jsonKeyDataExtraInfo].rawData() {
            if isWebhook {
                if let info = try? decoder.decode(WebhookBotExtraInfo.self, from: data) {
                    return info
                }
            } else {
                if let info = try? decoder.decode(AppBotExtraInfo.self, from: data) {
                    return info
                }
            }
        }
        return nil
    }

    static func encodeExtraInfo(json: inout JSON, isWebHook: Bool, extraInfo: AbstractBotExtraInfo?) {
        let encoder = JSONEncoder()
        var data: Data?
        if let info = extraInfo as? WebhookBotExtraInfo {
            data = try? encoder.encode(info)
        } else if let info = extraInfo as? AppBotExtraInfo {
            data = try? encoder.encode(info)
        }
        if let data = data, let jsonStr = String(data: data, encoding: .utf8) {
            json[AppDetailInfo.jsonKeyData][AppDetailInfo.jsonKeyDataExtraInfo] = JSON(parseJSON: jsonStr)
        }
        json[AppDetailInfo.jsonKeyData][AppDetailInfo.jsonKeyDataIsWebHook] = JSON(isWebHook)
    }

    /// 获取国际化字段值
    /// - Parameters:
    ///   - fromJson: 国际化字段JSON
    ///   - default: 默认字段值
    func getLocal(fromJson: [String: JSON], defaultContent: String) -> String {
        /// 国际化语言(适配后台逻辑，国际化Key统一使用小写)
        let localLanguage = LanguageManager.currentLanguage.rawValue.lowercased()
        if let localContent = fromJson[localLanguage]?.rawString(), !localContent.isEmpty {
            return localContent
        } else {    // 默认内容
            return defaultContent
        }
    }

    /// 获取国际化语言的title
    func getLocalTitle() -> String {
        return getLocal(fromJson: titlesOfInter, defaultContent: title)
    }

    /// 获取国际化语言的description
    func getLocalDescription() -> String {
        return getLocal(fromJson: descriptionsOfInter, defaultContent: description)
    }

    /// 获取国际化语言的开发者信息
    func getLocalDeveloperInfo() -> String {
        let localeLanguage = LanguageManager.currentLanguage.rawValue.lowercased()
        if let i18nName = developerDisplayName?.i18nValue?[localeLanguage], !i18nName.isEmpty {
            return i18nName
        } else if let nameValue = developerDisplayName?.value, !nameValue.isEmpty {
            return nameValue
        } else {
            return getLocal(fromJson: developerInfosOfInter, defaultContent: developerInfo)
        }
    }

    /// 获取国际化语言的群机器人邀请者信息
    func getLocalBotInviterName() -> String? {
        let localeLanguage = LanguageManager.currentLanguage.rawValue.lowercased()
        if let i18nName = botInviterDisplayName?.i18nValue?[localeLanguage], !i18nName.isEmpty {
            return i18nName
        } else if let nameValue = botInviterDisplayName?.value, !nameValue.isEmpty {
            return nameValue
        } else if let botInviterName = botInviterName {
            return getLocal(fromJson: i18nBotInviterName ?? [:], defaultContent: botInviterName)
        } else {
            // 没有邀请人信息
            return nil
        }
    }

    /// 获取帮助文档信息
    func getHelpDocInfo() -> String {
        return getLocal(fromJson: helpsOfInter, defaultContent: helpDoc)
    }

    /// 获取国际化语言的使用说明
    func getLocalDirection() -> String {
        return getLocal(fromJson: directionsOfInter, defaultContent: direction)
    }

    /// 获取国际化语言的合同条款
    func getLocalClauseUrl() -> String {
        return getLocal(fromJson: clauseUrlOfInter, defaultContent: clauseUrl)
    }

    /// 获取国际化语言的隐私条款
    func getLocalPrivacyUrl() -> String {
        return getLocal(fromJson: privacyUrlOfInter, defaultContent: privacyUrl)
    }

    func curAppStatus() -> OpenApp.State? {
        guard let status = appStatus else { return nil }
        return OpenApp.State(rawValue: status)
    }

    func canApplyAccessWhenInVisible() -> Bool {
        return canApplyVisibility ?? true
    }

    func curAvatar(width widthIn: Int?, height heightIn: Int?, type: String? = nil, scale scaleIn: Float? = nil) -> String {
        guard var width = widthIn, var height = heightIn, width > 0, height > 0 else {
            return "\(avatarKey)~noop.\(type ?? "image")"
        }
        var scale: Float = 2.0
        if scaleIn == nil {
            scale = Float(UIScreen.main.scale)
        }
        width = Int(Float(width) * scale)
        height = Int(Float(height) * scale)
        return "\(avatarKey)~\(width)x\(height).\(type ?? "image")"
    }

    func curAppSceneType() -> AppSceneType? {
        guard let type = appSceneType else { return nil }
        return AppSceneType(rawValue: type)
    }

    func curChatType() -> AppDetailChatType {
        guard let type = chatType, let curType = AppDetailChatType(rawValue: type)  else {
            return .InChatBot
        }
        return curType
    }

    func isISV() -> Bool {
        guard let appType = curAppSceneType() else { return false }
        return appType == .External || appType == .Personal
    }

    func getAppType() -> ApplicationType {
        if isOnCall ?? false {
            return .oncall
        } else if let scene = appSceneType {
            if scene == AppSceneType.Enterprise.rawValue {
                return .customapp
            } else {
                return .publicapp
            }
        } else {
            return .others
        }
    }
}

/// 判断应用类型
enum ApplicationType: String {
    /// 自建应用
    case customapp
    /// 商店应用（webhook机器人、套件机器人等目前暂时归于此类目下）
    case publicapp
    /// oncall机器人
    case oncall
    /// 其他的访问类型
    case others
}
