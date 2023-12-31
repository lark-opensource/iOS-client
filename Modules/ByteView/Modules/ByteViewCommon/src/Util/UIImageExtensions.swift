//
//  UIImageExtensions.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/8/18.
//

import Foundation
import CoreGraphics
import UniverseDesignTheme

extension UIImage: VCExtensionCompatible {}
public extension VCExtension where BaseType == UIImage {
    static func fromColor(_ color: UIColor, size: CGSize = CGSize(width: 1, height: 1), cornerRadius: CGFloat = 0,
                          insets: UIEdgeInsets = .zero) -> UIImage {
        // 设置正确的 TraitCollection
        if #available(iOS 13.0, *) {
            let correctTrait = UITraitCollection(userInterfaceStyle: UDThemeManager.userInterfaceStyle)
            UITraitCollection.current = correctTrait
            let light = _fromColor(color.resolvedColor(with: .light), size: size, cornerRadius: cornerRadius, insets: insets)
            let dark = _fromColor(color.resolvedColor(with: .dark), size: size, cornerRadius: cornerRadius, insets: insets)
            return UIImage.dynamic(light: light, dark: dark)
        } else {
            return _fromColor(color, size: size, cornerRadius: cornerRadius, insets: insets)
        }
    }

    private static func _fromColor(_ color: UIColor, size: CGSize, cornerRadius: CGFloat, insets: UIEdgeInsets) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        let render = UIGraphicsImageRenderer(bounds: rect)
        let image = render.image { _ in
            let path = UIBezierPath(roundedRect: rect.inset(by: insets), cornerRadius: cornerRadius)
            color.setFill()
            path.fill()
        }
        return image
    }

    func resized(to newSize: CGSize) -> UIImage {
        if newSize == base.size { return base }
        let render = UIGraphicsImageRenderer(size: newSize)
        let image = render.image { (_) in
            base.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return image.withRenderingMode(base.renderingMode)
    }

    /// 生成左下至右上倾斜的渐变Image
    /// - Parameters:
    ///   - bounds: 生成Image的大小
    ///   - colors: 生成Image使用的颜色
    /// - Returns: UIImage对象
    static func obliqueGradientImage(bounds: CGRect, colors: [UIColor]) -> UIImage {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.0)

        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { ctx in
            gradientLayer.render(in: ctx.cgContext)
        }
    }

    /// 生成左至右的渐变Image
    /// - Parameters:
    ///   - bounds: 生成Image的大小
    ///   - colors: 生成Image使用的颜色
    /// - Returns: UIImage对象
    static func horizontalGradientImage(bounds: CGRect, colors: [UIColor]) -> UIImage {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.0)

        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { ctx in
            gradientLayer.render(in: ctx.cgContext)
        }
    }
}

extension Data: VCExtensionCompatible {}
public extension VCExtension where BaseType == Data {
    enum PixelFormat {
        case unknown
        case rgb
        case argb
        case rgba
        case gargb
        case grgba

        var alphaInfo: CGImageAlphaInfo {
            switch self {
            case .rgb: return .none
            case .argb: return .first
            case .rgba: return .last
            case .gargb: return .premultipliedFirst
            case .grgba: return .premultipliedLast
            default: return .noneSkipLast
            }
        }

        var bytesPerPixel: Int {
            switch self {
            case .rgb: return 3
            default: return 4
            }
        }
    }

    func createRGBImage(width: Int, height: Int, format: PixelFormat = .rgba) -> UIImage? {

        let bytes = [UInt8](base)

        guard let data = CFDataCreate(nil, bytes, bytes.count),
              let provider = CGDataProvider(data: data) else {
            return nil
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: format.alphaInfo.rawValue)
        let bitsPerComponent: Int = 8 // 每个字节8位
        let bitsPerPixel: Int = bitsPerComponent * format.bytesPerPixel // 32位像素
        let bytesPerRow: Int = width * format.bytesPerPixel // 每行字节数 = 每行像素数 * 每个像素字节数

        guard let cgImage = CGImage(
            width: width,
            height: bytes.count / bytesPerRow,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
