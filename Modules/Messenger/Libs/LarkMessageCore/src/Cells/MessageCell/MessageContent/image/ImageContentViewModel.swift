//
//  ImageContentViewModel.swift
//  LarkMicroApp
//
//  Created by liuwanlin on 2019/5/29.
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
import LarkAlertController
import LKCommonsLogging
import LarkSDKInterface

struct ChatNoPreviewPermissionLayerSizeConfig {
    static let normalSize = CGSize(width: CGFloat(200), height: CGFloat(120))
    static let smallSize = CGSize(width: CGFloat(80), height: CGFloat(80))
}

enum SendImageProgressState: Float {
    // 等待展示态，发送图片后会等待0.5s再展示progress
    // 这个wait是端上自己添加的
    case wait = -1
    // 0态
    case zero = 0
    // 上传成功态
    case uploadSuccess = 1
    // 发送成功态
    case sendSuccess = 2
    // 失败态
    case sendFail = 3
}

private let logger = Logger.log(LarkMessageBase.ViewModelContext.self, category: "ImageContentViewModel")
class ImageContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ImageContentContext>: NewAuthenticationMessageSubViewModel<M, D, C> {
    public override var identifier: String {
        return "image"
    }

    /// 显示规则：原文、译文、原文+译文
    private var displayRule: RustPB.Basic_V1_DisplayRule

    //为防止业务上在权限拒绝的情况下渲染图片，所以当权限拒绝时从数据层把content改成了可选型。当权限变更时，会触发刷新UI
    private var content: ImageContent? {
        guard self.dynamicAuthorityEnum.authorityAllowed else { return nil }
        return self._content
    }

    //业务不应直接拿这个值，应该拿鉴权后的content。仅一些无需鉴权的逻辑（如清理cache）允许直接取这个值
    private var _content: ImageContent {
        let originalContent = (message.content as? ImageContent) ?? .transform(pb: RustPB.Basic_V1_Message())
        switch self.displayRule {
        case .onlyTranslation, .withOriginal:
            return message.translateContent as? ImageContent ?? originalContent
        case .noTranslation, .unknownRule:
            return originalContent
        @unknown default:
            return originalContent
        }
    }

    var imageTrackScene: Scene {
        assertionFailure("Must be overrided.")
        return .Chat
    }

    var allMessages: [Message] {
        return []
    }

    // 点击查看大图时，是否支持「跳转至会话」
    var canViewInChat: Bool {
        if let myAIPageService = try? self.context.userResolver.resolve(type: MyAIPageService.self), myAIPageService.chatMode { return false }
        return true
    }

    // 是否显示添加表情
    var showAddToSticker: Bool {
        let chat = metaModel.getChat()
        return !chat.isPrivateMode && !chat.enableRestricted(.download)
    }

    public var originSize: CGSize {
        guard let content = content else { return ChatNoPreviewPermissionLayerSizeConfig.normalSize }
        // origin 的数据可能不是不准确的，有intact优先用intact，并根据exifOrientation决定宽高
        return getPreviewSize(content.image.intactSize)
    }

    func getPreviewSize(_ size: CGSize) -> CGSize {
        return (permissionPreview.0 && dynamicAuthorityEnum.authorityAllowed) ? size : ChatNoPreviewPermissionLayerSizeConfig.normalSize
    }

    private lazy var fetchKeyWithCrypto: Bool = {
        return self.context.getStaticFeatureGating("messenger.image.resource_not_found")
    }()

    @PageContext.InjectedLazy var userGeneralSettings: UserGeneralSettings?

