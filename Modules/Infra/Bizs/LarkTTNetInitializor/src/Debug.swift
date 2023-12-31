//
//  Debug.swift
//  LarkTTNetInitializor
//
//  Created by Supeng on 2021/11/9.
//

import Foundation
import LarkDebugExtensionPoint
import TTNetworkManager

// Debug 工具代码，无需进行统一存储规则检查
// lint:disable lark_storage_check

public struct BoeProxyItem: DebugCellItem {
    public let title: String = "Set Boe Proxy Enabled"
    public let type: DebugCellType = .switchButton

    public var isSwitchButtonOn: Bool { UserDefaults.standard.boeProxyEnabled }

    public init() {}

    public let switchValueDidChange: ((Bool) -> Void)? = { (isOn: Bool) in
        UserDefaults.standard.boeProxyEnabled = isOn
        TTNetworkManager.shareInstance().setBoeProxyEnabled(isOn)
    }
}

public struct CAStoreItem: DebugCellItem {
    public let title: String = "Set CA Store Enabled(重启后生效)"
    public let type = DebugCellType.switchButton

    public var isSwitchButtonOn: Bool { UserDefaults.standard.caStoreEnabled }

    public init() {}

    public let switchValueDidChange: ((Bool) -> Void)? = { (isOn: Bool) in
        UserDefaults.standard.caStoreEnabled = isOn
    }
}

extension UserDefaults {
    var boeProxyEnabled: Bool {
        set {
            set(newValue, forKey: "Set_Boe_Proxy_Enabled")
        }
        get {
            bool(forKey: "Set_Boe_Proxy_Enabled")
        }
    }

    var caStoreEnabled: Bool {
        set { set(newValue, forKey: "Set_CA_Store_Enabled") }
        get { (object(forKey: "Set_CA_Store_Enabled") as? Bool) ?? true }
    }
}
