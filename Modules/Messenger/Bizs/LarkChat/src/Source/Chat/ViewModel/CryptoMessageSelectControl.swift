//
//  CryptoMessageSelectControl.swift
//  LarkChat
//
//  Created by Ping on 2022/9/20.
//

import UIKit
import Foundation
import LarkMessageCore
import UniverseDesignToast
import LarkMessengerInterface
import LarkEMM
import LarkSensitivityControl

final class CryptoMessageSelectControl: MessageSelectControl {
    private var copying: Bool = false
    private let contentDecoder: CryptoContentDecoder = CryptoContentDecoder()

    override func selectionRangeText(_ range: NSRange, didSelectedAttrString: NSAttributedString, didSelectedRenderAttributedString: NSAttributedString) -> String? {
        guard !copying,
              let menuService = self.menuService,
              let message = menuService.currentMessage else { return nil }
        copying = true

        var selectedType: MenuMessageSelectedType = .all
        if let chatVC = self.chatVC,
            let (label, showAllMessage) = chatVC.findSelectedLabelAndStatus(
                messageId: message.id,
                postViewComponentConstant: menuService.currentComponentKey) {
            selectedType = self.getMenuSelectedRange(label: label, showAllMessage: showAllMessage, range: range)
        }

        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let message = menuService.currentMessage,
                  let content = self?.contentDecoder.getRealContent(token: message.cryptoToken) else {
                self?.copying = false
                return
            }
            DispatchQueue.main.async {
                self?.menuService?.dissmissMenu(completion: nil)
                let copyString: String = self?.modelService?.copyString(richText: content.richText,
                                                                       docEntity: nil,
                                                                       selectType: selectedType ?? .all,
                                                                       urlPreviewProvider: nil,
                                                                       hangPoint: [:],
                                                                       copyValueProvider: nil) ?? ""
                let config = PasteboardConfig(token: Token(self?.pasteboardToken ?? ""))
                do {
                    try SCPasteboard.generalUnsafe(config).string = copyString
                    self?.copying = false
                    guard let window = self?.chatVC?.view.window else { return }
                    UDToast.showSuccess(with: BundleI18n.LarkChat.Lark_Legacy_JssdkCopySuccess, on: window)
                } catch {
                    Self.logger.error("PasteboardConfig init fail token:\(self?.pasteboardToken ?? "")")
                    self?.copying = false
                    guard let window = self?.chatVC?.view.window else { return }
                    UDToast.showFailure(with: BundleI18n.LarkChat.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: window)
                }
            }
        }
        return nil
    }

    override func selectionRangeHandleCopy(selectedText: String) -> Bool {
        if let chat = self.chatVC?._chat, chat.enableRestricted(.copy) {
            return true
        }
        return false
    }
}
