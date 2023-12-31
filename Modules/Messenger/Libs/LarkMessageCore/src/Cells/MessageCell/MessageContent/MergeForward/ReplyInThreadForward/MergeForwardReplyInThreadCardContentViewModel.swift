//
//  MMergeForwardReplyInThreadCardContentViewModel.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/5/24.
//
import UIKit
import Foundation
import LarkMessageBase
import LarkModel
import Swinject
import EENavigator
import LarkMessengerInterface
import LarkFeatureSwitch
import RustPB
import LarkCore
import LarkUIKit
import LKCommonsLogging
import ByteWebImage
import LarkAlertController
import LarkContainer
import LarkSDKInterface

final class MergeForwardReplyInThreadCardContentViewModelLogger {
    static let logger = Logger.log(MergeForwardReplyInThreadCardContentViewModelLogger.self, category: "replyInThreadMergeForward")
}

/// 转发"群内的话题回复"到群
final class MergeForwardReplyInThreadCardContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: MergeForwardContentContext>: NewAuthenticationMessageSubViewModel<M, D, C> {
    override public var identifier: String {
        return "replyInThreadForwardCard"
    }

    private(set) var shouldAnimating: Bool = true {
        didSet {
            if self.shouldAnimating == oldValue || originSize == .zero {
                return
            }
            self.binderAbility?.syncToBinder()
            self.binderAbility?.updateComponent(animation: .none)
        }
    }

    var content: MergeForwardContent? {
        return message.content as? MergeForwardContent
    }

    var title: String {
        return MergeForwardPostCardTool.getTitleFromContent(content)
    }

    var isFromChatMember: Bool {
        return ReplyInThreadMergeForwardDataManager.isChatMember(content: content, currentChatterId: self.context.currentUserID)
    }

    var contextText: String {
        return content?.thread?.subtitle ?? ""
    }

    var fromTitle: String {
        return ReplyInThreadMergeForwardDataManager.fromTitleFor(content: content, currentChatterId: self.context.currentUserID)
    }

    var fromAvatar: String {
        return ReplyInThreadMergeForwardDataManager.fromAvatarFor(content: content, currentChatterId: self.context.currentUserID)
    }

    var entityId: String {
        return ReplyInThreadMergeForwardDataManager.fromAvatarEntityId(content: content, currentChatterId: self.context.currentUserID)
    }

    var originSize: CGSize {
        guard let item = MergeForwardCardItem.getImageSetForMergeForwardMessage(self.message) else {
            return .zero
        }
        return CGSize(width: CGFloat(item.originWidth ?? 0), height: CGFloat(item.originHeight ?? 0))
    }

    var imageMaxSize: CGSize {
        return CGSize(width: 64, height: 64)
    }

    var permissionPreview: (Bool, ValidateResult?) {
        if let firstMsg = content?.messages.first {
            return context.checkPermissionPreview(chat: metaModel.getChat(), message: firstMsg)
        }
        return (true, nil)
    }

    public override var authorityMessage: Message? {
        let firstMsg = content?.messages.first
        return firstMsg
    }

    /// 内容的最大宽度
    var contentMaxWidth: CGFloat {
        return metaModelDependency.getContentPreferMaxWidth(message)
    }

    func previewImageWith(visibleThumbnail: UIImageView) {
        guard let image = MergeForwardCardItem.getImagePropertyForMergeForwardMessage(message) else {
            return
        }
        if !(permissionPreview.0 && dynamicAuthorityEnum.authorityAllowed) {
            context.handlerPermissionPreviewOrReceiveError(receiveAuthResult: dynamicAuthorityEnum, previewAuthResult: permissionPreview.1, resourceType: .image)
            return
        }
        let result = LKDisplayAsset.createAsset(
            postImageProperty: image, isTranslated: false, isAutoLoadOrigin: context.isMe(message.fromId), message: message, chat: self.metaModel.getChat()
        )
        result.visibleThumbnail = visibleThumbnail
        let chat = self.metaModel.getChat()
        let body = PreviewImagesBody(assets: [result.transform()],
                                     pageIndex: 0,
                                     scene: .normal(assetPositionMap: [:], chatId: nil),
                                     trackInfo: PreviewImageTrackInfo(messageID: message.id),
                                     shouldDetectFile: chat.shouldDetectFile,
                                     canSaveImage: !chat.enableRestricted(.download),
                                     canShareImage: false,
                                     canEditImage: !chat.enableRestricted(.download),
                                     showSaveToCloud: !chat.enableRestricted(.download),
                                     canTranslate: false,
                                     translateEntityContext: (nil, .other),
                                     canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
                                     showAddToSticker: !chat.enableRestricted(.download))
        self.context.navigator(type: .push, body: body, params: nil)
    }

    var setImageAction: ChatImageViewWrapper.SetImageType {
        return { [weak self] imageView, completion in
            guard let self = self,
                  let item = MergeForwardCardItem.getImageSetForMergeForwardMessage(self.message) else {
                return
            }
            let key = item.generateImageMessageKey(forceOrigin: false)
            let placeholder = item.inlinePreview
            let metrics: [String: String] = [
                "message_id": self.message.id
            ]
            imageView.bt.setLarkImage(with: .default(key: key),
                                      placeholder: placeholder,
                                      trackStart: {
                                        TrackInfo(biz: .Messenger,
                                                  scene: .Forward,
                                                  fromType: .image,
                                                  metric: metrics)
                                      },
                                      completion: { result in
                                          switch result {
                                          case let .success(imageResult):
                                              completion(imageResult.image, nil)
                                          case let .failure(error):
                                              completion(nil, error)
                                          }
                                      })
        }
    }

    @PageContext.InjectedLazy var userSettings: UserGeneralSettings?

    override var contentConfig: ContentConfig? {
        var contentConfig = ContentConfig(hasMargin: false, backgroundStyle: .white, maskToBounds: true, supportMutiSelect: true, hasBorder: true)
        contentConfig.isCard = true
        return contentConfig
    }
    override func willDisplay() {
        self.shouldAnimating = true
        super.willDisplay()
    }
    override func didEndDisplay() {
        self.shouldAnimating = false
        super.didEndDisplay()
    }
}
