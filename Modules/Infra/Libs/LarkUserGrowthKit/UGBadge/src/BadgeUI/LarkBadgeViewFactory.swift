//
//  BadgeViewFactory.swift
//  UGBadge
//
//  Created by liuxianyu on 2021/11/26.
//

import UIKit
import Foundation

public final class LarkBadgeViewFactory {

    public static func createBadgeView(badgeData: LarkBadgeData, badgeWidth: CGFloat) -> (LarkBaseBadgeView, CGFloat)? {
        let badgeView = LarkBaseBadgeView(badgeData: badgeData, badgeWidth: badgeWidth)
        return (badgeView, badgeView.getContentSize().height)
    }
}
