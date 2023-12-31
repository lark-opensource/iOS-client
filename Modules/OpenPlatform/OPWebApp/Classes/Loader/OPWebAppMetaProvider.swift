//
//  OPWebAppMetaProvider.swift
//  OPGadget
//
//  Created by Nicholas Tau on 2021/11/4.
//

import Foundation
import OPSDK
import TTMicroApp
import ECOProbe
import LKCommonsLogging
import LarkSetting


private let logger = Logger.oplog(OPWebAppMetaProvider.self)

public final class OPWebAppMetaProvider: NSObject, OPAppMetaRemoteAccessor & OPAppMetaLocalAccessor {
    private let builder: OPAppMetaBuilder
    private let localAccessor = MetaLocalAccessor(type: .webApp)
    private let remoteAccessor = MetaFetcher(config: MetaFetcherConfiguration(shouldReuseSameRequest:true,
                                                                              timeoutIntervalForRequest: 15),
                                             appType: .webApp)
    init(builder: OPAppMetaBuilder) {
        self.builder = builder
    }
    deinit {
        remoteAccessor.invalidateSession()
    }
    
    public convenience override init() {
        self.init(builder: OPWebAppMetaBuilder())
    }

    public func deleteLocalMeta(with uniqueID: OPAppUniqueID) {
        let metaContext = MetaContext(uniqueID: uniqueID, token: nil)
        localAccessor.removeMetas(with: [metaContext])
    }

    public func getLocalMeta(with uniqueID: OPAppUniqueID) throws -> OPBizMetaProtocol {
        let metaContext = MetaContext(uniqueID: uniqueID, token: nil)
        guard let jsonStr = localAccessor.getLocalMeta(with: metaContext) else {
            let opError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "has no local meta for app \(uniqueID)")
            throw opError
        }
        let meta = try builder.buildFromJson(jsonStr)
        return meta
    }

    /// 获取所有离线H5的metas数组
    public func getAllOfflineH5Metas() -> [OPBizMetaProtocol] {
        let allMetaJsons = localAccessor.getAllMetas()
        var offlineMetaArray = [OPBizMetaProtocol]()

        do {
            for metaJson in allMetaJsons {
                let bizMeta = try builder.buildFromJson(metaJson)
                if let webMeta = bizMeta as? OPWebAppMeta, webMeta.extConfig.offlineEnable {
                    offlineMetaArray.append(bizMeta)
                }
            }
        } catch {
            logger.warn("build webApp meta fail")
        }

        return offlineMetaArray
    }

    public func saveMetaToLocal(with uniqueID: OPAppUniqueID, meta: OPBizMetaProtocol) throws {
        let jsonStr = try meta.toJson()
        localAccessor.saveLocalMeta(with: uniqueID.versionType, key: uniqueID.identifier, value: jsonStr)
    }

    public func cancelFetchMeta(with uniqueID: OPAppUniqueID, previewToken: String) {
        let taskID = getRemoteMetaTaskID(with: uniqueID, previewToken: previewToken)
        remoteAccessor.clearTask(with: taskID)
    }

    public func fetchRemoteMeta(
        with uniqueID: OPAppUniqueID,
        previewToken: String,
        progress: requestProgress?,
        completion: requestCompletion?)
    {
        let metaContext = MetaContext(uniqueID: uniqueID, token: previewToken)
        let requestTrace = BDPTracingManager.sharedInstance().generateTracing(withParent: metaContext.trace)
        progress?(0, 1)
        guard let request = try? builder.generateMetaRequest(uniqueID, previewToken: previewToken) else {
            let opError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "request remote build request error for app \(uniqueID)")
            progress?(1, 1)
            completion?(false, nil, opError)
            return
        }
        let taskID = getRemoteMetaTaskID(with: uniqueID, previewToken: previewToken)
        remoteAccessor.requestMeta(with: request, token: taskID, uniqueID: uniqueID, trace: requestTrace) { [weak self](data, _, error) in
            progress?(1, 1)
            let error: Error? = nil
            guard let `self` = self else {
                let opError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "request remote callback but provider released for app \(uniqueID)")
                completion?(false, nil, opError)
                return
            }
            guard error == nil else {
                let opError = error!.newOPError(monitorCode: OPSDKMonitorCode.unknown_error)
                completion?(false, nil, opError)
                return
            }
            guard let data = data else {
                let opError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "request remote meta error with nil data")
                completion?(false, nil, opError)
                return
            }
            do {
                let meta = try self.builder.buildFromData(data, uniqueID: uniqueID)
                if let meta = meta as? OPWebAppMeta {
                    logger.info("webApp:\(uniqueID) suppoerOnline is\(uniqueID.supportOnline)")
                    if !FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webapp.update.pushcommand.enable")) {
                        //离线能力不可用，返回错误
                        if !meta.extConfig.offlineEnable &&
                            //仅在线模式时，不检查 offlineEnable
                            !uniqueID.supportOnline {
                            let opError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, userInfo: ["errorExType": OPWebAppErrorType.offlineDisable.rawValue])
                            completion?(false, nil, opError)
                            return
                        }
                    }
                    //判断版本可用性
                    if let minLarkVersion = meta.extConfig.minLarkVersion as? String,
                       let larkVersion = BDPDeviceTool.bundleShortVersion {
                        //如果minLarkVersion大于本地飞书版本，则不允许打开离线包
                        if BDPVersionManager.compareVersion(minLarkVersion, with: larkVersion) > 0 {
                            let opError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, userInfo: ["errorExType": OPWebAppErrorType.verisonCompatible.rawValue])
                            completion?(false, nil, opError)
                            return
                            
                        }
                    }
                    completion?(true, meta, nil)
                }
            } catch let err {
                let opError = err as? OPError ?? err.newOPError(monitorCode: OPSDKMonitorCode.unknown_error)
                completion?(true, nil, opError)
            }
        }
    }

    private func getRemoteMetaTaskID(with uniqueID: OPAppUniqueID,
                                     previewToken: String) -> String {
        return "\(uniqueID.fullString)-\(previewToken)"
    }
}
