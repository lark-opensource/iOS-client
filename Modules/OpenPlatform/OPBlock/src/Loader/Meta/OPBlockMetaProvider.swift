//
//  OPBlockMetaProvider.swift
//  OPBlock
//
//  Created by lixiaorui on 2020/12/6.
//

import Foundation
import OPSDK
import TTMicroApp
import LarkOPInterface
import ECOProbe
import LKCommonsLogging

extension OPBlockMetaProvider: MetaProviderProtocol {
    
    public func buildMetaModel(with data: Data, ttcode: BDPMetaTTCode, context: TTMicroApp.MetaContext) throws -> TTMicroApp.AppMetaProtocol {
        let json = try JSONSerialization.jsonObject(with: data)
        guard let jsonDic = json as? [String: Any] else {
            let msg = "jsonDic form data is nil"
            let opError = OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: msg)
            assertionFailure(opError.description)
            throw opError
        }
        return try buildMetaModelWithDict(jsonDic, ttcode: ttcode, context: context)
    }
    
    public func buildMetaModelWithDict(
            _ dict: [String: Any],
            ttcode: BDPMetaTTCode,
            context: MetaContext
    ) throws -> AppMetaProtocol  {
        let provider = OPBlockMetaProvider()
        if  let data = try? JSONSerialization.data(withJSONObject: dict),
            let blockMeta = provider.getMeta(with: data, uniqueID: context.uniqueID) {
                return blockMeta
        }
        throw OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: "buildMetaModelWithDict with error, blockMeta return nil")
    }
    
    public func buildMetaModel(with metaJsonStr: String, context: MetaContext) throws -> AppMetaProtocol {
        let provider = OPBlockMetaProvider()
        if  let data = metaJsonStr.data(using: .utf8),
            let blockMeta = provider.getMeta(with: data, uniqueID: context.uniqueID) {
            return blockMeta
        }
        throw OPError.error(monitorCode: CommonMonitorCodeMeta.invalid_params, message: "buildMetaModel with error, blockMeta return nil")
    }
}

@objc
public final class OPBlockMetaProvider: NSObject, OPAppMetaRemoteAccessor, OPAppMetaLocalAccessor {

    private let builder: OPAppMetaBuilder
    private let containerContext: OPContainerContext
    private let localAccessor = MetaLocalAccessor(type: .block)
    private let remoteAccessor = MetaFetcher(config: MetaFetcherConfiguration(shouldReuseSameRequest:true,
                            timeoutIntervalForRequest: 15),
                                          appType: .block)

    private var trace: BlockTrace {
        containerContext.blockTrace
    }
    deinit {
        remoteAccessor.invalidateSession()
    }

    init(builder: OPAppMetaBuilder, containerContext: OPContainerContext) {
        self.builder = builder
        self.containerContext = containerContext
    }
    /// 仅提供预安装场景使用
    /// - Parameter builder:
    public convenience override init() {
        //如果要在外部获得block 的metaprovider，需要伪造一系列的对象
        let appID = "blk_preload"
        let blkUniqueID = OPAppUniqueID(appID: appID, identifier: nil, versionType:.current, appType: .block)
        let applicationContext = OPApplicationContext(applicationServiceContext: OPApplicationService.current.applicationServiceContext, appID: appID)
        let containerConfig = OPContainerConfig(previewToken: nil, enableAutoDestroy: false)
        let containerContext = OPContainerContext(applicationContext: applicationContext, uniqueID:blkUniqueID, containerConfig: containerConfig)
        let tracing = BDPTracingManager.sharedInstance().getTracingBy(blkUniqueID) ??  BDPTracingManager.sharedInstance().generateTracing(by:blkUniqueID)
        let blkTrace = OPBlockTrace(trace: tracing, uniqueID: blkUniqueID)
        containerContext.baseBlockTrace = blkTrace
        
        self.init(builder: OPBlockMetaBuilder(), containerContext: containerContext)
    }

    public func deleteLocalMeta(with uniqueID: OPAppUniqueID) {
        trace.info("OPBlockMetaProvider.deleteLocalMeta")
        let metaContext = MetaContext(uniqueID: uniqueID, token: nil)
        localAccessor.removeMetas(with: [metaContext])
    }

