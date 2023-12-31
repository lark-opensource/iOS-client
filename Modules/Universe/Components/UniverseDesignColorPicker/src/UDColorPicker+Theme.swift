//
//  UDColorPicker+Theme.swift
//  UniverseDesignColorPicker
//
//  Created by panzaofeng on 2020/12/1.
//

import UIKit
import Foundation
import UniverseDesignColor

/// UDColor Name Extension
public extension UDColor.Name {

    /// ColorPicker Background Color Key
    static let colorPickerBgColor = UDColor.Name("colorPicker-bg-color")

    /// ColorPicker Text Color Key
    static let colorPickerTitleTextColor = UDColor.Name("colorPicker-title-text-color")

    /// ColorPicker Border Color Key
    static let colorPickerBorderColor = UDColor.Name("colorPicker-border-color")

    /// ColorPicker Border Color Key
    static let colorPickerInnerTextBorderColor = UDColor.Name("colorPicker-innertext-border-color")

    /// ColorPicker text background Color Key
    static let colorPickerTextBackgroundColor = UDColor.Name("colorPicker-text-background-color")

    /// ColorPicker text default Color Key
    static let colorPickerTextDefaultColor = UDColor.Name("colorPicker-text-default-color")
}

/// UDColorPicker Color Theme
public struct UDColorPickerColorTheme {

    /// ColorPicker Background  Color, Default Color: neutralColor1
    static var colorPickerBgColor: UIColor {
        return UDColor.getValueByKey(.colorPickerBgColor) ?? UDColor.bgBody
    }

    /// ColorPicker Text  Color, Default Color: neutralColor12
    static var colorPickerTitleTextColor: UIColor {
        return UDColor.getValueByKey(.colorPickerTitleTextColor) ?? UDColor.textTitle
    }

    /// ColorPicker Border  Color, Default Color: primaryColor6
    static var colorPickerBorderColor: UIColor {
        return UDColor.getValueByKey(.colorPickerBorderColor) ?? UDColor.primaryFillDefault
    }

    /// ColorPicker inner text Border Color, Default Color: neutralColor5
    static var colorPickerInnerTextBorderColor: UIColor {
        return UDColor.getValueByKey(.colorPickerInnerTextBorderColor) ?? UDColor.lineBorderCard
    }

    /// ColorPicker text background Border Color, Default Color: neutralColor1
    static var colorPickerTextBackgroundColor: UIColor {
        return UDColor.getValueByKey(.colorPickerTextBackgroundColor) ?? UDColor.bgBody
    }

    /// ColorPicker text default Color, Default Color: neutralColor12
    static var colorPickerTextDefaultColor: UIColor {
        return UDColor.getValueByKey(.colorPickerTextDefaultColor) ?? UDColor.textTitle
    }
}

/// UDColor Name Extension
public extension UDColor.Name {
    /// ColorPicker Base Model Color0 Key
    static let baseModelColor0 = UDColor.Name("colorPicker-BaseModel-color0")
    /// ColorPicker Base Model Color1 Key
    static let baseModelColor1 = UDColor.Name("colorPicker-BaseModel-clor1")
    /// ColorPicker Base Model Color2 Key
    static let baseModelColor2 = UDColor.Name("colorPicker-BaseModel-color2")
    /// ColorPicker Base Model Color3 Key
    static let baseModelColor3 = UDColor.Name("colorPicker-BaseModel-color3")
    /// ColorPicker Base Model Color4 Key
    static let baseModelColor4 = UDColor.Name("colorPicker-BaseModel-color4")
    /// ColorPicker Base Model Color5 Key
    static let baseModelColor5 = UDColor.Name("colorPicker-BaseModel-color5")
    /// ColorPicker Base Model Color6 Key
    static let baseModelColor6 = UDColor.Name("colorPicker-BaseModel-color6")
    /// ColorPicker Base Model Color7 Key
    static let baseModelColor7 = UDColor.Name("colorPicker-BaseModel-color7")
    /// ColorPicker Base Model Color8 Key
    static let baseModelColor8 = UDColor.Name("colorPicker-BaseModel-color8")
    /// ColorPicker Base Model Color9 Key
    static let baseModelColor9 = UDColor.Name("colorPicker-BaseModel-color9")
    /// ColorPicker Base Model Color10 Key
    static let baseModelColor10 = UDColor.Name("colorPicker-BaseModel-color10")
    /// ColorPicker Base Model Color11 Key
    static let baseModelColor11 = UDColor.Name("colorPicker-BaseModel-color11")
}

