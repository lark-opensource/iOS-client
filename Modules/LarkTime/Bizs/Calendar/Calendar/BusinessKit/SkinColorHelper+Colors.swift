//
//  SkinColorHelper+Colors.swift
//  Calendar
//
//  Created by Hongbin Liang on 9/26/23.
//

import Foundation
import RustPB
import CalendarFoundation

public typealias ColorIndex = RustPB.Calendar_V1_ColorIndex

extension ColorIndex {
    public var isNoneColor: Bool { self == .noneColor }
}

extension SkinColorHelper {

    static let colorsForPicker: [UIColor] = [
        .ud.udtokenColorpickerCarmine,
        .ud.udtokenColorpickerRed,
        .ud.udtokenColorpickerOrange,
        .ud.udtokenColorpickerYellow,
        .ud.udtokenColorpickerGreen,
        .ud.udtokenColorpickerTurquoise,
        .ud.udtokenColorpickerBlue,
        .ud.udtokenColorpickerWathet,
        .ud.udtokenColorpickerIndigo,
        .ud.udtokenColorpickerPurple,
        .ud.udtokenColorpickerViolet,
        .ud.udtokenColorpickerNeutral
    ]

    static let colorsGroupModern: [ColorIndex: ColorGroup] = [
        .carmine: .init(
            background: (.ud.LightBgCarmine, .ud.LightBgPendingCarmine),
            text: (.ud.LightTextCarmine, .ud.LightTextUnansweredCarmine),
            foreBar: (.ud.LightBgBarCarmine, .ud.LightBgBarCarmine),
            stripe: .ud.StripeCarmine, border: .ud.BorderUnansweredCarmine
        ),

        .red: .init(
            background: (.ud.LightBgRed, .ud.LightBgPendingRed),
            text: (.ud.LightTextRed, .ud.LightTextUnansweredRed),
            foreBar: (.ud.LightBgBarRed, .ud.LightBgBarRed),
            stripe: .ud.StripeRed, border: .ud.BorderUnansweredRed
        ),

        .orange: .init(
            background: (.ud.LightBgOran, .ud.LightBgPendingOrange),
            text: (.ud.LightTextOrange, .ud.LightTextUnansweredOrange),
            foreBar: (.ud.LightBgBarOrange, .ud.LightBgBarOrange),
            stripe: .ud.StripeOrange, border: .ud.BorderUnansweredOrange
        ),

        .yellow: .init(
            background: (.ud.LightBgYellow, .ud.LightBgPendingYellow),
            text: (.ud.LightTextYellow, .ud.LightTextUnansweredYellow),
            foreBar: (.ud.LightBgBarYellow, .ud.LightBgBarYellow),
            stripe: .ud.StripeYellow, border: .ud.BorderUnansweredYellow
        ),

        .green: .init(
            background: (.ud.LightBgGreen, .ud.LightBgPendingGreen),
            text: (.ud.LightTextGreen, .ud.LightTextUnansweredGreen),
            foreBar: (.ud.LightBgBarGreen, .ud.LightBgBarGreen),
            stripe: .ud.StripeGreen, border: .ud.BorderUnansweredGreen
        ),

        .turquoise: .init(
            background: (.ud.LightBgTur, .ud.LightBgPendingTur),
            text: (.ud.LightTextTur, .ud.LightTextUnansweredTur),
            foreBar: (.ud.LightBgBarTur, .ud.LightBgBarTur),
            stripe: .ud.StripeTur, border: .ud.BorderUnansweredTur
        ),

        .blue: .init(
            background: (.ud.LightBgBlue, .ud.LightBgPendingBlue),
            text: (.ud.LightTextBlue, .ud.LightTextUnansweredBlue),
            foreBar: (.ud.LightBgBarBlue, .ud.LightBgBarBlue),
            stripe: .ud.StripeBlue, border: .ud.BorderUnansweredBlue
        ),

        .wathet: .init(
            background: (.ud.LightBgWathet, .ud.LightBgPendingWathet),
            text: (.ud.LightTextWathet, .ud.LightTextUnansweredWathet),
            foreBar: (.ud.LightBgBarWathet, .ud.LightBgBarWathet),
            stripe: .ud.StripeWathet, border: .ud.BorderUnansweredWathet
        ),

        .indigo: .init(
            background: (.ud.LightBgIndigo, .ud.LightBgPendingIndigo),
            text: (.ud.LightTextIndigo, .ud.LightTextUnansweredIndigo),
            foreBar: (.ud.LightBgBarIndigo, .ud.LightBgBarIndigo),
            stripe: .ud.StripeIndigo, border: .ud.BorderUnansweredIndigo
        ),

        .purple: .init(
            background: (.ud.LightBgPurple, .ud.LightBgPendingPurple),
            text: (.ud.LightTextPurple, .ud.LightTextUnansweredPurple),
            foreBar: (.ud.LightBgBarPurple, .ud.LightBgBarPurple),
            stripe: .ud.StripePurple, border: .ud.BorderUnansweredPurple
        ),

        .violet: .init(
            background: (.ud.LightBgViolet, .ud.LightBgPendingViolet),
            text: (.ud.LightTextViolet, .ud.LightTextUnansweredViolet),
            foreBar: (.ud.LightBgBarViolet, .ud.LightBgBarViolet),
            stripe: .ud.StripeViolet, border: .ud.BorderUnansweredViolet
        ),

        .neutral: .init(
            background: (.ud.LightBgNeutral, .ud.LightBgPendingNeutral),
            text: (.ud.LightTextNeutral, .ud.LightTextUnansweredNeutral),
            foreBar: (.ud.LightBgBarNeutral, .ud.LightBgBarNeutral),
            stripe: .ud.StripeNeutral, border: .ud.BorderUnansweredNeutral
        )
    ]

