//
//  UIImage+Docs.swift
//  Common
//
//  Created by weidong fu on 5/1/2018.
//

import Foundation
import SKFoundation
import EENavigator
import UniverseDesignIcon

extension UIImage: DocsExtensionCompatible {}

public extension DocsExtension where BaseType == UIImage {

    /// 画一个等边三角形
    static func drawEquilateralTriangle(_ size: CGSize = CGSize(width: 7, height: 7), with color: CGColor) -> UIImage {
        let render = UIGraphicsImageRenderer(size: size)
        let downVertexX = size.width / 2.0
        let downVertexY = sqrt(size.width * size.width - downVertexX * downVertexX)

        let downVertex = CGPoint(x: downVertexX, y: downVertexY)

        let image = render.image { (ctx) in
            ctx.cgContext.move(to: .zero)
            ctx.cgContext.addLine(to: .init(x: size.width, y: 0))
            ctx.cgContext.addLine(to: downVertex)
            ctx.cgContext.addLine(to: .zero)

            ctx.cgContext.setFillColor(color)
            ctx.cgContext.drawPath(using: .fill)
        }

        return image
    }

}

//public extension DocsExtension where BaseType == UIImage {
//    func alpha(_ value: CGFloat) -> UIImage {
//        UIGraphicsBeginImageContextWithOptions(base.size, false, base.scale)
//        base.draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
//        let newImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        return newImage!
//    }
//}

//public extension DocsExtension where BaseType == UIImage {
//    static func getTransparentImage() -> UIImage {
//        var transparentBackground: UIImage
//        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 1),
//                                               false,
//                                               UIScreen.main.scale)
//        let context = UIGraphicsGetCurrentContext()!
//        context.setFillColor(red: 1, green: 1, blue: 1, alpha: 0)
//        UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
//        transparentBackground = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
//        UIGraphicsEndImageContext()
//        return transparentBackground
//    }
//}

public extension DocsExtension where BaseType == UIImage {
    class func image(strBase64: String, scale: CGFloat = 3) -> UIImage? {
        guard let imageUrl = URL(string: strBase64) else { return nil }
        do {
            let data = try Data.read(from: SKFilePath(absUrl: imageUrl))
            return UIImage(data: data, scale: scale)
        } catch let error {
            DocsLogger.error("image 出错", error: error)
            return nil
        }
    }
    class func image(datBase64: String, scale: CGFloat = 3) -> UIImage? {
        guard let data = Data(base64Encoded: datBase64, options: .ignoreUnknownCharacters) else { return nil }
        return UIImage(data: data, scale: scale)
    }

    class func image(base64: String, scale: CGFloat = 3) -> UIImage? {
        if base64.hasPrefix("data:image/png;base64")
            || base64.hasPrefix("data:image/jpeg;base64") {
            return UIImage.docs.image(strBase64: base64, scale: scale)
        } else {
            return UIImage.docs.image(datBase64: base64, scale: scale)
        }
    }

//    func alpha(_ value: CGFloat) -> UIImage? {
//        UIGraphicsBeginImageContextWithOptions(self.base.size, false, self.base.scale)
//        self.base.draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
//        let newImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        return newImage
//    }
}

// // MARK: 生成圆角图片
//public extension DocsExtension where BaseType == UIImage {
//    func roundImage() -> UIImage? {
//        return self.withRoundedCorners(radius: min(self.base.size.width, self.base.size.height) / 2)
//    }
//
//    func withRoundedCorners(radius: CGFloat? = nil) -> UIImage? {
//        let size = self.base.size
//        let maxRadius = min(size.width, size.height) / 2
//        let cornerRadius: CGFloat
//        if let radius = radius, radius > 0 && radius <= maxRadius {
//            cornerRadius = radius
//        } else {
//            cornerRadius = maxRadius
//        }
//
//        UIGraphicsBeginImageContextWithOptions(size, false, self.base.scale)
//
//        let rect = CGRect(origin: .zero, size: size)
//        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
//        self.base.draw(in: rect)
//
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        return image
//    }
//
//}

// MARK: 生成自定义图片
public extension DocsExtension where BaseType == UIImage {
    
