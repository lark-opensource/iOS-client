//
//  DocCryptoChatKeyboardSubModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/1/20.
//

import Foundation
import LarkOpenChat
import LarkOpenIM
import LarkContainer
import LarkModel
import EENavigator
import LarkMessengerInterface
import LarkUIKit
import RustPB
import LarkCore
import LarkChat
import CCMMod

public final class DocCryptoChatKeyboardSubModule: CryptoChatKeyboardSubModule {
    /// 「+」号菜单
    public override var moreItems: [ChatKeyboardMoreItem] {
        return [doc].compactMap { $0 }
    }

    @ScopedInjectedLazy private var chatDocDependency: ChatDocDependency?
    private var metaModel: ChatKeyboardMetaModel?

    public override class func canInitialize(context: ChatKeyboardContext) -> Bool {
        return true
    }

    public override func canHandle(model: ChatKeyboardMetaModel) -> Bool {
        return true
    }

    public override func handler(model: ChatKeyboardMetaModel) -> [Module<ChatKeyboardContext, ChatKeyboardMetaModel>] {
        return [self]
    }

    public override func modelDidChange(model: ChatKeyboardMetaModel) {
        self.metaModel = model
    }

    public override func createMoreItems(metaModel: ChatKeyboardMetaModel) {
        self.metaModel = metaModel
    }

    private lazy var doc: ChatKeyboardMoreItem? = {
        guard let chatModel = self.metaModel?.chat else { return nil }
        if !chatModel.isCrossWithKa,
           !chatModel.isCrossTenant {
            let item = ChatKeyboardMoreItemConfig(
                text: BundleI18n.LarkChat.Lark_Legacy_SendDocKey,
                icon: Resources.send_docs,
                type: .doc,
                tapped: { [weak self] in
                    self?.clickDoc()
                })
            return item
        }
        return nil
    }()

    private func clickDoc() {
        guard let chat = self.metaModel?.chat else { return }
        IMTracker.Chat.InputPlus.Click.Docs(chat)
        ChatTracker.trackSendDocIconClicked()

        let vc = self.context.baseViewController()
        let param = PresentParam(wrap: LkNavigationController.self, from: vc, prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
        let sendDocBlock: (Bool, [MessengerSendDocModel]) -> Void = { [weak self] (clickedConfirm, docs) in
            guard clickedConfirm,
                  let self = self else { return }
            ChatTracker.sendDocInChat()
            var richTexts: [RustPB.Basic_V1_RichText] = []
            for doc in docs {
                let content = RustPB.Basic_V1_RichText.text(doc.url)
                richTexts.append(content)
            }
            for richText in richTexts {
                if let parentMessage = self.context.getReplyMessage() {
                    self.context.sendText(content: richText, lingoInfo: nil, parentMessage: parentMessage)
                } else {
                    self.context.sendText(content: richText, lingoInfo: nil, parentMessage: self.context.getRootMessage())
                }
            }
            self.context.clearReplyMessage()
            self.context.foldKeyboard()
        }
        let body = SendDocBody(SendDocBody.Context(chat: chat)) { (config: SendDocConfirm, models: [SendDocModel]) in
            sendDocBlock(config, models.map { MessengerSendDocModel(url: $0.url) })
        }
        self.context.nav.present(body: body, presentParam: param)
    }
}
