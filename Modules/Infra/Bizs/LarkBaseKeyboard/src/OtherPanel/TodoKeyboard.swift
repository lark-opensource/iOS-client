//
//  TodoKeyboard.swift.swift
//  LarkKeyboardView
//
//  Created by 张威 on 2021/4/10.
//

import UIKit
import Foundation
import LarkUIKit
import LarkKeyboardView

extension LarkKeyboard {

    public static func buildTodo(
        iconColor: UIColor?,
        badgeTypeBlock: @escaping () -> KeyboardIconBadgeType = { .none },
        selectedBlock: @escaping () -> Bool
    ) -> InputKeyboardItem {

        let keyboardInfo = KeyboardInfo(
            height: 0,
            icon: Resources.todo_bottombar,
            selectedIcon: Resources.todo_bottombar_selected,
            tintColor: iconColor ?? UIColor.ud.N500
        )

        return InputKeyboardItem(
            key: KeyboardItemKey.todo.rawValue,
            keyboardViewBlock: { UIView() },
            keyboardHeightBlock: { keyboardInfo.height },
            keyboardIcon: keyboardInfo.icons,
            badgeTypeBlock: badgeTypeBlock,
            selectedAction: selectedBlock
        )
    }

}
