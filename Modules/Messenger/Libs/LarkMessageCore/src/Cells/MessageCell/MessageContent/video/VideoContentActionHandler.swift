//
//  VideoContentActionHandler.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/2/1.
//

import UIKit
import Foundation
import RxSwift
import LarkCore
import LarkUIKit
import LarkModel
import LarkContainer
import LarkMessageBase
import LarkSDKInterface
import LKCommonsTracker
import LKCommonsLogging
import UniverseDesignToast
import LarkAlertController
import LarkMessengerInterface

private typealias Path = LarkSDKInterface.PathWrapper

private let logger = Logger.log(NSObject(), category: "LarkMessageCore.cell.VideoContentActionHandler")

class VideoContentActionHandler<C: VideoContentContext>: ComponentActionHandler<C> {
    lazy var fileAPI: SecurityFileAPI? = {
        return try? self.context.resolver.resolve(assert: SecurityFileAPI.self)
    }()
    lazy var messageAPI: MessageAPI? = {
        return try? self.context.resolver.resolve(assert: MessageAPI.self)
    }()
    lazy var fileDependency: DriveSDKFileDependency? = {
        return try? self.context.resolver.resolve(assert: DriveSDKFileDependency.self)
    }()
    private let disposeBag = DisposeBag()

    // swiftlint:disable function_parameter_count
    public func videoTapped(
        _ view: VideoImageViewWrapper,
        permissionPreview: (Bool, ValidateResult?),
        dynamicAuthorityEnum: DynamicAuthorityEnum,
        status: VideoViewStatus,
        allMessages: [Message],
        chat: Chat,
        message: Message,
        content: MediaContent?,
        updateStatus: @escaping (VideoViewStatus) -> Void,
        canViewInChat: Bool,
        showSaveToCloud: Bool
    ) {
        if !(permissionPreview.0 && dynamicAuthorityEnum.authorityAllowed) {
            context.handlerPermissionPreviewOrReceiveError(receiveAuthResult: dynamicAuthorityEnum,
                                                           previewAuthResult: permissionPreview.1,
                                                           resourceType: .video)
            return
        }
        guard let content = content else { return }
        switch status {
        /// 发送成功，点击预览
        case .normal:
            if content.isPCOriginVideo {
                self.previewOriginVideo(view, message: message, showSaveToCloud: showSaveToCloud)
            } else {
                self.previewVideo(
                    view,
                    allMessages: allMessages,
                    chat: chat,
                    message: message,
                    content: content,
                    canViewInChat: canViewInChat,
                    showSaveToCloud: showSaveToCloud
                )
            }
        /// 发送失败/用户取消
        case .pause:
            // 本地文件存在，点击预览
            if checkFileExist(at: content.originPath) {
                self.previewVideo(
                    view,
                    allMessages: allMessages,
                    chat: chat,
                    message: message,
                    content: content,
                    canViewInChat: canViewInChat,
                    showSaveToCloud: showSaveToCloud
                )
            } else {
                // 提示无效内容
                self.showInvalid()
            }
        /// 文件被撤回
        case .fileRecalled:
            if let window = self.context.targetVC?.view.window {
                UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_Legacy_VideoMessagePreviewInvalid, on: window)
            }
        /// 被管理员临时删除后可能会恢复
        case .fileRecoverable:
            // 需要调用getFileState主动获取push，保证下次的状态是最新的
            self.fileAPI?.getFileStateRequest(messageId: message.id,
                                              sourceType: message.sourceType,
                                              sourceID: message.sourceID,
                                              authToken: content.authToken,
                                              downloadFileScene: context.downloadFileScene)
                .subscribe().disposed(by: self.disposeBag)
            if let window = self.context.targetVC?.view.window {
                UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_ChatFileStorage_ChatFileNotFoundDialogWithin90Days, on: window)
            }
        /// 被永久删除
        case .fileUnrecoverable:
            if let window = self.context.targetVC?.view.window {
                UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_ChatFileStorage_ChatFileNotFoundDialogOver90Days, on: window)
            }
        /// 正在转码/上传，取消转码
        case .uploading:
            self.context.cancelUpload(message).observeOn(MainScheduler.instance).subscribe(onNext: {
                updateStatus(.pause)
            }).disposed(by: self.disposeBag)
        /// 不处理
        case .notWork:
            break
        case .fileFreedup:
            if let window = self.context.targetVC?.view.window {
                UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_ViewOrDownloadFile_FileDeleted_Text, on: window)
            }
        }
    }
    // swiftlint:enable function_parameter_count

    func previewOriginVideo(_ view: VideoImageViewWrapper, message: Message, showSaveToCloud: Bool) {
        logger.info("open SDKPreview origin video")
        guard let targetVC = self.context.targetVC else {
            assertionFailure()
            return
        }
        var startTime = CACurrentMediaTime()
        let fileBrowseScene: FileSourceScene = (self.context.scene == .mergeForwardDetail || self.context.scene == .threadPostForwardDetail) ? .mergeForward : .chat
        var supportForward = true
        if case .mergeForward = fileBrowseScene { supportForward = false }

        var extra: [String: Any] = [:]
        var isTodoScene = false
        if let downloadFileScene = context.downloadFileScene {
            extra[FileBrowseFromWhere.DownloadFileSceneKey] = downloadFileScene
            isTodoScene = downloadFileScene == .todo
        }

        var goToFileBrowser = { [weak self, weak targetVC] (message: Message) in
            guard let self = self,
                let targetVC = targetVC else {
                return
            }
            self.fileDependency?.openSDKPreview(
                message: message,
                chat: nil,
                fileInfo: nil,
                from: targetVC,
                supportForward: supportForward,
                canSaveToDrive: showSaveToCloud,
                browseFromWhere: .file(extra: extra)
            )
            Tracker.post(TeaEvent("original_video_click_event_dev", params: [
                "result": 1,
                "cost_time": (CACurrentMediaTime() - startTime) * 1000
            ]))
        }

        if isTodoScene, message.channel.id.isEmpty {
            // TODO 场景需要重新获取一遍 message
            self.messageAPI?.fetchMessage(id: message.id).subscribe(onNext: { message in
                logger.info("fetch video message in todo scene success")
                let fileMessage = message.transformToFileMessageIfNeeded()
                goToFileBrowser(fileMessage)
            }, onError: { error in
                logger.error("fetch video message in todo scene failed \(error)")
            })
        } else {
            let fileMessage = message.transformToFileMessageIfNeeded()
            goToFileBrowser(fileMessage)
        }
    }

    func previewVideo(
        _ view: VideoImageViewWrapper,
        allMessages: [Message],
        chat: Chat,
        message: Message,
        content: MediaContent,
        canViewInChat: Bool,
        showSaveToCloud: Bool
    ) {
        assertionFailure("Must override")
    }

    private func checkFileExist(at path: String) -> Bool {
        guard !path.isEmpty else { return false }
        guard let fixedPath = VideoCacheConfig.replaceHomeDirectory(forPath: path) else {
            return false
        }
        return Path(fixedPath).exists
    }

    private func showInvalid() {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_Legacy_Hint)
        alertController.setContent(text: BundleI18n.LarkMessageCore.Lark_Legacy_VideoMessagePreviewInvalid)
        alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Legacy_LarkConfirm)
        context.navigator(type: .present, controller: alertController, params: nil)
    }
}

