//
//  APIContextModifier.swift
//  LarkChat
//
//  Created by 李勇 on 2023/12/19.
//

import Foundation
import RxSwift
import RxCocoa
import LarkModel
import LarkAIInfra
import LarkSendMessage
import LarkMessengerInterface

/// 部分Modifier设置属性需要依赖一些额外的信息
final class ExtraInfo {
    var parentMessage: Message?

    init(parentMessage: Message?) {
        self.parentMessage = parentMessage
    }
}
/// 用于消息发送前，对APIContext属性进行调整
protocol APIContextModifier: AnyObject {
    func modify(for context: APIContext, info: ExtraInfo)
}

/// 设置DisplayMode
final class DisplayModeModifier: APIContextModifier {
    private let chat: BehaviorRelay<Chat>

    init(chat: BehaviorRelay<Chat>) {
        self.chat = chat
    }

    func modify(for context: APIContext, info: ExtraInfo) {
        context.chatDisplayMode = self.chat.value.displayMode
    }
}

/// 设置ChatFrom
final class ChatFromModifier: APIContextModifier {
    private let fromWhere: ChatFromWhere

    init(fromWhere: ChatFromWhere) {
        self.fromWhere = fromWhere
    }

    func modify(for context: APIContext, info: ExtraInfo) {
        context.set(key: APIContext.chatFromWhere, value: self.fromWhere.rawValue)
    }
}

/// 设置ChatModeConfig
final class ChatModeConfigModifier: APIContextModifier {
    private let chatModeConfig: MyAIChatModeConfig

    init(chatModeConfig: MyAIChatModeConfig) {
        self.chatModeConfig = chatModeConfig
    }

    func modify(for context: APIContext, info: ExtraInfo) {
        context.set(key: APIContext.myAIChatModeConfig, value: self.chatModeConfig)
    }
}

/// 设置MainChatConfig
final class MainChatConfigModifier: APIContextModifier {
    private let mainChatConfig: MyAIMainChatConfig

    init(mainChatConfig: MyAIMainChatConfig) {
        self.mainChatConfig = mainChatConfig
    }

    func modify(for context: APIContext, info: ExtraInfo) {
        context.set(key: APIContext.myAIMainChatConfig, value: self.mainChatConfig)
    }
}

/// 设置PartialReplyInfo
final class PartialReplyInfoModifier: APIContextModifier {
    private var getReplyInfoForMessage: ((Message?) -> PartialReplyInfo?)?

    init(getReplyInfoForMessage: ((Message?) -> PartialReplyInfo?)?) {
        self.getReplyInfoForMessage = getReplyInfoForMessage
    }

    func modify(for context: APIContext, info: ExtraInfo) {
        if let parentMessage = info.parentMessage, let replyInfo = self.getReplyInfoForMessage?(parentMessage) {
            context.set(key: APIContext.partialReplyInfo, value: replyInfo)
        }
    }
}
