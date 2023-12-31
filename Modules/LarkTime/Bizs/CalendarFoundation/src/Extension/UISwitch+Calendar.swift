//
//  UISwitch+Calendar.swift
//  Calendar
//
//  Created by zhuchao on 2019/4/24.
//

import UIKit

extension UISwitch {
    public static func blueSwitch() -> UISwitch {
        let switchControl = UISwitch()
        switchControl.onTintColor = UIColor.ud.primaryFillDefault
        return switchControl
    }
}
