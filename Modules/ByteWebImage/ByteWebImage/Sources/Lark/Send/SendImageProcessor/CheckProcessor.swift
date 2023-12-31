//
//  CheckProssor.swift
//  ByteWebImage
//
//  Created by kangkang on 2022/8/23.
//

import Photos
import RxSwift
import Foundation
import LarkSetting
import LKCommonsLogging

public final class CheckResult {
    public var result: Result<Void, CheckError>
    public var input: CompressInput
    public init(result: Result<Void, CheckError>, input: CompressInput) {
        self.result = result
        self.input = input
    }
}

/// 封装工具方法。检查图片参数是否超出setting限制
public final class ImageUploadChecker {
    static let logger = Logger.log(ImageUploadChecker.self, category: "byteImage.image.upload.checker")

    /// 根据formatOptions内是否含有needConvertToWebp和useOrigin，返回最终展示的格式
    public static func getFinalImageType(imageType: ImageSourceResult.SourceType, formatOptions: ImageProcessOptions = []) -> ImageSourceResult.SourceType {
        if imageType != .gif, !formatOptions.contains(.useOrigin) {
            return formatOptions.contains(.needConvertToWebp) ? .webp : .jpeg
        }
        return imageType
    }

    /// 根据formatOptions是否含有needConvertToWebp和useOrigin，估计最终展示的图片格式，再判断是否含有isFromCrypto，进行格式校验，文件大小校验，像素大小校验
    public static func getAssetCheckResult(asset: PHAsset,
                                           formatOptions: ImageProcessOptions = [],
                                           customLimitFileType: [String]? = nil,
                                           customLimitFileSize: Int? = nil,
                                           customLimitImageSize: CGSize? = nil) -> Result<Void, CheckError> {
        let finalImageType = getFinalImageType(imageType: asset.imageType, formatOptions: formatOptions)
        return ImageUploadChecker.getImageInfoCheckResult(sourceImageType: asset.imageType,
                                                          finalImageType: finalImageType,
                                                          customLimitFileType: customLimitFileType,
                                                          fileSize: asset.size,
                                                          customLimitFileSize: customLimitFileSize,
                                                          imageSize: asset.originSize,
                                                          customLimitImageSize: customLimitImageSize)
    }

    /// 根据formatOptions是否含有isFromCrypto，进行格式校验，文件大小校验，像素大小校验
    public static func getImageInfoCheckResult(sourceImageType: ImageSourceResult.SourceType,
                                               finalImageType: ImageSourceResult.SourceType,
                                               formatOptions: ImageProcessOptions = [],
                                               customLimitFileType: [String]? = nil,
                                               fileSize: Int64,
                                               customLimitFileSize: Int? = nil,
                                               imageSize: CGSize,
                                               customLimitImageSize: CGSize? = nil) -> Result<Void, CheckError> {
        let fileTypeResult = ImageUploadChecker.getFileUTICheckResult(finalImageType: finalImageType, customLimitFileType: customLimitFileType, formatOptions: formatOptions)
        if case .failure = fileTypeResult {
            return fileTypeResult
        }
        let fileSizeResult = ImageUploadChecker.getFileSizeCheckResult(sourceImageType: sourceImageType,
                                                                       finalImageType: finalImageType,
                                                                       fileSize: fileSize,
                                                                       customLimitFileSize: customLimitFileSize)
        if case .failure = fileSizeResult {
            return fileSizeResult
        }
        let imageSizeResult = ImageUploadChecker.getImageSizeCheckResult(sourceImageType: sourceImageType,
                                                                         finalImageType: finalImageType,
                                                                         imageSize: imageSize,
                                                                         customLimitImageSize: customLimitImageSize)
        if case .failure = imageSizeResult {
            return imageSizeResult
        }
        return .success(())
    }

