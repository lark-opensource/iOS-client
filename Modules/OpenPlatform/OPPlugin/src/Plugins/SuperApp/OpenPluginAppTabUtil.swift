//
//  OpenPluginAppTabUtil.swift
//  OPPlugin
//
//  Created by justin on 2023/7/4.
//

import Foundation
import OPFoundation
import LarkOpenAPIModel
import LarkRustClient

class OpenPluginAppTabUtil {
    
    class func processError(error: Error) -> OpenAPIError {
        guard let rcError = error as? RCError else {
            return OpenAPIError(errno: OpenAPICommonErrno.internalError)
        }
        var errorMessage = OpenAPICommonErrno.internalError.errString
        var errCode = OpenAPICommonErrno.internalError.rawValue
        switch rcError {
        case .businessFailure(let errorInfo):
            errorMessage = errorInfo.displayMessage
            errCode = Int(errorInfo.errorCode)
        default:
            errorMessage = OpenAPICommonErrno.internalError.errString
            errCode = OpenAPICommonErrno.internalError.rawValue
        }
        
        let categoryError = OpenAPIError(errno: OpenAPIAppCatalogErrno.tabError(code: String(errCode), message: errorMessage)).setAddtionalInfo(["errCode": String(errCode)])
        return categoryError
    }
    
    // 检查appTab API 是否在白名单
    class func checkAppTabAPI(apiName: String, uniqueID: OPAppUniqueID) -> Bool {
        guard let appEngine = (BDPTimorClient.shared().appEnginePlugin.sharedPlugin() as? EMAAppEnginePluginDelegate),
              appEngine.onlineConfig?.isApiAvailable(apiName, for: uniqueID) ?? false else {
            return false
        }
        return true
    }
    
}
