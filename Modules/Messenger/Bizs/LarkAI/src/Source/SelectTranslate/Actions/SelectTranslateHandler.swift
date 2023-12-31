//
//  SelectTranslateHandler.swift
//  LarkAI
//
//  Created by zhaoyujie on 2022/8/2.
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

public final class SelectTranslateMessageActionSubModule: MessageActionSubModule {
    private static let logger = Logger.log(TranslateMessageActionSubModule.self, category: "SelectTranslate.SelectTranslateMessageActionSubModule")
    private var selectTranslateService: SelectTranslateService? {
        return try? self.context.userResolver.resolve(assert: SelectTranslateService.self)
    }

    public override var type: MessageActionType {
        return .selectTranslate
    }

    private func selectTranslate(message: Message, chat: Chat, copyType: CopyMessageType, selectedType: CopyMessageSelectedType) {
        guard let targetVC = self.context.targetVC,
              let modelService = try? self.context.userResolver.resolve(assert: ModelService.self) else { return }
        var resultAttr: String
        if case .richView(let callback) = selectedType, let (attr, _) = callback() {
            resultAttr = attr.string.trimmingCharacters(in: .whitespaces)
        } else {
            resultAttr = modelService.copyMessageSummerizeAttr(
                message,
                selectType: selectedType,
                copyType: copyType
            ).string.trimmingCharacters(in: .whitespaces)
        }
        let trackParam = [
            "messageID": message.id,
            "srcLanguage": message.messageLanguage,
            "chatID": chat.id,
            "cardSource": "im_card"
        ]
        selectTranslateService?.showSelectTranslateView(selectString: resultAttr, fromVC: targetVC, trackParam: trackParam)
    }

    // 是否可以初始化(FG)
    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return AIFeatureGating.selectTranslate.isUserEnabled(userResolver: context.userResolver)
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        switch model.selected() {
        case .all:
            return false
        default:
            break
        }
        if (model.message.content as? PostContent)?.isGroupAnnouncement == true {
            return false
        }
        switch model.message.type {
        case .text, .post:
            return true
        @unknown default:
            return false
        }
    }

    private func handle(_ model: MessageActionMetaModel) {
        selectTranslate(message: model.message, chat: model.chat, copyType: model.copyType, selectedType: model.selected())
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        return MessageActionItem(text: BundleI18n.LarkAI.Lark_ASL_SelectTranslate_TranslationResult_TitleTranslate,
                                 icon: BundleResources.LarkAI.menu_translate,
                                 trackExtraParams: ["click": "hyper_translate", "target": "none"]) { [weak self] in
            self?.selectTranslate(message: model.message, chat: model.chat, copyType: model.copyType, selectedType: model.selected())
        }
    }
}
