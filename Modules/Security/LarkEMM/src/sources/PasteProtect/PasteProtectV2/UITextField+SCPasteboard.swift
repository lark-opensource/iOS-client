//
//  UITextField+SCPasteboard.swift
//  LarkEMM
//
//  Created by ByteDance on 2023/7/19.
//

import Foundation
import LarkSensitivityControl
import LarkSecurityComplianceInfra

extension UITextField {
    private var config: PasteboardConfig {
        SCPasteboard.currentConfig()
    }
    
    static let replaceMethods = {
        var methods = [#selector(UITextField.canPerformAction(_:withSender:)): #selector(UITextField.sc_canPerformAction(_:withSender:))]
        if #available(iOS 13.0, *) {
            methods[#selector(UITextField.buildMenu(with:))] = #selector(UITextField.sc_buildMenu(with:))
        }
        return methods
    }()
    
    public static func scReplaceActionMethod() {
        replaceMethods.forEach { (key, value) in
            let result = UITextField.btd_swizzleInstanceMethod(key, with: value)
            pasteProtectLogger.info("UITextField replace \(key.description) with \(value.description), result: \(result)", additionalData: nil)
        }
    }

    @objc
    func sc_canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        SCPasteboard.general(SCPasteboard.currentConfig()).monitorIfNeeded(action: action.description)
        if let remainItems = SCPasteboard.general(config).canRemainActionsDescrption() {
            if remainItems.contains(action.description) {
                return sc_canPerformAction(action, withSender: sender)
            } else {
                return false
            }
        }

        return sc_canPerformAction(action, withSender: sender)
    }

    @objc
    @available(iOS 13.0, *)
    func sc_buildMenu(with builder: UIMenuBuilder) {
        sc_buildMenu(with: builder)
        guard let hiddenItems = SCPasteboard.general(config).hiddenItemsDescrption() else { return }
        pasteProtectLogger.info("SCPasteboard: UITextField hide menu button")
        for item in hiddenItems {
            pasteProtectLogger.info("SCPasteboard: UITextField remove additional button", additionalData: ["identifier": item.rawValue])
            builder.remove(menu: item)
        }
    }
}
