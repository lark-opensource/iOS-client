//
//  CalendarColorToken.swift
//  CalendarFoundation
//
//  Created by Liang Hongbin on 11/7/22.
//

import UIKit
import Foundation
import UniverseDesignColor
import UniverseDesignTheme

/// 和UX对齐的日历特有Token
public extension UDComponentsExtension where BaseType == UIColor {

    static var LightBgBlue: UIColor {
        return UIColor.ud.B100 & UIColor.ud.B100
    }

    static var LightTextBlue: UIColor {
        return UIColor.ud.B700 & UIColor.ud.B600
    }

    static var StripeBlue: UIColor {
        return UIColor.ud.B50 & UIColor.ud.B50
    }

    static var LightBgBarBlue: UIColor {
        return UIColor.ud.B400 & UIColor.ud.B500
    }

    static var BorderUnansweredBlue: UIColor {
        return UIColor.ud.B400 & UDColor.rgb(0x5A7ABA)
    }

    static var LightTextUnansweredBlue: UIColor {
        return UDColor.rgb(0x3668DB) & UDColor.rgb(0x6C96E8)
    }

    static var LightBgCarmine: UIColor {
        return UIColor.ud.C100 & UIColor.ud.C100
    }

    static var LightTextCarmine: UIColor {
        return UIColor.ud.C700 & UIColor.ud.C600
    }

    static var StripeCarmine: UIColor {
        return UIColor.ud.C50 & UIColor.ud.C50
    }

    static var LightBgBarCarmine: UIColor {
        return UIColor.ud.C400 & UIColor.ud.C500
    }

    static var BorderUnansweredCarmine: UIColor {
        return UIColor.ud.C400 & UIColor.ud.C400
    }

    static var LightTextUnansweredCarmine: UIColor {
        return UDColor.rgb(0xB14481) & UIColor.ud.C500
    }

    static var LightBgGreen: UIColor {
        return UIColor.ud.G100 & UIColor.ud.G100
    }

    static var LightTextGreen: UIColor {
        return UIColor.ud.G700 & UIColor.ud.G600
    }

    static var StripeGreen: UIColor {
        return UIColor.ud.G50 & UIColor.ud.G50
    }

    static var LightBgBarGreen: UIColor {
        return UIColor.ud.G400 & UIColor.ud.G500
    }

    static var BorderUnansweredGreen: UIColor {
        return UIColor.ud.G400 & UIColor.ud.G350
    }

    static var LightTextUnansweredGreen: UIColor {
        return UDColor.rgb(0x388C2E) & UIColor.ud.G500
    }

    static var LightBgIndigo: UIColor {
        return UIColor.ud.I100 & UIColor.ud.I100
    }

    static var LightTextIndigo: UIColor {
        return UIColor.ud.I700 & UIColor.ud.I600
    }

    static var StripeIndigo: UIColor {
        return UIColor.ud.I50 & UIColor.ud.I50
    }

    static var LightBgBarIndigo: UIColor {
        return UIColor.ud.I400 & UIColor.ud.I500
    }

    static var BorderUnansweredIndigo: UIColor {
        return UIColor.ud.I400 & UIColor.ud.I400
    }

    static var LightTextUnansweredIndigo: UIColor {
        return UDColor.rgb(0x525AD4) & UIColor.ud.I500
    }

    static var LightBgNeutral: UIColor {
        return UIColor.ud.N300 & UIColor.ud.N200
    }

    static var LightTextNeutral: UIColor {
        return UIColor.ud.N650 & UIColor.ud.N650
    }

    static var StripeNeutral: UIColor {
        return UIColor.ud.N100 & UIColor.ud.N100
    }

    static var LightBgBarNeutral: UIColor {
        return UIColor.ud.N500 & UIColor.ud.N500
    }

    static var BorderUnansweredNeutral: UIColor {
        return UIColor.ud.N500 & UIColor.ud.N500
    }

    static var LightTextUnansweredNeutral: UIColor {
        return UIColor.ud.N600 & UIColor.ud.N600
    }

    static var LightBgOran: UIColor {
        return UIColor.ud.O100 & UIColor.ud.O100
    }

    static var LightTextOrange: UIColor {
        return UIColor.ud.O600 & UIColor.ud.O700
    }

    static var StripeOrange: UIColor {
        return UIColor.ud.O50 & UIColor.ud.O50
    }

    static var LightBgBarOrange: UIColor {
        return UIColor.ud.O400 & UIColor.ud.O400
    }

