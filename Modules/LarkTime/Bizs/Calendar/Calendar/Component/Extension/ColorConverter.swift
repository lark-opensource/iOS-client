//
//  ColorConverter.swift
//  Calendar
//
//  Created by jiayi zou on 2018/4/19.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import RustPB
import UniverseDesignColor

/// 详情页头部的颜色
struct EventDetailColor {
    /// 渐变色
    var gradientColors: [UIColor]
    /// 会话icon颜色
    var chatEnterColor: UIColor
}

/// Aurora 详情页 header 配色
struct AuroraEventDetailColor {
    // 背景极光色 (main, sub, reflection)
    let backgroundColors: (UIColor, UIColor, UIColor)
    // 文本颜色
    let textColor: UIColor
    // 按钮文字颜色
    let buttonTextColor: UIColor
    // 按钮背景色
    let buttonBackgroundColor: UIColor
    // 颜色方块颜色
    let markerColor: UIColor
    // 标签背景色、文本颜色
    let relationTagColor: (UIColor, UIColor)
    // 极光色透明度
    var auroraOpacity: CGFloat = 0.15
}

struct ColorCombo {

    // eventColorIndex: (mainColor, subColor, reflectionColor)
    static let auroraColorMap: [ColorIndex: AuroraEventDetailColor] = [
        .carmine: AuroraEventDetailColor(
            backgroundColors: (UDColor.C350, UDColor.C300, UDColor.C200),
            textColor: UDColor.C600,
            buttonTextColor: UDColor.C600,
            buttonBackgroundColor: UDColor.C50 & UDColor.C600.withAlphaComponent(0.1),
            markerColor: UDColor.C400,
            relationTagColor: (UDColor.udtokenTagBgCarmineSolid, UDColor.udtokenTagTextSCarmine)
        ),
        .red: AuroraEventDetailColor(
            backgroundColors: (UDColor.R350, UDColor.R300, UDColor.R200),
            textColor: UDColor.R600,
            buttonTextColor: UDColor.R600,
            buttonBackgroundColor: UDColor.R50 & UDColor.R600.withAlphaComponent(0.1),
            markerColor: UDColor.R400,
            relationTagColor: (UDColor.udtokenTagBgRedSolid, UDColor.udtokenTagTextSRed))
        ,
        .orange: AuroraEventDetailColor(
            backgroundColors: (UDColor.O350, UDColor.O300, UDColor.O200),
            textColor: UDColor.O600,
            buttonTextColor: UDColor.O600,
            buttonBackgroundColor: UDColor.O50 & UDColor.O600.withAlphaComponent(0.1),
            markerColor: UDColor.O400,
            relationTagColor: (UDColor.udtokenTagBgOrangeSolid, UDColor.udtokenTagTextSOrange)
        ),
        .yellow: AuroraEventDetailColor(
            backgroundColors: (UDColor.Y350, UDColor.Y300, UDColor.Y200),
            textColor: UDColor.Y600,
            buttonTextColor: UDColor.Y600,
            buttonBackgroundColor: UDColor.Y50 & UDColor.Y600.withAlphaComponent(0.1),
            markerColor: UDColor.Y400,
            relationTagColor: (UDColor.udtokenTagBgYellowSolid, UDColor.udtokenTagTextSYellow)
        ),
        .green: AuroraEventDetailColor(
            backgroundColors: (UDColor.G350, UDColor.G300, UDColor.G200),
            textColor: UDColor.G600,
            buttonTextColor: UDColor.G600,
            buttonBackgroundColor: UDColor.G50 & UDColor.G600.withAlphaComponent(0.1),
            markerColor: UDColor.G400,
            relationTagColor: (UDColor.udtokenTagBgGreenSolid, UDColor.udtokenTagTextSGreen)
        ),
        .turquoise: AuroraEventDetailColor(
            backgroundColors: (UDColor.T350, UDColor.T300, UDColor.T200),
            textColor: UDColor.T600,
            buttonTextColor: UDColor.T600,
            buttonBackgroundColor: UDColor.T50 & UDColor.T600.withAlphaComponent(0.1),
            markerColor: UDColor.T400,
            relationTagColor: (UDColor.udtokenTagBgTurquoiseSolid, UDColor.udtokenTagTextSTurquoise)
        ),
        .blue: AuroraEventDetailColor(
            backgroundColors: (UDColor.B350, UDColor.B300, UDColor.B200),
            textColor: UDColor.B700,
            buttonTextColor: UDColor.B600,
            buttonBackgroundColor: UDColor.B50 & UDColor.B600.withAlphaComponent(0.1),
            markerColor: UDColor.B400,
            relationTagColor: (UDColor.udtokenTagBgBlueSolid, UDColor.udtokenTagTextSBlue),
            auroraOpacity: 0.2
        ),
        .wathet: AuroraEventDetailColor(
            backgroundColors: (UDColor.W350, UDColor.W300, UDColor.W200),
            textColor: UDColor.W600,
            buttonTextColor: UDColor.W600,
            buttonBackgroundColor: UDColor.W50 & UDColor.W600.withAlphaComponent(0.1),
            markerColor: UDColor.W400,
            relationTagColor: (UDColor.udtokenTagBgWathetSolid, UDColor.udtokenTagTextSWathet)
        ),
        .indigo: AuroraEventDetailColor(
            backgroundColors: (UDColor.I350, UDColor.I300, UDColor.I200),
            textColor: UDColor.I600,
            buttonTextColor: UDColor.I600,
            buttonBackgroundColor: UDColor.I50 & UDColor.I600.withAlphaComponent(0.1),
            markerColor: UDColor.I400,
            relationTagColor: (UDColor.udtokenTagBgIndigoSolid, UDColor.udtokenTagTextSIndigo)
        ),
        .purple: AuroraEventDetailColor(
            backgroundColors: (UDColor.P350, UDColor.P300, UDColor.P200),
            textColor: UDColor.P600,
            buttonTextColor: UDColor.P600,
            buttonBackgroundColor: UDColor.P50 & UDColor.P600.withAlphaComponent(0.1),
            markerColor: UDColor.P400,
            relationTagColor: (UDColor.udtokenTagBgPurpleSolid, UDColor.udtokenTagTextSPurple)
        ),
        .violet: AuroraEventDetailColor(
            backgroundColors: (UDColor.V350, UDColor.V300, UDColor.V200),
            textColor: UDColor.V600,
            buttonTextColor: UDColor.V600,
            buttonBackgroundColor: UDColor.V50 & UDColor.V600.withAlphaComponent(0.1),
            markerColor: UDColor.V400,
            relationTagColor: (UDColor.udtokenTagBgVioletSolid, UDColor.udtokenTagTextSViolet)
        ),
        .neutral: AuroraEventDetailColor(
            backgroundColors: (UDColor.N600, UDColor.N500, UDColor.N350),
            textColor: UDColor.N700,
            buttonTextColor: UDColor.N650,
            buttonBackgroundColor: UDColor.N50 & UDColor.N600.withAlphaComponent(0.1),
            markerColor: UDColor.N500,
            relationTagColor: (UDColor.udtokenTagNeutralBgSolid, UDColor.udtokenTagNeutralTextSolid)
        )
    ]

