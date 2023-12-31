//
//  ReplyComponentActionHandler.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/2/7.
//

import UIKit
import Foundation
import LarkCore
import LarkUIKit
import LarkModel
import LarkMessageBase
import LKCommonsLogging
import LarkSetting
import LarkMessengerInterface
import AsyncComponent

private let logger = Logger.log(LarkMessageBase.ViewModelContext.self, category: "ReplyComponentActionHandler")

class ReplyComponentActionHandler<C: ReplyViewModelContext>: ComponentActionHandler<C>, CellTopReplyInlinePreviewTappable {
    public func replyViewTapped(replyMessage: Message?, chat: Chat) {
        guard let replyMessage = replyMessage else {
            return
        }
        let body = MessageDetailBody(chat: chat,
                                     message: replyMessage,
                                     source: .replyMsg,
                                     chatFromWhere: ChatFromWhere(fromValue: context.trackParams[PageContext.TrackKey.sceneKey] as? String) ?? .ignored)
        context.navigator(type: .push, body: body, params: nil)
        LarkMessageCoreTracker.trackShowMessageDetail(type: .parentMessage)
    }
}

final class MergeForwardDetailReplyComponentActionHandler<Context: ReplyViewModelContext>: ReplyComponentActionHandler<Context> {
    override func replyViewTapped(replyMessage: Message?, chat: Chat) {
    }
}

// reply区域顶部抽出来图片点击的通用能力，供引用回复和同时发送到群的话题回复同时使用
protocol CellTopReplyInlinePreviewTappable: AnyObject {
    associatedtype ContextType: ReplyViewModelContext
    var context: ContextType { get }
    func replyViewTapped(replyMessage: Message?, chat: Chat)
    func replyImageTapped(
        imageView: UIImageView,
        replyMessage: Message,
        chat: Chat,
        messageID: String,
        permissionPreview: (Bool, ValidateResult?),
        dynamicAuthorityEnum: DynamicAuthorityEnum)
}

extension CellTopReplyInlinePreviewTappable {
    public func replyImageTapped(
        imageView: UIImageView,
        replyMessage: Message,
        chat: Chat,
        messageID: String,
        permissionPreview: (Bool, ValidateResult?),
        dynamicAuthorityEnum: DynamicAuthorityEnum
    ) {
        let result: CreateAssetsResult
        /// 表情消息走特殊处理
        if replyMessage.content is StickerContent {
            result = LKDisplayAsset.createAssetForSticker(messages: [replyMessage], currentMessage: replyMessage)
        } else {
            result = LKDisplayAsset.createAssetExceptForSticker(
                messages: [replyMessage],
                isMeSend: context.isMe,
                checkPreviewPermission: { [weak self] message in
                    return self?.context.checkPreviewAndReceiveAuthority(chat: chat, message: message) ?? .allow
                },
                chat: chat.isCrypto ? nil : chat // 密聊不需要传
            )
        }
        guard !result.assets.isEmpty, let index = result.selectIndex else { return }
        result.assets[index].visibleThumbnail = imageView
        let context = self.context
        if !(permissionPreview.0 && dynamicAuthorityEnum.authorityAllowed) {
            context.handlerPermissionPreviewOrReceiveError(receiveAuthResult: dynamicAuthorityEnum,
                                                           previewAuthResult: permissionPreview.1,
                                                           resourceType: .image)
            return
        }
        let body = PreviewImagesBody(
            assets: result.assets.map({ $0.transform() }),
            pageIndex: index,
            scene: .normal(assetPositionMap: result.assetPositionMap, chatId: chat.id),
            trackInfo: PreviewImageTrackInfo(messageID: messageID),
            shouldDetectFile: chat.shouldDetectFile,
            canSaveImage: !chat.isCrypto && !chat.enableRestricted(.download),
            canShareImage: !chat.isCrypto && !chat.enableRestricted(.forward),
            canEditImage: !chat.isCrypto && (!chat.enableRestricted(.forward) || !chat.enableRestricted(.download)),
            hideSavePhotoBut: chat.isCrypto,
            canTranslate: !chat.isCrypto && !chat.isPrivateMode && self.context.getStaticFeatureGating(.imageViewerInMessageScenesTranslateEnable),
            translateEntityContext: (replyMessage.id, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageID)")
                context.viewDidDisplay()
            },
            buttonType: replyMessage.type == .image ? .stack(config: .init(getAllAlbumsBlock: nil)) : .onlySave,
            showAddToSticker: !chat.isCrypto && !chat.isPrivateMode && !chat.enableRestricted(.download)
        )
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}
