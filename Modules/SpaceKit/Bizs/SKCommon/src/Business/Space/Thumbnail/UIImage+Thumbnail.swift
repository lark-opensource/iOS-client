//
//  UIImage+Thumbnail.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/5/22.
//  

import UIKit
import Kingfisher
import SKFoundation
import SKUIKit

extension DocsExtension where BaseType == UIImage {

    var actualImageSize: CGSize {
        if let realWidth = base.cgImage?.width,
           let realHeight = base.cgImage?.height {
            return CGSize(width: realWidth, height: realHeight)
        } else {
            return base.size
        }
    }

    // 裁剪图片中心的最大方形区域
//    0
//    func croppingMaxCenterSquare() -> UIImage {
//        return croppingMaxCenterRectangle(widthHeightRatio: 1)
//    }

    func croppingRoundCenterRectangle() -> UIImage {
        //取最短边长
        let shotest = min(base.size.width, base.size.height)
        //输出尺寸
        let outputRect = CGRect(x: 0, y: 0, width: shotest, height: shotest)
        //开始图片处理上下文（由于输出的图不会进行缩放，所以缩放因子等于屏幕的scale即可）
        var renderSize = outputRect.size
        if renderSize.width == 0 { renderSize.width = 1 }
        if renderSize.height == 0 { renderSize.height = 1 }
        UIGraphicsBeginImageContextWithOptions(renderSize, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }
        //添加圆形裁剪区域
        context.addEllipse(in: outputRect)
        context.clip()
        //绘制图片
        base.draw(in: outputRect)
        //获得处理后的图片
        let maskedImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return maskedImage
    }

    func croppingMaxCenterRectangle(widthHeightRatio: CGFloat) -> UIImage {
        let size = maxSizeForRectangle(origin: .zero, widthHeightRatio: widthHeightRatio)
        let imageSize = actualImageSize
        let origin = CGPoint(x: (imageSize.width - size.width) / 2,
                             y: (imageSize.height - size.height) / 2)
        return cropping(origin: origin, size: size)
    }

    // 裁剪从指定原点开始的最大方形区域
//    0
//    func croppingMaxSquare(origin: CGPoint) -> UIImage {
//        return croppingMaxRectangle(origin: origin, widthHeightRatio: 1)
//    }

    func croppingMaxRectangle(origin: CGPoint, widthHeightRatio: CGFloat) -> UIImage {
        let size = maxSizeForRectangle(origin: origin, widthHeightRatio: widthHeightRatio)
        return cropping(origin: origin, size: size)
    }

    public func maxSizeForRectangle(origin: CGPoint, widthHeightRatio: CGFloat) -> CGSize {
        let imageSize = actualImageSize
        let maxWidth = imageSize.width - origin.x
        let maxHeight = imageSize.height - origin.y
        let imageWidthHeightRatio = maxWidth / maxHeight
        let targetSize: CGSize
        if widthHeightRatio >= imageWidthHeightRatio {
            // 截取图片剩余区域的顶部
            let width = maxWidth
            let height = width / widthHeightRatio
            targetSize = CGSize(width: width, height: height)
        } else {
            // 截取图片剩余区域的左部
            let height = maxHeight
            let width = height * widthHeightRatio
            targetSize = CGSize(width: width, height: height)
        }
        return targetSize
    }

    /// origin 和 length 的单位是像素(pixel)，point 需要先乘上屏幕的缩放比例
//    0
//    func croppingSquare(origin: CGPoint, length: CGFloat) -> UIImage {
//        return cropping(origin: origin, size: CGSize(width: length, height: length))
//    }

    /// origin 和 length 的单位是像素(pixel)，point 需要先乘上屏幕的缩放比例，若传入的矩形区域和图片没有交集，会返回原图
    public func cropping(origin: CGPoint, size: CGSize) -> UIImage {
        guard let imageRef = base.cgImage else {
            DocsLogger.error("Failed to get cgImage when cropping image")
            return base
        }
        let cropZone = CGRect(origin: origin, size: size)
        guard let croppedImageRef = imageRef.cropping(to: cropZone) else {
            DocsLogger.error("Failed to get croppedImage when cropping image", extraInfo: ["originSize": actualImageSize, "cropSize": size, "cropOrigin": origin])
            return base
        }
        return UIImage(cgImage: croppedImageRef)
    }

    public func downsample(viewSize: CGSize) -> UIImage {
        guard let data = base.kf.data(format: .unknown) else {
            return base
        }
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            DocsLogger.error("CGImageSource create failed when down sample")
            return base
        }

        let scale = SKDisplay.scale
        let maxDimensionInPixels = max(viewSize.width, viewSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels] as CFDictionary
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            DocsLogger.error("downsample failed")
            return base
        }
        return UIImage(cgImage: downsampledImage, scale: scale, orientation: base.imageOrientation)
    }
}
