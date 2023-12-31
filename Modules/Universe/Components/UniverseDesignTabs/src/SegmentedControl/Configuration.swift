//
//  Configuration.swift
//  UniverseDesignTabs
//
//  Created by Hayden on 2023/2/13.
//

import Foundation
import UIKit
import UniverseDesignShadow

extension UDSegmentedControl {

    public struct Configuration {

        public enum CornerStyle {
            /// 直角
            case none
            /// 全圆角，圆角半径根据组件高度自动调整
            case rounded
            /// 固定圆角，使用指定的数值作为圆角半径
            case fixedRadius(CGFloat)
        }

        public enum DistributionStyle {
            /// 所有选项卡等宽，宽度优先采用最长选项卡的宽度
            case equalWidth
            /// 根据选项卡的文字内容，自动分配宽度
            case automatic
            /// 采用给定的宽度，文字可能会被压缩
            case fixedWidth(CGFloat)
        }

        /// 选项卡标题颜色，默认 textCaption
        public var titleColor: UIColor = UIColor.ud.textCaption
        /// 选项卡标题选中时的颜色，默认 textTitle
        public var titleSelectedColor: UIColor = UIColor.ud.textTitle
        /// 选项卡标题字体，默认 body2
        public var titleFont: UIFont = UIFont.ud.body2
        /// 选项卡标题选中时的字体，默认 body1
        public var titleSelectedFont: UIFont = UIFont.ud.body1
        /// 选项卡标题的缩略规则，默认 byTruncatingMiddle
        public var titleLineBreakMode: NSLineBreakMode = .byTruncatingMiddle
        /// 选项卡文字横向边距，默认左右各 20
        public var titleHorizontalMargin: CGFloat = 20
        /// 选项卡四周边距，默认四周都是 2，暂不支持各方向不等边距
        public var contentEdgeInset: CGFloat = 2
        /// 选项卡之间的距离，默认为 2
        public var itemSpacing: CGFloat = 2
        /// 组件期望高度，默认为 32
        public var preferredHeight: CGFloat = 32
        /// 背景颜色，默认为 bgBase
        public var backgroundColor: UIColor = UIColor.ud.bgBase
        /// 游标颜色，默认为 bgFloat
        public var indicatorColor: UIColor = UIColor.ud.bgFloat
        /// 游标阴影颜色，默认为 s1DownColor
        public var indicatorShadowColor: UIColor = UDShadowColorTheme.s1DownColor
        /// 游标阴影透明度，默认为 0.15
        public var indicatorShadowOpacity: CGFloat = 0.15
        /// 游标阴影羽化值，默认为 6
        public var indicatorShadowRadius: CGFloat = 6
        /// 游标阴影偏移，默认横向 0，纵向 2
        public var indicatorShadowOffset: CGSize = CGSize(width: 0, height: 2)
        /// title 内容超出尺寸是，是否能手动滑动
        public var isScrollEnabled: Bool = false
        /// 手动滑动到边缘是否有回弹效果
        public var isBounceEnabled: Bool = false

        // TODO: 参数合法性校验

        /// 单个选项卡的最大宽度，默认不作限制。过小的值会导致文字压缩。
        public var itemMaxWidth: CGFloat = .greatestFiniteMagnitude

        /// 选项卡的排布样式，分为等宽 (equalWidth)、自动 (automatic) 和定宽 (fixedWidth)，默认为 `.equalWidth`
        ///
        /// - `equalWidth`: 所有选项卡等宽，宽度优先采用最长选项卡的宽度；
        /// - `automatic`: 根据选项卡的文字内容，自动分配宽度；
        /// - `fixedWidth`: 采用给定的宽度，文字可能会被压缩。
        ///
        /// 注意，不论何种类型，其最大宽度均不能超过 `itemMaxWidth`。
        public var itemDistributionStyle: DistributionStyle = .equalWidth

        /// 边角样式，分为无圆角 (none)、固定圆角 (rounded) 和全圆角 (fixedRadius)，默认为 `.rounded`
        ///
        /// - `none`: 直角
        /// - `rounded`: 全圆角，圆角半径根据组件高度自动调整
        /// - `fixedRadius`: 固定圆角，使用指定的数值作为圆角半径
        public var cornerStyle: CornerStyle = .rounded

        public init() {}

        func toTabsTitleConfig() -> UDTabsTitleViewConfig {
            // 将 UDSegmentedControl.Configuration 的属性转换成 UDTabsTitleView 的属性
            let config = UDTabsTitleViewConfig()
            config.isSelectedAnimable = true
            config.isContentScrollViewClickTransitionAnimationEnabled = true
            // 内容过长时，右侧的渐变遮罩样式
            config.isShowGradientMaskLayer = true
            config.maskColor = backgroundColor
            config.maskWidth = preferredHeight > 0 ? preferredHeight : 40
            config.maskVerticalPadding = 0
            // 选项卡标题样式
            config.isTitleColorGradientEnabled = false
            config.titleNormalColor = titleColor
            config.titleSelectedColor = titleSelectedColor
            config.titleNormalFont = titleFont
            config.titleSelectedFont = titleSelectedFont
            // 选项卡布局样式
            config.contentEdgeInsetLeft = contentEdgeInset
            config.contentEdgeInsetRight = contentEdgeInset
            config.itemSpacing = itemSpacing
            config.itemWidthIncrement = titleHorizontalMargin * 2
            config.itemMaxWidth = itemMaxWidth
            config.isItemSpacingAverageEnabled = true
            config.titleLineBreakMode = titleLineBreakMode
            config.layoutStyle = {
                switch itemDistributionStyle {
                case .automatic:                return .custom()
                case .equalWidth:               return .average
                case .fixedWidth(let width):    return .custom(itemContentWidth: width)
                }
            }()
            return config
        }

        func makeIndicator() -> UDTabsIndicatorLineView {
            let indicator = UDTabsIndicatorLineView()
            indicator.layer.ud.setShadowColor(UDShadowColorTheme.s1DownColor)
            indicator.layer.shadowOpacity = 0.15
            indicator.layer.shadowRadius = preferredHeight / 8
            indicator.layer.shadowOffset = CGSize(width: 0, height: 2)
            indicator.indicatorHeight = preferredHeight - contentEdgeInset * 2
            indicator.indicatorRadius = preferredHeight / 2 - contentEdgeInset
            indicator.indicatorColor = indicatorColor
            indicator.verticalOffset = contentEdgeInset
            indicator.indicatorMaskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            return indicator
        }
    }
}
