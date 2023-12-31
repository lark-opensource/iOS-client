//
//  Extension.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/19.
//

import UIKit
import Foundation
import RustPB
import LarkTag
import TangramService
import TangramComponent
import UniverseDesignFont
import UniverseDesignColor

extension Basic_V1_URLPreviewComponent.Orientation {
    var tcOrientation: Orientation {
        switch self {
        case .row: return .row
        case .rowReverse: return .rowReverse
        case .column: return .column
        case .columnReverse: return .columnReverse
        @unknown default: return .row
        }
    }
}

extension Basic_V1_URLPreviewComponent.FlexWrap {
    var tcFlexWrap: FlexWrap {
        switch self {
        case .noWrap: return .noWrap
        case .wrap: return .wrap
        case .wrapReverse: return .wrapReverse
        case .linearWrap: return .linearWrap
        @unknown default: return .noWrap
        }
    }
}

extension Basic_V1_URLPreviewComponent.Justify {
    var tcJustify: Justify {
        switch self {
        case .start: return .start
        case .center: return .center
        case .end: return .end
        case .spaceBetween: return .spaceBetween
        case .spaceArround: return .spaceArround
        case .spaceEvenly: return .spaceEvenly
        @unknown default: return .start
        }
    }
}

extension Basic_V1_URLPreviewComponent.Align {
    var tcAlign: Align {
        switch self {
        case .top: return .top
        case .middle: return .middle
        case .bottom: return .bottom
        case .stretch: return .stretch
        case .baseline: return .baseline
        @unknown default: return .top
        }
    }
}

extension Basic_V1_Tag {
    var larkTag: LarkTag.TagType? {
        switch self {
        case .unknownTag: return nil
        case .official: return .officialOncall
        case .onCall: return .oncall
        case .bot: return .robot
        case .meeting: return nil
        case .approval: return nil
        case .secretChat: return .crypto
        case .whole: return nil
        case .department: return .team
        case .external: return .external
        case .public: return .public
        case .groupAdmin: return nil
        case .supervisor: return .supervisor
        case .stopped: return nil
        case .offline: return nil
        case .deleted: return nil
        case .unactivated: return nil
        case .edu: return nil
        case .frozen: return .isFrozen
        case .oncallOffline: return .oncallOffline
        @unknown default: return nil
        }
    }
}

extension Basic_V1_URLPreviewComponent.ValueType {
    var tcUnit: TCUnit {
        switch self {
        case .auto: return .auto
        case .percentage: return .percentage
        case .point: return .pixcel
        @unknown default: return .undefined
        }
    }
}

extension Basic_V1_URLPreviewComponent.Value {
    var tcValue: TCValue {
        return TCValue(value: CGFloat(value), unit: type.tcUnit)
    }
}

extension Basic_V1_Gradient.Linear {
    func sync(to style: RenderComponentStyle) {
        guard !colorsV2.isEmpty else { return }
        if colorsV2.count == 1 {
            style.backgroundColor = colorsV2[0].color
        } else {
            var gradientStyle = GradientStyle()
            gradientStyle.colors = colorsV2.compactMap { $0.color }
            let endPoint = self.endPoint()
            let startPoint = CGPoint(x: 1.0 - endPoint.x, y: 1.0 - endPoint.y)
            gradientStyle.startPoint = startPoint
            gradientStyle.endPoint = endPoint
            style.gradientStyle = gradientStyle
        }
    }

    /// deg = 0时，默认从下往上方向，以顺时针为正方向
    func fixDegree() -> Double {
        var degree = Double(Int(deg) % 360)
        if degree < 0 { // 负角度转换为正角度
            degree = 360 + degree
        }
        return degree
    }

    func endPoint() -> CGPoint {
        let degree = fixDegree()
        var x = 0.0
        var y = 0.0
        let tanX = tan(degree * Double.pi / 180)
        if degree >= 0, degree <= 180 { // 0 ~ 180
            x = min(1.0, 0.5 + abs(0.5 * tanX))
        } else {
            x = max(0, 0.5 - abs(0.5 * tanX))
        }
        let cotY = 1.0 / tanX
        if (degree >= 0 && degree <= 90) || (degree >= 270 && degree <= 360) {
            y = max(0, 0.5 - abs(0.5 * cotY))
        } else {
            y = min(1, 0.5 + abs(0.5 * cotY))
        }
        return .init(x: x, y: y)
    }
}

extension Basic_V1_URLPreviewComponent.FontLevel {
    var font: UIFont? {
        var fontType: String
        switch type {
        case .body: fontType = "body"
        case .caption: fontType = "caption"
        case .headline: fontType = "headline"
        case .title: fontType = "title"
        @unknown default: fontType = "body"
        }
        // headline只有一种且不能带数字，对齐PC识别，兼容headline带数字情况
        if hasLevel, type != .headline {
            fontType.append("\(level)")
        }
        return UIFont.named(fontType)
    }
}

extension Basic_V1_URLPreviewComponent.Style {
    var tcTextColor: UIColor? {
        if !hasTextColorV2 { return nil }
        return textColorV2.color
    }

    var tcBackgroundColor: UIColor? {
        if !hasBackgroundColor { return nil }
        return backgroundColor.linear.colorsV2.first?.color
    }

    var tcBorderColor: UIColor? {
        if !hasBorder { return nil }
        return border.colorV2.color
    }

    var tcFont: UIFont? {
        if !hasFontLevel { return nil }
        return fontLevel.font
    }

    func syncBackgroundColor(to style: RenderComponentStyle) {
        guard hasBackgroundColor else { return }
        switch backgroundColor.type {
        case .linear: backgroundColor.linear.sync(to: style)
        @unknown default: assertionFailure("unknown case")
        }
    }
}

extension Basic_V1_CardComponent.Orientation {
    var tcOrientation: Orientation {
        switch self {
        case .row: return .row
        case .rowReverse: return .rowReverse
        case .column: return .column
        case .columnReverse: return .columnReverse
        @unknown default: return .row
        }
    }
}

extension Basic_V1_CardComponent.FlexWrap {
    var tcFlexWrap: FlexWrap {
        switch self {
        case .noWrap: return .noWrap
        case .wrap: return .wrap
        case .wrapReverse: return .wrapReverse
        case .linearWrap: return .linearWrap
        @unknown default: return .noWrap
        }
    }
}

extension Basic_V1_CardComponent.Justify {
    var tcJustify: Justify {
        switch self {
        case .start: return .start
        case .center: return .center
        case .end: return .end
        case .spaceBetween: return .spaceBetween
        case .spaceAround: return .spaceArround
        case .spaceEvenly: return .spaceEvenly
        @unknown default: return .start
        }
    }
}

extension Basic_V1_CardComponent.Align {
    var tcAlign: Align {
        switch self {
        case .top: return .top
        case .middle: return .middle
        case .bottom: return .bottom
        case .stretch: return .stretch
        case .baseline: return .baseline
        @unknown default: return .top
        }
    }
}

extension Basic_V1_CardComponent.ValueType {
    var tcUnit: TCUnit {
        switch self {
        case .auto: return .auto
        case .percentage: return .percentage
        case .point: return .pixcel
        @unknown default: return .undefined
        }
    }
}

extension Basic_V1_CardComponent.Value {
    var tcValue: TCValue {
        return TCValue(value: CGFloat(value), unit: type.tcUnit)
    }
}
