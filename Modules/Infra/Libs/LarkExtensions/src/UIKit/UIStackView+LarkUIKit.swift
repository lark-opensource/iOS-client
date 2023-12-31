//
//  UIStackView+LarkUIKit.swift
//  LarkExtensions
//
//  Created by Hayden on 28/7/2023.
//

import UIKit
import LarkCompatible

public extension LarkUIKitExtension where BaseType: UIStackView {

    // nolint-next-line: magic_number
    private var backgroundViewTag: Int { return 999 }

    /// Set `backgroundColor` of UIStackView.
    /// - Parameter color: backgroundColor
    /// - NOTE: [See reason](https://useyourloaf.com/blog/stack-view-background-color/)
    func setBackgroundColor(_ color: UIColor?) {
        // iOS 14 及以上，UIStackView 可以直接设置背景色
        if #available(iOS 14.0, *) {
            base.backgroundColor = color
            return
        }
        // iOS 13 及以下，通过添加 subview 设置背景色
        if let color = color {
            // color 不为空，添加 backgroundVIew
            var backgroundView: UIView
            if let existBackgroundView = base.viewWithTag(backgroundViewTag)  {
                backgroundView = existBackgroundView
            } else {
                let newBackgroundView = UIView(frame: base.bounds)
                newBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                newBackgroundView.tag = backgroundViewTag
                base.insertSubview(newBackgroundView, at: 0)
                backgroundView = newBackgroundView
            }
            backgroundView.backgroundColor = color
        } else {
            // color 为空，移除 backgroundVIew
            base.viewWithTag(backgroundViewTag)?.removeFromSuperview()
        }
    }
}
