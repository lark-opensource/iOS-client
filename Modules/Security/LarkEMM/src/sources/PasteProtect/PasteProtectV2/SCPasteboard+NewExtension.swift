//
//  SCPasteboard+NewExtension.swift
//  LarkEMM
//
//  Created by ByteDance on 2023/12/24.
//

import Foundation
import LarkSecurityComplianceInfra
import LarkContainer
import WebKit

extension SCPasteboard {
    var pointIdKey: String {
        "PointId_\(pasteboardService?.currentEncryptUserId())"
    }
    
    var scStore: SCKeyValueStorage {
        SCKeyValue.globalUserDefault()
    }
    
    public class var customPasteboard: UIPasteboard? {
        let general = SCPasteboard.general
        return general.customPasteboard
    }
    
    public class var copyPasteboard: UIPasteboard? {
        let general = SCPasteboard.general
        if general.checkCopyPermission() {
            pasteProtectLogger.info("SCPasteboard: get custom pasteboard when copy")
            return general.customPasteboard
        }
        return nil
    }
    
    public class var pastePasteboard: UIPasteboard? {
        let general = SCPasteboard.general
        if general.checkPastePermission() {
            pasteProtectLogger.info("SCPasteboard: get custom pasteboard when paste")
            return general.customPasteboard
        }
        return nil
    }
    
    static func currentConfig() -> PasteboardConfig {
        return general.config
    }
    
    static func scReplaceUIPasteboard() {
        DispatchQueue.main.once {
            pasteProtectLogger.info("UIPasteboard.scReplaceMethod")
            UIPasteboard.scReplaceMethod()
            WKWebView.scReplaceActionMethod()
            PDFView.scReplaceActionMethod()
            UITextView.scReplaceActionMethod()
            UITextField.scReplaceActionMethod()
        }
    }
    
    func updateCustomPasteboard() {
        addPointIdIfNeeded()
        clearOtherCustomPasteboard()
        showDialogIfNeed()
    }
    
    func clearLastPointId() {
        pasteProtectLogger.info("SCPasteboard: clearLastPointId with currentConfig: \(Self.currentConfig())", additionalData: nil)
        lastPointId = nil
        scStore.removeObject(forKey: pointIdKey)
    }
    
    static func config(resolver: UserResolver) {
        DispatchQueue.main.once {
            // hook逻辑只取决于第一次获取到的FG
            let fgService = try? resolver.resolve(assert: SCFGService.self)
            enablePasteProtectOpt = (fgService?.realtimeValue(.enablePasteProtectOpt) == true)
        }
    }
}
