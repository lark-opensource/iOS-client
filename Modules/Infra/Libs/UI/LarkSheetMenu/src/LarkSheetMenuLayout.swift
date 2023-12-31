//
//  LarkSheetMenuLayout.swift
//  LarkSheetMenu
//
//  Created by Zigeng on 2023/1/23.
//

import Foundation
import UIKit

// ignore magic number checking for Layout
// disable-lint: magic number

/// 默认的菜单内组件高度,可根据业务需求自行调整
public extension LarkSheetMenuLayout {
    var hotZoneSpace: CGFloat { 8 }
    var headerHeight: CGFloat { 0 }
    var cellHeight: CGFloat { 48 }
    var sectionInterval: CGFloat { 12 }
    var foldSheetHeight: CGFloat {
        UIScreen.main.bounds.size.height * CGFloat(0.46)
    }
    func popoverSize(_ traitCollection: UITraitCollection, containerSize: CGSize) -> CGSize {
        if traitCollection.horizontalSizeClass == .compact || traitCollection.verticalSizeClass == .compact {
            return CGSize(width: min(330, containerSize.width - self.popoverSafePadding * 2), height: min(349, containerSize.height - self.popoverSafePadding * 2))
        }
        return CGSize(width: 375, height: 486)
    }
    var popoverArrowSize: CGSize {
        CGSize(width: 13, height: 47)
    }
    var partialTopAndBottomMargin: CGFloat {
        return 4
    }
    var popoverSafePadding: CGFloat { 12 }
}

/// 菜单样式的默认实现
public struct DefaultLarkSheetMenuLayout: LarkSheetMenuLayout {
    public var sectionCount: Int = 0
    public var itemCount: Int = 0

    public var headerHeight: CGFloat = 0
    public var topPadding: CGFloat = 0
    public let messageOffset: CGFloat
    public let expandedSheetHeight: CGFloat
    public let moreViewMaxHeight: CGFloat

    public init(messageOffset: CGFloat,
                expandedSheetHeight: CGFloat,
                moreViewMaxHeight: CGFloat) {
        self.messageOffset = messageOffset
        self.expandedSheetHeight = expandedSheetHeight
        self.moreViewMaxHeight = moreViewMaxHeight
    }

    public func updateLayout(sectionCount: Int, itemCount: Int, header: LarkSheetMenuHeader) -> LarkSheetMenuLayout {
        var layout = DefaultLarkSheetMenuLayout(messageOffset: self.messageOffset,
                                                expandedSheetHeight: self.expandedSheetHeight,
                                                moreViewMaxHeight: self.moreViewMaxHeight)
        layout.sectionCount = sectionCount
        layout.itemCount = itemCount
        switch header {
        case .invisible:
            layout.headerHeight = 0
        case .custom(let view):
            layout.headerHeight = view.frame.height
        case .emoji:
            layout.headerHeight = 52
        }
        layout.topPadding = 200

        return layout
    }
}

/// 菜单的Source信息
public struct LarkSheetMenuSourceInfo {
    /// 菜单SourceView
    public private(set) var sourceView: UIView
    /// 文本类型消息存在选区状态下, Popover菜单箭头需指向光标选区
    public private(set) var contentView: UIView?
    /// 菜单在popover模式下箭头指向方向,不指定的话会自动计算
    public private(set) var arrowDirection: UIPopoverArrowDirection
    public private(set) var partialRect: (() -> CGRect?)?

    public init(sourceView: UIView,
                contentView: UIView?,
                arrowDirection: UIPopoverArrowDirection = .any,
                partialRect: (() -> CGRect?)? = nil) {
        self.sourceView = sourceView
        self.contentView = contentView
        self.arrowDirection = arrowDirection
        self.partialRect = partialRect
    }
}
