//
//  ThreadKeyboardPictureSubModule.swift
//  LarkThread
//
//  Created by liluobin on 2023/4/11.
//

import UIKit
import LarkBaseKeyboard
import LarkChatOpenKeyboard
import LarkOpenKeyboard
import LarkKeyboardView
import LarkAssetsBrowser
import LarkMessageCore
import LarkCore
import LarkSetting
import Photos
import LarkModel
import ByteWebImage
import LarkContainer
import LarkSDKInterface
import LarkMessengerInterface
import LarkFeatureGating
import LarkSendMessage
import LarkStorage

public class NormalThreadKeyboardPictureSubModule: BaseThreadKeyboardPictureSubModule {

    @ScopedInjectedLazy var dependency: ThreadDependency?

    override func sendImages(parentMessage: Message?, useOriginal: Bool, imageMessageInfos: [ImageMessageInfo], chatId: String) {
        guard let parentMessage = parentMessage,
              !chatId.isEmpty,
              let threadId = self.threadPageItem?.thread.id else {
            assertionFailure("error data")
            return
        }
        guard let sendMessageAPI, let isSupportURLType = dependency?.isSupportURLType(url:) else { return }

        ThreadTracker.trackSendMessage(
            parentMessage: parentMessage,
            type: .image,
            chatId: self.metaModel?.chat.id ?? "",
            isSupportURLType: isSupportURLType,
            chat: self.metaModel?.chat)

        sendMessageAPI.sendImages(contexts: nil,
                                       parentMessage: parentMessage,
                                       useOriginal: useOriginal,
                                       imageMessageInfos: imageMessageInfos,
                                       chatId: chatId,
                                       threadId: threadId,
                                       stateHandler: nil)
    }

    override func sendVideo(with content: SendVideoContent, isCrypto: Bool, chatId: String, parentMessage: Message?) {
        guard let parentMessage = parentMessage,
              !chatId.isEmpty,
              let chat = self.metaModel?.chat,
              let thread = self.threadPageItem?.thread else {
            assertionFailure("error data")
            return
        }
        guard let videoMessageSendService, let isSupportURLType = dependency?.isSupportURLType(url:) else { return }
        ThreadTracker.trackSendMessage(
            parentMessage: parentMessage,
            type: .media,
            chatId: chatId,
            isSupportURLType: isSupportURLType,
            chat: self.metaModel?.chat)

        let params = SendVideoParams(content: content,
                                     isCrypto: isCrypto,
                                     isOriginal: false,
                                     forceFile: false,
                                     chatId: chatId,
                                     threadId: thread.id,
                                     parentMessage: parentMessage,
                                     from: self.context.displayVC)
        // 真正的发送逻辑处理部分
        videoMessageSendService.sendVideo(with: params,
                                               extraParam: ["quasiMsgCreateByNative":
                                                                thread.anonymousID.isEmpty,
                                                            "lastMessagePosition": thread.lastMessagePosition,
                                                            APIContext.chatDisplayModeKey:
                                                                chat.displayMode],
                                               context: nil,
                                               sendMessageTracker: nil,
                                               stateHandler: nil)
    }

}

public class MessageThreadKeyboardPictureSubModule: BaseThreadKeyboardPictureSubModule {

    override func sendImages(parentMessage: Message?, useOriginal: Bool, imageMessageInfos: [ImageMessageInfo], chatId: String) {
        guard let sendMessageAPI else { return }
        guard let parentMessage = parentMessage,
              !chatId.isEmpty,
              let threadId = self.threadPageItem?.thread.id else {
            assertionFailure("error data")
            return
        }

        sendMessageAPI.sendImages(contexts: imageMessageInfos.map({ _ in self.defaultSendContext() }),
                                       parentMessage: parentMessage,
                                       useOriginal: useOriginal,
                                       imageMessageInfos: imageMessageInfos,
                                       chatId: chatId,
                                       threadId: threadId) { [weak self] idx, status in
            if idx == 0, case .finishSendMessage(_, _, _, _, _) = status, let chat = self?.metaModel?.chat {
                ThreadTracker.trackReplyThreadClick(chat: chat,
                                                    message: parentMessage,
                                                    clickType: .reply,
                                                    threadId: !parentMessage.threadId.isEmpty ? parentMessage.threadId : parentMessage.id,
                                                    inGroup: true)
            }
        }

    }