/// UDColorPicker Color Theme
public extension UDColorPickerColorTheme {
    /// ColorPicker BaseMode  Color0, Default Color: colorfulCarmine
    static var baseModelColor0: UIColor {
        return UDColor.getValueByKey(.baseModelColor0) ?? UDColor.udtokenColorpickerCarmine
    }
    /// ColorPicker BaseMode  Color1, Default Color: colorfulRed
    static var baseModelColor1: UIColor {
        return UDColor.getValueByKey(.baseModelColor1) ?? UDColor.udtokenColorpickerRed
    }
    /// ColorPicker BaseMode  Color2, Default Color: colorfulOrange
    static var baseModelColor2: UIColor {
        return UDColor.getValueByKey(.baseModelColor2) ?? UDColor.udtokenColorpickerOrange
    }
    /// ColorPicker BaseMode  Color3, Default Color: colorfulYellow
    static var baseModelColor3: UIColor {
        return UDColor.getValueByKey(.baseModelColor3) ?? UDColor.udtokenColorpickerYellow
    }
    /// ColorPicker BaseMode  Color4, Default Color: colorfulGreen
    static var baseModelColor4: UIColor {
        return UDColor.getValueByKey(.baseModelColor4) ?? UDColor.udtokenColorpickerGreen
    }
    /// ColorPicker BaseMode  Color5, Default Color: colorfulTurquoise
    static var baseModelColor5: UIColor {
        return UDColor.getValueByKey(.baseModelColor5) ?? UDColor.udtokenColorpickerTurquoise
    }
    /// ColorPicker BaseMode  Color6, Default Color: colorfulBlue
    static var baseModelColor6: UIColor {
        return UDColor.getValueByKey(.baseModelColor6) ?? UDColor.udtokenColorpickerBlue
    }
    /// ColorPicker BaseMode  Color7, Default Color: colorfulWathet
    static var baseModelColor7: UIColor {
        return UDColor.getValueByKey(.baseModelColor7) ?? UDColor.udtokenColorpickerWathet
    }
    /// ColorPicker BaseMode  Color8, Default Color: colorfulIndigo
    static var baseModelColor8: UIColor {
        return UDColor.getValueByKey(.baseModelColor8) ?? UDColor.udtokenColorpickerIndigo
    }
    /// ColorPicker BaseMode  Color9, Default Color: colorfulPurple
    static var baseModelColor9: UIColor {
        return UDColor.getValueByKey(.baseModelColor9) ?? UDColor.udtokenColorpickerPurple
    }
    /// ColorPicker BaseMode  Color10, Default Color: colorfulViolet
    static var baseModelColor10: UIColor {
        return UDColor.getValueByKey(.baseModelColor10) ?? UDColor.udtokenColorpickerViolet
    }
    /// ColorPicker BaseMode  Color11, Default Color: N500
    static var baseModelColor11: UIColor {
        return UDColor.getValueByKey(.baseModelColor11) ?? UDColor.udtokenColorpickerNeutral
    }
}