    public var setImageAction: ChatImageViewWrapper.SetImageType {
        return { [weak self] imageView, completion in
            guard let self, let content = self.content else { return }
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
            let metrics: [String: Any] = [
                "message_id": self.metaModel.message.id ?? "",
                "is_message_delete": self.metaModel.message.isDeleted ?? false
            ]

            let resource: LarkImageResource
            let isOrigin: Bool
            if self.fetchKeyWithCrypto {
                if let cacheItem = ImageDisplayStrategy.messageImage(imageItem: imageSet, scene: .imageMessage,
                                                                     originSize: Int(content.originFileSize)) {
                    resource = cacheItem.imageResource()
                } else {
                    resource = imageSet.getThumbResource()
                }
                isOrigin = imageSet.isOrigin(resource: resource)
            } else {
                // 可以查找缓存的FG开启，并在key和originKey中找到缓存
                if let cacheKey = ImageDisplayStrategy.messageImage(imageItem: imageSet, scene: .imageMessage,
                                                                    originSize: Int(content.originFileSize))?.key {
                    resource = .default(key: cacheKey)
                } else {
                    resource = .default(key: imageSet.getThumbKey())
                }
                isOrigin = imageSet.isOrigin(resource: resource)
            }
            imageView.bt.setLarkImage(
                with: resource,
                placeholder: inlineImage,
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
                        // 这里completion的image是指view上正在贴的图。
                        // 如果请求图片失败，会向外抛出placeholder的inline图。
                        completion(inlineImage, error)
                    }
                }
            )
        }
    }

    public var isShowProgress: Bool = true

    public var currentFrameIndex = 0

    public var currentFrame: UIImage?

    public var hasInlinePreview: Bool {
        guard let content = content else { return false }
        let imageSet = content.image
        return imageSet.hasInlinePreview && !imageSet.inlinePreview.isEmpty
    }

    public var imageMaxSize: CGSize {
        // 得到内容展示的最大宽度
        var maxContentWidth = self.metaModelDependency.getContentPreferMaxWidth(message)
        // 根据自身contentConfig，判断是否需要去掉margin
        if self.contentConfig?.hasMargin ?? false && !((self.context.scene == .newChat || self.context.scene == .mergeForwardDetail) && self.message.showInThreadModeStyle) {
            maxContentWidth -= self.metaModelDependency.contentPadding * 2
        }
        // 计算出实际能展示的最大宽度限制
        let validMaxWidth = min(BaseImageView.Cons.imageMaxDisplaySize.width, maxContentWidth)
        return CGSize(width: validMaxWidth, height: BaseImageView.Cons.imageMaxDisplaySize.height)
    }

    public var permissionPreview: (Bool, ValidateResult?) {
        context.checkPermissionPreview(chat: metaModel.getChat(), message: metaModel.message)
    }

    public var shouldAddBorder: Bool {
        if (self.context.scene == .newChat || self.context.scene == .mergeForwardDetail), message.showInThreadModeStyle {
            return true
        }
        // 会话和转发页，单图不自己画边框，由 BubbleView 统一画
        return !([.newChat, .mergeForwardDetail].contains(self.context.scene) &&
                 message.parentId.isEmpty && message.reactions.isEmpty)
    }

    public var sendProgress: Float {
        return uploadProgress?.progressReplay.value ?? 0
    }

    private lazy var uploadProgress: UploadProgressStatusManager? = {
        return UploadProgressStatusManager(messageId: metaModel.message.id,
                                           dependency: { [weak self] in
            return try? self?.context.resolver.resolve(assert: SDKDependency.self)
        })
    }()

    public private(set) var shouldAnimating: Bool = true {
        didSet {
            if self.shouldAnimating == oldValue {
                return
            }
            self.binderAbility?.syncToBinder()
            self.binderAbility?.updateComponent(animation: .none)
        }
    }

    private let disposeBag = DisposeBag()
    private var progressBag = DisposeBag()
    private var isDisplay: Bool = false

    public override init(metaModel: M, metaModelDependency: D, context: C) {
        self.displayRule = metaModel.message.displayRule
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context)
    }

    public override func initialize() {
        super.initialize()
        self.observeProgress()
        if message.localStatus == .success {
            // 隐藏上传进度
            uploadProgress?.successeEnd()
            return
        }
        guard let content = self.content else {
            //下面的逻辑都是上传进度相关。
            //按照预期，自己上传的文件 权限一定是allow，即self.content一定不为空
            return
        }

        // 图片发送中是没有inlinePreview的，所以这里的逻辑不生效
        // 图片下载中，如果有inline，本来下载也不展示上传进度，所以隐藏
        if content.image.hasInlinePreview, !content.image.inlinePreview.isEmpty {
            // 隐藏上传进度
            uploadProgress?.successeEnd()
            return
        }
        if message.localStatus == .fail {
            // 隐藏上传进度
            uploadProgress?.failEnd()
            // 这里不return，消息可能会进入重试，还是需要监听push
        }
        // 开始计时准备展示
        uploadProgress?.start(messageLocalStatus: message.localStatus)
        // 接受progress的push，主动更新
        self.context.progressValue(key: content.image.origin.key)
            .subscribe(onNext: { [weak self] (progress) in
                self?.updateProgress(progressValue: { Float(progress.fractionCompleted) })
            })
            .disposed(by: self.disposeBag)
    }

    public override func update(metaModel: M, metaModelDependency: D?) {
        self.displayRule = metaModel.message.displayRule
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        // cell的更新，主动获取状态
        guard let content = self.content else {
            //下面的逻辑都是上传进度相关。
            //按照预期，自己上传的文件 权限一定是allow，即self.content一定不为空
            return
        }
        updateProgress(progressValue: { [weak self] () in
            let progressValue = self?.context.getProgressValue(key: content.image.origin.key)?.fractionCompleted ??
            Double(SendImageProgressState.zero.rawValue)
            return Float(progressValue)
        })
    }

    public override var contentConfig: ContentConfig? {
        let threadStyleConfig = ThreadStyleConfig(addBorderBySelf: true)
        if message.parentMessage != nil || !message.reactions.isEmpty {
            return ContentConfig(hasMargin: true, maskToBounds: true,
                                 supportMutiSelect: true, threadStyleConfig: threadStyleConfig)
        }
        return ContentConfig(hasMargin: false, maskToBounds: true,
                             supportMutiSelect: true, threadStyleConfig: threadStyleConfig)
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
        let key = ImageItemSet.transform(imageSet: self._content.image).getThumbKey() //这里仅用于清理cache，无须取鉴权数据
        LarkImageService.shared.removeCache(resource: LarkImageResource.default(key: key), options: .memory)
    }

    private func observeProgress() {
        if self.message.localStatus == .success {
            return
        }
        guard let content = self.content else {
            //下面的逻辑都是上传进度相关。
            //按照预期，自己上传的文件 权限一定是allow，即self.content一定不为空
            return
        }
        self.progressBag = DisposeBag()
        if content.image.hasInlinePreview, !content.image.inlinePreview.isEmpty {
            return
        }
        uploadProgress?.progressReplay.asObservable()
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] (value) in
                guard let `self` = self else { return }
                logger.info("\(self.message.id) real progress \(value)")
                self.binderAbility?.syncToBinder()
                self.binderAbility?.updateComponent(animation: .none)
            }).disposed(by: self.progressBag)
    }

    private func updateProgress(progressValue: () -> Float) {
        // message状态已经完成，不显示进度
        if message.localStatus == .success {
            logger.info("\(message.id) update progress, message local status success")
            uploadProgress?.successeEnd()
            return
        } else if message.localStatus == .fail {
            // message状态已经失败，传回来的进度不用。如果是重发，那么状态不是fail
            logger.info("\(message.id) update progress, message local status fail")
            uploadProgress?.failEnd()
            return
        } else {
            let progressValue: Float = progressValue()
            logger.info("\(message.id) update progress, progress show \(progressValue)")
            uploadProgress?.update(value: progressValue)
        }
    }
}

