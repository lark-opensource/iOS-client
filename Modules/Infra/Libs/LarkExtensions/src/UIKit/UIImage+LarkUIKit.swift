//
//  UIImage+LarkUIKit.swift
//  LarkUIKit
//
//  Created by 李耀忠 on 2016/12/15.
//  Copyright © 2016年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkCompatible
import UIKit
import UniverseDesignColor

extension UIImage: LarkUIKitExtensionCompatible {}

public extension LarkUIKitExtension where BaseType == UIImage {
    func defaultResize() -> UIImage {
        return self.resize(maxSize: CGSize(width: 1280, height: 1280))
    }

    func defaultThumbnail() -> UIImage {
        return self.resize(maxSize: CGSize(width: 640, height: 640))
    }

    func scale(toSize size: CGSize) -> UIImage? {
        if self.base.size == size { return self.base }

        var originWidth: Float = 0
        var originHeight: Float = 0
        if let cgImage = self.base.cgImage {
            originWidth = Float(cgImage.width)
            originHeight = Float(cgImage.height)
        } else if let ciImage = self.base.ciImage {
            originWidth = Float(ciImage.extent.size.width)
            originHeight = Float(ciImage.extent.size.height)
        } else {
            originWidth = Float(self.base.size.width)
            originHeight = Float(self.base.size.height)
        }

        guard originWidth != 0, originHeight != 0 else { return nil }

        let horizontalRatio = Float(size.width) / originWidth
        let verticalRatio = Float(size.height) / originHeight

        let radio: Float
        if verticalRatio > 1, horizontalRatio > 1 {
            radio = verticalRatio > horizontalRatio ? horizontalRatio : verticalRatio
        } else {
            radio = verticalRatio < horizontalRatio ? verticalRatio : horizontalRatio
        }

        let newWidth = CGFloat(roundf(originWidth * radio))
        let newHeight = CGFloat(roundf(originHeight * radio))

        let xPos = (size.width - CGFloat(newWidth)) / 2
        let yPos = (size.height - CGFloat(newHeight)) / 2

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        self.base.draw(in: CGRect(x: xPos, y: yPos, width: newWidth, height: newHeight))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }

    @discardableResult
    func resize(maxSize: CGSize) -> UIImage {
        let sizeChangedTo = RectUtils.resizeRectShapWithMaxSize(targetSize: self.base.size, maxSize: maxSize)
        if sizeChangedTo.equalTo(self.base.size) {
            return self.base
        } else {
            // 绘制缩放后的图片
            UIGraphicsBeginImageContext(sizeChangedTo)
            self.base.draw(in: CGRect(x: 0, y: 0, width: sizeChangedTo.width, height: sizeChangedTo.height))
            let newImg = UIGraphicsGetImageFromCurrentImageContext() ?? self.base
            UIGraphicsEndImageContext()

            return newImg
        }
    }

    // 填充背景图可用，只拉伸图片中间部分
    func stretchToBackground() -> UIImage {
        // 设置左边端盖宽度
        let leftCapWidth = Int(self.base.size.width * 0.5)
        // 设置上边端盖高度
        let topCapHeight = Int(self.base.size.height * 0.5)

        return self.base.stretchableImage(withLeftCapWidth: leftCapWidth, topCapHeight: topCapHeight)
    }

