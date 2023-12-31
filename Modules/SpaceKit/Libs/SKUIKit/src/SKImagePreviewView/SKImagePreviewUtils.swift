//
//  SKImagePreviewUtils.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/6/5.
//

import Foundation
import SKFoundation

public final class SKImagePreviewUtils {
    private static let defaultBitsPerPixel = 32
    /// 获取图片原大小(通过url)
    public static func originSizeOfImage(path: SKFilePath) -> CGSize? {
        return SKImagePreviewUtils.originSizeOfImage(path: path, data: nil)
    }
    /// 获取图片原大小(通过data)
    public static func originSizeOfImage(data: Data?) -> CGSize? {
        return SKImagePreviewUtils.originSizeOfImage(path: nil, data: data)
    }

    private static func originSizeOfImage(path: SKFilePath?, data: Data?) -> CGSize? {
        var imageSourceTemp: CGImageSource?
        if let path = path {
            imageSourceTemp = CGImageSourceCreateWithURL(path.pathURL as CFURL, nil)
        } else if let dataCf = data {
            imageSourceTemp = CGImageSourceCreateWithData(dataCf as CFData, nil)
        }

        guard let imageSource = imageSourceTemp,
            let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable: Any],
            let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? NSNumber,
            let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? NSNumber
            else {
                DocsLogger.warning("getImage meta data failed")
                return nil
        }
        var width: CGFloat = 0, height: CGFloat = 0, orientation: Int = 0
        let orientationNumber = imageProperties[kCGImagePropertyOrientation] as? NSNumber ?? 1 // default value is 1

        CFNumberGetValue(pixelWidth, .cgFloatType, &width)
        CFNumberGetValue(pixelHeight, .cgFloatType, &height)
        CFNumberGetValue(orientationNumber, .intType, &orientation)

        // Check orientation and flip size if required
        if orientation > 4 {
            let temp = width; width = height; height = temp
        }

        return CGSize(width: width, height: height)
    }

    /// 通过图片路径获取缩略图(通过url)
    public static func downsampleImage(path: SKFilePath, maxPixelSize: CGFloat) -> UIImage? {
        return SKImagePreviewUtils.downsampleImage(path: path, data: nil, maxPixelSize: maxPixelSize)
    }

    /// 通过图片路径获取缩略图(通过data)
    public static func downsampleImage(data: Data?, maxPixelSize: CGFloat) -> UIImage? {
        return SKImagePreviewUtils.downsampleImage(path: nil, data: data, maxPixelSize: maxPixelSize)
    }

    /// 通过图片路径获取缩略图
    private static func downsampleImage(path: SKFilePath?, data: Data?, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        var imageSourceTemp: CGImageSource?
        if let filePath = path {
            imageSourceTemp = CGImageSourceCreateWithURL(filePath.pathURL as CFURL, sourceOptions)
        } else if let dataCf = data {
            imageSourceTemp = CGImageSourceCreateWithData(dataCf as CFData, sourceOptions)
        }

        guard let source = imageSourceTemp else {
            DocsLogger.error("CGImageSourceCreateWithURL failed")
            return nil
        }
        let downsampleOptions = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                 kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
                                 kCGImageSourceShouldCacheImmediately: true,
                                 kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {
            DocsLogger.error("downsample failed")
            return nil
        }
        return  UIImage(cgImage: downsampledImage)
    }
    
    /// 如果图片解码后占用内存大小超出最大限制
    public static func imageOverSize(imagePath: SKFilePath) -> Bool {
        guard let size = originSizeOfImage(path: imagePath) else {
            DocsLogger.warning("image not found")
            return false
        }

        let originMemorySize = originImageMemorySize(of: size)
        let maxMemory = maxMemorySize()

        if originMemorySize > maxMemory {
            return true
        } else {
            return false
        }
    }

    // 设定最大的图片内存占用，计算出应该downsample的size
    public static func isOverSizeAndSampleSize(orignalSize: CGSize, maxMemoryBytes: Int) -> (Bool, CGSize) {
        let bytesPerPixel = CGFloat(defaultBitsPerPixel / 8)
        let orignalMemorySize: CGFloat = orignalSize.width * orignalSize.height * bytesPerPixel
        guard Int(orignalMemorySize) > maxMemoryBytes, maxMemoryBytes > 0 else {
            return (false, orignalSize)
        }
        let ratioSqrt: CGFloat = CGFloat(orignalMemorySize) / CGFloat(maxMemoryBytes)
        let ratio: CGFloat = sqrt(ratioSqrt)
        let targetSize = CGSize(width: Int(orignalSize.width / ratio), height: Int(orignalSize.height / ratio))
        return (true, targetSize)
    }
    
    /// 图片解码后占用内存大小
    private static func originImageMemorySize(of size: CGSize) -> CGFloat {
        let bytesPerPixel = CGFloat(defaultBitsPerPixel / 8)
        let decopressedMemory = size.width * size.height * bytesPerPixel
        return decopressedMemory
    }
    
    /// 图片size为设备屏幕大小4倍时的内存占用
    private static func maxMemorySize() -> CGFloat {
        let bytesPerPixel = defaultBitsPerPixel / 8
        let screenSize = SKDisplay.mainScreenBounds.size
        let scale = SKDisplay.scale
        let maxMemoryInBytes = screenSize.width * scale * screenSize.height * scale * CGFloat(bytesPerPixel) * 4
        return maxMemoryInBytes
    }
    
    /// 根据图片原始尺寸获取裁剪范围
    /// - Parameters:
    ///   - originalSize: 图片原始尺寸
    ///   - cropScale: 图片裁剪范围，元素值为裁剪的起始坐标和终止坐标的坐标值占图片宽高的比例
    public static func cropRect(cropScale: [CGFloat]?, originalSize: CGSize = .zero) -> (Bool, CGRect) {
        guard let cropScale, UserScopeNoChangeFG.LJW.cropImageViewEnable else { return (false, .zero) }
        guard cropScale.count == 4 else {
            DocsLogger.error("crop data wrong")
            return (false, .zero)
        }
        guard cropScale != Self.noCropScale else { return (false, .zero) }
        let origin = CGPoint(x: cropScale[0], y: cropScale[1])
        let end = CGPoint(x: cropScale[2], y: cropScale[3])
        let rectScale = CGRect(x: origin.x, y: origin.y, width: end.x - origin.x, height: end.y - origin.y)
        //判断裁剪范围是否超出图片
        guard CGRect(x: 0, y: 0, width: 1, height: 1).contains(rectScale) else {
            DocsLogger.error("cropRect out of range")
            return (false, .zero)
        }
        guard originalSize != .zero else { return (true, .zero) }
        let rect = CGRect(x: originalSize.width * rectScale.origin.x,
                          y: originalSize.height * rectScale.origin.y,
                          width: originalSize.width * rectScale.width,
                          height: originalSize.height * rectScale.height)
        return (true, rect)
    }
    
    public static let noCropScale:[CGFloat] = [0, 0, 1, 1]
    
}
