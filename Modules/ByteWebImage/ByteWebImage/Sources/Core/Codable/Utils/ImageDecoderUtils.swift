//
//  ImageDecoderUtils.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/16.
//
//  Included OSS: SDWebImage
//  Copyright (c) Olivier Poitrey <rs@dailymotion.com>
//  spdx license identifier: MIT

import UIKit

public let kUTTypeHEICS = "public.heics" as CFString

// kCGImagePropertyAPNGLoopCount这些常量虽然API标记了iOS 8支持，在iOS 8系统库的头文件里定义了，但库的实现未定义，会导致符号未找到，直接使用真实的值
public let kImagePropertyAPNGUnclampedDelayTime = "UnclampedDelayTime"
public let kImagePropertyAPNGLoopCount = "LoopCount"
public let kImagePropertyAPNGDelayTime = "DelayTime"

public let kImagePropertyHEICSDictionary: String = "{HEICS}"
public let kImagePropertyHEICSDelayTime: String = "DelayTime"
public let kImagePropertyHEICSLoopCount: String = "LoopCount"
public let kImagePropertyHEICSUnclampedDelayTime: String = "UnclampedDelayTime"

public enum ImageDecoderUtils {

    static let kDestImageSizeMB: CGFloat = 60.0

    static let kBytesPerPixel: CGFloat = 4
    static let kBitsPerComponent: CGFloat = 8
    static let kSourceImageTileSizeMB: CGFloat = 20.0

    static let kBytesPerMB: CGFloat = 1024.0 * 1024.0
    static let kPixelsPerMB: CGFloat = kBytesPerMB / kBytesPerPixel
    static let kDestTotalPixels: CGFloat = kDestImageSizeMB * kPixelsPerMB
    static let kTileTotalPixels: CGFloat = kSourceImageTileSizeMB * kPixelsPerMB
    static let kDestSeemOverlap: CGFloat = 2.0

    /**
     获取共享的当前设备的ColorSpace
     */
    static let colorSpaceDeviceRGB: CGColorSpace? = {
        if  #available(iOS 9.0, *) {
            return CGColorSpace(name: CGColorSpace.sRGB)
        }
        return CGColorSpaceCreateDeviceRGB()
    }()

    /* kCGBitmapByteOrder32Host
     */
    static let kCGBitmapByteOrder32Host: CGBitmapInfo = {
        return (CFByteOrderGetCurrent() == BIG_ENDIAN) ? .byteOrder32Big : .byteOrder32Little
    }()

    public static func destImageSizeMB() -> CGFloat {
        return kDestImageSizeMB
    }

    public static func bytesPerPixel() -> CGFloat {
        return kBytesPerPixel
    }

    public static func bitsPerComponent() -> CGFloat {
        return kBitsPerComponent
    }

    public static func sourceImageTileSizeMB() -> CGFloat {
        return kSourceImageTileSizeMB
    }

    public static func bytesPerMB() -> CGFloat {
        return kBytesPerMB
    }

    public static func pixelsPerMB() -> CGFloat {
        return kPixelsPerMB
    }

    public static func destTotalPixels() -> CGFloat {
        return kDestTotalPixels
    }

    public static func tileTotalPixels() -> CGFloat {
        return kTileTotalPixels
    }

    public static func destSeemOverlap() -> CGFloat {
        return kDestSeemOverlap
    }

}
// swiftlint:disable identifier_name

/// 工具方法
public extension ImageDecoderUtils {

    static func imageByteAlign(size: size_t, alignment: size_t) -> size_t {
        return (size + (alignment - 1)) / alignment * alignment
    }

    /**
     EXIF方向转换到UIImage方向
     */
    static func imageOrientation(from exifOrientation: CGImagePropertyOrientation) -> UIImage.Orientation {
        switch exifOrientation {
        case .up:
            return .up
        case .upMirrored:
            return .upMirrored
        case .down:
            return .down
        case .downMirrored:
            return .downMirrored
        case .leftMirrored:
            return .leftMirrored
        case .right:
            return .right
        case .rightMirrored:
            return .rightMirrored
        case .left:
            return .left
        default:
            return .up
        }
    }

