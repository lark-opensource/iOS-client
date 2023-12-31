//
//  StickerContentActionHandler.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/2/6.
//

import Foundation
import RustPB
import LarkCore
import LarkModel
import LarkUIKit
import EENavigator
import LarkMessageBase
import LKCommonsLogging
import LarkMessengerInterface

private var logger = Logger.log(NSObject(), category: "StickerContentActionHandler")

class StickerContentActionHandler<C: StickerContentContext>: ComponentActionHandler<C> {
    public func imageDidTapped(
        view: ChatImageViewWrapper,
        chat: Chat,
        message: Message,
        allMessages: [Message]
    ) {
        assertionFailure("must override")
    }

    /// 展示表情包里面的表情
    public func showStickerFromStickerSetIfNeeded(message: Message) -> Bool {
        guard let content = message.content as? StickerContent else {
            assertionFailure("missed From VC")
            return false
        }

        let sticker: RustPB.Im_V1_Sticker = content.transformToSticker()
        if sticker.mode == .meme {
            let body = EmotionSingleDetailBody(
                sticker: sticker,
                stickerSet: nil,
                stickerSetID: sticker.stickerSetID,
                message: message)
            self.context.navigator(type: .push, body: body, params: nil)
            return true
        } else {
            return false
        }
    }
}