    static let colorsGroupClasic: [ColorIndex: ColorGroup] = [
        .carmine: .init(
            background: (.ud.DarkBgCarmine, .ud.DarkBgPendingCarmine),
            text: (.ud.primaryOnPrimaryFill, .ud.LightTextUnansweredCarmine),
            foreBar: (.ud.DarkBgBarCarmine, .ud.DarkPendingBarCarmine),
            stripe: .ud.StripeCarmine, border: .ud.BorderUnansweredCarmine
        ),

        .red: .init(
            background: (.ud.DarkBgRed, .ud.DarkBgPendingRed),
            text: (.ud.primaryOnPrimaryFill, .ud.LightTextUnansweredRed),
            foreBar: (.ud.DarkBgBarRed, .ud.DarkPendingBarRed),
            stripe: .ud.StripeRed, border: .ud.BorderUnansweredRed
        ),

        .orange: .init(
            background: (.ud.DarkBgOrange, .ud.DarkBgPendingOrange),
            text: (.ud.primaryOnPrimaryFill, .ud.LightTextUnansweredOrange),
            foreBar: (.ud.DarkBgBarOrange, .ud.DarkPendingBarOrange),
            stripe: .ud.StripeOrange, border: .ud.BorderUnansweredOrange
        ),

        .yellow: .init(
            background: (.ud.DarkBgYellow, .ud.DarkBgPendingYellow),
            text: (.ud.primaryOnPrimaryFill, .ud.LightTextUnansweredYellow),
            foreBar: (.ud.DarkBgBarYellow, .ud.DarkPendingBarYellow),
            stripe: .ud.StripeYellow, border: .ud.BorderUnansweredYellow
        ),

        .green: .init(
            background: (.ud.DarkBgGreen, .ud.DarkBgPendingGreen),
            text: (.ud.primaryOnPrimaryFill, .ud.LightTextUnansweredGreen),
            foreBar: (.ud.DarkBgBarGreen, .ud.DarkPendingBarGreen),
            stripe: .ud.StripeGreen, border: .ud.BorderUnansweredGreen
        ),

        .turquoise: .init(
            background: (.ud.DarkBgTur, .ud.DarkBgPendingTur),
            text: (.ud.primaryOnPrimaryFill, .ud.LightTextUnansweredTur),
            foreBar: (.ud.DarkBgBarTur, .ud.DarkPendingBarTur),
            stripe: .ud.StripeTur, border: .ud.BorderUnansweredTur
        ),

        .blue: .init(
            background: (.ud.DarkBgBlue, .ud.DarkBgPendingBlue),
            text: (.ud.primaryOnPrimaryFill, .ud.LightTextUnansweredBlue),
            foreBar: (.ud.DarkBgBarBlue, .ud.DarkPendingBarBlue),
            stripe: .ud.StripeBlue, border: .ud.BorderUnansweredBlue
        ),

        .wathet: .init(
            background: (.ud.DarkBgWathet, .ud.DarkBgPendingWathet),
            text: (.ud.primaryOnPrimaryFill, .ud.LightTextUnansweredWathet),
            foreBar: (.ud.DarkBgBarWathet, .ud.DarkPendingBarWathet),
            stripe: .ud.StripeWathet, border: .ud.BorderUnansweredWathet
        ),

        .indigo: .init(
            background: (.ud.DarkBgIndigo, .ud.DarkBgPendingIndigo),
            text: (.ud.primaryOnPrimaryFill, .ud.LightTextUnansweredIndigo),
            foreBar: (.ud.DarkBgBarIndigo, .ud.DarkPendingBarIndigo),
            stripe: .ud.StripeIndigo, border: .ud.BorderUnansweredIndigo
        ),

        .purple: .init(
            background: (.ud.DarkBgPurple, .ud.DarkBgPendingPurple),
            text: (.ud.primaryOnPrimaryFill, .ud.LightTextUnansweredPurple),
            foreBar: (.ud.DarkBgBarPurple, .ud.DarkPendingBarPurple),
            stripe: .ud.StripePurple, border: .ud.BorderUnansweredPurple
        ),

        .violet: .init(
            background: (.ud.DarkBgViolet, .ud.DarkBgPendingViolet),
            text: (.ud.primaryOnPrimaryFill, .ud.LightTextUnansweredViolet),
            foreBar: (.ud.DarkBgBarViolet, .ud.DarkPendingBarViolet),
            stripe: .ud.StripeViolet, border: .ud.BorderUnansweredViolet
        ),

        .neutral: .init(
            background: (.ud.DarkBgNeutral, .ud.DarkBgPendingNeutral),
            text: (.ud.primaryOnPrimaryFill, .ud.LightTextUnansweredNeutral),
            foreBar: (.ud.DarkBgBarNeutral, .ud.DarkPendingBarNeutral),
            stripe: .ud.StripeNeutral, border: .ud.BorderUnansweredNeutral
        )
    ]
}