extension ImageContentViewModel: AnimatedViewDelegate {
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

final class ChatImageContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ImageContentContext>: ImageContentViewModel<M, D, C> {
    override var imageTrackScene: Scene {
        return .Chat
    }

    override var allMessages: [Message] {
        let viewModels: [ChatMessageCellViewModel<M, D>] = self.context.filter { _ in true }
        return viewModels.map { $0.content.message }
    }

    public override var contentConfig: ContentConfig? {
        let threadStyleConfig = ThreadStyleConfig(addBorderBySelf: true)
        if message.parentMessage != nil || !message.reactions.isEmpty {
            return ContentConfig(hasMargin: true, maskToBounds: true,
                                 supportMutiSelect: true, threadStyleConfig: threadStyleConfig)
        }
        var contentConfig = ContentConfig(hasMargin: false, maskToBounds: true,
                                          supportMutiSelect: true, hasBorder: true,
                                          threadStyleConfig: threadStyleConfig)
        contentConfig.borderStyle = .image
        return contentConfig
    }
}

/// 话题转发卡片 & 消息链接化卡片
final class MessageLinkImageContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ImageContentContext>: ImageContentViewModel<M, D, C> {
    override var imageTrackScene: Scene {
        return .Chat
    }

    override var allMessages: [Message] {
        return [self.message]
    }

