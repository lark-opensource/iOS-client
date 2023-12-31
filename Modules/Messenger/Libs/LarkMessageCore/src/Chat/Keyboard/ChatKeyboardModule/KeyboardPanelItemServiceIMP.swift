//
//  KeyboardPanelItemPictureServiceIMP.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/4/13.
//

import UIKit
import LarkBaseKeyboard
import LarkCore
import EENavigator
import Photos
import LarkContainer
import LarkSendMessage
import LarkMessengerInterface
import ByteWebImage
import LarkAttachmentUploader
import LarkAssetsBrowser
import LarkAlertController
import UniverseDesignToast
import LarkSetting
import LarkSDKInterface
import LKCommonsLogging
import RxSwift
import RustPB
import AppReciableSDK

struct AttachmentPostSendImageError: CustomUploadError {
    // 不能通过context获取到compress的结果
    static let getCompressResult = -45_900_006
    // 不能通过context获取到存储的attachmentMessage
    static let getAttachmentMessage = -45_900_007
    public var code: Int
}

// 存储attachment的相关信息
// 当业务方自己实现上传，而不用attachment，上传完成后需要调用finish从对应数组移除
// 移除时需要知道attachment的相关信息，attachmentKey，上传结果，上传的data，上传错误
public final class AttachmentMessage {
    public var key: String
    public var result: String?
    public var data: Data
    public var error: Error?
    public var compressResult: CompressResult // 用于上传埋点
    public init(key: String, result: String?, data: Data, error: Error?, compressResult: CompressResult) {
        self.key = key
        self.result = result
        self.data = data
        self.error = error
        self.compressResult = compressResult
    }
}

