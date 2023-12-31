//
//  UIWindow+VisionOS.swift
//  UniverseDesignTheme
//
//  Created by Hayden on 18/12/2023.
//

import UIKit

// TODO: VisonOS 废弃接口适配，先放在这里，以后移动到 UDUtils 中

extension UIWindow: UDComponentsExtensible {}

public extension UDComponentsExtension where BaseType: UIWindow {

    /// 获取当前活跃的 window
    /// - NOTE: 用于替换原有的 `UIApplication.shared.keyWindow` 用法，在 VisionOS 上可用
    static var keyWindow: UIWindow? {
        UIApplication.shared.ud.keyWindow
    }

    /// 获取当前 `keyWindow` 的大小
    /// - NOTE: 用于替换原有的 `UIScreen.main.bounds` 用法，在 VisionOS 上可用
    static var windowBounds: CGRect {
        #if os(visionOS)
        // VisionOS window 的默认大小为 1280x720pt
        // https://developer.apple.com/design/human-interface-guidelines/windows#visionOS
        keyWindow?.bounds ?? .init(origin: .zero, size: .init(width: 1280, height: 720))
        #else
        keyWindow?.bounds ?? UIScreen.main.bounds
        #endif
    }

    /// 获取当前 `keyWindow` 的大小
    /// - NOTE: 用于替换原有的 `UIScreen.main.bounds.size` 用法，在 VisionOS 上可用
    static var windowSize: CGSize {
        windowBounds.size
    }

    /// 获取当前的设备缩放比率
    /// - NOTE: 用于替换原有的 `UIScreen.main.scale` 用法，在 VisionOS 上可用
    static var displayScale: CGFloat {
        #if os(visionOS)
        UITraitCollection.current.displayScale
        #else
        UIScreen.main.scale
        #endif
    }

    /// 获取当前 window 的缩放比率
    /// - NOTE: 用于替换原有的 `UIScreen.main.scale` 用法，在 VisionOS 上可用
    var displayScale: CGFloat {
        base.traitCollection.displayScale
    }
}
