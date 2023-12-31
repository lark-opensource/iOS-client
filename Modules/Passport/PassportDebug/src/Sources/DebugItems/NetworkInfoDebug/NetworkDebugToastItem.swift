//
//  NetworkDebugToastItem.swift
//  PassportDebug
//
//  Created by ZhaoKejie on 2023/4/6.
//

import Foundation
import LarkDebugExtensionPoint
import LarkContainer

class NetworkDebugToastItem: DebugCellItem {

    let title = "开启网络请求错误信息Toast"

    let type: DebugCellType = .switchButton

    var isSwitchButtonOn: Bool {
        return UserDefaults.standard.bool(forKey: DebugKey.shared.enablePassportNetworkDebugToast)
    }

    var switchValueDidChange: ((Bool) -> Void)?

    init() {
        self.switchValueDidChange = {(isOn: Bool) in
            UserDefaults.standard.set(isOn, forKey: DebugKey.shared.enablePassportNetworkDebugToast)
        }
    }

}
