//
//  CopyURLPinCardActionHandler.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/30.
//

import Foundation
import UniverseDesignToast
import LarkContainer
import LarkOpenChat
import LarkModel
import LKCommonsLogging
import LarkSDKInterface
import LarkSensitivityControl
import LarkEMM
import LarkCore
import LarkMessengerInterface

// 复制 URL 卡片链接
final class CopyURLPinCardActionHandler: ChatPinActionHandler {
    private static let logger = Logger.log(CopyURLPinCardActionHandler.self, category: "Module.IM.ChatPin")

    private weak var targetVC: UIViewController?
    private var auditService: ChatSecurityAuditService?

    init(targetVC: UIViewController?, auditService: ChatSecurityAuditService?) {
        self.targetVC = targetVC
        self.auditService = auditService
    }

    func handle(pin: ChatPin, chat: Chat) {
        IMTracker.Chat.Sidebar.Click.copyLink(chat, topId: pin.id)
        guard !chat.enableRestricted(.copy) else {
            if let view = self.targetVC?.view {
                UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_RestrictedMode_CopyForwardNotAllow_Toast, on: view)
            }
            return
        }

        guard let url = (pin.payload as? URLPreviewChatPinPayload)?.url else {
            return
        }
        self.auditService?.auditEvent(.chatPin(type: .copyContent(chatId: chat.id, pinId: pin.id)),
                                      isSecretChat: false)

        let pasteboardToken = "LARK-PSDA-messenger-chatNewPin-urlCard-copy-permission"
        let config = PasteboardConfig(token: Token(pasteboardToken))
        do {
            try SCPasteboard.generalUnsafe(config).string = url
            Self.logger.info("chatPinCardTrace url copy success chatId: \(chat.id) pinId: \(pin.id)")
            if let view = self.targetVC?.view {
                UDToast.showSuccess(with: BundleI18n.LarkChat.Lark_IM_NewPin_LinkCopied_Toast, on: view)
            }
        } catch {
            // 复制失败兜底逻辑
            Self.logger.error("PasteboardConfig init fail token:\(pasteboardToken)")
            if let view = self.targetVC?.view {
                UDToast.showFailure(with: BundleI18n.LarkChat.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: view)
            }
        }
    }
}
