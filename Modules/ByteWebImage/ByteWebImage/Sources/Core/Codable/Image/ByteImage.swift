//
//  ByteImage.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/3/16.
//

import UIKit

public struct AnimateImageFrame {
    var image: UIImage
    var index: UInt
    var delay: TimeInterval
    var nextFrameTime: TimeInterval = 0
}

protocol ByteImageInnerProtocol {

    var animatedImageData: Data? { get }
    var isAnimatedImage: Bool { get }
    var frameCount: UInt { get }

    var isAllFramesLoaded: Bool { get }
    var loopCount: UInt { get }
    var frameCache: [AnimateImageFrame] { get }
    var allFramesDuration: TimeInterval? { get }

    func frame(at index: Int, scale: CGFloat, orientation: UIImage.Orientation) -> AnimateImageFrame?
    func changeImage(with data: Data?)
    func preLoadAllFrames(scale: CGFloat, orientation: UIImage.Orientation)
}

/// 图片容器，对解码流程、动图、超大图有针对性优化
///
/// 和 ByteImage 相关的内部详细步骤和注意事项，参见文档 <doc:Decode>、<doc:Render>。
public final class ByteImage: UIImage {

    private var innerImage: ByteImageInnerProtocol?

    private(set) var imageFileFormat: ImageFileFormat = .unknown

    /// If the image is created from animated image data (multi-frame GIF/APNG/WebP), this property stores the original image data.
    public var animatedImageData: Data? {
        innerImage?.animatedImageData
    }
    public var isAnimatedImage: Bool {
        innerImage?.isAnimatedImage ?? false
    }
    public var frameCount: UInt {
        innerImage?.frameCount ?? 1
    }

    var loopCount: UInt? {
        innerImage?.loopCount
    }

    private(set) var enableAnimatedDownsample: Bool = false

    // MARK: - Public
    public func frame(at index: Int) -> AnimateImageFrame? {
        innerImage?.frame(at: index, scale: self.scale, orientation: self.imageOrientation)
    }

    public func changeImage(with data: Data?) {
        innerImage?.changeImage(with: data)
    }

    public func preLoadAllFrames() {
        innerImage?.preLoadAllFrames(scale: self.scale, orientation: self.imageOrientation)
    }

    // MARK: - Override
    public override var images: [UIImage]? {
        guard innerImage?.isAllFramesLoaded ?? false else {
            return nil
        }
        return innerImage?.frameCache.map { $0.image }
    }

    public override var duration: TimeInterval {
        innerImage?.allFramesDuration ?? 0
    }

    public override var description: String {
        "\(super.description); scale = \(scale); frameCount = \(frameCount);" +
        " format = \(imageFileFormat); imageURL = \(self.bt.webURL?.absoluteString ?? "nil")"
    }
}

extension ByteImage {

    /// 从 Data 初始化 ByteImage，线程安全，方法耗时，避免在主线程调用
    ///
    /// 如果是静图，内部会先判断 `Data` 的格式类型，找到对应的解码器，解码出 `Bitmap(CGImage)`，再从 `CGImage` 初始化 `ByteImage`。
    /// 如果是动图，内部会解码出第一帧 `CGImage`，``ByteImageView`` 播放时会调用 ``ByteImage/frame(at:)`` 方法依次解码对应帧。
    /// - Parameters:
    ///   - data: 图片源文件数据，支持 ImageIO 支持的格式 + WebP 格式
    ///   - scale: 图片缩放，用于设置 ByteImage.scale，默认为 UIScreen.main.scale
    ///   - decode: 是否提前预解码，从而避免在上屏时才解码，默认为 true
    ///   - downsampleSize: 降采样大小，单位 px，默认为 ImageManager.default.defaultDownsampleSize
    ///   - cropRect: 裁剪矩形，默认为 .zero
    ///   - enableAnimatedDownsample: 是否开启动图裁剪，实验中
    /// - Note:当 decodeForDisplay = true 时，会提前解码图片，方法耗时，避免在主线程调用此方法
    public convenience init(_ data: Data?,
                            scale: CGFloat = UIScreen.main.scale,
                            decodeForDisplay decode: Bool = true,
                            downsampleSize: CGSize = ImageManager.default.defaultDownsampleSize,
                            cropRect: CGRect = .zero,
                            enableAnimatedDownsample: Bool = false) throws {
        guard let data, !data.isEmpty else {
            throw ImageError.badImageData()
        }
        let decodeBox = try ImageDecodeBox(data, needCrop: cropRect != .zero)
        try self.init(decodeBox,
                      scale: scale,
                      decodeForDisplay: decode,
                      downsampleSize: downsampleSize,
                      cropRect: cropRect,
                      enableAnimatedDownsample: enableAnimatedDownsample)
    }

