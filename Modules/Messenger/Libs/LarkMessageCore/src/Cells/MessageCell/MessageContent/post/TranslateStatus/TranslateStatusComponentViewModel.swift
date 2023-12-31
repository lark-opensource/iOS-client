//
//  TranslateStatusComponentViewModel.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/2/17.
//

import Foundation
import Homeric
import LarkModel
import LarkStorage
import LarkSearchCore
import LarkMessageBase
import LKCommonsTracker
import LarkSDKInterface
import LarkMessengerInterface

final class TranslateStatusComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: NewMessageSubViewModel<M, D, C> {
    /// 翻译服务
    private lazy var translateService: NormalTranslateService? = {
        return try? self.context.resolver.resolve(assert: NormalTranslateService.self)
    }()

    var translateStatus: Message.TranslateState {
        return message.translateState
    }

    var canShowTranslateIcon: Bool {
        return LarkMessageCore.canShowTranslateIcon(message: message, chat: metaModel.getChat(), isFromMe: isFromMe)
    }

    var isFromMe: Bool {
        return context.isMe(message.fromId, chat: metaModel.getChat())
    }

    var translateTrackInfo: [String: Any] {
        var trackInfo = [String: Any]()
        trackInfo["chat_id"] = metaModel.getChat().id
        trackInfo["chat_type"] = chatTypeForTracking
        trackInfo["msg_id"] = message.id
        trackInfo["message_language"] = message.messageLanguage
        return trackInfo
    }

    var chatTypeForTracking: String {
        if metaModel.getChat().chatMode == .threadV2 {
            return "topic"
        } else if metaModel.getChat().type == .group {
            return "group"
        } else {
            return "single"
        }
    }

    /// 显示原文、收起译文
    func translateTapHandler() {
        guard let vc = self.context.pageAPI else {
            assertionFailure()
            return
        }
        var trackInfo = self.translateTrackInfo
        trackInfo["click"] = "translate"
        Tracker.post(TeaEvent(Homeric.ASL_CROSSLANG_TRANSLATION_IM_CLICK, params: trackInfo))
        let translateParam = MessageTranslateParameter(message: message,
                                                       source: MessageSource.common(id: message.id),
                                                       chat: metaModel.getChat())
        self.translateService?.translateMessage(translateParam: translateParam, from: vc)
    }
}

func canShowTranslateIcon(message: Message, chat: Chat, isFromMe: Bool) -> Bool {
    let mainLanguage = KVPublic.AI.mainLanguage.value()
    let messageCharThreshold = KVPublic.AI.messageCharThreshold.value()
    var canShowTranslateIcon: Bool {
        guard AIFeatureGating.translationOptimization.isEnabled else { return false }
        if mainLanguage.isEmpty { return false }
        if message.messageLanguage.isEmpty { return false }
        if message.messageLanguage == "not_lang" { return false }
        if message.type == .audio { return false }
        if messageCharThreshold <= 0 { return false }
        if message.characterLength <= 0 { return false }
        let isMainLanguage = mainLanguage == message.messageLanguage
        let isBeyondCharThreshold = message.characterLength >= messageCharThreshold
        let isAutoTranslate = chat.isAutoTranslate
        return !message.isRecalled && !isFromMe && !isMainLanguage && isBeyondCharThreshold && !isAutoTranslate && !chat.isP2PAi
    }
    return canShowTranslateIcon && !message.isFoldRootMessage
}
