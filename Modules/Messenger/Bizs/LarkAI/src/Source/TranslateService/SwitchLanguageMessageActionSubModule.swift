//
//  File.swift
//  LarkAI
//
//  Created by Zigeng on 2023/3/23.
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

public final class SwitchLanguageMessageActionSubModule: MessageActionSubModule {
    @ScopedInjectedLazy private var translateService: NormalTranslateService?
    public override var type: MessageActionType {
        return .switchLanguage
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return AIFeatureGating.translationOptimizationSwitchLanguage.isUserEnabled(userResolver: context.userResolver)
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        if model.message.displayRule == .noTranslation || model.message.displayRule == .unknownRule {
            return false
        }
        return true
    }

    private func handle(message: Message, chat: Chat) {
        translateService?.showSelectLanguage(messageId: message.id,
                                            source: MessageSource.common(id: message.id),
                                            chatId: chat.id)
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        return MessageActionItem(text: BundleI18n.LarkAI.Lark_ASLTranslation_IMTranslatedText_MoreOptions_SwitchLanguages,
                                 icon: BundleResources.LarkAI.menu_switchLanguage,
                                 trackExtraParams: ["click": "switch_translate_language",
                                                    "target": "none"]) { [weak self] in
            self?.handle(message: model.message, chat: model.chat)
        }
    }
}
