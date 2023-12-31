//
//  SCPasteboardWrapper.swift
//  LarkEMM
//
//  Created by ByteDance on 2023/2023/12/24.
//
import LarkSensitivityControl
import LarkSecurityComplianceInfra

public final class SCPasteboardWrapper: NSObject {
    // For paste protect scheme
    @objc public class var customPasteboard: UIPasteboard? {
        return SCPasteboard.customPasteboard
    }
    
    @objc public class var copyPasteboard: UIPasteboard? {
        return SCPasteboard.copyPasteboard
    }
    
    @objc public class var pastePasteboard: UIPasteboard? {
        return SCPasteboard.pastePasteboard
    }
    
    @objc
    public class func updateCustomPasteboard() {
        SCPasteboard.general(SCPasteboard.currentConfig()).updateCustomPasteboard()
    }
    
    @objc
    public class func clearSCPasteboardConfig() {
        // 用默认config重置当前config
        pasteProtectLogger.info("SCPasteboard: clear currentConfig: \(SCPasteboard.currentConfig())", additionalData: nil)
        _ = SCPasteboard.general(SCPasteboard.defaultConfig())
    }
    
    @objc
    public class func clearLastPointId() {
        SCPasteboard.general(SCPasteboard.currentConfig()).clearLastPointId()
    }
    
    // For pdf
    @objc
    public class func updatePasteboardForPdfCopyContent() {
        if SCPasteboard.general(SCPasteboard.defaultConfig()).checkCopyPermission() {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                let config = PasteboardConfig(token: Token("LARK-PSDA-pasteboard_pdfview"))
                SCPasteboard.general(config).assignmentFromPasteboard()
            }
        }
    }
    
    @objc
    public class func info(_ msg: String,
                           file: String = #fileID) {
        SCLogger.info(msg, file: file)
    }
    
}