    /// 根据formatOptions是否含有needConvertToWebp和useOrigin，估计最终展示的图片格式，再判断是否含有isFromCrypto，进行格式校验，文件大小校验，像素大小校验
    public static func getDataCheckResult(data: Data,
                                          formatOptions: ImageProcessOptions = [],
                                          customLimitFileType: [String]? = nil,
                                          customLimitFileSize: Int? = nil,
                                          customLimitImageSize: CGSize? = nil) -> Result<Void, CheckError> {
        // 获取data的文件类型
        let finalImageType = getFinalImageType(imageType: data.bt.imageFileFormat, formatOptions: formatOptions)
        let fileTypeResult = ImageUploadChecker.getFileUTICheckResult(finalImageType: finalImageType, customLimitFileType: customLimitFileType, formatOptions: formatOptions)
        if case .failure = fileTypeResult {
            return fileTypeResult
        }
        let fileSizeResult = ImageUploadChecker.getFileSizeCheckResult(sourceImageType: data.bt.imageFileFormat, finalImageType: finalImageType, fileSize: Int64(data.count), customLimitFileSize: customLimitFileSize)
        if case .failure = fileSizeResult {
            return fileSizeResult
        }
        if let imageSourceResult = CGImageSourceCreateWithData(data as CFData, nil),
           let imageDic = CGImageSourceCopyPropertiesAtIndex(imageSourceResult, 0, nil) as? [CFString: Any],
           let width = imageDic[kCGImagePropertyPixelWidth] as? Int,
           let height = imageDic[kCGImagePropertyPixelHeight] as? Int {
            let imageSizeResult = ImageUploadChecker.getImageSizeCheckResult(sourceImageType: data.bt.imageFileFormat,
                                                                             finalImageType: finalImageType,
                                                                             imageSize: CGSize(width: width, height: height),
                                                                             customLimitImageSize: customLimitImageSize)
            if case .failure = imageSizeResult {
                return imageSizeResult
            }
        }
        return .success(())
    }

    /// 根据formatOptions是否含有isFromCrypto，进行格式校验
    public static func getFileUTICheckResult(finalImageType: ImageSourceResult.SourceType,
                                             customLimitFileType: [String]? = nil,
                                             formatOptions: ImageProcessOptions = []) -> Result<Void, CheckError> {
        ImageUploadChecker.logger.info("checkFileUTI \(finalImageType) \(String(describing: customLimitFileType)) \(formatOptions)")
        let imageTypeContainer = customLimitFileType ?? (
            formatOptions.contains(.isFromCrypto) ? LarkImageService.shared.imageUploadSetting.fileTypeCheckConfig.localWhiteList :
                LarkImageService.shared.imageUploadSetting.fileTypeCheckConfig.serverWhiteList)
        if imageTypeContainer.contains(finalImageType.description) {
            return .success(())
        }
        ImageUploadChecker.logger.info("checkFileUTI failed \(imageTypeContainer)")
        return .failure(.fileTypeInvalid)
    }

    /// 文件大小校验
    public static func getFileSizeCheckResult(sourceImageType: ImageSourceResult.SourceType,
                                              finalImageType: ImageSourceResult.SourceType,
                                              fileSize: Int64,
                                              customLimitFileSize: Int? = nil) -> Result<Void, CheckError> {
        ImageUploadChecker.logger.info("checkFileSize \(finalImageType) \(fileSize) \(String(describing: customLimitFileSize))")
        // 如果图片原格式是Tiff，那么以Tiff的上限进行对比
        var diffType = finalImageType
        if sourceImageType == .tiff {
            diffType = sourceImageType
        }
        // 对比settings
        let limitFileSize: Int = customLimitFileSize ?? Int(LarkImageService.shared.imageUploadSetting.getFileSizeFromSetting(imageType: diffType))
        if fileSize > limitFileSize {
            ImageUploadChecker.logger.info("checkFileSize failed \(limitFileSize)")
            return .failure(.imageFileSizeExceeded(Int(limitFileSize)))
        }
        return .success(())
    }

    /// 像素大小校验
    public static func getImageSizeCheckResult(sourceImageType: ImageSourceResult.SourceType,
                                               finalImageType: ImageSourceResult.SourceType,
                                               imageSize: CGSize,
                                               customLimitImageSize: CGSize? = nil) -> Result<Void, CheckError> {
        ImageUploadChecker.logger.info("checkImageSize \(finalImageType) \(imageSize) \(String(describing: customLimitImageSize))")
        var diffType = finalImageType
        if sourceImageType == .tiff {
            diffType = sourceImageType
        }
        // 对比settings
        let limitImageSize: CGSize = customLimitImageSize ?? LarkImageService.shared.imageUploadSetting.getImageSizeFromSetting(imageType: diffType)
        if (imageSize.width * imageSize.height) > (limitImageSize.width * limitImageSize.height) {
            ImageUploadChecker.logger.info("checkImageSize failed \(limitImageSize)")
            return .failure(.imagePixelsExceeded(limitImageSize))
        }
        return .success(())
    }
}

