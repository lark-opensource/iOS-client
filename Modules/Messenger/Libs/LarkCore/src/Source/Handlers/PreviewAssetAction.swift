//
//  PreviewAssetAction.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2018/4/9.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkModel
import LarkUIKit
import LarkContainer
import AVFoundation
import EENavigator
import LarkMessengerInterface
import LarkFeatureGating
import LarkAssetsBrowser
import RustPB
import LKCommonsLogging
import RxSwift
import LarkSDKInterface
import LKCommonsTracker

public protocol HasAssets: AnyObject {
    var messages: [Message] { get }
    func getImageAssets(id: String, cid: String, downloadFileScene: RustPB.Media_V1_DownloadFileScene?) -> CreateAssetsResult
    func getImageAssets(id: String, key: String, downloadFileScene: RustPB.Media_V1_DownloadFileScene?) -> CreateAssetsResult
    func getStickerAssets(id: String, cid: String) -> CreateAssetsResult
    func isMeSend(_ id: String) -> Bool
    func checkPreviewPermission(message: Message) -> PermissionDisplayState
}

extension HasAssets {
    public func getImageAssets(id: String, cid: String, downloadFileScene: RustPB.Media_V1_DownloadFileScene?) -> CreateAssetsResult {
        return LKDisplayAsset.createAssetExceptForSticker(
            messages: processMessages(messageId: id),
            selected: id,
            cid: cid,
            downloadFileScene: downloadFileScene,
            isMeSend: isMeSend,
            checkPreviewPermission: checkPreviewPermission
        )
    }

    public func getImageAssets(id: String, key: String, downloadFileScene: RustPB.Media_V1_DownloadFileScene?) -> CreateAssetsResult {
        return LKDisplayAsset.createAssetExceptForSticker(
            messages: processMessages(messageId: id),
            selectedKey: key,
            downloadFileScene: downloadFileScene,
            isMeSend: isMeSend,
            checkPreviewPermission: checkPreviewPermission
        )
    }

    public func getStickerAssets(id: String, cid: String) -> CreateAssetsResult {
        var assets: [LKDisplayAsset] = []
        var selectIndex: Int?
        var assetPositionMap: [String: (position: Int32, id: String)] = [:]
        messages.filter { !$0.isDeleted && !$0.isRecalled }.forEach { (message) in
            guard let content = message.content as? StickerContent else { return }

            let asset = LKDisplayAsset()
            asset.key = content.key
            asset.originalImageKey = content.key
            asset.forceLoadOrigin = true
            asset.isAutoLoadOriginalImage = true
            asset.extraInfo = [ImageAssetExtraInfo: LKImageAssetSourceType.sticker(stickerSetID: content.stickerSetID)]
            assets.append(asset)
            assetPositionMap[asset.key] = (message.position, message.id)
            if selectIndex == nil, (message.id == id || message.cid == cid) {
                selectIndex = assets.count - 1
            }
        }
        return CreateAssetsResult(assets: assets, selectIndex: selectIndex, assetPositionMap: assetPositionMap)
    }

    private func processMessages(messageId: String) -> [Message] {
        let messagesSource = messages
        //目前该handler仅收藏、flag在时候，后续应废弃，统一对接到直接调用PreviewImagesBody @qujieye
        //只展示本消息内所有图片（1.行为与各端保持对齐 2.群防泄密需求，如果此处可跨群去查看图片，无法管控）
        let validMessages = messagesSource.filter { $0.id == messageId
            && !$0.isRecalled
            && !$0.isDeleted
            && !$0.isSecretChatDecryptedFailed
            && ($0.type == .image || $0.type == .media || $0.type == .post)
        }
        return validMessages
    }
}

public class PreviewAssetAction: RequestHandler<PreviewAssetActionMessage>, UserResolverWrapper {
    public let userResolver: UserResolver

    private static let logger = Logger.log(PreviewAssetAction.self, category: "IM.PreviewAssetAction")

    @ScopedInjectedLazy private var fileDependency: DriveSDKFileDependency?

    unowned let assetsProvider: HasAssets
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    private var disposeBag = DisposeBag()

    public init(userResolver: UserResolver, assetsProvider: HasAssets) {
        self.userResolver = userResolver
        self.assetsProvider = assetsProvider
    }

