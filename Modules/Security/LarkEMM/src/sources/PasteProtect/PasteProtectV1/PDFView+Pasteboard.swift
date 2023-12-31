//
//  PDFView+Pasteboard.swift
//  LarkEMM
//
//  Created by ByteDance on 2023/7/19.
//

import Foundation
import LarkSensitivityControl
import LarkSecurityComplianceInfra
import PDFKit

extension PDFView {
    /// 通用token、context，用于psda鉴权校验
    private static var token = Token("LARK-PSDA-pasteboard_pdfview")
    private static let context = Context([AtomicInfo.Pasteboard.items.rawValue,
                                          AtomicInfo.Pasteboard.setItems.rawValue,
                                          AtomicInfo.Pasteboard.addItems.rawValue,
                                          AtomicInfo.Pasteboard.itemProviders.rawValue])
    
    private var config: PasteboardConfig {
        return PasteboardConfig(token: Self.token, scene: pasteScene, pointId: pointId, shouldImmunity: shouldImmunity, ignoreAlert: ignoreAlert)
    }
    
    public static func hookPasteMethods() {
        swizzling(forClass: PDFView.self, originalSelector: #selector(PDFView.copy(_ :)), swizzledSelector: #selector(PDFView.swizzleCopy(_:)))
        swizzling(forClass: PDFView.self, originalSelector: #selector(PDFView.paste(_ :)), swizzledSelector: #selector(PDFView.swizzlePaste(_:)))
        swizzling(forClass: PDFView.self, originalSelector: #selector(PDFView.cut(_ :)), swizzledSelector: #selector(PDFView.swizzleCut(_:)))
        swizzling(forClass: PDFView.self, originalSelector: #selector(PDFView.paste(itemProviders:)), swizzledSelector: #selector(PDFView.swizzlePasteItemProviders(itemProviders:)))
        swizzling(forClass: PDFView.self, originalSelector: #selector(PDFView.canPerformAction(_:withSender:)), swizzledSelector: #selector(PDFView.swizzleCanPerformAction(_:withSender:)))
        if #available(iOS 13.0, *) {
            swizzling(forClass: PDFView.self, originalSelector: #selector(PDFView.buildMenu(with:)), swizzledSelector: #selector(PDFView.swizzleBuildMenu(with:)))
        }
    }
    
    @objc
    func swizzleCopy(_ sender: Any) {
        SCLogger.info("SCPasteboard: PDFView copy")
        do {
            try SensitivityManager.shared.checkToken(Self.token, context: Self.context)
            swizzleCopy(sender)
            updatePasteboardContent()
        } catch {
            SCLogger.error("SCPasteboard: PDFView copy error: \(error.localizedDescription)")
        }
    }
    
    @objc
    func swizzlePaste(_ sender: Any) {
        let generalHasContent = SCPasteboard.generalHasNewContent(.all)
        if !generalHasContent {
            pasteFromCustomPasteboard(sender)
            return
        }
        SCLogger.info("SCPasteboard: PDFView paste from UIPasteboard.general")
        do {
            try SensitivityManager.shared.checkToken(Self.token, context: Self.context)
            swizzlePaste(sender)
        } catch {
            SCLogger.error("SCPasteboard: PDFView paste error: \(error.localizedDescription)")
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
            SCLogger.error("SCPasteboard: PDFView paste itemProviders error: \(error.localizedDescription)")
        }
    }
    
    @objc
    func swizzleCut(_ sender: Any) {
        SCLogger.info("SCPasteboard: PDFView cut")
        do {
            try SensitivityManager.shared.checkToken(Self.token, context: Self.context)
            swizzleCut(sender)
            updatePasteboardContent()
        } catch {
            SCLogger.error("SCPasteboard: PDFView cut error: \(error.localizedDescription)")
        }
    }
    
    @objc
    func swizzleCanPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        SCPasteboard.general(self.config).monitorIfNeeded(action: action.description)
        guard let remainItems = SCPasteboard.general(config).canRemainActionsDescrption() else {
            // PDF默认不支持粘贴，所以这里不需要单独判断
            return swizzleCanPerformAction(action, withSender: sender)
        }
        if remainItems.contains(action.description) {
            return swizzleCanPerformAction(action, withSender: sender)
        }
        return false
    }
    
    @objc
    @available(iOS 13.0, *)
    func swizzleBuildMenu(with builder: UIMenuBuilder) {
        swizzleBuildMenu(with: builder)
        guard let hiddenItems = SCPasteboard.general(config).hiddenItemsDescrption() else { return }
        SCLogger.info("SCPasteboard: PDFView hide menu button")
        for item in hiddenItems {
            SCLogger.info("SCPasteboard: PDFView remove additional button", additionalData: ["identifier": item.rawValue])
            builder.remove(menu: item)
        }
    }
    
    private func updatePasteboardContent() {
        if checkCopyPermission() {
            SCLogger.info("SCPasteboard: PDFView custom paste board copy or cut")
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
        SCLogger.info("SCPasteboard: PDFView paste from custom pasteboard")
        if let items = SCPasteboard.general(config).items {
            do {
                try PasteboardEntry.setItems(forToken: Self.token, pasteboard: UIPasteboard.general, items)
            } catch {
                SCLogger.error("SCPasteboard: PDFView set items error: \(error.localizedDescription)")
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