// attachment上传图片，包含post图片和moment图片上传
public class AttachmentTrackerImage: LarkSendImageUploader {
    static let logger = Logger.log(AttachmentTrackerImage.self, category: "attachment.upload.processor")
    public typealias AbstractType = [AttachmentMessage]
    public init() { }
    public func imageUpload(request: LarkSendImageAbstractRequest) -> Observable<AbstractType> {
        return Observable.create { [weak self] observer in
            guard let `self` = self,
                  let AttachmentMessageArray = request.getContext()["send.image.post.attachment.key"] as? [AttachmentMessage]
            else {
                observer.onError(LarkSendImageError(type: .upload, error: AttachmentPostSendImageError(code: AttachmentPostSendImageError.getAttachmentMessage)))
                return Disposables.create()
            }
            let group = DispatchGroup()
            // 上传的资源个数
            let resourceCount = AttachmentMessageArray.count
            let scene = request.getConfig().checkConfig.scene
            let fromType = request.getConfig().checkConfig.fromType
            let isOrigin = request.getConfig().checkConfig.isOrigin
            for attachmentMessage in AttachmentMessageArray {
                group.enter()
                let uuid = UUID().uuidString
                UploadImageTracker.start(key: uuid, scene: scene, biz: .Messenger)
                self.uploadOneImage(attachmentMessage: attachmentMessage)
                    .subscribe(onNext: { url in
                        AttachmentTrackerImage.logger.info("UniteSendImage \(request.requestId) attachment upload success")
                        attachmentMessage.result = url
                        var info = UploadImageInfo()
                        info.fromType = fromType
                        info.useOrigin = isOrigin
                        info.resourceCount = resourceCount
                        // addParams会根据compressResult设置info的原始数据和压缩完的数据
                        info.addParams(compressResult: attachmentMessage.compressResult)
                        UploadImageTracker.end(key: uuid, info: info)
                        group.leave()
                    }, onError: { error in
                        AttachmentTrackerImage.logger.error("UniteSendImage \(request.requestId) attachment upload error \(error)")
                        attachmentMessage.error = error
                        let info = UploadImageInfo()
                        UploadImageTracker.error(key: uuid, error: error)
                        group.leave()
                    })
            }
            group.notify(queue: .main) {
                observer.onNext(AttachmentMessageArray)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    public func uploadOneImage(attachmentMessage: AttachmentMessage) -> Observable<String> {
        assertionFailure("need a new subClass to override this function")
        return .just("")
    }
}

// 业务方上传单张图片
public final class AttachmentImageUploader: AttachmentTrackerImage {
    private let imageAPI: ImageAPI?
    private let encrypt: Bool
    public init(encrypt: Bool, imageAPI: ImageAPI?) {
        self.encrypt = encrypt
        self.imageAPI = imageAPI
    }
    override public func uploadOneImage(attachmentMessage: AttachmentMessage) -> Observable<String> {
        let type = RustPB.Media_V1_UploadSecureImageRequest.TypeEnum.post
        // 上传单张图片
        return self.imageAPI?.uploadSecureImage(data: attachmentMessage.data, type: type, imageCompressedSizeKb: 0, encrypt: encrypt) ?? .empty()
    }
}

// 使用post、moment场景下，选择图片或拍摄图片，处理压缩后的图片.
// 将检查通过的图片，调用callback让业务方返回attachmentKey，processor再封装成AttachmentMessage存储到context中
final class AttachmentProcessor: LarkSendImageProcessor {
    var callback: ((ImageSourceResult) -> String?)?
    init(callback: ((ImageSourceResult) -> String?)?) {
        self.callback = callback
    }
    public func imageProcess(sendImageState: SendImageState, request: LarkSendImageAbstractRequest) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let `self` = self, let compressResultArray = request.getCompressResult()
            else {
                observer.onError(AttachmentPostSendImageError(code: AttachmentPostSendImageError.getCompressResult))
                return Disposables.create()
            }
            DispatchQueue.main.async {
                var checkSuccess = true
                let attachmentMessageArray: [AttachmentMessage] = compressResultArray.compactMap({ compressResult -> AttachmentMessage? in
                    switch compressResult.result {
                    case .success(let result):
                        let key = self.callback?(result)
                        guard let key = key, let data = result.data else { return nil }
                        return AttachmentMessage(key: key, result: nil, data: data, error: nil, compressResult: compressResult)
                    case .failure(let err):
                        observer.onError(err)
                        checkSuccess = false
                    }
                    return nil
                })
                if !checkSuccess { return }
                request.setContext(key: "send.image.post.attachment.key", value: attachmentMessageArray)
                observer.onNext(())
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}

public class KeyboardPanelItemPictureServiceIMP: KeyboardPanelPictureHandlerService,
                                                 KeyboardPanelInsertCanvasService,
                                                 UserResolverWrapper {
    public let userResolver: UserResolver

    @ScopedInjectedLazy var sendImageProcessor: SendImageProcessor?

    /// 图片发送逻辑统一FG
    lazy var IsCompressCameraPhotoFG: Bool = fgService?.staticFeatureGatingValue(with: "feature_key_camera_photo_compress") ?? false

    lazy var assetManager: AssetPreProcessManager = {
        return AssetPreProcessManager(userResolver: self.userResolver, isCrypto: false)
    }()

    @ScopedInjectedLazy var videoSendService: VideoMessageSendService?

    @ScopedInjectedLazy var resourceAPI: ResourceAPI?

    @ScopedInjectedLazy var imageAPI: ImageAPI?

    lazy var  mediaDiskUtil: MediaDiskUtil = { .init(userResolver: self.userResolver) }()

    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?

    @ScopedInjectedLazy private var fgService: FeatureGatingService?

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    /// 该方法在检测失败会自动提示error
    public func checkMediaSendEnable(assets: [PHAsset], on view: UIView?) -> Bool {
        return mediaDiskUtil.checkMediaSendEnable(assets: assets, on: view)
    }

    public func checkImageSendEnable(image: UIImage, on view: UIView?) -> Bool {
        return mediaDiskUtil.checkImageSendEnable(image: image, on: view)
    }

    public func checkVideoSendEnable(videoURL: URL, on view: UIView?) -> Bool {
        return mediaDiskUtil.checkVideoSendEnable(videoURL: videoURL, on: view)
    }

    public func handlerInsertVideoFrom(_ type: LarkBaseKeyboard.PanelVideoType,
                                      attachmentUploader: LarkAttachmentUploader.AttachmentUploader,
                                      isOriginal: Bool,
                                      extraParam: [String: Any]?,
                                      callBack: ((LarkBaseKeyboard.VideoHandlerResult) -> Void)?) {
        var content: SendVideoContent?
        switch type {
        case .asset(let asset):
            content = .asset(asset)
        case .fileURL(let url):
            content = .fileURL(url)
        @unknown default:
            break
        }
        guard let content = content else {
            return
        }
        self.videoSendService?.getVideoInfo(with: content,
                                           isOriginal: isOriginal,
                                           extraParam: extraParam) { [weak self] (info, error) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let info = info {
                    if info.status == .fillBaseInfo {
                        let result = self.transformVideoInfo(info, attachmentUploader: attachmentUploader)
                        callBack?(.success(result.0, result.1, result.2))
                    } else {
                        let message = VideoParser.notSupportSendI18n(info: info)
                        callBack?(.notSupport(message))
                    }
                } else {
                    callBack?(.error(error))
                }
            }
        }
    }

    public func transformVideoInfo(_ videoInfo: VideoParseTask.VideoInfo,
                                   attachmentUploader: AttachmentUploader) -> (VideoTransformInfo?, UIImage, String) {
        // 视频第一帧图像
        let image = videoInfo.preview
        guard let imageKey = self.upload(videoInfo: videoInfo, attachmentUploader: attachmentUploader) else { return (nil, UIImage(), "") }
        var imageData = (image as? ByteImage)?.animatedImageData
        if imageData == nil {
            if let firstFrameData = videoInfo.firstFrameData {
                imageData = firstFrameData
            } else {
                imageData = image.jpegData(compressionQuality: 0.75)
            }
        }
        let info = VideoTransformInfo(
            name: videoInfo.name,
            duration: Int32(videoInfo.duration * 1000),
            size: Int64(videoInfo.filesize),
            compressPath: videoInfo.compressPath,
            originPath: videoInfo.exportPath,
            imageRemoteKeys: nil,
            imageLocalKey: imageKey,
            imageSize: image.size,
            imageData: imageData ?? Data(),
            uploadID: nil,
            cryptoToken: nil,
            key: nil,
            copyImage: false,
            copyMedia: false,
            authToken: nil)
        return (info, image, imageKey)
    }

    func upload(videoInfo: VideoParseInfo, attachmentUploader: AttachmentUploader) -> String? {
        let priview = videoInfo.preview
        // 这里添加 isVideo 是为了提示上传者 不上传视频首帧图片，只使用缓存能力
        let info: [String: String] = [
            "isVideo": "1"
        ]

        var imageData = (priview as? ByteImage)?.animatedImageData
        if imageData == nil {
            if let firstFrameData = videoInfo.firstFrameData {
                imageData = firstFrameData
            } else {
                imageData = priview.jpegData(compressionQuality: 0.75)
            }
        }
        guard let data = imageData else {
            ComposePostViewModel.logger.info("video image can transform to data")
            return nil
        }
        let imageAttachment = attachmentUploader.attachemnt(data: data, type: .secureImage, info: info)
        guard attachmentUploader.upload(attachment: imageAttachment) else {
            ComposePostViewModel.logger.error("not register image type attachment upload handler")
            return nil
        }
        return imageAttachment.key
    }

    public func handlerInsertImageAssetsFrom(_ assets: [PHAsset],
                                      attachmentUploader: LarkAttachmentUploader.AttachmentUploader,
                                      encrypt: Bool,
                                      useOriginal: Bool,
                                      scene: Scene,
                                      process: ((ImageProcessInfo) -> Void)?,
                                      callBack: ((LarkBaseKeyboard.ImageHandlerResult) -> Void)?) {
        assetManager.cancelAllOperation()
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            let uploader = AttachmentImageUploader(encrypt: encrypt, imageAPI: self.imageAPI)
            let processor = AttachmentProcessor { [weak self] imageInfo in
                return self?.insert(imageInfo: imageInfo, useOriginal: useOriginal, attachmentUploader: attachmentUploader, process: process)
            }

            let request = SendImageRequest(
                input: .assets(assets),
                sendImageConfig: SendImageConfig(
                    isSkipError: false,
                    checkConfig: SendImageCheckConfig(isOrigin: useOriginal, needConvertToWebp: LarkImageService.shared.imageUploadWebP, scene: scene, biz: .Messenger, fromType: .post)),
                uploader: uploader)
            // 因为是多图，所以设置业务方自定义上传埋点
            request.setContext(key: SendImageRequestKey.Other.isCustomTrack, value: true)
            let hasProProcessBlock: PreCompressResultBlock = { [weak self] asset in
                guard asset.editImage == nil,
                    let assetManager = self?.assetManager
                else { return nil }
                let originAssetName = assetManager.getDefaultKeyFrom(phAsset: asset)
                let assetName = assetManager.combineImageKeyWithIsOriginal(imageKey: originAssetName, isOriginal: useOriginal)
                return assetManager.getImageSourceResult(assetName: assetName)
            }
            request.setContext(key: SendImageRequestKey.CompressResult.PreCompressResultBlock, value: hasProProcessBlock)
            request.addProcessor(afterState: .compress, processor: processor, processorId: "compose.post.fetch.images")
            SendImageManager.shared
                .sendImage(request: request)
                .subscribe(onNext: { [weak self] messageArray in
                    DispatchQueue.main.async {
                        callBack?(.success)
                        self?.assetManager.afterPreProcess(assets: assets)
                    }
                    messageArray.forEach { message in
                        attachmentUploader.finishCustomUpload(
                            key: message.key, result: message.result, data: message.data, error: message.error)
                    }
                }, onError: { [weak self] error in
                    var tips = BundleI18n.LarkMessageCore.Lark_Legacy_ErrorMessageTip
                    if let imageError = error as? LarkSendImageError,
                        let compressError = imageError.error as? CompressError,
                        let err = AttachmentImageError.getCompressError(error: compressError) {
                        tips = err
                    }
                    DispatchQueue.main.async {
                        self?.assetManager.afterPreProcess(assets: assets)
                        callBack?(.error(tips))
                    }
                })
        }
    }

    public func handlerInsertImageFrom(_ image: UIImage,
                                      useOriginal: Bool,
                                      attachmentUploader: LarkAttachmentUploader.AttachmentUploader,
                                      sendImageConfig: ByteWebImage.SendImageConfig,
                                      encrypt: Bool,
                                      fromVC: UIViewController?,
                                      processorId: String,
                                      callBack: ((LarkBaseKeyboard.ImageProcessInfo) -> Void)?) {
        DispatchQueue.global().async { [weak self] in
            guard let `self` = self else { return }
            let uploader = AttachmentImageUploader(encrypt: encrypt, imageAPI: self.imageAPI)
            // processor的callback提供处理完成后的图片信息，希望返回attachmentKey
            let processor = AttachmentProcessor { [weak self] imageInfo in
                return self?.insert(imageInfo: imageInfo,
                                    useOriginal: useOriginal,
                                    attachmentUploader: attachmentUploader,
                                    process: callBack)
            }
            let request = SendImageRequest(
                input: .image(image),
                sendImageConfig: sendImageConfig,
                uploader: uploader)
            // upload内上传了埋点
            request.setContext(key: SendImageRequestKey.Other.isCustomTrack, value: true)
            request.addProcessor(afterState: .compress,
                                 processor: processor,
                                 processorId: processorId)
            SendImageManager.shared
                .sendImage(request: request)
                .subscribe(onNext: { messageArray in
                    messageArray.forEach { message in
                        attachmentUploader.finishCustomUpload(key: message.key, result: message.result, data: message.data, error: message.error)
                    }
                }, onError: { error in
                    var tips = BundleI18n.LarkMessageCore.Lark_Legacy_ErrorMessageTip
                    // 如果是compress阶段的error，提示对应错误
                    if let imageError = error as? LarkSendImageError,
                        let compressError = imageError.error as? CompressError,
                        let err = AttachmentImageError.getCompressError(error: compressError) {
                        tips = err
                    }
                    DispatchQueue.main.async { [weak self, weak fromVC] in
                        guard let self = self, let fromVC = fromVC else { return }
                        UDToast.showFailure(with: tips, on: fromVC.view.window ?? fromVC.view)
                    }
                })
        }
    }

    public func handlerAssetPickerSuiteChange(result: AssetPickerSuiteSelectResult) {
        guard assetManager.checkPreProcessEnable else { return }
        result.selectedAssets.forEach { asset in
            guard asset.mediaType == .image,
                  assetManager.checkEnableByType(fileType: .image),
                  assetManager.checkMemoryIsEnough()
            else { return }
            let originAssetName = assetManager.getDefaultKeyFrom(phAsset: asset)
            // 区分是否原图
            let assetName = assetManager.combineImageKeyWithIsOriginal(imageKey: originAssetName, isOriginal: result.isOriginal)
            guard !assetManager.checkAssetHasOperation(assetName: assetName) else { return }
            let assetOperation = BlockOperation { [weak self] in
                guard let self = self, let sendImageProcessor = self.sendImageProcessor else { return }
                var dependency = ImageInfoDependency(useOrigin: result.isOriginal,
                                                     sendImageProcessor: sendImageProcessor)
                dependency.isConvertWebp = LarkImageService.shared.imageUploadWebP
                let imageSourceResult = asset.imageInfo(dependency)
                self.assetManager.addToFinishAssets(name: assetName, value: imageSourceResult)
            }
            assetManager.addAssetProcessOperation(assetOperation)
            assetManager.addToPendingAssets(name: assetName, value: asset)
        }
    }

    @discardableResult
    func insert(imageInfo: ImageSourceResult,
                useOriginal: Bool,
                attachmentUploader: LarkAttachmentUploader.AttachmentUploader,
                process: ((ImageProcessInfo) -> Void)?) -> String? {
        guard let image = imageInfo.image,
              let imageKey = createAttachment(imageInfo: imageInfo, useOriginal: useOriginal, attachmentUploader: attachmentUploader)
        else { return nil }
        process?(ImageProcessInfo(image: image, imageKey: imageKey, useOrigin: useOriginal))
        return imageKey
    }

    func createAttachment(imageInfo: ImageSourceResult,
                          useOriginal: Bool,
                          attachmentUploader: LarkAttachmentUploader.AttachmentUploader) -> String? {
        guard let image = imageInfo.image else { return nil }
        let height = image.size.height * image.scale
        let width = image.size.width * image.scale
        let extraInfo: [String: AnyHashable] = [
            "image_type": imageInfo.sourceType.description,
            "color_space": imageInfo.colorSpaceName ?? "unkonwn",
            "is_image_origin": useOriginal,
            "resource_height": height,
            "resource_width": width,
            "compress_cost": imageInfo.compressCost ?? 0,
            "resource_content_length": imageInfo.data?.count ?? 0,
            "from_type": UploadImageInfo.FromType.post.rawValue, // 富文本消息
            "scene": UploadImageInfo.UploadScene.chat.rawValue // scene
        ]

        guard let imageKey = self.upload(
            attachmentUploader: attachmentUploader,
            image: image,
            imageData: imageInfo.data,
            useOriginal: useOriginal,
            extraInfo: extraInfo
            ) else { return nil }
        return imageKey
    }

    func upload(attachmentUploader: LarkAttachmentUploader.AttachmentUploader,
                image: UIImage,
                imageData: Data?,
                useOriginal: Bool,
                extraInfo: [String: AnyHashable]? = nil) -> String? {
        var imageInfo: [String: String] = [
            "width": "\(Int32(image.size.width))",
            "height": "\(Int32(image.size.height))",
            "type": "post",
            "useOriginal": useOriginal ? "1" : "0"
        ]
        // 额外信息，为了不破坏原有结构，所以转jsonString放进去
        if let extra = extraInfo,
           let jsonData = try? JSONSerialization.data(withJSONObject: extra, options: .fragmentsAllowed) {
            let string = String(data: jsonData, encoding: .utf8)
            imageInfo["extraInfo"] = string
        }

        guard let data = imageData else {
            ComposePostViewModel.logger.info("image can transform to data")
            return nil
        }

        let imageAttachment = attachmentUploader.attachemnt(data: data, type: .secureImage, info: imageInfo)
        ComposePostViewModel.logger.info("use custom uploader imageAttachment.key: \(imageAttachment.key)")
        // 使用自定义上传attachment接口
        attachmentUploader.customUpload(attachment: imageAttachment)
        return imageAttachment.key
    }

     public func handlerVideoError(_ error: Error, fromVC: UIViewController?) {
         DispatchQueue.main.async { [weak self, weak fromVC] in
             if let sendvideoError = error as? VideoParseTask.ParseError {
                 switch sendvideoError {
                 case let .fileReachMax(_, fileSizeLimit):
                     self?.showFileSizeLimitFailure(fileSizeLimit, fromVC: fromVC)
                 case .videoTrackUnavailable:
                     if let window = fromVC?.view.window {
                         UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Legacy_VideoMessageVideoUnavailable, on: window)
                     }
                 case .loadAVAssetIsInCloudError:
                     self?.showAlert(BundleI18n.LarkMessageCore.Lark_Chat_iCloudMediaUploadError, from: fromVC, showCancel: false)
                 case .userCancel: break
                 default:
                     // 提示数据读取错误
                     self?.showAlert(BundleI18n.LarkMessageCore.Lark_Legacy_ComposePostVideoReadDataError, from: fromVC, showCancel: false)
                 }
             } else {
                 // 提示数据读取错误
                 self?.showAlert(BundleI18n.LarkMessageCore.Lark_Legacy_ComposePostVideoReadDataError, from: fromVC, showCancel: false)
             }
         }
    }

    public func showAlert(_ message: String,
                           from: UIViewController?,
                           showCancel: Bool = true, onSure: (() -> Void)? = nil) {
        guard let from = from else {
            return
        }
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_Legacy_Hint)
        alertController.setContent(text: message)
        if showCancel {
            alertController.addCancelButton()
        }
        alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Legacy_LarkConfirm, dismissCompletion: {
            onSure?()
        })
        self.navigator.present(alertController, from: from)
    }

    private func showFileSizeLimitFailure(_ fileSizeLimit: UInt64, fromVC: UIViewController?) {
        if let window = fromVC?.view.window {
            UDToast.showFailure(with: BundleI18n
                .LarkMessageCore
                .Lark_File_ToastSingleFileSizeLimit(fileSizeToString(fileSizeLimit)),
                on: window)
        }
    }

    /// 将文件大小限制转换为字符串
    /// 当限制小于1GB时，以MB为单位表示，否则以GB为单位表示
    private func fileSizeToString(_ fileSize: UInt64) -> String {
        let megaByte: UInt64 = 1024 * 1024
        let gigaByte = 1024 * megaByte
        if fileSize < gigaByte {
            let fileSizeInMB = Double(fileSize) / Double(megaByte)
            return String(format: "%.2fMB", fileSizeInMB)
        } else {
            let fileSizeInGB = Double(fileSize) / Double(gigaByte)
            return String(format: "%.2fGB", fileSizeInGB)
        }
    }

    public func computeResourceKey(key: String, isOrigin: Bool) -> String {
        return self.resourceAPI?.computeResourceKey(key: key, isOrigin: isOrigin) ?? ""
    }

    public func handlerImageUploadError(error: Error?, fromVC: UIViewController) {
        if let apiError = error?.underlyingError as? APIError {
            switch apiError.type {
            case .cloudDiskFull:
                let alertController = LarkAlertController()
                alertController.showCloudDiskFullAlert(from: fromVC, nav: self.navigator)
            case .securityControlDeny(let message):
                self.chatSecurityControlService?.authorityErrorHandler(event: .sendImage,
                                                                      authResult: nil,
                                                                      from: fromVC,
                                                                      errorMessage: message)
            case .strategyControlDeny: // 鉴权的策略引擎返回的报错，安全侧弹出弹框，端上做静默处理
                break
            default: self.showDefaultError(error: apiError, view: fromVC.view.window)
            }
            return
        }
        if let error = error {
            self.showDefaultError(error: error, view: fromVC.view.window)
        }
    }

    func showDefaultError(error: Error, view: UIWindow?) {
        guard let window = view else {
            return
        }
        UDToast.showFailure(
            with: BundleI18n.LarkMessageCore.Lark_Legacy_ErrorMessageTip, on: window, error: error
        )
    }
}
