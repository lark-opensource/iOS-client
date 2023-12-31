//
//  CanvasKeyboard.swift
//  LarkKeyboardView
//
//  Created by Saafo on 2021/2/24.
//

import UIKit
import Foundation
import LarkKeyboardView

extension LarkKeyboard {

    public static func buildCanvas(
        badgeTypeBlock: @escaping () -> KeyboardIconBadgeType = { .none },
        iconColor: UIColor? = nil,
        selectedBlock: @escaping () -> Bool
    ) -> InputKeyboardItem {
        let keyboardInfo = KeyboardInfo(
            height: 0,
            icon: Resources.canvas_bottomBar_icon,
            selectedIcon: Resources.canvas_bottomBar_selected_icon,
            tintColor: iconColor ?? UIColor.ud.N500
        )
        let keyboardViewBlock = { return UIView() }
        let selectedAction = selectedBlock

        return InputKeyboardItem(
            key: KeyboardItemKey.canvas.rawValue,
            keyboardViewBlock: keyboardViewBlock,
            keyboardHeightBlock: { keyboardInfo.height },
            keyboardIcon: keyboardInfo.icons,
            badgeTypeBlock: badgeTypeBlock,
            selectedAction: selectedAction
        )
    }
}
