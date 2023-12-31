//
//  HashTagKeyboard.swift
//  LarkKeyboardView
//
//  Created by liluobin on 2021/6/29.
//

import Foundation
import LarkUIKit
import LarkKeyboardView

extension LarkKeyboard {

    public static func buildHashTag(iconColor: UIColor? = nil, selectedBlock: @escaping () -> Bool) -> InputKeyboardItem {
        let keyboardInfo = KeyboardInfo(
            height: 0,
            icon: Resources.hashTag_bottombar,
            selectedIcon: Resources.hashTag_bottombar,
            tintColor: iconColor ?? UIColor.ud.N500
        )
        let keyboardViewBlock = { return UIView() }
        let selectedAction = selectedBlock

        return InputKeyboardItem(
            key: KeyboardItemKey.hashTag.rawValue,
            keyboardViewBlock: keyboardViewBlock,
            keyboardHeightBlock: { keyboardInfo.height },
            keyboardIcon: keyboardInfo.icons,
            selectedAction: selectedAction
        )
    }
}
