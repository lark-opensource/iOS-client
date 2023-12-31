//
//  OPDebugWindowLayout.swift
//  EEMicroAppSDK
//
//  Created by 尹清正 on 2021/2/3.
//

import UIKit

/// 最小化窗口固定宽度
fileprivate let minimizedWindowViewWidth: CGFloat = 100
/// 最小化窗口固定高度
fileprivate let minimizedWindowViewHeight: CGFloat = 80
/// 正常调试窗口的最小宽度
fileprivate let maximizedWindowViewMinWidth: CGFloat = 350
/// 正常调试窗口的最大宽度
fileprivate let maximizedWindowViewMaxWidth: CGFloat = 450
/// iPad状态下调试窗口的高度
fileprivate let maximizedWindowPadOriginHeight: CGFloat = 800

class OPDebugWindowLayout {
    
    static var windowShadowColor: CGColor {UIColor.gray.cgColor}
    static var windowShadowRadius: CGFloat {5}
    static var windowShadowOpacity: Float {0.6}
    static var windowRadius: CGFloat {5}
    static var windowBorderWidth: CGFloat {1}
    static var windowBorderColor: CGColor {UIColor.gray.cgColor}

    /// 为当前布局提供窗口大小信息的主Window
    let currentWindow: UIWindow?

    /// 当前布局所需要处理的安全区限制
    var safeAreaInsets: UIEdgeInsets?

    init(withWindow window: UIWindow?) {
        if let window = window {
            currentWindow = window
        } else {
            currentWindow = OPWindowHelper.fincMainSceneWindow()
        }
    }

    /// 最小化窗口除了安全区之外额外的margin
    var extraMargin: CGFloat { 5 }

    /// 最小化窗口距离window四周需要保持的最小距离：安全区加上额外的margin
    var expectedMargin: UIEdgeInsets {
        if let insets = safeAreaInsets {
            return UIEdgeInsets(
                top: insets.top+extraMargin,
                left: insets.left+extraMargin,
                bottom: insets.bottom+extraMargin,
                right: insets.right+extraMargin)
        } else {
            return UIEdgeInsets(
                top: extraMargin,
                left: extraMargin,
                bottom: extraMargin,
                right: extraMargin)
        }
    }

    /// 调试窗口所在主Window的size
    var mainWindowSize: CGSize {
        UIWindow.ema_currentWindowSize(currentWindow)
    }

    /// 最小化窗口的size
    var minimizedViewSize: CGSize {
        CGSize(width: minimizedWindowViewWidth, height: minimizedWindowViewHeight)
    }

    /// 正常调试窗口的size
    var maximizedViewSize: CGSize {
        // 计算宽度
        let originWidth = mainWindowSize.width

        var expectedWidth = originWidth
        if expectedWidth > maximizedWindowViewMaxWidth {
            expectedWidth = maximizedWindowViewMaxWidth
        } else if expectedWidth < maximizedWindowViewMinWidth {
            expectedWidth = maximizedWindowViewMinWidth
        }

        // 计算高度
        var expectedHeight = mainWindowSize.height
        if BDPDeviceHelper.isPadDevice() {
            expectedHeight = maximizedWindowPadOriginHeight
        }
        if expectedHeight > mainWindowSize.height {
            expectedHeight = mainWindowSize.height
        }

        return CGSize(width: expectedWidth, height: expectedHeight)
    }

}