    override func sendVideo(with content: SendVideoContent, isCrypto: Bool, chatId: String, parentMessage: Message?) {
        guard let videoMessageSendService else { return }
        guard let parentMessage = parentMessage,
              !chatId.isEmpty,
              let chat = self.metaModel?.chat,
              let thread = self.threadPageItem?.thread else {
            assertionFailure("error data")
            return
        }

        let params = SendVideoParams(content: content,
                                     isCrypto: isCrypto,
                                     isOriginal: false,
                                     forceFile: false,
                                     chatId: chatId,
                                     threadId: thread.id,
                                     parentMessage: parentMessage,
                                     from: self.context.displayVC)
        // 真正的发送逻辑处理部分
        videoMessageSendService.sendVideo(with: params,
                                               extraParam: ["quasiMsgCreateByNative": thread.anonymousID.isEmpty, "lastMessagePosition": replyInThreadMessagePosition,
                                                   APIContext.chatDisplayModeKey: chat.displayMode,
                                                   APIContext.replyInThreadKey: true],
                                               context: nil,
                                               sendMessageTracker: nil) { state in
            if case .finishSendMessage(_, _, _, _, _) = state {
                ThreadTracker.trackReplyThreadClick(chat: chat,
                                                    message: parentMessage,
                                                    clickType: .reply,
                                                    threadId: !parentMessage.threadId.isEmpty ? parentMessage.threadId : parentMessage.id,
                                                    inGroup: true)
            }
        }
    }
}

open class BaseThreadKeyboardPictureSubModule: KeyboardPanelPictureSubModule<KeyboardContext, IMKeyboardMetaModel>, ThreadKeyboardViewPageItemProtocol {

    @ScopedInjectedLazy var sendMessageAPI: SendMessageAPI?
    @ScopedInjectedLazy var videoMessageSendService: VideoMessageSendService?
    @ScopedInjectedLazy var sendImageProcessor: SendImageProcessor?
    @ScopedProvider var mediaDiskUtil: MediaDiskUtil?

    open override func getPanelConfig() -> (UIColor?, LarkKeyboard.PictureKeyboardConfig)? {
        guard let chat = self.metaModel?.chat else { return nil }
        let config = LarkKeyboard.PictureKeyboardConfig(
            type: PhotoPickerAssetType.default,
            delegate: self,
            selectedBlock: { [weak self] () -> Bool in
                LarkMessageCoreTracker.trackClickKeyboardInputItem(KeyboardItemKey.picture)
                IMTracker.Chat.Main.Click.ImageSelect(chat,
                                                      isFulllScreen: false,
                                                      self?.threadPageItem?.thread.id,
                                                      nil)
                return true
            },
            photoViewCallback: { _ in },
            originVideo: true,
            sendButtonTitle: BundleI18n.LarkThread.Lark_Legacy_Send,
            isOriginalButtonHidden: false
        )

        return (ThreadKeyboardPageItem.iconColor, config)
    }

