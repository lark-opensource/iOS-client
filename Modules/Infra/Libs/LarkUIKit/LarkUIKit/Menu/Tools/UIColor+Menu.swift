//
//  UIColor+Menu.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/1/29.
//

import Foundation
import UIKit

final class MenuColor {
    private init() { }

    static let shared = MenuColor()

    // MenuItem BackgroundColor
    var normalBackgroundColorForIPad = UIColor.clear
    var normalBackgroundColor = UIColor.ud.bgBodyOverlay
    // 与朱单单讨论，发现之前的颜色设置与设计稿不符，现在更正
    var hoverBackgroundColor = UIColor.ud.N900.withAlphaComponent(0.2)
    var pressBackgroundColor = UIColor.ud.N900.withAlphaComponent(0.2)
    var disableBackgroundColor = UIColor.ud.N900.withAlphaComponent(0.05)

    // MenuItem TitleColor
    var normalTitleColor = UIColor.ud.textCaption
    var hoverTitleColor = UIColor.ud.textCaption
    var pressTitleColor = UIColor.ud.textCaption
    var normalTitleColorForIPad = UIColor.ud.textTitle
    var hoverTitleColorForIPad = UIColor.ud.textTitle
    var pressTitleColorForIPad = UIColor.ud.textTitle
    var disableTitleColor = UIColor.ud.textDisabled

    // MenuItem Image Color
    var normalImageColor = UIColor.ud.iconN1
    var hoverImageColor = UIColor.ud.iconN1
    var pressImageColor = UIColor.ud.iconN1
    var disableImageColor = UIColor.ud.iconDisabled

    // PageIndicator
    var pageControllerLightColor = UIColor.ud.N500
    var pageControllerUnlightColor = UIColor.ud.N300

    // Addition View
    var additionTitleColor = UIColor.ud.textCaption

    // Panel
    var panelLineColor = UIColor.ud.lineDividerDefault
    var panelMaskColor = UIColor.ud.bgMask
    var panelBackgroundColor = UIColor.ud.bgBody
    var panelBackgroundColorForIPad = UIColor.ud.bgFloat

    // Cancel Button
    var cancelButtonTextColor = UIColor.ud.textTitle
    var cancelButtonBackgroundColor = UIColor.clear
}

extension UIColor {
    static let menu = MenuColor.shared
}
