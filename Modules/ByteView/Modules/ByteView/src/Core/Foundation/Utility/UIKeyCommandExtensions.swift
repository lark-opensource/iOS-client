//
//  UIKeyCommandExtensions.swift
//  ByteView
//
//  Created by chentao on 2020/12/18.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation

extension UIKeyCommand {
    /// https://stackoverflow.com/questions/41731442/stop-uikeycommand-repeated-actions
    /// 避免快捷键长按，无限响应
    var nonRepeating: UIKeyCommand {
        let repeatableConstant = "repeatable"
        if self.responds(to: Selector(repeatableConstant)) {
            self.setValue(false, forKey: repeatableConstant)
        }
        return self
    }

    static func createFrom(
        input: String,
        modifierFlags: UIKeyModifierFlags,
        action: Selector,
        discoverabilityTitle: String? = nil) -> UIKeyCommand {
        let keyCommand: UIKeyCommand
        if #available(iOS 13.0, *) {
            keyCommand = UIKeyCommand(title: "", image: nil, action: action, input: input, modifierFlags: modifierFlags, propertyList: nil, alternates: [], discoverabilityTitle: discoverabilityTitle, attributes: [], state: .off)
        } else {
            keyCommand = UIKeyCommand(input: input, modifierFlags: modifierFlags, action: action)
        }
        return keyCommand.nonRepeating
    }
}
