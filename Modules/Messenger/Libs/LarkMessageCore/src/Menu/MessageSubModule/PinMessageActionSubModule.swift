//
//  PinMessageActionSubModule.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/1.
//

import UIKit
import LarkModel
import LarkMessageBase
import EENavigator
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface
import LarkContainer
import LarkAccountInterface
import LarkCore
import LarkOpenChat
import LarkOpenKeyboard

public final class PinMessageActionSubModule: MessageActionSubModule {
    public override var type: MessageActionType {
        return .pin
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    lazy var pinMenuActionHandler = PinMenuActionHandler(pinAPI: try? self.userResolver.resolve(assert: PinAPI.self),
                                                         currentChatterId: self.userResolver.userID)

    lazy var unPinMenuActionHandler: UnPinMenuActionHandler? = {
        if let targetVC = context.pageAPI {
            return UnPinMenuActionHandler(targetVC: targetVC,
                                          from: .inChat,
                                          nav: self.context.nav)
        } else {
            return nil
        }
    }()

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        let message = model.message
        let chat = model.chat
        if ChatNewPinConfig.supportPinMessage(chat: chat, self.context.userResolver.fg) {
            return false
        }
        let cardSupportFg = self.userResolver.fg.staticFeatureGatingValue(with: "messagecard.pin.support")
        guard message.isSupportPin(cardSupportFg: cardSupportFg),
              chat.isSupportPinMessage,
              ChatPinPermissionManager.hasPinPermissionInChat(chat,
                                                              userID: self.context.userID,
                                                              featureGatingService: self.userResolver.fg) else {
            return false
        }
        return true
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        if model.message.pinChatter != nil {
            return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_Pin_UnpinButton,
                                     icon: BundleResources.Menu.menu_unPin,
                                     trackExtraParams: ["click": "unpin", "target": "none"]) { [weak self] in
                self?.unPinMenuActionHandler?.handle(message: model.message, chat: model.chat, params: [:])
            }
        } else {
            return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_Pin_PinButton,
                                     icon: BundleResources.Menu.menu_pin,
                                     trackExtraParams: ["click": "pin", "target": "none"]) { [weak
                                                                                                self] in
                self?.pinMenuActionHandler.handle(message: model.message, chat: model.chat, params: [:])
            }
        }
    }
}
