//
//  UDActionSheetUIConfig.swift
//  UniverseDesignActionPanel
//
//  Created by 白镜吾 on 2022/7/22.
//

import Foundation
import UniverseDesignStyle
import UniverseDesignPopover
import UIKit

/// UDActionSheet UI Config
public struct UDActionSheetUIConfig {

    /// Style
    public enum Style {
        case normal
        case autoPopover(popSource: UDActionSheetSource)
        case autoAlert
    }

    public let style: Style

    /// ActionSheet Title Color
    public var titleColor: UIColor?

    /// Show Title
    public var isShowTitle: Bool

    /// Background Color
    public var backgroundColor: UIColor?

    /// Views cornerRadius
    public var cornerRadius: CGFloat

    /// Dismissed Action
    public var dismissedByTapOutside: (() -> Void)?

    /// init
    /// - Parameters:
    ///   - titleColor: ActionSheet Title Color
    ///   - isShowTitle: Show Title
    ///   - backgroundColor: Background Color
    ///   - cornerRadius: Views cornerRadius
    ///   - popSource: Popover Source
    ///   - dismissedByTapOutside: Dismissed Action
    public init(titleColor: UIColor? = UDActionPanelColorTheme.asPrimaryTitleNormalColor,
                isShowTitle: Bool = false,
                backgroundColor: UIColor? = UDActionPanelColorTheme.asPrimaryBgNormalColor,
                cornerRadius: CGFloat = UDStyle.superLargeRadius,
                popSource: UDActionSheetSource,
                dismissedByTapOutside: (() -> Void)? = nil) {
        self.init(style: .autoPopover(popSource: popSource),
                  titleColor: titleColor,
                  isShowTitle: isShowTitle,
                  backgroundColor: backgroundColor,
                  cornerRadius: cornerRadius,
                  dismissedByTapOutside: dismissedByTapOutside)
    }

    /// init
    /// - Parameters:
    ///   - titleColor: ActionSheet Title Color
    ///   - isShowTitle: Show Title
    ///   - backgroundColor: Background Color
    ///   - cornerRadius: Views cornerRadius
    ///   - popSource: Popover Source
    ///   - dismissedByTapOutside: Dismissed Action
    public init(style: Style = .normal,
                titleColor: UIColor? = UDActionPanelColorTheme.acPrimaryTitleNormalColor,
                isShowTitle: Bool = false,
                backgroundColor: UIColor? = UDActionPanelColorTheme.acPrimaryBgNormalColor,
                cornerRadius: CGFloat = UDStyle.superLargeRadius,
                dismissedByTapOutside: (() -> Void)? = nil) {
        self.style = style
        self.titleColor = titleColor
        self.isShowTitle = isShowTitle
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.dismissedByTapOutside = dismissedByTapOutside
    }
}

