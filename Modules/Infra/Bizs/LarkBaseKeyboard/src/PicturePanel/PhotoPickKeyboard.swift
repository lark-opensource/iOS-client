//
//  PhotoPickKeyboard.swift
//  LarkKeyboardView
//
//  Created by 李晨 on 2020/11/11.
//

import UIKit
import Foundation
import LarkUIKit
import LarkAssetsBrowser
import LarkKeyboardView

extension PhotoPickView {
    public static func keyboard(iconColor: UIColor? = nil) -> KeyboardInfo {
        let tipsHeight: Float = self.preventStyle.showTips() ? 44 : 0
        return KeyboardInfo(
            height: Display.height >= 812 ? 302 + tipsHeight : 260 + tipsHeight,
            icon: Resources.picture_bottombar,
            selectedIcon: Resources.picture_bottombar_selected,
            unenableIcon: nil,
            tintColor: iconColor ?? UIColor.ud.N500
        )
    }
}
