//
//  MicroAppDebugItems.swift
//  LarkMicroApp
//
//  Created by CharlieSu on 11/28/19.
//

import Foundation
import LarkDebugExtensionPoint
import EEMicroAppSDK
import EENavigator
import LarkNavigator

// Debug 工具代码，无需进行统一存储规则检查
// lint:disable lark_storage_check

struct MicroAppDebugItem: DebugCellItem {
    let title: String = "允许小程序调试"
    let detail: String = "Gadget,JSSDK,Block..."
    let type: DebugCellType = .switchButton
    private static let microAppDebugSwitch: String = "kEEMicroAppDebugSwitch"

    let isSwitchButtonOn = UserDefaults.standard.bool(forKey: MicroAppDebugItem.microAppDebugSwitch)

    let switchValueDidChange: ((Bool) -> Void)? = { (isOn: Bool) in
        UserDefaults.standard.set(isOn, forKey: MicroAppDebugItem.microAppDebugSwitch)
        EERoute.shared().updateDebug()
    }
}

struct MicroAppDebugPageItem: DebugCellItem {
    let title: String = "小程序调试页面"
    let type: DebugCellType = .disclosureIndicator

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        OPUserScope.userResolver().navigator.push(EMADebugViewController(), from: debugVC)
    }
}
