//
//  UIWindow+Theme.swift
//  UniverseDesignTheme
//
//  Created by Hayden on 2021/6/11.
//

import Foundation
import UIKit

public extension UIWindow {

    /// Overrides the user interface style adopted by the view and all of its subviews.
    /// - Parameter userInterfaceStyle: The user interface style adopted by the view and all of its subviews.
    @available(iOS 13.0, *)
    func override(_ userInterfaceStyle: UIUserInterfaceStyle) {
        overrideUserInterfaceStyle = userInterfaceStyle
    }

    /// Force overrides the user interface style adopted by the view and all of its subviews.
    /// - Parameter userInterfaceStyle: The user interface style adopted by the view and all of its subviews.
    @available(iOS 13.0, *)
    func forceOverride(_ userInterfaceStyle: UIUserInterfaceStyle) {
        if userInterfaceStyle == overrideUserInterfaceStyle {
            if let snapshot = snapshotView(afterScreenUpdates: false) {
                snapshot.frame = frame
                addSubview(snapshot)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    snapshot.removeFromSuperview()
                }
            }
            overrideUserInterfaceStyle = userInterfaceStyle.opposite
            DispatchQueue.main.async {
                self.overrideUserInterfaceStyle = userInterfaceStyle
            }
        } else {
            overrideUserInterfaceStyle = userInterfaceStyle
        }
    }
}

public extension Array where Element: UIWindow {

    /// Overrides the user interface style adopted by all elements.
    /// - Parameter userInterfaceStyle: The user interface style adopted by all elements.
    @available(iOS 13.0, *)
    func override(_ userInterfaceStyle: UIUserInterfaceStyle) {
        for window in self {
            window.override(userInterfaceStyle)
        }
    }

    /// Force overrides the user interface style adopted by all elements.
    /// - Parameter userInterfaceStyle: The user interface style adopted by all elements.
    @available(iOS 13.0, *)
    func forceOverride(_ userInterfaceStyle: UIUserInterfaceStyle) {
        for window in self {
            window.forceOverride(userInterfaceStyle)
        }
    }
}

@available(iOS 12.0, *)
internal extension UIUserInterfaceStyle {

    var opposite: Self {
        switch self {
        case .unspecified:
            return UIScreen.main.traitCollection.userInterfaceStyle == .light ? .dark : .light
        case .light:
            return .dark
        case .dark:
            return .light
        }
    }
}
