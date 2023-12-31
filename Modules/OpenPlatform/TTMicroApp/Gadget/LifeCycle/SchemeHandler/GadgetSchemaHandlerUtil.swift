//
//  GadgetSchemaHandlerUtil.swift
//  TTMicroApp
//
//  Created by justin on 2023/8/15.
//

import Foundation
import ECOInfra
import LarkContainer
import Swinject

func safeStr(_ str: String?) -> String {
    guard let safeS = str else {
        return ""
    }
    return safeS
}

func safeDict(_ dict: [String: String]?) -> [String: String] {
    guard let safeMap = dict else {
        return ["":""]
    }
    return safeMap
}

@objc
final public class GadgetSchemeHandlerUtil: NSObject {
    public static let shareUtil = GadgetSchemeHandlerUtil()
    
    /// url scheme handler valide global, include webview preload, default  false.
    let enableAllSchemeHandler: Bool
    
    /// enable scheme handler for appid in whiteAppIds. otherwise not enable, default [].
    let whiteAppIds: [String]
    
    /// enable webview monitor stuck, defalut false
    let enableStuckMonitor: Bool
    
    /// stuck time threshold, default is 3.0 seconds
    let stuckThreshold: Double
    
    @objc override init() {
        let config = Self.getHandlerConfig()
        self.enableAllSchemeHandler = config?["enableAllSchemaHandler"] as? Bool ?? false
        self.whiteAppIds = config?["whiteAppIds"] as? [String] ?? []
        self.enableStuckMonitor = config?["enableStuckMonitor"] as? Bool ?? false
        self.stuckThreshold = config?["stuckThreshold"] as? Double ?? 3.0
        
        super.init()
    }
    
    
    /// enable scheme handle for target gadget appId
    /// - Parameter appId: gadget app identifier
    /// - Returns: true is in white appIds; false not in.
    @objc static public func enableHandle(appId: String?) -> Bool {
        guard let curAppId = appId else {
            return false
        }
        return shareUtil.whiteAppIds.contains(curAppId)
    }
    
    /// enable  scheme handle for all gadget, that mean white appIds invalidate.
    /// - Returns: true is enable all; false, not all and check white appIds.
    @objc static public func enableAllHandle() -> Bool {
        return shareUtil.enableAllSchemeHandler
    }
    
    
    @objc static public func enableStuckMonitor() -> Bool {
        return shareUtil.enableStuckMonitor
    }
    
    
    @objc static public func stuckThreshold() -> Double {
        return shareUtil.stuckThreshold
    }
    
    
    /// get handler config for Scheme Handler
    /// - Returns: config
    static func getHandlerConfig() -> [String: AnyObject]? {
        let userResolver = OPUserScope.userResolver()
        let configService = userResolver.resolve(ECOConfigService.self)
        guard let config = configService?.getLatestDictionaryValue(for: "gadget_webview_scheme_handler_config") as? [String: AnyObject] else {
            return nil
        }
        return config
    }
}
