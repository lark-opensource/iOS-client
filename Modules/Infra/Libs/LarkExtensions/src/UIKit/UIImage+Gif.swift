//
//  UIImage+Gif.swift
//  Lark
//
//  Created by liuwanlin on 2017/10/18.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkCompatible
import MobileCoreServices
import UIKit

extension LarkUIKitExtension where BaseType == UIImage {
    public static func animated(with data: Data, scale: CGFloat = 1.0) -> UIImage? {
        func decode(from imageSource: CGImageSource, for options: NSDictionary) -> ([UIImage], TimeInterval)? {
            // Calculates frame duration for a gif frame out of the kCGImagePropertyGIFDictionary dictionary
            func frameDuration(from gifInfo: NSDictionary?) -> Double {
                let gifDefaultFrameDuration = 0.100

                guard let gifInfo = gifInfo else {
                    return gifDefaultFrameDuration
                }

                let unclampedDelayTime = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber
                let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber
                let duration = unclampedDelayTime ?? delayTime

                guard let frameDuration = duration else { return gifDefaultFrameDuration }

                return frameDuration.doubleValue > 0.011 ? frameDuration.doubleValue : gifDefaultFrameDuration
            }

            let frameCount = CGImageSourceGetCount(imageSource)
            var images = [UIImage]()
            var gifDuration = 0.0
            for index in 0 ..< frameCount {
                guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, index, options) else {
                    return nil
                }

                if frameCount == 1 {
                    // Single frame
                    gifDuration = Double.infinity
                } else {
                    // Animated GIF
                    guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) else {
                        return nil
                    }

                    let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary
                    gifDuration += frameDuration(from: gifInfo)
                }

                images.append(image(cgImage: imageRef, scale: scale, refImage: nil))
            }

            return (images, gifDuration)
        }

        // Start of kf.animatedImageWithGIFData
        let options: NSDictionary = [kCGImageSourceShouldCache as String: true,
                                     kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF]
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, options) else {
            return nil
        }

        guard let (images, gifDuration) = decode(from: imageSource, for: options) else { return nil }

        return animated(with: images, forDuration: gifDuration)
    }

    private static func animated(with images: [UIImage], forDuration duration: TimeInterval) -> UIImage? {
        return .animatedImage(with: images, duration: duration)
    }

    private static func image(cgImage: CGImage, scale: CGFloat, refImage: UIImage?) -> UIImage {
        if let refImage = refImage {
            return UIImage(cgImage: cgImage, scale: scale, orientation: refImage.imageOrientation)
        } else {
            return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
        }
    }
}
