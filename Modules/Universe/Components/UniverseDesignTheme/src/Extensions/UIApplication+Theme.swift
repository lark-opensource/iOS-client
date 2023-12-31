//
//  UIApplication+Theme.swift
//  UniverseDesignTheme
//
//  Created by Hayden on 2021/6/11.
//

import Foundation
import UIKit

public extension UIApplication {

    /// Overrides the user interface style adopted by all windows in all connected scenes.
    /// - Parameter userInterfaceStyle: The user interface style adopted by all windows in all connected scenes.
    @available(iOS 13.0, *)
    func override(_ userInterfaceStyle: UIUserInterfaceStyle) {
        if supportsMultipleScenes {
            for connectedScene in connectedScenes {
                if let scene = connectedScene as? UIWindowScene {
                    scene.windows.override(userInterfaceStyle)
                }
            }
        } else {
            windows.override(userInterfaceStyle)
        }
    }

    /// Force overrides the user interface style adopted by all windows in all connected scenes.
    /// - Parameter userInterfaceStyle: The user interface style adopted by all windows in all connected scenes.
    @available(iOS 13.0, *)
    func forceOverride(_ userInterfaceStyle: UIUserInterfaceStyle) {
        if supportsMultipleScenes {
            for connectedScene in connectedScenes {
                if let scene = connectedScene as? UIWindowScene {
                    scene.windows.forceOverride(userInterfaceStyle)
                }
            }
        } else {
            windows.forceOverride(userInterfaceStyle)
        }
    }
}