    static var BorderUnansweredOrange: UIColor {
        return UIColor.ud.O400 & UIColor.ud.O400
    }

    static var LightTextUnansweredOrange: UIColor {
        return UDColor.rgb(0xB66D36) & UDColor.rgb(0xE08E41)
    }

    static var LightBgPurple: UIColor {
        return UIColor.ud.P100 & UIColor.ud.P100
    }

    static var LightTextPurple: UIColor {
        return UIColor.ud.P800 & UIColor.ud.P600
    }

    static var StripePurple: UIColor {
        return UIColor.ud.P50 & UIColor.ud.P50
    }

    static var LightBgBarPurple: UIColor {
        return UIColor.ud.P400 & UIColor.ud.P500
    }

    static var BorderUnansweredPurple: UIColor {
        return UIColor.ud.P400 & UIColor.ud.P400
    }

    static var LightTextUnansweredPurple: UIColor {
        return UDColor.rgb(0x6D41B8) & UIColor.ud.P500
    }

    static var LightBgRed: UIColor {
        return UIColor.ud.R100 & UIColor.ud.R100
    }

    static var LightTextRed: UIColor {
        return UIColor.ud.R700 & UIColor.ud.R600
    }

    static var StripeRed: UIColor {
        return UIColor.ud.R50 & UIColor.ud.R50
    }

    static var LightBgBarRed: UIColor {
        return UIColor.ud.R400 & UIColor.ud.R400
    }

    static var BorderUnansweredRed: UIColor {
        return UIColor.ud.R400 & UIColor.ud.R400
    }

    static var LightTextUnansweredRed: UIColor {
        return UDColor.rgb(0xB85451) & UDColor.rgb(0xDC7572)
    }

    static var LightBgTur: UIColor {
        return UIColor.ud.T100 & UIColor.ud.T100
    }

    static var LightTextTur: UIColor {
        return UIColor.ud.T700 & UIColor.ud.T600
    }

    static var StripeTur: UIColor {
        return UIColor.ud.T50 & UIColor.ud.T50
    }

    static var LightBgBarTur: UIColor {
        return UIColor.ud.T400 & UIColor.ud.T500
    }

    static var BorderUnansweredTur: UIColor {
        return UIColor.ud.T400 & UIColor.ud.T350
    }

    static var LightTextUnansweredTur: UIColor {
        return UIColor.ud.T600 & UIColor.ud.T500
    }

    static var LightBgViolet: UIColor {
        return UIColor.ud.V100 & UIColor.ud.V100
    }

    static var LightTextViolet: UIColor {
        return UIColor.ud.V700 & UIColor.ud.V600
    }

    static var StripeViolet: UIColor {
        return UIColor.ud.V50 & UIColor.ud.V50
    }

    static var LightBgBarViolet: UIColor {
        return UIColor.ud.V400 & UIColor.ud.V500
    }

    static var BorderUnansweredViolet: UIColor {
        return UIColor.ud.V400 & UIColor.ud.V350
    }

    static var LightTextUnansweredViolet: UIColor {
        return UDColor.rgb(0x9F529F) & UDColor.rgb(0xCD75CD)
    }

    static var LightBgWathet: UIColor {
        return UIColor.ud.W100 & UIColor.ud.W100
    }

    static var LightTextWathet: UIColor {
        return UIColor.ud.W600 & UIColor.ud.W600
    }

    static var StripeWathet: UIColor {
        return UIColor.ud.W50 & UIColor.ud.W50
    }

    static var LightBgBarWathet: UIColor {
        return UIColor.ud.W400 & UIColor.ud.W500
    }

    static var BorderUnansweredWathet: UIColor {
        return UIColor.ud.W400 & UIColor.ud.W500
    }

    static var LightTextUnansweredWathet: UIColor {
        return UIColor.ud.W500 & UIColor.ud.W500
    }

    static var LightBgYellow: UIColor {
        return UIColor.ud.Y100 & UIColor.ud.Y100
    }

    static var LightTextYellow: UIColor {
        return UIColor.ud.Y600 & UIColor.ud.Y500
    }

    static var StripeYellow: UIColor {
        return UIColor.ud.Y50 & UIColor.ud.Y50
    }

    static var LightBgBarYellow: UIColor {
        return UIColor.ud.Y400 & UIColor.ud.Y400
    }

    static var BorderUnansweredYellow: UIColor {
        return UIColor.ud.Y400 & UIColor.ud.Y350
    }

