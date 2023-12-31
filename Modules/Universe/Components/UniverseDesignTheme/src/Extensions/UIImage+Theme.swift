//
//  UIImage+Theme.swift
//  UniverseDesignTheme
//
//  Created by Hayden on 2021/3/29.
//

import Foundation
import UIKit

public extension UIImage {

    /// Make a dynamic image by registering light and dark image into image asset during runtime.
    /// - Parameters:
    ///   - light: light image maker
    ///   - dark: dark image maker
    /// - Returns: UIImage instance competiable with user interface style.
    static func dynamic(
        light: @autoclosure () -> UIImage,
        dark: @autoclosure () -> UIImage) -> UIImage {

        if #available(iOS 13.0, *) {
            let lightTC = UITraitCollection(traitsFrom: [.current, .init(userInterfaceStyle: .light)])
            let darkTC = UITraitCollection(traitsFrom: [.current, .init(userInterfaceStyle: .dark)])
            var lightImage = UIImage()
            var darkImage = UIImage()
            lightTC.performAsCurrent { lightImage = light() }
            darkTC.performAsCurrent { darkImage = dark() }
            lightImage.imageAsset?.register(darkImage, with: UITraitCollection(userInterfaceStyle: .dark))
            return lightImage
        } else {
            return light()
        }
    }

    /// Make a dynamic image by registering light and dark image into image asset during runtime.
    static func & (lightImage: @autoclosure () -> UIImage, darkImage: UIImage) -> UIImage {
        return dynamic(light: lightImage(), dark: darkImage)
    }

    /// Return a non-dynamic image (always in light mode) from input.
    var nonDynamic: UIImage {
        return alwaysLight
    }

    /// Return a non-dynamic image always in light mode.
    var alwaysLight: UIImage {
        guard #available(iOS 13.0, *) else {
            return self.withRenderingMode(.alwaysOriginal)
        }
        if let lightImage = self.imageAsset?.image(with: .light) {
            return lightImage.withRenderingMode(.alwaysOriginal)
        } else {
            assertionFailure("Cannot find image asset or no light image registered.")
            return self.withRenderingMode(.alwaysOriginal)
        }
    }

    /// Return a non-dynamic image always in dark mode.
    ///
    /// NOTE: DO NOT use alwaysDark separately under iOS 13, unintuitive api use might cause bugs.
    var alwaysDark: UIImage {
        guard #available(iOS 13.0, *) else {
            return self.withRenderingMode(.alwaysOriginal)
        }
        if let darkImage = self.imageAsset?.image(with: .dark) {
            return darkImage.withRenderingMode(.alwaysOriginal)
        } else {
            assertionFailure("Cannot find image asset or no dark image registered.")
            return self.withRenderingMode(.alwaysOriginal)
        }
    }
}

@available(iOS 13.0, *)
public extension UIImageAsset {

    /// Creates an image asset with registration of tht eimages with the light and dark trait collections.
    /// - Parameters:
    ///   - lightModeImage: The image you want to register with the image asset with light user interface style.
    ///   - darkModeImage: The image you want to register with the image asset with dark user interface style.
    convenience init(lightModeImage: UIImage?, darkModeImage: UIImage?) {
        self.init()
        register(lightModeImage: lightModeImage, darkModeImage: darkModeImage)
    }

    /// Register an images with the light and dark trait collections respectively.
    /// - Parameters:
    ///   - lightModeImage: The image you want to register with the image asset with light user interface style.
    ///   - darkModeImage: The image you want to register with the image asset with dark user interface style.
    func register(lightModeImage: UIImage?, darkModeImage: UIImage?) {
        register(lightModeImage, for: .light)
        register(darkModeImage, for: .dark)
    }

    /// Register an image with the specified trait collection.
    /// - Parameters:
    ///   - image: The image you want to register with the image asset.
    ///   - traitCollection: The traits to associate with image.
    func register(_ image: UIImage?, for traitCollection: UITraitCollection) {
        guard let image = image else {
            return
        }
        register(image, with: traitCollection)
    }

    /// Returns the variant of the image that best matches the current trait collection. For early SDKs returns the image for light user interface style.
    func image() -> UIImage {
        if #available(iOS 13.0, *) {
            return image(with: .current)
        }
        return image(with: .light)
    }
}
