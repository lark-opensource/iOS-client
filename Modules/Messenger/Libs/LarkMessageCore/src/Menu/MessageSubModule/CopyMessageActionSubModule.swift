//
//  Copy.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/1/5.
//

import Foundation
import LarkModel
import UniverseDesignToast
import LarkMessageBase
import LarkMessengerInterface
import LarkContainer
import LarkRichTextCore
import LarkEMM
import LarkSetting
import LarkOpenChat
import LarkBaseKeyboard

public class CopyMessageActionSubModule: MessageActionSubModule {
    @ScopedInjectedLazy private var modelService: ModelService?
    @ScopedInjectedLazy var chatSecurityAuditService: ChatSecurityAuditService?
    @ScopedInjectedLazy private var chatSecurityControlService: ChatSecurityControlService?

    public override var type: MessageActionType {
        return .copy
    }

    fileprivate var pasteboardToken: String {
        assertionFailure("pasteboardToken need to override")
        return ""
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        if context.userResolver.fg.dynamicFeatureGatingValue(with: "im.chat.disable_announcement.client"),
           (model.message.content as? PostContent)?.isGroupAnnouncement ?? false {
            return false
        }
        guard self.chatSecurityControlService?.getDynamicAuthorityFromCache(event: .receive,
                                                                            message: model.message,
                                                                            anonymousId: model.chat.anonymousId).authorityAllowed ?? false else { return false }
        switch model.message.type {
        case .text, .post:
            return true
        @unknown default:
            return false
        }
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

    private func getMessageCardCopyString(_ AllString: NSAttributedString, selectType: CopyMessageSelectedType) -> NSAttributedString {
        // 文本总范围
        var result = AllString
        let allRange = NSRange(location: 0, length: result.length)
        switch selectType {
        case .all, .richView:
            break
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
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_RestrictedMode_CopyForwardNotAllow_Toast, on: targetVC.view)
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
            UDToast.showFailure(with: errorMessage, on: targetVC.view)
            return
        }

        let copyType: CopyMessageType? = copyType
        let resultAttr: NSAttributedString
        if case .richView(let callback) = selectedType, let (attr, _) = callback() {
            resultAttr = attr
        } else {
                resultAttr = modelService?.copyMessageSummerizeAttr(
                    message,
                    selectType: selectedType,
                    copyType: copyType ?? .message
                ) ?? NSAttributedString()
        }
        if let chatSecurityControlService = self.chatSecurityControlService {
            CopyToPasteboardManager.msgCopyToPasteboardFormAttribute(resultAttr,
                                                                     message: message,
                                                                     chat: chat,
                                                                     chatSecurityControlService: chatSecurityControlService,
                                                                     selectedType: selectedType,
                                                                     pasteboardToken: self.pasteboardToken,
                                                                     toastFromVC: targetVC,
                                                                     fgService: self.context.userResolver.fg)
        }
        self.chatSecurityAuditService?.auditEvent(.copy(chatId: chat.id,
                                                        chatType: chat.type,
                                                        messageType: message.type),
                                                  isSecretChat: false)
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        return MessageActionItem(text: getMenuTitle(model: model),
                                 icon: BundleResources.Menu.menu_copy,
                                 trackExtraParams: getTrackExtraParams(model: model)) { [weak self] in
            self?.handle(message: model.message,
                         chat: model.chat,
                         copyType: model.copyType,
                         selectedType: model.selected())
        }
    }

    fileprivate func getMenuTitle(model: MessageActionMetaModel) -> String {
        return BundleI18n.LarkMessageCore.Lark_Legacy_Copy
    }

    fileprivate func getTrackExtraParams(model: MessageActionMetaModel) -> [AnyHashable: Any] {
        return ["click": "copy", "target": "none"]
    }
}

public class BaseThreadCopyMessageActionSubModule: CopyMessageActionSubModule {
    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        // Thread内如果是群公告 不需要复制功能
        if (model.message.content as? PostContent)?.isGroupAnnouncement == true {
            return false
        }
        return super.canHandle(model: model)
    }
}

public final class ChatCopyMessageActionSubModule: CopyMessageActionSubModule {
    override var pasteboardToken: String { "LARK-PSDA-messenger-chat-menu-copy-permission" }

    override func getMenuTitle(model: MessageActionMetaModel) -> String {
        if model.message.isSinglePreview {
            return BundleI18n.LarkMessageCore.Lark_Chat_CopyLink
        }
        return super.getMenuTitle(model: model)
    }

    override func getTrackExtraParams(model: MessageActionMetaModel) -> [AnyHashable: Any] {
        if model.message.isSinglePreview {
            return ["click": "copy_link", "target": "none"]
        }
        return super.getTrackExtraParams(model: model)
    }
}

public final class MessageDetailCopyMessageActionSubModule: CopyMessageActionSubModule {
    override var pasteboardToken: String { "LARK-PSDA-messenger-messageDetail-menu-copy-permission" }

    override func getMenuTitle(model: MessageActionMetaModel) -> String {
        if model.message.isSinglePreview {
            return BundleI18n.LarkMessageCore.Lark_Chat_CopyLink
        }
        return super.getMenuTitle(model: model)
    }

    override func getTrackExtraParams(model: MessageActionMetaModel) -> [AnyHashable: Any] {
        if model.message.isSinglePreview {
            return ["click": "copy_link", "target": "none"]
        }
        return super.getTrackExtraParams(model: model)
    }
}
public final class MergeForwardDetailCopyMessageActionSubModule: CopyMessageActionSubModule {
    override var pasteboardToken: String { "LARK-PSDA-messenger-chatMergeForwardDetail-menu-copy-permission" }
}

public final class ThreadCopyMessageActionSubModule: BaseThreadCopyMessageActionSubModule {
    override var pasteboardToken: String { "LARK-PSDA-messenger-threadChatAndThreadFilter-menu-copy-permission" }
}

public final class ThreadDetailCopyMessageActionSubModule: BaseThreadCopyMessageActionSubModule {
    override var pasteboardToken: String { "LARK-PSDA-messenger-threadDetail-menu-copy-permission" }
}
public final class ThreadReplyCopyMessageActionSubModule: BaseThreadCopyMessageActionSubModule {
    override var pasteboardToken: String { "LARK-PSDA-messenger-replyInThread-menu-copy-permission" }

    override func getMenuTitle(model: MessageActionMetaModel) -> String {
        if model.message.isSinglePreview {
            return BundleI18n.LarkMessageCore.Lark_Chat_CopyLink
        }
        return super.getMenuTitle(model: model)
    }

    override func getTrackExtraParams(model: MessageActionMetaModel) -> [AnyHashable: Any] {
        if model.message.isSinglePreview {
            return ["click": "copy_link", "target": "none"]
        }
        return super.getTrackExtraParams(model: model)
    }
}
