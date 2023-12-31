//
//  UDColor+Theme.swift
//  Color
//
//  Created by 姚启灏 on 2020/8/4.
//

import UIKit
import Foundation
import UniverseDesignTheme

/// Primary Color
@available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
extension UDColor {
    /// Default Color colorfulBlue
    public static var primaryColor1: UIColor {
        return UDColor.getValueByKey(.primaryColor1) ?? UDColor.B50
    }

    /// Default Color B100
    public static var primaryColor2: UIColor {
        return UDColor.getValueByKey(.primaryColor2) ?? UDColor.B100
    }

    /// Default Color B200
    public static var primaryColor3: UIColor {
        return UDColor.getValueByKey(.primaryColor3) ?? UDColor.B200
    }

    /// Default Color B300
    public static var primaryColor4: UIColor {
        return UDColor.getValueByKey(.primaryColor4) ?? UDColor.B300
    }

    /// Default Color B400
    public static var primaryColor5: UIColor {
        return UDColor.getValueByKey(.primaryColor5) ?? UDColor.B400
    }

    /// Default Color colorfulBlue
    public static var primaryColor6: UIColor {
        return UDColor.getValueByKey(.primaryColor6) ?? UDColor.colorfulBlue
    }

    /// Default Color B600
    public static var primaryColor7: UIColor {
        return UDColor.getValueByKey(.primaryColor7) ?? UDColor.B600
    }

    /// Default Color B700
    public static var primaryColor8: UIColor {
        return UDColor.getValueByKey(.primaryColor8) ?? UDColor.B700
    }

    /// Default Color B800
    public static var primaryColor9: UIColor {
        return UDColor.getValueByKey(.primaryColor9) ?? UDColor.B800
    }

    /// Default Color B900
    public static var primaryColor10: UIColor {
        return UDColor.getValueByKey(.primaryColor10) ?? UDColor.B900
    }
}

/// Success Color
@available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
extension UDColor {
    /// Default Color G50
    public static var successColor1: UIColor {
        return UDColor.getValueByKey(.successColor1) ?? UDColor.G50
    }

    /// Default Color G100
    public static var successColor2: UIColor {
        return UDColor.getValueByKey(.successColor2) ?? UDColor.G100
    }

    /// Default Color G200
    public static var successColor3: UIColor {
        return UDColor.getValueByKey(.successColor3) ?? UDColor.G200
    }

    /// Default Color G300
    public static var successColor4: UIColor {
        return UDColor.getValueByKey(.successColor4) ?? UDColor.G300
    }

    /// Default Color G400
    public static var successColor5: UIColor {
        return UDColor.getValueByKey(.successColor5) ?? UDColor.G400
    }

    /// Default Color colorfulGreen
    public static var successColor6: UIColor {
        return UDColor.getValueByKey(.successColor6) ?? UDColor.colorfulGreen
    }

    /// Default Color G600
    public static var successColor7: UIColor {
        return UDColor.getValueByKey(.successColor7) ?? UDColor.G600
    }

    /// Default Color G700
    public static var successColor8: UIColor {
        return UDColor.getValueByKey(.successColor8) ?? UDColor.G700
    }

    /// Default Color G800
    public static var successColor9: UIColor {
        return UDColor.getValueByKey(.successColor9) ?? UDColor.G800
    }

    /// Default Color G900
    public static var successColor10: UIColor {
        return UDColor.getValueByKey(.successColor10) ?? UDColor.G900
    }
}

/// Warning Color1
@available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
extension UDColor {
    /// Default Color Y50
    public static var warningColor1: UIColor {
        return UDColor.getValueByKey(.warningColor1) ?? UDColor.O50
    }

    /// Default Color Y100
    public static var warningColor2: UIColor {
        return UDColor.getValueByKey(.warningColor2) ?? UDColor.O100
    }

    /// Default Color Y200
    public static var warningColor3: UIColor {
        return UDColor.getValueByKey(.warningColor3) ?? UDColor.O200
    }

