//
//  UDTabsViewConfig.swift
//  UniverseDesignTabs
//
//  Created by 姚启灏 on 2020/12/8.
//

import UIKit
import Foundation

/// UDTabsView Automatic Dimension
public let UDTabsViewAutomaticDimension: CGFloat = -1

/// UDTabsView Scroll Style
public enum UDTabsViewItemLayoutStyle: Equatable {
    /// 均分布局
    case average
    /// 自定义长度，默认值UDTabsViewAutomaticDimension，会根据能容撑开
    case custom(itemContentWidth: CGFloat = UDTabsViewAutomaticDimension)
}

/// UDTabsView Config
open class UDTabsViewConfig {
    /// item布局
    open var layoutStyle: UDTabsViewItemLayoutStyle = .custom()
    /// 真实的item宽度 = itemContentWidth + itemWidthIncrement。
    open var itemWidthIncrement: CGFloat = 0
    /// 真实的item最大宽度
    open var itemMaxWidth: CGFloat = CGFloat.greatestFiniteMagnitude
    /// item之前的间距
    open var itemSpacing: CGFloat = 20
    /// 当collectionView.contentSize.width小于UDTabsView的宽度时，是否将itemSpacing均分。
    open var isItemSpacingAverageEnabled: Bool = true
    /// item左右滚动过渡时，是否允许渐变。比如UDTabsTitleDataSource的titleZoom、titleNormalColor、titleStrokeWidth等渐变。
    open var isItemTransitionEnabled: Bool = true
    /// 选中的时候，是否需要动画过渡。自定义的cell需要自己处理动画过渡逻辑，动画处理逻辑参考`UDTabsTitleCell`
    open var isSelectedAnimable: Bool = false
    /// 选中动画的时长
    open var selectedAnimationDuration: TimeInterval = 0.25
    /// 是否允许item宽度缩放
    open var isItemWidthZoomEnabled: Bool = false
    /// item宽度选中时的scale
    open var itemWidthSelectedZoomScale: CGFloat = 1.5
    /// item宽度在普通状态下的scale
    open var itemWidthNormalZoomScale: CGFloat = 1
    /// Tabs右侧展示一个渐变图层
    open var isShowGradientMaskLayer: Bool = false
    /// 整体内容的左边距，默认UDTabsViewAutomaticDimension（等于itemSpacing）
    open var contentEdgeInsetLeft: CGFloat = UDTabsViewAutomaticDimension
    /// 整体内容的右边距，默认UDTabsViewAutomaticDimension（等于itemSpacing）
    open var contentEdgeInsetRight: CGFloat = UDTabsViewAutomaticDimension
    /// 点击切换的时候，contentScrollView的切换是否需要动画
    open var isContentScrollViewClickTransitionAnimationEnabled: Bool = true
    /// mask长度
    open var maskWidth: CGFloat = 64
    /// mask高度的上下间隔
    open var maskVerticalPadding: CGFloat = 0
    /// mask颜色
    open var maskColor: UIColor = UDTabsColorTheme.tabsScrollableDisappearColor
    /// Init
    public init() {}
}