    override var canViewInChat: Bool {
        return false
    }

    override var showAddToSticker: Bool {
        return false
    }

    override var shouldAddBorder: Bool {
        return true
    }

    override var contentConfig: ContentConfig? {
        let threadStyleConfig = ThreadStyleConfig(addBorderBySelf: true)
        var contentConfig = ContentConfig(hasMargin: false, maskToBounds: false,
                                          supportMutiSelect: false, hasBorder: false,
                                          threadStyleConfig: threadStyleConfig)
        contentConfig.borderStyle = .image
        return contentConfig
    }

    override var imageMaxSize: CGSize {
        // 卡片场景一定会有padding，需要减去得到内容展示的最大宽度
        let contentPadding = MessageLinkEngineConfig.getContentPadding(message: message, defaultContentPadding: self.metaModelDependency.contentPadding)
        let maxContentWidth = self.metaModelDependency.getContentPreferMaxWidth(message) - contentPadding * 2
        // 计算出实际能展示的最大宽度限制
        let validMaxWidth = min(BaseImageView.Cons.imageMaxDisplaySize.width, maxContentWidth)
        return CGSize(width: validMaxWidth, height: BaseImageView.Cons.imageMaxDisplaySize.height)
    }
}

final class ThreadChatImageContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ImageContentContext>: ImageContentViewModel<M, D, C> {
    override var imageTrackScene: Scene {
        return .Thread
    }

    override var shouldAddBorder: Bool {
        return false
    }

    override var showAddToSticker: Bool {
        return true
    }
}

final class ThreadDetailImageContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ImageContentContext>: ImageContentViewModel<M, D, C> {
    override var imageTrackScene: Scene {
        return .Thread
    }

    override var allMessages: [Message] {
        let viewModels: [ThreadDetailMessageCellViewModel<M, D>] = self.context.filter { _ in true }
        return viewModels.map { $0.content.message }
    }

    override var shouldAddBorder: Bool {
        return false
    }

    override var showAddToSticker: Bool {
        return !metaModel.getChat().enableRestricted(.download)
    }
}

final class MergeForwardDetailImageContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ImageContentContext>: ImageContentViewModel<M, D, C> {
    override var imageTrackScene: Scene {
        return .Chat
    }

    override var allMessages: [Message] {
        let viewModels: [MergeForwardMessageCellViewModel<M, D>] = self.context.filter { _ in true }
        return viewModels.map { $0.content.message }
    }

    public override var contentConfig: ContentConfig? {
        let threadStyleConfig = ThreadStyleConfig(addBorderBySelf: true)
        if message.parentMessage != nil || !message.reactions.isEmpty {
            return ContentConfig(hasMargin: true, maskToBounds: true,
                                 supportMutiSelect: true, threadStyleConfig: threadStyleConfig)
        }
        var contentConfig = ContentConfig(hasMargin: false, maskToBounds: true,
                                          supportMutiSelect: true, hasBorder: true,
                                          threadStyleConfig: threadStyleConfig)
        contentConfig.borderStyle = .image
        return contentConfig
    }
}

final class MessageDetailImageContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ImageContentContext>: ImageContentViewModel<M, D, C> {
    override var imageTrackScene: Scene {
        return .Detail
    }

    override var allMessages: [Message] {
        let viewModels: [MessageDetailMessageCellViewModel<M, D>] = self.context.filter { _ in true }
        return viewModels.map { $0.content.message }
    }

    override var shouldAddBorder: Bool {
        return true
    }
}

final class PinImageContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ImageContentContext>: ImageContentViewModel<M, D, C> {
    override var imageTrackScene: Scene {
        return .Pin
    }

    override var allMessages: [Message] {
        let viewModels: [PinMessageCellViewModel<M, D>] = self.context.filter { _ in true }
        return viewModels.map { $0.content.message }
    }

    override var shouldAddBorder: Bool {
        return true
    }

    override var showAddToSticker: Bool {
        return !metaModel.getChat().enableRestricted(.download)
    }
}
