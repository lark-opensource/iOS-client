//
//  CryptoImageContentViewModel.swift
//  LarkMessageCore
//
//  Created by zc09v on 2022/1/17.
//

import Foundation
import LarkModel
import LarkMessageBase
import RxSwift
import RxCocoa
import LarkMessengerInterface
import EENavigator
import ByteWebImage
import LarkCore
import LarkUIKit
import LarkSetting
import LarkFeatureSwitch
import RustPB
import AppReciableSDK
import UIKit
import LKCommonsLogging
import LarkSDKInterface

private let logger = Logger.log(NSObject(), category: "CryptoImageContentViewModel")

class CryptoImageContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ImageContentContext>: MessageSubViewModel<M, D, C> {
    public override var identifier: String {
        return "image"
    }

    private var content: ImageContent {
        return (message.content as? ImageContent) ?? .transform(pb: RustPB.Basic_V1_Message())
    }

    private lazy var fetchKeyWithCrypto: Bool = {
        return self.context.getStaticFeatureGating("messenger.image.resource_not_found")
    }()

    @PageContext.InjectedLazy var userGeneralSettings: UserGeneralSettings?

    var imageTrackScene: Scene {
        return .SecretChat
    }

    public var originSize: CGSize {
        // origin 的数据可能不是不准确的，有intact优先用intact，并根据exifOrientation决定宽高
        return content.image.intactSize
    }

    public var setImageAction: ChatImageViewWrapper.SetImageType {
        return { [weak self] imageView, completion in
            guard let self else { return }
            let content = self.content
            let scene = self.imageTrackScene
            let type = self.metaModel.getChat().type
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
            if self.context.scene == .threadDetail || self.context.scene == .replyInThread {
                chatType = .threadDetail
            }
            let imageSet = ImageItemSet.transform(imageSet: content.image)
            let inlineImage = imageSet.inlinePreview
            let metrics: [String: String] = [
                "message_id": self.metaModel.message.id
            ]
            let resource: LarkImageResource
            if self.fetchKeyWithCrypto {
                resource = imageSet.getThumbResource()
            } else {
                resource = .default(key: imageSet.getThumbKey())
            }
            let isOrigin = imageSet.isOrigin(resource: resource)
            imageView.bt.setLarkImage(
                with: resource,
                placeholder: inlineImage,
                options: [.ignoreCache(.disk), .notCache(.disk)],
                trackStart: {
                    TrackInfo(biz: .Messenger,
                              scene: scene,
                              isOrigin: isOrigin,
                              fromType: .image,
                              chatType: chatType,
                              metric: metrics
                    )
                },
                completion: { result in
                    switch result {
                    case .success(let imageResult):
                        let image = imageResult.image
                        completion(image, nil)
                    case .failure(let error):
                        completion(nil, error)
                    }
                }
            )
        }
    }

    public let isShowProgress = true

    public var currentFrameIndex = 0

    public var currentFrame: UIImage?

    public var hasInlinePreview: Bool {
        let imageSet = content.image
        return imageSet.hasInlinePreview && !imageSet.inlinePreview.isEmpty
    }

    public var imageMaxSize: CGSize {
        // 得到内容展示的最大宽度
        var maxContentWidth = self.metaModelDependency.getContentPreferMaxWidth(message)
        // 根据自身contentConfig，判断是否需要去掉margin
        if self.contentConfig?.hasMargin ?? false {
            maxContentWidth -= self.metaModelDependency.contentPadding * 2
        }
        // 计算出实际能展示的最大宽度限制
        let validMaxWidth = min(BaseImageView.Cons.imageMaxDisplaySize.width, maxContentWidth)
        return CGSize(width: validMaxWidth, height: BaseImageView.Cons.imageMaxDisplaySize.height)
    }

    public var shouldAddBorder: Bool {
        return !(self.context.scene == .newChat && message.parentId.isEmpty && message.reactions.isEmpty)
    }

