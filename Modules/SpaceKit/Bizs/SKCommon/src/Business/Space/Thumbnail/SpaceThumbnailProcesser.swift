//
//  SpaceThumbnailProcesser.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/5/22.
//  

import UIKit
import Kingfisher
import SKUIKit
import SKFoundation
import SpaceInterface

public struct SpaceThumbnailProcesserResizeInfo {
    /// 给specialPlaceholder图片 resize 使用，空白图、删除图、无权限图、后台生成失败图等
    var targetSize: CGSize
    var imageInsets: UIEdgeInsets
    public init(targetSize: CGSize, imageInsets: UIEdgeInsets) {
        self.targetSize = targetSize
        self.imageInsets = imageInsets
    }
}

public protocol SpaceThumbnailProcesser {

    var resizeInfo: SpaceThumbnailProcesserResizeInfo? { get set }

    /// 存入缓存前执行
    func preProcess(image: UIImage) -> UIImage

    /// 每次从缓存取出后执行
    func process(image: UIImage) -> UIImage
}

extension SpaceThumbnailProcesser {

    typealias Thumbnail = SpaceThumbnailCache.Thumbnail

    public func preProcess(image: UIImage) -> UIImage {
        return image
    }

    public func resizeImage(_ image: UIImage) -> UIImage? {
        return nil
    }

    public func preProcessSpecialPlaceholder(image: UIImage) -> UIImage {
        let (isAvailable, targetSize, imageInsets) = checkResizeInfoIsAvailable()
        guard isAvailable else {
            return image
        }

        let newImage = resizeImage(image, targetSize: targetSize, imageInsets: imageInsets)

        return newImage
    }

    func resizeImage(_ image: UIImage, targetSize: CGSize, imageInsets: UIEdgeInsets) -> UIImage {
        var targetSize = targetSize
        if targetSize.width == 0 { targetSize.width = 1 }
        if targetSize.height == 0 { targetSize.height = 1 }
        let imageShowSize: CGSize = CGSize(width: targetSize.width - imageInsets.left - imageInsets.right,
                                           height: targetSize.height - imageInsets.top - imageInsets.bottom)

        let oriSize: CGSize = image.size
        let ws = oriSize.width / imageShowSize.width
        let hs = oriSize.height / imageShowSize.height
        var scale = max(ws, hs)
        if scale < 0.0001 { // CGFloat 和 Double 的 0 直接比较 ： scale == 0 可能会有问题，所以改成这种写法
            spaceAssertionFailure("scale 作为除数不能为0")
            scale = 1
        }
        let newTargetSize = CGSize(width: oriSize.width / scale, height: oriSize.height / scale)
        let x = (targetSize.width - newTargetSize.width) / 2.0
        let y = imageInsets.top
        let rect = CGRect(x: x, y: y, width: newTargetSize.width, height: newTargetSize.height)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, SKDisplay.scale)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()

        return newImage
    }

    public func process(image: UIImage) -> UIImage {
        return image
    }

    func preProcess(thumbnail: Thumbnail) -> Thumbnail {
        switch thumbnail.type {
        case let .thumbnail(image, etag):
            let proceedImage = preProcess(image: image)
            let result = Thumbnail(updatedTime: thumbnail.updatedTime,
                                   type: .thumbnail(image: proceedImage, etag: etag))
            return result
        case let .specialPlaceholder(image, etag):
            let proceedImage = preProcessSpecialPlaceholder(image: image)
            let result = Thumbnail(updatedTime: thumbnail.updatedTime,
                                   type: .specialPlaceholder(image: proceedImage, etag: etag))
            return result
        default:
            return thumbnail
        }
    }

    func process(thumbnail: Thumbnail) -> Thumbnail {
        switch thumbnail.type {
        case let .thumbnail(image, etag):
            let proceedImage = process(image: image)
            let result = Thumbnail(updatedTime: thumbnail.updatedTime,
                                   type: .thumbnail(image: proceedImage, etag: etag))
            return result
        default:
            return thumbnail
        }
    }

    fileprivate func checkResizeInfoIsAvailable() -> (Bool, CGSize, UIEdgeInsets) {
        guard let resizeInfoLocal = resizeInfo,
              resizeInfoLocal.targetSize.width > 0,
              resizeInfoLocal.targetSize.height > 0 else {
            return (false, .zero, .zero)
        }

        return (true, resizeInfoLocal.targetSize, resizeInfoLocal.imageInsets)
    }
}

public struct SpaceDefaultProcesser: SpaceThumbnailProcesser {
    public var resizeInfo: SpaceThumbnailProcesserResizeInfo?

    public init() { }
}

// 写入磁盘时，不进行裁剪，读取时才进行裁剪
// VC 展示 space 缩略图时，同一张图需要不同尺寸，用到这个 processer
public struct SpaceCropWhenReadProcesser: SpaceThumbnailProcesser {
    public var resizeInfo: SpaceThumbnailProcesserResizeInfo?

