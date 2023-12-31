//
//  UDTabsBaseItemModel.swift
//  UniverseDesignTabs
//
//  Created by 姚启灏 on 2020/12/8.
//

import UIKit
import Foundation

/// UDTabsBase Item Model
open class UDTabsBaseItemModel {
    /// index
    open var index: Int = 0
    /// 是否被选中
    open var isSelected: Bool = false
    /// item宽度
    open var itemWidth: CGFloat = 0
    /// 指示器视图Frame转换到cell
    open var indicatorConvertToItemFrame: CGRect = CGRect.zero
    /// 是否正在进行过渡动画
    open var isTransitionAnimating: Bool = false
    /// 当前状态Item宽度的scale
    open var itemWidthCurrentZoomScale: CGFloat = 0

    /// Init
    public init() {}
}