    /// Default Color Y300
    public static var warningColor4: UIColor {
        return UDColor.getValueByKey(.warningColor4) ?? UDColor.O300
    }

    /// Default Color Y400
    public static var warningColor5: UIColor {
        return UDColor.getValueByKey(.warningColor5) ?? UDColor.O400
    }

    /// Default Color colorfulYellow
    public static var warningColor6: UIColor {
        return UDColor.getValueByKey(.warningColor6) ?? UDColor.colorfulOrange
    }

    /// Default Color Y600
    public static var warningColor7: UIColor {
        return UDColor.getValueByKey(.warningColor7) ?? UDColor.O600
    }

    /// Default Color Y700
    public static var warningColor8: UIColor {
        return UDColor.getValueByKey(.warningColor8) ?? UDColor.O700
    }

    /// Default Color Y800
    public static var warningColor9: UIColor {
        return UDColor.getValueByKey(.warningColor9) ?? UDColor.O800
    }

    /// Default Color Y900
    public static var warningColor10: UIColor {
        return UDColor.getValueByKey(.warningColor10) ?? UDColor.O900
    }
}

/// Alert Color
@available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
extension UDColor {
    /// Default Color R50
    public static var alertColor1: UIColor {
        return UDColor.getValueByKey(.alertColor1) ?? UDColor.R50
    }

    /// Default Color R100
    public static var alertColor2: UIColor {
        return UDColor.getValueByKey(.alertColor2) ?? UDColor.R100
    }

    /// Default Color R200
    public static var alertColor3: UIColor {
        return UDColor.getValueByKey(.alertColor3) ?? UDColor.R200
    }

    /// Default Color R300
    public static var alertColor4: UIColor {
        return UDColor.getValueByKey(.alertColor4) ?? UDColor.R300
    }

    /// Default Color R400
    public static var alertColor5: UIColor {
        return UDColor.getValueByKey(.alertColor5) ?? UDColor.R400
    }

    /// Default Color colorfulRed
    public static var alertColor6: UIColor {
        return UDColor.getValueByKey(.alertColor6) ?? UDColor.colorfulRed
    }

    /// Default Color R600
    public static var alertColor7: UIColor {
        return UDColor.getValueByKey(.alertColor7) ?? UDColor.R600
    }

    /// Default Color R700
    public static var alertColor8: UIColor {
        return UDColor.getValueByKey(.alertColor8) ?? UDColor.R700
    }

    /// Default Color R800
    public static var alertColor9: UIColor {
        return UDColor.getValueByKey(.alertColor9) ?? UDColor.R800
    }

    /// Default Color R900
    public static var alertColor10: UIColor {
        return UDColor.getValueByKey(.alertColor10) ?? UDColor.R900
    }
}

/// Neutral Color
@available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
extension UDColor {
    /// Default Color N00
    public static var neutralColor1: UIColor {
        return UDColor.getValueByKey(.neutralColor1) ?? UDColor.N00
    }

    /// Default Color N50
    public static var neutralColor2: UIColor {
        return UDColor.getValueByKey(.neutralColor2) ?? UDColor.N50
    }

    /// Default Color N100
    public static var neutralColor3: UIColor {
        return UDColor.getValueByKey(.neutralColor3) ?? UDColor.N100
    }

    /// Default Color N200
    public static var neutralColor4: UIColor {
        return UDColor.getValueByKey(.neutralColor4) ?? UDColor.N200
    }

    /// Default Color N300
    public static var neutralColor5: UIColor {
        return UDColor.getValueByKey(.neutralColor5) ?? UDColor.N300
    }

    /// Default Color N400
    public static var neutralColor6: UIColor {
        return UDColor.getValueByKey(.neutralColor6) ?? UDColor.N400
    }

    /// Default Color N500
    public static var neutralColor7: UIColor {
        return UDColor.getValueByKey(.neutralColor7) ?? UDColor.N500
    }

