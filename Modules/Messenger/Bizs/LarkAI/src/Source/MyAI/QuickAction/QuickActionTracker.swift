//
//  QuickActionTracker.swift
//  LarkAI
//
//  Created by Hayden on 6/9/2023.
//

import LarkCore
import LarkModel
import LarkAIInfra
import LarkMessengerInterface

/// 快捷指令埋点工具类，从 PageService 中获取
class QuickActionTracker {

    /// 快捷指令展示的位置
    enum Location: String {
        /// 在进页面未产生任何会话时展示的快捷指令
        case onboardingCard = "onboarding"
        /// 跟随消息气泡展示（新样式）
        case followMessage = "follow_up"
        /// 在输入框上方（老样式）
        case overEditor = "over_chatbox"
        /// 业务方主动触发的快捷指令，预期又业务方来定义Location。如果业务方没有传，默认传个unknown
        case unknown = "unknown"
    }

    private let chatId: String
    private let shadowId: String
    private let chatMode: Bool
    private let chatFromWhere: ChatFromWhere
    private weak var chatModeConfig: MyAIChatModeConfig?

    init(chatId: String, shadowId: String, chatMode: Bool, chatFromWhere: ChatFromWhere, chatModeConfig: MyAIChatModeConfig?) {
        self.chatId = chatId
        self.shadowId = shadowId
        self.chatMode = chatMode
        self.chatFromWhere = chatFromWhere
        self.chatModeConfig = chatModeConfig
    }

    private var quickActionGeneralPramas: [String: Any] {
        var generalParams: [String: Any] = [
            "chat_id": chatId,
            "shadow_id": shadowId,
            "scene": chatMode ? "im_chat_mode_view" : "im_chat_view",
            "app_name": "other",
            "chat_type": "single",
            "chat_type_detail": "single_ai"
        ]
        // 从 chatModeConfig 获取业务方埋点信息
        if let chatModeConfig = chatModeConfig {
            generalParams["app_id"] = chatModeConfig.extra["app_id"] // 小程序需要传
            generalParams["app_name"] = chatModeConfig.extra["app_name"] ?? "other"
            generalParams["session_id"] = chatModeConfig.extra["session_id"]
        }
        return generalParams
    }

    func reportQuickActionShownEvent(_ quickActions: [AIQuickActionModel],
                                     roundId: String,
                                     location: Location,
                                     fromChat chat: Chat? = nil,
                                     extraParams: [String: Any]? = nil) {
        let actions = quickActions.compactMap({ $0.toJsonString() })
        guard !actions.isEmpty else { return }
        var params = quickActionGeneralPramas
        params["round_id"] = roundId
        params["location"] = location.rawValue
        params["action_obj"] = actions
        params["action_cnt"] = actions.count
        if let extraParams = extraParams {
            params.merge(extraParams, uniquingKeysWith: { _, new in new })
        }
        IMTracker.Chat.Main.QuickActionView(params: params, chat: chat, chatFromWhere: chatFromWhere)
        MyAITopExtendSubModule.logger.info("[MyAI.QuickAction][Track] \(#function), \(params)")
    }

    func reportQuickActionClickEvent(_ quickAction: AIQuickActionModel,
                                     roundId: String,
                                     location: Location,
                                     fromChat chat: Chat? = nil,
                                     extraParams: [String: Any]? = nil) {
        var params = quickActionGeneralPramas
        params["round_id"] = roundId
        params["location"] = location.rawValue
        params["click"] = "shortcut_command"
        params["action_id"] = quickAction.id
        params["type"] = quickAction.trackTypeName
        if let extraParams = extraParams {
            params.merge(extraParams, uniquingKeysWith: { _, new in new })
        }
        IMTracker.Chat.Main.Click.QuickAction(params: params, chat: chat, chatFromWhere: chatFromWhere)
        MyAITopExtendSubModule.logger.info("[MyAI.QuickAction][Track] \(#function), \(params)")
    }

    func reportQuickActionSendEvent(_ quickAction: AIQuickActionModel?,
                                    roundId: String,
                                    location: Location,
                                    isEdited: Bool,
                                    fromChat chat: Chat? = nil,
                                    extraParams: [String: Any]? = nil) {
        guard let quickAction = quickAction else { return }
        var params = quickActionGeneralPramas
        params["round_id"] = roundId
        params["location"] = location.rawValue
        params["click"] = isEdited ? "input_send" : "direct_send"
        params["action_id"] = quickAction.id
        params["type"] = quickAction.trackTypeName
        if let extraParams = extraParams {
            params.merge(extraParams, uniquingKeysWith: { _, new in new })
        }
        IMTracker.Chat.Main.Click.QuickAction(params: params, chat: chat, chatFromWhere: chatFromWhere)
        MyAITopExtendSubModule.logger.info("[MyAI.QuickAction][Track] \(#function), \(params)")
    }
}

fileprivate extension AIQuickActionModel {

    /// 将 AIQuickAction 转为 JsonString 供埋点使用
    func toJsonString() -> String? {
        let variables: [String: String] = ["action_id": id, "type": trackTypeName]
        if let jsonData = try? JSONSerialization.data(withJSONObject: variables, options: []) {
            return String(data: jsonData, encoding: .utf8)
        }
        return nil
    }

    /// 埋点时上报的快捷指令 "type"
    var trackTypeName: String {
        if typeIsQuery {
            return "query"
        } else {
            return needUserInput ? "parameter" : "no_parameter"
        }
    }
}
