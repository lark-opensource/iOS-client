//
//  OperationTool.swift
//  Image
//
//  Created by Crazy凡 on 2023/6/20.
//

import UIKit
import LarkExtensions
import LarkCompatible

@available(iOS 14.0, *)
struct OperationTool {
    private var base: UIImage = UIImage(systemName: "figure.walk")!
    init(size: CGFloat, image: UIImage? = nil) {
        self.base = image ?? UIImage(systemName: "figure.walk", withConfiguration: UIImage.SymbolConfiguration(pointSize: size))!
    }

    // MARK: - HELP
    static func drawCheckerboardImage(size: CGSize, blockSize: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let ctx = context.cgContext

            for y in stride(from: CGFloat(0), to: size.height, by: blockSize * 2) {
                for x in stride(from: CGFloat(0), to: size.width, by: blockSize * 2) {
                    ctx.setFillColor(UIColor.black.cgColor)
                    ctx.fill(CGRect(x: x, y: y, width: blockSize, height: blockSize))
                    ctx.fill(CGRect(x: x + blockSize, y: y + blockSize, width: blockSize, height: blockSize))

                    ctx.setFillColor(UIColor.white.cgColor)
                    ctx.fill(CGRect(x: x + blockSize, y: y, width: blockSize, height: blockSize))
                    ctx.fill(CGRect(x: x, y: y + blockSize, width: blockSize, height: blockSize))
                }
            }
        }
        return image
    }

    // MARK: - Scale

    func scaleNew(toSize size: CGSize) -> UIImage? {
        base.lu.scale(toSize: size)
    }

    func scaleOld(toSize size: CGSize) -> UIImage? {
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

    // MARK: - Resize

    @discardableResult
    func resizeNew(maxSize: CGSize) -> UIImage {
        base.lu.resize(maxSize: maxSize)
    }

    @discardableResult
    func resizeOld(maxSize: CGSize) -> UIImage {
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

    // MARK: - alpha
    func alphaNew(_ value: CGFloat) -> UIImage {
        base.lu.alpha(value)
    }

    func alphaOld(_ value: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.base.size, false, self.base.scale)
        self.base.draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        var newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        newImage = newImage?.resizableImage(withCapInsets: self.base.capInsets)
        return newImage ?? self.base
    }

    // MARK: - 根据 capInserts 生成特定边框/填充颜色的图片
    /**
     根据 capInserts 生成特定边框/填充颜色的图片
     
     - parameter inserts:      border cap
     - parameter cornerRadius: radius
     - parameter fillColor:    fill color
     - parameter borderColor:  border color
     - parameter borderWidth:  border width
     
     - returns: image
     */
    func imageWithNew(
        inserts: UIEdgeInsets,
        cornerRadius: Float,
        fillColor: UIColor? = .clear,
        borderColor: UIColor? = .clear,
        borderWidth: Float
    ) -> UIImage? {
        LarkUIKitExtension<UIImage>.imageWith(
            inserts: inserts,
            cornerRadius: cornerRadius,
            fillColor: fillColor,
            borderColor: borderColor,
            borderWidth: borderWidth
        )
    }

    func imageWithOld(
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

    // MARK: - drawRectWithRoundedCorner

    func drawRectWithRoundedCornerNew(radius: CGFloat, sizetoFit: CGSize) -> UIImage {
        base.lu.drawRectWithRoundedCorner(radius: radius, sizetoFit: sizetoFit)
    }

    func drawRectWithRoundedCornerOld(radius: CGFloat, sizetoFit: CGSize) -> UIImage? {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: sizetoFit)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: .allCorners,
                                cornerRadii: CGSize(width: radius, height: radius))
        context.addPath(path.cgPath)
        context.clip()

        self.base.draw(in: rect)
        context.drawPath(using: .fillStroke)
        let output = UIGraphicsGetImageFromCurrentImageContext()
        return output
    }

    // MARK: - rotate
    func rotateNew(by radians: CGFloat) -> UIImage {
        base.lu.rotate(by: radians)
    }

    func rotateOld(by radians: CGFloat) -> UIImage {
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

struct ViewOperationTool {
    private var base: UIView = UIApplication.shared.keyWindow?.rootViewController?.view ?? .init()

    // MARK: - screenshot

    func screenshotNew() -> UIImage {
        base.lu.screenshot()
    }

    func screenshotOld() -> UIImage? {
        let transform = self.base.transform
        self.base.transform = .identity
        var screenshot: UIImage?
        UIGraphicsBeginImageContextWithOptions(self.base.frame.size, false, UIScreen.main.scale)
        if let context = UIGraphicsGetCurrentContext() {
            self.base.layer.render(in: context)
            screenshot = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        self.base.transform = transform
        return screenshot
    }
}
