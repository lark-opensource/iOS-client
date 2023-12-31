//
//  FeedMainViewController+iPadKeyBind.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/22.
//

import UIKit
import Foundation
import LarkKeyCommandKit

/// For iPad 快捷键绑定: 跳转搜索
extension FeedMainViewController {
    func searchKeyCommand() -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: "k",
                modifierFlags: .command,
                discoverabilityTitle: BundleI18n.LarkFeed.Lark_Legacy_iPadShortcutsSearch
            ).binding(
                target: self,
                selector: #selector(pushSearchController)
            ).wraper,

            KeyCommandBaseInfo(
                input: UIKeyCommand.inputRightArrow,
                modifierFlags: [.command, .alternate],
                discoverabilityTitle: BundleI18n.LarkFeed.Lark_Settings_ShortcutsOneMessageTypeRight
            ).binding(
                tryHandle: { (_) -> Bool in
                    return false
                },
                target: self,
                selector: #selector(nextFilterItem)
            ).wraper,

            KeyCommandBaseInfo(
                input: UIKeyCommand.inputLeftArrow,
                modifierFlags: [.command, .alternate],
                discoverabilityTitle: BundleI18n.LarkFeed.Lark_Settings_ShortcutsOneMessageTypeLeft
            ).binding(
                tryHandle: { (_) -> Bool in
                    return false
                },
                target: self,
                selector: #selector(previousFilterItem)
            ).wraper
        ]
    }
}
