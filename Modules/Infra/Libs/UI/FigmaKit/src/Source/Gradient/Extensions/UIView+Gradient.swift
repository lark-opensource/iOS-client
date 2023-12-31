//
//  UIView+Gradient.swift
//  EEAtomic
//
//  Created by Hayden on 2023/2/7.
//

import UIKit

public extension UIView {

    private static let kLayerNameGradientBorder = "FKGradientBorderLayer"

    func setGradientBorder(pattern: GradientPattern,
                           width: CGFloat,
                           cornerRadius: CGFloat = 0,
                           clipsToBounds: Bool = true) {
        // create gradient border layer
        let existingBorder = existingGradientBorderLayer()
        let borderLayer = existingBorder ?? FKGradientLayer.fromPattern(pattern)
        borderLayer.frame = CGRect(x: bounds.origin.x, y: bounds.origin.y,
                                   width: bounds.size.width + width, height: bounds.size.height + width)
        borderLayer.name = UIView.kLayerNameGradientBorder

        let borderMask = CAShapeLayer()
        let borderMaskRect = CGRect(x: bounds.origin.x + width / 2, y: bounds.origin.y + width / 2,
                                    width: bounds.size.width - width, height: bounds.size.height - width)
        if cornerRadius <= 0 {
            borderMask.path = UIBezierPath(rect: borderMaskRect).cgPath
        } else {
            borderMask.path = UIBezierPath(roundedRect: borderMaskRect, cornerRadius: cornerRadius).cgPath
        }

        borderMask.fillColor = UIColor.clear.cgColor
        borderMask.strokeColor = UIColor.white.cgColor
        borderMask.lineWidth = width

        borderLayer.mask = borderMask

        let exists = (existingBorder != nil)
        if !exists {
            layer.addSublayer(borderLayer)
        }
        // mask rounded corners
        if clipsToBounds {
            let roundedMask = CAShapeLayer()
            roundedMask.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
            layer.mask = roundedMask
        }
    }

    func setGradientBorder(width: CGFloat,
                           colors: [UIColor],
                           direction: GradientDirection,
                           cornerRadius: CGFloat = 0,
                           clipsToBounds: Bool = true) {
        setGradientBorder(pattern: .init(direction: direction, colors: colors),
                          width: width,
                          cornerRadius: cornerRadius,
                          clipsToBounds: clipsToBounds)
    }

    private func existingGradientBorderLayer() -> FKGradientLayer? {
        let borderLayers = layer.sublayers?.filter {
            return $0.name == UIView.kLayerNameGradientBorder
        }
        if borderLayers?.count ?? 0 > 1 {
            fatalError("can not add more than one border layer.")
        }
        return borderLayers?.first as? FKGradientLayer
    }
}