    func alpha(_ value: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.base.size, false, self.base.scale)
        self.base.draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        var newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        newImage = newImage?.resizableImage(withCapInsets: self.base.capInsets)
        return newImage ?? self.base
    }

    /// 获取添加滤镜的图片
    ///
    /// 使用 CIFilter.filterNamesInCategory(kCICategoryBuiltIn) 可以获取所有系统 filter
    ///
    /// - Parameter name: filter name
    /// - Returns: 添加过滤镜的图片
    func filter(name: String) -> UIImage? {
        guard let imageData = self.base.pngData() else {
            return nil
        }
        let inputImage = CoreImage.CIImage(data: imageData)
        let context = CIContext(options: nil)
        guard let filter = CIFilter(name: name) else {
            print("create image CIFilter failed with name \(name)")
            return nil
        }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        if let outputImage = filter.outputImage,
           let outImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: outImage)
        }
        return nil
    }

    /// 黑白滤镜
    ///
    /// - Returns: 添加过滤镜的图片
    func noir() -> UIImage? {
        return filter(name: "CIPhotoEffectNoir")
    }

    func colorize(color: UIColor, resizingMode: UIImage.ResizingMode = .tile) -> UIImage {
        return base.ud.colorize(color: color, resizingMode: resizingMode)
    }

    /**
     根据 capInserts 生成特定边框/填充颜色的图片

     - parameter inserts:      border cap
     - parameter cornerRadius: radius
     - parameter fillColor:    fill color
     - parameter borderColor:  border color
     - parameter borderWidth:  border width

     - returns: image
     */
    class func imageWith(
        inserts: UIEdgeInsets,
        cornerRadius: Float,
        fillColor: UIColor? = .clear,
        borderColor: UIColor? = .clear,
        borderWidth: Float
    ) -> UIImage? {
        let contextSize = CGSize(width: 20, height: 20)
        UIGraphicsBeginImageContextWithOptions(contextSize, false, 0.0)
        let rect = CGRect(x: 0, y: 0, width: contextSize.width, height: contextSize.height)
        let path = UIBezierPath(
            roundedRect: CGRect(
                x: inserts.left,
                y: inserts.right,
                width: rect.size.width - inserts.left - inserts.right,
                height: rect.size.height - inserts.top - inserts.bottom
            ),
            cornerRadius: CGFloat(cornerRadius)
        )
        fillColor?.setFill()
        path.fill()

        path.lineWidth = CGFloat(borderWidth)
        borderColor?.setStroke()
        path.stroke()

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image?.resizableImage(
            withCapInsets: UIEdgeInsets(
                top: 9,
                left: 9,
                bottom: 9,
                right: 9
            ),
            resizingMode: .stretch
        )
    }

    class func fromColor(_ color: UIColor, opaque: Bool = true) -> UIImage {
        return UIImage.ud.fromPureColor(color, opaque: opaque)
    }

    class func gradientImage(colors: [UIColor], startPoint: CGPoint, endPoint: CGPoint, size: CGSize) -> UIImage {
        return UIImage.ud.fromGradientColors(colors, startPoint: startPoint, endPoint: endPoint, size: size)
    }

    func drawRectWithRoundedCorner(radius: CGFloat, sizetoFit: CGSize) -> UIImage? {
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: sizetoFit)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: .allCorners,
                                cornerRadii: CGSize(width: radius, height: radius))
        context.addPath(path.cgPath)
        context.clip()

        self.base.draw(in: rect)
        context.drawPath(using: .fillStroke)
        let output = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return output
    }

    // swiftlint:disable cyclomatic_complexity
    func fixOrientation() -> UIImage {
        guard base.imageOrientation != .up, let cgImage = base.cgImage, let colorSpace = cgImage.colorSpace else {
            return base
        }
        var transform: CGAffineTransform = .identity
        switch base.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: base.size.width, y: base.size.height).rotated(by: CGFloat.pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: base.size.width, y: 0).rotated(by: CGFloat.pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: base.size.height).rotated(by: -CGFloat.pi / 2)
        case .up, .upMirrored: break
        @unknown default: break
        }
        switch base.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: base.size.width, y: 0).scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: base.size.height, y: 0).scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right: break
        @unknown default: break
        }

        guard let ctx = CGContext(
            data: nil,
            width: Int(base.size.width),
            height: Int(base.size.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return self.base
        }

        ctx.concatenate(transform)
        switch base.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(cgImage, in: CGRect(origin: .zero, size: CGSize(width: base.size.height, height: base.size.width)))
        default:
            ctx.draw(cgImage, in: CGRect(origin: .zero, size: base.size))
        }

        guard let image = ctx.makeImage() else { return self.base }
        return UIImage(cgImage: image)
    }

    // swiftlint:enable cyclomatic_complexity

    func rotate(by radians: CGFloat) -> UIImage {
        let rotatedViewBox = UIView(frame:
            CGRect(
                x: 0,
                y: 0,
                width: base.size.width,
                height: base.size.height
            )
        )
        let transform = CGAffineTransform(rotationAngle: radians)
        rotatedViewBox.transform = transform
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, self.base.scale)
        guard let bitmap: CGContext = UIGraphicsGetCurrentContext() else {
            return self.base
        }
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        bitmap.rotate(by: radians)
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(
            base.cgImage!,
            in: CGRect(
                x: -base.size.width / 2,
                y: -base.size.height / 2,
                width: base.size.width,
                height: base.size.height
            )
        )
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self.base
    }
}

public enum RectUtils {
    public static func resizeRectShapWithMaxSize(targetSize: CGSize, maxSize: CGSize) -> CGSize {
        let width = targetSize.width
        let height = targetSize.height
        let scale = width / height

        var sizeChange = CGSize()

        if width <= maxSize.width && height <= maxSize.height {
            // a，图片宽或者高均小于或等于最大尺寸时图片尺寸保持不变，不改变图片大小
            return targetSize
        } else if width > maxSize.width || height > maxSize.height {
            // b,宽或者高大于最大尺寸，但是图片宽度高度比小于或等于2，则将图片宽或者高取大的等比压缩至最大尺寸
            if scale <= 2 && scale >= 1 {
                let changedWidth: CGFloat = maxSize.width
                let changedheight: CGFloat = changedWidth / scale
                sizeChange = CGSize(width: changedWidth, height: changedheight)
            } else if scale >= 0.5 && scale <= 1 {
                let changedheight: CGFloat = maxSize.height
                let changedWidth: CGFloat = changedheight * scale
                sizeChange = CGSize(width: changedWidth, height: changedheight)
            } else if width > maxSize.width && height > maxSize.height {
                // 宽以及高均大于最大尺寸，但是图片宽高比大于2时，则宽或者高取小的等比压缩至最大尺寸
                if scale > 2 {
                    // 高的值比较小
                    let changedheight: CGFloat = maxSize.height
                    let changedWidth: CGFloat = changedheight * scale
                    sizeChange = CGSize(width: changedWidth, height: changedheight)
                } else if scale < 0.5 {
                    // 宽的值比较小
                    let changedWidth: CGFloat = maxSize.width
                    let changedheight: CGFloat = changedWidth / scale
                    sizeChange = CGSize(width: changedWidth, height: changedheight)
                }
            } else {
                return targetSize
            }
        }
        return sizeChange
    }
}
