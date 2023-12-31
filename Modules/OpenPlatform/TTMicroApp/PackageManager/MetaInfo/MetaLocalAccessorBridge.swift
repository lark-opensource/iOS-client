//
//  MetaLocalAccessorBridge.swift
//  TTMicroApp
//
//  Created by ChenMengqi on 2021/7/14.
//

import Foundation
import LKCommonsLogging

private let log = Logger.oplog(MetaLocalAccessorBridge.self, category: "MetaLocalAccessorBridge")
///桥接 swift 方法，以供OC调用
public final class MetaLocalAccessorBridge: NSObject{
    @objc public static func getAllMetas(appType: BDPType) -> [AppMetaProtocol]{
        var metas : [AppMetaProtocol] = []
        let metaLocalAccessor = MetaLocalAccessor(type: appType)
        let provider = GadgetMetaProvider(type: appType)
        let metaJsonStrs =  metaLocalAccessor.getAllMetas()
         for metaJsonStr in metaJsonStrs {
            if let data = metaJsonStr.data(using: String.Encoding.utf8){
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let appId = json?["appID"] as? String {
                    let uniqueId = OPAppUniqueID(appID: appId, identifier: nil, versionType: .current, appType: appType)
                    let metaContext = MetaContext(uniqueID: uniqueId, token: nil)
                    var metaModel: AppMetaProtocol?
                        do {
                            metaModel = try provider.buildMetaModel(with: metaJsonStr, context: metaContext)
                            metas.append(metaModel!)
                        } catch {
                            _ = error.newOPError(monitorCode: CommonMonitorCodeMeta.meta_db_error, message: "build local metamodel from db str failed")
                        }
                    }

            }
        }
        return metas
    }
    
    @objc public static func getMetaWithUniqueId(uniqueID: OPAppUniqueID) -> AppMetaProtocol? {
        let metaLocalAccessor = MetaLocalAccessor(type: .gadget)
        let provider = GadgetMetaProvider(type: .gadget)
        let metaContext = MetaContext(uniqueID: uniqueID, token: nil)
        if let existedMetaString =  metaLocalAccessor.getLocalMeta(with: metaContext){
            let existedMeta = try? provider.buildMetaModel(with: existedMetaString, context: metaContext)
            return existedMeta
        }
        return nil
    }
    
    @objc public static func getAllMetasDESCByTimestampBy(_ appID: String) -> [GadgetMeta] {
        log.info("getAllMetasDESCByTimestampBy with appID:\(appID)")
        let pkmMetaAccessor = PKMMetaAccessor(type: .gadget)
        let provider = GadgetMetaProvider(type: .gadget)
        let metaContext = MetaContext(uniqueID: BDPUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .gadget), token: nil)
        return pkmMetaAccessor.getAllMetasDESCByTimestampBy(appID).compactMap { metaJSONString in
            guard let meta = try? provider.buildMetaModel(with: metaJSONString, context: metaContext) as? GadgetMeta else {
                return nil
            }
            return meta
        }
    }
    
    @objc public static func removeAllMetasInPKMDBWith(_ metaList: [GadgetMeta]){
        log.info("removeAllMetasInPKMDBWith with metaList:\(metaList)")
        let pkmMetaAccessor = PKMMetaAccessor(type: .gadget)
        pkmMetaAccessor.removeMetas(metas: metaList)
    }
    
    @objc public static func removeAllPackagesInPKMWith(_ appID: String, excludedMetaList:[GadgetMeta]) throws {
        log.info("removeAllPackagesInPKMWith with appID:\(appID) and excludedMetaList:\(excludedMetaList)")
        let excludedPackageNameList = excludedMetaList.compactMap { $0.packageName() }
        do {
            try BDPPackageLocalManager.deleteLocalPackages(for: BDPUniqueID(appID: appID,
                                                                            identifier: nil,
                                                                            versionType: .current,
                                                                            appType: .gadget),
                                                           excludedPackageNames: excludedPackageNameList)

        } catch  {
            throw error
        }
    }
    
    @objc public static func removeAllMetasInPKMDBWithAppID(_ appID: String) {
        let pkmMetaAccessor = PKMMetaAccessor(type: .gadget)
        pkmMetaAccessor.removeAllMetasBy(appID)
    }
}

