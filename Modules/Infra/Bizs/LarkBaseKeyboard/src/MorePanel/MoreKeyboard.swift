//
//  MoreKeyboard.swift
//  Pods
//
//  Created by lichen on 2018/7/27.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkKeyboardView

extension LarkKeyboard {

    static public func buildMore(
        _ iconColor: UIColor?,
        _ selectedBlock: @escaping () -> Bool,
        moreItemsDriver: Driver<[BaseKeyboardMoreItem]>
    ) -> InputKeyboardItem {

        let keyboardInfo = KeyboardMoreItemPanel.keyboard(iconColor: iconColor)
        let keyboardIcons: (UIImage?, UIImage?, UIImage?) = keyboardInfo.icons
        let keyboardHeight: Float = keyboardInfo.height
        let keyboardViewBlock = { () -> UIView in
            return KeyboardMoreItemPanel(observableItems: moreItemsDriver)
        }
        let selectedAction = selectedBlock
        let tapped: (KeyboardPanelEvent) -> Void = { event in
            switch event.type {
            case .tap:
                event.keyboardSelect()
            case .tapWhenSelected:
                event.keyboardClose()
            default:
                break
            }
        }
        return InputKeyboardItem(
            key: KeyboardItemKey.more.rawValue,
            keyboardViewBlock: keyboardViewBlock,
            keyboardHeightBlock: { keyboardHeight },
            coverSafeArea: true,
            keyboardIcon: keyboardIcons,
            onTapped: tapped,
            selectedAction: selectedAction
        )
    }
}
