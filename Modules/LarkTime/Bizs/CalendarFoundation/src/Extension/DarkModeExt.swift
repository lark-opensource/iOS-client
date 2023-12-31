//
//  DarkModeExt.swift
//  CalendarFoundation
//
//  Created by Rico on 2021/6/6.
//

import UIKit
import Foundation
import UniverseDesignColor
import UniverseDesignTheme

/// 和UX对齐的日历特有Token
public extension UDComponentsExtension where BaseType == UIColor {

    /// 日历[cal] - 日历业务的深浅模式[Light/Dark] - 字体色/背景色[Font/Bg] - 颜色代号[12种(Carmine、red、oran......)]

    /// Carmine
    static var calLightFontCarmine: UIColor {
        return UIColor.ud.C700
    }

    static var calLightBgCarmine: UIColor {
        return UIColor.ud.C100
    }

    static var calDarkFontCarmine: UIColor {
        return UIColor.ud.N00 & UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
    }

    static var calDarkBgCarmine: UIColor {
        return UIColor.ud.colorfulCarmine & UIColor.ud.C400
    }

    /// Red
    static var calLightFontRed: UIColor {
        return UIColor.ud.R700
    }

    static var calLightBgRed: UIColor {
        return UIColor.ud.R100
    }

    static var calDarkFontRed: UIColor {
        return UIColor.ud.N00 & UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
    }

    static var calDarkBgRed: UIColor {
        return UIColor.ud.colorfulRed & UIColor.ud.R400
    }

    /// Oran
    static var calLightFontOran: UIColor {
        return UIColor.ud.O700
    }

    static var calLightBgOran: UIColor {
        return UIColor.ud.O100
    }

    static var calDarkFontOran: UIColor {
        return UIColor.ud.N00 & UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
    }

    static var calDarkBgOran: UIColor {
        return UIColor.ud.colorfulOrange & UIColor.ud.O400
    }

    /// Yellow
    static var calLightFontYellow: UIColor {
        return UIColor.ud.Y700
    }

    static var calLightBgYellow: UIColor {
        return UIColor.ud.Y100
    }

    static var calDarkFontYellow: UIColor {
        return UIColor.ud.N00 & UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
    }

    static var calDarkBgYellow: UIColor {
        return UIColor.ud.Y600 & UIColor.ud.Y400
    }

    /// Green
    static var calLightFontGreen: UIColor {
        return UIColor.ud.G700
    }

    static var calLightBgGreen: UIColor {
        return UIColor.ud.G100
    }

    static var calDarkFontGreen: UIColor {
        return UIColor.ud.N00 & UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
    }

    static var calDarkBgGreen: UIColor {
        return UIColor.ud.G600 & UIColor.ud.G400
    }

    /// Tur
    static var calLightFontTur: UIColor {
        return UIColor.ud.T700
    }

    static var calLightBgTur: UIColor {
        return UIColor.ud.T100
    }

    static var calDarkFontTur: UIColor {
        return UIColor.ud.N00 & UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
    }

    static var calDarkBgTur: UIColor {
        return UIColor.ud.T600 & UIColor.ud.T400
    }

    /// Blue
    static var calLightFontBlue: UIColor {
        return UIColor.ud.B700
    }

    static var calLightBgBlue: UIColor {
        return UIColor.ud.B100
    }

    static var calDarkFontBlue: UIColor {
        return UIColor.ud.N00 & UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
    }

    static var calDarkBgBlue: UIColor {
        return UIColor.ud.colorfulBlue & UIColor.ud.B400
    }

    /// Wathet
    static var calLightFontWathet: UIColor {
        return UIColor.ud.W700
    }

    static var calLightBgWathet: UIColor {
        return UIColor.ud.W50
    }

    static var calDarkFontWathet: UIColor {
        return UIColor.ud.N00 & UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
    }

    static var calDarkBgWathet: UIColor {
        return UIColor.ud.W600 & UIColor.ud.W400
    }

    /// Indigo
    static var calLightFontIndigo: UIColor {
        return UIColor.ud.I700
    }

    static var calLightBgIndigo: UIColor {
        return UIColor.ud.I100
    }

    static var calDarkFontIndigo: UIColor {
        return UIColor.ud.N00 & UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
    }

    static var calDarkBgIndigo: UIColor {
        return UIColor.ud.I600 & UIColor.ud.I400
    }