    private(set) var auroraEventDetailColor: AuroraEventDetailColor = AuroraEventDetailColor(
        backgroundColors: (UDColor.B350, UDColor.B300, UDColor.B200),
        textColor: UDColor.B700,
        buttonTextColor: UDColor.B600,
        buttonBackgroundColor: UDColor.B50 & UDColor.B600.withAlphaComponent(0.1),
        markerColor: UDColor.B400,
        relationTagColor: (UDColor.udtokenTagBgBlueSolid, UDColor.udtokenTagTextSBlue),
        auroraOpacity: 0.2
    )

    init(colorIndex: ColorIndex) {
        if let auroraEventDetailColor = ColorCombo.auroraColorMap[colorIndex] {
            self.auroraEventDetailColor = auroraEventDetailColor
        }
    }

    static func colorCombo(fromColorIndex index: ColorIndex) -> ColorCombo {
        ColorCombo(colorIndex: index)
    }
}

extension CalendarModel {
    func toColorCombo() -> ColorCombo {
        return ColorCombo.colorCombo(fromColorIndex: self.colorIndex)
    }
}

extension RustPB.Calendar_V1_Calendar {
    func toColorCombo() -> ColorCombo {
        return ColorCombo.colorCombo(fromColorIndex: self.personalizationSettings.colorIndex)
    }
}
