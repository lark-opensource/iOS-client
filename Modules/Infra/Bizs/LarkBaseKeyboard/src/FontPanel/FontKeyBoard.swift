//
//  FontKeyBoard.swift
//  LarkKeyboardView
//
//  Created by liluobin on 2021/8/17.
//

import Foundation
import UIKit
import LarkKeyboardView

extension LarkKeyboard {
    public static func buildFont(iconColor: UIColor? = nil, selectedBlock: @escaping () -> Bool) -> InputKeyboardItem {
        let keyboardInfo = KeyboardInfo(
            height: 0,
            icon: Resources.font_bottombar,
            selectedIcon: Resources.font_bottombar_selected,
            tintColor: iconColor ?? UIColor.ud.N500
        )
        let keyboardViewBlock = { return UIView() }
        let selectedAction = selectedBlock
        return InputKeyboardItem(
            key: KeyboardItemKey.font.rawValue,
            keyboardViewBlock: keyboardViewBlock,
            keyboardHeightBlock: { keyboardInfo.height },
            keyboardIcon: keyboardInfo.icons,
            selectedAction: selectedAction
        )
    }
}
