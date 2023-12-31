//
//  GadgetSchemeHandlerCode.swift
//  TTMicroApp
//
//  Created by justin on 2023/8/17.
//

import Foundation
import ECOProbe
import ECOProbeMeta

final class GadgetSchemeHandlerCode: OPMonitorCode {
    
    /// file handler parse url info is null.
    static let fileAppLoadURLInfoNull = GadgetSchemeHandlerCode(code: 10001, level:OPMonitorLevelError , message: "file_app_load_url_info_null")
    
    /// file handler response data is invalid
    static let fileResponseError = GadgetSchemeHandlerCode(code: 10002, level: OPMonitorLevelError, message: "file_response_error")
    
    /// file handler load data is null.
    static let fileLoadDataNull = GadgetSchemeHandlerCode(code: 10003, level:OPMonitorLevelError , message: "file_load_data_null")
    
    /// file handler response is null.
    static let fileResponseNull = GadgetSchemeHandlerCode(code: 10004, level:OPMonitorLevelError , message: "file_response_null")
    
    /// file handler pkg read fail.
    static let filePkgReadFail = GadgetSchemeHandlerCode(code: 10005, level:OPMonitorLevelError , message: "file_pkg_read_fail")
    
    /// file handler jssdk read fail.
    static let fileJSSDKReadFail = GadgetSchemeHandlerCode(code: 10006, level:OPMonitorLevelError , message: "file_jssdk_read_fail")
    
    /// file handler jssdk read fail.
    static let fileSandboxReadFail = GadgetSchemeHandlerCode(code: 10007, level:OPMonitorLevelError , message: "file_sandbox_read_fail")
    
    /// file handler app info type invalid
    static let fileAppInfoTypeInvalid = GadgetSchemeHandlerCode(code: 10008, level:OPMonitorLevelError , message: "file_app_info_type_invalid")
    
    /// file handler store module error
    static let fileStorageModuleInvalid = GadgetSchemeHandlerCode(code: 10009, level:OPMonitorLevelError , message: "file_storage_module_invalid")
    
    /// webp response data is invalid
    static let webpResponseError = GadgetSchemeHandlerCode(code: 20001, level: OPMonitorLevelError, message: "webp_response_error")
    
    /// webp response data is invalid
    static let webpDataInvalid = GadgetSchemeHandlerCode(code: 20002, level: OPMonitorLevelError, message: "webp_data_Invalidate")
    
    /// webp response is Invalid , maybe is nil
    static let webpResponeInvalid = GadgetSchemeHandlerCode(code: 20003, level: OPMonitorLevelError, message: "webp_response_Invalidate")
    
    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: GadgetSchemeHandlerCode.domain, code: code, level: level, message: message)
    }

    static let domain = "client.open_platform.gadget.schemehandler"
}
