//
//  OPWebAppLoader.swift
//  OPWebApp
//
//  Created by Nicholas Tau on 2021/11/8.
//

import Foundation
import OPSDK
import TTMicroApp
import ECOProbe
import LKCommonsLogging
import LarkSetting

private let logger = Logger.oplog(OPWebAppLoader.self)

protocol OPWebAppLoaderMetaAndPackageEvent: OPAppLoaderMetaAndPackageEvent {

    /// 包更新成功
    func onBundleUpdateSuccess()
}

/// 应用loader需要遵循的协议，后续需要补上bundlemanager
public protocol OPWebAppLoaderProtocol: AnyObject {

    /// 冷加载meta和package
    /// - Parameter listener: 事件监听者
    func loadMetaAndPackage(listener: OPAppLoaderMetaAndPackageEvent?)

    /// 异步更新meta和package
    /// - Parameter listener: 事件监听者
    func asyncUpdateMetaAndPackage(listener: OPAppLoaderMetaAndPackageEvent?)

    /// 预加载meta和package
    /// - Parameter listener: 事件监听者
    func preloadMetaAndPackage(listener: OPAppLoaderMetaAndPackageEvent?)

    /// 取消加载meta和package
    func cancelLoadMetaAndPackage()
}

class OPWebAppLoaderContext {
    let uniqueID: OPAppUniqueID
    let previewToken: String
    init(uniqueID: OPAppUniqueID, previewToken: String) {
        self.uniqueID = uniqueID
        self.previewToken = previewToken
    }
}

public final class OPWebAppLoader: NSObject, OPWebAppLoaderProtocol {

    private var loaderContext: OPWebAppLoaderContext

    private let packageProvider: BDPPackageModuleProtocol
    private let metaProvider: OPAppMetaRemoteAccessor & OPAppMetaLocalAccessor

