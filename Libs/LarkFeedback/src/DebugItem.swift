//
//  DebugItem.swift
//  LarkFeedback
//
//  Created by kongkaikai on 2021/4/8.
//

import Foundation
import LarkDebugExtensionPoint
import BDFeedBack

struct BOEEnableDebugItem: DebugCellItem {
    var title: String { "内测的 BOE 模拟开关" }
    var type: DebugCellType { .switchButton }

    // key from NSUserDefaults+BDFB.m
    var isSwitchButtonOn: Bool { UserDefaults.standard.bool(forKey: "com.bdfb.boe") }

    var switchValueDidChange: ((Bool) -> Void)? {
        return { isOn in
            BDFBFloatingWindowManager.shared().setBOEEnabled(isOn)
        }
    }
}
