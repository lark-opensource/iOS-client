//
//  FCFileMonitor.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/11/17.
//

import Foundation
import LarkSetting
import LarkSecurityCompliance
import LarkSecurityComplianceInfra

public class FCFileMonitor: NSObject {
    
    enum Method: String {
        case dataRead = "data_read"
        case fileHandle = "file_handle"
        case fileManager = "file_manager"
    }
    
    @objc public class var isEnabled: Bool {
        FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: "ios_file_cryptor_monitor_enabled"))
    }
    
    @objc public class func eventIfNeeded(data: Data, path: String) {
        guard checkEncrypted(withData: data) else { return }
        SCMonitor.info(business: .file_stream, eventName: "read_api_mistaked", category: ["path": path, "method": Method.dataRead.rawValue])
        Logger.error("file_read_api_mistaked with path: \(path)")
    }
    
    @objc public class func eventFileManagerIfNeeded(data: Data, path: String) {
        guard checkEncrypted(withData: data) else { return }
        SCMonitor.info(business: .file_stream, eventName: "read_api_mistaked", category: ["path": path, "method": Method.fileManager.rawValue])
        Logger.error("file_read_api_mistaked with path: \(path)")
    }
    
    @objc public class func eventFileHandleIfNeeded(data: Data, path: String) {
        guard checkEncrypted(withData: data) else { return }
        SCMonitor.info(business: .file_stream, eventName: "read_api_mistaked", category: ["path": path, "method": Method.fileHandle.rawValue])
        Logger.error("file_read_api_mistaked with path: \(path)")
    }
    
    class func checkEncrypted(withData data: Data) -> Bool {
        do {
            let header = try AESHeader(data: data)
            return header.checkEncrypted()
        } catch {
            return false
        }
    }
}