    static var LightTextUnansweredYellow: UIColor {
        return UIColor.ud.Y500 & UIColor.ud.Y400
    }

    static var LightBgPendingCarmine: UIColor {
        return UIColor.ud.C50 & UDColor.rgb(0x351F2B)
    }

    static var LightBgPendingRed: UIColor {
        return UIColor.ud.R50 & UIColor.ud.R50
    }

    static var LightBgPendingOrange: UIColor {
        return UIColor.ud.O50 & UIColor.ud.O50
    }

    static var LightBgPendingYellow: UIColor {
        return UIColor.ud.Y50 & UIColor.ud.Y50
    }

    static var LightBgPendingGreen: UIColor {
        return UIColor.ud.G50 & UIColor.ud.G50
    }

    static var LightBgPendingTur: UIColor {
        return UIColor.ud.T50 & UIColor.ud.T50
    }

    static var LightBgPendingBlue: UIColor {
        return UIColor.ud.B50 & UDColor.rgb(0x192233)
    }

    static var LightBgPendingWathet: UIColor {
        return UIColor.ud.W50 & UIColor.ud.W50
    }

    static var LightBgPendingIndigo: UIColor {
        return UIColor.ud.I50 & UIColor.ud.I50
    }

    static var LightBgPendingPurple: UIColor {
        return UIColor.ud.P50 & UIColor.ud.P50
    }

    static var LightBgPendingViolet: UIColor {
        return UIColor.ud.V50 & UIColor.ud.V50
    }

    static var LightBgPendingNeutral: UIColor {
        return UIColor.ud.N50 & UDColor.rgb(0x282828)
    }

    static var DarkBgBlue: UIColor {
        return UIColor.ud.B400 & UIColor.ud.B400
    }

    static var DarkBgBarBlue: UIColor {
        return UIColor.ud.B500 & UIColor.ud.B500
    }

    static var DarkPendingBarBlue: UIColor {
        return UIColor.ud.B500 & UIColor.ud.B500
    }

    static var DarkBgPendingBlue: UIColor {
        return UIColor.ud.B400 & UIColor.ud.B350
    }

    static var DarkBgCarmine: UIColor {
        return UIColor.ud.C400 & UIColor.ud.C400
    }

    static var DarkBgBarCarmine: UIColor {
        return UIColor.ud.C500 & UIColor.ud.C500
    }

    static var DarkPendingBarCarmine: UIColor {
        return UIColor.ud.C500 & UIColor.ud.C500
    }

    static var DarkBgPendingCarmine: UIColor {
        return UDColor.rgb(0xE369AE) & UIColor.ud.C350
    }

    static var DarkBgGreen: UIColor {
        return UIColor.ud.G400 & UIColor.ud.G350
    }

    static var DarkBgBarGreen: UIColor {
        return UIColor.ud.G500 & UIColor.ud.G400
    }

    static var DarkPendingBarGreen: UIColor {
        return UIColor.ud.G600 & UIColor.ud.G500
    }

    static var DarkBgPendingGreen: UIColor {
        return UDColor.rgb(0x46A73B) & UIColor.ud.G300
    }

    static var DarkBgIndigo: UIColor {
        return UIColor.ud.I400 & UIColor.ud.I400
    }

    static var DarkBgBarIndigo: UIColor {
        return UIColor.ud.I500 & UIColor.ud.I500
    }

    static var DarkPendingBarIndigo: UIColor {
        return UIColor.ud.I500 & UIColor.ud.I500
    }

    static var DarkBgPendingIndigo: UIColor {
        return UIColor.ud.I400 & UIColor.ud.I350
    }

    static var DarkBgNeutral: UIColor {
        return UDColor.rgb(0x83888F) & UIColor.ud.N400
    }

    static var DarkBgBarNeutral: UIColor {
        return UIColor.ud.N600.withAlphaComponent(0.6) & UIColor.ud.N500
    }

    static var DarkPendingBarNeutral: UIColor {
        return UIColor.ud.N600.withAlphaComponent(0.85) & UIColor.ud.N500
    }

    static var DarkBgPendingNeutral: UIColor {
        return UIColor.ud.N500 & UIColor.ud.N350
    }

    static var DarkBgOrange: UIColor {
        return UIColor.ud.O400 & UIColor.ud.O400
    }

    static var DarkBgBarOrange: UIColor {
        return UIColor.ud.O500 & UIColor.ud.O500
    }

