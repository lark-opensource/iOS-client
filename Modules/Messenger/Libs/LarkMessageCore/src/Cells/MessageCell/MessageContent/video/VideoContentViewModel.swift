//
//  VideoContentViewModel.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/5/30.
//

import Foundation
import LarkModel
import Swinject
import LarkMessageBase
import RxSwift
import RxCocoa
import EENavigator
import LarkUIKit
import LarkMessengerInterface
import UniverseDesignToast
import LarkSDKInterface
import ByteWebImage
import LarkSetting
import LarkContainer
import LarkAssetsBrowser
import LarkCore
import LKCommonsLogging
import LKCommonsTracker
import UIKit
import LarkAccountInterface
import RustPB

struct UploadAndCompressRation {
    static let upload: Double = 0.4
    static let compress: Double = 0.6
}

public struct VideoContentConfig {
    // 是否支持保存到云盘，同时受config和chat的权限管控
    public var showSaveToCloud: Bool

    public init(showSaveToCloud: Bool = true) {
        self.showSaveToCloud = showSaveToCloud
    }
}

private let logger = Logger.log(NSObject(), category: "LarkMessageCore.cell.VideoContentViewModel")

public class VideoContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: VideoContentContext>: NewAuthenticationMessageSubViewModel<M, D, C> {
    @PageContext.InjectedLazy private var passportUserService: PassportUserService?

    public lazy var fetchKeyWithCryptoFG: Bool = {
        return self.context.getStaticFeatureGating("messenger.image.resource_not_found")
    }()

    public override var identifier: String {
        return "video"
    }

    //为防止业务上在权限拒绝的情况下渲染图片/播放视频，所以当权限拒绝时从数据层把content改成了可选型。当权限变更时，会触发刷新UI
    var content: MediaContent? {
        guard self.dynamicAuthorityEnum.authorityAllowed else { return nil }
        return self._content
    }

    //业务不应直接拿这个值，应该拿鉴权后的content。仅一些无需鉴权的逻辑（如清理cache）允许直接取这个值
    private var _content: MediaContent {
        return (self.message.content as? MediaContent) ?? .transform(pb: RustPB.Basic_V1_Message())
    }

    public var allMessages: [Message] {
        return []
    }

    public var contentPreferMaxWidth: CGFloat {
        if (self.context.scene == .newChat || self.context.scene == .mergeForwardDetail), message.showInThreadModeStyle {
            return self.metaModelDependency.getContentPreferMaxWidth(self.message)
        }
        let hasMargin = self.contentConfig?.hasMargin ?? true
        return self.metaModelDependency.getContentPreferMaxWidth(self.message) - (hasMargin ? 2 * metaModelDependency.contentPadding : 0)
    }

    public var permissionPreview: (Bool, ValidateResult?) {
        context.checkPermissionPreview(chat: metaModel.getChat(), message: metaModel.message)
    }
    public var originSize: CGSize {
        guard let content = content else { return ChatNoPreviewPermissionLayerSizeConfig.normalSize }
        // origin 的数据可能不是不准确的，有intact优先用intact，并根据exifOrientation决定宽高
        return getPreviewSize(content.image.intactSize)
    }

    func getPreviewSize(_ size: CGSize) -> CGSize {
        return (permissionPreview.0 && dynamicAuthorityEnum.authorityAllowed) ? size : ChatNoPreviewPermissionLayerSizeConfig.normalSize
    }

    public var duration: Int32 {
        guard let content = content else { return 0 }
        return content.duration
    }

    public var previewImageInfo: (ImageItemSet, forceOrigin: Bool)? {
        guard self.dynamicAuthorityEnum.authorityAllowed else { return nil }
        return _previewImageInfo
    }

    //业务不应直接拿这个值，应该拿鉴权后的previewImageInfo。仅一些无需鉴权的逻辑（如清理cache）允许直接取这个值
    private var _previewImageInfo: (ImageItemSet, forceOrigin: Bool) {
        let imageSet = self._content.image
        if !imageSet.origin.key.isEmpty {
            return (ImageItemSet.transform(imageSet: imageSet), forceOrigin: false)
        } else {
            var imageItemSet = ImageItemSet()
            imageItemSet.origin = ImageItem(key: message.id)
            return (imageItemSet, forceOrigin: true)
        }
    }

    // 是否支持跳转至会话
    var canViewInChat: Bool {
        if let myAIPageService = try? self.context.userResolver.resolve(type: MyAIPageService.self), myAIPageService.chatMode { return false }
        return true
    }