/// UDColor Name Extension
public extension UDColor.Name {
    /// ColorPicker text Model Color0 Key
    static let textModelColor0 = UDColor.Name("colorPicker-TextModel-color0")
    /// ColorPicker text Model Color1 Key
    static let textModelColor1 = UDColor.Name("colorPicker-TextModel-color1")
    /// ColorPicker text Model Color2 Key
    static let textModelColor2 = UDColor.Name("colorPicker-TextModel-color2")
    /// ColorPicker text Model Color3 Key
    static let textModelColor3 = UDColor.Name("colorPicker-TextModel-color3")
    /// ColorPicker text Model Color4 Key
    static let textModelColor4 = UDColor.Name("colorPicker-TextModel-color4")
    /// ColorPicker text Model Color5 Key
    static let textModelColor5 = UDColor.Name("colorPicker-TextModel-color5")
    /// ColorPicker text Model Color6 Key
    static let textModelColor6 = UDColor.Name("colorPicker-TextModel-color6")
}

/// UDColorPicker Color Theme
public extension UDColorPickerColorTheme {
    /// ColorPicker TextModel  Color0, Default Color: R600
    static var textModelColor0: UIColor {
        return UDColor.getValueByKey(.textModelColor0) ?? UDColor.R500
    }
    /// ColorPicker TextModel  Color1, Default Color: O600
    static var textModelColor1: UIColor {
        return UDColor.getValueByKey(.textModelColor1) ?? UDColor.O400
    }
    /// ColorPicker TextModel  Color2, Default Color: Y600
    static var textModelColor2: UIColor {
        return UDColor.getValueByKey(.textModelColor2) ?? UDColor.Y400
    }
    /// ColorPicker TextModel  Color3, Default Color: G600
    static var textModelColor3: UIColor {
        return UDColor.getValueByKey(.textModelColor3) ?? UDColor.G500
    }
    /// ColorPicker TextModel  Color4, Default Color: B600
    static var textModelColor4: UIColor {
        return UDColor.getValueByKey(.textModelColor4) ?? UDColor.B600
    }
    /// ColorPicker TextModel  Color5, Default Color: P600
    static var textModelColor5: UIColor {
        return UDColor.getValueByKey(.textModelColor5) ?? UDColor.P700
    }
    /// ColorPicker TextModel  Color6, Default Color: N500
    static var textModelColor6: UIColor {
        return UDColor.getValueByKey(.textModelColor6) ?? UDColor.N500
    }
}

/// UDColor Name Extension
public extension UDColor.Name {
    /// ColorPicker text background Model Color0 Key
    static let textBackgroundModelColor0 = UDColor.Name("colorPicker-TextBackgroundModel-color0")
    /// ColorPicker text background Model Color1 Key
    static let textBackgroundModelColor1 = UDColor.Name("colorPicker-TextBackgroundModel-color1")
    /// ColorPicker text background Model Color2 Key
    static let textBackgroundModelColor2 = UDColor.Name("colorPicker-TextBackgroundModel-color2")
    /// ColorPicker text background Model Color3 Key
    static let textBackgroundModelColor3 = UDColor.Name("colorPicker-TextBackgroundModel-color3")
    /// ColorPicker text background Model Color4 Key
    static let textBackgroundModelColor4 = UDColor.Name("colorPicker-TextBackgroundModel-color4")
    /// ColorPicker text background Model Color5 Key
    static let textBackgroundModelColor5 = UDColor.Name("colorPicker-TextBackgroundModel-color5")
    /// ColorPicker text background Model Color6 Key
    static let textBackgroundModelColor6 = UDColor.Name("colorPicker-TextBackgroundModel-color6")
    /// ColorPicker text background Model Color7 Key
    static let textBackgroundModelColor7 = UDColor.Name("colorPicker-TextBackgroundModel-color7")
    /// ColorPicker text background Model Color8 Key
    static let textBackgroundModelColor8 = UDColor.Name("colorPicker-TextBackgroundModel-color8")
    /// ColorPicker text background Model Color9 Key
    static let textBackgroundModelColor9 = UDColor.Name("colorPicker-TextBackgroundModel-color9")
    /// ColorPicker text background Model Color10 Key
    static let textBackgroundModelColor10 = UDColor.Name("colorPicker-TextBackgroundModel-color10")
    /// ColorPicker text background Model Color11 Key
    static let textBackgroundModelColor11 = UDColor.Name("colorPicker-TextBackgroundModel-color11")
    /// ColorPicker text background Model Color12 Key
    static let textBackgroundModelColor12 = UDColor.Name("colorPicker-TextBackgroundModel-color12")
    /// ColorPicker text background Model Color13 Key
    static let textBackgroundModelColor13 = UDColor.Name("colorPicker-TextBackgroundModel-color13")
}

