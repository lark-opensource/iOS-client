//
//  LayoutConfig.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/11.
//

import UIKit

public struct LayoutConfig {

    public static var safeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return currentWindow?.safeAreaInsets ?? .zero
        }
        return .zero
    }

    public static var bounds: CGRect {
        return currentWindow?.bounds ?? UIWindow.ud.windowBounds
    }

    // MARK: - Private functions

    public static var currentWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                .first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        }
    }
}