    public var sendProgress: Float {
        return self.progressReplay.value
    }

    private let progressReplay: BehaviorRelay<Float> = BehaviorRelay(value: SendImageProgressState.zero.rawValue)

    public private(set) var shouldAnimating: Bool = true {
        didSet {
            if self.shouldAnimating == oldValue {
                return
            }
            self.binder.update(with: self)
            self.update(component: self.binder.component, animation: .none)
        }
    }

    private let disposeBag = DisposeBag()
    private var progressBag = DisposeBag()
    private var isDisplay: Bool = false

    public override init(metaModel: M, metaModelDependency: D, context: C, binder: ComponentBinder<C>) {
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
    }

    public override func initialize() {
        self.observeProgress()

        if message.localStatus == .success {
            self.progressReplay.accept(SendImageProgressState.sendSuccess.rawValue)
            return
        }
        if content.image.hasInlinePreview, !content.image.inlinePreview.isEmpty {
            self.progressReplay.accept(SendImageProgressState.sendSuccess.rawValue)
            return
        }
        if message.localStatus == .fail {
            self.progressReplay.accept(SendImageProgressState.sendFail.rawValue)
        }
        self.context.progressValue(key: content.image.origin.key)
            .subscribe(onNext: { [weak self] (progress) in
                if self?.message.localStatus == .fail { self?.progressReplay.accept(SendImageProgressState.sendFail.rawValue) }
                self?.progressReplay.accept(Float(progress.fractionCompleted))
            })
            .disposed(by: self.disposeBag)
    }

    public override func update(metaModel: M, metaModelDependency: D?) {
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        if message.localStatus == .success {
            self.progressReplay.accept(SendImageProgressState.sendSuccess.rawValue)
        } else if message.localStatus == .fail {
            self.progressReplay.accept(SendImageProgressState.sendFail.rawValue)
        } else {
            self.progressReplay.accept(
                Float(self.context.getProgressValue(key: content.image.origin.key)?.fractionCompleted ??
                      Double(SendImageProgressState.zero.rawValue))
            )
        }
    }

    public override var contentConfig: ContentConfig? {
        if message.parentMessage != nil || !message.reactions.isEmpty {
            return ContentConfig(hasMargin: true, maskToBounds: true, supportMutiSelect: true)
        }
        return ContentConfig(hasMargin: false, maskToBounds: true, supportMutiSelect: true)
    }

    public override func willDisplay() {
        super.willDisplay()
        self.observeProgress()
        self.shouldAnimating = true
        self.isDisplay = true
    }

    public override func didEndDisplay() {
        super.didEndDisplay()
        // 不显示时停止监听进度变化
        self.progressBag = DisposeBag()
        self.shouldAnimating = false
        self.isDisplay = false
    }

    deinit {
        guard !self.isDisplay else {
            return
        }
        let key = ImageItemSet.transform(imageSet: content.image).getThumbKey()
        LarkImageService.shared.removeCache(resource: LarkImageResource.default(key: key), options: .memory)
    }

    public func imageDidTapped(_ view: ChatImageViewWrapper) {
        assertionFailure("must override")
    }

    private func observeProgress() {
        if self.message.localStatus == .success {
            return
        }
        self.progressBag = DisposeBag()
        if content.image.hasInlinePreview, !content.image.inlinePreview.isEmpty {
            return
        }
        self.progressReplay.asObservable()
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.binder.update(with: self)
                self.update(component: self.binder.component, animation: .none)
            })
            .disposed(by: self.progressBag)
    }
}

extension CryptoImageContentViewModel: AnimatedViewDelegate {
    public func animatedImageView(_ imageView: ByteImageView, didPlayAnimationLoops count: UInt) {
    }

