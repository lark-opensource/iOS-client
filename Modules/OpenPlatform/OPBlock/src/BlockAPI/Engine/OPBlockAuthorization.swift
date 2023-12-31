//
//  OPBlockAuthorization.swift
//  OPBlock
//
//  Created by xiangyuanyuan on 2022/8/12.
//

import Foundation
import TTMicroApp
import LarkFeatureGating
import LKCommonsLogging
import OPSDK

// 迁移自OPBlockAPIAdapterPlugin，后期删除OPBlockAPIAdapterPlugin


private let logger = Logger.oplog(OPBlockAuthorization.self, category: "OPBlockAuthorization")

//  Block 引擎API权限校验器
class OPBlockAuthorization: BDPAuthorization {

    override func checkSchema(_ url: AutoreleasingUnsafeMutablePointer<NSURL?>!, uniqueID: OPAppUniqueID, errorMsg: AutoreleasingUnsafeMutablePointer<NSString?>!) -> Bool {
        
        guard let dataSource = source as? OPBlockMetaWithAuth else {
            logger.error("Block id:\(uniqueID) apiCall checkSchema with exec source")
            return false
        }
        
        let trace = dataSource.containerContext?.trace
        
        guard let meta = dataSource.containerContext?.meta else {
            trace?.error("Block id:\(uniqueID) apiCall checkSchema without meta")
            return false
        }
        
        guard let useOpenSchemas = meta.useOpenSchemas, useOpenSchemas else {
            trace?.info("Block id:\(uniqueID) apiCall checkSchema passed do not need useOpenSchemas")
            return true
        }
        
        guard let targetURL = url.pointee else {
            trace?.error("Block id:\(uniqueID) apiCall checkSchema blocked, url is null")
            return false
        }
        
        guard let scheme = targetURL.scheme, let host = targetURL.host else {
            trace?.error("Block id:\(uniqueID) apiCall checkSchema blocked, illegal url")
            return false
        }
        
        guard let schemas = meta.openSchemas as? [OPAppSchema] else {
            trace?.error("Block id:\(uniqueID) apiCall checkSchema blocked, illegal openSchemas")
            return false
        }
        
        let pattern = OPAppSchema(schema: scheme, host: host)
        let ret = schemas.contains(pattern)
        trace?.info("Block id: \(uniqueID) apiCall checkSchema \(ret ? "passed" : "blocked")")
        return ret
    }
    override func checkAuthorization(_ method: BDPJSBridgeMethod?, engine: BDPJSBridgeEngine?, completion: ((BDPAuthorizationPermissionResult) -> Void)? = nil) {
        // 暂且全部开放
        completion?(.enabled)
    }
}

class OPBlockMetaWithAuth: NSObject, BDPMetaWithAuthProtocol {
    
    public let uniqueID: BDPUniqueID
    
    public let name: String
    
    public let icon: String
    
    public weak var containerContext: OPContainerContext?
    
    public private(set) var version: String = ""
    
    public private(set) var version_code: Int64 = 0
    
    // Block 应用目前没有
    public var domainsAuthMap: [String: [String]] {
        return [:]
    }
    
    // Block 应用目前没有
    public var whiteAuthList: [String] {
        return []
    }
    
    // Block 应用目前没有
    public var blackAuthList: [String] {
        return []
    }
    
    public private(set) var authPass: Int = 0
    
    public private(set) var orgAuthMap: [AnyHashable: Any] = [:]
    
    public fileprivate(set) var userAuthMap: [AnyHashable: Any] = [:]
    
    init(name: String, icon: String, containerContext: OPContainerContext) {
        self.name = name
        self.icon = icon
        self.containerContext = containerContext
        self.uniqueID = containerContext.uniqueID
    }
}

class OPBlockAuthStorageProvider: NSObject, BDPAuthStorage {
    func setObject(_ object: Any!, forKey key: String!) -> Bool {
        return true
    }
    
    func object(forKey key: String!) -> Any! {
        return nil
    }
    
    func removeObject(forKey key: String!) -> Bool {
        return true
    }
}
