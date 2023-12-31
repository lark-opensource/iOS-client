//
//  UDActionPanel+Theme.swift
//  UniverseDesignActionPanel
//
//  Created by 姚启灏 on 2020/11/23.
//

import UIKit
import Foundation
import UniverseDesignColor

/// UDColor Name Extension
public extension UDColor.Name {
    /// Ac Primary Bg Normal Color , Value: "ac-primary-bg-normal-color"
    static let acPrimaryBgNormalColor = UDColor.Name("ac-primary-bg-normal-color")

    /// Ac Primary Icon Normal Color , Value: "ac-primary-icon-normal-color"
    static let acPrimaryIconNormalColor = UDColor.Name("ac-primary-icon-normal-color")

    /// Ac Primary Mack Normal Color , Value: "ac-primary-mack-normal-color"
    static let acPrimaryMaskNormalColor = UDColor.Name("ac-primary-mask-normal-color")

    /// Ac Primary Title Normal Color , Value: "ac-primary-title-normal-color"
    static let acPrimaryTitleNormalColor = UDColor.Name("ac-primary-title-normal-color")

    /// Ac Primary Btn Normal Color , Value: "ac-primary-btn-normal-color"
    static let acPrimaryBtnNormalColor = UDColor.Name("ac-primary-btn-normal-color")

    /// Ac Primary Btn Error Color , Value: "ac-primary-btn-error-color"
    static let acPrimaryBtnErrorColor = UDColor.Name("ac-primary-btn-error-color")

    /// Ac Primary Btn Cancle Color , Value: "ac-primary-btn-cancle-color"
    static let acPrimaryBtnCancleColor = UDColor.Name("ac-primary-btn-cancle-color")

    /// Ac Primary Line Normal Color , Value: "ac-primary-line-normal-color"
    static let acPrimaryLineNormalColor = UDColor.Name("ac-primary-line-normal-color")

    /// Ac Primary pressed Color , Value: "ac-primary-bg-pressed-color"
    static let acPrimaryBgPressedColor = UDColor.Name("ac-primary-bg-pressed-color")

    /// As Primary Title Normal Color , Value: "as-primary-title-normal-color"
    static let asPrimaryTitleNormalColor = UDColor.Name("as-primary-title-normal-color")

    /// As Primary Bg Normal Color , Value: "ac-primary-bg-normal-color"
    static let asPrimaryBgNormalColor = UDColor.Name("as-primary-bg-normal-color")


}

/// UDActionPanel Color Theme
public struct UDActionPanelColorTheme {
    /// Ac Primary Bg Normal Color Color, Default Color: UDColor.neutralColor1
    public static var acPrimaryBgNormalColor: UIColor {
        return UDColor.getValueByKey(.acPrimaryBgNormalColor) ?? UDColor.bgBody
    }

    /// Ac Primary Icon Normal Color Color, Default Color: UDColor.neutralColor5
    public static var acPrimaryIconNormalColor: UIColor {
        return UDColor.getValueByKey(.acPrimaryIconNormalColor) ?? UDColor.lineBorderComponent
    }

    /// Ac Primary Mack Normal Color Color, Default Color: UDColor.neutralColor12.withAlphaComponent(0.4)
    public static var acPrimaryMaskNormalColor: UIColor {
        return UDColor
            .getValueByKey(.acPrimaryMaskNormalColor) ?? UDColor.bgMask
    }

    /// Ac Primary Title Normal Color Color, Default Color: UDColor.neutralColor7
    public static var acPrimaryTitleNormalColor: UIColor {
        return UDColor.getValueByKey(.acPrimaryTitleNormalColor) ?? UDColor.textPlaceholder
    }

    /// Ac Primary Btn Normal Color Color, Default Color: UDColor.neutralColor12
    public static var acPrimaryBtnNormalColor: UIColor {
        return UDColor.getValueByKey(.acPrimaryBtnNormalColor) ?? UDColor.textTitle
    }

    /// Ac Primary Btn Error Color Color, Default Color: UDColor.alertColor6
    public static var acPrimaryBtnErrorColor: UIColor {
        return UDColor.getValueByKey(.acPrimaryBtnErrorColor) ?? UDColor.functionDangerContentDefault
    }

    /// Ac Primary Btn Cancle Color Color, Default Color: UDColor.neutralColor12
    public static var acPrimaryBtnCancleColor: UIColor {
        return UDColor.getValueByKey(.acPrimaryBtnCancleColor) ?? UDColor.textTitle
    }

    /// Ac Primary Line Normal Color Color, Default Color: UDColor.neutralColor12.withAlphaComponent(0.15)
    public static var acPrimaryLineNormalColor: UIColor {
        return UDColor
            .getValueByKey(.acPrimaryLineNormalColor) ?? UDColor.lineDividerDefault
    }

    /// Ac Primary Pressed Color, Default Color: neutral-color-4
    public static var acPrimaryBgPressedColor: UIColor {
        return UDColor.getValueByKey(.acPrimaryBgPressedColor) ?? UDColor.fillPressed
    }

    /// As Primary Title Normal Color Color, Default Color: UDColor.neutralColor7
    public static var asPrimaryTitleNormalColor: UIColor {
        return UDColor.getValueByKey(.asPrimaryTitleNormalColor) ?? UDColor.textPlaceholder
    }

    /// As Primary Bg Normal Color Color, Default Color: UDColor.neutralColor1
    public static var asPrimaryBgNormalColor: UIColor {
        return UDColor.getValueByKey(.asPrimaryBgNormalColor) ?? UDColor.bgBody
    }
}
