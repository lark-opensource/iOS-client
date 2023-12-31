//
//  FetchChatIDUtil.swift
//  OPPluginBiz
//
//  Created by ByteDance on 2023/8/29.
//

import Foundation
import ECOInfra
import LKCommonsLogging
import LarkContainer

@objc
public final class FetchIDUtils: NSObject {
    
    static let logger = Logger.oplog(FetchIDUtils.self, category: "FetchIDUtils")
    
    public static var service: ECONetworkService {
        return Injected<ECONetworkService>().wrappedValue
    }
    
    public static func getSessionKey(appType: OPAppType) -> String {
        var sessionKey = "session"
        switch appType {
        case .webApp:
            sessionKey = "h5Session"
        case .gadget:
            sessionKey = "minaSession"
        default:
            break
        }
        return sessionKey
    }
    
    public static func generateContext(uniqueID: OPAppUniqueID) -> OpenECONetworkAppContext {
        let tracing = EMARequestUtil.generateRequestTracing(uniqueID)
        let networkContext = OpenECONetworkAppContext(trace: tracing, uniqueId: uniqueID, source: .api)
        return networkContext
    }
    
}
