//
//  IMCryptoChatKeyboardPicturePanelSubModule.swift
//  LarkChat
//
//  Created by liluobin on 2023/4/6.
//

import UIKit
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import LarkBaseKeyboard
import LarkMessageCore
import LarkAssetsBrowser
import LarkCore
import LarkOpenIM
import LarkModel
import ByteWebImage
import LarkFeatureGating
import LarkContainer
import LarkSDKInterface
import LKCommonsTracker
import Photos
import LarkSendMessage
import LarkStorage
import LarkKeyboardView
import LarkMessengerInterface
import LarkChatKeyboardInterface

public class IMCryptoChatKeyboardPicturePanelSubModule: KeyboardPanelPictureSubModule<KeyboardContext,
                                                 IMKeyboardMetaModel>, ChatKeyboardViewPageItemProtocol {

    var chatFromWhere: ChatFromWhere? {
        return chatPageItem?.chatFromWhere
    }

    //发资源类消息管理类
    lazy var assetManager: AssetPreProcessManager = {
        return AssetPreProcessManager(userResolver: userResolver, isCrypto: true)
    }()

    private lazy var IsCompressCameraPhotoFG: Bool = userResolver.fg.staticFeatureGatingValue(with: "feature_key_camera_photo_compress")

    var messageSender: KeyboardPictureItemSendService? {
        return try? self.context.userResolver.resolve(type: KeyboardPictureItemSendService.self)
    }

    var chatKeyPointTracker: KeyboardSendMessageKeyPointTrackerService? {
        return try? self.context.userResolver.resolve(type: KeyboardSendMessageKeyPointTrackerService.self)
    }

    var getReplyInfo: (() -> KeyboardJob.ReplyInfo?)? {
        return chatPageItem?.getReplyInfo
    }

    var afterSendMessage: (() -> Void)? {
        return chatPageItem?.afterSendMessage
    }

    @ScopedInjectedLazy var sendImageProcessor: SendImageProcessor?
    @ScopedInjectedLazy private var secretChatService: SecretChatService?
    @ScopedInjectedLazy var mediaDiskUtil: MediaDiskUtil?

    public override func handler(model: IMKeyboardMetaModel) -> [Module<KeyboardContext, IMKeyboardMetaModel>] {
        self.metaModel = model
        return super.handler(model: model)
    }

    public override func getPanelConfig() -> (UIColor?, LarkKeyboard.PictureKeyboardConfig)? {
        let config = LarkKeyboard.PictureKeyboardConfig(
            type: PhotoPickerAssetType.imageAndVideoWithTotalCount(totalCount: 9),
            delegate: self,
            selectedBlock: { [weak self] () -> Bool in
                LarkMessageCoreTracker.trackClickKeyboardInputItem(KeyboardItemKey.picture)
                if let chat = self?.metaModel?.chat {
                    IMTracker.Chat.Main.Click.ImageSelect(chat, isFulllScreen: false, nil, self?.chatFromWhere)
                }
                return true
            },
            photoViewCallback: { _ in },
            originVideo: true,
            sendButtonTitle: BundleI18n.LarkChat.Lark_Legacy_Send,
            isOriginalButtonHidden: false
        )
        return (secretChatService?.keyboardItemsTintColor, config)
    }

    public override func assetPickerSuite(_ clickType: AssetPickerSuiteClickType) {
        LarkMessageCoreTracker.trackAssetPickerSuiteClickType(clickType)
    }

    public override func assetPickerSuite(_ clickType: AssetPickerPreviewClickType) {
        LarkMessageCoreTracker.trackAssetPickerPreviewClickType(clickType)
    }

    public override func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakePhoto photo: UIImage) {
        // 检测图片是否拥有足够的磁盘空间用于发送，不足时弹出提示
        guard let mediaDiskUtil, mediaDiskUtil.checkImageSendEnable(image: photo, on: context.displayVC.view) else {
            return
        }
        LarkMessageCoreTracker.trackTakePhoto()
        foldKeyboard()
        let parentMessage = self.getReplyInfo?()?.message

        let indentify = chatKeyPointTracker?.generateIndentify() ?? ""
        chatKeyPointTracker?.startImageProcess(indentify: indentify, imageFrom: .takePhoto)
        chatKeyPointTracker?.startOriginImageProcess(indentify: indentify)
        let result: ImageProcessResult?
        if IsCompressCameraPhotoFG {
            result = sendImageProcessor?.process(source: .image(photo), option: LarkImageService.shared.imageUploadWebP ? [.needConvertToWebp] : [], scene: .Chat)
        } else {
            result = sendImageProcessor?.process(source: .image(photo), option: [.useOrigin], scene: .Chat)
        }
        chatKeyPointTracker?.endOriginImageProcess(indentify: indentify)
        let tracker = self.chatKeyPointTracker
        let imageSourceFunc: ImageSourceFunc = {
            tracker?.endImageProcess(indentify: indentify)
            return ImageSourceResult(imageProcessResult: result)
        }
        let imageInfo = ImageMessageInfo(
            originalImageSize: CGSize(width: photo.size.width * photo.scale, height: photo.size.height * photo.scale),
            sendImageSource: SendImageSource(cover: imageSourceFunc, origin: imageSourceFunc),
            isFromCrypto: true
        )
        guard let chat = self.metaModel?.chat else {
            return
        }

        self.messageSender?.sendImages(
            parentMessage: parentMessage,
            useOriginal: false,
            imageMessageInfos: [imageInfo],
            chatId: chat.id,
            lastMessagePosition: chat.lastMessagePosition,
            quasiMsgCreateByNative: false,
            extraTrackerContext: [ChatKeyPointTracker.selectAssetsCount: 1,
                                  ChatKeyPointTracker.chooseAssetSource: ChatKeyPointTracker.ChooseAssetSource.camera.rawValue],
            stateHandler: nil
        )
        self.afterSendMessage?()
    }

    public override func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakeVideo url: URL) {
        // 检测视频是否拥有足够的磁盘空间用于发送，不足时弹出提示
        guard let mediaDiskUtil, mediaDiskUtil.checkVideoSendEnable(videoURL: url, on: context.displayVC.view) else {
            return
        }
        let vc = self.context.displayVC
        guard let chat = self.metaModel?.chat else { return }
        let message = self.getReplyInfo?()?.message
        self.messageSender?.sendVideo(
            with: .fileURL(url),
            isCrypto: true,
            forceFile: true,
            isOriginal: false,
            chatId: chat.id,
            parentMessage: message,
            lastMessagePosition: chat.lastMessagePosition,
            quasiMsgCreateByNative: false,
            preProcessManager: nil,
            from: vc,
            extraTrackerContext: [ChatKeyPointTracker.selectAssetsCount: 1,
                                  ChatKeyPointTracker.chooseAssetSource: ChatKeyPointTracker.ChooseAssetSource.camera.rawValue])
        self.afterSendMessage?()
    }

    public override func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didFinishSelect result: AssetPickerSuiteSelectResult) {
        // 检测视频、图片是否拥有足够的磁盘空间用于发送，不足时弹出提示
        guard let mediaDiskUtil, mediaDiskUtil.checkMediaSendEnable(assets: result.selectedAssets, on: self.context.displayVC.view) else {
            return
        }
        self.pickedAssets(result.selectedAssets, useOriginal: result.isOriginal, imageCache: suiteView.imageCache)
    }

    public func pickedAssets(_ assets: [PHAsset], useOriginal: Bool, imageCache: LarkAssetsBrowser.ImageCache) {
        guard !assets.isEmpty else {
            return
        }
        foldKeyboard()
        func sendItems(with parentMessage: LarkModel.Message?) {
            let videoAssets = assets.filter { (asset) -> Bool in
                return asset.mediaType == .video
            }
            let imageAssets = assets.filter { (asset) -> Bool in
                return asset.mediaType == .image
            }
            if !imageAssets.isEmpty {
                // 发图调用多选发图方法，内部保证时序
                self.sendImageWithAssets(imageAssets, isOriginal: useOriginal, parentMessage: parentMessage,
                                         imageCache: imageCache, selectAssetsCount: imageAssets.count + videoAssets.count)
            }
            if !videoAssets.isEmpty {
                videoAssets.forEach { [weak self] (asset) in
                    guard let self = self, let chat = self.metaModel?.chat else {
                        assertionFailure("miss chat")
                        return
                    }
                    let vc = self.context.displayVC
                    // 这一步是为了将事件传递出去，保证消息页面调到底部行为正常
                    self.messageSender?.sendVideo(
                        with: .asset(asset),
                        isCrypto: true,
                        forceFile: true,
                        isOriginal: useOriginal,
                        chatId: chat.id,
                        parentMessage: parentMessage,
                        lastMessagePosition: chat.lastMessagePosition,
                        quasiMsgCreateByNative: false,
                        preProcessManager: nil,
                        from: vc,
                        extraTrackerContext: [ChatKeyPointTracker.selectAssetsCount: videoAssets.count + imageAssets.count,
                                              ChatKeyPointTracker.chooseAssetSource: ChatKeyPointTracker.ChooseAssetSource.album.rawValue])
                }
            }
        }
        let message = self.getReplyInfo?()?.message
        sendItems(with: message)
        self.afterSendMessage?()
    }

    public func sendImageWithAssets(_ assets: [PHAsset], isOriginal: Bool, parentMessage: LarkModel.Message? = nil, imageCache: LarkAssetsBrowser.ImageCache, selectAssetsCount: Int) {
        guard let sendImageProcessor else { return }
        let imageMessageInfos = assets.compactMap { (asset) in
            return self.getImageMessageInfo(asset: asset, isOriginal: isOriginal, imageCache: imageCache, sendImageProcessor: sendImageProcessor)
        }
        guard let chat = self.metaModel?.chat else { return }
        self.messageSender?.sendImages(
            parentMessage: parentMessage,
            useOriginal: isOriginal,
            imageMessageInfos: imageMessageInfos,
            chatId: chat.id,
            lastMessagePosition: chat.lastMessagePosition,
            quasiMsgCreateByNative: false,
            extraTrackerContext: [ChatKeyPointTracker.selectAssetsCount: selectAssetsCount,
                                  ChatKeyPointTracker.chooseAssetSource: ChatKeyPointTracker.ChooseAssetSource.album.rawValue],
            stateHandler: nil
        )
    }

    private func getImageMessageInfo(asset: PHAsset, isOriginal: Bool, imageCache: LarkAssetsBrowser.ImageCache, sendImageProcessor: SendImageProcessor) -> ImageMessageInfo {
        let image = imageCache.imageForAsset(asset)
        let name = assetManager.getDefaultKeyFrom(phAsset: asset)
        /// 通过asset获取URL
        func getURL(_ block: @escaping (URL?) -> Void) {
            if let editImage = asset.editImage {
                guard let data = editImage.pngData() else {
                    block(nil)
                    return
                }
                let dir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "tempEditImage" + name
                try? dir.createDirectoryIfNeeded()
                let fileName = asset.assetResource?.originalFilename ?? name
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
        let indentify = chatKeyPointTracker?.generateIndentify() ?? ""
        chatKeyPointTracker?.startImageProcess(indentify: indentify, imageFrom: .photoLibrary)
        chatKeyPointTracker?.startThumbImageProcess(indentify: indentify)
        var coverImageFunc: ImageSourceFunc?
        //如果资源在预处理后进行了编辑，取消预处理
        var hasEditImage: Bool = (asset.editImage != nil)
        var preprocessResourceKey: String?
        var sendImage: ImageSourceResult?
        let imageName = assetManager.getDefaultKeyFrom(phAsset: asset)
        let preProcessKey = assetManager.combineImageKeyWithIsOriginal(imageKey: imageName, isOriginal: isOriginal)

        if let image = image {
            let result = sendImageProcessor.process(source: .image(image), option: LarkImageService.shared.imageUploadWebP ? [.needConvertToWebp] : [], scene: .Chat)
            coverImageFunc = {
                return ImageSourceResult(imageProcessResult: result)
            }
        }
        chatKeyPointTracker?.endThumbImageProcess(indentify: indentify)
        let imageFormatOption: ImageProcessOptions = isOriginal ? [.useOrigin] : (LarkImageService.shared.imageUploadWebP ? [.needConvertToWebp] : [])
        let originalImageSize: CGSize
        if let editImage = asset.editImage {
            originalImageSize = CGSize(width: editImage.size.width * editImage.scale, height: editImage.size.height * editImage.scale)
        } else {
            originalImageSize = asset.originSize
        }
        let tracker = self.chatKeyPointTracker
        let imageMessageInfo = ImageMessageInfo(
            originalImageSize: originalImageSize,
            sendImageSource: SendImageSource(cover: coverImageFunc, origin: { () -> ImageSourceResult in
                //如果资源已经被处理，并且非编辑后的图片，用处理后的
                if let image = sendImage, !hasEditImage {
                    return image
                } else {
                    var dependency = ImageInfoDependency(
                        useOrigin: isOriginal,
                        sendImageProcessor: sendImageProcessor) { status in
                        switch status {
                        case .beforeRequest:
                            tracker?.startImageRequest(indentify: indentify)
                        case .finishRequest:
                            tracker?.endImageRequest(indentify: indentify)
                        case .beforeImageProcess:
                            tracker?.startOriginImageProcess(indentify: indentify)
                        case .finishImageProcess:
                            tracker?.endOriginImageProcess(indentify: indentify)
                        }
                    }
                    dependency.isConvertWebp = LarkImageService.shared.imageUploadWebP

                    let imageSourceResult: ImageSourceResult = asset.imageInfo(dependency)
                    tracker?.endImageProcess(indentify: indentify)
                    return imageSourceResult
                }
            }),
            imageSize: asset.editImage == nil ? asset.size : nil,
            imageType: ImageUploadChecker.getFinalImageType(imageType: asset.imageType, formatOptions: imageFormatOption),
            sourceImageType: asset.imageType,
            preprocessResourceKey: preprocessResourceKey,
            isFromCrypto: true,
            imagePathProvider: getURL
        )
        return imageMessageInfo
    }
}