    public func getLocalMeta(with uniqueID: OPAppUniqueID) throws -> OPBizMetaProtocol {
        trace.info("OPBlockMetaProvider.getLocalMeta")
        let metaContext = MetaContext(uniqueID: uniqueID, token: nil)
        guard let jsonStr = localAccessor.getLocalMeta(with: metaContext) else {
            let opError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "has no local meta for app \(uniqueID)")
            trace.error("OPBlockMetaProvider.getLocalMeta error: \(opError.description)")
            throw opError
        }
        let meta = try builder.buildFromJson(jsonStr)
        return meta
    }
    
    public func getMeta(with data: Data, uniqueID: OPAppUniqueID) -> AppMetaProtocol? {
        if let blockMeta = try? self.builder.buildFromData(data, uniqueID: uniqueID) as? OPBlockMeta {
            return blockMeta.appMetaAdapter
        }
        return nil
    }

    public func saveMetaToLocal(with uniqueID: OPAppUniqueID, meta: OPBizMetaProtocol) throws {
        let jsonStr = try meta.toJson()
        trace.info("OPBlockMetaProvider.saveMetaToLocal metaAppVersion: \(meta.appVersion)")
        localAccessor.saveLocalMeta(with: uniqueID.versionType, key: uniqueID.identifier, value: jsonStr)
    }

    public func cancelFetchMeta(with uniqueID: OPAppUniqueID, previewToken: String) {
        trace.info("OPBlockMetaProvider.cancelFetchMeta")
        let taskID = getRemoteMetaTaskID(with: uniqueID, previewToken: previewToken)
        remoteAccessor.clearTask(with: taskID)
    }

    public func fetchRemoteMeta(
        with uniqueID: OPAppUniqueID,
        previewToken: String,
        progress: requestProgress?,
        completion: requestCompletion?)
    {
        trace.info("OPBlockMetaProvider.fetchRemoteMeta")
        let metaContext = MetaContext(uniqueID: uniqueID, token: previewToken)
        let requestTrace = BDPTracingManager.sharedInstance().generateTracing(withParent: trace.bdpTracing)
        progress?(0, 1)
        guard let request = try? builder.generateMetaRequest(uniqueID, previewToken: previewToken) else {
            let opError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "request remote build request error for app \(uniqueID)")
            trace.error("OPBlockMetaProvider.fetchRemoteMeta error: \(opError.description)")
            progress?(1, 1)
            completion?(false, nil, opError)
            return
        }
        let taskID = getRemoteMetaTaskID(with: uniqueID, previewToken: previewToken)
        let tmpTrace = trace

        remoteAccessor.requestMeta(with: request, token: taskID, uniqueID: uniqueID, trace: requestTrace) { [weak self](data, _, error) in
            progress?(1, 1)
            guard let `self` = self else {
                let opError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "request remote callback but provider released for app \(uniqueID)")
                tmpTrace.error("OPBlockMetaProvider.fetchRemoteMeta remoteAccessor.requestMeta error: \(opError.description)")
                completion?(false, nil, opError)
                return
            }
            guard error == nil else {
                let opError = error!.newOPError(monitorCode: OPSDKMonitorCode.unknown_error)
                self.trace.error("OPBlockMetaProvider.fetchRemoteMeta remoteAccessor.requestMeta error: \(opError.description)")
                completion?(false, nil, opError)
                return
            }
            guard let data = data else {
                let opError = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "request remote meta error with nil data")
                self.trace.error("OPBlockMetaProvider.fetchRemoteMeta remoteAccessor.requestMeta error: \(opError.description)")
                completion?(false, nil, opError)
                return
            }
            do {
                let meta = try self.builder.buildFromData(data, uniqueID: uniqueID)
                completion?(true, meta, nil)
            } catch let err {
                let opError = err as? OPError ?? err.newOPError(monitorCode: OPSDKMonitorCode.unknown_error)
                self.trace.error("OPBlockMetaProvider.fetchRemoteMeta remoteAccessor.requestMeta error: \(opError.description)")
                completion?(true, nil, opError)
            }
        }
    }

    private func getRemoteMetaTaskID(with uniqueID: OPAppUniqueID,
                                     previewToken: String) -> String {
        return "\(uniqueID.fullString)-\(previewToken)"
    }
}
