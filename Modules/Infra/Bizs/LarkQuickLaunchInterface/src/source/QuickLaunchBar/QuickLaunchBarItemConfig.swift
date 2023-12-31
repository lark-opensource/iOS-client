//
//  QuickLaunchBarItemConfig.swift
//  LarkQuickLaunchInterface
//
//  Created by ByteDance on 2023/5/26.
//

import Foundation
import UniverseDesignColor
import LarkBadge

public protocol QuickLaunchBarDelegate: AnyObject {
    // 滚动展示/消失动画生命周期相关
    func quickLaunchBarWillShow()
    func quickLaunchBarDidShow()
    func quickLaunchBarWillHide()
    func quickLaunchBarDidHide()
}

public struct QuickLaunchBarItem {
    // name
    public var name: String?
    // isEnable
    public var isEnable: Bool
    // normal image
    public var nomalImage: UIImage
    // disableImage
    public var disableImage: UIImage?
    // badge
    public var badge: Badge?
    // enable状态下的操作
    public var action: ((QuickLaunchBarItem) -> Void)?
    // disable状态下的操作
    public var disableAction: ((QuickLaunchBarItem) -> Void)?
    // long press action
    public var longPressAction: ((QuickLaunchBarItem) -> Void)?

    public init(name: String? = nil,
                isEnable: Bool = true,
                nomalImage: UIImage,
                disableImage: UIImage? = nil,
                badge: Badge? = nil,
                action: ((QuickLaunchBarItem) -> Void)? = nil,
                disableAction: ((QuickLaunchBarItem) -> Void)? = nil,
                longPressAction: ((QuickLaunchBarItem) -> Void)? = nil) {
        self.name = name
        self.isEnable = isEnable
        self.nomalImage = nomalImage
        self.disableImage = disableImage
        self.badge = badge
        self.action = action
        self.disableAction = disableAction
        self.longPressAction = action
    }
}

public struct QuickLaunchBarItemViewConfig {

    // 是否显示标题
    public var enableTitle: Bool
    // 图标size
    public var iconSize: CGSize

    public var titleFont: UIFont

    public var titleColor: UIColor

    public var titleTopPadding: CGFloat

    public init(enableTitle: Bool = false,
                iconSize: CGSize = CGSize(width: 20, height: 20),
                titleFont: UIFont = UIFont.systemFont(ofSize: 12),
                titleColor: UIColor = UIColor.ud.textCaption,
                titleTopPadding: CGFloat = 6.0) {
        self.iconSize = iconSize
        self.enableTitle = enableTitle
        self.titleFont = titleFont
        self.titleColor = titleColor
        self.titleTopPadding = titleTopPadding
    }
}

public struct Badge {
    public var type: LarkBadge.BadgeType
    public var style: LarkBadge.BadgeStyle
    
    public init(type: LarkBadge.BadgeType, style: LarkBadge.BadgeStyle) {
        self.type = type
        self.style = style
    }
}