    public func animatedImageViewDidFinishAnimating(_ imageView: ByteImageView) {
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

final class CryptoChatImageContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ImageContentContext>: CryptoImageContentViewModel<M, D, C> {
    override var imageTrackScene: Scene {
        return .SecretChat
    }

    override func imageDidTapped(_ view: ChatImageViewWrapper) {
        // Chat图片查看逻辑：当前图构造asset，调用预览图接口，支持前后翻页，并且表情、帖子、视频图片都可以预览
        let viewModels: [ChatMessageCellViewModel<M, D>] = self.context.filter { _ in true }
        let messages = viewModels.map { $0.content.message }

        let result = LKDisplayAsset.createAssetExceptForSticker(
            messages: messages, selected: self.message.id, cid: self.message.cid, isMeSend: context.isMe
        )
        guard !result.assets.isEmpty,
            let index = result.selectIndex else {
            return
        }
        IMTracker.Chat.Main.Click.Msg.Image(self.metaModel.getChat(), self.message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        result.assets[index].visibleThumbnail = view.imageView
        let chat = self.metaModel.getChat()
        let context = self.context
        let messageId = self.message.id
        var body = PreviewImagesBody(
            assets: result.assets.map({ $0.transform() }),
            pageIndex: index,
            scene: .chat(chatId: message.channel.id, chatType: chat.type, assetPositionMap: result.assetPositionMap),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: false,
            canSaveImage: false,
            canShareImage: false,
            canEditImage: false,
            hideSavePhotoBut: true,
            canTranslate: false,
            translateEntityContext: (nil, .message),
            canImageOCR: false,
            dismissCallback: {
                // need hold local object.self maybe deinit when come new message.
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            },
            buttonType: .stack(config: .init(getAllAlbumsBlock: { [weak context] in
                if let context = context {
                    return context.getChatAlbumDataSourceImpl(chat: chat, isMeSend: context.isMe)
                }
                return DefaultAlbumDataSourceImpl()
            })),
            showAddToSticker: false
        )
        body.customTransition = BaseImageViewWrapperTransition()
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }

    public override var contentConfig: ContentConfig? {
        if message.parentMessage != nil || !message.reactions.isEmpty {
            return ContentConfig(hasMargin: true, maskToBounds: true, supportMutiSelect: true)
        }
        var contentConfig = ContentConfig(hasMargin: false, maskToBounds: true, supportMutiSelect: true, hasBorder: true)
        contentConfig.borderStyle = .image
        return contentConfig
    }
}

final class CryptoChatMessageDetailImageContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ImageContentContext>: CryptoImageContentViewModel<M, D, C> {
    override var imageTrackScene: Scene {
        return .Detail
    }

    override var shouldAddBorder: Bool {
        return true
    }
    override func imageDidTapped(_ view: ChatImageViewWrapper) {
        let viewModels: [MessageDetailMessageCellViewModel<M, D>] = self.context.filter { _ in true }
        let messages = viewModels.map { $0.content.message }
        let result = LKDisplayAsset.createAssetExceptForSticker(
            messages: messages,
            selected: self.message.id,
            cid: self.message.cid,
            isMeSend: context.isMe
        )
        guard !result.assets.isEmpty,
            let index = result.selectIndex else {
                return
        }
        result.assets[index].visibleThumbnail = view.imageView
        let chat = self.metaModel.getChat()
        let context = self.context
        let messageId = self.message.id
        var body = PreviewImagesBody(
            assets: result.assets.map({ $0.transform() }),
            pageIndex: index,
            scene: .normal(assetPositionMap: result.assetPositionMap, chatId: chat.id),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: false,
            canSaveImage: false,
            canShareImage: false,
            canEditImage: false,
            hideSavePhotoBut: true,
            canTranslate: false,
            translateEntityContext: (nil, .message),
            canImageOCR: false,
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            },
            buttonType: .stack(config: .init(getAllAlbumsBlock: nil)),
            showAddToSticker: false
        )
        body.customTransition = BaseImageViewWrapperTransition()
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}
