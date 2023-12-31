//
//  UDDialog+Config.swift
//  UniverseDesignDialog
//
//  Created by 姚启灏 on 2020/10/15.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignStyle

/// UD Dialog UI Config
public final class UDDialogUIConfig {

    /// Dialog Corner Radius
    public var cornerRadius: CGFloat

    /// Dialog Title Font
    public var titleFont: UIFont

    /// Dialog Title Text Color
    public var titleColor: UIColor

    /// Dialog Title Alignment
    public var titleAlignment: NSTextAlignment

    /// Dialog Title NumberOfLines
    public var titleNumberOfLines: Int

    /// Dialog Button Layout Style
    public var style: UDDialogButtonLayoutStyle

    /// Dialog ContentView Margin
    public var contentMargin: UIEdgeInsets

    /// Dialog Button View  SplitLine Color
    public var splitLineColor: UIColor

    /// Dialog BackgroundColor
    public var backgroundColor: UIColor

    /// init
    /// - Parameters:
    ///   - cornerRadius: Dialog Corner Radius
    ///   - titleFont: Dialog Title Font
    ///   - titleColor: Dialog Title Text Color
    ///   - titleAlignment: Dialog Title Alignment
    ///   - titleNumberOfLines: Dialog Title NumberOfLines
    ///   - style: Dialog Button Layout Style
    ///   - contentMargin: Dialog ContentView Margin
    ///   - splitLineColor: Dialog Button View  SplitLine Color
    ///   - backgroundColor: Dialog BackgroundColor
    public init(cornerRadius: CGFloat = UDStyle.largeRadius,
                titleFont: UIFont = UDFont.title3(.fixed),
                titleColor: UIColor = UDDialogColorTheme.dialogTextColor,
                titleAlignment: NSTextAlignment = .center,
                titleNumberOfLines: Int = 0,
                style: UDDialogButtonLayoutStyle = .normal,
                contentMargin: UIEdgeInsets = UIEdgeInsets(top: 16, left: 20, bottom: 18, right: 20),
                splitLineColor: UIColor = UDDialogColorTheme.dialogBorderColor,
                backgroundColor: UIColor = UDDialogColorTheme.dialogBgColor) {
        self.cornerRadius = cornerRadius
        self.titleFont = titleFont
        self.titleColor = titleColor
        self.titleAlignment = titleAlignment
        self.titleNumberOfLines = titleNumberOfLines
        self.style = style
        self.contentMargin = contentMargin
        self.splitLineColor = splitLineColor
        self.backgroundColor = backgroundColor
    }
}
