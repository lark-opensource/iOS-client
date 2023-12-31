//
//  StickerContentViewModel.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/5/30.
//

import Foundation
import LarkModel
import LarkMessageBase
import EENavigator
import LarkUIKit
import LarkMessengerInterface
import LarkSetting
import ByteWebImage
import LarkAssetsBrowser
import RustPB
import LarkCore
import AppReciableSDK
import UIKit
import LKCommonsLogging

private var logger = Logger.log(NSObject(), category: "LarkMessage.StickerContentViewModel")

class StickerContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: StickerContentContext>: NewMessageSubViewModel<M, D, C> {
    public override var identifier: String {
        return "sticker"
    }

    var trackScene: Scene {
        assertionFailure("Must be overrided!")
        return .Chat
    }

    var content: StickerContent {
        return (self.message.content as? StickerContent) ?? .transform(pb: RustPB.Basic_V1_Message())
    }

    var allMessages: [Message] {
        return []
    }

    public var originSize: CGSize {
        return CGSize(width: CGFloat(content.width), height: CGFloat(content.height))
    }

    public var setImageAction: ChatImageViewWrapper.SetImageType {
        return { [weak self] imageView, completion in
            guard let content = self?.content,
                  let scene = self?.trackScene,
                  let type = self?.metaModel.getChat().type
            else {
                return
            }
            var chatType = TrackInfo.ChatType.unkonwn
            switch type {
            case .group:
                chatType = .group
            case .p2P:
                chatType = .single
            case .topicGroup:
                chatType = .topic
            @unknown default:
                chatType = .unkonwn
            }
            if self?.context.scene == .threadDetail || self?.context.scene == .replyInThread {
                chatType = .threadDetail
            }
            let resource = LarkImageResource.sticker(key: content.key,
                                                     stickerSetID: content.stickerSetID)
            let metrics: [String: String] = [
                "message_id": self?.metaModel.message.id ?? ""
            ]
            imageView.bt.setLarkImage(
                with: resource,
                trackStart: {
                    TrackInfo(biz: .Messenger,
                              scene: scene,
                              fromType: .sticker,
                              chatType: chatType,
                              metric: metrics)
                },
                completion: { result in
                    switch result {
                    case .success(let imageResult):
                        completion(imageResult.image, nil)
                    case .failure(let error):
                        completion(nil, error)
                    }
                }
            )
        }
    }

    public var isShowProgress = false

    public var currentFrameIndex = 0

    public var currentFrame: UIImage?

    public var shouldAddBorder: Bool {
        if (self.context.scene == .newChat || self.context.scene == .mergeForwardDetail), message.showInThreadModeStyle {
            return true
        }
        return !message.parentId.isEmpty || !message.reactions.isEmpty
    }

    public private(set) var shouldAnimating: Bool = true {
        didSet {
            if self.shouldAnimating == oldValue {
                return
            }
            self.binderAbility?.syncToBinder()
            self.binderAbility?.updateComponent()
        }
    }

    private var isDisplay: Bool = false

    public var imageMaxSize: CGSize {
        let maxCellWidth = metaModelDependency.getContentPreferMaxWidth(message)
        let width = maxCellWidth * 0.6 > 150 ? 150 : maxCellWidth * 0.6
        return CGSize(width: width, height: width)
    }

    public override var contentConfig: ContentConfig? {
        let threadStyleConfig = ThreadStyleConfig(addBorderBySelf: true)
        if message.parentMessage != nil || !message.reactions.isEmpty {
            return ContentConfig(hasMargin: true, maskToBounds: true,
                                 supportMutiSelect: true, threadStyleConfig: threadStyleConfig)
        } else if message.isUrgent {
            var contentConfig = ContentConfig(hasMargin: false, maskToBounds: true,
                                              supportMutiSelect: true, hasBorder: true,
                                              threadStyleConfig: threadStyleConfig)
            contentConfig.borderStyle = .other
            return contentConfig
        }
        return ContentConfig(hasMargin: false, backgroundStyle: .clear, maskToBounds: true, supportMutiSelect: true, threadStyleConfig: threadStyleConfig)
    }

    public override func willDisplay() {
        super.willDisplay()
        self.shouldAnimating = true
        self.isDisplay = true
    }

    public override func didEndDisplay() {
        super.didEndDisplay()
        self.shouldAnimating = false
        self.isDisplay = false
    }

    deinit {
        guard !isDisplay else {
            return
        }
        LarkImageService.shared.removeCache(resource: .sticker(key: content.key, stickerSetID: content.stickerSetID),
                                            options: .memory)
    }
}

extension StickerContentViewModel: AnimatedViewDelegate {
    public func animatedImageViewDidFinishAnimating(_ imageView: ByteImageView) {
    }

    public func animatedImageView(_ imageView: ByteImageView, didPlayAnimationLoops count: UInt) {
    }

    public func animatedImageViewCurrentFrameIndex(_ imageView: ByteImageView, image: UIImage, index: Int) {
        currentFrameIndex = index
        currentFrame = image
    }

    public func animatedImageViewReadyToPlay(_ imageView: ByteImageView) {
    }

    public func animatedImageViewHasPlayedFirstFrame(_ imageView: ByteImageView) {
    }

    public func animatedImageViewCompleted(_ imageView: ByteImageView) {
    }
}

class ChatStickerContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: StickerContentContext>: StickerContentViewModel<M, D, C> {
    override var allMessages: [Message] {
        let viewModels: [ChatMessageCellViewModel<M, D>] = self.context.filter { _ in true }
        return viewModels.map { $0.content.message }
    }

    override var trackScene: Scene {
        return .Chat
    }
}

class MessageLinkStickerContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: StickerContentContext>: ChatStickerContentViewModel<M, D, C> {
    override var allMessages: [Message] {
        return [self.message]
    }
}

final class ThreadChatStickerContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: StickerContentContext>: StickerContentViewModel<M, D, C> {
    override var trackScene: Scene {
        return .Thread
    }

    override var shouldAddBorder: Bool {
        return false
    }
}

final class ThreadDetailStickerContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: StickerContentContext>: StickerContentViewModel<M, D, C> {
    override var allMessages: [Message] {
        let viewModels: [ThreadDetailMessageCellViewModel<M, D>] = self.context.filter { _ in true }
        return viewModels.map { $0.content.message }
    }

    override var trackScene: Scene {
        return .Thread
    }

    override var shouldAddBorder: Bool {
        return false
    }
}

final class MergeForwardDetailStickerContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: StickerContentContext>: StickerContentViewModel<M, D, C> {
    override var allMessages: [Message] {
        let viewModels: [MergeForwardMessageCellViewModel<M, D>] = self.context.filter { _ in true }
        return viewModels.map { $0.content.message }
    }

    override var trackScene: Scene {
        return .Chat
    }
}

final class MessageDetailStickerContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: StickerContentContext>: StickerContentViewModel<M, D, C> {
    override var allMessages: [Message] {
        let viewModels: [MessageDetailMessageCellViewModel<M, D>] = self.context.filter { _ in true }
        return viewModels.map { $0.content.message }
    }

    override var trackScene: Scene {
        return .Chat
    }
}

final class PinStickerContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: StickerContentContext>: StickerContentViewModel<M, D, C> {
    override var allMessages: [Message] {
        let viewModels: [PinMessageCellViewModel<M, D>] = self.context.filter { _ in true }
        return viewModels.map { $0.content.message }
    }

    override var trackScene: Scene {
        return .Pin
    }
}
