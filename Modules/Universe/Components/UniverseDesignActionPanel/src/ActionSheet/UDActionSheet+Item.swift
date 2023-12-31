//
//  UDActionSheet+Item.swift
//  UniverseDesignActionPanel
//
//  Created by 姚启灏 on 2020/10/29.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignColor

/// UD ActionSheet Item
public struct UDActionSheetItem {

    /// UD ActionSheet Style
    public enum Style: Int {
        case `default` = 0

        case cancel = 1

        case destructive = 2
    }

    /// Item Title
    public var title: String

    /// Item Title Color
    public var titleColor: UIColor?

    /// Item Style
    public var style: Style

    /// Item IsEnable
    public var isEnable: Bool

    /// Item Action
    public var action: (() -> Void)?

    /// init
    /// - Parameters:
    ///   - title:
    ///   - titleColor:
    ///   - style:
    ///   - isEnable:
    ///   - action:
    public init(title: String,
                titleColor: UIColor? = nil,
                style: Style = .default,
                isEnable: Bool = true,
                action: (() -> Void)? = nil) {
        self.title = title
        self.titleColor = titleColor
        self.style = style
        self.isEnable = isEnable
        self.action = action
    }
}
