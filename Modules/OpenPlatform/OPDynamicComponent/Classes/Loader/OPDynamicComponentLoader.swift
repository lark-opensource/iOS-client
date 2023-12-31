//
//  OPDynamicComponentLoader.swift
//  OPDynamicComponent
//
//  Created by Nicholas Tau on 2022/05/25.
//

import Foundation
import OPSDK
import TTMicroApp
import ECOProbe
import LKCommonsLogging
import ECOInfra

private let logger = Logger.oplog(OPDynamicComponentLoader.self)

protocol OPDynamicComponentLoaderMetaAndPackageEvent: OPAppLoaderMetaAndPackageEvent {

    /// 包更新成功
    func onBundleUpdateSuccess()
}

class OPDynamicComponentLoaderContext {
    let uniqueID: OPAppUniqueID
    let previewToken: String
    init(uniqueID: OPAppUniqueID, previewToken: String) {
        self.uniqueID = uniqueID
        self.previewToken = previewToken
    }
}

final class OPDynamicComponentLoader: NSObject, OPAppLoaderSimpleProtocol {

    private var loaderContext: OPDynamicComponentLoaderContext

    private let packageProvider: BDPPackageModuleProtocol
    private let metaProvider: OPAppMetaRemoteAccessor & OPAppMetaLocalAccessor
    
    private static let subscribeRelationshipKey = "ksubscribeRelationshipKey"