    let cropSize: CGSize

    public init(cropSize: CGSize) {
        self.cropSize = cropSize
    }

    public func process(image: UIImage) -> UIImage {
        guard cropSize.height != 0 else {
            assertionFailure("crop size height is zero")
            DocsLogger.error("crop size height is zero")
            return image
        }
        let cropRatio = cropSize.width / cropSize.height
        let croppedImage = image.docs.croppingMaxRectangle(origin: .zero, widthHeightRatio: cropRatio)
        let downsampledImage = croppedImage.docs.downsample(viewSize: cropSize)
        return downsampledImage
    }
}

public struct SpaceGridListProcesser: SpaceThumbnailProcesser {
    public var resizeInfo: SpaceThumbnailProcesserResizeInfo?

    let viewSize: CGSize

    // 网格视图的尺寸可能会发生变化，因此不在写入前进行处理，改为读取时处理
    public func process(image: UIImage) -> UIImage {
        let viewRatio = viewSize.width / viewSize.height
        let croppedImage = image.docs.croppingMaxRectangle(origin: .zero, widthHeightRatio: viewRatio)
        let downsampledImage = croppedImage.docs.downsample(viewSize: viewSize)
        return downsampledImage
    }

    public init(viewSize: CGSize, resizeInfo: SpaceThumbnailProcesserResizeInfo? = nil) {
        self.viewSize = viewSize
        self.resizeInfo = resizeInfo
    }
}

public struct SpaceListIconProcesser: SpaceThumbnailProcesser {
    public var resizeInfo: SpaceThumbnailProcesserResizeInfo?

    let viewSize = CGSize(width: 40, height: 40)

    public func preProcess(image: UIImage) -> UIImage {
        let size = image.size
        let croppedImage: UIImage
        let viewRatio = viewSize.width / viewSize.height
        let imageRatio = size.width / size.height
        if imageRatio >= viewRatio {
            // 宽图片截取图片中心的方形区域
            croppedImage = image.docs.croppingMaxCenterRectangle(widthHeightRatio: viewRatio)
        } else {
            // 长图片截取图片顶部的方形区域
            croppedImage = image.docs.croppingMaxRectangle(origin: .zero, widthHeightRatio: viewRatio)
        }
        let downsampledImage = croppedImage.docs.downsample(viewSize: viewSize)
        return downsampledImage
    }
    public init() {
        
    }
}

public struct SpaceRoundProcesser: SpaceThumbnailProcesser {
    public var resizeInfo: SpaceThumbnailProcesserResizeInfo?

    let diameter: CGFloat
    public init(diameter: CGFloat) {
        self.diameter = diameter
    }

    public func preProcess(image: UIImage) -> UIImage {
        let croppedImage = image.docs.croppingRoundCenterRectangle()
        return croppedImage
    }

    public func process(image: UIImage) -> UIImage {
        return image
    }
}

struct SpaceTemplateProcesserV2: SpaceThumbnailProcesser {
    var resizeInfo: SpaceThumbnailProcesserResizeInfo?

    let imageTargetSize: CGSize

    var isNeedScaleImage: Bool = false

    ///iPad模版item在非doc的情况下缩略图模糊
    ///需要把截取图片的大小乘以一定的系数，缩小截取的范围，提高图片清晰度
    var docsType: DocsType = .doc

    var downscaleForPad = false //针对pad做特化缩小处理

    func preProcess(image: UIImage) -> UIImage {
        if isNeedScaleImage {
            var ratio: CGFloat = 1
            if imageTargetSize.height > 0.001 {
                ratio = imageTargetSize.width / imageTargetSize.height
            }
            var size = image.docs.maxSizeForRectangle(origin: .zero, widthHeightRatio: ratio)
            let croppedImage = image.docs.croppingMaxRectangle(origin: .zero, widthHeightRatio: ratio)
            if SKDisplay.pad, downscaleForPad, docsType != .doc {
                size.width *= 0.6
                size.height *= 0.6
            }
            return croppedImage.docs.cropping(origin: .zero, size: size)
        }
        let imageSize: CGSize = imageTargetSize
        let viewRatio = imageSize.width / imageSize.height
        let croppedImage = image.docs.croppingMaxRectangle(origin: .zero, widthHeightRatio: viewRatio)
        return resizeImage(croppedImage, targetSize: imageSize, imageInsets: .zero)
    }
}

public struct SpaceTemplateBannerProcesser: SpaceThumbnailProcesser {
    public var resizeInfo: SpaceThumbnailProcesserResizeInfo?

    private let size: CGSize

    public init(size: CGSize) {
        self.size = size
    }

    public func preProcess(image: UIImage) -> UIImage {
        let widthHeightRatio = size.width / size.height
        let croppedImage = image.docs.croppingMaxRectangle(origin: .zero, widthHeightRatio: widthHeightRatio)
        return croppedImage.docs.downsample(viewSize: size)
    }
}
