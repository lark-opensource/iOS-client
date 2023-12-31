//
//  MailLabelTransformer.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/6/23.
//

import Foundation
import UniverseDesignColor
import UIKit

class MailLabelTransformer {
    struct LabelColor {
        let fontColor: UIColor
        let backgroundColor: UIColor
        let colorType: LabelColorType

        func fontToHex(alwaysLight: Bool = false) -> String {
            return alwaysLight ? fontColor.alwaysLight.hex8 ?? "" : fontColor.hex8 ?? ""
        }

        func bgToHex(alwaysLight: Bool = false) -> String {
            return alwaysLight ? backgroundColor.alwaysLight.hex8 ?? "" : backgroundColor.hex8 ?? ""
        }

        func cssFontToHex(alwaysLight: Bool = false) -> String {
            return alwaysLight ? fontColor.alwaysLight.mail.cssHexString ?? "" : fontColor.compatibleColor.mail.cssHexString ?? ""
        }

        func cssBgToHex(alwaysLight: Bool = false) -> String {
            return alwaysLight ? backgroundColor.alwaysLight.mail.cssHexString ?? "" : backgroundColor.compatibleColor.mail.cssHexString ?? ""
        }
    }

    static func transformLabelColor(backgroundColor: String) -> LabelColor {
        var type = LabelColorType.blue
        var font = UIColor.ud.udtokenTagTextSBlue
        var bg = UIColor.ud.udtokenTagBgBlue
        switch backgroundColor.lowercased() {
            //1
        case "#dee0e3", "#d4ddf2", "#e1eaff", "#828386", "#d3dcf2", "#bbbfc4", "#4E83FD", "#d5ddf2", "#ffffff", "#000000", "#d3ddf2", "#d5def2", "#e1e3e6":
            type = .blue
            font = UIColor.ud.udtokenTagTextSBlue
            bg = UIColor.ud.udtokenTagBgBlue
            //2
        case "#d9dbf2", "#d5d7f2", "#616ae5", "#d2d4f2", "#e0e2fa":
            type = .indigo
            font = UIColor.ud.udtokenTagTextSIndigo
            bg = UIColor.ud.udtokenTagBgIndigo
            //3
        case "#e0d6f2", "#e1d7f2", "#ded3f2", "#dfd4f2", "#ece2fe", "#7f3bf5":
            type = .purple
            font = UIColor.ud.udtokenTagTextSPurple
            bg = UIColor.ud.udtokenTagBgPurple
            //4
        case "#db66db", "#f2d7f2", "#f8def8", "#f2d6f2", "#f2d4f2":
            type = .violet
            font = UIColor.ud.udtokenTagTextSViolet
            bg = UIColor.ud.udtokenTagBgViolet
            //5
        case "#fdddef", "#f2d2e4", "#f2d0e3":
            type = .carmine
            font = UIColor.ud.udtokenTagTextSCarmine
            bg = UIColor.ud.udtokenTagBgCarmine
            //6
        case "#fde2e2", "#f2d8d6", "#f2d9d8", "#f2d8d8", "#f2d7d6", "#f76964":
            type = .red
            font = UIColor.ud.udtokenTagTextSRed
            bg = UIColor.ud.udtokenTagBgRed
            //7
        case "#f2e1cf", "#f2e2ce", "#f2e1ce", "#f2e1cd", "#f2eae1", "#feead2":
            type = .orange
            font = UIColor.ud.udtokenTagTextSOrange
            bg = UIColor.ud.udtokenTagBgOrange
            //8
        case "#fad355", "#f2e8cf", "#f2e7cd", "#faf1d1", "#f2eacf", "#f8e6ab", "#f2e7ce":
            type = .yellow
            font = UIColor.ud.udtokenTagTextSYellow
            bg = UIColor.ud.udtokenTagBgYellow
            //9
        case "#c3dd40", "#ecf2ce", "#ecf2cd", "#eef6c6", "#dfee96":
            type = .lime
            font = UIColor.ud.udtokenTagTextSLime
            bg = UIColor.ud.udtokenTagBgLime
            //10
        case "#296b22", "#d7f2d4", "#d9f5d6", "#b7edb1", "#62d256", "#d8f2d5":
            type = .green
            font = UIColor.ud.udtokenTagTextSGreen
            bg = UIColor.ud.udtokenTagBgGreen
            //11
        case "#cef2ed", "#a9efe6", "#cff2ed", "#cdf2ed", "#d5f6f2":
            type = .turquoise
            font = UIColor.ud.udtokenTagTextSTurquoise
            bg = UIColor.ud.udtokenTagBgTurquoise
            //12
        case "#d0e9f2", "#b1e8fc", "#cee8f2", "#d9f3fd", "#cfe9f2", "#d1e9f2":
            type = .wathet
            font = UIColor.ud.udtokenTagTextSWathet
            bg = UIColor.ud.udtokenTagBgWathet
        default:
            type = .blue
            font = UIColor.ud.udtokenTagTextSBlue
            bg = UIColor.ud.udtokenTagBgBlue
        }

        //generate result
        return LabelColor(fontColor: font, backgroundColor: bg, colorType: type)
    }
}

