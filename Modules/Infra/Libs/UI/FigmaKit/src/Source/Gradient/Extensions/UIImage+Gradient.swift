//
//  UIImage+Gradient.swift
//  EEAtomic
//
//  Created by Hayden on 2023/2/7.
//

import Foundation
import UIKit

public extension UIImage {

    /// Tint a UIImage with linear gradient.
    func tintedWithGradientWithDirection(_ direction: GradientDirection, colors: [UIColor], locations: [CGFloat]?) -> UIImage {
        defer { UIGraphicsEndImageContext() }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        // Create context
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(.normal)
        // Get image rect
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        guard let cgImage = cgImage else { return self }
        context.clip(to: rect, mask: cgImage)
        // Create gradient
        let colorsArr = colors.map({ $0.cgColor }) as CFArray
        let space = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(colorsSpace: space, colors: colorsArr, locations: locations) else { return self }
        // Convert the start and end points from iOS screen coordinates to cartesian coordinates
        var (start, end) = direction.startAndEndPointForLinear
        start = CGPoint(x: start.x * size.width, y: (1 - start.y) * size.height)
        end = CGPoint(x: end.x * size.width, y: (1 - end.y) * size.height)
        // Apply gradient
        context.drawLinearGradient(gradient, start: start, end: end, options: .drawsBeforeStartLocation)
        guard let gradientImage = UIGraphicsGetImageFromCurrentImageContext() else { return self }
        return gradientImage
    }

    func tinted(with pattern: GradientPattern) -> UIImage {
        return self.tintedWithGradientWithDirection(
            pattern.direction,
            colors: pattern.colors,
            locations: pattern.locations?.map { CGFloat(truncating: $0) }
        )
    }

    static func fromPattern(_ pattern: GradientPattern, patternSize: CGSize) -> UIImage? {
        return UIImage.fromGradient(FKGradientLayer.fromPattern(pattern),
                                    frame: CGRect(origin: .zero, size: patternSize))
    }

    static func fromGradient(_ gradient: FKGradientLayer, frame: CGRect, cornerRadius: CGFloat = 0) -> UIImage? {
        // 避免传入的非法 frame: iOS17 上如果 size 为 0 会触发 'failed to allocate CGBitampContext' assert
        var renderingFrame = frame
        if renderingFrame.size.width == 0 { renderingFrame.size.width = 10 }
        if renderingFrame.size.height == 0 { renderingFrame.size.height = 10 }
        UIGraphicsBeginImageContextWithOptions(renderingFrame.size, false, UIScreen.main.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        let cloneGradient = gradient.clone()
        cloneGradient.frame = renderingFrame
        cloneGradient.cornerRadius = cornerRadius
        cloneGradient.render(in: ctx)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return image
    }

    static func fromGradientWithDirection(_ direction: GradientDirection, frame: CGRect, colors: [UIColor], cornerRadius: CGFloat = 0, locations: [NSNumber]? = nil) -> UIImage? {
        let gradient = FKGradientLayer(direction: direction, colors: colors.map({ $0.cgColor }), cornerRadius: cornerRadius, locations: locations)
        return UIImage.fromGradient(gradient, frame: frame)
    }
}
