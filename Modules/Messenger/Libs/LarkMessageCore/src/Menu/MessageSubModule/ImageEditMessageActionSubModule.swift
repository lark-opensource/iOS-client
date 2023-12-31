//
//  ImageEdit.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/7.
//

import LarkModel
import RxSwift
import LarkOpenChat
import LarkMessengerInterface

public final class ImageEditMessageActionSubModule: MessageActionSubModule {
    private let disposeBag = DisposeBag()
    private var imageEditorHandler: ImageEditHandler?

    public override var type: MessageActionType {
        return .imageEdit
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    public override func handler(model: MessageActionMetaModel) -> [Module<MessageActionContext, MessageActionMetaModel>] {
        if imageEditorHandler == nil, let targetVC = context.targetVC {
            imageEditorHandler = ImageEditHandler(chatSecurityControlService: try? self.userResolver.resolve(assert: ChatSecurityControlService.self),
                                                  nav: self.context.nav,
                                                  fromVC: targetVC)
        }
        return super.handler(model: model)
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        model.message.type == .image
    }

    private func handle(message: Message, chat: Chat) {
        imageEditorHandler?.handle(message: message, chat: chat, params: [:])
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
            return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_Legacy_ImageEdit,
                                     icon: BundleResources.Menu.menu_image_edit,
                                     trackExtraParams: ["click": "edit_image",
                                                        "target": "none"]) { [weak self] in
                self?.handle(message: model.message, chat: model.chat)
            }
    }
}
