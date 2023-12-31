//
//  ImageIODecoder.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/7/26.
//

import Foundation
import ImageIO

public protocol ImageIODecoder: ImageDecoder {

    /// 同步解码
    /// 提供开关做线上实验 Fix heif 解码 crash，https://bytedance.feishu.cn/docs/doccnEotnJ5JkfY0By8ISixE2md
    var needSync: Bool { get }
}

public protocol ImageIODecoderAnimatable {

    /// 信息键 - 字典
    var kImagePropertyDictionary: String { get }

    /// 信息键 - 延时(<50ms，调整为100ms)
    var kImagePropertyDelayTime: String { get }

    /// 信息键 - 宽松延时(无限制)
    var kImagePropertyUnclampedDelayTime: String { get }

    /// 信息键 - 循环次数
    var kImagePropertyLoopCount: String { get }
}

extension ImageIODecoder {

    public func preprocess(_ data: Data) throws -> ImageDecoderResource {
        guard let issrc = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw ImageError.Decoder.invalidData
        }
        let index = 0
        guard let propertiesData = CGImageSourceCopyPropertiesAtIndex(issrc, index, nil) as? [CFString: Any], let properties = ImageProperties(index, propertiesData) else {
            throw ImageError.Decoder.invalidImageProperties(index)
        }
        return .imageIO(issrc, properties)
    }

    public func image(_ res: Resources, at index: Int) throws -> CGImage {
        let (issrc, properties) = try getImageSource(res)
        return try DispatchImageQueue.sync {
            let isAnimatedImage = isAnimatedImage(res)
            let limitSize = Int(ImageManager.default.gifLimitSize)
            if isAnimatedImage,
               limitSize > 0,
               properties.pixelSize > limitSize {
                throw ImageError.Decoder.hugeAnimatedImage(properties.pixelSize)
            }

            let (downsample, undecodedImage) = try undecodedImage(issrc, index, properties)
            guard let undecodedImage = undecodedImage else {
                throw ImageError.Decoder.invalidIndex(index)
            }

            // 预解码策略
            // 1. 非降采样
            // 2. 配置需要预解码
            // 3. 内存空间足够
            guard !downsample,
                  config.forceDecode,
                  try ImageDecoderUtils.hasEnoughAvailableMemory(size: properties.pixelSize, format: imageFileFormat) else {
                return undecodedImage
            }
            let decodedImage: CGImage
            if needSync {
                objc_sync_enter(Self.self)
                decodedImage = ImageDecoderUtils.createDecodedCopy(undecodedImage, decodeForDisplay: true)
                objc_sync_exit(Self.self)
            } else {
                decodedImage = ImageDecoderUtils.createDecodedCopy(undecodedImage, decodeForDisplay: true)
            }
            return decodedImage
        }
    }

    func undecodedImage(_ issrc: CGImageSource, _ index: Int, _ properties: ImageProperties) throws -> (Bool, CGImage?) {
        return try autoreleasepool {
            let imageRect = CGRect(x: 0, y: 0, width: properties.pixelWidth, height: properties.pixelHeight)
            let needCrop = config.cropRect != .zero && imageRect.contains(config.cropRect)

            // 降采样策略
            // 以下情况不进行降采样
            // 1. 未正确指定降采样大小
            // 2. 像素总量未超过阈值
            let needDownsample: Bool = config.downsamplePixelSize > 0 && properties.pixelSize > config.downsamplePixelSize

            if needDownsample {
                try ImageDecoderUtils.hasEnoughAvailableMemory(size: config.downsamplePixelSize, format: imageFileFormat)
                let targetSize = ImageDecoderUtils.downsampleSize(for: imageRect.size,
                                                                  targetPixels: config.downsamplePixelSize)
                let maxTargetPixelSide = max(targetSize.width, targetSize.height)

                let needTransform = properties.orientation == .up

                let options: [CFString: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceThumbnailMaxPixelSize: Int(maxTargetPixelSide),
                    kCGImageSourceCreateThumbnailWithTransform: needTransform
                ]

                var image: CGImage?
                if needSync {
                    objc_sync_enter(Self.self)
                    image = CGImageSourceCreateThumbnailAtIndex(issrc, index, options as CFDictionary)
                    objc_sync_exit(Self.self)
                } else {
                    image = CGImageSourceCreateThumbnailAtIndex(issrc, index, options as CFDictionary)
                }
                if needCrop {
                    let sourceRect = config.cropRect
                    let accurateSizeRatio = targetSize.width / imageRect.width
                    let targetRect = CGRect(x: sourceRect.minX * accurateSizeRatio,
                                            y: sourceRect.minY * accurateSizeRatio,
                                            width: sourceRect.width * accurateSizeRatio,
                                            height: sourceRect.height * accurateSizeRatio)
                    // 不需要与 image.size 再 intersect，cropping 方法会做
                    image = image?.cropping(to: targetRect)
                }
                return (true, image)
            } else {
                let options: [CFString: Any] = [kCGImageSourceShouldCache: false]

                var image = CGImageSourceCreateImageAtIndex(issrc, index, options as CFDictionary)
                if needCrop {
                    image = image?.cropping(to: config.cropRect)
                }
                return (false, image)
            }
        }
    }

    public func delay(_ res: Resources, at index: Int) throws -> TimeInterval {
        let (issrc, _) = try getImageSource(res)

        let defaultDelay = 0.1
        guard let decoder = self as? ImageIODecoderAnimatable else {
            return defaultDelay
        }

        var delayTime: TimeInterval = 0
        if let properties = CGImageSourceCopyPropertiesAtIndex(issrc, index, nil) as? [String: Any],
           let info = properties[decoder.kImagePropertyDictionary] as? [String: Any] {
            delayTime = (info[decoder.kImagePropertyUnclampedDelayTime] as? TimeInterval) ?? (info[decoder.kImagePropertyDelayTime] as? TimeInterval) ?? 0
        }

        if delayTime < config.delayMinimum {
            delayTime = config.delayMinimum
        }

        // Many annoying ads specify a 0 duration to make an image flash as quickly as possible.
        // We follow Firefox's behavior and use a duration of 100 ms for any frames that specify
        // a duration of <= 10 ms. See <rdar://problem/7689300> and <http://webkit.org/b/36082>
        // for more information.
        let minDelayTime = 0.011
        if delayTime < minDelayTime {
            delayTime = defaultDelay
        }

        return delayTime
    }

    public func imageCount(_ res: Resources) -> Int {
        guard supportAnimation, let (issrc, _) = try? getImageSource(res) else {
            return 1
        }

        return CGImageSourceGetCount(issrc)
    }

    public func loopCount(_ res: Resources) -> Int {
        guard isAnimatedImage(res),
              let (issrc, _) = try? getImageSource(res),
              let propertiesData = CGImageSourceCopyPropertiesAtIndex(issrc, 0, nil) as? [String: Any],
              let decoder = self as? ImageIODecoderAnimatable,
              let imageDictionaries = propertiesData[decoder.kImagePropertyDictionary] as? [String: Any],
              let loopCount = imageDictionaries[decoder.kImagePropertyLoopCount] as? Int else {
            return 0
        }

        return loopCount
    }

    public func pixelSize(_ res: Resources) throws -> CGSize {
        let (_, properties) = try getImageSource(res)
        return CGSize(width: properties.pixelWidth, height: properties.pixelHeight)
    }

    public func orientation(_ res: Resources) throws -> UIImage.Orientation {
        let (_, properties) = try getImageSource(res)
        return ImageDecoderUtils.imageOrientation(from: properties.orientation)
    }

    public func clearCacheIfNeeded(_ resource: ImageDecoderResource) {
        guard let (issrc, _) = try? getImageSource(resource) else {
            return
        }
        for index in 0..<imageCount(resource) {
            CGImageSourceRemoveCacheAtIndex(issrc, index)
        }
    }

    private func getImageSource(_ res: Resources) throws -> (CGImageSource, ImageProperties) {
        guard case let .imageIO(issrc, properties) = res else {
            throw ImageError.Decoder.invalidData
        }
        return (issrc, properties)
    }
}

extension ImageIODecoder {

    public var needSync: Bool {
        false
    }

    public var kImagePropertyOrientation: String {
        kCGImagePropertyOrientation as String
    }
}

public struct ImageProperties {

    public let index: Int

    public let orientation: CGImagePropertyOrientation

    public let pixelWidth: Int

    public let pixelHeight: Int

    public var pixelSize: Int {
        pixelWidth * pixelHeight
    }

    public init?(_ index: Int, _ data: [CFString: Any]) {
        let orientation: CGImagePropertyOrientation = {
            guard let orientationValue = data[kCGImagePropertyOrientation] as? UInt32,
                  let orientation = CGImagePropertyOrientation(rawValue: orientationValue) else {
                return .up
            }
            return orientation
        }()
        guard let pixelWidth = data[kCGImagePropertyPixelWidth] as? Int,
              let pixelHeight = data[kCGImagePropertyPixelHeight] as? Int,
              pixelWidth != 0 || pixelHeight != 0 else {
            return nil
        }

        self.index = index
        self.orientation = orientation
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }
}
