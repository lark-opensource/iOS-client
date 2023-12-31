//
//  UITraitCollection+VisionOS.swift
//  UniverseDesignTheme
//
//  Created by Hayden on 19/12/2023.
//

import UIKit

extension UITraitCollection: UDComponentsExtensible {}

extension UDComponentsExtension where BaseType: UITraitCollection {

    static var topMost: UITraitCollection {
        #if os(visionOS)
        if Thread.isMainThread {
            return UIApplication.shared.ud.topMostWindowScene?.traitCollection ?? .current
        } else {
            return .current
        }
        #else
        if #available(iOS 13.0, *) {
            if Thread.isMainThread {
                return UIApplication.shared.ud.topMostWindowScene?.traitCollection ?? .current
            } else {
                return .current
            }
        } else {
            return UIScreen.main.traitCollection
        }
        #endif
    }

    public static var current: UITraitCollection {
        #if os(visionOS)
        return .current
        #else
        if #available(iOS 13.0, *) {
            return .current
        } else {
            return UIScreen.main.traitCollection
        }
        #endif
    }
}
