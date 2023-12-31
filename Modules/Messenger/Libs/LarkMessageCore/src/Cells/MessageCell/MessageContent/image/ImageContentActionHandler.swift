//
//  ImageContentActionHandler.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/1/31.
//

import Foundation
import LarkCore
import LarkModel
import LarkUIKit
import LarkMessageBase
import LKCommonsLogging
import LarkSetting
import LarkMessengerInterface

private let logger = Logger.log(LarkMessageBase.ViewModelContext.self, category: "ImageContentActionHandler")
class ImageContentActionHandler<C: ImageContentContext>: ComponentActionHandler<C> {
    public func imageDidTapped(
        _ view: ChatImageViewWrapper,
        chat: Chat,
        message: Message,
        permissionPreview: (Bool, ValidateResult?),
        dynamicAuthorityEnum: DynamicAuthorityEnum,
        allMessages: [Message],
        canViewInChat: Bool,
        showAddToSticker: Bool
    ) {
        assertionFailure("must override")
    }
}

final class ChatImageContentActionHandler<C: ImageContentContext>: ImageContentActionHandler<C> {
    override func imageDidTapped(
        _ view: ChatImageViewWrapper,
        chat: Chat,
        message: Message,
        permissionPreview: (Bool, ValidateResult?),
        dynamicAuthorityEnum: DynamicAuthorityEnum,
        allMessages: [Message],
        canViewInChat: Bool,
        showAddToSticker: Bool
    ) {
        // Chat图片查看逻辑：当前图构造asset，调用预览图接口，支持前后翻页，并且表情、帖子、视频图片都可以预览
        let context = self.context
        if !(permissionPreview.0 && dynamicAuthorityEnum.authorityAllowed) {
            context.handlerPermissionPreviewOrReceiveError(receiveAuthResult: dynamicAuthorityEnum,
                                                           previewAuthResult: permissionPreview.1,
                                                           resourceType: .image)
            return
        }
        let result = LKDisplayAsset.createAssetExceptForSticker(
            messages: allMessages,
            selected: message.id,
            cid: message.cid,
            downloadFileScene: context.downloadFileScene,
            isMeSend: context.isMe,
            checkPreviewPermission: { [weak self] message in
                return self?.context.checkPreviewAndReceiveAuthority(chat: chat, message: message) ?? .allow
            },
            chat: chat
        )
        guard !result.assets.isEmpty,
            let index = result.selectIndex else {
            return
        }
        IMTracker.Chat.Main.Click.Msg.Image(chat, message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        let messageId = message.id
        result.assets[index].visibleThumbnail = view.imageView
        var body = PreviewImagesBody(
            assets: result.assets.map({ $0.transform() }),
            pageIndex: index,
            scene: .chat(chatId: message.channel.id, chatType: chat.type, assetPositionMap: result.assetPositionMap),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: chat.shouldDetectFile,
            canSaveImage: !chat.enableRestricted(.download),
            canShareImage: !chat.enableRestricted(.forward),
            canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
            canTranslate: !chat.isPrivateMode && context.getStaticFeatureGating(.imageViewerInMessageScenesTranslateEnable),
            canViewInChat: canViewInChat,
            translateEntityContext: (message.id, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                // need hold local object.self maybe deinit when come new message.
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            },
            buttonType: .stack(config: .init(getAllAlbumsBlock: { [weak context] in
                if let context = context {
                    return context.getChatAlbumDataSourceImpl(chat: chat, isMeSend: context.isMe(_:))
                }
                return DefaultAlbumDataSourceImpl()
            })),
            showAddToSticker: showAddToSticker
        )
        body.customTransition = BaseImageViewWrapperTransition()
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}

final class ThreadChatImageContentActionHandler<C: ImageContentContext>: ImageContentActionHandler<C> {
    override func imageDidTapped(
        _ view: ChatImageViewWrapper,
        chat: Chat,
        message: Message,
        permissionPreview: (Bool, ValidateResult?),
        dynamicAuthorityEnum: DynamicAuthorityEnum,
        allMessages: [Message],
        canViewInChat: Bool,
        showAddToSticker: Bool
    ) {
        // ThreadChat图片查看逻辑：当前图构造asset，只预览一张
        let result = LKDisplayAsset.createAssetExceptForSticker(
            messages: [message],
            downloadFileScene: context.downloadFileScene,
            isMeSend: context.isMe,
            checkPreviewPermission: { [weak self] message in
                return self?.context.checkPreviewAndReceiveAuthority(chat: chat, message: message) ?? .allow
            },
            chat: chat
        )
        guard !result.assets.isEmpty,
            let index = result.selectIndex else {
            return
        }
        let context = self.context
        if !(permissionPreview.0 && dynamicAuthorityEnum.authorityAllowed) {
            context.handlerPermissionPreviewOrReceiveError(receiveAuthResult: dynamicAuthorityEnum,
                                                           previewAuthResult: permissionPreview.1,
                                                           resourceType: .image)
            return
        }
        IMTracker.Chat.Main.Click.Msg.Image(chat, message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        result.assets[index].visibleThumbnail = view.imageView
        result.assets.forEach { $0.isAutoLoadOriginalImage = true }
        let messageId = message.id
        var body = PreviewImagesBody(
            assets: result.assets.map { $0.transform() },
            pageIndex: index,
            scene: .normal(assetPositionMap: result.assetPositionMap, chatId: chat.id),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: chat.shouldDetectFile,
            canTranslate: context.getStaticFeatureGating(.imageViewerInMessageScenesTranslateEnable),
            canViewInChat: canViewInChat,
            translateEntityContext: (message.id, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            },
            buttonType: .stack(config: .init(getAllAlbumsBlock: nil)),
            showAddToSticker: showAddToSticker
        )
        body.customTransition = BaseImageViewWrapperTransition()
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}

final class ThreadDetailImageContentActionHandler<C: ImageContentContext>: ImageContentActionHandler<C> {
    override func imageDidTapped(
        _ view: ChatImageViewWrapper,
        chat: Chat,
        message: Message,
        permissionPreview: (Bool, ValidateResult?),
        dynamicAuthorityEnum: DynamicAuthorityEnum,
        allMessages: [Message],
        canViewInChat: Bool,
        showAddToSticker: Bool
    ) {
        // ThreadDetail图片查看逻辑：内存里表情、帖子、视频图片都可以预览
        let context = self.context
        if !(permissionPreview.0 && dynamicAuthorityEnum.authorityAllowed) {
            context.handlerPermissionPreviewOrReceiveError(receiveAuthResult: dynamicAuthorityEnum,
                                                           previewAuthResult: permissionPreview.1,
                                                           resourceType: .image)
            return
        }
        let result = LKDisplayAsset.createAssetExceptForSticker(
            messages: allMessages,
            selected: message.id,
            cid: message.cid,
            downloadFileScene: context.downloadFileScene,
            isMeSend: context.isMe,
            checkPreviewPermission: { [weak self] message in
                return self?.context.checkPreviewAndReceiveAuthority(chat: chat, message: message) ?? .allow
            },
            chat: chat
        )
        guard !result.assets.isEmpty,
            let index = result.selectIndex else {
            return
        }

        ChannelTracker.TopicDetail.Click.Msg.Image(chat, message)
        result.assets[index].visibleThumbnail = view.imageView
        result.assets.forEach { $0.isAutoLoadOriginalImage = true }
        let messageId = message.id
        var body = PreviewImagesBody(
            assets: result.assets.map { $0.transform() },
            pageIndex: index,
            scene: .normal(assetPositionMap: result.assetPositionMap, chatId: chat.id),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: chat.shouldDetectFile,
            canSaveImage: !chat.enableRestricted(.download),
            canShareImage: !chat.enableRestricted(.forward),
            canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
            canTranslate: context.getStaticFeatureGating(.imageViewerInMessageScenesTranslateEnable),
            canViewInChat: canViewInChat,
            translateEntityContext: (message.id, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            },
            buttonType: .stack(config: .init(getAllAlbumsBlock: nil)),
            showAddToSticker: showAddToSticker
        )
        body.customTransition = BaseImageViewWrapperTransition()
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}

final class MergeForwardDetailImageContentActionHandler<C: ImageContentContext>: ImageContentActionHandler<C> {
    override func imageDidTapped(
        _ view: ChatImageViewWrapper,
        chat: Chat,
        message: Message,
        permissionPreview: (Bool, ValidateResult?),
        dynamicAuthorityEnum: DynamicAuthorityEnum,
        allMessages: [Message],
        canViewInChat: Bool,
        showAddToSticker: Bool
    ) {
        let context = self.context
        if !(permissionPreview.0 && dynamicAuthorityEnum.authorityAllowed) {
            context.handlerPermissionPreviewOrReceiveError(receiveAuthResult: dynamicAuthorityEnum,
                                                           previewAuthResult: permissionPreview.1,
                                                           resourceType: .image)
            return
        }
        let result = LKDisplayAsset.createAssetExceptForSticker(
            messages: allMessages,
            selected: message.id,
            cid: message.cid,
            downloadFileScene: context.downloadFileScene,
            isMeSend: context.isMe,
            checkPreviewPermission: { [weak self] message in
                return self?.context.checkPreviewAndReceiveAuthority(chat: chat, message: message) ?? .allow
            },
            chat: chat
        )
        guard !result.assets.isEmpty,
            let index = result.selectIndex else {
                return
        }
        result.assets[index].visibleThumbnail = view.imageView
        let messageId = message.id
        var body = PreviewImagesBody(
            assets: result.assets.map { $0.transform() },
            pageIndex: index,
            scene: .normal(assetPositionMap: result.assetPositionMap, chatId: chat.id),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: chat.shouldDetectFile,
            canSaveImage: !chat.enableRestricted(.download),
            canShareImage: !chat.enableRestricted(.forward),
            canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
            canTranslate: !chat.isPrivateMode && context.getStaticFeatureGating(.imageViewerInMessageScenesTranslateEnable),
            canViewInChat: canViewInChat,
            translateEntityContext: (message.id, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            },
            buttonType: .stack(config: .init(getAllAlbumsBlock: nil)),
            showAddToSticker: showAddToSticker
        )
        body.customTransition = BaseImageViewWrapperTransition()
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}

final class MessageDetailImageContentActionHandler<C: ImageContentContext>: ImageContentActionHandler<C> {
    override func imageDidTapped(
        _ view: ChatImageViewWrapper,
        chat: Chat,
        message: Message,
        permissionPreview: (Bool, ValidateResult?),
        dynamicAuthorityEnum: DynamicAuthorityEnum,
        allMessages: [Message],
        canViewInChat: Bool,
        showAddToSticker: Bool
    ) {
        let context = self.context
        if !(permissionPreview.0 && dynamicAuthorityEnum.authorityAllowed) {
            context.handlerPermissionPreviewOrReceiveError(receiveAuthResult: dynamicAuthorityEnum,
                                                           previewAuthResult: permissionPreview.1,
                                                           resourceType: .image)
            return
        }
        let result = LKDisplayAsset.createAssetExceptForSticker(
            messages: allMessages,
            selected: message.id,
            cid: message.cid,
            downloadFileScene: context.downloadFileScene,
            isMeSend: context.isMe,
            checkPreviewPermission: { [weak self] message in
                return self?.context.checkPreviewAndReceiveAuthority(chat: chat, message: message) ?? .allow
            },
            chat: chat
        )
        guard !result.assets.isEmpty,
            let index = result.selectIndex else {
                return
        }
        result.assets[index].visibleThumbnail = view.imageView
        let messageId = message.id
        var body = PreviewImagesBody(
            assets: result.assets.map({ $0.transform() }),
            pageIndex: index,
            scene: .normal(assetPositionMap: result.assetPositionMap, chatId: chat.id),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: chat.shouldDetectFile,
            canSaveImage: !chat.enableRestricted(.download),
            canShareImage: !chat.enableRestricted(.forward),
            canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
            canTranslate: !chat.isPrivateMode && context.getStaticFeatureGating(.imageViewerInMessageScenesTranslateEnable),
            canViewInChat: canViewInChat,
            translateEntityContext: (message.id, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            },
            buttonType: .stack(config: .init(getAllAlbumsBlock: nil)),
            showAddToSticker: showAddToSticker
        )
        body.customTransition = BaseImageViewWrapperTransition()
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}

final class PinImageContentActionHandler<C: ImageContentContext>: ImageContentActionHandler<C> {
    override func imageDidTapped(
        _ view: ChatImageViewWrapper,
        chat: Chat,
        message: Message,
        permissionPreview: (Bool, ValidateResult?),
        dynamicAuthorityEnum: DynamicAuthorityEnum,
        allMessages: [Message],
        canViewInChat: Bool,
        showAddToSticker: Bool
    ) {
        let context = self.context
        if !(permissionPreview.0 && dynamicAuthorityEnum.authorityAllowed) {
            context.handlerPermissionPreviewOrReceiveError(receiveAuthResult: dynamicAuthorityEnum,
                                                           previewAuthResult: permissionPreview.1,
                                                           resourceType: .image)
            return
        }
        let result = LKDisplayAsset.createAssetExceptForSticker(
            messages: allMessages,
            selected: message.id,
            cid: message.cid,
            downloadFileScene: context.downloadFileScene,
            isMeSend: context.isMe,
            checkPreviewPermission: { [weak self] message in
                return self?.context.checkPreviewAndReceiveAuthority(chat: chat, message: message) ?? .allow
            },
            chat: chat
        )
        guard !result.assets.isEmpty,
            let index = result.selectIndex else {
                return
        }
        result.assets[index].visibleThumbnail = view.imageView
        let messageId = message.id
        var body = PreviewImagesBody(
            assets: result.assets.map { $0.transform() },
            pageIndex: index,
            scene: .normal(assetPositionMap: result.assetPositionMap, chatId: nil),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: chat.shouldDetectFile,
            canSaveImage: !chat.enableRestricted(.download),
            canShareImage: !chat.enableRestricted(.forward),
            canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
            canTranslate: context.getStaticFeatureGating(.imageViewerInOtherScenesTranslateEnable),
            canViewInChat: canViewInChat,
            translateEntityContext: (nil, .other),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            },
            buttonType: .stack(config: .init(getAllAlbumsBlock: nil)),
            showAddToSticker: showAddToSticker
        )
        body.customTransition = BaseImageViewWrapperTransition()
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}
