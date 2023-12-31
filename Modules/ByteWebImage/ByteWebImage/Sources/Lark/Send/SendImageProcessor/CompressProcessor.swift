//
//  LarkSendImageCheckAndCompress.swift
//  ByteWebImage
//
//  Created by kangsiwan on 2022/1/27.
//

import RxSwift
import Foundation
import Photos
import LKCommonsLogging

// compress的结果，包含结果和对应的输入
public final class CompressResult {
    public var result: Result<ImageSourceResult, CompressError>
    public var input: CompressInput
    public var extraInfo: [String: Any]
    public init(result: Result<ImageSourceResult, CompressError>, input: CompressInput, extraInfo: [String: Any] = [:]) {
        self.result = result
        self.input = input
        self.extraInfo = extraInfo
    }
}

public enum CompressInput {
    case phasset(PHAsset)
    case image(UIImage)
    case data(Data)
}

/// 压缩阶段
/// compress的process
class LarkSendImageCompressProcess: LarkSendImageProcessor {
    let sendImageConfig: SendImageConfig
    let sendImageProcessor = SendImageProcessorImpl()
    static let logger = Logger.log(LarkSendImageCompressProcess.self, category: "byteImage.compress.processor")
    init(config: SendImageConfig) {
        self.sendImageConfig = config
    }
    /// 封装SendImageProcessor方法，最终得到[ImageSourceResult]
    func imageProcess(sendImageState: SendImageState, request: LarkSendImageAbstractRequest) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self, let compressInput = request.getCheckResult() else {
                observer.onError(CompressError.failedToGetCheckResult)
                return Disposables.create()
            }
            let isSkipError = self.sendImageConfig.isSkipError
            var compressResultArray: [CompressResult] = []
            var hasError = false
            let extraInfo: [String: Any] = [:]
            for input in compressInput {
                let result: Result<ImageSourceResult, CompressError>
                switch input.result {
                case .success:
                    switch input.input {
                    case .phasset(let asset):
                        // 如果是PHAsset类型，调用对应的方法压缩处理
                        if let preProcessBlock = request.getContext()[SendImageRequestKey.CompressResult.PreCompressResultBlock] as? PreCompressResultBlock,
                           let imageSourceResult = preProcessBlock(asset) {
                            result = Result.success(imageSourceResult)
                        } else {
                            var dependency = ImageInfoDependency(
                                useOrigin: self.sendImageConfig.checkConfig.isOrigin,
                                sendImageProcessor: self.sendImageProcessor)
                            dependency.isConvertWebp = LarkImageService.shared.imageUploadWebP
                            result = self.getPHAssetImageSourceResult(asset: asset, dependency: dependency)
                        }
                    case .image(let image):
                        // 如果是image和data类型，调用原本的process方法处理
                        result = self.getImageSourceResult(input: .image(image))
                    case .data(let data):
                        result = self.getImageSourceResult(input: .imageData(data))
                    }
                case .failure(let checkError):
                    result = .failure(checkError.transformCheckErrorToCompressError())
                }
                // 如果业务方要求不跳过错误，则发送错误
                if !isSkipError, case .failure(let error) = result {
                    hasError = true
                    observer.onError(error)
                    break
                } else {
                    // 将输入和结果存入数组中
                    compressResultArray.append(CompressResult(result: result, input: input.input, extraInfo: extraInfo))
                }
            }
            // 标记为true，直接返回
            if hasError { return Disposables.create() }
            // 将数组存入context中
            request.setContext(key: SendImageRequestKey.CompressResult.CompressResult, value: compressResultArray)
            LarkSendImageCompressProcess.logger.info("UniteSendImage compress success imageResultAndInputArray: \(compressResultArray)")
            observer.onNext(())
            observer.onCompleted()
            return Disposables.create()
        }
    }

    // 将asset类型的图片转为ImageSourceResult
    func getPHAssetImageSourceResult(asset: PHAsset, dependency: ImageInfoDependency) -> Result<ImageSourceResult, CompressError> {
        let imageSourceResult: ImageSourceResult
        if let destPixel = self.sendImageConfig.compressConfig.destPixel,
           let compressRate = self.sendImageConfig.compressConfig.compressRate {
            LarkSendImageCompressProcess.logger.info("UniteSendImage compress phasset new interface \(destPixel) \(compressRate)")
            imageSourceResult = asset.compressedImageInfo(dependency, destPixel, compressRate)
        } else {
            LarkSendImageCompressProcess.logger.info("UniteSendImage compress phasset old interface")
            imageSourceResult = asset.imageInfo(dependency)
        }
        return Result.success(imageSourceResult)
    }

    // 用于执行从ImageProcessorResult到ImageSourceResult
    func getImageSourceResult(input: ImageProcessSourceType) -> Result<ImageSourceResult, CompressError> {
        var imageProcessorResult: ImageProcessResult?
        // config -> Options TODO: @kangsiwan to be refactored
        var options: ImageProcessOptions = .init()
        let checkConfig = self.sendImageConfig.checkConfig
        if checkConfig.isOrigin {
            options = options.union(.useOrigin)
        }
        if checkConfig.needConvertToWebp {
            options = options.union(.needConvertToWebp)
        }
        if !checkConfig.canUseServer {
            options = options.union(.isFromCrypto)
        }
        // 如果业务方自定义了压缩参数等，则使用自定义参数
        if let destPixel = self.sendImageConfig.compressConfig.destPixel,
           let compressRate = self.sendImageConfig.compressConfig.compressRate,
           let processorResult = self.sendImageProcessor.process(source: input, options: options, destPixel: destPixel, compressRate: compressRate, scene: self.sendImageConfig.checkConfig.scene) {
            LarkSendImageCompressProcess.logger.info("UniteSendImage compress ProcessSourceType new interface \(destPixel) \(compressRate)")
            imageProcessorResult = processorResult
        // 否则使用默认参数
        } else if let processorResult = self.sendImageProcessor.process(source: input, option: options, scene: self.sendImageConfig.checkConfig.scene) {
            LarkSendImageCompressProcess.logger.info("UniteSendImage compress ProcessSourceType old interface")
            imageProcessorResult = processorResult
        }
        // 如果没有获取到参数，则返回error
        guard let imageProcessorResult = imageProcessorResult else {
            LarkSendImageCompressProcess.logger.error("UniteSendImage can not get compress result")
            return Result.failure(CompressError.failedToGetProcessResult)
        }
        // 将结果转为ImageSourceResult
        let imageSourceResult = ImageSourceResult(
            sourceType: imageProcessorResult.imageType,
            data: imageProcessorResult.imageData,
            image: imageProcessorResult.image,
            compressCost: imageProcessorResult.cost,
            colorSpaceName: imageProcessorResult.colorSpaceName,
            compressRatio: imageProcessorResult.compressRatio,
            compressAlgorithm: imageProcessorResult.compressAlgorithm?.rawValue)
        return Result.success(imageSourceResult)
    }
}