final class ChatVideoContentActionHandler<C: VideoContentContext>: VideoContentActionHandler<C> {
    override func previewVideo(
        _ view: VideoImageViewWrapper,
        allMessages: [Message],
        chat: Chat,
        message: Message,
        content: MediaContent,
        canViewInChat: Bool,
        showSaveToCloud: Bool
    ) {
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
        guard !result.assets.isEmpty, let index = result.selectIndex else { return }
        IMTracker.Chat.Main.Click.Msg.Media(chat, message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        result.assets[index].visibleThumbnail = view.previewView
        let extensionButtonType: LKAssetBrowserViewController.ButtonType
        if message.type == .media {
            let isMe: (_ id: String) -> Bool = context.isMe
            extensionButtonType = .stack(
                config: .init(getAllAlbumsBlock: { [weak context] in
                    if let context = context {
                        return context.getChatAlbumDataSourceImpl(chat: chat, isMeSend: isMe)
                    }
                    return DefaultAlbumDataSourceImpl()
                })
            )
        } else {
            extensionButtonType = .onlySave
        }
        let context = self.context
        let messageId = message.id
        let body = PreviewImagesBody(
            assets: result.assets.map { $0.transform() },
            pageIndex: index,
            scene: .chat(
                chatId: message.channel.id,
                chatType: chat.type,
                assetPositionMap: result.assetPositionMap
            ),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: chat.shouldDetectFile,
            canSaveImage: !chat.enableRestricted(.download),
            canShareImage: !chat.enableRestricted(.forward),
            canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
            showSaveToCloud: showSaveToCloud,
            canTranslate: false,
            canViewInChat: canViewInChat,
            translateEntityContext: (nil, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            },
            buttonType: extensionButtonType
        )
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}

final class ThreadChatVideoContentActionHandler<C: VideoContentContext>: VideoContentActionHandler<C> {
    override func previewVideo(
        _ view: VideoImageViewWrapper,
        allMessages: [Message],
        chat: Chat,
        message: Message,
        content: MediaContent,
        canViewInChat: Bool,
        showSaveToCloud: Bool
    ) {
        let result = LKDisplayAsset.createAssetExceptForSticker(
            messages: [message],
            isMeSend: context.isMe,
            checkPreviewPermission: { [weak self] message in
                return self?.context.checkPreviewAndReceiveAuthority(chat: chat, message: message) ?? .allow
            }
        )
        guard !result.assets.isEmpty, let index = result.selectIndex else { return }
        IMTracker.Chat.Main.Click.Msg.Media(chat, message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        result.assets[index].visibleThumbnail = view.previewView
        let context = self.context
        let messageId = message.id
        let body = PreviewImagesBody(
            assets: result.assets.map { $0.transform() },
            pageIndex: index,
            scene: .normal(assetPositionMap: result.assetPositionMap, chatId: chat.id),
            trackInfo: PreviewImageTrackInfo(messageID: message.id),
            shouldDetectFile: chat.shouldDetectFile,
            showSaveToCloud: false,
            canTranslate: false,
            canViewInChat: canViewInChat,
            translateEntityContext: (message.id, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            }
        )
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}

final class ThreadDetailVideoContentActionHandler<C: VideoContentContext>: VideoContentActionHandler<C> {
    override func previewVideo(
        _ view: VideoImageViewWrapper,
        allMessages: [Message],
        chat: Chat,
        message: Message,
        content: MediaContent,
        canViewInChat: Bool,
        showSaveToCloud: Bool
    ) {
        let result = LKDisplayAsset.createAssetExceptForSticker(
            messages: allMessages,
            selectedKey: content.key,
            isMeSend: context.isMe,
            checkPreviewPermission: { [weak self] message in
                return self?.context.checkPreviewAndReceiveAuthority(chat: chat, message: message) ?? .allow
            },
            chat: chat
        )
        guard !result.assets.isEmpty, let index = result.selectIndex else { return }

        ChannelTracker.TopicDetail.Click.Msg.Media(chat, message)
        result.assets[index].visibleThumbnail = view.previewView
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
            showSaveToCloud: showSaveToCloud,
            canTranslate: false,
            canViewInChat: canViewInChat,
            translateEntityContext: (message.id, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            }
        )
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}

final class MergeForwardDetailVideoContentActionHandler<C: VideoContentContext>: VideoContentActionHandler<C> {
    override func previewVideo(
        _ view: VideoImageViewWrapper,
        allMessages: [Message],
        chat: Chat,
        message: Message,
        content: MediaContent,
        canViewInChat: Bool,
        showSaveToCloud: Bool
    ) {
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
        guard !result.assets.isEmpty, let index = result.selectIndex else { return }

        result.assets[index].visibleThumbnail = view.previewView
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
            showSaveToCloud: showSaveToCloud,
            canTranslate: false,
            canViewInChat: canViewInChat,
            translateEntityContext: (message.id, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            }
        )
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}

final class MessageDetailVideoContentActionHandler<C: VideoContentContext>: VideoContentActionHandler<C> {
    override func previewVideo(
        _ view: VideoImageViewWrapper,
        allMessages: [Message],
        chat: Chat,
        message: Message,
        content: MediaContent,
        canViewInChat: Bool,
        showSaveToCloud: Bool
    ) {
        let result = LKDisplayAsset.createAssetExceptForSticker(
            messages: allMessages,
            selected: message.id,
            cid: message.cid,
            isMeSend: context.isMe,
            checkPreviewPermission: { [weak self] message in
                return self?.context.checkPreviewAndReceiveAuthority(chat: chat, message: message) ?? .allow
            },
            chat: chat
        )
        guard !result.assets.isEmpty, let index = result.selectIndex else { return }

        result.assets[index].visibleThumbnail = view.previewView
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
            showSaveToCloud: showSaveToCloud,
            canTranslate: false,
            canViewInChat: canViewInChat,
            translateEntityContext: (message.id, .message),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            }
        )
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}

final class PinVideoContentActionHandler<C: VideoContentContext>: VideoContentActionHandler<C> {
    override func previewVideo(
        _ view: VideoImageViewWrapper,
        allMessages: [Message],
        chat: Chat,
        message: Message,
        content: MediaContent,
        canViewInChat: Bool,
        showSaveToCloud: Bool
    ) {
        let result = LKDisplayAsset.createAssetExceptForSticker(
            messages: allMessages,
            selected: message.id,
            cid: message.cid,
            isMeSend: context.isMe,
            checkPreviewPermission: { [weak self] message in
                return self?.context.checkPreviewAndReceiveAuthority(chat: chat, message: message) ?? .allow
            },
            chat: chat
        )
        guard !result.assets.isEmpty, let index = result.selectIndex else { return }

        result.assets[index].visibleThumbnail = view.previewView
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
            showSaveToCloud: showSaveToCloud,
            canTranslate: false,
            canViewInChat: canViewInChat,
            translateEntityContext: (nil, .other),
            canImageOCR: !chat.isCrypto && !chat.enableRestricted(.copy) && !chat.enableRestricted(.forward),
            dismissCallback: {
                logger.info("chatTrace detect Asset dismissCallback \(chat.id) \(messageId)")
                context.viewDidDisplay()
            }
        )
        context.navigator(type: .present, body: body, params: nil)
        context.viewWillEndDisplay()
    }
}
