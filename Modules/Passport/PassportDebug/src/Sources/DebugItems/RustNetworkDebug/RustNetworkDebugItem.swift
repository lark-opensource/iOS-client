//
//  RustNetworkDebugItem.swift
//  PassportDebug
//
//  Created by ByteDance on 2022/7/25.
//

import Foundation
import LarkDebugExtensionPoint
import LarkAccountInterface
import EENavigator
import RoundedHUD
import LarkContainer


struct RustNetworkDebugItem: DebugCellItem {
    let title = "关闭登录前Rust网络加速"
    let type: DebugCellType = .switchButton

    var isSwitchButtonOn: Bool {
        return UserDefaults.standard.bool(forKey: DebugKey.shared.disablePassportRustHTTPKey)
    }

    var switchValueDidChange: ((Bool) -> Void)?

    init() {
        self.switchValueDidChange = { (isOn: Bool) in
            if isOn {
                UserDefaults.standard.set(true, forKey: DebugKey.shared.disablePassportRustHTTPKey)
            } else {
                UserDefaults.standard.set(false, forKey: DebugKey.shared.disablePassportRustHTTPKey)
            }
        }
    }
}
