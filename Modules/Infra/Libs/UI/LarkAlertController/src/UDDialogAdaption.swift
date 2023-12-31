//
//  UDAdaption.swift
//  LarkAlertController
//
//  Created by Hayden on 2021/6/4.
//

import UIKit
import Foundation
import UniverseDesignDialog
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignTheme

/// Typealias of UDDialog
///
/// @available(*, deprecated, renamed: "UDDialog")
public typealias LarkAlertController = UDDialog

extension UDDialog {

    /// UniverseDesignDialog API adaptor.
    ///
    /// @available(*, deprecated, message: "Parameters: color, font, alignment, numberOfLines are removed in UniverseDesignDialog, set those params in UDDialogUIConfig.")
    public func setTitle(
        text: String,
        color: UIColor = UIColor.ud.textTitle,
        font: UIFont = UIFont.ud.title3(.fixed),
        alignment: NSTextAlignment = .center,
        numberOfLines: Int = 0) {
        config.titleColor = color
        config.titleFont = font
        config.titleAlignment = alignment
        config.titleNumberOfLines = numberOfLines
        setTitle(text: text)
    }

    /// UniverseDesignDialog API adaptor.
    ///
    /// @available(*, deprecated, message: "Parameter: padding is removed in UniverseDesignDialog, set this param in UDDialogUIConfig.")
    public func setContent(
        view: UIView,
        padding: UIEdgeInsets) {
        config.contentMargin = padding
        setContent(view: view)
    }

    /// UniverseDesignDialog API adaptor.
    ///
    /// @available(*, deprecated, message: "Parameters: newLine, weight are removed in UniverseDesignDialog.")
    @discardableResult
    public func addButton(
        text: String,
        color: UIColor = UIColor.ud.primaryContentDefault,
        font: UIFont = UIFont.ud.title4(.fixed),
        newLine: Bool = false,
        weight: Int = 1,
        numberOfLines: Int = 1,
        dismissCheck: @escaping () -> Bool = { true },
        dismissCompletion: (() -> Void)? = nil) -> UIButton {
        addButton(
            text: text,
            color: color,
            font: font,
            numberOfLines: numberOfLines,
            dismissCheck: dismissCheck,
            dismissCompletion: dismissCompletion
        )
    }

    /// UniverseDesignDialog API adaptor.
    ///
    /// @available(*, deprecated, message: "Parameters: newLine, weight are removed in UniverseDesignDialog.")
    public func addSecondaryButton(
        text: String,
        newLine: Bool = false,
        weight: Int = 1,
        numberOfLines: Int = 1,
        dismissCheck: @escaping () -> Bool = { true },
        dismissCompletion: (() -> Void)? = nil) {
        addSecondaryButton(
            text: text,
            numberOfLines: numberOfLines,
            dismissCheck: dismissCheck,
            dismissCompletion: dismissCompletion
        )
    }

    /// UniverseDesignDialog API adaptor.
    ///
    /// @available(*, deprecated, message: "Parameters: newLine, weight are removed in UniverseDesignDialog.")
    public func addDestructiveButton(
        text: String,
        newLine: Bool = false,
        weight: Int = 1,
        numberOfLines: Int = 1,
        dismissCheck: @escaping () -> Bool = { true },
        dismissCompletion: (() -> Void)? = nil) {
        addDestructiveButton(
            text: text,
            numberOfLines: numberOfLines,
            dismissCheck: dismissCheck,
            dismissCompletion: dismissCompletion
        )
    }

    /// UniverseDesignDialog API adaptor.
    ///
    /// @available(*, deprecated, message: "API removed in UniverseDesignDialog, use 'addSecondaryButton' to create cancel button with custom text.")
    public func addCancelButton(
        newLine: Bool = false,
        weight: Int = 1,
        numberOfLines: Int = 1,
        dismissCheck: @escaping () -> Bool = { true },
        dismissCompletion: (() -> Void)? = nil) {
        addSecondaryButton(
            text: BundleI18n.LarkAlertController.Lark_Legacy_Cancel,
            newLine: newLine,
            weight: weight,
            numberOfLines: numberOfLines,
            dismissCheck: dismissCheck,
            dismissCompletion: dismissCompletion
        )
    }

    /// UniverseDesignDialog API adaptor.
    ///
    /// @available(*, deprecated, message: "API removed in UniverseDesignDialog")
    public func registerFirstResponder(for view: UIView) {}
}
