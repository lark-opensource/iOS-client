//
//  TaskDebugItem.swift
//  Todo
//
//  Created by wangwanxin on 2022/10/10.
//

import Foundation
import LarkDebugExtensionPoint

struct TaskDebugItem: DebugCellItem {
    let title = "Task Debug"
    let type: DebugCellType = .switchButton

    var isSwitchButtonOn: Bool {
        return FeatureGatingKey.isDebugMode
    }

    var switchValueDidChange: ((Bool) -> Void)?

    init() {
        self.switchValueDidChange = { (isOn: Bool) in
            FeatureGatingKey.isDebugMode = isOn
        }
    }
}
