//
//  MessageCardCopySubmodule.swift
//  LarkOpenPlatform
//
//  Created by Zigeng on 2023/4/13.
//

import Foundation
import LarkOpenChat
import LarkMessengerInterface
import UniverseDesignToast
import LarkModel
import LarkMessageBase
import LarkMessageCore
import LarkContainer
import LarkSetting
import LarkMessageCard

// 新菜单架构下的卡片复制按钮
public class MessageCardCopyActionSubModule: MessageActionSubModule {
    @ScopedInjectedLazy var chatSecurityAuditService: ChatSecurityAuditService?
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?

    // 老消息卡片支持复制FG
    @FeatureGatingValue(key: "messagecard.surpportcopy.enable")
    static var messageCardEnableCopy: Bool

    // 新消息卡片支持复制FG
    @FeatureGatingValue(key: "messagecard.jsoncardsurpportcopy.enable")
    static var newMessageCardEnableCopy: Bool

    public override var type: MessageActionType {
        return .cardCopy
    }

    // 消息卡片复制的安全侧Key, 有重复是因为此为新菜单架构下的消息卡片复制,与老架构的用户操作流程一致
    fileprivate var pasteboardToken: String = "LARK-PSDA-messenger-messageCard-menu-copy-permission"

    // 能否初始化
    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return Self.messageCardEnableCopy || Self.newMessageCardEnableCopy
    }

    // 能否展示消息卡片复制的按钮
    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        guard !model.message.isRecalled else {
            return false
        }
        guard (model.message.content as? CardContent)?.type == .text else {
            return false
        }
        guard !(model.message.isEphemeral && !model.message.isVisible) else {
            return false
        }
        return MessageCardRenderControl.lynxCardRenderEnable(message: model.message) ? Self.newMessageCardEnableCopy : Self.messageCardEnableCopy
    }

    // 获取消息卡片中选中的富文本
    private func getMessageCardCopyString(selectType: CopyMessageSelectedType,
                                          message: Message,
                                          msgCardSelectedViewContent: (() -> NSAttributedString)?) -> NSAttributedString {
        var result = NSAttributedString()
        var singleLabel = false
        if let labelString = msgCardSelectedViewContent?(), !labelString.string.isEmpty {
            result = labelString
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

    private func handle(message: Message,
                        chat: Chat,
                        copyType: CopyMessageType,
                        selectedType: CopyMessageSelectedType) {
        guard let targetVC = self.context.pageAPI else { return }
        guard !chat.enableRestricted(.copy) else {
            UDToast.showTips(with: BundleI18n.MessageAction.Lark_IM_RestrictedMode_CopyForwardNotAllow_Toast, on: targetVC.view)
            return
        }

        let copyType: CopyMessageType? = copyType
        let resultAttr: NSAttributedString
        // 获取卡片选择的文本
        var msgCardSelectedViewContent: (() -> NSAttributedString)?
        if case .card(let content) = copyType {
            msgCardSelectedViewContent = content
        }
        resultAttr = self.getMessageCardCopyString(selectType: selectedType,
                                                   message: message,
                                                   msgCardSelectedViewContent: msgCardSelectedViewContent)
        if let chatSecurityControlService = chatSecurityControlService {
            // 消息复制到剪贴板的通用方法
            CopyToPasteboardManager.msgCopyToPasteboardFormAttribute(resultAttr,
                                                                     message: message,
                                                                     chat: chat,
                                                                     chatSecurityControlService: chatSecurityControlService,
                                                                     selectedType: selectedType,
                                                                     pasteboardToken: self.pasteboardToken,
                                                                     toastFromVC: targetVC,
                                                                     fgService: self.context.userResolver.fg)
        }
        // 安全侧的审计埋点
        self.chatSecurityAuditService?.auditEvent(.copy(chatId: chat.id,
                                                        chatType: chat.type,
                                                        messageType: message.type),
                                                  isSecretChat: false)
    }

    // 创建菜单按钮
    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        return MessageActionItem(text: BundleI18n.MessageAction.Lark_Legacy_Copy,
                                     icon: BundleResources.LarkOpenPlatform.card_message_menu_copy,
                                     trackExtraParams: ["click": "copy",
                                                        "target": "none"]) { [weak self] in
                self?.handle(message: model.message,
                             chat: model.chat,
                             copyType: model.copyType,
                             selectedType: model.selected())
            }
    }
}
