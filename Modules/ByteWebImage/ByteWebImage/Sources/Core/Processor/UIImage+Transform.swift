//
//  UIImage+Transform.swift
//  ByteWebImage
//
//  Created by bytedance on 2021/4/2.
//

import Foundation
import Accelerate
import UIKit

// disable-lint: magic number
// swiftlint:disable identifier_name
func ByteDegressToRadius(_ degress: CGFloat) -> CGFloat {
    return CGFloat(Double(degress) * Double.pi / 180)
}

/**
 Resize rect to fit the size using a given contentMode.

 @param rect The draw rect
 @param size The content size
 @param mode The content mode
 @return A resized rect for the given content mode.
 @discussion UIViewContentModeRedraw is same as UIViewContentModeScaleToFill.
 */

func ByteRectFit(with contentMode: UIView.ContentMode, rect: CGRect, size: CGSize) -> CGRect {
    var standardRect = rect.standardized
    var newSize = size
    newSize.width = newSize.width < 0 ? -newSize.width : newSize.width
    newSize.height = newSize.height < 0 ? -newSize.height : newSize.height
    let center = CGPoint(x: rect.midX, y: rect.midY)
    switch contentMode {
    case .scaleAspectFit, .scaleAspectFill:
        if standardRect.size.width < 0.01 || standardRect.size.height < 0.01 ||
            newSize.width < 0.01 || newSize.height < 0.01 {
            standardRect.origin = center
            standardRect.size = .zero
        } else {
            var scale: CGFloat = 1.0
            if contentMode == .scaleAspectFit {
                if newSize.width / newSize.height < standardRect.size.width / standardRect.size.height {
                    scale = standardRect.size.height / newSize.height
                } else {
                    scale = standardRect.size.width / newSize.width
                }
            } else {
                if newSize.width / newSize.height < standardRect.size.width / standardRect.size.height {
                    scale = standardRect.size.width / newSize.width
                } else {
                    scale = standardRect.size.height / newSize.height
                }
            }
            newSize.width *= scale
            newSize.height *= scale
            standardRect.size = newSize
            standardRect.origin = CGPoint(x: center.x - newSize.width * 0.5, y: center.y - newSize.height * 0.5)
        }
    case .center:
        standardRect.size = newSize
        standardRect.origin = CGPoint(x: center.x - newSize.width * 0.5, y: center.y - newSize.height * 0.5)
    case .top:
        standardRect.origin.x = center.x - newSize.width * 0.5
        standardRect.size = newSize
    case .bottom:
        standardRect.origin.x = center.x - newSize.width * 0.5
        standardRect.origin.y += standardRect.size.height - newSize.height
        standardRect.size = newSize
    case .left:
        standardRect.origin.y = center.y - newSize.height * 0.5
        standardRect.size = newSize
    case .right:
        standardRect.origin.y = center.y - newSize.height * 0.5
        standardRect.origin.x += standardRect.size.width - newSize.width
        standardRect.size = newSize
    case .topLeft:
        standardRect.size = newSize
    case .topRight:
        standardRect.origin.x += standardRect.size.width - newSize.width
        standardRect.size = newSize
    case .bottomLeft:
        standardRect.origin.y += standardRect.size.height - newSize.height
        standardRect.size = newSize
    case .bottomRight:
        standardRect.origin.x += standardRect.size.width - newSize.width
        standardRect.origin.y += standardRect.size.height - newSize.height
        standardRect.size = newSize
    case .scaleToFill, .redraw:
        break
    @unknown default:
        break
    }
    return standardRect
}

// swiftlint:enable identifier_name
extension ImageWrapper where Base: UIImage {

    public func hasAlpha() -> Bool {
        guard let cgImage = base.cgImage else { return false }
        return ImageDecoderUtils.containsAlpha(cgImage)
    }

