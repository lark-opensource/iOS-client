//
//  LabImageCrop.swift
//  ByteView
//
//  Created by wangpeiran on 2021/11/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import CoreServices
import ByteViewCommon
import ByteViewUI

class LabImageCrop {
    private static var imageScale: CGFloat = 3.0

    static let initializeOnce: Void = {
        Util.runInMainThread {
            LabImageCrop.imageScale = VCScene.displayScale
        }
    }()

    // MARK: 裁剪图片

    /// 裁剪缩略图
    static let defaultWidth: CGFloat = 640.0
    static let defaultHeight: CGFloat = 360.0
    static func cropThumbnailImageAt(path: String, thumbnailPath: IsoFilePath, service: MeetingBasicService) -> UIImage? {
        let absPath = service.storage.getAbsPath(absolutePath: path)
        guard absPath.fileExists(), let imageData = try? absPath.readData(options: .mappedIfSafe) else {//wpr todo
            Logger.lab.info("lab bg: crop failed: image not exist")
            return nil
        }
        guard let rawImage = UIImage(data: imageData as Data) else { return nil }
        if let image = cropImageToSizeNew(image: rawImage, imgData: imageData, targetRatio: 1) {
            _ = saveLabBgImage(image: image, savePath: thumbnailPath)
            return image
        } else {
            return nil
        }
    }

    /// 裁剪横竖屏图
    static func cropImageAt(info: VirtualBgModel, service: MeetingBasicService) -> Bool {
        let absPath = service.storage.getAbsPath(absolutePath: info.originPath)
        guard absPath.fileExists(), let imageData = try? absPath.readData(options: .mappedIfSafe) else { //wpr todo
            Logger.lab.info("lab bg: crop failed: image not exist, name \(info.name)")
            return false
        }
        guard let rawImage = UIImage(data: imageData as Data) else { return false }
        let originSize = rawImage.size
        Logger.lab.info("lab bg: Raw size is: \(originSize), name: \(info.name), path: \(info.originPath)")

        // 横屏
        let landscapePath: String = info.landscapePath
        if !FileManager.default.fileExists(atPath: landscapePath) { // 文件不存在
            let targetSize: CGSize = getCropSize(originSize: originSize, targetRatio: LabImageCrop.defaultWidth / LabImageCrop.defaultHeight)
            Logger.lab.info("lab bg: Landscape size is: \(targetSize)")

            if let image = cropImageToSizeNew(image: rawImage, imgData: imageData, targetRatio: LabImageCrop.defaultWidth / LabImageCrop.defaultHeight) {
                if !saveLabBgImage(image: image, savePath: info.landscapeIsoPath) {
                    return false
                }
            } else {
                return false
            }
        }

        // 竖屏
        let portraitPath: String = info.portraitPath
        if info.originPortraitPath.isEmpty { // 原始竖图不存在
            if !FileManager.default.fileExists(atPath: portraitPath) { // 裁剪完成的竖图不存在 就用横图裁剪
                let targetSize: CGSize = getCropSize(originSize: originSize, targetRatio: LabImageCrop.defaultHeight / LabImageCrop.defaultWidth)
                Logger.lab.info("lab bg: Portrait size is: \(targetSize)")

                if let image = cropImageToSizeNew(image: rawImage, imgData: imageData, targetRatio: LabImageCrop.defaultHeight / LabImageCrop.defaultWidth) {
                    if !saveLabBgImage(image: image, savePath: info.portraitIsoPath) {
                        return false
                    }
                } else {
                    return false
                }
            }
        } else { // settings
            let pAbsPath = service.storage.getAbsPath(absolutePath: info.originPortraitPath)
            guard pAbsPath.fileExists(), let pImageData = try? pAbsPath.readData(options: .mappedIfSafe) else { return false }//wpr todo
            guard let pRawImage = UIImage(data: pImageData as Data) else { return false }

            let targetSize: CGSize = getCropSize(originSize: originSize, targetRatio: LabImageCrop.defaultHeight / LabImageCrop.defaultWidth)
            Logger.lab.info("lab bg: Portrait size is: \(targetSize)")

            if let image = cropImageToSizeNew(image: pRawImage, imgData: pImageData, targetRatio: LabImageCrop.defaultHeight / LabImageCrop.defaultWidth) {
                if !saveLabBgImage(image: image, savePath: info.portraitIsoPath) {
                    return false
                }
            } else {
                return false
            }
        }

        Logger.lab.info("lab bg: Crop landscape and portrait success")
        return true
    }

