//
//  AtKeyboard.swift
//  Pods
//
//  Created by lichen on 2018/7/27.
//

import UIKit
import Foundation
import LarkUIKit
import LarkKeyboardView

extension LarkKeyboard {

    public static func buildAt(iconColor: UIColor? = nil, selectedBlock: @escaping () -> Bool) -> InputKeyboardItem {
        let keyboardInfo = KeyboardInfo(
            height: 0,
            icon: Resources.at_bottombar,
            selectedIcon: Resources.at_bottombar_selected,
            tintColor: iconColor ?? UIColor.ud.N500
        )
        let keyboardViewBlock = { return UIView() }
        let selectedAction = selectedBlock

        return InputKeyboardItem(
            key: KeyboardItemKey.at.rawValue,
            keyboardViewBlock: keyboardViewBlock,
            keyboardHeightBlock: { keyboardInfo.height },
            keyboardIcon: keyboardInfo.icons,
            selectedAction: selectedAction
        )
    }
}