extension MailLabelTransformer {
    enum LabelColorType: CaseIterable {
        case blue
        case indigo
        case purple
        case violet
        case carmine
        case red
        case orange
        case yellow
        case lime
        case green
        case turquoise
        case wathet
    }
}

extension MailLabelTransformer.LabelColorType {

    /// 只能用于上报服务端的value值
    func bgColorValue() -> String {
        switch self {
        case .blue: return "#e1eaff"
        case .indigo: return "#e0e2fa"
        case .purple: return "#ece2fe"
        case .violet: return "#f8def8"
        case .carmine: return "#fdddef"
        case .red: return "#fde2e2"
        case .orange: return "#feead2"
        case .yellow: return "#f8e6ab"
        case .lime: return "#dfee96"
        case .green: return "#b7edb1"
        case .turquoise: return "#a9efe6"
        case .wathet: return "#b1e8fc"
        }
    }

    /// 标签背景颜色
    func displayBgColor() -> UIColor {
        switch self {
        case .blue: return UIColor.ud.udtokenTagBgBlue
        case .indigo: return UIColor.ud.udtokenTagBgIndigo
        case .purple: return UIColor.ud.udtokenTagBgPurple
        case .violet: return UIColor.ud.udtokenTagBgViolet
        case .carmine: return UIColor.ud.udtokenTagBgCarmine
        case .red: return UIColor.ud.udtokenTagBgRed
        case .orange: return UIColor.ud.udtokenTagBgOrange
        case .yellow: return UIColor.ud.udtokenTagBgYellow
        case .lime: return UIColor.ud.udtokenTagBgLime
        case .green: return UIColor.ud.udtokenTagBgGreen
        case .turquoise: return UIColor.ud.udtokenTagBgTurquoise
        case .wathet: return UIColor.ud.udtokenTagBgWathet
        }
    }

    /// 只能用于上报服务端的value值
    func fontColorValue() -> String {
        switch self {
        case .blue: return "#3370ff"
        case .indigo: return "#4954e6"
        case .purple: return "#7f3bf5"
        case .violet: return "#d136d1"
        case .carmine: return "#f01d94"
        case .red: return "#f54a45"
        case .orange: return "#ff8800"
        case .yellow: return "#dc9b04"
        case .lime: return "#8fac02"
        case .green: return "#2ea121"
        case .turquoise: return "#078372"
        case .wathet: return "#037eaa"
        }
    }

    /// 标签字体颜色
    func displayFontColor() -> UIColor {
        switch self {
        case .blue: return UIColor.ud.udtokenTagTextSBlue
        case .indigo: return UIColor.ud.udtokenTagTextSIndigo
        case .purple: return UIColor.ud.udtokenTagTextSPurple
        case .violet: return UIColor.ud.udtokenTagTextSViolet
        case .carmine: return UIColor.ud.udtokenTagTextSCarmine
        case .red: return UIColor.ud.udtokenTagTextSRed
        case .orange: return UIColor.ud.udtokenTagTextSOrange
        case .yellow: return UIColor.ud.udtokenTagTextSYellow
        case .lime: return UIColor.ud.udtokenTagTextSLime
        case .green: return UIColor.ud.udtokenTagTextSGreen
        case .turquoise: return UIColor.ud.udtokenTagTextSTurquoise
        case .wathet: return UIColor.ud.udtokenTagTextSWathet
        }
    }

    /// 创建标签色板颜色 & 标签列表 icon 颜色
    func displayPickerColor(forTagList: Bool = false) -> UIColor {
        switch self {
        case .blue: return UIColor.ud.colorfulBlue
        case .indigo: return UIColor.ud.colorfulIndigo
        case .purple: return UIColor.ud.colorfulPurple
        case .violet: return UIColor.ud.colorfulViolet
        case .carmine: return UIColor.ud.colorfulCarmine
        case .red: return UIColor.ud.colorfulRed
        case .orange: return UIColor.ud.colorfulOrange
        case .yellow: return forTagList ? UIColor.ud.Y400 : UIColor.ud.colorfulYellow
        case .lime: return UIColor.ud.colorfulLime
        case .green: return UIColor.ud.colorfulGreen
        case .turquoise: return UIColor.ud.colorfulTurquoise
        case .wathet: return UIColor.ud.colorfulWathet
        }
    }
}

extension MailClientLabel {
    private struct AssociatedKeys {
        static var lkMailLabelColor = "Lark.Mail.Label.Color"
    }

    var colorType: MailLabelTransformer.LabelColorType {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.lkMailLabelColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return (objc_getAssociatedObject(self, &AssociatedKeys.lkMailLabelColor) as? MailLabelTransformer.LabelColorType) ?? .blue
        }
    }
}