    public override func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didFinishSelect result: AssetPickerSuiteSelectResult) {
        // 检测视频、图片是否拥有足够的磁盘空间用于发送，不足时弹出提示
        guard let mediaDiskUtil, mediaDiskUtil.checkMediaSendEnable(assets: result.selectedAssets,
                                                 on: self.context.displayVC.view) else {
            return
        }
        pickedAssets(result.selectedAssets, useOriginal: result.isOriginal)
    }

    public override func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakeVideo url: URL) {
        guard let mediaDiskUtil, mediaDiskUtil.checkVideoSendEnable(videoURL: url, on: self.context.displayVC.view) else {
            return
        }
        self.sendVideo(with: .fileURL(url),
                                 isCrypto: self.metaModel?.chat.isCrypto == true,
                                 chatId: self.metaModel?.chat.id ?? "",
                                 parentMessage: self.threadPageItem?.getReplyMessage?())
    }

    public override func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakePhoto photo: UIImage) {
        guard let sendImageProcessor else { return }
        guard let mediaDiskUtil, mediaDiskUtil.checkImageSendEnable(image: photo,
                                                 on: self.context.displayVC.view) else {
            return
        }
        self.foldKeyboard()
        let parentMessage: LarkModel.Message? = self.threadPageItem?.getReplyMessage?()
        var IsCompressCameraPhotoFG: Bool = context.getFeatureGating(.init(stringLiteral: "feature_key_camera_photo_compress"))
        let result = sendImageProcessor.process(
            source: .image(photo),
            option: !IsCompressCameraPhotoFG ? [.useOrigin] : LarkImageService.shared.imageUploadWebP ? [.needConvertToWebp] : [],
            scene: .Thread)
        let imageSource = {
            return ImageSourceResult(imageProcessResult: result)
        }
        let imageMessageInfo = ImageMessageInfo(originalImageSize: result?.image.size ?? .zero, sendImageSource: SendImageSource(cover: imageSource, origin: imageSource))
        self.sendImages(
            parentMessage: parentMessage,
            useOriginal: false,
            imageMessageInfos: [imageMessageInfo],
            chatId: self.metaModel?.chat.id ?? ""
        )
    }

    public override func assetPickerSuite(_ clickType: AssetPickerSuiteClickType) {
        LarkMessageCoreTracker.trackAssetPickerSuiteClickType(clickType)
    }

    public func pickedAssets(_ assets: [PHAsset], useOriginal: Bool) {
        guard !assets.isEmpty else {
            return
        }
        self.foldKeyboard()
        func sendItems(with parentMessage: LarkModel.Message?) {
            let videoAssets = assets.filter { (asset) -> Bool in
                asset.mediaType == .video
            }
            let imageAssets = assets.filter { (asset) -> Bool in
                asset.mediaType == .image
            }
            if !imageAssets.isEmpty {
                // 发图调用多选发图方法，内部保证时序
                sendImageWithAssets(assets, isOriginal: useOriginal, parentMessage: parentMessage)
            }
            if !videoAssets.isEmpty {
                videoAssets.forEach { asset in
                    // 这一步是为了将事件传递出去，保证消息页面调到底部行为正常
                    self.sendVideo(with: .asset(asset),
                                   isCrypto: self.metaModel?.chat.isCrypto ?? false,
                                   chatId: (self.metaModel?.chat.id) ?? "",
                                   parentMessage: parentMessage)
                }
            }
        }
        sendItems(with: self.threadPageItem?.getReplyMessage?())
    }

    public func sendImageWithAssets(_ assets: [PHAsset], isOriginal: Bool, parentMessage: LarkModel.Message? = nil) {
        guard let sendImageProcessor = self.sendImageProcessor else { return }
        var dependency = ImageInfoDependency(useOrigin: isOriginal, sendImageProcessor: sendImageProcessor)
        dependency.isConvertWebp = LarkImageService.shared.imageUploadWebP
        let imageMessageInfos = assets.map { (asset) -> ImageMessageInfo in
            /// 通过asset获取URL
            /// 添加imagePath，图片在转文件时，会判断imagePathProvider是否为nil
            func imagePath(_ block: @escaping (URL?) -> Void) {
                if let editImage = asset.editImage {
                    guard let data = editImage.pngData() else {
                        block(nil)
                        return
                    }
                    let dir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "tempEditImage"
                    try? dir.createDirectoryIfNeeded()
                    let fileName = asset.assetResource?.originalFilename ?? ("image_" + UUID().uuidString + ".PNG")
                    let path = dir + fileName
                    try? path.removeItem()
                    do {
                        try data.write(to: path)
                        block(path.url)
                    } catch {
                        block(nil)
                    }
                } else {
                    let opt = PHContentEditingInputRequestOptions()
                    opt.canHandleAdjustmentData = { (_) in
                        return false
                    }
                    asset.requestContentEditingInput(with: opt) { (input, _) in
                        if input?.fullSizeImageURL == nil {
                            block(nil)
                            return
                        }
                        block(input?.fullSizeImageURL)
                    }
                }
            }

            let imageSource = { asset.imageInfo(dependency) }
            let imageFormatOption: ImageProcessOptions = isOriginal ? [.useOrigin] : []
            let imageMessageInfo = ImageMessageInfo(
                originalImageSize: asset.originSize,
                sendImageSource: SendImageSource(cover: imageSource, origin: imageSource),
                imageSize: asset.size,
                imageType: ImageUploadChecker.getFinalImageType(imageType: asset.imageType, formatOptions: imageFormatOption),
                sourceImageType: asset.imageType,
                imagePathProvider: imagePath
            )
            return imageMessageInfo
        }
        sendImages(parentMessage: parentMessage,
                                  useOriginal: isOriginal,
                                  imageMessageInfos: imageMessageInfos,
                                  chatId: self.metaModel?.chat.id ?? "")
    }

    func sendImages(parentMessage: Message?, useOriginal: Bool, imageMessageInfos: [ImageMessageInfo], chatId: String) {
    }

    func sendVideo(with content: SendVideoContent, isCrypto: Bool, chatId: String, parentMessage: Message?) {
    }
}