    class func color(_ color: UIColor, _ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)
        var imgSize = rect.size
        if imgSize.width == 0 { imgSize.width = 1 }
        if imgSize.height == 0 { imgSize.height = 1 }
        UIGraphicsBeginImageContextWithOptions(imgSize, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
}

extension UIImage {
    public func withColor(_ newColor: UIColor) -> UIImage? {
        var imgSize = size
        if imgSize.width == 0 { imgSize.width = 1 }
        if imgSize.height == 0 { imgSize.height = 1 }
        UIGraphicsBeginImageContextWithOptions(imgSize, false, scale)

        let drawRect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        newColor.setFill()
        UIRectFill(drawRect)
        draw(in: drawRect, blendMode: .destinationIn, alpha: 1.0)
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return tintedImage
    }

    // beware that this is a time-consuming operation
    public func grayedOut() -> UIImage? {
        let context = CIContext(options: nil)
        guard let currentFilter = CIFilter(name: "CIPhotoEffectNoir") else { return nil }
        currentFilter.setValue(CIImage(image: self), forKey: kCIInputImageKey)
        if let output = currentFilter.outputImage,
            let cgImage = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
        }
        return nil
    }

    public func compress(quality: CGFloat, limitSize: UInt) -> (Data?, Int) {
        var compression: CGFloat = 1
        guard var data = self.jpegData(compressionQuality: quality) else {
            DocsLogger.error("get jpeg data fail")
            return (nil, 0)
        }
        let orignalCount: Int = data.count
        if data.count < limitSize { return (data, orignalCount) }
        // 压缩大小
        var max: CGFloat = 1
        var min: CGFloat = 0
        for _ in 0..<6 {
            compression = (max + min) / 2
            guard let data = self.jpegData(compressionQuality: quality) else {
                return (nil, orignalCount)
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
            return (data, orignalCount)
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
            let getImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            if let getImage = getImage {
                resultImage = getImage
                let tmpData = resultImage.jpegData(compressionQuality: compression)
                if tmpData == nil {
                    DocsLogger.error("get jpeg compression fail")
                    return (nil, orignalCount)
                }
                data = tmpData!
            } else {
                DocsLogger.error("get jpeg fromCurrentImageContext fail")
                return (nil, orignalCount)
            }
        }
        return (data, orignalCount)
    }

    public func data(quality: CGFloat, limitSize: UInt) -> Data? {
        let (data, _) = compress(quality: quality, limitSize: limitSize)
        return data
    }

    public func change(alpha: CGFloat) -> UIImage? {
        var imgSize = size
        if imgSize.width == 0 { imgSize.width = 1 }
        if imgSize.height == 0 { imgSize.height = 1 }
        UIGraphicsBeginImageContextWithOptions(imgSize, false, 0)
        let context = UIGraphicsGetCurrentContext()
        let area = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context?.scaleBy(x: 1, y: -1)
        context?.translateBy(x: 0, y: -area.size.height)
        context?.setBlendMode(.multiply)
        context?.setAlpha(alpha)
        defer { UIGraphicsEndImageContext() }
        guard let cgImage = self.cgImage else {
            return nil
        }
        context?.draw(cgImage, in: area)
        let newImg = UIGraphicsGetImageFromCurrentImageContext()
        return newImg
    }
}


extension UIImage: SKExtensionCompatible {}

extension SKExtension where Base == UIImage {

