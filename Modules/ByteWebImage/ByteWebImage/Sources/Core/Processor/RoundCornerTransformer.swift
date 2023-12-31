//
//  RoundCornerTransformer.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/4/2.
//

import Foundation

public struct RoundCornerSize {

    public let size: Int
    // disable-lint: magic number
    public static let r64 = RoundCornerSize(size: 64)
    // enable-lint: magic number
    public static var r100 = RoundCornerSize(size: 100)
}

/// 圆角图片预处理器
public final class RoundCornerTransformer: NSObject, BaseTransformer {

    /// 默认的圆角图片预处理器
    ///
    /// 默认使用 RoundCornerImageSize100
    public static let shared = RoundCornerTransformer()

    private static var transformerMap: [String: RoundCornerTransformer] = [:]

    private var imageSize: RoundCornerSize = .r100
    private var borderWidth: CGFloat = 0
    private var borderColor: UIColor?

    public static func transformer(with imageSize: RoundCornerSize, borderWidth: CGFloat = 0, borderColor: UIColor? = nil) -> RoundCornerTransformer {
        let key = String(format: "%td_%.0f_%@", imageSize.size, borderWidth, borderColor?.description ?? "none")
        if let transformer = transformerMap[key] {
            return transformer
        }

        let transformer = RoundCornerTransformer()
        transformer.imageSize = imageSize
        transformer.borderWidth = borderWidth
        transformer.borderColor = borderColor
        transformerMap[key] = transformer
        return transformer
    }

    public func transformImageBeforeStore(with image: UIImage) -> UIImage? {
        guard let image = image as? ByteImage, !image.isAnimatedImage else {
            return nil
        }
        guard let newImage = image.bt.resize(to: CGSize(width: self.imageSize.size, height: self.imageSize.size)),
              let resultImage = newImage.bt.roundCorner(with: image.size.width / 2, borderColor: self.borderColor) else {
            return nil
        }
        return resultImage
    }

}

extension RoundCornerTransformer {
    public func appendingStringForCacheKey() -> String {
        return "RoundCornerTransformer_\(self.imageSize)_\(self.borderWidth)_\(self.borderColor?.description ?? "")"
    }
}
