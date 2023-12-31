//
//  SendImageProcedure.swift
//  ByteWebImage
//
//  Created by kangsiwan on 2022/1/18.
//

import RustPB
import RxSwift
import Foundation
import CoreServices
import LarkContainer
import EEImageMagick
import AppReciableSDK
import LKCommonsLogging
import LarkRustClient

// 输入
public enum ImageProcessSourceType {
    case image(UIImage)
    case imageData(Data)
}

public enum CompressAlgorithm: String {
    case native
    case sdk
    case noCompress
}

// 输出
public struct ImageProcessResult {
    public let image: UIImage
    public let imageData: Data
    public let cost: TimeInterval
    public let imageType: ImageSourceResult.SourceType
    public let colorSpaceName: String?
    public let compressRatio: Float?
    public let compressAlgorithm: CompressAlgorithm?
    public init(image: UIImage, imageData: Data, imageType: ImageSourceResult.SourceType, cost: TimeInterval,
                colorSpaceName: String?, compressRatio: Float? = nil, compressAlgorithm: CompressAlgorithm? = nil) {
        self.image = image
        self.imageData = imageData
        self.cost = cost
        self.colorSpaceName = colorSpaceName
        self.imageType = imageType
        self.compressRatio = compressRatio
        self.compressAlgorithm = compressAlgorithm
    }
}

public enum ProcessImageError: Int {
    case generateDestination = 10_000
    case createImageSource = 10_001
    case createImage = 10_002
    case createCGImage = 10_003
    case webpEncoder = 10_004
    case webpResultDataSize = 10_005
    case getCGImage = 10_006
    case fileSizeIncreased = 10_007
    case compressQualityAlreadySatisfied = 10_008
}

// 非原图压缩类型
// custom: 用户定制压缩参数
// default: 使用默认的压缩参数
enum ProcessCompressType {
    // int: 降采样后最长边的长度
    // float: 压缩比例
    case custom(Int, Float)
    case `default`
}

public struct ImageSourceResult {
    public typealias SourceType = ImageFileFormat

    public var data: Data?
    public var image: UIImage?
    // 为了跟之前兼容保留
    public var isGif: Bool {
        return sourceType == .gif
    }
    public var compressCost: TimeInterval?
    // 图片压缩比例，图片埋点上报使用
    public let compressRatio: Float?
    // 图片的压缩算法
    public let compressAlgorithm: String?
    public var sourceType: SourceType = .unknown
    public var colorSpaceName: String?

    public init(sourceType: SourceType,
                data: Data?, image: UIImage?,
                compressCost: TimeInterval? = nil,
                colorSpaceName: String? = nil,
                compressRatio: Float? = nil,
                compressAlgorithm: String? = nil) {
        self.data = data
        self.image = image
        self.sourceType = sourceType
        self.compressCost = compressCost
        self.colorSpaceName = colorSpaceName
        self.compressRatio = compressRatio
        self.compressAlgorithm = compressAlgorithm
    }

    public init(imageProcessResult: ImageProcessResult?) {
        self.data = imageProcessResult?.imageData
        self.image = imageProcessResult?.image
        self.sourceType = imageProcessResult?.imageType ?? .unknown
        self.compressCost = imageProcessResult?.cost
        self.colorSpaceName = imageProcessResult?.colorSpaceName
        self.compressRatio = imageProcessResult?.compressRatio
        self.compressAlgorithm = imageProcessResult?.compressAlgorithm?.rawValue
    }
}

