//
//  LarkOpenBusinessBody.swift
//  LarkOPInterface
//
//  Created by bytedance on 2022/9/13.
//

import Foundation
import EENavigator

public enum AppSettingOpenScene: Int, Codable {
    case H5
    case MiniApp
}

/// Profile页打开场景
public enum AppDetailOpenScene: String, Codable {
    /// 机器人已被添加到群，支持删除
    case groupBotToRemove
    /// 机器人未被添加到群，支持添加
    case groupBotToAdd
}

public struct AppDetailBody: CodablePlainBody {
    public static let pattern = "//client/appdetail"

    public let botId: String
    public let appId: String
    public let params: [String: String]

    /// Profile页打开场景
    public let scene: AppDetailOpenScene?
    /// 群ID，目前服务于群机器人业务
    public let chatID: String?

    public init(botId: String = "", appId: String = "", params: [String: String] = [:], scene: AppDetailOpenScene? = nil, chatID: String? = nil) {
        self.botId = botId
        self.appId = appId
        self.params = params
        self.scene = scene
        self.chatID = chatID
    }
}

public struct AppSettingBody: CodablePlainBody {
    public static let pattern = "//client/appsetting"

    public let botId: String
    public let appId: String
    public let scene: AppSettingOpenScene
    public let params: [String: String]?

    /// 小程序跳转时将版本信息传入params，key为 version
    public init(botId: String = "",
                appId: String = "",
                params: [String: String]? = nil,
                scene: AppSettingOpenScene) {
        self.botId = botId
        self.appId = appId
        self.scene = scene
        self.params = params
    }
}

public struct ApplyForUseBody: CodablePlainBody {
    public static let pattern: String = "//client/applyforuse"

    public let appId: String?
    public let botId: String?
    public let appName: String

    public init(appId: String, appName: String) {
        self.appId = appId
        self.botId = nil
        self.appName = appName
    }

    public init(botId: String, appName: String) {
        self.botId = botId
        self.appId = nil
        self.appName = appName
    }

    public init(appId: String, botId: String, appName: String) {
        self.appId = appId
        self.botId = botId
        self.appName = appName
    }
}

/// 群机器人
public struct ChatGroupBotBody: CodablePlainBody {
    public static let pattern = "//client/forward/chatGroupBot"

    /// chat id
    public let chatId: String

    /// 是否是外部群
    public let isCrossTenant: Bool

    /// 群内是否已经有机器人
    public let hasBot: Bool

    public init(chatId: String, isCrossTenant: Bool, hasBot: Bool) {
        self.chatId = chatId
        self.isCrossTenant = isCrossTenant
        self.hasBot = hasBot
    }
}

