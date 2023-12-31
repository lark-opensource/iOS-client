//
//  OPBlockLoader.swift
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
import OPBlockInterface

protocol OPBlockLoaderMetaAndPackageEvent: OPAppLoaderMetaAndPackageEvent {

    /// 包更新成功
    func onBundleUpdateSuccess(info: OPBlockUpdateInfo)
}

@objc
public final class OPBlockLoader: NSObject, OPAppLoaderProtocol {

    // TODO: [lxr] 定义code后替换掉此code
//    public static let OPBlockTODOMonitorCode = OPMonitorCode(domain: "OPBlockLoader", code: -1, level: OPMonitorLevelError, message: "")

    public var loaderContext: OPAppLoaderContext

    private let packageProvider: BDPPackageModuleProtocol
    private let metaProvider: OPAppMetaRemoteAccessor & OPAppMetaLocalAccessor

    private let containerContext: OPContainerContext

    private var trace: BlockTrace {
        containerContext.blockTrace
    }

    public init?(containerContext: OPContainerContext, previewToken: String) {
        self.containerContext = containerContext
        let uniqueID = containerContext.uniqueID
        let applicationContext = containerContext.applicationContext
        let tempTrace = containerContext.blockTrace

        tempTrace.info("OPBlockLoader.init")

        guard let packageManager = BDPModuleManager(of: .block).resolveModule(with: BDPPackageModuleProtocol.self) as? BDPPackageModuleProtocol else {
            let error = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "has no pkg module manager for block for app \(uniqueID)")
            tempTrace.error("OPBlockLoader.init error: \(error.localizedDescription)")
            assertionFailure("has no pkg module manager for block for app \(uniqueID)")
            return nil
        }
        guard let blockTypeAbility = OPApplicationService.current.containerService(for: .block)?.appTypeAbility as? OPBlockTypeAbility,
              let metaManager = blockTypeAbility.generateBlockMetaProvider(containerContext: containerContext) else {
              let error = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "has no pkg meta manager for block for app \(uniqueID)")
                  tempTrace.error("OPBlockLoader.init error: \(error.localizedDescription)")
              assertionFailure("has no meta manager for block for app \(uniqueID)")
              return nil
        }
        metaProvider = metaManager
        packageProvider = packageManager
        loaderContext = OPAppLoaderContext(applicationContext: applicationContext, uniqueID: uniqueID, previewToken: previewToken)
    }

    public func loadMetaAndPackage(listener: OPAppLoaderMetaAndPackageEvent?) {
        let uniqueID = loaderContext.uniqueID
        trace.info("OPBlockLoader.loadMetaAndPackage")

        listener?.onMetaLoadStarted(strategy: .normal)
        // preview每次都获取最新的，不取本地
        if uniqueID.versionType != .preview, let localMeta = try? metaProvider.getLocalMeta(with: uniqueID) {
            trace.info("OPBlockLoader.loadMetaAndPackage not preview")
            listener?.onMetaLoadStarted(strategy: .normal)
            listener?.onMetaLoadProgress(strategy: .normal, current: 1.0, total: 1.0)
            listener?.onMetaLoadComplete(strategy: .normal, success: true, meta: localMeta, error: nil, fromCache: true)
            getRemotePackage(strategy: .normal, meta: localMeta, metaTrace: trace.bdpTracing, listener: listener, successHandler: nil)
            internalUpdateMetaAndPackage(strategy: .update, listener: listener)
        } else {
            let tempTrace = trace
            getRemoteMeta(uniqueID: uniqueID, strategy: .normal, listener: listener) { [weak self] (meta) in
                guard let `self` = self else {
                    let error = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "loader release for app \(uniqueID)")
                    tempTrace.error("OPBlockLoader.loadMetaAndPackage.getRemoteMeta error: \(error.localizedDescription)")
                    return
                }
                self.getRemotePackage(strategy: .normal, meta: meta, metaTrace: self.trace.bdpTracing, listener: listener) {[weak self] in
                    guard let `self` = self else {
                        let error = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "loader release for app \(uniqueID)")
                        tempTrace.error("OPBlockLoader.loadMetaAndPackage.getRemotePackage error: \(error.localizedDescription)")
                        return
                    }
                    self.saveLocalMeta(meta)
                }
            }
        }
    }
    
    public func packageInstalled(meta: OPBizMetaProtocol) -> Bool {
        guard let appMeta = (meta as? OPBlockMeta)?.appMetaAdapter else {
            trace.error("packageInstalled fail")
            return false
        }
        let packageContext = BDPPackageContext(appMeta: appMeta, packageType: .zip, packageName: nil, trace: self.trace.bdpTracing)
        return packageProvider.isLocalPackageExsit(packageContext)
    }

    public func asyncUpdateMetaAndPackage(listener: OPAppLoaderMetaAndPackageEvent?) {
        trace.info("OPBlockLoader.asyncUpdateMetaAndPackage")
        internalUpdateMetaAndPackage(strategy: .update, listener: listener)
    }

    public func preloadMetaAndPackage(listener: OPAppLoaderMetaAndPackageEvent?) {
        trace.info("OPBlockLoader.preloadMetaAndPackage")
        internalUpdateMetaAndPackage(strategy: .preload, listener: listener)
    }

    public func cancelLoadMetaAndPackage() {
        // 目前逻辑并没有取消，还是继续相关请求，只是UI自己不处理回调了
    }

    private func internalUpdateMetaAndPackage(strategy: OPAppLoaderStrategy, listener: OPAppLoaderMetaAndPackageEvent?) {
        trace.info("OPBlockLoader.internalUpdateMetaAndPackage")
        let uniqueID = loaderContext.uniqueID
        let tempTrace = trace
        getRemoteMeta(uniqueID: uniqueID, strategy: strategy, listener: listener) { [weak self] (meta) in
            guard let `self` = self else {
                let error = OPError.error(monitorCode: OPSDKMonitorCode.unknown_error, message: "loader release for app \(uniqueID)")
                tempTrace.error("OPBlockLoader.internalUpdateMetaAndPackage.getRemoteMeta error: \(error.localizedDescription)")
                return
            }
            let localVersion = try? self.metaProvider.getLocalMeta(with: uniqueID).appVersion
            self.trace.info("OPBlockLoader.internalUpdateMetaAndPackage.getRemoteMeta update meta loc: \(String(describing: localVersion)), ser: \(meta.appVersion)")
            //  版本更新才需要异步更新包（之前头条还判断了version_code和md5，但是在飞书开放平台，version不一样，必定是发了个新包上去，需要下载）
            if meta.appVersion == localVersion {
                self.trace.info("OPBlockLoader.internalUpdateMetaAndPackage get local package")
                // meta更新了但是包没更新也需要持久化
                self.saveLocalMeta(meta)
                // 本地有包时，返回reader
                self.getLocalPackage(strategy: strategy, meta: meta, metaTrace: self.trace.bdpTracing, listener: listener)
            } else {
                self.trace.info("OPBlockLoader.internalUpdateMetaAndPackage download remote package")
                // 包有更新，需要去下载
                self.getRemotePackage(strategy: strategy, meta: meta, metaTrace: self.trace.bdpTracing, listener: listener) {
                    self.saveLocalMeta(meta)
                    guard strategy == .update, let lst = listener as? OPBlockLoaderMetaAndPackageEvent, let blockMeta = meta as? OPBlockMeta else {
                        return
                    }
                    self.trace.info("OPBlockLoader.update type: \(String(describing: blockMeta.updateType?.rawValue)) updatedescription: \(blockMeta.updateDescription ?? "none")")
                    lst.onBundleUpdateSuccess(info: .map(updateType: blockMeta.updateType,
                                                         updateDescription: blockMeta.updateDescription))
                }
            }
        }
    }

    private func saveLocalMeta(_ meta: OPBizMetaProtocol) {
        trace.info("OPBlockLoader.saveLocalMeta")
        do {
            try metaProvider.saveMetaToLocal(with: loaderContext.uniqueID, meta: meta)
        } catch {
            let error = error as? OPError ?? error.newOPError(monitorCode: OPSDKMonitorCode.unknown_error)
            trace.error("OPBlockLoader.saveLocalMeta error: \(error.localizedDescription)")
        }
    }

    private func getRemotePackage(strategy: OPAppLoaderStrategy, meta: OPBizMetaProtocol, metaTrace: BDPTracing, listener: OPAppLoaderMetaAndPackageEvent?, successHandler: (()->Void)?) {
//        let uniqueID = loaderContext.uniqueID
        trace.info("OPBlockLoader.getRemotePackage strategy: \(strategy.rawValue) metaAppVersion: \(meta.appVersion)")
        let appMeta = (meta as! OPBlockMeta).appMetaAdapter
        let downloadProgressBlock: BDPPackageDownloaderProgressBlock  = {(current, total, _) in
            listener?.onPackageLoadProgress(strategy: strategy, current: Float(current), total: Float(total))
        }
        let downloadCompletion: BDPPackageDownloaderCompletedBlock = {(error, _, reader) in
            guard error == nil , reader != nil else {
                let opError = error ?? OPSDKMonitorCode.unknown_error.error(message: "getRemotePackage failed")
                self.trace.error("OPBlockLoader.getRemotePackage download incomplete error: \(String(describing: opError))")
                listener?.onPackageLoadComplete(strategy: strategy, success: false, error: opError)
                return
            }
            successHandler?()
            listener?.onPackageReaderReady(strategy: strategy, reader: reader as! OPPackageReaderProtocol)
            listener?.onPackageLoadComplete(strategy: strategy, success: true, error: nil)
        }
        let packageContext = BDPPackageContext(appMeta: appMeta, packageType: .zip, packageName: nil, trace: metaTrace)
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
        trace.info("OPBlockLoader.getLocalPackage strategy: \(strategy.rawValue) metaAppVersion: \(meta.appVersion)")
        let appMeta = (meta as! OPBlockMeta).appMetaAdapter
        let packageContext = BDPPackageContext(appMeta: appMeta, packageType: .zip, packageName: nil, trace: metaTrace)
        listener?.onPackageLoadStart(strategy: strategy)
        listener?.onPackageLoadProgress(strategy: strategy, current: 1.0, total: 1.0)
        // 本地有包时，返回reader
        if packageProvider.isLocalPackageExsit(packageContext) {
            trace.info("OPBlockLoader.getLocalPackage local packages exist")
            let reader = BDPPackageManagerStrategy.packageReaderAfterDownloaded(for: packageContext)
            listener?.onPackageReaderReady(strategy: strategy, reader: reader as! OPPackageReaderProtocol)
            listener?.onPackageLoadComplete(strategy: strategy, success: true, error: nil)
        } else {
            trace.info("OPBlockLoader.getLocalPackage no local packages")
            listener?.onPackageLoadComplete(strategy: strategy, success: false, error: nil)
        }
    }

    private func getRemoteMeta(uniqueID: OPAppUniqueID, strategy: OPAppLoaderStrategy, listener: OPAppLoaderMetaAndPackageEvent?, successHandler: ((OPBizMetaProtocol) -> Void)?) {
        trace.info("OPBlockLoader.getRemoteMeta strategy: \(strategy.rawValue)")
        /// meta started
        listener?.onMetaLoadStarted(strategy: strategy)
        metaProvider.fetchRemoteMeta(with: uniqueID, previewToken: loaderContext.previewToken, progress: { (current, total) in
            listener?.onMetaLoadProgress(strategy: strategy, current: current, total: total)
        }, completion: { (success, meta, error) in
            if success, let blockMeta = meta {
                self.trace.info("OPBlockLoader.getRemoteMeta success and get blockmeta")
                listener?.onMetaLoadComplete(strategy: strategy, success: true, meta: blockMeta, error: nil, fromCache: false)
                successHandler?(blockMeta)
            } else {
                self.trace.error("OPBlockLoader.getRemoteMeta fetch remote data failed error: \(error?.localizedDescription)")
                listener?.onMetaLoadComplete(strategy: strategy, success: false, meta: nil, error: error, fromCache: false)
            }
        })
    }
}