    /// 具体裁剪方法
    static func cropImageToSizeNew(image: UIImage, imgData: Data, targetRatio: CGFloat) -> UIImage? {
        // 计算所需要图片的尺寸
        let originSize = image.size
        var size = self.getCropSize(originSize: originSize, targetRatio: targetRatio)
        if targetRatio == 1 {
            size = CGSize(width: 60 * Self.imageScale, height: 60 * Self.imageScale)
        }

        // 计算缩放尺寸
        let widthFactor = size.width / originSize.width
        let heightFactor = size.height / originSize.height
        let scaleFactor = widthFactor > heightFactor ? widthFactor : heightFactor
        let scaledWidth = originSize.width * scaleFactor
        let scaledHeight = originSize.height * scaleFactor

        Logger.lab.debug("lab bg: ratio \(scaledWidth) \(scaledHeight)")

        // 如果大小一样，不需要裁剪 直接返回
        if image.size.width == size.width && image.size.height == size.height {
            return image
        }

        // 降采样
        var croppingCGImage = image.cgImage
        // 降分辨率 降采样
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary   // 在创建对象时不解码图像（即true，在读取数据时就进行解码 为false 则在渲染时才进行解码）
        guard let imageSource = CGImageSourceCreateWithData(imgData as CFData, imageSourceOptions) else { // 用data因为并未decode,所占内存没那么大
            Logger.lab.error("lab bg: CGImageSource create failed")
            return nil
        }
        let maxPixelSize = max(scaledWidth, scaledHeight) // 可能会有浮点数，像素最好整数，如果要支持浮点数，需要额外设置kCGImageSourceShouldAllowFloat
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,   // 用原图产生缩略图
            kCGImageSourceShouldCacheImmediately: true,           // CreateThumbnailAtIndex必然会解码的，true是生成ImageIO的缓存，这个值对内存影响不大；开始下采样过程的那一刻解码图像；
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxPixelSize)] as CFDictionary // 指定最大的尺寸初一一个常量系数来缩放图片，同时保持原始的长宽比，
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            Logger.lab.error("lab bg: downsampledImage create failed")
            return nil
        }
        croppingCGImage = downsampledImage

        // 裁剪图片
        var drawRect = CGRect.init()
        drawRect.origin.x = (scaledWidth - size.width) / 2
        drawRect.origin.y = (scaledHeight - size.height) / 2
        drawRect.size.width = size.width
        drawRect.size.height = size.height

//        let imagenew = UIImage(cgImage: croppingCGImage!)
//        Logger.lab.debug("lab bg: ratio \(ratio) originSize \(originSize) targetSize \(size) drawRect \(drawRect) cropImage \(imagenew.size)")

        if let croppingCGImage = croppingCGImage {
            guard let newImageRef = croppingCGImage.cropping(to: drawRect) else { return nil }
            return UIImage(cgImage: newImageRef)
        } else {
            return nil
        }
    }

    // MARK: 辅助的私有方法

    /// 裁剪所需要的大小
    private static func getCropSize(originSize: CGSize, targetRatio: CGFloat) -> CGSize {
        let originRatio = originSize.width / originSize.height
        var size: CGSize = .zero
        if originRatio > targetRatio {
            size = CGSize(width: originSize.width * (targetRatio / originRatio), height: originSize.height)
        } else {
            size = CGSize(width: originSize.width, height: originSize.height * (originRatio / targetRatio))
        }
        // nolint-next-line: magic number
        let cropMaxWidth: CGFloat = Display.pad ? 1280.0 : LabImageCrop.defaultWidth
        if max(size.width, size.height) > cropMaxWidth {
            let ratio = max(size.width, size.height) / cropMaxWidth
            size = CGSize(width: size.width / ratio, height: size.height / ratio)
        }
        Logger.lab.debug("lab bg: originSize \(originSize) cropSize \(size)")
        return size
    }

    /// 保存图片 from image
    private static func saveLabBgImage(image: UIImage?, savePath: IsoFilePath) -> Bool {
        guard let image = image else { return false }
        if let data = self.UIImageIOToData(image: image, compressionRatio: 0.9) { // jpegData(compressionQuality: 0.9)
            do {
                try savePath.createFile(with: data, attributes: nil)
                Logger.lab.info("lab bg: save image success \(savePath)")
                return true
            } catch {
                Logger.lab.error("lab bg: save image failed: \(savePath)")
            }
        }
        return false
    }

    /// image to data
    private static func UIImageIOToData(image: UIImage, compressionRatio: CGFloat, orientation: Int = 1) -> Data? {
        return autoreleasepool(invoking: { () -> Data? in
            let data = NSMutableData()
            let options: NSDictionary = [
                kCGImagePropertyOrientation: orientation,
                kCGImagePropertyHasAlpha: true,
                kCGImageDestinationLossyCompressionQuality: compressionRatio
            ]

            guard let imageDestinationRef = CGImageDestinationCreateWithData(data as CFMutableData, kUTTypeJPEG, 1, nil),
                  let cgImage = image.cgImage else {
                return nil
            }
            CGImageDestinationAddImage(imageDestinationRef, cgImage, options)
            CGImageDestinationFinalize(imageDestinationRef)
            return data as Data
        })
    }
}
