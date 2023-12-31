//
//  MinutesDesignColor.swift
//  LarkSuspendable
//
//  Created by panzaofeng on 2021/5/27.
//

import UIKit
import UniverseDesignTheme
import UniverseDesignColor

extension UDComponentsExtension where BaseType == UIColor {

    public static var lmTokenFloatBtnBorderBlue: UIColor {
        return UIColor.ud.primaryFillSolid03 & UIColor.ud.primaryContentLoading
    }

    public static var lmTokenFloatBgBody: UIColor {
        return UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.6) & UIColor.ud.bgFloatOverlay
    }

    public static var lmTokenRecordingBtnSmallGray: UIColor {
        return UIColor.ud.N900.withAlphaComponent(0.05)
    }

    public static var lmTokenRecordingBtnBorderGray: UIColor {
        return UIColor.ud.N900.withAlphaComponent(0.3)
    }
}
