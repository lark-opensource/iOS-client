//
//  WKWebView+DarkMode.swift
//  SKUIKit
//
//  Created by yinyuan on 2023/8/26.
//

import Foundation
import WebKit
import UniverseDesignTheme
import SKFoundation

extension WKWebView {
    
    /// 在合适的时机调用 isOpaque=false，解决 DarkMode 下首次加载页面闪白问题
    /// 你可以在页面闪白过后的合适的时机再调用 tryRecoveryOpaque 方法来恢复其默认值
    public func tryFixDarkModeWhitePage() {
        if #available(iOS 13.0, *) {
            if UDThemeManager.getRealUserInterfaceStyle() == .dark {
                isOpaque = false
            }
        }
    }
    
    /// 你可以在页面闪白过后的合适的时机再调用 tryRecoveryOpaque 方法来恢复其默认值
    public func tryRecoveryOpaque() {
        if #available(iOS 13.0, *) {
            if !isOpaque {
                isOpaque = true
            }
        }
    }
}
