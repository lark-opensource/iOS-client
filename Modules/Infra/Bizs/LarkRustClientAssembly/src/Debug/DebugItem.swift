//
//  DebugItem.swift
//  LarkRustClientAssembly
//
//  Created by Yiming Qu on 2021/2/3.
//

import Foundation
import LarkAppConfig
import LarkDebugExtensionPoint
import EENavigator
import UniverseDesignDialog
import LarkRustClient
import LarkAccountInterface
import CookieManager

// Debug 工具代码，无需进行统一存储规则检查
// lint:disable lark_storage_check
struct ClearCookitItem: DebugCellItem {
    let title = "Clear All Cookies"

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        let dialog = UDDialog(config: UDDialogUIConfig())
        dialog.setTitle(text: "确定要清除所有Cookies？")
        dialog.addDestructiveButton(text: "清除全部(监控上报)", dismissCompletion: {
            self.clearCookies(excludedNames: [], tracked: true)
        })
        dialog.addDestructiveButton(text: "清除全部(监控不上报)", dismissCompletion: {
            self.clearCookies(excludedNames: [])
        })

        dialog.addDestructiveButton(text: "清除除session外(监控不上报)", dismissCompletion: {
            self.clearCookies(excludedNames: [
                "install_id",
                "ttreq",
                "session",
                "osession",
                "bear-session"
            ])
        })
        dialog.addSecondaryButton(text: "取消")
        DispatchQueue.main.async { Navigator.shared.present(dialog, from: debugVC) }
    }

    // tracked: 触发监控上报
    private func clearCookies(excludedNames: [String] = [], tracked: Bool = false) {
        HTTPCookieStorage.shared.cookies?
            .filter { !excludedNames.contains($0.name) }
            .forEach { cookie in
                if tracked {
                    HTTPCookieStorage.shared.deleteCookie(cookie)
                } else {
                    LarkCookieDoctor.shared.performCookieStorageOperation {
                        HTTPCookieStorage.shared.deleteCookie(cookie)
                    }
                }
            }
    }
}

#if canImport(AWEAnywhereArena)
struct AnyWhereDoorItem: DebugCellItem {
    let title = "enable Anywhere Door(need reboot)"
    let type = DebugCellType.switchButton
    static let itemKey = "set_anyWhereDoor_enable"

    let isSwitchButtonOn = UserDefaults.standard.bool(forKey: Self.itemKey)

    init() {}

    let switchValueDidChange: ((Bool) -> Void)? = { UserDefaults.standard.set($0, forKey: Self.itemKey) }
}
#endif
