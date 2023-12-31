//
//  UDNotice+Theme.swift
//  UniverseDesignNotice
//
//  Created by 龙伟伟 on 2020/11/19.
//

import UIKit
import Foundation
import UniverseDesignColor

/// UDColor Name Extension
public extension UDColor.Name {
    /// noticeInfoBgColor
    static let noticeInfoBgColor = UDColor.Name("notice-info-bg-color")
    /// noticeInfoIconColor
    static let noticeInfoIconColor = UDColor.Name("notice-info-icon-color")

    /// noticeSuccessBgColor
    static let noticeSuccessBgColor = UDColor.Name("notice-success-bg-color")
    /// noticeSuccessIconColor
    static let noticeSuccessIconColor = UDColor.Name("notice-success-icon-color")

    /// noticeWarningBgColor
    static let noticeWarningBgColor = UDColor.Name("notice-warning-bg-color")
    /// noticeWarningIconColor
    static let noticeWarningIconColor = UDColor.Name("notice-warning-icon-color")

    /// noticeErrorBgColor
    static let noticeErrorBgColor = UDColor.Name("notice-error-bg-color")
    /// noticeErrorIconColor
    static let noticeErrorIconColor = UDColor.Name("notice-error-icon-color")

    /// noticeTextColor
    static let noticeTextColor = UDColor.Name("notice-text-color")
    /// noticeButtonTextColor
    static let noticeButtonTextColor = UDColor.Name("notice-button-text-color")
    /// noticeLinkTextColor
    static let noticeLinkTextColor = UDColor.Name("notice-link-text-color")
}

/// UDNotice Color Theme
public struct UDNoticeColorTheme {

    /// noticeInfoBgColor, Default Color: primaryColor2
    public static var noticeInfoBgColor: UIColor {
        return UDColor.getValueByKey(.noticeInfoBgColor) ?? UDColor.primaryFillSolid01
    }

    /// noticeInfoIconColor, Default Color: primaryColor6
    public static var noticeInfoIconColor: UIColor {
        return UDColor.getValueByKey(.noticeInfoIconColor) ?? UDColor.functionInfoContentDefault
    }

    /// noticeSuccessBgColor, Default Color: successColor2
    public static var noticeSuccessBgColor: UIColor {
        return UDColor.getValueByKey(.noticeSuccessBgColor) ?? UDColor.functionSuccessFillSolid01
    }

    /// noticeSuccessIconColor, Default Color: successColor6
    public static var noticeSuccessIconColor: UIColor {
        return UDColor.getValueByKey(.noticeSuccessIconColor) ?? UDColor.functionSuccessContentDefault
    }

    /// noticeWarningBgColor, Default Color: warningColor2
    public static var noticeWarningBgColor: UIColor {
        return UDColor.getValueByKey(.noticeWarningBgColor) ?? UDColor.functionWarningFillSolid01
    }

    /// noticeWarningIconColor, Default Color: warningColor6
    public static var noticeWarningIconColor: UIColor {
        return UDColor.getValueByKey(.noticeWarningIconColor) ?? UDColor.functionWarningContentDefault
    }

    /// noticeErrorBgColor, Default Color: alertColor2
    public static var noticeErrorBgColor: UIColor {
        return UDColor.getValueByKey(.noticeErrorBgColor) ?? UDColor.functionDangerFillSolid01
    }

    /// noticeErrorIconColor, Default Color: alertColor6
    public static var noticeErrorIconColor: UIColor {
        return UDColor.getValueByKey(.noticeErrorIconColor) ?? UDColor.functionDangerContentDefault
    }

    /// noticeTextColor, Default Color: neutralColor12
    public static var noticeTextColor: UIColor {
        return UDColor.getValueByKey(.noticeTextColor) ?? UDColor.textTitle
    }

    /// noticeButtonTextColor, Default Color: primaryColor6
    public static var noticeButtonTextColor: UIColor {
        return UDColor.getValueByKey(.noticeButtonTextColor) ?? UDColor.primaryContentDefault
    }

    /// noticeLinkTextColor, Default Color: primaryColor7
    public static var noticeLinkTextColor: UIColor {
        return UDColor.getValueByKey(.noticeLinkTextColor) ?? UDColor.primaryContentDefault
    }
}
