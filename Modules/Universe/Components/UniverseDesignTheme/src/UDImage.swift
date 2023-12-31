//
//  UDImage.swift
//  UniverseDesignTheme
//
//  Created by Hayden on 2021/3/31.
//

import Foundation
import UIKit

public final class UDImage: UDDynamicValue {

    public private(set) var dynamicProvider: (UITraitCollection) -> UIImage

    public init(dynamicProvider: @escaping (UITraitCollection) -> UIImage) {
        self.dynamicProvider = dynamicProvider
    }

    /// Resolve any image to its most fundamental form (a non-dynamic image) for a specific trait collection.
    @available(iOS 13.0, *)
    public func resolvedImage(with traitCollection: UITraitCollection) -> UIImage {
        return dynamicProvider(traitCollection)
    }

    /// Define dynamic image with both light and dark mode.
    /// - Parameters:
    ///   - light: The image to use in light mode.
    ///   - dark: The image to use in dark mode.
    /// - Returns: A dynamic image that uses both given images respectively for the given user interface style.
    static func dynamic(light: UIImage, dark: UIImage) -> UDImage {
        if #available(iOS 13.0, *) {
            return UDImage { trait -> UIImage in
                switch trait.userInterfaceStyle {
                case .dark:
                    return dark
                case .light, .unspecified:
                    return light
                @unknown default:
                    return light
                }
            }
        } else {
            return UDImage { _ in light }
        }
    }
}
