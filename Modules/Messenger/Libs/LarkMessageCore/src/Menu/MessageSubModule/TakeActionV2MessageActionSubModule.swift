//
//  TakeActionV2.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/1/10.
//

import Foundation
import LarkModel
import RxSwift
import LarkOpenChat
import UniverseDesignToast
import LarkContainer
import LarkGuide
import SuiteAppConfig

public final class TakeActionV2MessageActionSubModule: MessageActionSubModule {
    @ScopedInjectedLazy private var chatMicroAppDependency: ChatMicroAppDependency?
    @ScopedInjectedLazy private var guideService: GuideService?
    public override var type: MessageActionType {
        return .takeActionV2
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return AppConfigManager.shared.feature(for: .messageAction).isOn
    }

    private func handle(message: Message, chat: Chat) {
        guard let targetVC = self.context.pageAPI,
              let chatMicroAppDependency = chatMicroAppDependency,
              let guideService = guideService else { return }
        chatMicroAppDependency.takeMessageActionV2(chatId: chat.id,
                                                   messageIds: [message.id],
                                                   isMultiSelect: false,
                                                   targetVC: targetVC)
        if guideService.needShowGuide(key: "chat_quick_app_dot") {
            guideService.didShowGuide(key: "chat_quick_app_dot")
        }
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        return true
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        let isShowDot = guideService?.needShowGuide(key: "chat_quick_app_dot") ?? false
        return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_OpenPlatform_MsgScBttn,
                                 icon: BundleResources.Menu.menu_takeActionV2,
                                 showDot: isShowDot,
                                 trackExtraParams: ["click": "more_action",
                                                    "target": "im_chat_msg_menu_more_app_view"]) { [weak self] in
            self?.handle(message: model.message, chat: model.chat)
        }
    }
}
