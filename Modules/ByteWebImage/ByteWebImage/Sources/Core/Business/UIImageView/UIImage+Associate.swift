//
//  UIImage+Associate.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/22.
//

import Foundation

private enum AssociativeKey {

    static var dataCount = "AssociativeKey.DataCount"

    static var isDidScaleDown = "AssociativeKey.IsDidScaleDown"

    static var frameCount = "AssociativeKey.FrameCount"

    static var pixelSize = "AssociativeKey.PixelSize"

    static var destPixelSize = "AssociativeKey.DestPixelSize"

    static var colorSpaceName = "AssociativeKey.ColorSpaceName"

    static var requestKey = "AssociativeKey.RequestKey"

    static var loading = "AssociativeKey.Loading"

    static var webURL = "AssociativeKey.webURL"
}

extension ImageWrapper where Base: UIImage {

    /// 图片格式
    ///
    /// - Important: 只适用于 ByteImage，对普通 UIImage 不生效
    public var imageFileFormat: ImageFileFormat {
        (base as? ByteImage)?.imageFileFormat ?? .unknown
    }

    /// 数据长度
    public internal(set) var dataCount: Int {
        get {
            objc_getAssociatedObject(base, &AssociativeKey.dataCount) as? Int ?? 0
        }
        set {
            objc_setAssociatedObject(base, &AssociativeKey.dataCount, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 如果是gif图会保留原始data，如果非gif会读取image的data
    public var originData: Data? {
        if let gifData = (base as? ByteImage)?.animatedImageData {
            return gifData
        }
        guard let cgImage = base.cgImage else { return base.pngData() }
        let hasAlpha = ImageDecoderUtils.containsAlpha(cgImage)
        return hasAlpha ? base.pngData() : base.jpegData(compressionQuality: Constants.standardJpegQuality)
    }

    /// 是否为动图
    public var isAnimatedImage: Bool {
        return (base as? ByteImage)?.isAnimatedImage ?? false
    }

    /// 是否进行缩放
    public internal(set) var isDidScaleDown: Bool {
        get {
            objc_getAssociatedObject(base, &AssociativeKey.isDidScaleDown) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(base, &AssociativeKey.isDidScaleDown, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 空间占用大小
    public var cost: Int {
        var cost: Int = 1
        if let image = base as? ByteImage, let length = image.animatedImageData?.count {
            cost += length
        }
        guard let cgImage = base.cgImage else {
            return cost
        }
        cost += cgImage.height * cgImage.bytesPerRow
        return cost
    }

    /// 帧数
    public internal(set) var frameCount: Int {
        get {
            objc_getAssociatedObject(base, &AssociativeKey.frameCount) as? Int ?? 1
        }
        set {
            objc_setAssociatedObject(base, &AssociativeKey.frameCount, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 原始图像大小(像素)
    public internal(set) var pixelSize: CGSize {
        get {
            objc_getAssociatedObject(base, &AssociativeKey.pixelSize) as? CGSize ?? .zero
        }
        set {
            objc_setAssociatedObject(base, &AssociativeKey.pixelSize, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 处理后图像大小(像素)
    public internal(set) var destPixelSize: CGSize {
        get {
            objc_getAssociatedObject(base, &AssociativeKey.destPixelSize) as? CGSize ?? .zero
        }
        set {
            objc_setAssociatedObject(base, &AssociativeKey.destPixelSize, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 色彩空间
    public internal(set) var colorSpaceName: String? {
        get {
            objc_getAssociatedObject(base, &AssociativeKey.colorSpaceName) as? String ?? (base.cgImage?.colorSpace?.name as? String)
        }
        set {
            objc_setAssociatedObject(base, &AssociativeKey.colorSpaceName, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 请求键
    internal var requestKey: ImageRequestKey? {
        get {
            objc_getAssociatedObject(base, &AssociativeKey.requestKey) as? ImageRequestKey
        }
        set {
            objc_setAssociatedObject(base, &AssociativeKey.requestKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 加载状态
    internal var loading: Bool {
        get {
            objc_getAssociatedObject(base, &AssociativeKey.loading) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(base, &AssociativeKey.loading, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 图片URL
    public var webURL: URL? {
        get {
            objc_getAssociatedObject(base, &AssociativeKey.webURL) as? URL
        }
        set {
            objc_setAssociatedObject(base, &AssociativeKey.webURL, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension UIImage {
    /// 图片像素大小，单位 px
    public var pixelSize: CGSize {
        CGSize(width: size.width * scale, height: size.height * scale)
    }

    /// 图片像素宽度，单位 px
    public var pixelWidth: Double {
        size.width * scale
    }

    /// 图片像素高度，单位 px
    public var pixelHeight: Double {
        size.height * scale
    }
}
