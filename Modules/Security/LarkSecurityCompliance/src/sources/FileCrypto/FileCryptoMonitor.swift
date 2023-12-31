//
//  FileCryptoMonitor.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/7/10.
//

import LarkSecurityComplianceInfra

struct FileCryptoMonitor {
    static func error(_ params: [String: Any], error: Error) {
        let nsErr = error as NSError
        var extra = params
        extra["error_code"] = nsErr.code
        extra["error_msg"] = "\(error)"
        if nsErr == CryptoRustService.CryptoError.globalSdkNotInit
            || nsErr == CryptoRustService.CryptoError.userSdkNotInit {
            SCMonitor.error(business: .file_stream, eventName: "sdk_not_init", extra: extra)
        } else {
            SCMonitor.error(business: .file_stream, eventName: "encryption", extra: extra)
        }
    }
    
    static func migrationTask(_ params: [String: Any]) {
        SCMonitor.error(business: .file_stream, eventName: "migration_record", extra: params)
    }
}
