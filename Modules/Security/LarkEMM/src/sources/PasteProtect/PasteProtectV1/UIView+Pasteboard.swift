//
//  reproducibleView.swift
//  EnterpriseMobilityManagement
//
//  Created by WangXijing on 2022/7/6.
//

import Foundation
import LarkSecurityComplianceInfra
import AppContainer
import LarkAccountInterface
import LarkSensitivityControl

extension UIView {
    private struct AssociatedKey {
        static var identifier: Scene?
        static var pointLocation: String?
        static var shouldImmunity: Bool?
        static var ignoreAlert: Bool?
    }
    public var pasteScene: Scene? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.identifier) as? Scene
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.identifier, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    public var pointId: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.pointLocation) as? String
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.pointLocation, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    public var shouldImmunity: Bool? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.shouldImmunity) as? Bool
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.shouldImmunity, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    public var ignoreAlert: Bool? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.ignoreAlert) as? Bool
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.ignoreAlert, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
}

func swizzling(forClass: AnyClass, originalSelector: Selector, swizzledSelector: Selector) {
    guard let originalMethod = class_getInstanceMethod(forClass, originalSelector),
        let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector) else {
            return
    }
    if class_addMethod(
        forClass,
        originalSelector,
        method_getImplementation(swizzledMethod),
        method_getTypeEncoding(swizzledMethod)
        ) {
        class_replaceMethod(
            forClass,
            swizzledSelector,
            method_getImplementation(originalMethod),
            method_getTypeEncoding(originalMethod)
        )
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

@available(iOS 13.0, *)
extension UIAction {
    private static var token = Token("LARK-PSDA-pasteboard_action")

    @objc
    func handleIdentifier(_ identifier: String) {
        let disabled = emmConfig()?.isPasteProtectDisabled ?? true
        if disabled {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            if identifier == "WKElementActionTypeCopy" || identifier.hasPrefix("com.apple.datadetectors.DDCopyAction") {
                do {
                    let items = try PasteboardEntry.items(ofToken: Self.token, pasteboard: UIPasteboard.general)
                    SCPasteboard.general(PasteboardConfig(token: Self.token)).setItems(items)
                } catch {
                    SCLogger.error("SCPasteboard: WKWebView set items error: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc
    class func startReplaceConfigImp() {
    }

    private func emmConfig() -> EMMConfig? {
        // 针对系统类的扩展没法传user，通过container中获取userResolver的方式处理
        let passportService = BootLoader.container.resolve(PassportService.self)
        guard let userID = passportService?.foregroundUser?.userID else { return nil } // Global
        let resolver = try? BootLoader.container.getUserResolver(userID: userID)
        return try? resolver?.resolve(assert: EMMConfig.self)
    }
}

extension UIView {
    @objc
    public func customCanPerformAction(_ action: Selector, withSender sender: Any?) -> SCResponderActionType {
        guard let remainItems = SCPasteboard.general(SCPasteboard.defaultConfig()).canRemainActionsDescrption(),
              !remainItems.contains(action.description) else {
            return SCResponderActionType.performOriginActionAllow
        }
        SCLogger.info("SCPasteboard:PDFView action \(action) forbid")
        return SCResponderActionType.performActionForbid
    }
}

extension SCPasteboard {
    func monitorIfNeeded(action: String) {
        pasteboardService?.monitorIfNeeded(action: action)
    }
}
