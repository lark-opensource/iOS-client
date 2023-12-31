//
//  ShowEnvInfoItem.swift
//  PassportDebug
//
//  Created by ByteDance on 2022/7/25.
//

import Foundation
import LarkDebugExtensionPoint
import EENavigator


struct ShowEnvInfoItem: DebugCellItem {
    let title = "显示 实际环境信息"
    let type: DebugCellType = .switchButton
    
    var isSwitchButtonOn: Bool {
        EnvInfoManager.shared.isEnvInfoViewExist
    }
    
    var switchValueDidChange: ((Bool) -> Void)?
    
    init() {
        let manager = EnvInfoManager.shared
        self.switchValueDidChange = { (isOn: Bool) in
            if isOn {
                let mainWindow = Navigator.shared.mainSceneWindow
                manager.showEnvInfoView()
            } else {
                manager.removeEnvInfoView()
            }
        }
    }
}
