//
//  CryptoCopyMessageActionSubModule.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/1/21.
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

public class CryptoCopyMessageActionSubModule: MessageActionSubModule {
    public override var type: MessageActionType {
        return .copy
    }

    @ScopedInjectedLazy private var modelService: ModelService?
    @ScopedInjectedLazy private var chatSecurityControlService: ChatSecurityControlService?
    private var copying: Bool = false
    private let contentDecoder: CryptoContentDecoder = CryptoContentDecoder()

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        switch model.message.type {
        case .text, .post:
            return true
        @unknown default:
            return false
        }
    }

    var pasteboardToken: String {
        #if DEBUG
        assertionFailure("need to override")
        #endif
        return ""
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_Legacy_Copy,
                                 icon: BundleResources.Menu.menu_copy,
                                 trackExtraParams: [:]) { [weak self] in
            self?.handle(message: model.message,
                         chat: model.chat,
                         selectedType: model.selected())
        }
    }

    public func handle(message: Message, chat: Chat, selectedType: CopyMessageSelectedType) {
        guard let targetVC = self.context.pageAPI else { return }
        guard !copying else {
            return
        }
        copying = true
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let content = self?.contentDecoder.getRealContent(token: message.cryptoToken) else {
                return
            }
            DispatchQueue.main.async {
                guard let self = self, let modelService = self.modelService, let chatSecurityControlService = self.chatSecurityControlService else { return }
                let copyString: NSAttributedString = modelService.copyStringAttr(richText: content.richText,
                                                                                 docEntity: nil,
                                                                                 selectType: selectedType,
                                                                                 urlPreviewProvider: nil,
                                                                                 hangPoint: [:],
                                                                                 copyValueProvider: nil,
                                                                                 userResolver: self.context.userResolver)
                CopyToPasteboardManager.copyToPasteboardFormAttribute(copyString,
                                                                      fileAuthority: .message(message, chat, chatSecurityControlService),
                                                                      pasteboardToken: self.pasteboardToken,
                                                                      fgService: self.context.userResolver.fg)
                guard let window = targetVC.view.window else { return }
                UDToast.showSuccess(with: BundleI18n.LarkMessageCore.Lark_Legacy_JssdkCopySuccess, on: window)
                self.copying = false
            }
        }
    }

    private func getStyleItemsFrom(copy: NSAttributedString) -> [[[String: Any]]] {
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
}

public final class CryptoCopyMessageActionSubModuleInChat: CryptoCopyMessageActionSubModule {
    override var pasteboardToken: String {
        return "LARK-PSDA-messenger-cryptoChat-menu-copy-permission"
    }
}

public final class CryptoCopyMessageActionSubModuleInDetail: CryptoCopyMessageActionSubModule {
    override var pasteboardToken: String {
        return "LARK-PSDA-messenger-cryptoMessageDetail-menu-copy-permission"
    }
}
