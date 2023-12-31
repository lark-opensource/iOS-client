//
//  OPDynamicComponentMetaProvider.swift
//  OPDynamicComponent
//
//  Created by Nicholas Tau on 2022/05/25.
//

import Foundation
import OPSDK
import TTMicroApp
import ECOProbe
import LKCommonsLogging

private let logger = Logger.oplog(OPDynamicComponentMetaProvider.self)

private extension OPAppUniqueID {
    func identifierForDyComponent() -> String {
        return self.versionType == .current ? "\(self.appID)_\(self.requireVersion)" : "\(self.appID)_dev"
    }
}

fileprivate var bizMetaProtocolLastUpdateTimestamp: Void? = nil
internal extension OPBizMetaProtocol {
    // 上次更新时间,单位:毫秒
    func setLastUpdateTimestamp(ts: NSNumber)  {
        objc_setAssociatedObject(self, &bizMetaProtocolLastUpdateTimestamp, ts, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }

    // 上次更新时间,单位:毫秒
    func getLastUpdateTimestamp() -> NSNumber {
        return objc_getAssociatedObject(self, &bizMetaProtocolLastUpdateTimestamp) as? NSNumber ?? 0
    }
}

public final class OPDynamicComponentMetaProvider: NSObject, OPAppMetaRemoteAccessor & OPAppMetaLocalAccessor {
    private let builder: OPAppMetaBuilder
    private let localAccessor = MetaLocalAccessor(type: .dynamicComponent)
    private let remoteAccessor = MetaFetcher(config: MetaFetcherConfiguration(shouldReuseSameRequest:true,
                                                                              timeoutIntervalForRequest: 15),
                                             appType: .dynamicComponent)
    init(builder: OPAppMetaBuilder) {
        self.builder = builder
    }
    
    deinit {
        remoteAccessor.invalidateSession()
    }
    public convenience override init() {
        self.init(builder: OPDynamicComponentMetaBuilder())
    }

    public func deleteLocalMeta(with uniqueID: OPAppUniqueID) {
        let identifier = uniqueID.identifierForDyComponent()
        logger.info("deleteLocalMeta with identifier:\(identifier)")
        let uniqueIDWithIdentifier = OPAppUniqueID(appID: uniqueID.appID,
                                                   identifier: identifier,
                                                   versionType: uniqueID.versionType,
                                                   appType: uniqueID.appType)
        let metaContext = MetaContext(uniqueID: uniqueIDWithIdentifier, token: nil)
        localAccessor.removeMetas(with: [metaContext])
    }
    //获取制定的插件
    public func getLocalMeta(with uniqueID: OPAppUniqueID) throws -> OPBizMetaProtocol {
        let identifier = uniqueID.identifierForDyComponent()
        logger.info("getLocalMeta with identifier:\(identifier)")
        //真正去要查询的插件唯一键，需要设置 identifier（appID+版本的格式）
        let uniqueIDWithIdentifier = OPAppUniqueID(appID: uniqueID.appID,
                                                   identifier: identifier,
                                                   versionType: uniqueID.versionType,
                                                   appType: uniqueID.appType)
        let metaContext = MetaContext(uniqueID: uniqueIDWithIdentifier, token: nil)
        guard let jsonStr = localAccessor.getLocalMeta(with: metaContext) else {
            let opError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "has no local meta for app \(uniqueID)")
            throw opError
        }
        let meta = try builder.buildFromJson(jsonStr)
        return meta
    }
    
    public func getAllMetas() throws -> [OPBizMetaProtocol] {
        let allMetaJsonsWithTS = localAccessor.getAllMetasWithTimestamp()
        return try allMetaJsonsWithTS.map({
            let bizMeta = try builder.buildFromJson($0)
            bizMeta.setLastUpdateTimestamp(ts: $1)
            return bizMeta
        })
    }

    public func saveMetaToLocal(with uniqueID: OPAppUniqueID, meta: OPBizMetaProtocol) throws {
        let identifier = uniqueID.identifierForDyComponent()
        logger.info("saveMetaToLocal with identifier:\(identifier)")
        let jsonStr = try meta.toJson()
        let error = localAccessor.saveLocalMeta(with: uniqueID.versionType, key: identifier, value: jsonStr)
        if let error = error {
            logger.error("saveMetaToLocal with error:\(error)")
        }
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
                if let meta = meta as? OPDynamicComponentMeta {
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