    public init?(uniqueID: OPAppUniqueID, previewToken: String) {
        logger.info("[componentMeta] uniqueID: \(uniqueID) OPDynamicComponentLoader.init")
        guard let packageManager = BDPModuleManager(of: .dynamicComponent).resolveModule(with: BDPPackageModuleProtocol.self) as? BDPPackageModuleProtocol else {
            let _ = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "has no pkg module manager for componentMeta for app \(uniqueID)")
            assertionFailure("has no pkg module manager for componentMeta for app \(uniqueID)")
            return nil
        }
        self.metaProvider = OPDynamicComponentMetaProvider(builder: OPDynamicComponentMetaBuilder())
        self.packageProvider = packageManager
        self.loaderContext = OPDynamicComponentLoaderContext(uniqueID: uniqueID, previewToken: previewToken)
    }
    
    public func isLocalMetaExist() -> Bool {
        if let _ = try? metaProvider.getLocalMeta(with: self.loaderContext.uniqueID) {
            return true
        }
        return false
    }

    public func loadMetaAndPackage(listener: OPAppLoaderMetaAndPackageEvent?) {
        let uniqueID = loaderContext.uniqueID
        logger.info("[componentMeta] uniqueID: \(uniqueID), OPDynamicComponentLoader.loadMetaAndPackage")
        listener?.onMetaLoadStarted(strategy: .normal)
        //需要检查插件和宿主的订阅关系，如果不存在，不能返回缓存数据
        guard let kvStorage = (BDPModuleManager(of: .dynamicComponent).resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol)?.sharedLocalFileManager().kvStorage else {
            let error  = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "kvStorage is nil for app \(uniqueID)")
            listener?.onMetaLoadComplete(strategy: .normal, success: false, meta: nil, error: error, fromCache: false)
            return
        }
        let subscription =  kvStorage.object(forKey: OPDynamicComponentLoader.subscribeRelationshipKey) as? [String: [String]]
        guard let hostID = uniqueID.instanceID else {
            let error  = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "instanceID is nil for app \(uniqueID)")
            listener?.onMetaLoadComplete(strategy: .normal, success: false, meta: nil, error: error, fromCache: false)
            logger.error("[componentMeta] uniqueID: \(uniqueID), OPDynamicComponentLoader.loadMetaAndPackage with error, hostID is nil")
            return
        }
        //检查订阅关系，是否在宿主允许访问的动态组件列表内
        let relationshipExisted = (subscription?[hostID])?.contains(uniqueID.appID) ?? false
        //如果存在订阅关系，尝试从本地找到对应的动态组件
        //否则本地缓存必须是nil，尝试从线上拿最新版
        let localMeta = relationshipExisted ? try? metaProvider.getLocalMeta(with: uniqueID) : nil
        // perview每次都获取最新的，不取本地
        if uniqueID.versionType != .preview, let localMeta = localMeta {
            listener?.onMetaLoadProgress(strategy: .normal, current: 1.0, total: 1.0)
            listener?.onMetaLoadComplete(strategy: .normal, success: true, meta: localMeta, error: nil, fromCache: true)
            getRemotePackage(strategy: .normal, meta: localMeta, metaTrace: tracing, listener: listener, successHandler: nil)
            internalUpdateMetaAndPackage(strategy: .update, listener: listener)
        } else {
            getRemoteMeta(uniqueID: uniqueID, strategy: .normal, listener: listener) { [weak self] (meta) in
                guard let `self` = self else {
                    logger.error("loader release for dynamic component \(uniqueID)")
                    return
                }
                guard let meta = meta else {
                    logger.error("meta is nil for app \(uniqueID)")
                    return
                }
                //如果先前是没有订阅关系的，需要在缓存里添加订阅关系
                if !relationshipExisted {
                    var subscriptionMap = subscription ?? [:]
                    var subscriptionToUpdate = subscriptionMap[hostID] ?? []
                    subscriptionToUpdate.append(uniqueID.appID)
                    subscriptionMap[hostID] = subscriptionToUpdate
                    kvStorage.setObject(subscriptionMap, forKey: OPDynamicComponentLoader.subscribeRelationshipKey)
                }
                self.getRemotePackage(strategy: .normal, meta: meta, metaTrace: self.tracing, listener: listener) {[weak self] in
                    guard let `self` = self else {
                        logger.error("loader release for dynamic component \(uniqueID)")
                        return
                    }
                    self.saveLocalMeta(meta)
                }
            }
        }
    }

    public func asyncUpdateMetaAndPackage(listener: OPAppLoaderMetaAndPackageEvent?) {
        internalUpdateMetaAndPackage(strategy: .update, listener: listener)
    }

    public func preloadMetaAndPackage(listener: OPAppLoaderMetaAndPackageEvent?) {
        internalUpdateMetaAndPackage(strategy: .preload, listener: listener)
    }

    public func cancelLoadMetaAndPackage() {
        // 目前逻辑并没有取消，还是继续相关请求，只是UI自己不处理回调了
    }

    private var tracing: BDPTracing {
        let uniqueID = loaderContext.uniqueID
        let tracingManager = BDPTracingManager.sharedInstance()
        return tracingManager.getTracingBy(uniqueID) ?? tracingManager.generateTracing(by: uniqueID)
    }

    private func internalUpdateMetaAndPackage(strategy: OPAppLoaderStrategy, listener: OPAppLoaderMetaAndPackageEvent?) {
        let uniqueID = loaderContext.uniqueID
        //需要检查插件和宿主的订阅关系，如果不存在，不能返回缓存数据
        guard let kvStorage = (BDPModuleManager(of: .dynamicComponent).resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol)?.sharedLocalFileManager().kvStorage else {
            let error  = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "kvStorage is nil for app \(uniqueID)")
            listener?.onMetaLoadComplete(strategy: .normal, success: false, meta: nil, error: error, fromCache: false)
            return
        }
        guard let hostID = uniqueID.instanceID else {
            let error  = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "instanceID is nil for app \(uniqueID)")
            listener?.onMetaLoadComplete(strategy: .normal, success: false, meta: nil, error: error, fromCache: false)
            logger.error("[componentMeta] uniqueID: \(uniqueID), OPDynamicComponentLoader.loadMetaAndPackage with error, hostID is nil")
            return
        }
        let subscription =  kvStorage.object(forKey: OPDynamicComponentLoader.subscribeRelationshipKey) as? [String: [String]]
        //检查订阅关系，是否在宿主允许访问的动态组件列表内
        let relationshipExisted = (subscription?[hostID])?.contains(uniqueID.appID) ?? false
        getRemoteMeta(uniqueID: uniqueID, strategy: strategy, listener: listener) { [weak self] (meta) in
            guard let `self` = self else {
                logger.error("loader release for dynamic component \(uniqueID)")
                return
            }
            guard let meta = meta else {
                logger.error("meta is nil for app \(uniqueID)")
                //meta解析异常了，移除订阅关系
                var subscriptionMap = subscription ?? [:]
                var subscriptionToUpdate = subscriptionMap[hostID] ?? []
                subscriptionToUpdate.removeAll(where: { $0 == uniqueID.appID })
                subscriptionMap[hostID] = subscriptionToUpdate
                kvStorage.setObject(subscriptionMap, forKey: OPDynamicComponentLoader.subscribeRelationshipKey)
                return
            }
            //如果先前是没有订阅关系的，需要在缓存里添加订阅关系
            if !relationshipExisted {
                var subscriptionMap = subscription ?? [:]
                var subscriptionToUpdate = subscriptionMap[hostID] ?? []
                subscriptionToUpdate.append(uniqueID.appID)
                subscriptionMap[hostID] = subscriptionToUpdate
                kvStorage.setObject(subscriptionMap, forKey: OPDynamicComponentLoader.subscribeRelationshipKey)
            }
            let localVersion = try? self.metaProvider.getLocalMeta(with: uniqueID).appVersion
            logger.info("[componentMeta] update meta, uniqueId: \(meta.uniqueID), loc: \(String(describing: localVersion)), ser: \(meta.appVersion)")
            //  版本更新才需要异步更新包（之前头条还判断了version_code和md5，但是在飞书开放平台，version不一样，必定是发了个新包上去，需要下载）
            if meta.appVersion == localVersion {
                // meta更新了但是包没更新也需要持久化
                self.saveLocalMeta(meta)
                // 本地有包时，返回reader
                self.getLocalPackage(strategy: strategy, meta: meta, metaTrace: self.tracing, listener: listener)
            } else {
                // 包有更新，需要去下载
                self.getRemotePackage(strategy: strategy, meta: meta, metaTrace: self.tracing, listener: listener) {
                    self.saveLocalMeta(meta)
                    guard strategy == .update, let lst = listener as? OPDynamicComponentLoaderMetaAndPackageEvent else {
                        return
                    }
                    lst.onBundleUpdateSuccess()
                }
            }
        }
    }

    private func saveLocalMeta(_ meta: OPBizMetaProtocol) {
        logger.info("[componentMeta] uniqueID:\(meta.uniqueID) OPDynamicComponentLoader.saveLocalMeta")
        do {
            try metaProvider.saveMetaToLocal(with: loaderContext.uniqueID, meta: meta)
        } catch {
            _ = error as? OPError ?? error.newOPError(monitorCode: OPSDKMonitorCode.unknown_error)
        }
    }

    private func getRemotePackage(strategy: OPAppLoaderStrategy, meta: OPBizMetaProtocol, metaTrace: BDPTracing, listener: OPAppLoaderMetaAndPackageEvent?, successHandler: (()->Void)?) {
//        let uniqueID = loaderContext.uniqueID
        let appMeta = (meta as! OPDynamicComponentMeta).appMetaAdapter
        let downloadProgressBlock: BDPPackageDownloaderProgressBlock  = {(current, total, _) in
            listener?.onPackageLoadProgress(strategy: strategy, current: Float(current), total: Float(total))
        }
        let downloadCompletion: BDPPackageDownloaderCompletedBlock = {(error, _, reader) in
            guard error == nil , reader != nil else {
                let opError = error ?? OPSDKMonitorCode.unknown_error.error(message: "getRemotePackage failed")
                listener?.onPackageLoadComplete(strategy: strategy, success: false, error: opError)
                return
            }
            successHandler?()
            listener?.onPackageReaderReady(strategy: strategy, reader: reader as! OPPackageReaderProtocol)
            listener?.onPackageLoadComplete(strategy: strategy, success: true, error: nil)
        }
        let packageContext = BDPPackageContext(appMeta: appMeta, packageType: .pkg, packageName: nil, trace: metaTrace)
        switch strategy {
        case .preload:
            packageProvider.predownloadPackage(with: packageContext, priority: strategy.packageDownloadPriority, begun: nil, progress: downloadProgressBlock, completed: downloadCompletion)
        case .normal:
            packageProvider.normalLoadPackage(with: packageContext, priority: strategy.packageDownloadPriority, begun: nil, progress: downloadProgressBlock, completed: downloadCompletion)
        default:
            packageProvider.asyncDownloadPackage(with: packageContext, priority: strategy.packageDownloadPriority, begun: nil, progress: downloadProgressBlock, completed: downloadCompletion)
        }

    }

    private func getLocalPackage(strategy: OPAppLoaderStrategy, meta: OPBizMetaProtocol, metaTrace: BDPTracing, listener: OPAppLoaderMetaAndPackageEvent?) {
//        let uniqueID = loaderContext.uniqueID
        let appMeta = (meta as! OPDynamicComponentMeta).appMetaAdapter
        let packageContext = BDPPackageContext(appMeta: appMeta, packageType: .pkg, packageName: nil, trace: metaTrace)
        listener?.onPackageLoadStart(strategy: strategy)
        listener?.onPackageLoadProgress(strategy: strategy, current: 1.0, total: 1.0)
        // 本地有包时，返回reader
        if self.packageProvider.isLocalPackageExsit(packageContext) {
            let reader = BDPPackageManagerStrategy.packageReaderAfterDownloaded(for: packageContext)
            listener?.onPackageReaderReady(strategy: strategy, reader: reader as! OPPackageReaderProtocol)
            listener?.onPackageLoadComplete(strategy: strategy, success: true, error: nil)
        } else {
            listener?.onPackageLoadComplete(strategy: strategy, success: false, error: nil)
        }
    }

    private func getRemoteMeta(uniqueID: OPAppUniqueID, strategy: OPAppLoaderStrategy, listener: OPAppLoaderMetaAndPackageEvent?, completeHandler: ((OPBizMetaProtocol?) -> Void)?) {
        /// meta started
        listener?.onMetaLoadStarted(strategy: strategy)
        metaProvider.fetchRemoteMeta(with: uniqueID, previewToken: loaderContext.previewToken, progress: { (current, total) in
            listener?.onMetaLoadProgress(strategy: strategy, current: current, total: total)
        }, completion: { (success, meta, error) in
            if success, let componentMeta = meta {
                listener?.onMetaLoadComplete(strategy: strategy, success: true, meta: componentMeta, error: nil, fromCache: false)
                completeHandler?(componentMeta)
            } else {
                completeHandler?(nil)
                listener?.onMetaLoadComplete(strategy: strategy, success: false, meta: nil, error: error, fromCache: false)
            }
        })
    }
}
