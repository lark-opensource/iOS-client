//
//  Models.swift
//  LarkDebugDev
//
//  Created by SuPeng on 2/14/20.
//

import Foundation
import LarkDebugExtensionPoint

class TestDebugItem: DebugCellItem {
    init() { }
    var title: String { return "Test" }
    var type: DebugCellType { return .switchButton }
    var isSwitchButtonOn: Bool { return false }
    var switchValueDidChange: ((Bool) -> Void)?
}
