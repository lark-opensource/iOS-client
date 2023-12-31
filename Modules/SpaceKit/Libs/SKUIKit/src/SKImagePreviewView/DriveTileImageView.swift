//
//  DriveTileImageView.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/8/28.
//

import UIKit
import SKFoundation


class DriveTileImageView: UIView {
    class FastTiledLayer: CATiledLayer {
        override class func fadeDuration() -> CFTimeInterval {
            return 0.0
        }
    }
    override class var layerClass: AnyClass {
        return FastTiledLayer.self
    }

    var originImage: UIImage?
    var imageRect: CGRect?
    var imageScaleW: CGFloat?
    var imageScaleH: CGFloat?
    var imagePath: SKFilePath
    private var tileSize: CGSize?
    private let tileCount = 64
    init(imagePath: SKFilePath, frame: CGRect, tileSize: CGSize? = nil) {
        self.imagePath = imagePath
        self.tileSize = tileSize
        super.init(frame: frame)
        
        if let image = try? UIImage.read(from: imagePath) {
            self.originImage = image
        } else {
            DocsLogger.error("can not get image from url")
        }
        
        setup()
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        layer.delegate = nil
        layer.contents = nil
        DocsLogger.info("DriveTileImageView deinit")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setup()
    }
    override func draw(_ rect: CGRect) {
        // 将视图frame映射到图片的frame
        guard let scaleW = imageScaleW,
            let scaleH = imageScaleH,
            scaleW > 0,
            scaleH > 0,
            let originImage = originImage?.sk.fixOrientation(),
            let cgImage = originImage.cgImage else { return }
        let cutRect = CGRect(x: rect.origin.x / scaleW,
                             y: rect.origin.y / scaleH,
                             width: rect.width / scaleW,
                             height: rect.height / scaleH)
        DocsLogger.info("tileView draw rect: \(rect)")
        DocsLogger.info("tileView draw cutrect: \(cutRect)")
        autoreleasepool {
            let start = Date().timeIntervalSince1970 * 1000
            guard let imageRef = cgImage.cropping(to: cutRect),
            let context = UIGraphicsGetCurrentContext() else {
                DocsLogger.warning("croping image nil or context is nil")
                return
            }
            let end1 = Date().timeIntervalSince1970 * 1000
            DocsLogger.info("tileView draw cropping time: \(end1 - start)")

            let tileImage = UIImage(cgImage: imageRef)
            UIGraphicsPushContext(context)
            tileImage.draw(in: rect)

            UIGraphicsPopContext()
            let end = Date().timeIntervalSince1970 * 1000
            DocsLogger.info("tileView draw time: \(end - start)")
        }
    }

    private func setup() {
        if let image = originImage, let tiledLayer = layer as? FastTiledLayer {
            let rect = CGRect(origin: .zero, size: image.size)
            let scaleW = self.frame.size.width / rect.size.width
            let scaleH = self.frame.size.height / rect.size.height
            guard scaleW > 0, scaleH > 0 else {
                DocsLogger.info("frame is zero")
                return
            }
            let level = ceil(log2(1 / max(scaleW, scaleH)))
            tiledLayer.levelsOfDetail = 0
            tiledLayer.levelsOfDetailBias = Int(level) + 1
            tiledLayer.tileSize = resizeTileSize() ?? defaultTileSize()
            imageRect = rect
            imageScaleW = scaleW
            imageScaleH = scaleH
        }
    }
    private func resizeTileSize() -> CGSize? {
        guard let size = tileSize, self.frame.size.width > 0, self.frame.size.height > 0 else {
            return nil
        }
        
        // tile 的放大比例是2的N次方
        let scaleW = size.width / self.frame.size.width
        let scaleH = size.height / self.frame.size.height
        let scale = max(scaleW, scaleH)
        let level = ceil(log2(scale))
        let tileScale = 2 << Int(level)
        
        let tileWidth = self.frame.size.width * contentScaleFactor * CGFloat(tileScale)
        let tileHeight = (tileWidth / size.width) * size.height
        let resizedSize = CGSize(width: tileWidth, height: tileHeight)
        return resizedSize
    }
    
    private func defaultTileSize() -> CGSize {
        let size = self.bounds.size
        let tileSizeScale = CGFloat(tileCount).squareRoot() / 2
        let maxSize = max(size.width, size.height)
        let tileSize = CGSize(width: maxSize / tileSizeScale, height: maxSize / tileSizeScale)
        DocsLogger.info("default tile size: \(tileSize)")
        return tileSize
    }
}
