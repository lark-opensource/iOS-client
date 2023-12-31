//
//  UDTabsTitleViewConfig.swift
//  UniverseDesignTabs
//
//  Created by 姚启灏 on 2020/12/10.
//

import UIKit
import Foundation
import UniverseDesignFont

open class UDTabsTitleViewConfig: UDTabsViewConfig {
    /// label的numberOfLines
    public var titleNumberOfLines: Int = 1
    /// label的lineBreakMode
    public var titleLineBreakMode: NSLineBreakMode = .byTruncatingTail
    /// title普通状态的textColor
    public var titleNormalColor: UIColor = UDTabsColorTheme.tabsFixedTitleNormalColor
    /// title选中状态的textColor
    public var titleSelectedColor: UIColor = UDTabsColorTheme.tabsFixedTitleSelectedColor
    /// title普通状态时的字体
    public var titleNormalFont: UIFont = UDFont.body2
    /// title选中时的字体。如果不赋值，就默认与titleNormalFont一样
    public var titleSelectedFont: UIFont = UDFont.body1
    /// title变小时的字体。
    public var titleSmallerFont: UIFont = UDFont.caption1
    /// title的颜色是否渐变过渡
    public var isTitleColorGradientEnabled: Bool = false
    /// title是否缩放。使用该效果时，务必保证titleNormalFont和titleSelectedFont值相同。
    public var isTitleZoomEnabled: Bool = false
    /// isTitleZoomEnabled为true才生效。是对字号的缩放，比如titleNormalFont的pointSize为10，放大之后字号就是10*1.2=12。
    public var titleSelectedZoomScale: CGFloat = 1
    /// title的线宽是否允许粗细。使用该效果时，务必保证titleNormalFont和titleSelectedFont值相同。
    public var isTitleStrokeWidthEnabled: Bool = false
    /// 用于控制字体的粗细（底层通过NSStrokeWidthAttributeName实现），负数越小字体越粗。
    public var titleSelectedStrokeWidth: CGFloat = -2
    /// title是否使用遮罩过渡
    public var isTitleMaskEnabled: Bool = false

    public var titleNormalZoomScale: CGFloat = 1
    public var titleNormalStrokeWidth: CGFloat = 0
    public var textWidth: CGFloat = 0
}
