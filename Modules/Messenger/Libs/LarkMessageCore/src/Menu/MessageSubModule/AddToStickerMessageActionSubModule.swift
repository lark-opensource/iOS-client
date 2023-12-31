//
//  AddToSticker.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/1/16.
//

import Foundation
import LarkModel
import RxSwift
import LarkOpenChat
import UniverseDesignToast
import LarkMessengerInterface
import LarkSDKInterface

public final class AddToStickerMessageActionSubModule: MessageActionSubModule {
    public override var type: MessageActionType {
        return .addToSticker
    }

    private lazy var stickerHandler: AddToStickerMenuHandler? = {
        guard let targetVC = try? self.context.userResolver.resolve(assert: ChatMessagesOpenService.self).pageAPI else { return nil }
        return AddToStickerMenuHandler(stickerService: try? self.context.userResolver.resolve(assert: StickerService.self),
                                       rustService: try? self.context.userResolver.resolve(assert: SDKRustService.self),
                                       nav: self.context.userResolver.navigator,
                                       targetVC: targetVC)
    }()

    private lazy var imageHandler: SaveImageToSticker? = {
        guard let targetVC = try? self.context.userResolver.resolve(assert: ChatMessagesOpenService.self).pageAPI else { return nil }
        return  SaveImageToSticker(rustService: try? self.context.userResolver.resolve(assert: SDKRustService.self), targetVC: targetVC)
    }()

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        switch model.message.type {
        case .image, .sticker:
            return true
        @unknown default:
            return false
        }
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_Legacy_AddStickerForChat,
                                 icon: BundleResources.Menu.menu_sticker,
                                 trackExtraParams: ["click": "sticker_save", "target": "im_chat_main_view"]) { [weak self] in
            if model.message.type == .image {
                self?.imageHandler?.handle(message: model.message, chat: model.chat, params: [:])
            } else if model.message.type == .sticker {
                self?.stickerHandler?.handle(message: model.message, chat: model.chat, params: [:])
            }
        }
    }
}
