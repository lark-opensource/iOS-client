//
//  UDDialog+Theme.swift
//  UniverseDesignDialog
//
//  Created by 姚启灏 on 2020/11/13.
//

import UIKit
import Foundation
import UniverseDesignColor

/// UDColor Name Extension
public extension UDColor.Name {

    /// Dialog Mask Background Color Key
    static let dialogMaskBgColor = UDColor.Name("dialog-mask-bg-color")

    /// Dialog Background Color Key
    static let dialogBgColor = UDColor.Name("dialog-bg-color")

    /// Dialog Text Color Key
    static let dialogTextColor = UDColor.Name("dialog-text-color")

    /// Dialog Border Color Key
    static let dialogBorderColor = UDColor.Name("dialog-border-color")
}

/// UDDialog Color Theme
public struct UDDialogColorTheme {

    /// Dialog Mask Background  Color, Default Color: neutralColor12.withAlphaComponent(0.4)
    public static var dialogMaskBgColor: UIColor {
        return UDColor.getValueByKey(.dialogMaskBgColor) ?? UDColor.bgMask
    }

    /// Dialog Background  Color, Default Color: neutralColor1
    public static var dialogBgColor: UIColor {
        return UDColor.getValueByKey(.dialogBgColor) ?? UDColor.bgFloat
    }

    /// Dialog Text  Color, Default Color: neutralColor12
    public static var dialogTextColor: UIColor {
        return UDColor.getValueByKey(.dialogTextColor) ?? UDColor.textTitle
    }

    /// Dialog Border  Color, Default Color: neutralColor12.withAlphaComponent(0.15)
    public static var dialogBorderColor: UIColor {
        return UDColor.getValueByKey(.dialogBorderColor) ?? UDColor.lineDividerDefault
    }
}
