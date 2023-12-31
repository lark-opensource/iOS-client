//
//  MailColorToken.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/5/30.
//

import Foundation
import FigmaKit
import UniverseDesignColor

extension UDColor {
    static var composeErrBubbleTextHover: UIColor {
        return UDColor.functionDanger700 & UDColor.functionDanger700
    }

    static var composeDefaultBubbleBgNormal: UIColor {
        return UDColor.N200 & UDColor.N350
    }

    static var composeDefaultBubbleBgSelected: UIColor {
        return UDColor.B100 & UDColor.B350
    }

    static var composeErrBubbleBgNormal: UIColor {
        return UDColor.functionDanger100 & UDColor.functionDanger100
    }

    static var composeErrBubbleBgSelected: UIColor {
        return UDColor.functionDanger500 & UDColor.functionDanger350
    }

    static var composeFontSizeBgSelected: UIColor {
        return UDColor.N00 & UDColor.N200
    }

    static var readMsgListBG: UIColor {
        return UDColor.rgb(0xF2F3F5) & UDColor.rgb(0x0A0A0A)
    }

    static func attachmentCardBgBlue(withSize size: CGSize) -> UIColor {
        let lightColor = GradientPattern(direction: .leftToRight, colors: [UDColor.rgb(0xE0E6FF), UDColor.rgb(0xF8F7FE)])
        let darkColor = GradientPattern(direction: .leftToRight, colors: [UDColor.rgb(0x263451), UDColor.rgb(0x22273A)])
        return (lightColor.toColor(withSize: size) ?? UDColor.rgb(0xE0E6FF)) & (darkColor.toColor(withSize: size) ?? UDColor.rgb(0x263451))
    }

    static func attachmentCardBgRed(withSize size: CGSize) -> UIColor {
        let lightColor = GradientPattern(direction: .leftToRight, colors: [UDColor.rgb(0xFFE9E8), UDColor.rgb(0xFFF7F2)])
        let darkColor = GradientPattern(direction: .leftToRight, colors: [UDColor.rgb(0x4B3232), UDColor.rgb(0x2F221F)])
        return (lightColor.toColor(withSize: size) ?? UDColor.rgb(0xFFE9E8)) & (darkColor.toColor(withSize: size) ?? UDColor.rgb(0x4B3232))
    }

    static func attachmentCardBgGreen(withSize size: CGSize) -> UIColor {
        let lightColor = GradientPattern(direction: .leftToRight, colors: [UDColor.rgb(0xDEF6D9), UDColor.rgb(0xF4FAEA)])
        let darkColor = GradientPattern(direction: .leftToRight, colors: [UDColor.rgb(0x253A25), UDColor.rgb(0x202B1F)])
        return (lightColor.toColor(withSize: size) ?? UDColor.rgb(0xDEF6D9)) & (darkColor.toColor(withSize: size) ?? UDColor.rgb(0x253A25))
    }

    static func attachmentCardBgOrange(withSize size: CGSize) -> UIColor {
        let lightColor = GradientPattern(direction: .leftToRight, colors: [UDColor.rgb(0xFFEADE), UDColor.rgb(0xFFF7EC)])
        let darkColor = GradientPattern(direction: .leftToRight, colors: [UDColor.rgb(0x432F23), UDColor.rgb(0x2F251A)])
        return (lightColor.toColor(withSize: size) ?? UDColor.rgb(0xFFEADE)) & (darkColor.toColor(withSize: size) ?? UDColor.rgb(0x432F23))
    }

    static func attachmentCardBgViolet(withSize size: CGSize) -> UIColor {
        let lightColor = GradientPattern(direction: .leftToRight, colors: [UDColor.rgb(0xFFE5FF), UDColor.rgb(0xFFF3FA)])
        let darkColor = GradientPattern(direction: .leftToRight, colors: [UDColor.rgb(0x432944), UDColor.rgb(0x2E202F)])
        return (lightColor.toColor(withSize: size) ?? UDColor.rgb(0xFFE5FF)) & (darkColor.toColor(withSize: size) ?? UDColor.rgb(0x432944))
    }

    static func attachmentCardBgYellow(withSize size: CGSize) -> UIColor {
        let lightColor = GradientPattern(direction: .leftToRight, colors: [UDColor.rgb(0xFFEED0), UDColor.rgb(0xFEF7E7)])
        let darkColor = GradientPattern(direction: .leftToRight, colors: [UDColor.rgb(0x403A26), UDColor.rgb(0x2D2A1E)])
        return (lightColor.toColor(withSize: size) ?? UDColor.rgb(0xFFEED0)) & (darkColor.toColor(withSize: size) ?? UDColor.rgb(0x403A26))
    }

    static func attachmentCardBgGrey(withSize size: CGSize) -> UIColor {
        let lightColor = GradientPattern(direction: .leftToRight, colors: [UDColor.rgb(0xEAEEF3), UDColor.rgb(0xF6F7FA)])
        let darkColor = GradientPattern(direction: .leftToRight, colors: [UDColor.rgb(0x313639), UDColor.rgb(0x28292F)])
        return (lightColor.toColor(withSize: size) ?? UDColor.rgb(0xEAEEF3)) & (darkColor.toColor(withSize: size) ?? UDColor.rgb(0x313639))
    }
}