/// UDColorPicker Color Theme
public extension UDColorPickerColorTheme {
    /// ColorPicker TextBackgroundModel  Color0, Default Color: R200
    static var textBackgroundModelColor0: UIColor {
        return UDColor.getValueByKey(.textBackgroundModelColor0) ?? UDColor.R200
    }
    /// ColorPicker TextBackgroundModel  Color1, Default Color: O200
    static var textBackgroundModelColor1: UIColor {
        return UDColor.getValueByKey(.textBackgroundModelColor0) ?? UDColor.O200
    }
    /// ColorPicker TextBackgroundModel  Color2, Default Color: S100
    static var textBackgroundModelColor2: UIColor {
        return UDColor.getValueByKey(.textBackgroundModelColor2) ?? UDColor.S100
    }
    /// ColorPicker TextBackgroundModel  Color3, Default Color: G200
    static var textBackgroundModelColor3: UIColor {
        return UDColor.getValueByKey(.textBackgroundModelColor3) ?? UDColor.G200
    }
    /// ColorPicker TextBackgroundModel  Color4, Default Color: B200
    static var textBackgroundModelColor4: UIColor {
        return UDColor.getValueByKey(.textBackgroundModelColor4) ?? UDColor.B200
    }
    /// ColorPicker TextBackgroundModel  Color5, Default Color: P200
    static var textBackgroundModelColor5: UIColor {
        return UDColor.getValueByKey(.textBackgroundModelColor5) ?? UDColor.P200
    }
    /// ColorPicker TextBackgroundModel  Color6, Default Color: N300
    static var textBackgroundModelColor6: UIColor {
        return UDColor.getValueByKey(.textBackgroundModelColor6) ?? UDColor.N300
    }
    /// ColorPicker TextBackgroundModel  Color7, Default Color: R400
    static var textBackgroundModelColor7: UIColor {
        return UDColor.getValueByKey(.textBackgroundModelColor7) ?? UDColor.R400
    }
    /// ColorPicker TextBackgroundModel  Color8, Default Color: O350
    static var textBackgroundModelColor8: UIColor {
        return UDColor.getValueByKey(.textBackgroundModelColor8) ?? UDColor.O350
    }
    /// ColorPicker TextBackgroundModel  Color9, Default Color: S200
    static var textBackgroundModelColor9: UIColor {
        return UDColor.getValueByKey(.textBackgroundModelColor9) ?? UDColor.S200
    }
    /// ColorPicker TextBackgroundModel  Color10, Default Color: G350
    static var textBackgroundModelColor10: UIColor {
        return UDColor.getValueByKey(.textBackgroundModelColor10) ?? UDColor.G350
    }
    /// ColorPicker TextBackgroundModel  Color11, Default Color: B350
    static var textBackgroundModelColor11: UIColor {
        return UDColor.getValueByKey(.textBackgroundModelColor11) ?? UDColor.B350
    }
    /// ColorPicker TextBackgroundModel  Color12, Default Color: P350
    static var textBackgroundModelColor12: UIColor {
        return UDColor.getValueByKey(.textBackgroundModelColor12) ?? UDColor.P350
    }
    /// ColorPicker TextBackgroundModel  Color13, Default Color: N400
    static var textBackgroundModelColor13: UIColor {
        return UDColor.getValueByKey(.textBackgroundModelColor13) ?? UDColor.N400
    }
}
