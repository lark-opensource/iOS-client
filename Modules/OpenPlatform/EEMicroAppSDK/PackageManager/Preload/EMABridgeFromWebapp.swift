//
//  EMABridgeFroWebapp.swift
//  EEMicroAppSDK
//
//  Created by Nicholas Tau on 2021/12/7.
//

import Foundation
import OPSDK
import OPWebApp
import LKCommonsLogging

class EMABridgeBDPModel: NSObject, BDPCommonUpdateModelProtocol {
    private(set) var uniqueID: OPAppUniqueID
    private(set) var pkgName: String
    private(set) var version: String
    private(set) var version_code: Int64
    
    init(uniqueID: OPAppUniqueID, pkgName: String, version: String) {
        self.uniqueID = uniqueID
        self.pkgName = pkgName
        self.version = version
        self.version_code = 0
        super.init()
    }
}

@objcMembers
open class EMABridgeFromWebapp: NSObject {
    static let logger = Logger.oplog(EMABridgeFromWebapp.self, category: "EMABridgeFromWebapp")
    public class func getModelWithUniqueID(_ uniqueID: OPAppUniqueID) -> BDPCommonUpdateModelProtocol? {
        //如果是 webApp类型，收口处理
        if(uniqueID.appType == .webApp) {
            if let (version, pkgName) = OPWebAppManager.sharedInstance.basicInfoWithUniqueId(uniqueID) {
                var commonUpdateModel = EMABridgeBDPModel(uniqueID: uniqueID,
                                                          pkgName: pkgName,
                                                          version: version)
                return commonUpdateModel
            }
            return nil
        }
        return BDPAppLoadManager.getModelWith(uniqueID)
    }
    
    public class func preloadWebappWith(_ uniqueID: OPAppUniqueID, completeCallback:@escaping (Error?, BDPCommonUpdateModelProtocol?) -> Void) {
        OPWebAppManager.sharedInstance.preloadWebAppWith(uniqueId: uniqueID) { error, state, metaExtConfig in
            //error出错，直接透传出去
            if let error = error {
                completeCallback(error, nil)
                return
            }
            //meta 阶段不回调
            if state == .meta {
                EMABridgeFromWebapp.logger.info("preloadWebappWith, webapp return on meta state")
                return
            }
            var commonUpdateModel: BDPCommonUpdateModelProtocol? = nil
            if let (version, pkgName) = OPWebAppManager.sharedInstance.basicInfoWithUniqueId(uniqueID) {
                commonUpdateModel = EMABridgeBDPModel(uniqueID: uniqueID,
                                                          pkgName: pkgName,
                                                          version: version)
            }
            completeCallback(nil, commonUpdateModel)
            OPWebAppManager.sharedInstance.cleanWebAppInMemory(uniqueID: uniqueID)
        }
    }
}
