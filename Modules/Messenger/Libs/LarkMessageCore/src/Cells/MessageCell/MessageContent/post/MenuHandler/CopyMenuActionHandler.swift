//
//  CopyMenuActionHandler.swift
//  Pods
//
//  Created by liuwanlin on 2019/3/12.
//

import UIKit
import Foundation
import LarkModel
import UniverseDesignToast
import LarkMessageBase
import LarkMessengerInterface
import LarkContainer
import LarkRichTextCore
import LarkEMM
import LarkSetting
import LarkKeyboardView
import LarkBaseKeyboard

public final class CopyMenuActionHandler: UserResolverWrapper {
    public let userResolver: UserResolver
    private unowned let targetVC: UIViewController
    private let pasteboardToken: String
    @ScopedInjectedLazy private var modelService: ModelService?
    @ScopedInjectedLazy var chatSecurityAuditService: ChatSecurityAuditService?
    @ScopedInjectedLazy private var chatSecurityControlService: ChatSecurityControlService?

    public init(userResolver: UserResolver,
                targetVC: UIViewController,
                pasteboardToken: String) {
        self.userResolver = userResolver
        self.targetVC = targetVC
        self.pasteboardToken = pasteboardToken
    }

    public func handle(message: Message, chat: Chat, params: [String: Any]) {
        guard !chat.enableRestricted(.copy) else {
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_RestrictedMode_CopyForwardNotAllow_Toast, on: self.targetVC.view)
            return
        }

        /// 服务端权限禁用
        if let disableBehavior = message.disabledAction.actions[Int32(MessageDisabledAction.Action.copy.rawValue)] {
            let errorMessage: String
            switch disableBehavior.code {
            case 311_150:
                errorMessage = BundleI18n.LarkMessageCore.Lark_IM_MessageRestrictedCantCopy_Hover
            default:
                errorMessage = BundleI18n.LarkMessageCore.Lark_IM_UnableOperationDueToPermissionRestrictions_Toast
            }
            UDToast.showFailure(with: errorMessage, on: self.targetVC.view)
            return
        }

        let selectedType: MenuMessageSelectedType? = params["selectedType"] as? MenuMessageSelectedType
        let copyType: CopyMessageType? = params["copyType"] as? CopyMessageType
        let resultAttr: NSAttributedString

        if message.type == .card {
            //卡片复制
            resultAttr = getMessageCardCopyString(selectType: selectedType ?? .all, message: message, params: params)
        } else {
            if case .richView(let callback) = selectedType, let (attr, _) = callback() {
                resultAttr = attr
            } else {
                    resultAttr = modelService?.copyMessageSummerizeAttr(
                        message,
                        selectType: selectedType ?? .all,
                        copyType: copyType ?? .message
                    ) ?? NSAttributedString(string: "")
            }
        }
        var allSelect = false
        if case .all = selectedType { allSelect = true }
        IMCopyPasteMenuTracker.trackCopy(chat: chat, message: message, byCommand: false, allSelect: allSelect, text: resultAttr)
        if let chatSecurityControlService = self.chatSecurityControlService {
            if CopyToPasteboardManager.copyToPasteboardFormAttribute(resultAttr,
                                                                     fileAuthority: .message(message, chat, chatSecurityControlService),
                                                                     pasteboardToken: self.pasteboardToken,
                                                                     fgService: self.userResolver.fg) {
                guard let window = self.targetVC.view.window else { return }
                UDToast.showSuccess(with: BundleI18n.LarkMessageCore.Lark_Legacy_JssdkCopySuccess, on: window)
            } else {
                guard let window = self.targetVC.view.window else { return }
                UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: window)
            }
        }
        self.chatSecurityAuditService?.auditEvent(.copy(chatId: chat.id,
                                                       chatType: chat.type,
                                                       messageType: message.type),
                                                 isSecretChat: false)
    }

    public static func getStyleItemsFrom(copy: NSAttributedString) -> [[[String: Any]]] {
        var items: [[[String: Any]]] = []
        // 向剪切板里面添加字体相关信息
        let style = FontStyleItemProvider.styleForAttributedString(copy)
        if !style.isEmpty, let json = FontStyleItemProvider.JSONStringWithStyle(style, content: copy.string) {
            items.append([[FontStyleItemProvider.typeIdentifier: json]])
        }
        // 向剪切板里面添加emojiKey相关信息
        let emoji = EmojiItemProvider.emojiKeyForAttributedString(copy)
        if !emoji.isEmpty, let json = EmojiItemProvider.JSONStringWithEmoji(emoji, content: copy.string) {
            items.append([[EmojiItemProvider.emojiIdentifier: json]])
        }
        // 向剪切板里面添加代码块相关信息
        let code = CodeItemProvider.codeKeyForAttributedString(copy)
        if !code.isEmpty, let json = CodeItemProvider.JSONStringWithCode(code, content: copy.string) {
            items.append([[CodeItemProvider.codeIdentifier: json]])
        }
        return items
    }

    private func getMessageCardCopyString(selectType: CopyMessageSelectedType, message: Message, params: [String: Any]) -> NSAttributedString {
        var result = NSAttributedString()
        var singleLabel = false
        if let getLabelStringHandler = params[MessageCardSurpportCopyKey.msgCardSelectedViewContent] as? ( () -> NSAttributedString ) {
            result = getLabelStringHandler()
            singleLabel = true
        }

        let allRange = NSRange(location: 0, length: result.length)
        switch selectType {
        case .all:
            if !singleLabel, let  copySummerize = (message.content as? CardContent)?.summary {
                result = NSAttributedString(string: copySummerize)
            }
        case .richView(let callback):
            guard let attr = callback()?.0.string else {
                assertionFailure("selectType: .richView callback return nil")
                return result
            }
            result = NSAttributedString(string: attr)
        case .from(let index):
            if index > 0 && index < allRange.length {
                result = result.attributedSubstring(from: NSRange(location: index, length: allRange.length - index))
            }
        case .to(let index):
            if index > 0 && index < allRange.length {
                result = result.attributedSubstring(from: NSRange(location: 0, length: index))
            }
        case .range(let range):
            if range.location >= allRange.location &&
                (range.location + range.length) <= (allRange.location + allRange.length) {
                result = result.attributedSubstring(from: range)
            }
        }
        return result
    }
}
