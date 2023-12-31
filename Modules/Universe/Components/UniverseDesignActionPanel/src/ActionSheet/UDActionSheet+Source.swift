//
//  UDActionSheet+Source.swift
//  UniverseDesignActionPanel
//
//  Created by 姚启灏 on 2020/10/29.
//

import UIKit
import Foundation

/// UDActionSheet Popover Source
public struct UDActionSheetSource: Equatable {
    let sourceView: UIView
    let sourceRect: CGRect
    let arrowDirection: UIPopoverArrowDirection
    let preferredContentWidth: CGFloat

    /// init
    /// - Parameters:
    ///   - sourceView:
    ///   - sourceRect:
    ///   - arrowDirection:
    public init(sourceView: UIView,
                sourceRect: CGRect,
                preferredContentWidth: CGFloat = 180,
                arrowDirection: UIPopoverArrowDirection = .unknown) {
        self.sourceView = sourceView
        self.sourceRect = sourceRect
        self.preferredContentWidth = preferredContentWidth
        self.arrowDirection = arrowDirection
    }

    static public func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.sourceView == rhs.sourceView &&
            lhs.sourceRect == rhs.sourceRect &&
            lhs.preferredContentWidth == rhs.preferredContentWidth &&
            lhs.arrowDirection == rhs.arrowDirection
    }
}
