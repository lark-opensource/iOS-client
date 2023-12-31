//
//  UDPopoverSource.swift
//  UniverseDesignPopover
//
//  Created by 姚启灏 on 2021/4/7.
//

import UIKit
import Foundation

/// UDActionSheet Popover Source
public struct UDPopoverSource: Equatable {
    public let sourceView: UIView?
    public let sourceRect: CGRect
    public let arrowDirection: UIPopoverArrowDirection
    public let preferredContentWidth: CGFloat

    /// init
    /// - Parameters:
    ///   - sourceView:
    ///   - sourceRect:
    ///   - arrowDirection:
    public init(sourceView: UIView?,
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