    public func draw(in rect: CGRect, with contentMode: UIView.ContentMode, clipsToBounds: Bool) {
        let drawRect = ByteRectFit(with: contentMode, rect: rect, size: self.base.size)
        if drawRect.width == 0 || drawRect.height == 0 { return }
        if clipsToBounds {
            let context = UIGraphicsGetCurrentContext()
            context?.addRect(rect)
            context?.clip()
            self.base.draw(in: drawRect)
            context?.restoreGState()
        } else {
            self.base.draw(in: rect)
        }
    }

    public func resize(to size: CGSize, with mode: UIView.ContentMode = .scaleToFill) -> Base? {
        if self.base.size.equalTo(size) { return self.base }
        if size.width <= 0 || size.height <= 0 { return nil }
        UIGraphicsBeginImageContextWithOptions(size, false, self.base.scale)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height), with: mode, clipsToBounds: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image as? Base
    }

    public func crop(to rect: CGRect) -> Base? {
        var destRect = rect
        destRect.origin.x *= self.base.scale
        destRect.origin.y *= self.base.scale
        destRect.size.width *= self.base.scale
        destRect.size.height *= self.base.scale
        guard destRect.width > 0, destRect.height > 0 else { return nil }
        guard let cgImage = self.base.cgImage?.cropping(to: destRect) else { return nil }
        return UIImage(cgImage: cgImage, scale: self.base.scale, orientation: self.base.imageOrientation) as? Base
    }

    public func insetEdge(by insets: UIEdgeInsets, with color: UIColor? = nil) -> Base? {
        var size = self.base.size
        size.width -= insets.left + insets.right
        size.height -= insets.top + insets.bottom
        if size.width <= 0 || size.height <= 0 { return nil }
        let rect = CGRect(x: -insets.left, y: -insets.top, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, self.base.scale)
        let context = UIGraphicsGetCurrentContext()
        if let color = color {
            context?.setFillColor(color.cgColor)
            let path = CGMutablePath()
            path.addRect(CGRect(x: 0, y: 0, width: size.width, height: size.height))
            path.addRect(rect)
            context?.addPath(path)
            context?.fillPath(using: .evenOdd)
        }
        self.base.draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image as? Base
    }

    public func roundCorner(with radius: CGFloat, corners: UIRectCorner = .allCorners, borderWidth: CGFloat = 0, borderColor: UIColor? = nil, borderLineJoin: CGLineJoin? = nil) -> Base? {
        guard let cgImage = self.base.cgImage else { return nil }
        var corners = corners
        if corners != .allCorners {
            var tmp = UIRectCorner()
            if corners.contains(.topLeft) { tmp = tmp.union(.bottomLeft) }
            if corners.contains(.topRight) { tmp = tmp.union(.bottomRight) }
            if corners.contains(.bottomLeft) { tmp = tmp.union(.topLeft) }
            if corners.contains(.bottomRight) { tmp = tmp.union(.topRight) }
            corners = tmp
        }
        UIGraphicsBeginImageContextWithOptions(self.base.size, false, self.base.scale)
        let context = UIGraphicsGetCurrentContext()
        let rect = CGRect(x: 0, y: 0, width: self.base.size.width, height: self.base.size.height)
        context?.scaleBy(x: 1, y: -1)
        context?.translateBy(x: 0, y: -rect.height)
        let minSize = min(self.base.size.width, self.base.size.height)
        if borderWidth < minSize / 2 {
            let path = UIBezierPath(roundedRect: rect.insetBy(dx: borderWidth, dy: borderWidth), byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: borderWidth))
            path.close()
            context?.saveGState()
            context?.draw(cgImage, in: rect)
            context?.restoreGState()
        }
        if let borderColor = borderColor, borderWidth < minSize / 2, borderWidth > 0 {
            let strokeInset = CGFloat(floorf(Float(borderWidth * self.base.scale) + 0.5)) / self.base.scale
            let strokeRect = rect.insetBy(dx: strokeInset, dy: strokeInset)
            let strokeRadius = radius > self.base.scale / 2 ? radius - self.base.scale / 2 : 0
            let path = UIBezierPath(roundedRect: strokeRect, byRoundingCorners: corners, cornerRadii: CGSize(width: strokeRadius, height: borderWidth))
            path.close()
            path.lineWidth = borderWidth
            if let join = borderLineJoin {
                path.lineJoinStyle = join
            }
            borderColor.setStroke()
            path.stroke()
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image as? Base
    }

    public func rotate(by radius: CGFloat, fitSize: Bool) -> Base? {
        guard let width = self.base.cgImage?.width,
              let height = self.base.cgImage?.height,
              let cgImage = self.base.cgImage,
              width * height > 0
        else {
            return nil
        }
        let transform = CGAffineTransform(rotationAngle: radius)
        let newRect = CGRect(x: 0, y: 0, width: width, height: height).applying(fitSize ? transform : .identity)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: 0,
                                space: colorSpace,
                                bitmapInfo: CGImageByteOrderInfo.orderDefault.rawValue |
                                CGImageAlphaInfo.premultipliedFirst.rawValue)
        context?.setShouldAntialias(true)
        context?.setAllowsAntialiasing(true)
        context?.interpolationQuality = .high
        context?.translateBy(x: +(newRect.width * 0.5), y: +(newRect.height * 0.5))
        context?.rotate(by: radius)
        context?.draw(cgImage, in: CGRect(x: -(Double(width) * 0.5), y: -(Double(height) * 0.5), width: Double(width), height: Double(height)))
        guard let image = context?.makeImage() else { return nil }
        return Base(cgImage: image, scale: self.base.scale, orientation: self.base.imageOrientation)
    }

    public func flip(_ horizental: Bool, _ vertical: Bool) -> Base? {
        guard let cgImage = self.base.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = width * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: CGImageByteOrderInfo.orderDefault.rawValue |
                                      CGImageAlphaInfo.premultipliedFirst.rawValue) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else { return nil }
        var src = vImage_Buffer(data: data, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: bytesPerRow)
        var dest = vImage_Buffer(data: data, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: bytesPerRow)
        if vertical {
            vImageVerticalReflect_ARGB8888(&src, &dest, vImage_Flags(kvImageBackgroundColorFill))
        }
        if horizental {
            vImageHorizontalReflect_ARGB8888(&src, &dest, vImage_Flags(kvImageBackgroundColorFill))
        }
        guard let image = context.makeImage() else { return nil }
        return Base(cgImage: image, scale: self.base.scale, orientation: self.base.imageOrientation)
    }

    public func rotateLeft90() -> Base? {
        return self.rotate(by: ByteDegressToRadius(90), fitSize: true)
    }

    public func rotateRight90() -> Base? {
        return self.rotate(by: ByteDegressToRadius(-90), fitSize: true)
    }

    public func rotateRight180() -> Base? {
        return self.rotate(by: ByteDegressToRadius(180), fitSize: true)
    }

    public func flipHorizental() -> Base? {
        return self.flip(true, false)
    }

    public func flipVertical() -> Base? {
        return self.flip(false, true)
    }

    public func setTint(_ color: UIColor) -> Base? {
        UIGraphicsBeginImageContextWithOptions(self.base.size, false, self.base.scale)
        let rect = CGRect(origin: .zero, size: self.base.size)
        color.set()
        UIRectFill(rect)
        self.base.draw(at: .zero, blendMode: .destinationIn, alpha: 1)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image as? Base
    }

    public func setGrayScale() -> Base? {
        return self.setBlur(by: 0, tintColor: nil, tintMode: .normal, saturation: 0, maskImage: nil)
    }

    public func setBulrSoft() -> Base? {
        return self.setBlur(by: 60, tintColor: UIColor(white: 0.84, alpha: 0.36), tintMode: .normal, saturation: 1.8, maskImage: nil)
    }

    public func setBlurLight() -> Base? {
        return self.setBlur(by: 60, tintColor: UIColor(white: 1.0, alpha: 0.3), tintMode: .normal, saturation: 1.8, maskImage: nil)
    }

    public func setBulrExtraLight() -> Base? {
        return self.setBlur(by: 40, tintColor: UIColor(white: 0.97, alpha: 0.82), tintMode: .normal, saturation: 1.8, maskImage: nil)
    }

    public func setBlurDark() -> Base? {
        return self.setBlur(by: 40, tintColor: UIColor(white: 0.11, alpha: 0.73), tintMode: .normal, saturation: 1.8, maskImage: nil)
    }

    public func setBlur(with tinctColor: UIColor) -> Base? {
        let alpha: CGFloat = 0.6
        var effectColor = tinctColor
        let componentCount = tinctColor.cgColor.numberOfComponents
        if componentCount == 2 {
            var b: CGFloat = 0
            if tinctColor.getWhite(&b, alpha: nil) {
                effectColor = UIColor(white: b, alpha: alpha)
            }
        } else {
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            if tinctColor.getRed(&r, green: &g, blue: &b, alpha: nil) {
                effectColor = UIColor(red: r, green: g, blue: b, alpha: alpha)
            }
        }
        return self.setBlur(by: 20, tintColor: effectColor, tintMode: .normal, saturation: -1.0, maskImage: nil)
    }

    public func setBlur(by radius: CGFloat, tintColor: UIColor?, tintMode: CGBlendMode = CGBlendMode.normal, saturation: CGFloat = 0, maskImage: UIImage?) -> Base? {
        guard self.base.size.width > 1,
              self.base.size.height > 1,
              let cgImage = self.base.cgImage
        else { return nil }
        let hasBlur = Float(radius) > .ulpOfOne
        let hasSaturation = fabsf(Float(saturation) - 1.0) > .ulpOfOne
        let scale = self.base.scale
        let opaque = false
        if !hasBlur && !hasSaturation {
            return self.merge(cgImage, tintColor: tintColor, tinBlendMode: tintMode, maskImage: maskImage, opaque: opaque)
        }
        var effect = vImage_Buffer()
        var scratch = vImage_Buffer()
        var format = vImage_CGImageFormat(bitsPerComponent: 8,
                                          bitsPerPixel: 32,
                                          colorSpace: nil,
                                          bitmapInfo: CGBitmapInfo(
                                            rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue |
                                            CGImageByteOrderInfo.order32Little.rawValue),
                                          version: 0,
                                          decode: nil,
                                          renderingIntent: .defaultIntent)
        var err = vImageBuffer_InitWithCGImage(&effect, &format, nil, cgImage, vImage_Flags(kvImagePrintDiagnosticsToConsole))
        if err != kvImageNoError { return nil }
        err = vImageBuffer_Init(&scratch, effect.height, effect.width, format.bitsPerPixel, vImage_Flags(kvImageNoFlags))
        if err != kvImageNoError { return nil }
        var input: vImage_Buffer = effect
        var output: vImage_Buffer = scratch
        if hasBlur {
            // A description of how to compute the box kernel width from the Gaussian
            // radius (aka standard deviation) appears in the SVG spec:
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            //
            // For larger values of 's' (s >= 2.0), an approximation can be used: Three
            // successive box-blurs build a piece-wise quadratic convolution kernel, which
            // approximates the Gaussian kernel to within roughly 3%.
            //
            // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
            //
            // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
            var inputRadius: Float = Float(radius * scale)
            if inputRadius - 2.0 < .ulpOfOne { inputRadius = 1 }
            var resultRadius = UInt32(floorf((inputRadius * 3.0 * sqrtf(2.0 * Float.pi) / 4.0 + 0.5) / 2.0))
            resultRadius |= 1 // force radius to be odd so that the three box-blur methodology works.
            var iterations: UInt32 = 0
            if radius * scale < 0.5 {
                iterations = 1
            } else if radius * scale < 1.5 {
                iterations = 2
            } else {
                iterations = 3
            }
            let tempSize = vImageBoxConvolve_ARGB8888(&input,
                                                      &output,
                                                      nil,
                                                      vImagePixelCount(0),
                                                      vImagePixelCount(0),
                                                      resultRadius,
                                                      resultRadius,
                                                      nil,
                                                      vImage_Flags(kvImageGetTempBufferSize | kvImageEdgeExtend))
            let temp = malloc(tempSize)
            for _ in 0...iterations {
                vImageBoxConvolve_ARGB8888(&input, &output, temp, 0, 0, resultRadius, resultRadius, nil, vImage_Flags(kvImageEdgeExtend))
                // swap
                let swapTemp = input
                input = output
                output = swapTemp
            }
            free(temp)
        }
        if hasSaturation {
            // These values appear in the W3C Filter Effects spec:
            // https://dvcs.w3.org/hg/FXTF/raw-file/default/filters/Publish.html#grayscaleEquivalent
            let s = Float(saturation)
            let matrixFloat: [Float] = [0.0722 + 0.9278 * s, 0.0722 - 0.0722 * s, 0.0722 - 0.0722 * s, 0,
                                        0.7152 - 0.7152 * s, 0.7152 + 0.2848 * s, 0.7152 - 0.7152 * s, 0,
                                        0.2126 - 0.2126 * s, 0.2126 - 0.2126 * s, 0.2126 + 0.7873 * s, 0,
                                        0, 0, 0, 1]
            let divisor: Int32 = 256
            var matrix: [Int16] = []
            for i in 0...matrixFloat.count - 1 {
                matrix.append(Int16(roundf(matrixFloat[i] * Float(divisor))))
            }
            vImageMatrixMultiply_ARGB8888(&input, &output, &matrix, divisor, nil, nil, vImage_Flags(kvImageNoFlags))
            // swap
            let swapTemp = input
            input = output
            output = swapTemp
        }
        var outputImage: Base?
        var effectCGImage = vImageCreateCGImageFromBuffer(&input, &format, { (_, bufferData) in
            free(bufferData)
        }, nil, vImage_Flags(kvImageNoFlags), nil)
        if effectCGImage == nil {
            effectCGImage = vImageCreateCGImageFromBuffer(&input, &format, nil, nil, vImage_Flags(kvImageNoFlags), nil)
            free(input.data)
        }
        free(output.data)
        guard let image = effectCGImage?.takeRetainedValue() else { return nil }
        effectCGImage?.release()
        outputImage = self.merge(image, tintColor: tintColor, tinBlendMode: tintMode, maskImage: maskImage, opaque: opaque)
        return outputImage
    }

    public func merge(_ effect: CGImage, tintColor: UIColor? = nil, tinBlendMode: CGBlendMode = .normal, maskImage: UIImage? = nil, opaque: Bool = false) -> Base? {
        let hasTint = tintColor != nil && Float(tintColor!.cgColor.alpha) > .ulpOfOne
        let hasMask = maskImage != nil
        let size = self.base.size
        let rect = CGRect(origin: .zero, size: size)
        let scale = self.base.scale
        if !hasTint && !hasMask { return Base(cgImage: effect) }
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        let context = UIGraphicsGetCurrentContext()
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.translateBy(x: 0, y: -size.height)
        if hasMask, let maskCGImage = maskImage?.cgImage, let cgImage = self.base.cgImage {
            context?.draw(cgImage, in: rect)
            context?.saveGState()
            context?.clip(to: rect, mask: maskCGImage)
        }
        context?.draw(effect, in: rect)
        if hasTint {
            context?.saveGState()
            context?.setBlendMode(tinBlendMode)
            context?.setFillColor(tintColor!.cgColor)
            context?.fill(rect)
            context?.restoreGState()
        }
        if hasMask {
            context?.restoreGState()
        }
        let outputImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return outputImage as? Base
    }
}
