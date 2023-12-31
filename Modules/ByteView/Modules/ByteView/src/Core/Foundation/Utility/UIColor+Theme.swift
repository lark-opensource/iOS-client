//
//  Theme.swift
//  ByteView
//
//  Created by 李凌峰 on 2018/8/22.
//

import Foundation
import UniverseDesignColor
import UniverseDesignTheme
import ByteViewCommon

extension UDComponentsExtension where BaseType == UIColor {
    static let cgClear: UIColor = UDColor.primaryOnPrimaryFill.withAlphaComponent(0)
}

extension VCExtension where BaseType: CALayer {
    var borderColor: UIColor? {
        get {
            if let color = base.borderColor {
                return UIColor(cgColor: color)
            } else {
                return nil
            }
        }
        set {
            base.ud.setBorderColor(newValue ?? .ud.cgClear)
        }
    }

    var shadowColor: UIColor? {
        get {
            if let color = base.shadowColor {
                return UIColor(cgColor: color)
            } else {
                return nil
            }
        }
        set {
            base.ud.setShadowColor(newValue ?? .ud.cgClear)
        }
    }
}
