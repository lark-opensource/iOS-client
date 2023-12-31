//
//  FocusListController+iPadKey.swift
//  LarkFocus
//
//  Created by Yaoguoguo on 2023/9/4.
//

import UIKit
import Foundation
import LarkKeyCommandKit

/// For iPad 快捷键绑定
extension FocusListController {
    func selectFocusKeyCommand() -> [KeyBindingWraper] {
        let commands = [
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputReturn,
                modifierFlags: [],
                discoverabilityTitle: ""
            ).binding(
                target: self,
                selector: #selector(selectFocus)
            ).wraper
        ]
        return commands
    }

    @objc
    func selectFocus() {
        if let cell = self.tableView.visibleCells.first(where: {
            return $0.isFocused
        }) as? FocusModeCell {
            cell.didTapTitleview()
        }
    }
}

