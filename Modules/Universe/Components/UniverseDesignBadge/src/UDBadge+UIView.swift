//
//  UDBadge+UIView.swift
//  UniverseDesignBadge
//
//  Created by Meng on 2020/10/28.
//

import UIKit
import Foundation

extension UIView {
    private static var udBadgeKey: Void?

    /// view use `addBadge(_:on:for:)` will auto set this property
    public var badge: UDBadge? {
        get { return objc_getAssociatedObject(self, &UIView.udBadgeKey) as? UDBadge }
        set { objc_setAssociatedObject(self, &UIView.udBadgeKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }

    /// Add badge for a custom view
    /// - Parameters:
    ///   - config: badge config
    ///   - anchor: badge anchor, default value is topRight
    ///   - anchorType: badge anchor type, default value is rectangle
    ///   - offset: badge center offset
    /// - Returns: added badge
    @discardableResult
    public func addBadge(
        _ config: UDBadgeConfig,
        anchor: UDBadgeAnchor = .topRight,
        anchorType: UDBadgeAnchorType = .rectangle,
        offset: CGSize = .zero
    ) -> UDBadge {
        var anchorConfig = config
        anchorConfig.anchor = anchor
        anchorConfig.anchorType = anchorType
        anchorConfig.anchorOffset = offset
        let badge = UDBadge(config: anchorConfig)
        self.badge = badge
        addSubview(badge)
        return badge
    }
}
