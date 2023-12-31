//
//  FocusKeyPressPatch.swift
//  LarkCrashSanitizer
//
//  Created by Saafo on 2021/11/25.
//

import UIKit
import Foundation
import LKCommonsTracker

extension UIApplication {
    /// https://bytedance.feishu.cn/docx/doxcnsBzpJ6j9SJ1SultsQREhnc
    @objc
    public func swiftPhysicalButtonTypeForKeyboardEvent(_ event: Any, isTextual: Bool, systemValue: NSInteger
    ) -> NSInteger {
        SwiftLogger.info(message: NSString(string: "swiftPhysicalButtonTypeForKeyboardEvent, systemValue: \(systemValue)"))
        guard (UIPress.PressType.upArrow.rawValue...UIPress.PressType.select.rawValue).contains(systemValue) else {
            return systemValue
        }
        if let event = event as? UIPressesEvent {
            let keyCodes = event.allPresses.map { $0.type.rawValue }
            let keyCodesString = keyCodes.sorted().description
            let textual = isTextual ? "true" : "false"
            let value: Int = Int(systemValue)
            LKCommonsTracker.Tracker.post(SlardarEvent(name: "swizzled_physical_button_type_method",
                                                       metric: [:],
                                                       category: ["keyCodes": keyCodesString,
                                                                  "isTextual": textual,
                                                                  "systemValue": value],
                                                       extra: [:]))
            SwiftLogger.info(message: NSString(string: "swizzled_physical_button_type_method, " +
                                               "keyCodes: \(keyCodesString), " +
                                               "isTextual: \(textual), " +
                                               "systemValue: \(value)"))
        }
        return -1
    }
}