    override public func handle(_ message: PreviewAssetActionMessage) -> EmptyResponse? {
        if showOriginVideoUseFileBrowserIfNeeded(message: message) ||
            showStickerFromStickerSetIfNeeded(message: message) {
            return EmptyResponse()
        }
        guard let window = message.imageView?.window else {
            assertionFailure()
            return EmptyResponse()
        }

        let result: CreateAssetsResult
        let previewAssetActionMessage = message
        var messageID: String = ""
        var channelId: String = ""
        switch message.source {
        case .message(let message):
            messageID = message.id
            channelId = message.channel.id
            result = self.assetsProvider.getImageAssets(id: message.id, cid: message.cid, downloadFileScene: previewAssetActionMessage.downloadFileScene)
        case .post(selectKey: let key, let messageModel):
            channelId = messageModel.channel.id
            result = self.assetsProvider.getImageAssets(id: messageModel.id, key: key, downloadFileScene: message.downloadFileScene)
        case .sticker(let message):
            messageID = message.id
            channelId = message.channel.id
            result = self.assetsProvider.getStickerAssets(id: message.id, cid: message.cid)
        }
        guard !result.assets.isEmpty, let index = result.selectIndex, !channelId.isEmpty else {
            if channelId.isEmpty {
                Self.logger.error("handle previewAssetActionMessage channelId is empty \(messageID)")
            }
            return EmptyResponse()
        }
        result.assets[index].visibleThumbnail = message.imageView
        result.assets[index].isVideoMuted = message.isVideoMuted
        disposeBag = DisposeBag() //防止重复点击
        self.chatAPI?.fetchChat(by: channelId, forceRemote: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chat in
                guard let self = self else { return }
                if let chat = chat {
                    let body = PreviewImagesBody(
                        assets: result.assets.map({ (asset) -> Asset in
                            asset.transform()
                        }),
                        pageIndex: index,
                        scene: .normal(assetPositionMap: result.assetPositionMap, chatId: nil),
                        trackInfo: PreviewImageTrackInfo(messageID: messageID),
                        shouldDetectFile: chat.shouldDetectFile,
                        canSaveImage: !chat.enableRestricted(.download),
                        canShareImage: !chat.enableRestricted(.forward),
                        canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
                        showSaveToCloud: !chat.enableRestricted(.download),
                        canTranslate: self.userResolver.fg.staticFeatureGatingValue(with: .init(key: .imageViewerInOtherScenesTranslateEnable)),
                        translateEntityContext: (nil, .other),
                        canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
                        buttonType: .stack(config: .init(getAllAlbumsBlock: nil))
                    )
                    self.userResolver.navigator.present(body: body, from: window)
                } else {
                    Self.logger.error("handle previewAssetActionMessage fetchChat miss \(messageID) \(channelId)")
                }
            }, onError: { error in
                Self.logger.error("handle previewAssetActionMessage fetchChat fail \(messageID) \(channelId)", error: error)
            }).disposed(by: self.disposeBag)
        return EmptyResponse()
    }

    /// 展示表情包里面的表情
    public func showStickerFromStickerSetIfNeeded(message: PreviewAssetActionMessage) -> Bool {
        guard let window = message.imageView?.window else {
            assertionFailure()
            return false
        }

        switch message.source {
        case .sticker(let message):
            let stickerContent = message.content as? StickerContent
            if let sticker = stickerContent?.transformToSticker(), sticker.mode == .meme {
                let body = EmotionSingleDetailBody(
                    sticker: sticker,
                    stickerSet: nil,
                    stickerSetID: sticker.stickerSetID,
                    message: message)
                userResolver.navigator.push(body: body, from: window)
                return true
            }
        default:
            break
        }
        return false
    }

    /// 判断是否是原画视频
    func showOriginVideoUseFileBrowserIfNeeded(message: PreviewAssetActionMessage) -> Bool {
        guard let window = message.imageView?.window else {
            assertionFailure()
            return false
        }
        switch message.source {
        case .message(let msg):
            if let videoContent = msg.content as? MediaContent,
               videoContent.isPCOriginVideo {
                var startTime = CACurrentMediaTime()
                var supportForward = true
                var extra: [String: Any] = message.extra ?? [:]
                if let downloadFileScene = message.downloadFileScene {
                    extra[FileBrowseFromWhere.DownloadFileSceneKey] = downloadFileScene
                }
                let fileMessage = msg.transformToFileMessageIfNeeded()
                fileDependency?.openSDKPreview(
                    message: fileMessage,
                    chat: nil,
                    fileInfo: nil,
                    from: window,
                    supportForward: supportForward,
                    canSaveToDrive: true,
                    browseFromWhere: .file(extra: extra)
                )
                Tracker.post(TeaEvent("original_video_click_event_dev", params: [
                    "result": 1,
                    "cost_time": (CACurrentMediaTime() - startTime) * 1000
                ]))
                return true
            }
        default:
            break
        }
        return false
    }
}
