//
//  OpenPlatformAPI+GroupBot.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/10.
//

import LarkFoundation
import LarkAccountInterface
import LarkContainer

/// 添加机器人进群相关API
extension OpenPlatformAPI {
    // MARK: scope groupBot
    /// 获得已经添加到群的机器人
    public static func getGroupBotListPageDataAPI(chatID: String, resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .getGroupBotListPageData, resolver: resolver)
            .setMethod(.post)
            .useSession()
            .appendParam(key: .chat_id, value: chatID)
            .appendParam(key: .larkVersion, value: Utils.appVersion)
            .appendCookie()
            .useLocale()
            .setScope(.groupBot)
    }

    /// 获得可添加到群的机器人的API，同时附带已添加到群的机器人
    public static func getAddBotPageDataAPI(chatID: String, resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .getAddBotPageData, resolver: resolver)
            .setMethod(.post)
            .useSession()
            .appendParam(key: .chat_id, value: chatID)
            .appendParam(key: .larkVersion, value: Utils.appVersion)
            .appendCookie()
            .useLocale()
            .setScope(.groupBot)
    }

    /// 搜索可添加到群的机器人
    public static func searchBotData(chatID: String, query: String, resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .searchBotData, resolver: resolver)
            .setMethod(.post)
            .useSession()
            .appendParam(key: .query, value: query)
            .appendParam(key: .chat_id, value: chatID)
            .appendParam(key: .larkVersion, value: Utils.appVersion)
            .appendCookie()
            .useLocale()
            .setScope(.groupBot)
    }
    
    /// 添加机器人入群
    public static func addBotToGroup(botID: String, chatID: String, source: AppGroupBotSource? = .searchPanel, checkMender: Bool? = false, resolver: UserResolver) -> OpenPlatformAPI {
        var api = OpenPlatformAPI(path: .addBotToGroup, resolver: resolver)
            .setMethod(.post)
            .useSession()
            .appendParam(key: .bot_id, value: botID)
            .appendParam(key: .chat_id, value: chatID)
            .appendParam(key: .larkVersion, value: Utils.appVersion)
            .appendParam(key: .i18n, value: OpenPlatformAPI.curLanguage())
            .appendCookie()
            .useLocale()
            .setScope(.groupBotManage)
        if source == .profile {
            api.appendParam(key: .check_mender, value: checkMender)
        }
        return api
    }
    
    //删除机器人
    public static func deleteBotFromGroupAPI(botID: String, chatID: String, resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .deleteBotFromGroup, resolver: resolver)
            .setMethod(.post)
            .useSession()
            .appendParam(key: .bot_id, value: botID)
            .appendParam(key: .chat_id, value: chatID)
            .appendParam(key: .larkVersion, value: Utils.appVersion)
            .appendParam(key: .i18n, value: OpenPlatformAPI.curLanguage())
            .appendCookie()
            .useLocale()
            .setScope(.groupBotManage)
    }
    
    ///获得Webhook机器人详情
    public static func fetchWebhookBotInfoAPI(botID: String, resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .getWebhookBotInfo, resolver: resolver)
            .setMethod(.post)
            .useSession()
            .appendParam(key: .bot_id, value: botID)
            .appendParam(key: .larkVersion, value: Utils.appVersion)
            .appendParam(key: .i18n, value: OpenPlatformAPI.curLanguage())
            .appendCookie()
            .useLocale()
            .setScope(.groupBotManage)
    }
    
    ///获得应用机器人详情
    public static func fetchAppBotInfoAPI(botID: String, chatID: String, resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .getAppBotInfo, resolver: resolver)
            .setMethod(.post)
            .useSession()
            .appendParam(key: .bot_id, value: botID)
            .appendParam(key: .chat_id, value: chatID)
            .appendParam(key: .larkVersion, value: Utils.appVersion)
            .appendParam(key: .i18n, value: OpenPlatformAPI.curLanguage())
            .appendCookie()
            .useLocale()
            .setScope(.groupBotManage)
    }
    
    ///更新Webhook机器人设置
    public static func updateWebhookBotInfoAPI(botID: String, checkMender: Bool, resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .updateWebhookBotInfo, resolver: resolver)
            .setMethod(.post)
            .useSession()
            .appendParam(key: .bot_id, value: botID)
            .appendParam(key: .check_mender, value: checkMender)
            .appendParam(key: .larkVersion, value: Utils.appVersion)
            .appendParam(key: .i18n, value: OpenPlatformAPI.curLanguage())
            .appendCookie()
            .useLocale()
            .setScope(.groupBotManage)
    }
    
    ///更新应用机器人设置
    public static func updateAppBotInfoAPI(botID: String, chatID: String, checkMender: Bool, resolver: UserResolver) -> OpenPlatformAPI {
        return OpenPlatformAPI(path: .updateAppBotInfo, resolver: resolver)
            .setMethod(.post)
            .useSession()
            .appendParam(key: .bot_id, value: botID)
            .appendParam(key: .chat_id, value: chatID)
            .appendParam(key: .larkVersion, value: Utils.appVersion)
            .appendParam(key: .i18n, value: OpenPlatformAPI.curLanguage())
            .appendParam(key: .check_mender, value: checkMender)
            .appendCookie()
            .useLocale()
            .setScope(.groupBotManage)
    }
}
