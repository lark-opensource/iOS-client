//
//  ImageDecodeBox.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/7/22.
//

import Foundation

/// 图片解码容器
public final class ImageDecodeBox {

    /// 图片格式
    public let format: ImageFileFormat

    internal let decoder: any ImageDecoder

    internal let data: Data

    private let decoderResource: ImageDecoderResource

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// 从 `Data` 初始化一个图片解码容器
    ///
    /// - Parameters:
    ///   - data: 图片数据
    ///   - needCrop: 是否需要分片解码
    /// - Note: 目前由于 `libttheif` 暂时不支持分片解码，所以初始化时需要
    /// 传入是否需要分片解码，在需要时切回系统解码器
    public init(_ data: Data, needCrop: Bool = false) throws {
        let format = data.bt.imageFileFormat
        let decoder: any ImageDecoder
        switch (needCrop, format) {
        case (true, .heic):
            decoder = HEIC.Decoder()
        case (true, .heif):
            decoder = HEIF.Decoder()
        default:
            decoder = try ImageDecoderFactory.decoder(for: format)
        }

        self.data = data
        self.format = format
        self.decoder = decoder
        self.decoderResource = try decoder.preprocess(data)

        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarning(_:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }

    public convenience init(filePath: String) throws {
        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)

        try self.init(data)
    }

    /// 是否为动图
    public var isAnimatedImage: Bool {
        decoder.isAnimatedImage(decoderResource)
    }

    /// 图片数量（动图帧数）
    public var imageCount: Int {
        decoder.imageCount(decoderResource)
    }

    /// 动图循环次数
    public var loopCount: Int {
        decoder.loopCount(decoderResource)
    }

    /// 图片大小尺寸
    public var pixelSize: CGSize {
        get throws {
            try decoder.pixelSize(decoderResource)
        }
    }

    /// 图片旋转方向
    public var orientation: UIImage.Orientation {
        get throws {
            try decoder.orientation(decoderResource)
        }
    }

    /// 修正旋转方向后的图片大小尺寸
    public var rotatedPixelSize: CGSize {
        get throws {
            let pixelSize = try pixelSize
            let orientation = try orientation
            switch orientation {
            case .right, .left, .rightMirrored, .leftMirrored:
                return CGSize(width: pixelSize.height, height: pixelSize.width)
            default:
                return pixelSize
            }
        }
    }

    /// 获取图片的某一帧
    ///
    /// 涉及到解码，建议在子线程调用
    public func image(at index: Int) throws -> CGImage {
        try decoder.image(decoderResource, at: index)
    }

    public func image(at index: Int, cropRect: CGRect, forceDecode: Bool = true) throws -> CGImage {
        decoder.config.cropRect = cropRect
        decoder.config.forceDecode = forceDecode
        return try image(at: index)
    }

    /// 获取图片某一帧的延迟（动图用）
    public func delay(at index: Int) throws -> TimeInterval {
        try decoder.delay(decoderResource, at: index)
    }

    @objc func didReceiveMemoryWarning(_ notification: Notification) {
        decoder.clearCacheIfNeeded(decoderResource)
    }
}
