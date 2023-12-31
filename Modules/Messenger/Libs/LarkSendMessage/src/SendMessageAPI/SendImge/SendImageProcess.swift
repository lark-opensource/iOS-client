//
//  SendImageProcess.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/7/29.
//

import Foundation
import ByteWebImage // ImageProcessOptions
import RustPB // Basic_V1_CreateScene
import EEAtomic // SafeLazy

public struct SendImageSource {
    /// 消息上屏时用到的摘要图
    /// Thumbnail image for message on screen.
    @SafeLazy
    public var coverForOnScreen: ImageSourceResult?

    /// 准备好的丢给服务端的图片数据信息
    /// Ready to send to server image info.
    @SafeLazy
    public var originImage: ImageSourceResult

    public init(cover: ImageSourceFunc?, origin: @escaping ImageSourceFunc) {
        _coverForOnScreen = SafeLazy(block: {
            return cover?()
        })
        _originImage = SafeLazy(block: {
            return origin()
        })
    }
}

public struct ImageMessageInfo {
    /// 原始图片像素大小
    public var originalImageSize: CGSize
    public let sendImageSource: SendImageSource
    public var imagePathProvider: ((@escaping (URL?) -> Void) -> Void)?
    /// 原始图片文件大小
    public var imageSize: Int64?
    /// 目标图片格式
    public var imageType: ImageSourceResult.SourceType
    public var preprocessResourceKey: String?
    /// 是否是在预处理阶段处理的，埋点上报用
    public var isPreprocessed: Bool
    /// 图片是否来源于密聊
    public var isFromCrypto: Bool
    /// 原始图片格式
    public var sourceImageType: ImageSourceResult.SourceType

    public init(originalImageSize: CGSize,
                sendImageSource: SendImageSource,
                imageSize: Int64? = nil,
                imageType: ImageSourceResult.SourceType = .unknown,
                sourceImageType: ImageSourceResult.SourceType = .unknown,
                isPreprocessed: Bool = false,
                preprocessResourceKey: String? = nil,
                isFromCrypto: Bool = false,
                imagePathProvider: ((@escaping (URL?) -> Void) -> Void)? = nil) {
        self.originalImageSize = originalImageSize
        self.sendImageSource = sendImageSource
        self.imageSize = imageSize
        self.imageType = imageType
        self.isPreprocessed = isPreprocessed
        self.preprocessResourceKey = preprocessResourceKey
        self.imagePathProvider = imagePathProvider
        self.isFromCrypto = isFromCrypto
        self.sourceImageType = sourceImageType
    }
}

extension RustSendMessageAPI {
    func getSendImageProcess() -> SerialProcess<SendMessageProcessInput<SendImageModel>, RustSendMessageAPI> {
        let formatInputProcess = SerialProcess(SendImageFormatInputTask(context: self), context: self)
        let nativeCreateAndSendImageProcess = SerialProcess(
            [SendImageCoreFormatInputTask(context: self),
             SendImageMsgOnScreenTask(context: self),
             SendImageDealTask(context: self),
             SendImageCreateQuasiMsgTask(context: self),
             SendMessageTask(context: self)],
            context: self)

        let rustCreateAndSendImageProcess = SerialProcess(
            [SendImageCoreFormatInputTask(context: self),
             SendImageCreateQuasiMsgTask(context: self),
             SendImageDealTask(context: self),
             SendMessageTask(context: self)],
            context: self)

        let sendFileWrapperProcess = SendFileWrapperProcess(sendFileProcess: self.sendFileProcess, context: self)

        return SerialProcess(
            [formatInputProcess,
             ConditionProcess(context: self) { [weak self] (input)  in
                 guard let self = self else { return nil }
                 var input = input
                 input.useNativeCreate = self.quasiMsgCreateByNative(context: input.context)
                 let result = self.processSendFileResult(imageMessageInfo: input.model.imageMessageInfo)
                 if result.isNeedSendFile {
                     input.model.fileUrl = result.imageUrl
                     input.sendMessageTracker?.cacheImageFallbackToFileExtraInfo(cid: input.context?.contextID ?? "",
                                                                                 imageInfo: input.model.imageMessageInfo,
                                                                                 useOrigin: input.model.useOriginal)
                     return (sendFileWrapperProcess, input)
                 }
                 if !result.isNeedSendFile, input.useNativeCreate {
                     return (nativeCreateAndSendImageProcess, input)
                 }
                 return (rustCreateAndSendImageProcess, input)
             }],
        context: self)
    }

    // 发送图片转文件，校验图片各个值
    private func isImageNeedToFile(imageMessageInfo: ImageMessageInfo) -> Bool {

        let imageSize = imageMessageInfo.imageSize ?? 0
        Self.logger.info("isImageNeedToFile",
                         additionalData: [
                            "inputImageFileSize": "\(imageSize)",
                            "inputImageResolution": "\(imageMessageInfo.originalImageSize)"
                         ])
        let formatOptions: ImageProcessOptions = imageMessageInfo.isFromCrypto ? [.isFromCrypto] : []
        if case .failure(_) = ImageUploadChecker.getImageInfoCheckResult(sourceImageType: imageMessageInfo.sourceImageType,
                                                                         finalImageType: imageMessageInfo.imageType,
                                                                         formatOptions: formatOptions,
                                                                         fileSize: imageSize,
                                                                         imageSize: imageMessageInfo.originalImageSize) {
            return true
        }
        return false
    }
    struct SendFileResult {
        var isNeedSendFile = false
        var imageUrl: URL?
    }
    private func processSendFileResult(imageMessageInfo: ImageMessageInfo) -> SendFileResult {
        let isImageNeedToFile = isImageNeedToFile(imageMessageInfo: imageMessageInfo)
        guard isImageNeedToFile, let provider = imageMessageInfo.imagePathProvider else {
            return SendFileResult(isNeedSendFile: false, imageUrl: nil)
        }
        /// 需要保证时序取到URL之后再进行操作，使用信号量控制
        let semaphore = DispatchSemaphore(value: 0)
        var imageUrl: URL?
        provider({ url in
            guard url != nil else {
                semaphore.signal()
                return
            }
            imageUrl = url
            semaphore.signal()
        })
        semaphore.wait()
        return SendFileResult(isNeedSendFile: imageUrl != nil, imageUrl: imageUrl)
    }
}

public struct SendImageModel: SendMessageModelProtocol {
    var useOriginal: Bool
    var imageMessageInfo: ImageMessageInfo
    var chatId: String?
    var threadId: String?
    var cid: String?
    var startTime: TimeInterval?
    var imageData: Data?
    var imageSource: ImageSourceResult?
    var fileUrl: URL?
    var createScene: Basic_V1_CreateScene?
}

public protocol SendImageProcessContext: SendImageFormatInputTaskContext,
                                         SendImageCoreProcessContext,
                                         SendFileProcessContext {}

extension RustSendMessageAPI: SendImageProcessContext {}