    static func deviceBitmapInfo(hasAlpha: Bool) -> CGBitmapInfo {
        // 大端模式和小端模式区分
        var bitmapInfo = kCGBitmapByteOrder32Host
        if hasAlpha {
            // kCGImageAlphaPremultipliedFirst
            bitmapInfo = bitmapInfo.union(CGBitmapInfo(rawValue: 2))
        } else {
            // kCGImageAlphaNoneSkipFirst
            bitmapInfo = bitmapInfo.union(CGBitmapInfo(rawValue: 6))
        }
        return bitmapInfo
    }

    static func containsAlpha(_ sourceImage: CGImage?) -> Bool {
        guard let alphaInfo = sourceImage?.alphaInfo else { return false }
        switch alphaInfo {
        case .none, .noneSkipLast, .noneSkipFirst:
            return false
        default:
            return true
        }
    }
}

/// 图片处理相关
public extension ImageDecoderUtils {

    /**
     解码且保证GPU支持的bitmap格式
     */
    static func createDecodedCopy(_ sourceImage: CGImage, decodeForDisplay: Bool) -> CGImage {
        let image = autoreleasepool { () -> CGImage in
            let width = sourceImage.width
            let height = sourceImage.height
            guard width * height > 0,
                  let colorSpaceDeviceRGB = ImageDecoderUtils.colorSpaceDeviceRGB
            else { return sourceImage }
            if decodeForDisplay {
                // iOS display alpha info (BGRA8888/BGRX8888)
                let bitmapInfo = ImageDecoderUtils.deviceBitmapInfo(hasAlpha: ImageDecoderUtils.containsAlpha(sourceImage))
                guard let context = CGContext(data: nil,
                                              width: width,
                                              height: height,
                                              bitsPerComponent: 8,
                                              bytesPerRow: 0,
                                              space: colorSpaceDeviceRGB,
                                              bitmapInfo: bitmapInfo.rawValue)
                else { return sourceImage }
                // 解码
                context.draw(sourceImage, in: CGRect(x: 0, y: 0, width: width, height: height))
                guard let destImage = context.makeImage() else { return sourceImage }
                return destImage
            } else {
                // 惰性解码
                guard let dataProvider = sourceImage.dataProvider,
                      let space = sourceImage.colorSpace,
                      let data = dataProvider.data,
                      let newProvider = CGDataProvider(data: data)
                else { return sourceImage }
                let bitmapInfo = sourceImage.bitmapInfo
                let bitsPerPixel = sourceImage.bitsPerPixel
                let bitsPerComponent = sourceImage.bitsPerComponent
                let bytesPerRow = sourceImage.bytesPerRow
                guard let newImage = CGImage(width: width,
                                             height: height,
                                             bitsPerComponent: bitsPerComponent,
                                             bitsPerPixel: bitsPerPixel,
                                             bytesPerRow: bytesPerRow,
                                             space: space,
                                             bitmapInfo: bitmapInfo,
                                             provider: newProvider,
                                             decode: nil,
                                             shouldInterpolate: false,
                                             intent: .defaultIntent)
                else {
                    return sourceImage
                }
                return newImage
            }
        }
        return image
    }
}

extension ImageDecoderUtils {
    
    /// 计算降采样后的预期大小
    /// - Parameters:
    ///   - originSize: 原图大小
    ///   - targetPixels: 降采样宽高乘积上限限制
    /// - Returns: 保持原图片宽高比的目标降采样大小，已取整。可以保证 w x h <= targetPixels
    public static func downsampleSize(for originSize: CGSize, targetPixels: Int) -> CGSize {
        // 通过较小边取整缩放，减少整体图片宽高比差异变化
        let sideRatio = sqrt(Double(targetPixels) / (originSize.width * originSize.height))
        guard sideRatio < 1 else {
            return originSize
        }
        let shortSidePixels = min(originSize.width, originSize.height)
        let longerSidePixels = max(originSize.width, originSize.height)
        let minPixelSize = floor(shortSidePixels * sideRatio)
        let maxPixelSize = floor(minPixelSize * longerSidePixels / shortSidePixels)
        if originSize.width > originSize.height {
            return CGSize(width: maxPixelSize, height: minPixelSize)
        } else {
            return CGSize(width: minPixelSize, height: maxPixelSize)
        }
    }
}