extension ImageSourceResult: Codable {
    enum CodingKeys: String, CodingKey {
        case data = "data"
        case compressCost = "compress_cost"
        case compressRatio = "compress_ratio"
        case compressAlgorithm = "compress_algorithm"
        case sourceType = "image_file_format"
        case colorSpaceName = "color_space_name"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
        try container.encode(compressCost, forKey: .compressCost)
        try container.encode(compressRatio, forKey: .compressRatio)
        try container.encode(compressAlgorithm, forKey: .compressAlgorithm)
        try container.encode(sourceType, forKey: .sourceType)
        try container.encode(colorSpaceName, forKey: .colorSpaceName)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try? container.decode(Data.self, forKey: .data)
        self.compressCost = try? container.decode(TimeInterval.self, forKey: .compressCost)
        self.compressRatio = try? container.decode(Float.self, forKey: .compressRatio)
        self.compressAlgorithm = try? container.decode(String.self, forKey: .compressAlgorithm)
        self.sourceType = try container.decode(SourceType.self, forKey: .sourceType)
        self.colorSpaceName = try? container.decode(String.self, forKey: .colorSpaceName)
        if let data {
            self.image = UIImage(data: data)
        }
    }
}

public struct ImageProcessOptions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    // swiftlint:disable operator_usage_whitespace

    /// 如果设置useOrigin，转码后的格式为原格式，不做修改
    public static let useOrigin            = ImageProcessOptions(rawValue: 1 << 0)
    /// 如果不设置useOrigin，转码格式优先为webp，如果失败，兜底转码为jpeg
    public static let needConvertToWebp    = ImageProcessOptions(rawValue: 1 << 1)
    /// 是否是来自密聊，决定允许发送的图片的格式的白名单的不同
    public static let isFromCrypto         = ImageProcessOptions(rawValue: 1 << 2)
    // swiftlint:enable operator_usage_whitespace
}

public protocol SendImageProcessor {
    // 压缩+转码
    func process(source: ImageProcessSourceType, option: ImageProcessOptions, scene: Scene) -> ImageProcessResult?
    /// destPixel 最大边的值， compressRate 0 - 1.0 太小的话可能压缩不到对应的压缩率
    func process(source: ImageProcessSourceType, destPixel: Int, compressRate: Float, scene: Scene) -> ImageProcessResult?
    // TODO: 目前此方法仅用于指定压缩参数的 WebP 压缩，等待重构
    func process(source: ImageProcessSourceType, options: ImageProcessOptions,
                 destPixel: Int, compressRate: Float, scene: Scene) -> ImageProcessResult?
}

public final class SendImageProcessorImpl: SendImageProcessor {

    @InjectedLazy var rustService: RustService
    static let logger = Logger.log(SendImageProcessorImpl.self, category: "LarkSendImageProcess")

    public init() { }

    // MARK: - Processes

    // 不定制压缩参数，获取图片和data
    public func process(source: ImageProcessSourceType, option: ImageProcessOptions, scene: Scene) -> ImageProcessResult? {
        if option.contains(.useOrigin) {
            return self.originProcess(source: source)
        } else {
            // 想要压缩转码为webp，并且成功
            if option.contains(.needConvertToWebp),
               let webpProcess = compressWebpProcess(source: source, compressType: .default, scene: scene) {
                return webpProcess
            }
            // 否则压缩转码为jpeg
            return compressProcess(source: source, compressType: .default, scene: scene)
        }
    }

    public func process(source: ImageProcessSourceType, destPixel: Int, compressRate: Float, scene: Scene) -> ImageProcessResult? {
        return compressProcess(source: source, compressType: .custom(destPixel, compressRate), scene: scene)
    }

    // TODO: 目前此方法仅用于指定压缩参数的 WebP 压缩，等待重构
    public func process(source: ImageProcessSourceType, options: ImageProcessOptions,
                        destPixel: Int, compressRate: Float, scene: Scene) -> ImageProcessResult? {
        if options.contains(.useOrigin) {
            return self.originProcess(source: source)
        } else {
            if options.contains(.needConvertToWebp),
               let webpProcess = compressWebpProcess(source: source, compressType: .custom(destPixel, compressRate), scene: scene) {
                return webpProcess
            }
            return compressProcess(source: source, compressType: .custom(destPixel, compressRate), scene: scene)
        }
    }