    static var DarkPendingBarOrange: UIColor {
        return UIColor.ud.O500 & UIColor.ud.O500
    }

    static var DarkBgPendingOrange: UIColor {
        return UIColor.ud.O400 & UIColor.ud.O350
    }

    static var DarkBgPurple: UIColor {
        return UIColor.ud.P400 & UIColor.ud.P400
    }

    static var DarkBgBarPurple: UIColor {
        return UIColor.ud.P500 & UIColor.ud.P500
    }

    static var DarkPendingBarPurple: UIColor {
        return UIColor.ud.P500 & UIColor.ud.P500
    }

    static var DarkBgPendingPurple: UIColor {
        return UIColor.ud.P400 & UIColor.ud.P350
    }

    static var DarkBgRed: UIColor {
        return UDColor.rgb(0xF5605B) & UIColor.ud.R400
    }

    static var DarkBgBarRed: UIColor {
        return UIColor.ud.R500 & UIColor.ud.R500
    }

    static var DarkPendingBarRed: UIColor {
        return UIColor.ud.R500 & UIColor.ud.R500
    }

    static var DarkBgPendingRed: UIColor {
        return UDColor.rgb(0xF5605B) & UIColor.ud.R350
    }

    static var DarkBgTur: UIColor {
        return UIColor.ud.T400 & UIColor.ud.T400
    }

    static var DarkBgBarTur: UIColor {
        return UIColor.ud.T500 & UIColor.ud.T500
    }

    static var DarkPendingBarTur: UIColor {
        return UIColor.ud.T500 & UIColor.ud.T500
    }

    static var DarkBgPendingTur: UIColor {
        return UIColor.ud.T400 & UIColor.ud.T350
    }

    static var DarkBgViolet: UIColor {
        return UIColor.ud.V400 & UIColor.ud.V400
    }

    static var DarkBgBarViolet: UIColor {
        return UIColor.ud.V500 & UIColor.ud.V500
    }

    static var DarkPendingBarViolet: UIColor {
        return UIColor.ud.V500 & UIColor.ud.V500
    }

    static var DarkBgPendingViolet: UIColor {
        return UIColor.ud.V400 & UIColor.ud.V350
    }

    static var DarkBgWathet: UIColor {
        return UIColor.ud.W400 & UIColor.ud.W400
    }

    static var DarkBgBarWathet: UIColor {
        return UIColor.ud.W500 & UIColor.ud.W500
    }

    static var DarkPendingBarWathet: UIColor {
        return UIColor.ud.W500 & UIColor.ud.W500
    }

    static var DarkBgPendingWathet: UIColor {
        return UIColor.ud.W400 & UIColor.ud.W350
    }

    static var DarkBgYellow: UIColor {
        return UIColor.ud.Y500 & UIColor.ud.Y350
    }

    static var DarkBgBarYellow: UIColor {
        return UIColor.ud.Y600 & UIColor.ud.Y400
    }

    static var DarkPendingBarYellow: UIColor {
        return UIColor.ud.Y600 & UIColor.ud.Y400
    }

    static var DarkBgPendingYellow: UIColor {
        return UIColor.ud.Y500 & UIColor.ud.Y300
    }

    static var DetailBgLeftTur: UIColor {
        return UIColor.ud.T350 & UIColor.ud.T500
    }

    static var DetailBgRightTur: UIColor {
        return UIColor.ud.T400 & UIColor.ud.T600
    }

    static var DetailBgLeftRed: UIColor {
        return UIColor.ud.R350 & UIColor.ud.R500
    }

    static var DetailBgRightRed: UIColor {
        return UIColor.ud.R400 & UIColor.ud.R500
    }

    static var DetailBgLeftGreen: UIColor {
        return UIColor.ud.G300 & UIColor.ud.G500
    }

    static var DetailBgRightGreen: UIColor {
        return UIColor.ud.G400 & UIColor.ud.G600
    }

    static var DetailBgLeftOrange: UIColor {
        return UIColor.ud.O300 & UIColor.ud.O500
    }

    static var DetailBgRightOrange: UIColor {
        return UIColor.ud.O400 & UIColor.ud.O600
    }

    static var DetailBgLeftWathet: UIColor {
        return UIColor.ud.W350 & UIColor.ud.W400
    }

    static var DetailBgRightWathet: UIColor {
        return UIColor.ud.W400 & UIColor.ud.W500
    }
}
