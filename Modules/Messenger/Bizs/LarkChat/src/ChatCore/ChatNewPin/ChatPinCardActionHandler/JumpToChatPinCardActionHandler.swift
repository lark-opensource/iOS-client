//
//  JumpToChatPinCardActionHandler.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/7/5.
//

import Foundation
import LarkOpenChat
import LarkModel
import EENavigator
import LarkMessengerInterface
import LarkCore

final class JumpToChatPinCardActionHandler: ChatPinActionHandler {

    private weak var targetVC: UIViewController?
    private let nav: Navigatable
    private var auditService: ChatSecurityAuditService?

    init(targetVC: UIViewController?, nav: Navigatable, auditService: ChatSecurityAuditService?) {
        self.targetVC = targetVC
        self.nav = nav
        self.auditService = auditService
    }

    func handle(pin: ChatPin, chat: Chat) {
        guard let message = (pin.payload as? MessageChatPinPayload)?.message,
              let targetVC = self.targetVC else {
            return
        }
        IMTracker.Chat.Sidebar.Click.viewInChat(chat, topId: pin.id, messageId: message.id, topType: .message)
        MessagePinUtils.onClick(
            message: message,
            chat: chat,
            pinID: pin.id,
            navigator: self.nav,
            targetVC: targetVC,
            auditService: auditService
        )
    }
}
