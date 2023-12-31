//
//  ColorToken.swift
//  Todo
//
//  Created by wangwanxin on 2021/5/21.
//

import UniverseDesignColor
import UniverseDesignTheme

extension UDComponentsExtension where BaseType == UIColor {

    /// B50 at light mode, B100 at dark mode.
    static var sourceBg: UIColor {
        return UIColor.ud.B50 & UIColor.ud.B100
    }
}