    // 是否支持保存到云盘
    var showSaveToCloud: Bool {
        return !metaModel.getChat().enableRestricted(.download) && config.showSaveToCloud
    }

    public private(set) var status: VideoViewStatus = .normal

    public var uploadProgress: Double {
        return self.progressReplay.value
    }

    private let progressReplay: BehaviorRelay<Double> = BehaviorRelay(value: -1)

    public var shouldAddBorder: Bool {
        if (self.context.scene == .newChat || self.context.scene == .mergeForwardDetail), message.showInThreadModeStyle {
            return true
        }
        // 会话和转发页，单图不自己画边框，由 BubbleView 统一画
        return !([.newChat, .mergeForwardDetail].contains(self.context.scene) &&
                 message.parentId.isEmpty && message.reactions.isEmpty)
    }

    private let disposeBag = DisposeBag()
    private var progressBag = DisposeBag()
    private var isDisplay: Bool = false
    private let config: VideoContentConfig

    public init(
        metaModel: M,
        metaModelDependency: D,
        context: C,
        config: VideoContentConfig = VideoContentConfig()
    ) {
        self.config = config
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context)
    }

    public override func initialize() {
        super.initialize()
        self.status = self.getStatus()
        self.observeProgress()

        if message.localStatus == .success {
            return
        }
        guard let content = self.content else {
            //下面的逻辑都是上传进度相关。
            //按照预期，自己上传的文件 权限一定是allow，即self.content一定不为空
            return
        }

        // 获取视频上传进度
        self.context.progressValue(key: content.key)
            .subscribe(onNext: { [weak self] (progress) in
                let showProgress = UploadAndCompressRation.compress +
                    UploadAndCompressRation.upload * Double(progress.fractionCompleted)
                self?.progressReplay.accept(showProgress)
            })
            .disposed(by: self.disposeBag)
        // 获取视频转码进度
        self.context.getVideoCompressProgress(message)
            .subscribe(onNext: { [weak self] (progress) in
                self?.progressReplay.accept(UploadAndCompressRation.compress * progress)
            })
            .disposed(by: self.disposeBag)
    }

    public override func update(metaModel: M, metaModelDependency: D?) {
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        self.status = self.getStatus()
        self.binderAbility?.syncToBinder()
        self.binderAbility?.updateComponent(animation: .none)
    }

    public override var contentConfig: ContentConfig? {
        let threadStyleConfig = ThreadStyleConfig(addBorderBySelf: true)
        if message.parentMessage != nil || !message.reactions.isEmpty {
            var contentConfig = ContentConfig(hasMargin: true, maskToBounds: true,
                                              supportMutiSelect: true, hasBorder: true,
                                              threadStyleConfig: threadStyleConfig)
            contentConfig.borderStyle = .image
            return contentConfig
        }
        return ContentConfig(hasMargin: false, maskToBounds: true,
                             supportMutiSelect: true, threadStyleConfig: threadStyleConfig)
    }

    public override func willDisplay() {
        super.willDisplay()
        self.observeProgress()
        self.isDisplay = true
        self.messageDynamicAuthorityService?.performAfterAuthorityAllow(identify: "willDisplay") { [weak self] in
            if let self, let content = self.content {
                VideoPreloadManager.shared.preloadVideoIfNeeded(content,
                                                                currentAccessToken: self.passportUserService?.user.sessionKey,
                                                                userResolver: self.context.userResolver)
            }
        }
    }

    public override func didEndDisplay() {
        super.didEndDisplay()
        self.progressBag = DisposeBag()
        self.isDisplay = false
        if let content = content {
            VideoPreloadManager.shared.cancelPreloadVideoIfNeeded(content, currentAccessToken: self.passportUserService?.user.sessionKey)
        }
    }

    private func observeProgress() {
        if self.message.localStatus == .success {
            return
        }
        self.progressBag = DisposeBag()
        self.progressReplay.asObservable()
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.binderAbility?.syncToBinder()
                self.binderAbility?.updateComponent(animation: .none)
            })
            .disposed(by: self.progressBag)
    }

    func setStatus(status: VideoViewStatus) {
        self.status = status
    }

    private func getStatus() -> VideoViewStatus {
        switch message.fileDeletedStatus {
        case .normal:
            break
        case .recalled:
            return .fileRecalled
        case .recoverable:
            return .fileRecoverable
        case .unrecoverable:
            return .fileUnrecoverable
        case .freedUp:
            return .fileFreedup
        @unknown default:
            assertionFailure("unknown enum")
        }

        switch message.localStatus {
        case .success:
            return .normal
        case .process, .fakeSuccess:
            return .uploading
        case .fail:
            return .pause
        @unknown default:
            assert(false, "new value")
            return .normal
        }
    }

    deinit {
        guard !isDisplay else {
            return
        }
        let imageInfo = self._previewImageInfo //这里仅用于清理cache，无须取鉴权数据
        let resource = LarkImageResource.default(key: imageInfo.0.getThumbKey())
        LarkImageService.shared.removeCache(resource: resource, options: .memory)
    }
}

class ChatVideoContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: VideoContentContext>: VideoContentViewModel<M, D, C> {
    override var allMessages: [Message] {
        let viewModels: [ChatMessageCellViewModel<M, D>] = self.context.filter { _ in true }
        return viewModels.map { $0.content.message }
    }

    override var contentConfig: ContentConfig? {
        let threadStyleConfig = ThreadStyleConfig(addBorderBySelf: true)
        if message.parentMessage != nil || !message.reactions.isEmpty {
            return ContentConfig(hasMargin: true, maskToBounds: true, supportMutiSelect: true, threadStyleConfig: threadStyleConfig)
        }
        var contentConfig = ContentConfig(hasMargin: false, maskToBounds: true, supportMutiSelect: true, hasBorder: true, threadStyleConfig: threadStyleConfig)
        contentConfig.borderStyle = .image
        return contentConfig
    }
}

// 消息链接化卡片
final class MessageLinkVideoContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: VideoContentContext>: ChatVideoContentViewModel<M, D, C> {
    override var allMessages: [Message] {
        return [self.message]
    }

    override var canViewInChat: Bool {
        return false
    }

    override var shouldAddBorder: Bool {
        return true
    }

    override var contentConfig: ContentConfig? {
        let threadStyleConfig = ThreadStyleConfig(addBorderBySelf: true)
        var contentConfig = ContentConfig(hasMargin: false, maskToBounds: true,
                                          supportMutiSelect: false, hasBorder: false,
                                          threadStyleConfig: threadStyleConfig)
        contentConfig.borderStyle = .image
        return contentConfig
    }

    override var contentPreferMaxWidth: CGFloat {
        if message.showInThreadModeStyle {
            return self.metaModelDependency.getContentPreferMaxWidth(self.message)
        }
        let contentPadding = MessageLinkEngineConfig.getContentPadding(message: message, defaultContentPadding: self.metaModelDependency.contentPadding)
        return self.metaModelDependency.getContentPreferMaxWidth(self.message) - 2 * contentPadding
    }
}

final class ThreadChatVideoContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: VideoContentContext>: VideoContentViewModel<M, D, C> {
    override var shouldAddBorder: Bool {
        return false
    }

    override var showSaveToCloud: Bool {
        return false
    }
}

final class ThreadDetailVideoContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: VideoContentContext>: VideoContentViewModel<M, D, C> {
    override var shouldAddBorder: Bool {
        return false
    }

    override var allMessages: [Message] {
        let viewModels: [ThreadDetailMessageCellViewModel<M, D>] = context.filter { _ in true }
        return viewModels.map { $0.content.message }
    }
}

class MergeForwardDetailVideoContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: VideoContentContext>: VideoContentViewModel<M, D, C> {
    override var allMessages: [Message] {
        let viewModels: [MergeForwardMessageCellViewModel<M, D>] = context.filter { _ in true }
        return viewModels.map { $0.content.message }
    }

    public override var contentConfig: ContentConfig? {
        let threadStyleConfig = ThreadStyleConfig(addBorderBySelf: true)
        if message.parentMessage != nil || !message.reactions.isEmpty {
            return ContentConfig(hasMargin: true, maskToBounds: true, supportMutiSelect: true, threadStyleConfig: threadStyleConfig)
        }
        var contentConfig = ContentConfig(hasMargin: false, maskToBounds: true, supportMutiSelect: true, hasBorder: true, threadStyleConfig: threadStyleConfig)
        contentConfig.borderStyle = .image
        return contentConfig
    }
}

final class MessageDetailVideoContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: VideoContentContext>: VideoContentViewModel<M, D, C> {
    override var allMessages: [Message] {
        let viewModels: [MessageDetailMessageCellViewModel<M, D>] = self.context.filter {
            $0.content.message.content is ImageContent || $0.content.message.content is MediaContent
        }
        return viewModels.map { $0.content.message }
    }
}

final class PinVideoContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: VideoContentContext>: VideoContentViewModel<M, D, C> {
    override var allMessages: [Message] {
        let viewModels: [PinMessageCellViewModel<M, D>] = context.filter { _ in true }
        return viewModels.map { $0.content.message }
    }
}