extension ImageDecoderUtils {
    
    /// 计算有旋转信息的图片中，rect 对应的原始 rect
    ///
    /// 一般用于裁剪计算
    /// - Parameters:
    ///   - rect: orientation 为 .up 时，图片中的区域位置
    ///   - size: 未经旋转的图片原大小。一般 UIImage 通过 UIImage.cgImage.size 取得；data 通过 data.bt.imageSize 取得
    ///   - orientation: 图片旋转信息
    /// - Returns: orientation 为传入的 orientation 时，对应的区域位置
    public static func rawRect(of rect: CGRect, in size: CGSize, orientation: UIImage.Orientation) -> CGRect {
        let imageSize: CGSize
        switch orientation {
        case .right, .left, .rightMirrored, .leftMirrored:
            imageSize = CGSize(width: size.height, height: size.width)
        default:
            imageSize = size
        }
        switch orientation {
        case .right:
            return CGRect(x: rect.minY,
                          y: imageSize.width - rect.maxX,
                          width: rect.height, height: rect.width)
        case .rightMirrored:
            return CGRect(x: imageSize.height - rect.maxY,
                          y: imageSize.width - rect.maxX,
                          width: rect.height, height: rect.width)
        case .left:
            return CGRect(x: imageSize.height - rect.maxY,
                          y: rect.minX,
                          width: rect.height, height: rect.width)
        case .leftMirrored:
            return CGRect(x: rect.minY,
                          y: rect.minX,
                          width: rect.height, height: rect.width)
        case .down:
            return CGRect(x: imageSize.width - rect.maxX,
                          y: imageSize.height - rect.maxY,
                          width: rect.width, height: rect.height)
        case .downMirrored:
            return CGRect(x: rect.minX,
                          y: imageSize.height - rect.maxY,
                          width: rect.width, height: rect.height)
        case .up:
            return rect
        case .upMirrored:
            return CGRect(x: imageSize.width - rect.maxX,
                          y: rect.minY,
                          width: rect.width, height: rect.height)
        @unknown default:
            assertionFailure("should cover all cases")
            return rect
        }
    }
}

extension ImageDecoderUtils {

    @discardableResult
    static func hasEnoughAvailableMemory(size: Int, format: ImageFileFormat) throws -> Bool {
        let factor = ImageManager.default.skipDecodeMemoryFactor(of: format)
        guard factor != 0 else {
            return true
        }

        let availableSize = Double(DeviceMemory.availableSize)
        if availableSize <= Double(size) * factor {
            throw ImageError.Decoder.insufficientMemory(availableSize, size)
        }
        return true
    }
}

extension ImageManager {
    func skipDecodeMemoryFactor(of format: ImageFileFormat) -> Double {
        if format == .gif {
            return skipDecodeGIFMemoryFactor
        } else {
            return skipDecodeIMGMemoryFactor
        }
    }
}

public final class ImageDecoderUtilsBridge: NSObject {

    @objc public static func bitsPerComponent() -> CGFloat {
        ImageDecoderUtils.bitsPerComponent()
    }

    @objc public static func destTotalPixels() -> CGFloat {
        ImageDecoderUtils.destTotalPixels()
    }

    @objc public static func tileTotalPixels() -> CGFloat {
        ImageDecoderUtils.tileTotalPixels()
    }

    @objc public static func destSeemOverlap() -> CGFloat {
        ImageDecoderUtils.destSeemOverlap()
    }

    @objc public class func imageByteAlign(size: size_t, alignment: size_t) -> size_t {
        ImageDecoderUtils.imageByteAlign(size: size, alignment: alignment)
    }

    @objc public static func forbiddenWebPPartial() -> Bool {
        ImageConfiguration.forbiddenWebPPartial
    }

    @objc public static func downsampleSize(for originSize: CGSize, targetPixels: Int) -> CGSize {
        ImageDecoderUtils.downsampleSize(for: originSize, targetPixels: targetPixels)
    }
}
