//
//  UIImage+Docs.swift
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/7/3.
//

import Foundation
import Kingfisher
import CoreServices

@objc
public final class EditorImageUtil: NSObject {
    @objc
    public class func dataForImage(_ pickImage: EditorPickImage, quality: CGFloat, limitSize: UInt) -> Data? {
        // 分开处理gif和非gif图片
        if let data = pickImage.data, data.kf.imageFormat == .GIF {
            return pickImage.image.gifData(data: data, limitSize: limitSize)
        } else {
            return pickImage.image.data(quality: quality, limitSize: limitSize)
        }
    }
}

@objc
extension UIImage {
    func gifData(data: Data, limitSize: UInt) -> Data? {
        if data.count < limitSize {
            return data
        }

        // 压缩大小
        let frameCount = data.gifFrameCount()
        if frameCount <= 0 {
            return nil
        }
        let max: CGFloat = sqrt(CGFloat(limitSize) / CGFloat(data.count)) * sqrt(CGFloat(limitSize))
        var size = CGSize.zero
        if self.size.width > max {
            size.width = max
            size.height = self.size.height / self.size.width * max
        } else {
            size.height = max
            size.width = self.size.width / self.size.height * max
        }
        return data.resizeGif(size: size)
    }

    func data(quality: CGFloat, limitSize: UInt) -> Data? {
        var compression: CGFloat = 1
        guard var data = self.jpegData(compressionQuality: quality) else {
//            DocsLogger.debug("get jpeg data fail")
            return nil
        }
        if data.count < limitSize { return data }
        // 压缩大小
        var max: CGFloat = 1
        var min: CGFloat = 0
        for _ in 0..<6 {
            compression = (max + min) / 2
            guard var data = self.jpegData(compressionQuality: quality) else {
                return nil
            }
            if CGFloat(data.count) < CGFloat(limitSize) * 0.9 {
                min = compression
            } else if data.count > limitSize {
                max = compression
            } else {
                break
            }
        }
        if data.count < limitSize {
            return data
        }

        // 压缩大小
        var lastDataLength: Int = 0
        var resultImage = self
        while data.count > limitSize && data.count != lastDataLength {
            lastDataLength = data.count
            let ratio: CGFloat = CGFloat(limitSize) / CGFloat(data.count)
            let size: CGSize = CGSize(width: Int(resultImage.size.width * sqrt(ratio)),
                                      height: Int(resultImage.size.height * sqrt(ratio)))
            UIGraphicsBeginImageContext(size)
            resultImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            resultImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
            UIGraphicsEndImageContext()
            let tmpData = resultImage.jpegData(compressionQuality: compression)
            if tmpData == nil {
                return nil
            }
            data = tmpData!
        }

        return data
    }
}

extension Data {
    // 将gif修改成size大小，返回修改之后的data
    func resizeGif(size: CGSize) -> Data? {
        let options: NSDictionary = [
            kCGImageSourceShouldCache as String: true,
            kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF
        ]
        guard let imageSource = CGImageSourceCreateWithData(self as CFData, options) else {
            return nil
        }
        func _resizeGif(from imageSource: CGImageSource, for options: NSDictionary, size: CGSize) -> Data? {
            // 获取每帧时长
            func _frameDuration(from gifInfo: NSDictionary?) -> Double {
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

            guard var data = CFDataCreateMutable(nil, 0) else {
                return nil
            }
            guard let destination = CGImageDestinationCreateWithData(data, kUTTypeGIF, frameCount, nil) else {
                return nil
            }
            let imageProperties: NSDictionary = [
                kCGImagePropertyGIFDictionary: [
                    kCGImagePropertyGIFLoopCount: 0
                ]
            ]
            CGImageDestinationSetProperties(destination, imageProperties)

            for index in 0 ..< frameCount {
                guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, index, options) else {
                    return nil
                }
                // 缩放大小
                let uiimage = UIImage(cgImage: imageRef)
                UIGraphicsBeginImageContextWithOptions(size, false, 0)
                uiimage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
                let scaledUIImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()

                guard let scaledImageRef = scaledUIImage?.cgImage, let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) else {
                    return nil
                }
                let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary
                let frameDuration = _frameDuration(from: gifInfo)
                let frameProperties: NSDictionary = [
                    kCGImagePropertyGIFDictionary: [
                        kCGImagePropertyGIFDelayTime: frameDuration
                    ]
                ]
                CGImageDestinationAddImage(destination, scaledImageRef, frameProperties)
            }
            let success = CGImageDestinationFinalize(destination)

            return success ? (data as Data) : nil
        }

        return _resizeGif(from: imageSource, for: options, size: size)
    }

    // 获取gif的帧数
    func gifFrameCount() -> Int {
        let options: NSDictionary = [
            kCGImageSourceShouldCache as String: true,
            kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF
        ]
        guard let imageSource = CGImageSourceCreateWithData(self as CFData, options) else {
            return 0
        }
        return CGImageSourceGetCount(imageSource)
    }
}