    /// Purple
    static var calLightFontPurple: UIColor {
        return UIColor.ud.P700
    }

    static var calLightBgPurple: UIColor {
        return UIColor.ud.P100
    }

    static var calDarkFontPurple: UIColor {
        return UIColor.ud.N00 & UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
    }

    static var calDarkBgPurple: UIColor {
        return UIColor.ud.colorfulPurple & UIColor.ud.P400
    }

    /// Violet
    static var calLightFontViolet: UIColor {
        return UIColor.ud.V700
    }

    static var calLightBgViolet: UIColor {
        return UIColor.ud.V100
    }

    static var calDarkFontViolet: UIColor {
        return UIColor.ud.N00 & UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
    }

    static var calDarkBgViolet: UIColor {
        return UIColor.ud.V600 & UIColor.ud.V400
    }

    /// Neutral
    static var calLightFontNeutral: UIColor {
        return UIColor.ud.N700
    }

    static var calLightBgNeutral: UIColor {
        return UIColor.ud.N300
    }

    static var calDarkFontNeutral: UIColor {
        return UIColor.ud.N00 & UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
    }

    static var calDarkBgNeutral: UIColor {
        return UIColor.ud.N600 & UIColor.ud.N500
    }

    /// 日历视图页背景色（日程块所在背景）
    static var calEventViewBg: UIColor {
        return UIColor.ud.bgBody & UIColor.ud.bgBase
    }

    // MARK: - 会议室签到

    /// 空闲背景色
    static var calTokenSigninBgFree: UIColor {
        return UDColor.T600 & UDColor.T300
    }

    /// 已开始进度条背景色
    static var calTokenBeginProcessBg: UIColor {
        return UDColor.N600 & UDColor.N200
    }

    /// 使用中背景色
    static var calTokenSigninBgUsing: UIColor {
        return UDColor.R600 & UDColor.R300
    }

    /// 已开始背景色
    static var calTokenSigninBgProcess: UIColor {
        return UDColor.colorfulBlue & UDColor.B400
    }

    /// RSVP待定按钮边界色
    static var calTokenBtnSelectedLineGray: UIColor {
        return UDColor.N600
    }

    /// 跨时区优化太阳颜色
    static var calTokenTagColourDay: UIColor {
        return UIColor(red: 226 / 255, green: 155 / 255, blue: 0, alpha: 1) & UIColor(red: 207 / 255, green: 149 / 255, blue: 0, alpha: 1)
    }
}

/// 研发自定义的颜色方法
public enum DarkMode {}

public extension DarkMode {
    static var pickerTopGradient: (top: UIColor, bottom: UIColor) {
        (
            UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(1.0) & UIColor.ud.bgBody.withAlphaComponent(1.0),
            UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.0) & UIColor.ud.bgBody.withAlphaComponent(0.0)
        )
    }

    /// 和top的上下相反
    static var pickerBottomGradient: (top: UIColor, bottom: UIColor) {
        (pickerTopGradient.bottom, pickerTopGradient.top)
    }
}

extension DarkMode {
    public enum IconColor {
        /// n1 用于可点 icon，顶部区域
        case n1
        /// n2 用于可点 icon，非顶部区域
        case n2
        /// n3 用于不可点 icon
        case n3
        /// n3 用于 disable icon
        case n4
        case primaryOnPrimaryFill
        case primaryPri500

        var uiColor: UIColor {
            switch self {
            case .n1: return UIColor.ud.iconN1
            case .n2: return UIColor.ud.iconN2
            case .n3: return UIColor.ud.iconN3
            case .n4: return UIColor.ud.iconDisabled
            case .primaryOnPrimaryFill: return UIColor.ud.primaryOnPrimaryFill
            case .primaryPri500: return UIColor.ud.primaryPri500
            }
        }
    }
}

extension UIImage {
    public func renderColor(with color: DarkMode.IconColor, renderingMode: UIImage.RenderingMode = .automatic) -> UIImage {
        return self.ud.withTintColor(color.uiColor, renderingMode: renderingMode)
    }
    /// 顶部图标默认大小
    public func scaleNaviSize() -> UIImage {
        return ud.resized(to: CGSize(width: 24, height: 24))
    }

    /// 提示信息图标默认大小，一般用于 list 内
    public func scaleInfoSize() -> UIImage {
        return ud.resized(to: CGSize(width: 16, height: 16))
    }
}