    public func fixOrientation() -> UIImage {
        let ot: UIImage.Orientation = base.imageOrientation
        guard ot != .up else { return base }
        var transform: CGAffineTransform = CGAffineTransform.identity
        // 处理方向
        switch ot {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: base.size.width, y: base.size.height)
            transform = transform.rotated(by: CGFloat.pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: base.size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: base.size.height)
            transform = transform.rotated(by: -CGFloat.pi / 2)
        default:
            break
        }
        // 处理镜像
        switch ot {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: base.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: base.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        // 画图
        guard let cgImage = base.cgImage,
            let colorSpace = cgImage.colorSpace,
            let ctx = CGContext(data: nil, width: Int(base.size.width), height: Int(base.size.height),
                                bitsPerComponent: cgImage.bitsPerComponent,
                                bytesPerRow: 0,
                                space: colorSpace,
                                bitmapInfo: cgImage.bitmapInfo.rawValue) else { return base }
        ctx.concatenate(transform)
        switch ot {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: base.size.height, height: base.size.width))
        default:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: base.size.width, height: base.size.height))
        }
        // Get Result
        guard let resCGImage = ctx.makeImage() else { return base }
        let resImage: UIImage = UIImage(cgImage: resCGImage)
        return resImage
    }

    public func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: base.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        var imgSize = newSize
        if imgSize.width == 0 { imgSize.width = 1 }
        if imgSize.height == 0 { imgSize.height = 1 }
        UIGraphicsBeginImageContextWithOptions(imgSize, false, base.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        // Move origin to middle
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        base.draw(in: CGRect(x: -base.size.width / 2, y: -base.size.height / 2, width: base.size.width, height: base.size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

extension UIImage {

    public class func watermarkImage(text: String, context: CGContext, size: CGSize) {
        UIGraphicsPushContext(context)
        func drawRotatedText(_ text: NSAttributedString, size: CGSize, at p: CGPoint, angle: CGFloat, c: CGContext) {
            c.saveGState()
            c.translateBy(x: p.x, y: p.y)
            c.scaleBy(x: 1.0, y: -1.0)
            c.rotate(by: angle * .pi / 180)
            text.draw(at: CGPoint(x: 0, y: -size.height / 2))
            c.restoreGState()
        }
        let textColor: UIColor // 对齐Lark的白/黑模式两种水印颜色
        if UIColor.docs.isCurrentDarkMode {
            textColor = UIColor.ud.N500.withAlphaComponent(0.08)
        } else {
            textColor = UIColor.ud.N500.withAlphaComponent(0.12)
        }
        let font = UIFont.systemFont(ofSize: 30)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor]
        let drawedText = NSAttributedString(string: text, attributes: attrs)
        let textSize = drawedText.boundingRect(
            with: CGSize(width: CGFloat(MAXFLOAT), height: CGFloat(MAXFLOAT)),
            options: .usesLineFragmentOrigin,
            context: nil).size
        let angle: CGFloat = 15
        let padding: CGFloat = 160
        let height: CGFloat = 160
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = height
        var rowCount = 0
        while currentHeight < size.height + height * 2 {
            currentWidth = 0
            while currentWidth < size.width {
                let piAngle = angle * CGFloat.pi / 180.0
                var drawPoint = CGPoint(x: currentWidth, y: currentHeight - currentWidth * tan(piAngle))
                if rowCount % 2 == 1 {
                    drawPoint.y -= textSize.width * sin(piAngle)
                    drawPoint.x += textSize.width * cos(piAngle)
                }
                drawRotatedText(drawedText, size: textSize, at: drawPoint, angle: -angle, c: context)
                currentWidth += textSize.width + padding
            }
            currentHeight += height
            rowCount += 1
        }
        UIGraphicsPopContext()
    }
}

extension UDIcon: DocsExtensionCompatible {}

public extension DocsExtension where BaseType == UDIcon {
    static func iconWithPadding(_ type: UDIconType, iconSize: CGSize, imageSize: CGSize) -> UIImage {
        let originIcon = UDIcon.getIconByKey(type, size: iconSize)
        guard imageSize.width > iconSize.width, imageSize.height > iconSize.height else {
            assertionFailure()
            return originIcon
        }
        let iconOrigin = CGPoint(x: (imageSize.width - iconSize.width) / 2,
                                 y: (imageSize.height - iconSize.height) / 2)
        var imgSize = imageSize
        if imgSize.width == 0 { imgSize.width = 1 }
        if imgSize.height == 0 { imgSize.height = 1 }
        UIGraphicsBeginImageContextWithOptions(imgSize, false, 0)
        originIcon.draw(in: CGRect(origin: iconOrigin, size: iconSize))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result ?? originIcon
    }
}

extension UIImage {
    public func docs_grayscale() -> UIImage? {
        let context = CIContext(options: nil)
        guard let filter = CIFilter(name: "CIColorControls") else {
            DocsLogger.error("UIImage grayscale fails on create CIFilter")
            return nil
        }
        filter.setValue(CIImage(image: self), forKey: kCIInputImageKey)
        filter.setValue(0.0, forKey: kCIInputSaturationKey)
        guard let output = filter.outputImage,
              let cgImage = context.createCGImage(output, from: output.extent) else {
            DocsLogger.error("UIImage grayscale fails on createCGImage")
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
