//
//  UDCardHeaderColorScheme.swift
//  UniverseDesignCardHeader
//
//  Created by Siegfried on 2021/8/26.
//

import UIKit
import Foundation
import UniverseDesignColor

/// UDColor Name Extension
public extension UDColor.Name {
    // 背景色
    static let udtokenMessageCardBgBlue = UDColor.Name("udtoken-message-card-bg-blue")
    static let udtokenMessageCardBgWathet = UDColor.Name("udtoken-message-card-bg-wathet")
    static let udtokenMessageCardBgTurquoise = UDColor.Name("udtoken-message-card-bg-turquoise")
    static let udtokenMessageCardBgGreen = UDColor.Name("udtoken-message-card-bg-green")
    static let udtokenMessageCardBgLime = UDColor.Name("udtoken-message-card-bg-lime")
    static let udtokenMessageCardBgYellow = UDColor.Name("udtoken-message-card-bg-yellow")
    static let udtokenMessageCardBgOrange = UDColor.Name("udtoken-message-card-bg-orange")
    static let udtokenMessageCardBgRed = UDColor.Name("udtoken-message-card-bg-red")
    static let udtokenMessageCardBgCarmine = UDColor.Name("udtoken-message-card-bg-carmine")
    static let udtokenMessageCardBgViolet = UDColor.Name("udtoken-message-card-bg-violet")
    static let udtokenMessageCardBgPurple = UDColor.Name("udtoken-message-card-bg-purple")
    static let udtokenMessageCardBgIndigo = UDColor.Name("udtoken-message-card-bg-indigo")
    static let udtokenMessageCardBgNeural = UDColor.Name("udtoken-message-card-bg-neural")

    // 模糊色
    static let udtokenMessageCardBgMaskGeneral = UDColor.Name("udtoken-message-card-bg-mask-general")
    static let udtokenMessageCardBgMaskSpecial = UDColor.Name("udtoken-message-card-bg-mask-special")

    // 文字色
    static let udtokenMessageCardTextBlue = UDColor.Name("udtoken-message-card-text-blue")
    static let udtokenMessageCardTextWathet = UDColor.Name("udtoken-message-card-text-wathet")
    static let udtokenMessageCardTextTurquoise = UDColor.Name("udtoken-message-card-text-turquoise")
    static let udtokenMessageCardTextGreen = UDColor.Name("udtoken-message-card-text-green")
    static let udtokenMessageCardTextLime = UDColor.Name("udtoken-message-card-text-lime")
    static let udtokenMessageCardTextYellow = UDColor.Name("udtoken-message-card-text-yellow")
    static let udtokenMessageCardTextOrange = UDColor.Name("udtoken-message-card-text-orange")
    static let udtokenMessageCardTextRed = UDColor.Name("udtoken-message-card-text-red")
    static let udtokenMessageCardTextCarmine = UDColor.Name("udtoken-message-card-text-carmine")
    static let udtokenMessageCardTextViolet = UDColor.Name("udtoken-message-card-text-violet")
    static let udtokenMessageCardTextPurple = UDColor.Name("udtoken-message-card-text-purple")
    static let udtokenMessageCardTextIndigo = UDColor.Name("udtoken-message-card-text-indigo")
    static let udtokenMessageCardTextNeutral = UDColor.Name("udtoken-message-card-text-neutral")
}

/// 消息卡片颜色主题
public struct UDCardHeaderColorScheme {

    // 背景
    public static var udtokenMessageCardBgBlue: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardBgBlue) ?? UDColor.B100 & UDColor.B100
    }

    public static var udtokenMessageCardBgWathet: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardBgWathet) ?? UDColor.W100 & UDColor.W100
    }

    public static var udtokenMessageCardBgTurquoise: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardBgTurquoise) ?? UDColor.T100 & UDColor.T100
    }

    public static var udtokenMessageCardBgGreen: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardBgGreen) ?? UDColor.G100 & UDColor.G100
    }

    public static var udtokenMessageCardBgLime: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardBgLime) ?? UDColor.L100 & UDColor.L100
    }

    public static var udtokenMessageCardBgYellow: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardBgYellow) ?? UDColor.Y100 & UDColor.Y100
    }

    public static var udtokenMessageCardBgOrange: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardBgOrange) ?? UDColor.O100 & UDColor.O100
    }

    public static var udtokenMessageCardBgRed: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardBgRed) ?? UDColor.R100 & UDColor.R100
    }

    public static var udtokenMessageCardBgCarmine: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardBgCarmine) ?? UDColor.C100 & UDColor.C100
    }

    public static var udtokenMessageCardBgViolet: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardBgViolet) ?? UDColor.V100 & UDColor.V100
    }

    public static var udtokenMessageCardBgPurple: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardBgPurple) ?? UDColor.P100 & UDColor.P100
    }

    public static var udtokenMessageCardBgIndigo: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardBgIndigo) ?? UDColor.I100 & UDColor.I100
    }

    public static var udtokenMessageCardBgNeural: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardBgNeural) ?? UDColor.N500 & UDColor.N300
    }

    // 模糊颜色
    public static var udtokenMessageCardBgMaskGeneral: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardBgMaskGeneral) ?? UDColor.N00.withAlphaComponent(0.5) & UDColor.N00.withAlphaComponent(0.3)
    }

    public static var udtokenMessageCardBgMaskSpecial: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardBgMaskSpecial) ?? UDColor.N00.withAlphaComponent(0.2) & UDColor.N00.withAlphaComponent(0.3)
    }


    // 文字
    public static var udtokenMessageCardTextBlue: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardTextBlue) ?? UDColor.B600 & UDColor.B700
    }

    static var udtokenMessageCardTextWathet: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardTextWathet) ?? UDColor.W700 & UDColor.W700
    }

    static var udtokenMessageCardTextTurquoise: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardTextTurquoise) ?? UDColor.T700 & UDColor.T700
    }

    static var udtokenMessageCardTextGreen: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardTextGreen) ?? UDColor.G700 & UDColor.G700
    }

    static var udtokenMessageCardTextLime: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardTextLime) ?? UDColor.L700 & UDColor.L700
    }

    static var udtokenMessageCardTextYellow: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardTextYellow) ?? UDColor.Y700 & UDColor.Y700
    }

    static var udtokenMessageCardTextOrange: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardTextOrange) ?? UDColor.O600 & UDColor.O700
    }

    static var udtokenMessageCardTextRed: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardTextRed) ?? UDColor.R600 & UDColor.R700
    }

    static var udtokenMessageCardTextCarmine: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardTextCarmine) ?? UDColor.C600 & UDColor.C700
    }

    static var udtokenMessageCardTextViolet: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardTextViolet) ?? UDColor.V600 & UDColor.V700
    }

    static var udtokenMessageCardTextPurple: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardTextPurple) ?? UDColor.P600 & UDColor.P700
    }

    static var udtokenMessageCardTextIndigo: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardTextIndigo) ?? UDColor.I600 & UDColor.I700
    }

    static var udtokenMessageCardTextDeepNeural: UIColor {
        return UDColor.getValueByKey(.udtokenMessageCardTextNeutral) ?? UDColor.N00 & UDColor.N650
    }
    
}
