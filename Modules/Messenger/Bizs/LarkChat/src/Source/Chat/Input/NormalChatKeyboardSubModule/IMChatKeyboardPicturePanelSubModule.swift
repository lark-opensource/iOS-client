//
//  IMChatKeyboardPicturePanelSubModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/4/6.
//

import UIKit
import LarkBaseKeyboard
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import LarkCore
import LarkAssetsBrowser
import LarkSendMessage
import LarkModel
import Photos
import LarkMessageCore
import LarkOpenIM
import LarkSDKInterface
import ByteWebImage
import LarkFeatureGating
import LKCommonsTracker
import LarkStorage
import LarkContainer
import LKCommonsLogging
import LarkKeyboardView
import LarkMessengerInterface
import LarkChatKeyboardInterface

public class IMChatKeyboardPicturePanelSubModule: KeyboardPanelPictureSubModule<KeyboardContext,
                                                  IMKeyboardMetaModel>, ChatKeyboardViewPageItemProtocol,
                                                  ProcessImageDelegate {
    static let logger = Logger.log(IMChatKeyboardPicturePanelSubModule.self, category: "Module.Inputs")

    lazy var IsCompressCameraPhotoFG: Bool = userResolver.fg.staticFeatureGatingValue(with: "feature_key_camera_photo_compress")
    lazy var newResourcePreprocessFG: Bool = userResolver.fg.dynamicFeatureGatingValue(with: "messenger.resource.preprocess")

    lazy var assetManager: AssetPreProcessManager = {
        return AssetPreProcessManager(userResolver: userResolver, isCrypto: false)
    }()

    lazy var resourceManager: ResourcePreProcessManager = {
        return ResourcePreProcessManager(userResolver: userResolver, scene: .chat)
    }()

    lazy var processImage: ProcessImage = {
        return ProcessImage(delegate: self)
    }()

    @ScopedInjectedLazy var sendImageProcessor: SendImageProcessor?
    @ScopedInjectedLazy var mediaDiskUtil: MediaDiskUtil?

    private var itemConfig: ChatKeyboardPictureItemConfig? {
        return try? context.userResolver.resolve(assert: ChatOpenKeyboardItemConfigService.self).getChatKeyboardItemFor(self.panelItemKey)
    }

    private var chatKeyPointTracker: KeyboardSendMessageKeyPointTrackerService? {
        return try? self.context.userResolver.resolve(type: KeyboardSendMessageKeyPointTrackerService.self)
    }

    private var messageSender: KeyboardPictureItemSendService? {
        return itemConfig?.sendConfig?.sendService
    }

    private lazy var videoMessageSendService: VideoMessageSendService? = {
        return try? self.context.userResolver.resolve(assert: VideoMessageSendService.self)
    }()

    private var chatFromWhere: ChatFromWhere? {
        return chatPageItem?.chatFromWhere
    }

    private var getReplyInfo: (() -> KeyboardJob.ReplyInfo?)? {
        return chatPageItem?.getReplyInfo
    }

    private var afterSendMessage: (() -> Void)? {
        return chatPageItem?.afterSendMessage
    }

    public override func handler(model: IMKeyboardMetaModel) -> [Module<KeyboardContext, IMKeyboardMetaModel>] {
        metaModel = model
        return [self]
    }

    public override func modelDidChange(model: IMKeyboardMetaModel) {
        metaModel = model
        super.modelDidChange(model: model)
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
                self?.itemConfig?.uiConfig?.tappedBlock?()
                return true
            },
            photoViewCallback: { [weak self] (_) -> Void in
                self?.pictureKeyboard?.photoPickerReloadBlock = { [weak self] (result) in
                    self?.videoMessageSendService?.checkPreprocessVideoIfNeeded(result: result, preProcessManager: self?.resourceManager)
                }
            },
            originVideo: true,
            sendButtonTitle: BundleI18n.LarkChat.Lark_Legacy_Send,
            isOriginalButtonHidden: false
        )
        return (UIColor.ud.iconN2, config)
    }

    public override func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didFinishSelect result: AssetPickerSuiteSelectResult) {
        // 检测视频、图片是否拥有足够的磁盘空间用于发送，不足时弹出提示
        guard let mediaDiskUtil, mediaDiskUtil.checkMediaSendEnable(assets: result.selectedAssets, on: context.displayVC.view) else {
            return
        }
        self.pickedAssets(result.selectedAssets, useOriginal: result.isOriginal, imageCache: suiteView.imageCache)
    }

    public override func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didChangeSelection result: AssetPickerSuiteSelectResult) {
        if newResourcePreprocessFG {
            typealias RPM = ResourcePreProcessManager
            var resources: [(resource: RPM.ResourceType, name: RPM.NameSuffix, options: RPM.Options)] = []
            result.selectedAssets.forEach { asset in
                if asset.mediaType == .video {
                    Self.logger.info("pre process video \(asset) isOriginal \(result.isOriginal)")
                    self.videoMessageSendService?.preprocessVideo(with: .asset(asset), isOriginal: result.isOriginal, scene: .selectVideo, preProcessManager: resourceManager)
                } else if asset.mediaType == .image {
                    guard case .success = ImageUploadChecker.getAssetCheckResult(
                        asset: asset,
                        formatOptions: result.isOriginal ? [.useOrigin] : (LarkImageService.shared.imageUploadWebP ? [.needConvertToWebp] : [])) else { return }
                    resources.append((resource: .imageAsset(asset), name: .image(result.isOriginal), options: [.preprocessing(pro: processImage), .preSwiftTransmission]))
                    if let coverImage = suiteView.imageCache.imageForAsset(asset) {
                        resources.append((.image(coverImage, asset), .cover, [.preprocessing(pro: processImage)]))
                    }
                }
            }
            resourceManager.onResourcesChanged(resources)
            return
        }
        let checkPreProcessEnable = assetManager.checkPreProcessEnable
        result.selectedAssets.forEach { asset in
            // 预处理视频
            if asset.mediaType == .video {
                Self.logger.info("pre process video \(asset) isOriginal \(result.isOriginal)")
                self.videoMessageSendService?.preprocessVideo(with: .asset(asset), isOriginal: result.isOriginal, scene: .selectVideo, preProcessManager: nil)
            } else if checkPreProcessEnable,
                      asset.mediaType == .image,
                      assetManager.checkEnableByType(fileType: .image),
                      case .success(()) = ImageUploadChecker.getAssetCheckResult(
                        asset: asset, formatOptions: result.isOriginal ? [.useOrigin] : (LarkImageService.shared.imageUploadWebP ? [.needConvertToWebp] : [])) {
                let originAssetName = assetManager.getDefaultKeyFrom(phAsset: asset)
                // 判断内存是否足够
                let memoryIsEnough: Bool = assetManager.checkMemoryIsEnough()
                guard memoryIsEnough else {
                    Self.logger.info("pre process image surpassLimit: \(memoryIsEnough)")
                    return
                }
                // 区分是否原图
                let assetName = assetManager.combineImageKeyWithIsOriginal(imageKey: originAssetName, isOriginal: result.isOriginal)
                // 判断资源是否已经处理过
                guard !assetManager.checkAssetHasOperation(assetName: assetName) else { return }
                let assetOperation = BlockOperation { [weak self] in
                    guard let self = self else { return }
                    //图片预转码
                    guard let imageSourceResult: ImageSourceResult = self.genSendImageMessageInfo(asset: asset, isOriginal: result.isOriginal) else { return }
                    self.assetManager.addToFinishAssets(name: assetName, value: imageSourceResult)
                    //秒传预处理
                    self.assetManager.preProcessResource(filePath: nil, data: imageSourceResult.data, fileType: .image,
                                                          assetName: assetName, imageSourceResult: imageSourceResult)
                    //封面预转码
                    guard self.assetManager.checkPreprocessCoverEnable else { return }
                    let coverName = self.assetManager.combineImageKeyWithCover(imageKey: originAssetName)
                    guard let coverImage = suiteView.imageCache.imageForAsset(asset),
                          !self.assetManager.checkAssetHasOperation(assetName: coverName) else { return }
                    self.assetManager.addToPendingAssets(name: coverName, value: asset)
                    let coverSource = self.genCoverImageMessageInfo(cover: coverImage)
                    self.assetManager.addToFinishAssets(name: coverName, value: coverSource)
                }
                //添加到队列中
                assetManager.addAssetProcessOperation(assetOperation)
                self.assetManager.addToPendingAssets(name: assetName, value: asset)
            }
        }
    }

    public override func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didPreview asset: PHAsset) {
        if asset.mediaType == .video {
            self.videoMessageSendService?.preprocessVideo(with: .asset(asset), isOriginal: false, scene: .previewVideo, preProcessManager: resourceManager)
        }
    }

    public func pickedAssets(_ assets: [PHAsset], useOriginal: Bool, imageCache: LarkAssetsBrowser.ImageCache) {
        guard !assets.isEmpty else {
            return
        }
        if newResourcePreprocessFG {
            // 发送前调用
            self.resourceManager.onSendStart()
        } else {
            //取消预处理任务
            self.assetManager.cancelAllOperation()
        }
        /// 收起键盘
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
                        return
                    }
                    let vc = context.displayVC
                    // 这一步是为了将事件传递出去，保证消息页面调到底部行为正常
                    // 从这里取秒传 key

                    self.messageSender?.sendVideo(
                        with: .asset(asset),
                        isCrypto: false,
                        forceFile: chat.isPrivateMode,
                        isOriginal: useOriginal,
                        chatId: chat.id,
                        parentMessage: parentMessage,
                        lastMessagePosition: chat.lastMessagePosition,
                        quasiMsgCreateByNative: chat.anonymousId.isEmpty && !chat.isP2PAi,
                        preProcessManager: resourceManager,
                        from: vc,
                        extraTrackerContext: [ChatKeyPointTracker.selectAssetsCount: imageAssets.count + videoAssets.count,
                                              ChatKeyPointTracker.chooseAssetSource: ChatKeyPointTracker.ChooseAssetSource.album.rawValue])
                }
            }
        }
        let messageModel = self.getReplyInfo?()?.message
        sendItems(with: messageModel)
        self.afterSendMessage?()
        if newResourcePreprocessFG {
            // 发送后调用
            self.resourceManager.onSendFinish(preprocessCount: assets.filter { $0.mediaType == .image }.count)
        } else {
            //预处理后
            self.assetManager.afterPreProcess(assets: assets)
        }
    }

    public func sendImageWithAssets(_ assets: [PHAsset], isOriginal: Bool, parentMessage: LarkModel.Message? = nil, imageCache: LarkAssetsBrowser.ImageCache, selectAssetsCount: Int) {
        self.assetManager.cancelAllOperation()
        let imageMessageInfos = assets.map { (asset) -> ImageMessageInfo in
            if newResourcePreprocessFG {
                return self.newGetImageMessageInfo(asset: asset, isOriginal: isOriginal, imageCache: imageCache)
            } else {
                return self.getImageMessageInfo(asset: asset, isOriginal: isOriginal, imageCache: imageCache)
            }
        }
        guard let chat = metaModel?.chat else { return }
        self.messageSender?.sendImages(
            parentMessage: parentMessage,
            useOriginal: isOriginal,
            imageMessageInfos: imageMessageInfos,
            chatId: chat.id,
            lastMessagePosition: chat.lastMessagePosition,
            quasiMsgCreateByNative: chat.anonymousId.isEmpty && !chat.isP2PAi,
            extraTrackerContext: [ChatKeyPointTracker.selectAssetsCount: selectAssetsCount,
                                  ChatKeyPointTracker.chooseAssetSource: ChatKeyPointTracker.ChooseAssetSource.album.rawValue],
            stateHandler: nil
        )
    }

    func newGetImageMessageInfo(asset: PHAsset, isOriginal: Bool, imageCache: LarkAssetsBrowser.ImageCache) -> ImageMessageInfo {
        let originalImageSize: CGSize
        let coverImageFunc: ImageSourceFunc
        let imageFunc: ImageSourceFunc
        var imageSize: Int64?
        let usePreprocessedResource: Bool
        var preprocessResourceKey: String?
        let getURL: ((@escaping (URL?) -> Void) -> Void)
        if let editImage = asset.editImage {
            originalImageSize = CGSize(width: editImage.size.width * editImage.scale, height: editImage.size.height * editImage.scale)
            coverImageFunc = { [weak self] in
                guard let self, let image = imageCache.imageForAsset(asset), let result = self.genCoverImageMessageInfo(cover: image)
                else { return ImageSourceResult(sourceType: .unknown, data: nil, image: nil) }
                return result
            }
            imageFunc = { [weak self] in
                guard let self, let result = self.genSendImageMessageInfo(asset: asset, isOriginal: isOriginal) else { return ImageSourceResult(sourceType: .unknown, data: nil, image: nil) }
                return result
            }
            imageSize = nil
            usePreprocessedResource = false
            preprocessResourceKey = nil
            getURL = { block in
                guard let data = editImage.pngData() else {
                    block(nil)
                    return
                }
                let name = ResourcePreProcessManager.getDefaultKeyFrom(phAsset: asset)
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
            }
        } else {
            originalImageSize = asset.originSize
            let coverResult = resourceManager.getImageResult(type: .imageAsset(asset), name: .cover)
            coverImageFunc = { [weak self] in
                if let result = coverResult {
                    return result
                }
                guard let self, let image = imageCache.imageForAsset(asset), let result = self.genCoverImageMessageInfo(cover: image)
                else { return ImageSourceResult(sourceType: .unknown, data: nil, image: nil) }
                return result
            }
            let result = resourceManager.getImageResult(type: .imageAsset(asset), name: .image(isOriginal))
            usePreprocessedResource = result != nil
            imageFunc = { [weak self] in
                if let result { return result }
                guard let self, let result = self.genSendImageMessageInfo(asset: asset, isOriginal: isOriginal) else { return ImageSourceResult(sourceType: .unknown, data: nil, image: nil) }
                return result
            }
            imageSize = asset.size
            preprocessResourceKey = resourceManager.getSwiftKey(type: .imageAsset(asset), name: .image(isOriginal))
            getURL = { block in
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
        let imageFormatOption: ImageProcessOptions = isOriginal ? [.useOrigin] : (LarkImageService.shared.imageUploadWebP ? [.needConvertToWebp] : [])
        let imageMessageInfo = ImageMessageInfo(
            originalImageSize: originalImageSize,
            sendImageSource: SendImageSource(cover: coverImageFunc, origin: imageFunc),
            imageSize: imageSize,
            imageType: ImageUploadChecker.getFinalImageType(imageType: asset.imageType, formatOptions: imageFormatOption),
            sourceImageType: asset.imageType,
            isPreprocessed: usePreprocessedResource,
            preprocessResourceKey: preprocessResourceKey,
            imagePathProvider: getURL
        )
        return imageMessageInfo
    }

    private func getImageMessageInfo(asset: PHAsset, isOriginal: Bool, imageCache: LarkAssetsBrowser.ImageCache) -> ImageMessageInfo {
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
        var coverImageFunc: ImageSourceFunc?
        //如果资源在预处理后进行了编辑，取消预处理
        let hasEditImage: Bool = (asset.editImage != nil)
        var preprocessResourceKey: String?
        var sendImage: ImageSourceResult?
        let imageName = assetManager.getDefaultKeyFrom(phAsset: asset)
        let preProcessKey = assetManager.combineImageKeyWithIsOriginal(imageKey: imageName, isOriginal: isOriginal)
        if hasEditImage {
            self.assetManager.cancelPreprocessResource(assetName: name)
        } else {
            preprocessResourceKey = self.assetManager.getPreprocessResourceKey(assetName: preProcessKey)
            sendImage = self.assetManager.getImageSourceResult(assetName: preProcessKey)
        }
        let usePreprocessedResource = sendImage != nil && !hasEditImage

        let sendImageProcessor = self.sendImageProcessor
        // cover
        if let image = image {
            let imageName = self.assetManager.getDefaultKeyFrom(phAsset: asset)
            let coverPreprocessKey = self.assetManager.combineImageKeyWithCover(imageKey: imageName)
            let coverResource = self.assetManager.getImageSourceResult(assetName: coverPreprocessKey)
            coverImageFunc = { [weak self] in
                guard let self = self else { return ImageSourceResult(sourceType: .unknown, data: nil, image: nil) }
                // 先尝试有没有预处理封面图
                if !hasEditImage, let coverResource = coverResource {
                    return coverResource
                } else {
                    return self.genCoverImageMessageInfo(cover: image) ?? ImageSourceResult(sourceType: .unknown, data: nil, image: nil)
                }
            }
        }
        let imageFormatOption: ImageProcessOptions = isOriginal ? [.useOrigin] : (LarkImageService.shared.imageUploadWebP ? [.needConvertToWebp] : [])

        let originalImageSize: CGSize
        if let editImage = asset.editImage {
            originalImageSize = CGSize(width: editImage.size.width * editImage.scale, height: editImage.size.height * editImage.scale)
        } else {
            originalImageSize = asset.originSize
        }
        let imageMessageInfo = ImageMessageInfo(
            originalImageSize: originalImageSize,
            sendImageSource: SendImageSource(cover: coverImageFunc, origin: {[weak self] () -> ImageSourceResult in
                guard let self = self else { return ImageSourceResult(sourceType: .unknown, data: nil, image: nil) }
                //如果资源已经被处理，并且非编辑后的图片，用处理后的
                if let image = sendImage, usePreprocessedResource {
                    return image
                } else {
                    return self.genSendImageMessageInfo(asset: asset, isOriginal: isOriginal) ?? .init(sourceType: .unknown, data: nil, image: nil)
                }
            }),
            imageSize: asset.editImage == nil ? asset.size : nil,
            imageType: ImageUploadChecker.getFinalImageType(imageType: asset.imageType, formatOptions: imageFormatOption),
            sourceImageType: asset.imageType,
            isPreprocessed: usePreprocessedResource,
            preprocessResourceKey: preprocessResourceKey,
            imagePathProvider: getURL
        )
        return imageMessageInfo
    }

    //获取发送图片信息
    func genSendImageMessageInfo(asset: PHAsset, isOriginal: Bool) -> ImageSourceResult? {
        guard let sendImageProcessor = self.sendImageProcessor else { return nil }
        let indentify = chatKeyPointTracker?.generateIndentify() ?? ""
        var dependecy = ImageInfoDependency(
            useOrigin: isOriginal,
            sendImageProcessor: sendImageProcessor) { [weak self] status in
            switch status {
            case .beforeRequest:
                self?.chatKeyPointTracker?.startImageRequest(indentify: indentify)
            case .finishRequest:
                self?.chatKeyPointTracker?.endImageRequest(indentify: indentify)
            case .beforeImageProcess:
                self?.chatKeyPointTracker?.startOriginImageProcess(indentify: indentify)
            case .finishImageProcess:
                self?.chatKeyPointTracker?.endOriginImageProcess(indentify: indentify)
            @unknown default: break
            }
        }
        dependecy.isConvertWebp = LarkImageService.shared.imageUploadWebP
        let imageSourceResult: ImageSourceResult = asset.imageInfo(dependecy)
        chatKeyPointTracker?.endImageProcess(indentify: indentify)
        return imageSourceResult
    }

    /// 生成 cover 对应的 ImageSourceResult
    func genCoverImageMessageInfo(cover: UIImage) -> ImageSourceResult? {
        guard let sendImageProcessor else { return nil }
        let indentify = chatKeyPointTracker?.generateIndentify() ?? ""
        chatKeyPointTracker?.startThumbImageProcess(indentify: indentify)
        let result = sendImageProcessor.process(
            source: .image(cover),
            option: LarkImageService.shared.imageUploadWebP ? [.needConvertToWebp] : [],
            scene: .Chat)
        chatKeyPointTracker?.endThumbImageProcess(indentify: indentify)
        return ImageSourceResult(imageProcessResult: result)
    }

    public override func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakePhoto photo: UIImage) {
        guard let mediaDiskUtil, mediaDiskUtil.checkImageSendEnable(image: photo, on: context.displayVC.view), let sendImageProcessor else {
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
            result = sendImageProcessor.process(source: .image(photo), option: LarkImageService.shared.imageUploadWebP ? [.needConvertToWebp] : [], scene: .Chat)
        } else {
            result = sendImageProcessor.process(source: .image(photo), option: [.useOrigin], scene: .Chat)
        }
        chatKeyPointTracker?.endOriginImageProcess(indentify: indentify)
        let tracker = self.chatKeyPointTracker
        let imageSourceFunc: ImageSourceFunc = {
            tracker?.endImageProcess(indentify: indentify)
            return ImageSourceResult(imageProcessResult: result)
        }
        let imageInfo = ImageMessageInfo(
            originalImageSize: CGSize(width: photo.size.width * photo.scale, height: photo.size.height * photo.scale),
            sendImageSource: SendImageSource(cover: imageSourceFunc, origin: imageSourceFunc)
        )

        guard let chat = self.metaModel?.chat else { return }
        self.messageSender?.sendImages(
            parentMessage: parentMessage,
            useOriginal: false,
            imageMessageInfos: [imageInfo],
            chatId: chat.id,
            lastMessagePosition: chat.lastMessagePosition,
            quasiMsgCreateByNative: chat.anonymousId.isEmpty && !chat.isP2PAi,
            extraTrackerContext: [ChatKeyPointTracker.selectAssetsCount: 1,
                                  ChatKeyPointTracker.chooseAssetSource: ChatKeyPointTracker.ChooseAssetSource.camera.rawValue],
            stateHandler: nil
        )
        self.afterSendMessage?()
    }

    public override func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakeVideo url: URL) {
        guard let mediaDiskUtil, mediaDiskUtil.checkVideoSendEnable(videoURL: url, on: context.displayVC.view) else {
            return
        }
        let parentMessage = self.getReplyInfo?()?.message
        guard let chat = self.metaModel?.chat else { return }
        let vc = context.displayVC
        self.messageSender?.sendVideo(
            with: .fileURL(url),
            isCrypto: false,
            forceFile: chat.isPrivateMode,
            isOriginal: false,
            chatId: chat.id,
            parentMessage: parentMessage,
            lastMessagePosition: chat.lastMessagePosition,
            quasiMsgCreateByNative: chat.anonymousId.isEmpty && !chat.isP2PAi,
            preProcessManager: nil,
            from: vc,
            extraTrackerContext: [ChatKeyPointTracker.selectAssetsCount: 1,
                                  ChatKeyPointTracker.chooseAssetSource: ChatKeyPointTracker.ChooseAssetSource.camera.rawValue])
        self.afterSendMessage?()
    }

    public override func assetPickerSuite(_ clickType: AssetPickerSuiteClickType) {
        LarkMessageCoreTracker.trackAssetPickerSuiteClickType(clickType)
    }

    public override func assetPickerSuite(_ clickType: AssetPickerPreviewClickType) {
        LarkMessageCoreTracker.trackAssetPickerPreviewClickType(clickType)
    }
}

protocol ProcessImageDelegate: AnyObject {
    func genSendImageMessageInfo(asset: PHAsset, isOriginal: Bool) -> ImageSourceResult?
    func genCoverImageMessageInfo(cover: UIImage) -> ImageSourceResult?
}
class ProcessImage: PreProcessProtocol {
    weak var delegate: ProcessImageDelegate?
    init(delegate: ProcessImageDelegate?) {
        self.delegate = delegate
    }
    func processImage(_ image: PHAsset, suffix: ResourcePreProcessManager.NameSuffix) -> ImageSourceResult? {
        guard case let .image(origin) = suffix else { return nil }
        return delegate?.genSendImageMessageInfo(asset: image, isOriginal: origin)
    }
    func processImage(_ image: UIImage, suffix: ResourcePreProcessManager.NameSuffix) -> ImageSourceResult? {
        return delegate?.genCoverImageMessageInfo(cover: image)
    }
}
