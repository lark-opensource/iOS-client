//
//  SendKeyboard.swift
//  Pods
//
//  Created by lichen on 2018/7/27.
//

import UIKit
import Foundation
import LarkUIKit
import LarkKeyboardView

extension LarkKeyboard {

    public static func buildSend(_ selectedBlock: @escaping () -> Bool) -> InputKeyboardItem {
        let keyboardInfo = KeyboardInfo(
            height: 0,
            icon: Resources.sent_light,
            selectedIcon: Resources.sent_shadow,
            unenableIcon: Resources.sent_light,
            unenableTintColor: UIColor.ud.iconDisabled
        )
        let keyboardViewBlock = { return UIView() }
        let selectedAction = selectedBlock

        return InputKeyboardItem(
            key: KeyboardItemKey.send.rawValue,
            keyboardViewBlock: keyboardViewBlock,
            keyboardHeightBlock: { keyboardInfo.height },
            keyboardIcon: keyboardInfo.icons,
            selectedAction: selectedAction
        )
    }
}
