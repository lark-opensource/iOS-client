//
//  DriveImagePreviewStrategy.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/6/4.
//

import Foundation
import KingfisherWebP
import Kingfisher
import SKCommon
import SKUIKit
import SKFoundation
import ByteWebImage

public struct DriveImagePreviewStrategy: SKImagePreviewStrategy {
    /// 缩略图大小
    private let maxPixelSize: CGFloat
    public func imageForPreview(imagePath: SKFilePath) -> UIImage? {
        guard let data = try? Data.read(from: imagePath) else {
            DocsLogger.error("DriveImagePreviewStrategy: Data Read error ")
            return nil
        }
        if data.isWebPFormat {
            DocsLogger.driveInfo("DriveImagePreviewStrategy: data Format: \(data.bt.imageFileFormat)")
            if UserScopeNoChangeFG.TYP.DriveWebpEable {
                // 支持webp加载
                let date = CACurrentMediaTime()
                var image: UIImage?
                do {
                    image = try ByteImage(data)
                } catch {
                    DocsLogger.error("DriveImagePreviewStrategy: ByteImage error \(error)")
                }
                DocsLogger.driveInfo("webp ByteImage time: \(CACurrentMediaTime() - date)")
                return image
            } else {
                if (data as NSData).length > DriveFeatureGate.webpPreviewMaxSize {
                    DocsLogger.driveInfo("webp is too large and does not support foresight, otherwise there will be a risk of broken decoding OOM")
                    return nil
                } else {
                    // 支持webp加载
                    let date = CACurrentMediaTime()
                    let image = WebPProcessor.default.process(item: .data(data), options: KingfisherParsedOptionsInfo(nil))
                    DocsLogger.driveInfo("webp kingfiser parsed time: \(CACurrentMediaTime() - date)")
                    return image
                }
            }
        }
        DocsLogger.driveInfo("DriveImagePreviewStrategy: data Format: \(data.bt.imageFileFormat)")
        let needDownsample = DriveImageDownsampleUtils.needDownsample(imagePath: imagePath)
        guard needDownsample else { // 原图加载
            return try? UIImage.read(from: imagePath)
        }
        
        let start = Date().timeIntervalSince1970 * 1000
        if let downsampledImage = SKImagePreviewUtils.downsampleImage(path: imagePath, maxPixelSize: maxPixelSize) {
            let end = Date().timeIntervalSince1970 * 1000
            DocsLogger.debug("Drive downsample time: \(end - start)")
            return downsampledImage
        } else {
            DocsLogger.driveInfo("Drive downsample failed, use origin image")
            return try? UIImage.read(from: imagePath)
        }
    }
    
    public func needTileImage(imagePath: SKFilePath) -> Bool {
        return DriveImageDownsampleUtils.needTileImage(imagePath: imagePath)
    }

    public static func defaultStrategy(for windowSize: CGSize) -> SKImagePreviewStrategy {
        let maxPixelSize = DriveImageDownsampleUtils.defaultImageMaxSize(for: windowSize)
        return DriveImagePreviewStrategy(maxPixelSize: maxPixelSize)
    }
}
