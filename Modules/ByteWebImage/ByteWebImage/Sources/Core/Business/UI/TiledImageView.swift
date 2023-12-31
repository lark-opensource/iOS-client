//
//  TiledImageView.swift
//  ByteWebImage
//
//  Created by xiongmin on 2021/7/6.
//

import Foundation

/// 图片分片加载容器
public final class TiledImageView: UIView {

    // MARK: Default value

    public static let defaultMaxScale: CGFloat = 2.0
    public static let defaultMinScale: CGFloat = 0.5
    public static let defaultTiledSize: CGSize = CGSize(width: 128.0, height: 128.0)

    // MARK: Public attributes

    /// 图片大小，单位 px，已校正过旋转方向
    public private(set) var imageSize: CGSize = .zero

    /// 图片原始旋转方向，参见 `UIImage.Orientation`
    public private(set) var orientation: UIImage.Orientation = .up

    @available(*, deprecated, message: "This attribute is not safe, will be removed in the future")
    public var image: UIImage? {
        if let cgImage = cgImage {
            return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: orientation)
        } else if let decodeBox = decodeBox, let cgImage = try? decodeBox.image(at: 0, cropRect: .zero) {
            return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: orientation)
        }
        return nil
    }

    // MARK: Internal attributes

    // 用 ImageIO 解码的保留 CGImage
    private var cgImage: CGImage?
    // libwebp/libttheif 则保留 decodeBox
    private var decodeBox: ImageDecodeBox?

    private var maxScale: CGFloat = TiledImageView.defaultMaxScale
    private var minScale: CGFloat = TiledImageView.defaultMinScale
    private var tileSize: CGSize = TiledImageView.defaultTiledSize

    // MARK: Tiled layer

    public override class var layerClass: AnyClass {
        TiledLayer.self
    }

    private class TiledLayer: CATiledLayer {
        override class func fadeDuration() -> CFTimeInterval {
            0
        }
    }

    private var tiledLayer: TiledLayer? {
        self.layer as? TiledLayer
    }

    /// 设置分片图片
    ///
    /// - Note: 非 JPG/HEIC 图片无法高效支持Crop，因此其他格式暂时不支持分片
    public func set(with data: Data,
                    maxScale: CGFloat = TiledImageView.defaultMaxScale,
                    minScale: CGFloat = TiledImageView.defaultMinScale,
                    tiledSize: CGSize = TiledImageView.defaultTiledSize) throws {
        let decodeBox = try ImageDecodeBox(data, needCrop: true)
        try set(with: decodeBox, maxScale: maxScale, minScale: minScale, tiledSize: tiledSize)
    }

    internal func set(with decodeBox: ImageDecodeBox,
                      maxScale: CGFloat = TiledImageView.defaultMaxScale,
                      minScale: CGFloat = TiledImageView.defaultMinScale,
                      tiledSize: CGSize = TiledImageView.defaultTiledSize) throws {
        guard #available(iOS 13, *) else {
            // iOS 12 中 CATiledLayer 有 CA_ASSERT_MAIN_THREAD_TRANSACTIONS 的相关崩溃，暂不开启分片能力
            // https://bytedance.feishu.cn/wiki/UbjFwSuhNiOmRckIb7AcNQoqn4c
            throw ImageError(ByteWebImageTiledFailed, userInfo: [NSLocalizedDescriptionKey: "system not support"])
        }
        let formatIsValid = [.jpeg, .heic].contains(decodeBox.format)
        if !formatIsValid {
            throw ImageError(ByteWebImageTiledFailed, userInfo: [NSLocalizedDescriptionKey: "format not support for tiling"])
        }

        orientation = try decodeBox.orientation
        let size = try decodeBox.pixelSize
        switch orientation {
        case .right, .left, .rightMirrored, .leftMirrored:
            imageSize = CGSize(width: size.height, height: size.width)
        default:
            imageSize = size
        }
        // 用 ImageIO 解码的保留 CGImage，libwebp/libttheif 则保留 decodeBox
        if decodeBox.decoder is ImageIODecoder {
            decodeBox.decoder.config.downsamplePixelSize = 0
            cgImage = try decodeBox.image(at: 0, cropRect: .zero, forceDecode: false) // 不立即解码，等待分片裁剪
            self.decodeBox = nil
        } else {
            cgImage = nil
            self.decodeBox = decodeBox
        }
        self.maxScale = maxScale
        self.minScale = minScale
        self.tileSize = tiledSize
    }

    /// reset content for reuse
    public func reset() {
        maxScale = 2.0
        minScale = 0.5
        tileSize = CGSize(width: 128.0, height: 128.0)
        tiledLayer?.levelsOfDetail = 1
        tiledLayer?.levelsOfDetailBias = 0
        decodeBox = nil
        cgImage = nil
        imageSize = .zero
        orientation = .up
    }

    /// update levelsOfDetail & levelsOfDetailBias
    public func update(maxScale: CGFloat = 2.0,
                       minScale: CGFloat = 0.5) {
        guard maxScale > 1, minScale > 0, minScale < 1 else {
            tiledLayer?.levelsOfDetail = 1
            tiledLayer?.levelsOfDetailBias = 2
            return
        }
        self.maxScale = maxScale
        self.minScale = minScale
        display()
    }

    public override func draw(_ rect: CGRect) {
        autoreleasepool {
            // TODO: 可以使用 ImageDecoderUtils.rawRect(of:in:orientation)
            let cropRect = self.cropRect(rect: rect, orientation: self.orientation).integral
            guard let image = self.croppedCGImage(with: cropRect),
                  let context = UIGraphicsGetCurrentContext() else {
                return
            }
            UIGraphicsPushContext(context)
            let newImage = UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: self.orientation)
            newImage.draw(in: rect.integral)
            UIGraphicsPopContext()
        }
    }

    private func display() {
        let (lod, lodb) = calculate(maxScale, minScale)
        tiledLayer?.levelsOfDetail = lod
        tiledLayer?.levelsOfDetailBias = lodb
        tiledLayer?.tileSize = tileSize
    }

    private func cropRect(rect: CGRect, orientation: UIImage.Orientation) -> CGRect {
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

    private func croppedCGImage(with cropRect: CGRect) -> CGImage? {
        if let decodeBox = self.decodeBox {
            return try? decodeBox.image(at: 0, cropRect: cropRect, forceDecode: false)
        } else if let cgImage = self.cgImage {
            return cgImage.cropping(to: cropRect)
        }
        return nil
    }

    /// return (LOD, LODB)
    private func calculate(_ maxScale: CGFloat, _ minScale: CGFloat) -> (Int, Int) {
        var lod = Int(-log2(minScale))
        var lodb = Int(log2(maxScale))
        lod = lod < 1 ? 1 : lod
        lodb = lodb <= 1 ? 2 : lodb
        if lodb <= lod {
            lodb = lod + 1
        }
        return (lod, lodb)
    }
}