    /// Default Color N600
    public static var neutralColor8: UIColor {
        return UDColor.getValueByKey(.neutralColor8) ?? UDColor.N600
    }

    /// Default Color N650
    public static var neutralColor9: UIColor {
        return UDColor.getValueByKey(.neutralColor9) ?? UDColor.N650
    }

    /// Default Color N700
    public static var neutralColor10: UIColor {
        return UDColor.getValueByKey(.neutralColor10) ?? UDColor.N700
    }

    /// Default Color N800
    public static var neutralColor11: UIColor {
        return UDColor.getValueByKey(.neutralColor11) ?? UDColor.N800
    }

    /// Default Color N900
    public static var neutralColor12: UIColor {
        return UDColor.getValueByKey(.neutralColor12) ?? UDColor.N900
    }

    /// Default Color N950
    public static var neutralColor13: UIColor {
        return UDColor.getValueByKey(.neutralColor13) ?? UDColor.N950
    }

    /// Default Color N1000
    public static var neutralColor14: UIColor {
        return UDColor.getValueByKey(.neutralColor14) ?? UDColor.N1000
    }
}

/// Abstract theme color
@available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
extension UDColor {
    /// neutralColor1
    public static var backgroundColor: UIColor {
        return UDColor.getValueByKey(.backgroundColor) ?? UDColor.neutralColor1
    }

    /// neutralColor5
    public static var borderColor: UIColor {
        return UDColor.getValueByKey(.borderColor) ?? UDColor.neutralColor5
    }

    /// neutralColor1
    public static var borderColorInverse: UIColor {
        return UDColor.getValueByKey(.borderColorInverse) ?? UDColor.neutralColor1
    }

    /// neutralColor1.withAlphaComponent(0.15)
    public static var dividerColor: UIColor {
        return UDColor.getValueByKey(.dividerColor) ?? UDColor.neutralColor1.withAlphaComponent(0.15)
    }

    /// neutralColor1
    public static var dividerColorInverse: UIColor {
        return UDColor.getValueByKey(.dividerColorInverse) ?? UDColor.neutralColor1
    }

    /// neutralColor12
    public static var textColor: UIColor {
        return UDColor.getValueByKey(.textColor) ?? UDColor.neutralColor12
    }

    /// neutralColor1
    public static var textColorInverse: UIColor {
        return UDColor.getValueByKey(.textColorInverse) ?? UDColor.neutralColor1
    }

    /// neutralColor12
    public static var titleColor: UIColor {
        return UDColor.getValueByKey(.titleColor) ?? UDColor.neutralColor12
    }

    /// neutralColor1
    public static var titleColorInverse: UIColor {
        return UDColor.getValueByKey(.titleColorInverse) ?? UDColor.neutralColor1
    }

    /// B700
    public static var linkColor: UIColor {
        return UDColor.getValueByKey(.linkColor) ?? UDColor.primaryColor8
    }

    /// B400
    public static var linkColorInverse: UIColor {
        return UDColor.getValueByKey(.linkColorInverse) ?? UDColor.primaryColor5
    }

    /// neutralColor7
    public static var descriptionColor: UIColor {
        return UDColor.getValueByKey(.descriptionColor) ?? UDColor.neutralColor7
    }

    /// neutralColor1
    public static var descriptionColorInverse: UIColor {
        return UDColor.getValueByKey(.descriptionColorInverse) ?? UDColor.neutralColor1
    }

    /// neutralColor1
    public static var primaryIconColor: UIColor {
        return UDColor.getValueByKey(.primaryIconColor) ?? UDColor.neutralColor11
    }

    /// neutralColor1
    public static var primaryIconColorInverse: UIColor {
        return UDColor.getValueByKey(.primaryIconColorInverse) ?? UDColor.neutralColor1
    }

    /// neutralColor8
    public static var secondaryIconColor: UIColor {
        return UDColor.getValueByKey(.secondaryIconColor) ?? UDColor.neutralColor8
    }