    internal convenience init(_ decodeBox: ImageDecodeBox,
                              scale: CGFloat = UIScreen.main.scale,
                              decodeForDisplay decode: Bool = true,
                              downsampleSize: CGSize = ImageManager.default.defaultDownsampleSize,
                              cropRect: CGRect = .zero,
                              enableAnimatedDownsample: Bool = false) throws {
        // 兼容逻辑，旧的 downsampleSize 默认值是 .zero，仍然认为需要降采样
        var downsampleSize = downsampleSize == .zero ? ImageManager.default.defaultDownsampleSize : downsampleSize
        var cropRect = cropRect
        var delayMinimum: TimeInterval = 0
        if decodeBox.isAnimatedImage { // GIF 降采样和裁剪性能也很差，不做降采样和裁剪
            if enableAnimatedDownsample {
                delayMinimum = ImageConfiguration.animatedDelayMinimum
            } else {
                downsampleSize = .notDownsample
                cropRect = .zero
            }
        }
        if DeviceMemory.availableSize < decodeBox.data.count * 5 {
            NotificationCenter.default.post(name: .willReceiveMemoryIssue, object: nil)
        }
        var config = decodeBox.decoder.config
        config.limitSize = CGFloat(ImageManager.default.gifLimitSize)
        config.downsamplePixelSize = downsampleSize.shouldNotDownsample ? 0 : Int(downsampleSize.width * downsampleSize.height)
        config.cropRect = cropRect
        config.delayMinimum = delayMinimum
        decodeBox.decoder.config = config

        let cgImage = try decodeBox.image(at: 0)
        self.init(cgImage: cgImage, scale: scale, orientation: try decodeBox.orientation)
        self.innerImage = try Default(decodeBox)
        self.imageFileFormat = decodeBox.format
        let pixelSize = try decodeBox.pixelSize
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            self.bt.pixelSize = CGSize(width: pixelSize.height, height: pixelSize.width)
            self.bt.destPixelSize = CGSize(width: cgImage.height, height: cgImage.width)
        default:
            self.bt.pixelSize = CGSize(width: pixelSize.width, height: pixelSize.height)
            self.bt.destPixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        }
        self.bt.dataCount = decodeBox.data.count
        self.bt.colorSpaceName = cgImage.colorSpace?.name as? String
        self.bt.isDidScaleDown = false// decoder.isDidScaleDown
        self.bt.frameCount = decodeBox.imageCount
        self.enableAnimatedDownsample = enableAnimatedDownsample
    }

    public convenience init?(named name: String?) throws {
        func scales() -> [CGFloat] {
            let scale = UIScreen.main.scale
            if scale <= 1.0 { return [1, 2, 3] }
            if scale <= 2.0 { return [2, 3, 1] }
            return [3, 2, 1]
        }

        func appendingNameScale(_ string: String, scale: CGFloat) -> String {
            guard fabsf(Float(scale) - 1) > Float.ulpOfOne, !string.isEmpty, !string.hasSuffix("/") else {
                return string
            }
            return string + "@\(Int(scale))x"
        }

        guard let name = name, !name.isEmpty, !name.hasSuffix("/") else {
            return nil
        }
        let nameNSString = name as NSString
        let res = nameNSString.deletingPathExtension
        let ext = nameNSString.pathExtension
        var pathOrNil: String?
        // If no extension, guess by system supported (same as UIImage).
        let exts: [String] = !ext.isEmpty ? [ext] : ["", "png", "jpeg", "jpg", "gif", "webp", "apng"]
        let scales = scales()
        var resultScale: CGFloat = 1.0
        for scale in scales {
            resultScale = scale
            let scaleName = appendingNameScale(res, scale: scale)
            for e in exts {
                pathOrNil = Bundle.main.path(forResource: scaleName, ofType: e)
                if pathOrNil != nil {
                    break
                }
            }
            if pathOrNil != nil {
                break
            }
        }
        guard let path = pathOrNil,
              !path.isEmpty,
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              !data.isEmpty
        else { return nil }
        try self.init(data, scale: resultScale)
    }
}

extension ByteImage {

    final class Default: ByteImageInnerProtocol {

        private(set) var decodeBox: ImageDecodeBox?

        var animatedImageData: Data? {
            decodeBox?.data
        }

        var isAnimatedImage: Bool {
            decodeBox?.isAnimatedImage ?? false
        }

        var frameCount: UInt {
            UInt(decodeBox?.imageCount ?? 1)
        }

        var isAllFramesLoaded: Bool

        var loopCount: UInt

        var frameCache: [AnimateImageFrame]

        var allFramesDuration: TimeInterval?

        func frame(at index: Int, scale: CGFloat, orientation: UIImage.Orientation) -> AnimateImageFrame? {
            guard index >= 0 else { return nil }
            if isAllFramesLoaded && frameCache.count > index {
                return frameCache[index]
            }
            guard let cgImage = try? decodeBox?.image(at: index) else { return nil }
            let image = UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
            let frame = AnimateImageFrame(image: image, index: UInt(index), delay: (try? decodeBox?.delay(at: index)) ?? 0.0)
            return frame
        }

        func changeImage(with data: Data?) {
            //            decoder?.changeDecoder(with: data)
        }

        func preLoadAllFrames(scale: CGFloat, orientation: UIImage.Orientation) {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }

            if isAllFramesLoaded {
                return
            }
            guard let imageCount = decodeBox?.imageCount, imageCount > 1 else {
                return
            }

            var frames: [AnimateImageFrame] = []
            var duration: TimeInterval = 0
            for index in 0..<imageCount {
                guard let frame = self.frame(at: index, scale: scale, orientation: orientation) else {
                    break
                }
                duration += frame.delay
                frames.append(frame)
            }
            if frames.count == imageCount {
                isAllFramesLoaded = true
                allFramesDuration = duration
                frameCache = frames
            }
        }

        init(_ decodeBox: ImageDecodeBox) throws {
            if decodeBox.imageCount > 1 {
                self.decodeBox = decodeBox
            }
            self.loopCount = UInt(decodeBox.loopCount)
            self.isAllFramesLoaded = false
            self.frameCache = []
        }
    }
}

extension CGSize {
    static var notDownsample = CGSize(width: -1, height: -1)
    var shouldNotDownsample: Bool { width < 0 || height < 0 }
}
