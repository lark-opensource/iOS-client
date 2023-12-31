//
//  OPAppUniqueID+PB.swift
//  TTMicroApp
//
//  Created by MJXin on 2021/12/13.
//

import Foundation
import LarkRustClient
import RustPB
import LKCommonsLogging


extension Openplatform_Api_APIAppContext {
    static let logger = Logger.oplog(Openplatform_Api_APIAppContext.self, category: "OpenAPIAppContext")
    
    public static func context(from uniqueID: OPAppUniqueID) -> Openplatform_Api_APIAppContext? {
        guard let contextKey = BDPTracingManager.sharedInstance().getTracingBy(uniqueID)?.traceId else {
            Self.logger.error(
                "Get contextKey fail, UniqueID is illegal",
                additionalData: [
                    "fullString": uniqueID.fullString,
                    "appID": uniqueID.appID
            ])
            return nil
        }
        var version = ""
        switch uniqueID.appType {
        case .block, .widget:
            version = uniqueID.packageVersion ?? ""
        case .gadget:
            if let commonManager = BDPCommonManager.shared(), let common = commonManager.getCommonWith(uniqueID) {
                version = common.model.version ?? ""
            }
        default:
            assertionFailure("invalid app type, this must not happen")
        }
        
        var apiContext = Openplatform_Api_APIAppContext()
        apiContext.contextKey = contextKey
        apiContext.appID = uniqueID.appID
        apiContext.identifier = uniqueID.identifier
        apiContext.appVersion = version
        apiContext.appType = Self.appType(from: uniqueID.appType)
        apiContext.jssdkVersion = BDPVersionManager.localLibVersionString() ?? ""
        return apiContext
    }
    
    public  static func appType(from type: OPAppType) -> Openplatform_Api_OpenplatformAppType {
        switch type {
        case .unknown:
            return .unKnown
        case .gadget:
            return .gadgetApp
        case .webApp:
            return .webApp
        case .widget:
            return .cardApp
        case .block:
            return .blockitApp
        default:
            assertionFailure("unknown app type: \(type)")
            return .unKnown
        }
    }
}
