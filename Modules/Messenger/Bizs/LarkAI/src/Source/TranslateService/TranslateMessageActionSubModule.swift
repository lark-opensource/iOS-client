//
//  TranslateMessageActionSubModule.swift
//  LarkAI
//
//  Created by Zigeng on 2023/3/22.
//

import UIKit
import Foundation
import LKCommonsLogging
import LarkModel
import LarkMessageBase
import LarkMessengerInterface
import LarkContainer
import LarkOpenChat
import LarkSDKInterface
import LarkKAFeatureSwitch
import EENavigator
import LarkSearchCore
import LarkFeatureGating

public class BaseTranslateMessageActionSubModule: MessageActionSubModule {
    private static let logger = Logger.log(TranslateMessageActionSubModule.self, category: "TranslateService.TranslateMessageActionSubModule")
    private lazy var selectTranslateService: SelectTranslateService = SelectTranslateServiceImp(resolver: self.context.userResolver)
    @ScopedInjectedLazy fileprivate var translateService: NormalTranslateService?

    public override var type: MessageActionType {
        return .translate
    }

    // 是否可以handle(构造翻译ActionItem)
    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        let fg = self.context.userResolver.fg
        if (model.message.content as? PostContent)?.isGroupAnnouncement == true {
            return false
        }
        switch model.message.type {
        case .text, .post:
            return true
        case .audio:
            guard model.message.type == .audio else { return false }
            guard AIFeatureGating.audioMessageTranslation.isUserEnabled(userResolver: context.userResolver) else { return false }
            guard let audioContent = model.message.content as? AudioContent else { return false }
            return !audioContent.hideVoice2Text
        case .image:
            return fg.dynamicFeatureGatingValue(with: "translate.image.chat.menu.enable") && model.message.anyImageElementCanBeTranslated()
        case .card:
            guard model.message.isTranslatableMessageCardType(), let content = model.message.content as? CardContent else { return false }
            guard fg.dynamicFeatureGatingValue(with: "messagecard.translate.support") else { return false }
            return content.enableTrabslate || fg.dynamicFeatureGatingValue(with: "messagecard.translate.force_enable_translate")
        case .mergeForward:
            let isFromPrivateTopic = (model.message.content as? MergeForwardContent)?.isFromPrivateTopic ?? false
            return !isFromPrivateTopic
        @unknown default:
            return false
        }
    }

    func translate(message: Message, chat: Chat, from: UIViewController) {
        assertionFailure("Need to override")
    }

    private func handle(message: Message, chat: Chat) {
        guard let targetVC = context.targetVC else { return }
        /// 一级msg都是commonMessage
        translate(message: message, chat: chat, from: targetVC)
        let body = CheckAutoTranslateGuideBody(
            messageToOrigin: true,
            chatIsAutoTranslate: chat.isAutoTranslate,
            messageLanguage: message.messageLanguage
        )
        navigator.open(body: body, from: targetVC)
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        let (text, icon): (String, UIImage)
        switch model.message.displayRule {
            /// 原文
        case .noTranslation, .unknownRule:
            text = BundleI18n.LarkAI.Lark_ASL_SelectTranslate_TranslationResult_TitleTranslate
            icon = BundleResources.LarkAI.menu_translate
            let trackExtraParams = ["click": "translate", "target": "none"]
            /// 译文
        case .onlyTranslation:
            // 语音消息需要特殊的逻辑，语音消息的 onlyTranslation 和 withOriginal 都需要展示原文，所以两个情况都是展示 hideTranslate
            if model.message.type == .audio {
                text = BundleI18n.LarkAI.Lark_ASLTranslation_IMTranslatedText_MoreOptions_HideTranslation
                icon = BundleResources.LarkAI.menu_hide_translate
            } else {
                text = BundleI18n.LarkAI.Lark_ASLTranslation_IMTranslatedText_MoreOptions_ShowOriginal
                icon = BundleResources.LarkAI.menu_translate
            }
            let trackExtraParams = ["click": "original", "target": "none"]
            /// 原文+译文
        case .withOriginal:
            text = BundleI18n.LarkAI.Lark_ASLTranslation_IMTranslatedText_MoreOptions_HideTranslation
            icon = BundleResources.LarkAI.menu_hide_translate
            let trackExtraParams = ["click": "untranslate", "target": "none"]
        @unknown default:
            fatalError("unknown enum")
        }

        return MessageActionItem(text: text,
                                 icon: icon,
                                 trackExtraParams: [:]) { [weak self] in self?.handle(message: model.message, chat: model.chat) }
    }
}

public final class TranslateMessageActionSubModule: BaseTranslateMessageActionSubModule {
    // 是否可以初始化(FG)
    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return AIFeatureGating.enableTranslate.isUserEnabled(userResolver: context.userResolver)
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        if model.message.isSinglePreview {
            return false
        }
        return super.canHandle(model: model)
    }

    override func translate(message: Message, chat: Chat, from: UIViewController) {
        let translateParam = MessageTranslateParameter(message: message,
                                                       source: MessageSource.common(id: message.id),
                                                       chat: chat)
        translateService?.translateMessage(translateParam: translateParam, from: from)
    }
}

public class TranslateMessageActionSubModuleInMergeForward: BaseTranslateMessageActionSubModule {
    // 是否可以初始化(FG)
    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return AIFeatureGating.multiLayerTranslate.isUserEnabled(userResolver: context.userResolver)
    }
    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        // 合并转发界面内的合并转发消息和只支持text post
        return model.message.type == .text || model.message.type == .post
    }
    override func translate(message: Message, chat: Chat, from: UIViewController) {
        // 合并转发详情页面，翻译单个消息
        let translateParam = MessageTranslateParameter(message: message,
                                                       source: MessageSource.mergeForward(id: message.id, message: message),
                                                       chat: chat)
        translateService?.translateSingleMFMessage(translateParam: translateParam, from: from)
    }
}

// 消息链接化详情页复用合并转发页面，翻译和合并转发的翻译调用接口不同，单独写一个
public final class TranslateMessageActionSubModuleInMessageLink: TranslateMessageActionSubModuleInMergeForward {
    override func translate(message: Message, chat: Chat, from: UIViewController) {
        let translateParam = MessageTranslateParameter(message: message,
                                                       source: MessageSource.common(id: message.id),
                                                       chat: chat)
        translateService?.translateMessage(translateParam: translateParam, from: from)
    }
}
