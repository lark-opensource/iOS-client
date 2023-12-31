//
//  UITextField+Pasteboard.swift
//  LarkEMM
//
//  Created by ByteDance on 2023/7/19.
//

import Foundation
import LarkSensitivityControl
import LarkSecurityComplianceInfra

extension UITextField {
    /// 通用token、context，用于psda鉴权校验
    private static var token = Token("LARK-PSDA-pasteboard_textfield")
    private static let context = Context([AtomicInfo.Pasteboard.items.rawValue,
                                          AtomicInfo.Pasteboard.setItems.rawValue,
                                          AtomicInfo.Pasteboard.addItems.rawValue,
                                          AtomicInfo.Pasteboard.itemProviders.rawValue])

    private var config: PasteboardConfig {
        return PasteboardConfig(token: Self.token, scene: pasteScene, pointId: pointId, shouldImmunity: shouldImmunity, ignoreAlert: ignoreAlert)
    }
    
    public static func hookPasteMethods() {
        swizzling(forClass: UITextField.self, originalSelector: #selector(UITextField.copy(_ :)), swizzledSelector: #selector(UITextField.swizzleCopy(_:)))
        swizzling(forClass: UITextField.self, originalSelector: #selector(UITextField.paste(_ :)), swizzledSelector: #selector(UITextField.swizzlePaste(_:)))
        swizzling(forClass: UITextField.self, originalSelector: #selector(UITextField.cut(_ :)), swizzledSelector: #selector(UITextField.swizzleCut(_:)))
        swizzling(forClass: UITextField.self,
                  originalSelector: #selector(UITextField.paste(itemProviders:)),
                  swizzledSelector: #selector(UITextField.swizzlePasteItemProviders(itemProviders:)))
        swizzling(forClass: UITextField.self,
                  originalSelector: #selector(UITextField.canPerformAction(_:withSender:)),
                  swizzledSelector: #selector(UITextField.swizzleCanPerformAction(_:withSender:)))
        if #available(iOS 13.0, *) {
            swizzling(forClass: UITextField.self,
                      originalSelector: #selector(UITextField.buildMenu(with:)),
                      swizzledSelector: #selector(UITextField.swizzleBuildMenu(with:)))
        }
    }

    @objc
    func swizzleCopy(_ sender: Any) {
        SCLogger.info("SCPasteboard: UITextField copy")
        do {
            try SensitivityManager.shared.checkToken(Self.token, context: Self.context)
            swizzleCopy(sender)
            updatePasteboardContent()
        } catch {
            SCLogger.error("SCPasteboard: UITextField copy error: \(error.localizedDescription)")
        }
    }

    @objc
    func swizzlePaste(_ sender: Any) {
        let generalHasContent = SCPasteboard.generalHasNewContent(.all)
        if !generalHasContent {
            pasteFromCustomPasteboard(sender)
            return
        }
        SCLogger.info("SCPasteboard: UITextField paste from UIPasteboard.general")
        do {
            try SensitivityManager.shared.checkToken(Self.token, context: Self.context)
            swizzlePaste(sender)
        } catch {
            SCLogger.error("SCPasteboard: UITextField paste error: \(error.localizedDescription)")
        }
    }

    @objc
    func swizzlePasteItemProviders(itemProviders: [NSItemProvider]) {
        do {
            try SensitivityManager.shared.checkToken(Self.token, context: Self.context)
            let generalHasContent = SCPasteboard.generalHasNewContent(.all)
            if !generalHasContent {
                let config = PasteboardConfig(token: Self.token, scene: pasteScene, pointId: pointId, ignoreAlert: ignoreAlert)
                if let customItemProviders = SCPasteboard.general(config).itemProviders {
                    swizzlePasteItemProviders(itemProviders: customItemProviders)
                }
                return
            }
            swizzlePasteItemProviders(itemProviders: itemProviders)
        } catch {
            SCLogger.error("SCPasteboard: UITextField paste itemProviders error: \(error.localizedDescription)")
        }
    }

    @objc
    func swizzleCut(_ sender: Any) {
        SCLogger.info("SCPasteboard: UITextField cut")
        do {
            try SensitivityManager.shared.checkToken(Self.token, context: Self.context)
            swizzleCut(sender)
            updatePasteboardContent()
        } catch {
            SCLogger.error("SCPasteboard: UITextField cut error: \(error.localizedDescription)")
        }
    }

    @objc
    func swizzleCanPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        SCPasteboard.general(self.config).monitorIfNeeded(action: action.description)
        if let remainItems = SCPasteboard.general(config).canRemainActionsDescrption() {
            if remainItems.contains(action.description) {
                if action == #selector(paste(_:)), SCPasteboard.general(config).checkPastePermission() {
                    return SCPasteboard.general(config).hasValue()
                }
                return swizzleCanPerformAction(action, withSender: sender)
            } else {
                return false
            }
        }

        if action == #selector(paste(_:)) {
            if SCPasteboard.general(config).checkPastePermission() {
                return SCPasteboard.general(config).hasValue()
            }
        }
        return swizzleCanPerformAction(action, withSender: sender)
    }

    @objc
    @available(iOS 13.0, *)
    func swizzleBuildMenu(with builder: UIMenuBuilder) {
        swizzleBuildMenu(with: builder)
        guard let hiddenItems = SCPasteboard.general(config).hiddenItemsDescrption() else { return }
        SCLogger.info("SCPasteboard: UITextField hide menu button")
        for item in hiddenItems {
            SCLogger.info("SCPasteboard: UITextField remove additional button", additionalData: ["identifier": item.rawValue])
            builder.remove(menu: item)
        }
    }

    private func updatePasteboardContent() {
        if checkCopyPermission() {
            SCLogger.info("SCPasteboard: UITextField custom paste board copy or cut")
            let scene: Scene? = self.pasteScene
            let pointId: String? = self.pointId
            let immunity: Bool? = self.shouldImmunity
            let ignoreAlert: Bool? = self.ignoreAlert
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                let config = PasteboardConfig(token: Self.token, scene: scene, pointId: pointId, shouldImmunity: immunity, ignoreAlert: ignoreAlert)
                SCPasteboard.general(config).assignmentFromPasteboard()
            }
        }
    }

    private func pasteFromCustomPasteboard(_ sender: Any) {
        SCLogger.info("SCPasteboard: UITextField paste from custom pasteboard")
        if let items = SCPasteboard.general(config).items {
            do {
                try PasteboardEntry.setItems(forToken: Self.token, pasteboard: UIPasteboard.general, items)
            } catch {
                SCLogger.error("SCPasteboard: UITextField set items error: \(error.localizedDescription)")
            }
        }
        swizzlePaste(sender)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            UIPasteboard.general.clearPasteboard()
        }
    }

    private func checkCopyPermission() -> Bool {
        return SCPasteboard.general(config).checkCopyPermission()
    }
}
