//
//  IMComposeKeyboardAtUserPanelSubModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/4/22.
//

import UIKit
import LarkBaseKeyboard
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import LarkKeyboardView
import LarkCore
import LarkSetting
import LarkModel
import LarkContainer
import LarkMessengerInterface

class TopicKeyboardAtUserPanelSubModule: IMComposeKeyboardAtUserPanelSubModule {
    override var supportAtAll: Bool { return true }
}

class IMComposeKeyboardAtUserPanelSubModule: KeyboardPanelAtUserSubModule<IMComposeKeyboardContext, IMKeyboardMetaModel>, ComposeKeyboardViewPageItemProtocol {

    lazy var postRouter: ComposePostRouter? = {
        let router = try? context.userResolver.resolve(assert: ComposePostRouter.self)
        router?.rootVCBlock = { [weak self] in
            return self?.context.getRootVC()
        }
        return router
    }()

    var supportAtAll: Bool {
        guard let chat = self.metaModel?.chat else { return true }
        return chat.chatMode != .threadV2
    }

    override func itemIconColor() -> UIColor? {
        return ComposeKeyboardPageItem.iconColor
    }

    override func didCreatePanelItem() -> InputKeyboardItem? {
        return super.didCreatePanelItem()
    }

    override func didSelectedItem() {
        LarkMessageCoreTracker.trackComposePostInputItem(KeyboardItemKey.at)
    }

    override func becomeFirstResponderAfterComplete() -> Bool {
        return true
    }

    override func showAtPicker(cancel: (() -> Void)?, complete: (([InputKeyboardAtItem]) -> Void)?) {

        guard let chat = self.metaModel?.chat else {
            return
        }

        self.postRouter?.presentAtPicker(chat: chat,
                                         allowAtAll: supportAtAll,
                                         allowMyAI: self.pageItem?.supportAtMyAI ?? false,
                                         allowSideIndex: true,
                                         cancel: cancel,
                                         complete: complete)
        let threadID = getThreadIdForChat(chat, keyboardStatusManager: self.context.keyboardStatusManager)
        IMTracker.Chat.Main.Click.AtMention(chat,
                                            isFullScreen: true,
                                            self.pageItem?.chatFromWhere?.rawValue,
                                            threadId: threadID)
        if self.pageItem?.supportAtMyAI == true {
            try? self.context.userResolver.resolve(type: IMMyAIInlineService.self).trackInlineAIEntranceView(.mention)
        }
    }

    override func shouldInsert(id: String) -> Bool {
        if id == (try? self.context.userResolver.resolve(type: MyAIService.self).defaultResource.mockID) {
            let service = try? self.context.userResolver.resolve(type: IMMyAIInlineService.self)
            self.context.displayVC.dismiss(animated: true) { [weak service, weak context] in
                context?.dismissByCancel()
                service?.openMyAIInlineMode(source: .mention)
            }
            return false
        }
        return true
    }
}

public extension LarkModel.Chat {
    //在chat类型维度是否支持【会话接入My AI浮窗模式】功能
    var supportMyAIInlineMode: Bool {
        guard self.chatMode != .threadV2,
              !self.isCrypto,
              !self.isP2PAi,
              !(self.type == .p2P && self.chatter?.type == .bot),
              !self.isPrivateMode,
              !self.isCrossTenant,
              !self.isCrossWithKa,
              !self.restrictedModeSetting.switch, // 保密模式
              !self.isTeamVisitorMode else {
            return false
        }
        return true
    }
}