    public init?(uniqueID: OPAppUniqueID, previewToken: String) {
        logger.info("[webApp] uniqueID: \(uniqueID) OPWebAppLoader.init")
        guard let packageManager = BDPModuleManager(of: .webApp).resolveModule(with: BDPPackageModuleProtocol.self) as? BDPPackageModuleProtocol else {
            let _ = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "has no pkg module manager for webApp for app \(uniqueID)")
            assertionFailure("has no pkg module manager for webApp for app \(uniqueID)")
            return nil
        }
        self.metaProvider = OPWebAppMetaProvider(builder: OPWebAppMetaBuilder())
        self.packageProvider = packageManager
        self.loaderContext = OPWebAppLoaderContext(uniqueID: uniqueID, previewToken: previewToken)
    }
    
    public func isLocalMetaExist() -> Bool {
        if let _ = try? metaProvider.getLocalMeta(with: self.loaderContext.uniqueID) {
            return true
        }
        return false
    }

    public func loadMetaAndPackage(listener: OPAppLoaderMetaAndPackageEvent?) {
        let uniqueID = loaderContext.uniqueID
        logger.info("[webApp] uniqueID: \(uniqueID), OPWebAppLoader.loadMetaAndPackage")
        listener?.onMetaLoadStarted(strategy: .normal)

        // 这边记录包加载时间
        if let newUpdater = OPSDKConfigProvider.silenceUpdater?(.webApp), newUpdater.enableSlienceUpdate() {
            // 新产品化止血逻辑
            newUpdater.updateAppLaunchTime(uniqueID)
        } else {
            // 原产品化止血逻辑
            OPPackageSilenceUpdateServer.shared.updateAppLaunchTime(uniqueID)
        }
        //disableMetaCacheInWebApp 为 true 的情况，直接返回 nil，不使用缓存
        var localMeta = OPSDKFeatureGating.disableMetaCacheInWebApp() ? nil : try? metaProvider.getLocalMeta(with: uniqueID)
        if let newUpdater = OPSDKConfigProvider.silenceUpdater?(.webApp), newUpdater.enableSlienceUpdate(), let webAppMeta = localMeta as? OPWebAppMeta {
            // 新产品化止血逻辑
            let canSilenceUpdate = newUpdater.canSilenceUpdate(uniqueID: uniqueID, metaAppVersion: webAppMeta.applicationVersion)
            localMeta = canSilenceUpdate ? nil : localMeta
        } else if localMeta != nil {
            // 原产品化止血逻辑
            var canSilenceUpdate = false
            if let webAppMeta = localMeta as? OPWebAppMeta {
                canSilenceUpdate = OPPackageSilenceUpdateServer.shared.canSilenceUpdate(uniqueID: uniqueID, metaAppVersion: webAppMeta.applicationVersion)
                if canSilenceUpdate {
                    localMeta = nil
                }
            } else {
                logger.info("localMeta can not covert to OPWebAppMeta")
            }
            logger.info("uniqueID: \(uniqueID) canSilenceUpdate: \(canSilenceUpdate)")
        }

        // perview每次都获取最新的，不取本地
        if uniqueID.versionType != .preview, let localMeta = localMeta {
            listener?.onMetaLoadStarted(strategy: .normal)
            listener?.onMetaLoadProgress(strategy: .normal, current: 1.0, total: 1.0)
            listener?.onMetaLoadComplete(strategy: .normal, success: true, meta: localMeta, error: nil, fromCache: true)
            getRemotePackage(strategy: .normal, meta: localMeta, metaTrace: tracing, listener: listener, successHandler: nil)
            internalUpdateMetaAndPackage(strategy: .update, listener: listener)
        } else {
            getRemoteMeta(uniqueID: uniqueID, strategy: .normal, listener: listener) { [weak self] (meta) in
                guard let `self` = self else {
                    _ = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "loader release for app \(uniqueID)")
                    return
                }
                self.getRemotePackage(strategy: .normal, meta: meta, metaTrace: self.tracing, listener: listener) {[weak self] in
                    guard let `self` = self else {
                        _ = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "loader release for app \(uniqueID)")
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
        getRemoteMeta(uniqueID: uniqueID, strategy: strategy, listener: listener) { [weak self] (meta) in
            guard let `self` = self else {
                _ = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "loader release for app \(uniqueID)")
                return
            }
            let localVersion = try? self.metaProvider.getLocalMeta(with: uniqueID).appVersion
            logger.info("[webApp] update meta, uniqueId: \(meta.uniqueID), loc: \(String(describing: localVersion)), ser: \(meta.appVersion)")
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
                    guard strategy == .update, let lst = listener as? OPWebAppLoaderMetaAndPackageEvent else {
                        return
                    }
                    lst.onBundleUpdateSuccess()
                }
            }
        }
    }

    private func saveLocalMeta(_ meta: OPBizMetaProtocol) {
        logger.info("[webApp] uniqueID:\(meta.uniqueID) OPWebAppLoader.saveLocalMeta")
        do {
            try metaProvider.saveMetaToLocal(with: loaderContext.uniqueID, meta: meta)
        } catch {
            _ = error as? OPError ?? error.newOPError(monitorCode: OPSDKMonitorCode.unknown_error)
        }
    }

    private func getRemotePackage(strategy: OPAppLoaderStrategy, meta: OPBizMetaProtocol, metaTrace: BDPTracing, listener: OPAppLoaderMetaAndPackageEvent?, successHandler: (()->Void)?) {
//        let uniqueID = loaderContext.uniqueID
        let appMeta = (meta as! OPWebAppMeta).appMetaAdapter
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
        let offlineEnable = (meta as? OPWebAppMeta)?.extConfig.offlineEnable ?? false
        //在线模式且离线包本身只支持在线时，不需要走下包逻辑。但允许单独存meta
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webapp.update.pushcommand.enable")) {
            // 支持在线应用push命令更新后只需要判断offlineEnable即可。后续全量后干掉supportOnline这个特殊逻辑
            if !offlineEnable {
                logger.info("[webApp] uniqueID: \(loaderContext.uniqueID), supportOnline callback, package download should not start")
                successHandler?()
                listener?.onPackageLoadComplete(strategy: strategy, success: true, error: nil)
                return
            }
        } else {
            if loaderContext.uniqueID.supportOnline &&
                !offlineEnable {
                logger.info("[webApp] uniqueID: \(loaderContext.uniqueID), supportOnline callback, package download should not start")
                successHandler?()
                listener?.onPackageLoadComplete(strategy: strategy, success: true, error: nil)
                return
            }
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
        let appMeta = (meta as! OPWebAppMeta).appMetaAdapter
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

    private func getRemoteMeta(uniqueID: OPAppUniqueID, strategy: OPAppLoaderStrategy, listener: OPAppLoaderMetaAndPackageEvent?, successHandler: ((OPBizMetaProtocol) -> Void)?) {
        /// meta started
        listener?.onMetaLoadStarted(strategy: strategy)
        metaProvider.fetchRemoteMeta(with: uniqueID, previewToken: loaderContext.previewToken, progress: { (current, total) in
            listener?.onMetaLoadProgress(strategy: strategy, current: current, total: total)
        }, completion: { (success, meta, error) in
            if success, let webAppMeta = meta {
                listener?.onMetaLoadComplete(strategy: strategy, success: true, meta: webAppMeta, error: nil, fromCache: false)
                successHandler?(webAppMeta)
            } else {
                listener?.onMetaLoadComplete(strategy: strategy, success: false, meta: nil, error: error, fromCache: false)
            }
        })
    }
}
