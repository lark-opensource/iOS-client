//
//  UIApplication+VisionOS.swift
//  UniverseDesignTheme
//
//  Created by Hayden on 19/12/2023.
//

import UIKit

extension UIApplication: UDComponentsExtensible {}

extension UDComponentsExtension where BaseType: UIApplication {

    public var keyWindow: UIWindow? {
        #if os(visionOS)
        let availableScene = base.connectedScenes.filter {
            $0.activationState == .foregroundActive &&
            $0.session.role == .windowApplication
        }
        for case let ws as UIWindowScene in availableScene {
            if let kw = ws.keyWindow {
                return kw
            }
            if let kw = ws.windows.first(where: { $0.isKeyWindow }) {
                return kw
            }
        }
        return nil
        #else
        if #available(iOS 15, *) {
            return base.connectedScenes
                .filter { $0.session.role == .windowApplication }
                .compactMap { $0 as? UIWindowScene }
                .first?.keyWindow
        } else if #available(iOS 13, *) {
            return UIApplication.shared
                .windows
                .first { $0.isKeyWindow }
        } else {
            return base.keyWindow
        }
        #endif
    }

    @available(iOS 13.0, *)
    var topMostWindowScene: UIWindowScene? {
        var fallback: UIWindowScene?
        var fallbackActive: UIWindowScene?
        for case let scene as UIWindowScene in base.connectedScenes {
            if scene.activationState == .foregroundActive {
                if #available(iOS 15.0, *), scene.keyWindow != nil {
                    return scene
                } else if scene.windows.contains(where: { $0.isKeyWindow }) {
                    return scene
                } else if fallbackActive == nil {
                    fallbackActive = scene
                }
            }
            if fallback == nil {
                fallback = scene
            }
        }
        return fallbackActive ?? fallback
    }
}