    // MARK: Internal

    private func compressWebpProcess(source: ImageProcessSourceType, compressType: ProcessCompressType, scene: Scene) -> ImageProcessResult? {
        let event = ImageProcessTrackerEvent(scene: scene)
        event.addSourceParams(input: source)
        event.wantToConvert = .webp
        let startTime = CACurrentMediaTime()
        let downSampleImage: CGImage
        let compressRate: Float
        let compressAlgorithm: CompressAlgorithm
        switch source {
        case .image(let image):
            SendImageProcessorImpl.logger.info("UniteSendImage source image \(image.size)")
            // 获取压缩比例、最长边大小、压缩算法
            let rate: Float?
            let thumbnailMaxPixelSize: CGFloat?
            let algorithm: CompressAlgorithm
            switch compressType {
            case .custom(let int, let float):
                rate = float
                let pixelSize = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
                thumbnailMaxPixelSize = self.thumbnailMaxPixelSize(pixelSize, limit: CGFloat(int))
                algorithm = .native
            case .default:
                (rate, thumbnailMaxPixelSize, algorithm) = getCompressQualityAndThumbMaxPixelSide(
                    source: source,
                    imageSize: CGSize(width: image.size.width, height: image.size.height))
            }
            compressRate = rate ?? 1
            compressAlgorithm = algorithm
            // 如果需要降采样
            if let finalLongSide = thumbnailMaxPixelSize {
                SendImageProcessorImpl.logger.info("UniteSendImage get max pixel size \(finalLongSide)")
                // 计算出最终降采样的CGSize
                let finalSize: CGSize
                let proportion = image.size.width / image.size.height
                if proportion >= 1 {
                    finalSize = CGSize(width: finalLongSide, height: finalLongSide / proportion)
                } else {
                    finalSize = CGSize(width: finalLongSide * proportion, height: finalLongSide)
                }
                // 通过Render画出一个降采样的图片
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                let render = UIGraphicsImageRenderer(size: finalSize, format: format)
                let newImage = render.image { (_) in
                    image.draw(in: CGRect(origin: .zero, size: finalSize))
                }
                guard let cgImage = newImage.cgImage else {
                    SendImageProcessorImpl.logger.error("UniteSendImage webp can not get cgImage")
                    event.errorCode = ProcessImageError.getCGImage.rawValue
                    ImageProcessTracker.send(event: event)
                    return nil
                }
                downSampleImage = cgImage
            } else {
                // 不需要降采样，则直接返回CGImage
                guard let cgImage = image.cgImage else {
                    SendImageProcessorImpl.logger.error("UniteSendImage webp can not get cgImage")
                    event.errorCode = ProcessImageError.getCGImage.rawValue
                    ImageProcessTracker.send(event: event)
                    return nil
                }
                downSampleImage = cgImage
            }
        case .imageData(let data):
            // Data -> CGImageSource
            SendImageProcessorImpl.logger.info("UniteSendImage source data \(data.count)")
            guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
                SendImageProcessorImpl.logger.error("UniteSendImage get CGImageSource failed")
                event.errorCode = ProcessImageError.createImageSource.rawValue
                ImageProcessTracker.send(event: event)
                return nil
            }
            let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]
            let pixelWidth = imageProperties?[kCGImagePropertyPixelWidth] as? Int ?? 0
            let pixelHeight = imageProperties?[kCGImagePropertyPixelHeight] as? Int ?? 0
            // 获取压缩比例、最长边大小、压缩算法
            let rate: Float?
            let thumbnailMaxPixelSize: CGFloat?
            let algorithm: CompressAlgorithm
            switch compressType {
            case .custom(let int, let float):
                rate = float
                let pixelSize = CGSize(width: pixelWidth, height: pixelHeight)
                thumbnailMaxPixelSize = self.thumbnailMaxPixelSize(pixelSize, limit: CGFloat(int))
                algorithm = .native
            case .default:
                (rate, thumbnailMaxPixelSize, algorithm) = getCompressQualityAndThumbMaxPixelSide(
                    source: source,
                    imageSize: CGSize(width: pixelWidth, height: pixelHeight))
            }
            // TODO: 目前webp的开关是关闭状态，重新开启，需要调整这里
            compressRate = rate ?? 1
            compressAlgorithm = algorithm
            var downsampledDict: [AnyHashable: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                                       kCGImageSourceCreateThumbnailWithTransform: true,
                                                       kCGImagePropertyOrientation: CGImagePropertyOrientation.up,
                                                       kCGImageSourceShouldCache: false]
            if let thumbnailMaxPixelSize = thumbnailMaxPixelSize {
                downsampledDict[kCGImageSourceThumbnailMaxPixelSize] = thumbnailMaxPixelSize
            }
            // CGImageSource -> CGImage
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampledDict as CFDictionary) else {
                SendImageProcessorImpl.logger.error("UniteSendImage create cgImage failed")
                event.errorCode = ProcessImageError.createCGImage.rawValue
                ImageProcessTracker.send(event: event)
                return nil
            }
            downSampleImage = cgImage
        }
        // CGImage -> Data(webp格式)
        // compressRate返回的是0到1的数字，但webp接口为0到100
        SendImageProcessorImpl.logger.info("UniteSendImage success get cgImage")
        guard let finalData = WebP.Encoder.data(image: downSampleImage, quality: compressRate * 100), !finalData.isEmpty else {
            SendImageProcessorImpl.logger.error("UniteSendImage can not get webpData")
            event.errorCode = ProcessImageError.webpEncoder.rawValue
            ImageProcessTracker.send(event: event)
            return nil
        }
        if case .imageData(let data) = source, finalData.count > data.count {
            SendImageProcessorImpl.logger.error("UniteSendImage compressed size is larger than origin size")
            event.errorCode = ProcessImageError.webpResultDataSize.rawValue
            ImageProcessTracker.send(event: event)
            return nil
        }
        guard let finalImage = try? ByteImage(finalData) else {
            SendImageProcessorImpl.logger.error("UniteSendImage can not get uiImage")
            event.errorCode = ProcessImageError.createImage.rawValue
            ImageProcessTracker.send(event: event)
            return nil
        }
        let processResult = ImageProcessResult(
            image: finalImage,
            imageData: finalData,
            imageType: .webp,
            cost: CACurrentMediaTime() - startTime,
            colorSpaceName: downSampleImage.colorSpace?.name as? String,
            compressRatio: compressRate,
            compressAlgorithm: compressAlgorithm)
        SendImageProcessorImpl.logger.info("UniteSendImage success get webpData")
        event.addResultParams(result: processResult)
        ImageProcessTracker.send(event: event)
        return processResult
    }

    private func compressProcess(source: ImageProcessSourceType, compressType: ProcessCompressType, scene: Scene) -> ImageProcessResult? {
        // image_compress_dev埋点上报
        let event = ImageProcessTrackerEvent(scene: scene)
        event.addSourceParams(input: source)
        event.wantToConvert = .jpeg
        var imageSource: CGImageSource?
        switch source {
        case let .image(image):
            // 图片转成CGImageSource: UIImage -> CGImage -> Data -> CGImageSource
            imageSource = imageProcess(image: image, event: event)
        case let .imageData(data):
            // data转成CGImageSource
            imageSource = CGImageSourceCreateWithData(data as CFData, nil)
        }
        if let imageSource = imageSource {
            switch compressType {
            case .default:
                // 用户非定制情况下获取压缩比和降采样
                // 如果是image，那么直接计算
                // 如果是data，则调用sdk接口计算
                let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]
                let pixelWidth = imageProperties?[kCGImagePropertyPixelWidth] as? Int ?? 0
                let pixelHeight = imageProperties?[kCGImagePropertyPixelHeight] as? Int ?? 0
                let (compressRate, thumbnailMaxPixelSize, compressAlgorithm) = getCompressQualityAndThumbMaxPixelSide(
                    source: source, imageSize: CGSize(width: pixelWidth, height: pixelHeight), onlyGetParams: false)
                // compress为nil的前提之一是，thumbnailMaxPixelSize也为nil
                if let compressRate = compressRate {
                    // 通过ImageSource，拿到image和data
                    return procedureResult(source: source, imageSource: imageSource, compressedQuality: compressRate,
                                           thumbnailMaxPixelSize: thumbnailMaxPixelSize, event: event, compressAlgorithm: compressAlgorithm)
                } else if thumbnailMaxPixelSize != nil {
                    // compressRate是nil，但thumbnailMaxPixelSize不是nil。这种情况不应该存在
                    assertionFailure("please message kangsiwan@bytedance.com")
                    return procedureResult(source: source, imageSource: imageSource, compressedQuality: 1,
                                           thumbnailMaxPixelSize: thumbnailMaxPixelSize, event: event, compressAlgorithm: compressAlgorithm)
                } else {
                    // 不用压缩，也不用降采样
                    event.errorCode = ProcessImageError.compressQualityAlreadySatisfied.rawValue
                    ImageProcessTracker.send(event: event)
                    return originProcess(source: source)
                }
            case .custom(let destPixel, let compressRate):
                // 用户定制，获取降采样的最大边的长度
                // 根据imageSource获取图片的宽高，再计算一次
                let thumbnailMaxPixelSize = customizeThumbMaxPixelSide(customPixel: destPixel, imageSource: imageSource)
                return procedureResult(source: source, imageSource: imageSource, compressedQuality: compressRate,
                                       thumbnailMaxPixelSize: thumbnailMaxPixelSize, event: event, compressAlgorithm: .native)
            }
        } else if event.errorCode != 0 {
            // 在这步之前已经报错过，直接返回
            // 因为image产生CGImage时也可能失败，已经报错
            return nil
        } else {
            SendImageProcessorImpl.logger.error("UniteSendImage image process create imageSource failed")
            event.errorCode = ProcessImageError.createImageSource.rawValue
            ImageProcessTracker.send(event: event)
            return nil
        }
    }

    // 通过拿到的CGImageSource，根据压缩比和降采样，得到image和data
    private func procedureResult(source: ImageProcessSourceType,
        imageSource: CGImageSource, compressedQuality: Float, thumbnailMaxPixelSize: CGFloat?,
        event: ImageProcessTrackerEvent, compressAlgorithm: CompressAlgorithm) -> ImageProcessResult? {
        var downsampledDict: [AnyHashable: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                                   kCGImageSourceCreateThumbnailWithTransform: true,
                                                   kCGImagePropertyOrientation: CGImagePropertyOrientation.up,
                                                   kCGImageSourceShouldCache: false]
        if let thumbnailMaxPixelSize = thumbnailMaxPixelSize {
            downsampledDict[kCGImageSourceThumbnailMaxPixelSize] = thumbnailMaxPixelSize
        }
        /*当compressedQuality传1时，预期是图片不压缩，大小不变。但实际发现，传1时，图片会变大。而传非1时，
        结果符合预期,此处compressedQuality为1时，不设置相关参数*/
        var compressDict: [CFString: Any] = [:]
        if compressedQuality != 1 {
            compressDict[kCGImageDestinationLossyCompressionQuality] = compressedQuality
        }
        let downsampleData = NSMutableData()
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampledDict as CFDictionary),
                let dest = CGImageDestinationCreateWithData(downsampleData, kUTTypeJPEG, 1, nil)
        else {
            SendImageProcessorImpl.logger.error("UniteSendImage image process create CGImage failed")
            event.errorCode = ProcessImageError.createCGImage.rawValue
            ImageProcessTracker.send(event: event)
            return nil
        }
        CGImageDestinationAddImage(dest, cgImage, compressDict as CFDictionary)
        CGImageDestinationFinalize(dest)
        let data = downsampleData as Data
        guard let processImage = UIImage(data: data) else {
            SendImageProcessorImpl.logger.error("UniteSendImage image process create image failed")
            event.errorCode = ProcessImageError.createImage.rawValue
            ImageProcessTracker.send(event: event)
            return nil
        }
        if useSourceData(compressData: data, source: source) {
            event.errorCode = ProcessImageError.fileSizeIncreased.rawValue
            ImageProcessTracker.send(event: event)
            return originProcess(source: source)
        }
        let processResult = ImageProcessResult(image: processImage,
                                               imageData: data,
                                               imageType: .jpeg,
                                               cost: CACurrentMediaTime() - event.start,
                                               colorSpaceName: cgImage.colorSpace?.name as? String,
                                               compressRatio: compressedQuality,
                                               compressAlgorithm: compressAlgorithm)
        event.addResultParams(result: processResult)
        ImageProcessTracker.send(event: event)
        SendImageProcessorImpl.logger.info("UniteSendImage image procedure success \(data.count) \(processImage.size) \(compressedQuality) \(compressAlgorithm)")
        return processResult
    }

    // 非原图处理图片
    private func imageProcess(image: UIImage, event: ImageProcessTrackerEvent) -> CGImageSource? {
        // UIImage -> CGImage -> Data -> CGImageSource
        let newData = NSMutableData()
        guard let cgImage = image.cgImage,
              let dest = CGImageDestinationCreateWithData(newData as CFMutableData, kUTTypeJPEG, 1, nil)
        else {
            SendImageProcessorImpl.logger.error("UniteSendImage image process generate destination fail")
            event.errorCode = ProcessImageError.generateDestination.rawValue
            ImageProcessTracker.send(event: event)
            return nil
        }
        SendImageProcessorImpl.logger.info("UniteSendImage image process generate destination success")
        let dic: [AnyHashable: Any] = [kCGImagePropertyOrientation: self.transform(imageOrientation: image.imageOrientation).rawValue]
        CGImageDestinationAddImage(dest, cgImage, dic as CFDictionary)
        CGImageDestinationFinalize(dest)
        return CGImageSourceCreateWithData(newData, nil)
    }

    // 原图处理数据
    private func originProcess(source: ImageProcessSourceType) -> ImageProcessResult? {
        let start = CACurrentMediaTime()
        switch source {
        case let .image(image):
            let imageData: Data
            let imageType: ImageSourceResult.SourceType
            if let jpgData = image.jpegData(compressionQuality: Constants.standardJpegQuality) { // TODO: 这个几乎必取到，是否改成 containsAlpha
                imageData = jpgData
                imageType = .jpeg
            } else if let pngData = image.pngData() {
                imageData = pngData
                imageType = .png
            } else {
                SendImageProcessorImpl.logger.error("UniteSendImage process image to data error \(image.size)")
                return nil
            }
            SendImageProcessorImpl.logger.info("UniteSendImage procedure origin image \(imageData.count)")
            return ImageProcessResult(image: image,
                                      imageData: imageData,
                                      imageType: imageType,
                                      cost: CACurrentMediaTime() - start,
                                      colorSpaceName: image.cgImage?.colorSpace as? String,
                                      compressRatio: nil,
                                      compressAlgorithm: .noCompress)
        case let .imageData(data):
            do {
                // 会自动将data降采样
                let image = try ByteImage(data, decodeForDisplay: true)
                return ImageProcessResult(image: image,
                                          imageData: data,
                                          imageType: image.bt.imageFileFormat ,
                                          cost: CACurrentMediaTime() - start,
                                          colorSpaceName: image.bt.colorSpaceName,
                                          compressRatio: nil,
                                          compressAlgorithm: .noCompress)
            } catch {
                SendImageProcessorImpl.logger.error("UniteSendImage process data to image error", error: error)
            }
        }
        return nil
    }

    // MARK: - Utils

    // 用户非指定，则获取压缩比例和降采样
    // onlyGetParams: 为true，只获取SDK的值，webp格式需要；为false，和当前图片的压缩比例比较，取和合理的值
    private func getCompressQualityAndThumbMaxPixelSide(source: ImageProcessSourceType, imageSize: CGSize, onlyGetParams: Bool = true) -> (Float?, CGFloat?, CompressAlgorithm) {
        var targetCompressQuality: Float? = 1
        var thumbMaxPixel: CGFloat?
        var compressAlgorithm: CompressAlgorithm = .native
        let thumbnailLimitSize: CGFloat = 1080
        switch source {
        case .image:
            // 如果是图片，直接计算
            compressAlgorithm = .native
            targetCompressQuality = self.compressedQuality(imageSize)
            thumbMaxPixel = self.thumbnailMaxPixelSize(imageSize, limit: thumbnailLimitSize)
        case .imageData(let data):
            // 如果是data，通过sdk获取压缩比，获取不到走兜底
            // 获取jpegData的压缩比
            // 返回值在0到100，返回nil的可能是此data不是jpegData
            let quality: Int? = onlyGetParams ? nil : getJPEGQuality(data)
            let currentQuality: Float? = transformCompressQuality(Int32(quality ?? -1))
            // 通过SDK获取压缩比
            if let params = try? getImageCompressParameters(count: Int64(data.count), size: CGSize(width: imageSize.width, height: imageSize.height), quality: quality) {
                compressAlgorithm = .sdk
                targetCompressQuality = transformCompressQuality(params.quality) ?? 1
                thumbMaxPixel = self.thumbnailMaxPixelSize(CGSize(width: imageSize.width, height: imageSize.height), limit: CGFloat(params.shortSide))
                SendImageProcessorImpl.logger.info("UniteSendImage imageCompress params \(String(describing: quality)) \(params.quality) \(params.shortSide) \(imageSize.width) \(imageSize.height)")
            } else {
                // 走兜底方案
                SendImageProcessorImpl.logger.warn("UniteSendImage no image parameters")
                compressAlgorithm = .native
                targetCompressQuality = self.compressedQuality(CGSize(width: imageSize.width, height: imageSize.height))
                thumbMaxPixel = self.thumbnailMaxPixelSize(CGSize(width: imageSize.width, height: imageSize.height), limit: thumbnailLimitSize)
            }
            // 调用方需要比较当前压缩比例，并且setting开启“可以跳过压缩步骤”
            if !onlyGetParams, LarkImageService.shared.imageUploadSetting.useSourceDataConfig.enableNotCompress {
                // 如果图片目前压缩比例已经比目标值小，并且图片不用降采样，那么也不用再压缩了
                if let current = currentQuality, thumbMaxPixel == nil, let target = targetCompressQuality, target >= current {
                    targetCompressQuality = nil
                    compressAlgorithm = .noCompress
                }
            } else {
                // 可以获取到当前压缩比例，并且当前压缩值比目标值压缩值小。那么按照低压缩比例
                if let current = currentQuality, let target = targetCompressQuality, target > current {
                    targetCompressQuality = current
                    compressAlgorithm = .native
                }
            }
        }
        SendImageProcessorImpl.logger.info("UniteSendImage compressQuality \(String(describing: targetCompressQuality)) maxPixel \(String(describing: thumbMaxPixel)) \(compressAlgorithm)")
        return (targetCompressQuality, thumbMaxPixel, compressAlgorithm)
    }

    // 用户指定，获取降采样的最大边的长度
    // 如果customPixel为0，则不降采样
    private func customizeThumbMaxPixelSide(customPixel: Int, imageSource: CGImageSource) -> CGFloat? {
        guard let imageDic = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let width = imageDic[kCGImagePropertyPixelWidth] as? Int,
              let height = imageDic[kCGImagePropertyPixelHeight] as? Int,
              customPixel != 0
        else { return nil }
        return thumbnailMaxPixelSize(CGSize(width: width, height: height), limit: CGFloat(customPixel))
    }

    private func transform(imageOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .left: return .left
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        @unknown default:
            return .up
        }
    }

    // 压缩比例，宽高比越大，压缩越小
    private func compressedQuality(_ size: CGSize) -> Float {
        let width = size.width
        let height = size.height
        let ratio = max(width, height) / min(width, height)
        // disable-lint: magic number
        if ratio >= 10 {
            return 0.4
        } else if ratio < 10 && ratio >= 16 / 9.0 {
            return 0.4
        } else if ratio < 16 / 9.0 && ratio >= 4 / 3.0 {
            return 0.5
        } else {
            return 0.5
        }
        // enable-lint: magic number
    }

    // 缩略图的压缩比例, 算出长边的值
    private func thumbnailMaxPixelSize(_ size: CGSize, limit: CGFloat) -> CGFloat? {
        SendImageProcessorImpl.logger.info("UniteSendImage thumbnail \(size) \(limit)")
        let shortSide = min(size.width, size.height)
        let longSide = max(size.width, size.height)
        guard shortSide > limit else { return nil }
        return limit * (longSide / shortSide)
    }

    // 在测试中发现，把一张jpg图片按照0.5比例压缩，再次读取图片的压缩质量，恒等于78
    // 所以下面这张对应表，应该是和jpg格式强相关的。其他格式（如webp）不应该直接使用
    // 当前webp实验是关闭状态，如果需要再次打开，应该对这张表有一些调整
    private func transformCompressQuality(_ quality: Int32) -> Float? {
        // disable-lint: magic number
        switch quality {
        case 97...100: return 1
        case 95...97: return 0.9
        case 92...95: return 0.8
        case 87...92: return 0.7
        case 79...87: return 0.6
        case 65...78: return 0.5
        case 41...64: return 0.4
        case 31...40: return 0.3
        case 27...30: return 0.2
        case 21...26: return 0.1
        case 0...20: return 0
        default: return nil
        }
        // enable-lint: magic number
    }

    // sdk请求压缩比和降采样值
    func getImageCompressParameters(count: Int64, size: CGSize, quality: Int?) throws -> RustPB.Media_V1_GetImageCompressParametersResponse? {
        var request = RustPB.Media_V1_GetImageCompressParametersRequest()
        request.imageSize = count
        request.shortSide = Int32(min(size.width, size.height))
        request.longSide = Int32(max(size.width, size.height))
        if let quality = quality {
            request.quality = Int32(quality)
        }
        return try rustService.sendSyncRequest(request)
    }

    // 比较处理后的数据和处理前数据
    func useSourceData(compressData: Data, source: ImageProcessSourceType) -> Bool {
        // 如果输入是data，并且压缩后比压缩前体积大超过500K
        let useSourceDataConfig = LarkImageService.shared.imageUploadSetting.useSourceDataConfig
        guard useSourceDataConfig.enableCompare,
              case .imageData(let sourceData) = source,
              compressData.count > sourceData.count + useSourceDataConfig.increaseByte else { return false }
        // 如果压缩前，图片短边就比2000小，那就用压缩前
        if let imageSourceResult = CGImageSourceCreateWithData(sourceData as CFData, nil),
           let imageDic = CGImageSourceCopyPropertiesAtIndex(imageSourceResult, 0, nil) as? [CFString: Any],
           let width = imageDic[kCGImagePropertyPixelWidth] as? Int,
           let height = imageDic[kCGImagePropertyPixelHeight] as? Int,
           min(width, height) <= useSourceDataConfig.imageShortSide {
            return true
        }
        return false
    }
}
