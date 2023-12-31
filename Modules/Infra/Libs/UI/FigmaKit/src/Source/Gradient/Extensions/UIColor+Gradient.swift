//
//  UIColor+Gradient.swift
//  EEAtomic
//
//  Created by Hayden on 2023/2/7.
//

import Foundation
import UIKit

public extension UIColor {

    static func fromPattern(_ pattern: GradientPattern, patternSize: CGSize) -> UIColor? {
        return UIColor.fromGradient(FKGradientLayer.fromPattern(pattern),
                                    frame: CGRect(origin: .zero, size: patternSize))
    }

    static func fromGradient(_ gradient: FKGradientLayer, frame: CGRect, cornerRadius: CGFloat = 0) -> UIColor {
        let image = UIImage.fromGradient(gradient, frame: frame, cornerRadius: cornerRadius)
        return UIColor(patternImage: image ?? UIImage())
    }

    static func fromGradientWithDirection(_ direction: GradientDirection, frame: CGRect, colors: [UIColor], cornerRadius: CGFloat = 0, locations: [NSNumber]? = nil) -> UIColor? {
        let gradient = FKGradientLayer(direction: direction, colors: colors.map({ $0.cgColor }), cornerRadius: cornerRadius, locations: locations)
        return UIColor.fromGradient(gradient, frame: frame)
    }

    static func fromGradientWithType(_ type: GradientType, direction: GradientDirection, frame: CGRect, colors: [UIColor], locations: [NSNumber]? = nil) -> UIColor? {
        let gradient = FKGradientLayer(type: type, direction: direction, colors: colors, locations: locations)
        return UIColor.fromGradient(gradient, frame: frame)
    }
}
