//
//  AppLock+Resources.swift
//  LarkSecurityCompliance
//
//  Created by AlbertSun on 2023/5/29.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon

extension BundleResources.LarkEMM {
    // 锁屏保护 Resources
    static let mine_right_arrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
    static var hide_pin_code_icon: UIImage { Self.hide_pin_code_icon_1.ud.withTintColor(UIColor.ud.iconN3) }
    static var show_pin_code_icon: UIImage { Self.show_pin_code_icon_1.ud.withTintColor(UIColor.ud.iconN3) }
    static var number_pad_del_icon: UIImage { Self.lock_numberpad_del_1.ud.withTintColor(UIColor.ud.rgb(0xD5F6F2)) }
    static var number_pad_del_icon_with_theme: UIImage {
        Self.lock_numberpad_del_1.ud.withTintColor(UIColor.ud.N900.alwaysLight & UIColor.ud.N00.alwaysLight)
    }
}