/// 检查阶段
class LarkSendImageCheckProcess: LarkSendImageProcessor {
    let sendImageConfig: SendImageConfig
    let input: ImageInputType
    static let logger = Logger.log(LarkSendImageCheckProcess.self, category: "byteImage.check.processor")
    init(config: SendImageConfig, input: ImageInputType) {
        self.sendImageConfig = config
        self.input = input
    }

    func checkPHAsset(asset: PHAsset) -> CheckError? {
        var fileSize: Int?
        if let custom = sendImageConfig.checkConfig.fileSize {
            fileSize = Int(custom)
        }
        let formatOptions: ImageProcessOptions = sendImageConfig.checkConfig.isOrigin ? [.useOrigin] : []
        let checkResult = ImageUploadChecker.getAssetCheckResult(
            asset: asset, formatOptions: formatOptions, customLimitFileSize: fileSize, customLimitImageSize: sendImageConfig.checkConfig.imageSize)
        if case .failure(let checkError) = checkResult {
            return checkError
        }
        return nil
    }

    func checkData(data: Data) -> CheckError? {
        var fileSize: Int?
        if let custom = sendImageConfig.checkConfig.fileSize {
            fileSize = Int(custom)
        }
        let formatOptions: ImageProcessOptions = sendImageConfig.checkConfig.isOrigin ? [.useOrigin] : []
        let checkResult = ImageUploadChecker.getDataCheckResult(
            data: data, formatOptions: formatOptions, customLimitFileSize: fileSize, customLimitImageSize: sendImageConfig.checkConfig.imageSize)
        if case .failure(let checkError) = checkResult {
            return checkError
        }
        return nil
    }

    func checkUIImage(image: UIImage) -> CheckError? {
        // UIImage已经丢失了格式，所以finalImageType传unknown
        let checkResult = ImageUploadChecker.getImageSizeCheckResult(sourceImageType: .unknown,
            finalImageType: .unknown, imageSize: image.size, customLimitImageSize: sendImageConfig.checkConfig.imageSize)
        if case .failure(let checkError) = checkResult {
            return checkError
        }
        return nil
    }

    func imageProcess(sendImageState: SendImageState, request: LarkSendImageAbstractRequest) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(CompressError.requestRelease)
                LarkSendImageCheckProcess.logger.info("UniteSendImage can not get `self`")
                return Disposables.create()
            }
            let isSkipError = self.sendImageConfig.isSkipError
            var hasError: Bool = false
            var checkResultArray: [CheckResult] = []
            // 将输入的信息都转为同一种输入
            let inputArray: [CompressInput]
            switch self.input {
            case .image(let image):
                inputArray = [.image(image)]
            case .images(let images):
                inputArray = images.map { .image($0) }
            case .data(let data):
                inputArray = [.data(data)]
            case .datas(let datas):
                inputArray = datas.map { .data($0) }
            case .asset(let asset):
                inputArray = [.phasset(asset)]
            case .assets(let assets):
                inputArray = assets.map { .phasset($0) }
            }

            for input in inputArray {
                let checkError: CheckError?
                switch input {
                case .phasset(let asset):
                    checkError = self.checkPHAsset(asset: asset)
                case .image(let image):
                    checkError = self.checkUIImage(image: image)
                case .data(let data):
                    checkError = self.checkData(data: data)
                }
                if let checkError = checkError {
                    LarkSendImageCheckProcess.logger.info("UniteSendImage check error \(checkError)")
                    // 如果业务方要求不跳过错误，则直接抛出错误
                    if !isSkipError {
                        LarkSendImageCheckProcess.logger.info("UniteSendImage check error, !isSkipError")
                        hasError = true
                        // 目前业务方判断的是 LarkSendImageError.error as? CompressError 所以为了不改业务方逻辑，此处向外抛出compressError
                        observer.onError(LarkSendImageError(type: .compress, error: checkError.transformCheckErrorToCompressError()))
                        break
                    } else {
                        // 否则将错误存储起来
                        checkResultArray.append(CheckResult(result: .failure(checkError), input: input))
                    }
                } else {
                    checkResultArray.append(CheckResult(result: .success(()), input: input))
                }
            }
            if hasError { return Disposables.create() }
            request.setContext(key: SendImageRequestKey.CheckResult.CheckResult, value: checkResultArray)
            observer.onNext(())
            observer.onCompleted()
            return Disposables.create()
        }
    }
}