    /// neutralColor1
    public static var secondaryIconColorInverse: UIColor {
        return UDColor.getValueByKey(.secondaryIconColorInverse) ?? UDColor.neutralColor1
    }

    /// neutralColor7
    public static var tertiaryIconColor: UIColor {
        return UDColor.getValueByKey(.tertiaryIconColor) ?? UDColor.neutralColor7
    }

    /// neutralColor1
    public static var tertiaryIconColorInverse: UIColor {
        return UDColor.getValueByKey(.tertiaryIconColorInverse) ?? UDColor.neutralColor1
    }
}

/// Primary Color
extension UDComponentsExtension where BaseType == UIColor {
    /// colorfulBlue
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var primaryColor1: UIColor { return UDColor.primaryColor1 }

    /// B100
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var primaryColor2: UIColor { return UDColor.primaryColor2 }

    /// B200
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var primaryColor3: UIColor { return UDColor.primaryColor3 }

    /// B300
    @available(*, deprecated, message: "Use standard token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var primaryColor4: UIColor { return UDColor.primaryColor4 }

    /// B400
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var primaryColor5: UIColor { return UDColor.primaryColor5 }

    /// colorfulBlue
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var primaryColor6: UIColor { return UDColor.primaryColor6 }

    /// B600
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var primaryColor7: UIColor { return UDColor.primaryColor7 }

    /// B700
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var primaryColor8: UIColor { return UDColor.primaryColor8 }

    /// B800
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var primaryColor9: UIColor { return UDColor.primaryColor9 }

    /// B900
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var primaryColor10: UIColor { return UDColor.primaryColor10 }
}

/// Success Color
extension UDComponentsExtension where BaseType == UIColor {
    /// G50
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var successColor1: UIColor { return UDColor.successColor1 }

    /// G100
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var successColor2: UIColor { return UDColor.successColor2 }

    /// G200
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var successColor3: UIColor { return UDColor.successColor3 }

    /// G300
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var successColor4: UIColor { return UDColor.successColor4 }

    /// G400
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var successColor5: UIColor { return UDColor.successColor5 }

    /// colorfulGreen
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var successColor6: UIColor { return UDColor.successColor6 }

    /// G600
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var successColor7: UIColor { return UDColor.successColor7 }

    /// G700
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var successColor8: UIColor { return UDColor.successColor8 }

    /// G800
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var successColor9: UIColor { return UDColor.successColor9 }

    /// G900
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var successColor10: UIColor { return UDColor.successColor10 }
}

/// Warning Color1
extension UDComponentsExtension where BaseType == UIColor {
    /// Y50
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var warningColor1: UIColor { return UDColor.warningColor1 }

    /// Y100
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var warningColor2: UIColor { return UDColor.warningColor2 }

    /// Y200
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var warningColor3: UIColor { return UDColor.warningColor3 }

    /// Y300
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var warningColor4: UIColor { return UDColor.warningColor4 }

    /// Y400
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var warningColor5: UIColor { return UDColor.warningColor5 }

    /// colorfulYellow
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var warningColor6: UIColor { return UDColor.warningColor6 }

    /// Y600
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var warningColor7: UIColor { return UDColor.warningColor7 }

    /// Y700
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var warningColor8: UIColor { return UDColor.warningColor8 }

    /// Y800
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var warningColor9: UIColor { return UDColor.warningColor9 }

    /// Y900
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var warningColor10: UIColor { return UDColor.warningColor10 }
}

/// Alert Color
extension UDComponentsExtension where BaseType == UIColor {
    /// R50
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var alertColor1: UIColor { return UDColor.alertColor1 }

    /// R100
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var alertColor2: UIColor { return UDColor.alertColor2 }

    /// R200
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var alertColor3: UIColor { return UDColor.alertColor3 }

    /// R300
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var alertColor4: UIColor { return UDColor.alertColor4 }

    /// R400
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var alertColor5: UIColor { return UDColor.alertColor5 }