final class ChatStickerContentActionHandler<C: StickerContentContext>: StickerContentActionHandler<C> {
    override func imageDidTapped(
        view: ChatImageViewWrapper,
        chat: Chat,
        message: Message,
        allMessages: [Message]
    ) {
        if self.showStickerFromStickerSetIfNeeded(message: message) { return }
        let result = LKDisplayAsset.createAssetForSticker(
            messages: allMessages,
            currentMessage: message
        )
        guard !result.assets.isEmpty,
            let index = result.selectIndex else {
            return
        }
        IMTracker.Chat.Main.Click.Msg.Sticker(chat, message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        result.assets[index].visibleThumbnail = view.imageView
        let context = self.context
        let messageId = message.id
        let body = PreviewImagesBody(
            assets: result.assets.map { $0.transform() },
            pageIndex: index,
            scene: .normal(assetPositionMap: result.assetPositionMap, chatId: chat.id),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: chat.shouldDetectFile,
            canSaveImage: !chat.enableRestricted(.download),
            canShareImage: !chat.enableRestricted(.forward),
            canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
            canTranslate: false,
            translateEntityContext: (message.id, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            },
            buttonType: .stack(config: .init(getAllAlbumsBlock: { [weak context] in
                if let context = context {
                    return context.getChatAlbumDataSourceImpl(chat: chat, isMeSend: context.isMe)
                }
                return DefaultAlbumDataSourceImpl()
            }))
        )
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}

final class ThreadChatStickerContentActionHandler<C: StickerContentContext>: StickerContentActionHandler<C> {
    override func imageDidTapped(
        view: ChatImageViewWrapper,
        chat: Chat,
        message: Message,
        allMessages: [Message]
    ) {
        if self.showStickerFromStickerSetIfNeeded(message: message) { return }

        let result = LKDisplayAsset.createAssetForSticker(messages: [message], currentMessage: message)
        guard !result.assets.isEmpty,
            let index = result.selectIndex else {
            return
        }
        IMTracker.Chat.Main.Click.Msg.Sticker(chat, message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        result.assets[index].visibleThumbnail = view.imageView
        let context = self.context
        let messageId = message.id
        let body = PreviewImagesBody(
            assets: result.assets.map { $0.transform() },
            pageIndex: index,
            scene: .normal(assetPositionMap: result.assetPositionMap, chatId: chat.id),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: chat.shouldDetectFile,
            canTranslate: false,
            translateEntityContext: (message.id, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            },
            buttonType: .stack(config: .init(getAllAlbumsBlock: nil))
        )
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}

final class ThreadDetailStickerContentActionHandler<C: StickerContentContext>: StickerContentActionHandler<C> {
    override func imageDidTapped(
        view: ChatImageViewWrapper,
        chat: Chat,
        message: Message,
        allMessages: [Message]
    ) {
        if self.showStickerFromStickerSetIfNeeded(message: message) { return }

        let result = LKDisplayAsset.createAssetForSticker(
            messages: allMessages,
            currentMessage: message
        )
        guard !result.assets.isEmpty,
            let index = result.selectIndex else {
            return
        }

        ChannelTracker.TopicDetail.Click.Msg.Sticker(chat, message)
        result.assets[index].visibleThumbnail = view.imageView
        let context = self.context
        let messageId = message.id
        let body = PreviewImagesBody(
            assets: result.assets.map { $0.transform() },
            pageIndex: index,
            scene: .normal(assetPositionMap: result.assetPositionMap, chatId: chat.id),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: chat.shouldDetectFile,
            canSaveImage: !chat.enableRestricted(.download),
            canShareImage: !chat.enableRestricted(.forward),
            canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
            canTranslate: false,
            translateEntityContext: (message.id, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            },
            buttonType: .stack(config: .init(getAllAlbumsBlock: nil))
        )
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}

final class MergeForwardDetailStickerContentActionHandler<C: StickerContentContext>: StickerContentActionHandler<C> {
    override func imageDidTapped(
        view: ChatImageViewWrapper,
        chat: Chat,
        message: Message,
        allMessages: [Message]
    ) {
        if self.showStickerFromStickerSetIfNeeded(message: message) { return }

        let result = LKDisplayAsset.createAssetForSticker(
            messages: allMessages,
            currentMessage: message
        )
        guard !result.assets.isEmpty,
            let index = result.selectIndex else {
                return
        }
        result.assets[index].visibleThumbnail = view.imageView
        let context = self.context
        let messageId = message.id
        let body = PreviewImagesBody(
            assets: result.assets.map { $0.transform() },
            pageIndex: index,
            scene: .normal(assetPositionMap: result.assetPositionMap, chatId: chat.id),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: chat.shouldDetectFile,
            canSaveImage: !chat.enableRestricted(.download),
            canShareImage: !chat.enableRestricted(.forward),
            canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
            canTranslate: false,
            translateEntityContext: (message.id, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            },
            buttonType: .stack(config: .init(getAllAlbumsBlock: nil))
        )
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}

final class MessageDetailStickerContentActionHandler<C: StickerContentContext>: StickerContentActionHandler<C> {
    override func imageDidTapped(
        view: ChatImageViewWrapper,
        chat: Chat,
        message: Message,
        allMessages: [Message]
    ) {
        if self.showStickerFromStickerSetIfNeeded(message: message) { return }
        let result = LKDisplayAsset.createAssetForSticker(
            messages: allMessages,
            currentMessage: message
        )
        guard !result.assets.isEmpty,
            let index = result.selectIndex else {
                return
        }
        result.assets[index].visibleThumbnail = view.imageView
        let context = self.context
        let messageId = message.id
        let body = PreviewImagesBody(
            assets: result.assets.map { $0.transform() },
            pageIndex: index,
            scene: .normal(assetPositionMap: result.assetPositionMap, chatId: chat.id),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: chat.shouldDetectFile,
            canSaveImage: !chat.enableRestricted(.download),
            canShareImage: !chat.enableRestricted(.forward),
            canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
            canTranslate: false,
            translateEntityContext: (message.id, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            },
            buttonType: .stack(config: .init(getAllAlbumsBlock: nil))
        )
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}

final class PinStickerContentActionHandler<C: StickerContentContext>: StickerContentActionHandler<C> {
    override func imageDidTapped(
        view: ChatImageViewWrapper,
        chat: Chat,
        message: Message,
        allMessages: [Message]
    ) {
        if self.showStickerFromStickerSetIfNeeded(message: message) { return }
        let result = LKDisplayAsset.createAssetForSticker(
            messages: allMessages,
            currentMessage: message
        )
        guard !result.assets.isEmpty,
            let index = result.selectIndex else {
                return
        }
        result.assets[index].visibleThumbnail = view.imageView
        let context = self.context
        let messageId = message.id
        let body = PreviewImagesBody(
            assets: result.assets.map { $0.transform() },
            pageIndex: index,
            scene: .normal(assetPositionMap: result.assetPositionMap, chatId: nil),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: chat.shouldDetectFile,
            canSaveImage: !chat.enableRestricted(.download),
            canShareImage: !chat.enableRestricted(.forward),
            canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
            canTranslate: false,
            translateEntityContext: (nil, .other),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            },
            buttonType: .stack(config: .init(getAllAlbumsBlock: nil))
        )
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}
