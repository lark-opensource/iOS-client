//
//  TitleNaviBarItem.swift
//  LarkUIKit
//
//  Created by SuPeng on 9/8/19.
//

import UIKit
import Foundation
import LarkBadge

public typealias TitleNaviBarAction = (UIButton) -> Void

public final class NaviBarItemText {
    public let text: String
    public let color: UIColor
    public let font: UIFont

    public init(text: String, color: UIColor, font: UIFont) {
        self.text = text
        self.color = color
        self.font = font
    }
}

public enum TitleNaviBarItemBadge {
    case none
    case point
}

open class TitleNaviBarItem {
    public var image: UIImage?
    public let text: NaviBarItemText?
    public let action: TitleNaviBarAction
    public var longPressAction: TitleNaviBarAction?
    public var badge: TitleNaviBarItemBadge
    public var badgePath: Path?

    public init(image: UIImage? = nil,
                text: NaviBarItemText? = nil,
                badge: TitleNaviBarItemBadge = .none,
                action: @escaping TitleNaviBarAction,
                longPressAction: TitleNaviBarAction? = nil) {
        self.action = action
        self.image = image
        self.text = text
        self.badge = badge
        self.longPressAction = longPressAction
    }
}
