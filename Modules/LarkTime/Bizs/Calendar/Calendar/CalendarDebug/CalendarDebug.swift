#if !LARK_NO_DEBUG
//
//  CalendarDebug.swift
//  Calendar
//
//  Created by huoyunjie on 2022/3/23.
//

import Foundation
import LarkDebugExtensionPoint

struct CalendarDebugItem: DebugCellItem {
    let title = "Calendar 便捷调试"
    let type: DebugCellType = .switchButton

    var isSwitchButtonOn: Bool {
        return FG.canDebug
    }

    var switchValueDidChange: ((Bool) -> Void)?

    init() {
        self.switchValueDidChange = { (isOn: Bool) in
            if isOn {
                FG.canDebug = true
            } else {
                FG.canDebug = false
            }
        }
    }
}

extension FG {
    static var canDebug: Bool = false
}
#endif