    /// colorfulRed
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var alertColor6: UIColor { return UDColor.alertColor6 }

    /// R600
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var alertColor7: UIColor { return UDColor.alertColor7 }

    /// R700
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var alertColor8: UIColor { return UDColor.alertColor8 }

    /// R800
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var alertColor9: UIColor { return UDColor.alertColor9 }

    /// R900
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var alertColor10: UIColor { return UDColor.alertColor10 }
}

/// Neutral Color
extension UDComponentsExtension where BaseType == UIColor {
    /// N00
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var neutralColor1: UIColor { return UDColor.neutralColor1 }

    /// N50
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var neutralColor2: UIColor { return UDColor.neutralColor2 }

    /// N100
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var neutralColor3: UIColor { return UDColor.neutralColor3 }

    /// N200
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var neutralColor4: UIColor { return UDColor.neutralColor4 }

    /// N300
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var neutralColor5: UIColor { return UDColor.neutralColor5 }

    /// N400
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var neutralColor6: UIColor { return UDColor.neutralColor6 }

    /// N500
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var neutralColor7: UIColor { return UDColor.neutralColor7 }

    /// N600
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var neutralColor8: UIColor { return UDColor.neutralColor8 }

    /// N650
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var neutralColor9: UIColor { return UDColor.neutralColor9 }

    /// N700
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var neutralColor10: UIColor { return UDColor.neutralColor10 }

    /// N800
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var neutralColor11: UIColor { return UDColor.neutralColor11 }

    /// N900
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var neutralColor12: UIColor { return UDColor.neutralColor12 }

    /// N950
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var neutralColor13: UIColor { return UDColor.neutralColor13 }

    /// N1000
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var neutralColor14: UIColor { return UDColor.neutralColor14 }
}

/// Abstract theme color
extension UDComponentsExtension where BaseType == UIColor {
    /// neutralColor1
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var backgroundColor: UIColor { return UDColor.backgroundColor }

    /// neutralColor5
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var borderColor: UIColor { return UDColor.borderColor }

    /// neutralColor1
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var borderColorInverse: UIColor { return UDColor.borderColorInverse }

    /// neutralColor1.withAlphaComponent(0.15)
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var dividerColor: UIColor { return UDColor.dividerColor }

    /// neutralColor1
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var dividerColorInverse: UIColor { return UDColor.dividerColorInverse }

    /// neutralColor12
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var textColor: UIColor { return UDColor.textColor }

    /// neutralColor1
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var textColorInverse: UIColor { return UDColor.textColorInverse }

    /// neutralColor12
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var titleColor: UIColor { return UDColor.titleColor }

    /// neutralColor1
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var titleColorInverse: UIColor { return UDColor.titleColorInverse }

    /// B700
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var linkColor: UIColor { return UDColor.linkColor }

    /// B400
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var linkColorInverse: UIColor { return UDColor.linkColorInverse }

    /// neutralColor7
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var descriptionColor: UIColor { return UDColor.descriptionColor }

    /// neutralColor1
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var descriptionColorInverse: UIColor { return UDColor.descriptionColorInverse }

    /// neutralColor1
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var primaryIconColor: UIColor { return UDColor.primaryIconColor }

    /// neutralColor1
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var primaryIconColorInverse: UIColor { return UDColor.primaryIconColorInverse }

    /// neutralColor8
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var secondaryIconColor: UIColor { return UDColor.secondaryIconColor }

    /// neutralColor1
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var secondaryIconColorInverse: UIColor { return UDColor.secondaryIconColorInverse }

    /// neutralColor7
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var tertiaryIconColor: UIColor { return UDColor.tertiaryIconColor }

    /// neutralColor1
    @available(*, deprecated, message: "Use standard UD token instead: https://bytedance.feishu.cn/sheets/shtcnfi5Fnsz26xB2gFj5ff13K9")
    public static var tertiaryIconColorInverse: UIColor { return UDColor.tertiaryIconColorInverse }
}
