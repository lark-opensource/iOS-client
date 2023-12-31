//
//  PKMTriggerManager.swift
//  TTMicroApp
//
//  Created by laisanpin on 2022/12/8.
//

import Foundation
import LKCommonsLogging
import ECOProbe
import OPSDK

public final class PKMTriggerManager {
    public static let shared = PKMTriggerManager()

    static let logger = Logger.log(PKMTriggerProtocol.self, category: "PKMTriggerManager")
    // meta拉取工具
    let metaFetcher = PKMMetaFetcher()
    // pkg拉取工具
    let packageFetcher = PKMPackageFetcher()
    // 小程序启动批量拉取meta FG开关
    let gadgetLaunchBatchMetaEnable = BDPBatchMetaHelper.batchMetaConfig().enable && BDPBatchMetaHelper.batchMetaConfig().enableOnLaunchGadget

    /// 获取本地meta相关信息
    func localAppMetaInfo(with triggerParams: PKMAppTriggerParams,
                   poolManager: PKMAppPoolManagerProtocol) -> (PKMBaseMetaProtocol?, NSNumber?){

        let appPool = poolManager.appPoolWith(pkmType: triggerParams.bizType, isPreview: triggerParams.isPreview())

        let targetPage = triggerParams.strategy.extra?["pkm_startpage"] as? String
        let localMeta = findLocalLatestMetaAndInstalledWith(appPool: appPool, uniqueID: triggerParams.uniqueID, appVersion: triggerParams.appVersion, targetPage: targetPage)

        let appMeta = buildMetaModel(localMeta?.originalJSONString, metaBuilder: triggerParams.metaBuilder)

        return (appMeta, localMeta?.lastUpdateTime)
    }
    
    //找到本地已安装且版本最大的meta
    func findLocalLatestMetaAndInstalledWith(appPool: PKMAppPoolProtocol, uniqueID:PKMUniqueID, appVersion: String?, targetPage: String? = nil) -> PKMApp? {
        let localMeta = appPool.findAppWith(uniqueID: uniqueID, appVersion: appVersion)
        if let localMeta = localMeta,
           localMeta.isInstalled(targetPage: targetPage) {
            return localMeta
        }
        //如果appVersion为空，不指定版本，则找到任意版本相对较大且已安装的 meta
        if BDPIsEmptyString(appVersion) {
            //过滤一下，必须是已安装的【1.9>1.8>1.7....1.0>0.9>0.8....0.1】
            let allApps = appPool.allApps(uniqueID)[uniqueID.appID]?.filter{ $0.isInstalled(targetPage: targetPage) }
            return allApps?.first
        }
        return nil
    }

    /// 构造meta对象
    func buildMetaModel(_ metaJson: String?, metaBuilder: PKMMetaBuilderProtocol?) -> PKMBaseMetaProtocol? {
        guard let _metaJson = metaJson, let _metaBuilder = metaBuilder else {
            return nil
        }

        return _metaBuilder.buildMeta(with: _metaJson)
    }

    /// 请求远端meta信息
    func requestRemoteMeta(with triggerParams: PKMAppTriggerParams,
                           completion: PKMMetaRequestCompletion?) {
        let request = PKMMetaRequest(uniqueID: triggerParams.uniqueID, bizType: triggerParams.bizType, previewToken: triggerParams.previewToken)
        metaFetcher.fetchRemoteMeta(with: request, completion: completion)
    }

    /// 请求远端meta和pkg
    func requestMetaAndPkg(with triggerParams: PKMAppTriggerParams,
                           processCallback: PKMProcessCallback?,
                           completionCallback: PKMCompletionCallback?) {
        // 启动异步更新的时候进行批量拉取
        let loadType = triggerParams.strategy.loadType
        if gadgetLaunchBatchMetaEnable && loadType == .update {
            batchMetaAndPkg(with: triggerParams, scene: .gadgetLaunch, processCallback: processCallback, completionCallback: completionCallback)
        } else {
            requestSingleMetaAndPkg(with: triggerParams, processCallback: processCallback, completionCallback: completionCallback)
        }
    }

    /// 批量拉取Meta和pkg
    func batchMetaAndPkg(with triggerParams: PKMAppTriggerParams,
                         scene: BatchLaunchScene,
                         processCallback: PKMProcessCallback?,
                         completionCallback: PKMCompletionCallback?) {
        OPMonitor(kEventName_op_common_load_meta_start)
            .addTag(.appLoad)
            .setTriggerParams(triggerParams)
            .addCategoryValue("batch_meta", true)
            .addCategoryValue("batch_scene", scene.rawValue)
            .flush()

        let loadMetaResult = OPMonitor(kEventName_op_common_load_meta_result)
            .addTag(.appLoad)
            .setTriggerParams(triggerParams)
            .addCategoryValue("meta_cache", 0)
            .addCategoryValue("batch_meta", true)
            .addCategoryValue("batch_scene", scene.rawValue)
            .timing()

        let needBatchMetas = needBatchGadgetMetas(launchAppID: triggerParams.uniqueID.appID)

        let request = PKMMetaRequest(uniqueID: triggerParams.uniqueID, bizType: triggerParams.bizType, batchMetaParams: needBatchMetas)

        metaFetcher.batchMeta(with: request) { resultList, error in
            func failedCallback(error: PKMError) {
                let result = PKMPrepareResult(success: false, error: error)
                // 失败case下不回调processCallback, 只回调completion, 双端逻辑对齐
                completionCallback?(result, nil, triggerParams)
                loadMetaResult.setError(error.originError).setResultTypeFail().timing().flush()
                Self.logger.info("\(String.LoggerPrefix) batch meta fail: \(String(describing: error.msg))")
            }

            guard error == nil else {
                // 判断回调回来的error对象是否为PKMError, 否则构造一个PKMError对象
                let pkmError = error as? PKMError ?? PKMError(domain: .MetaError, msg: "batch meta failed", originError: error)
                failedCallback(error: pkmError)
                return
            }

            guard let resultList = resultList, resultList.contains(where: { appID, _, _ in
                appID == triggerParams.uniqueID.appID
            }) else {
                let pkmError = PKMError(domain: .MetaError, msg: "batch result not contain: \(triggerParams.uniqueID.appID)")
                failedCallback(error: pkmError)
                return
            }

            for (appID, meta, error) in resultList {
                if appID == triggerParams.uniqueID.appID {
                    if let meta = meta {
                        processCallback?(.loadMetaComplete, PKMPackageResource(meta: meta, pkgReader: nil), triggerParams)
                        self.requestRemotePackage(appMeta: meta,
                                                  metaFromCache: false,
                                                  triggerParams: triggerParams,
                                                  processCallback: processCallback,
                                                  completionCallback: completionCallback)
                        loadMetaResult.setResultTypeSuccess().timing().flush()
                    } else {
                        let pkmError = PKMError(domain: .MetaError, msg: "can not get meta for \(appID)", originError: error)
                        failedCallback(error: pkmError)
                    }
                } else {
                    if let meta = meta {
                        let newTriggerParams = PKMAppTriggerParams(uniqueID: meta.pkmID, bizeType: triggerParams.bizType, appVersion: meta.appVersion, previewToken: nil, strategy: triggerParams.strategy, metaBuilder: triggerParams.metaBuilder)
                        self.requestRemotePackage(appMeta: meta, metaFromCache: false, triggerParams: newTriggerParams, processCallback: nil, completionCallback: nil)
                    }
                }
            }
        }
    }

    /// 请求远端单个meta和pkg
    func requestSingleMetaAndPkg(with triggerParams: PKMAppTriggerParams,
                                 processCallback: PKMProcessCallback?,
                                 completionCallback: PKMCompletionCallback?) {
        OPMonitor(kEventName_op_common_load_meta_start)
            .addTag(.appLoad)
            .setTriggerParams(triggerParams)
            .flush()

        let loadMetaResult = OPMonitor(kEventName_op_common_load_meta_result)
            .addTag(.appLoad)
            .setTriggerParams(triggerParams)
            .addCategoryValue("meta_cache", 0)
            .timing()

        requestRemoteMeta(with: triggerParams) { appMeta, error in
            func failedCallback(error: PKMError) {
                let result = PKMPrepareResult(success: false, error: error)
                // 失败case下不回调processCallback, 只回调completion, 双端逻辑对齐
                completionCallback?(result, nil, triggerParams)
                loadMetaResult.setError(error.originError).setResultTypeFail().timing().flush()
            }

            guard error == nil else {
                // 判断回调回来的error对象是否为PKMError, 否则构造一个PKMError对象
                let pkmError = error as? PKMError ?? PKMError(domain: .MetaError, msg: "request remote meta fail", originError: error)
                failedCallback(error: pkmError)
                Self.logger.info("\(String.LoggerPrefix) request remote meta fail: \(String(describing: error))")
                return
            }

            guard let appMeta = appMeta else {
                let pkmError = PKMError(domain: .MetaError, msg: "remote meta is nil", originError: nil)
                failedCallback(error: pkmError)
                Self.logger.info("\(String.LoggerPrefix) request remote meta fail: meta is nil")
                return
            }

            processCallback?(.loadMetaComplete, PKMPackageResource(meta: appMeta), triggerParams)
            loadMetaResult.setResultTypeSuccess().timing().flush()

            self.requestRemotePackage(appMeta: appMeta,
                                      metaFromCache: false,
                                      triggerParams: triggerParams,
                                      processCallback: processCallback,
                                      completionCallback: completionCallback)
        }
    }

    /// 尝试请求远端meta, 如果失败了则降级使用本地meta
    func tryRequestRemote(with triggerParams: PKMAppTriggerParams,
                          localMeta: PKMBaseMetaProtocol?,
                          processCallback: PKMProcessCallback?,
                          completionCallback: PKMCompletionCallback?) {
        guard let localMeta = localMeta else {
            requestMetaAndPkg(with: triggerParams, processCallback: processCallback, completionCallback: completionCallback)
            return
        }

        requestRemoteMeta(with: triggerParams) { appMeta, error in
            guard let appMeta = appMeta else {
                self.useLocalMetaAndRequestRemote(with: triggerParams, localMeta: localMeta, processCallback: processCallback, completionCallback: completionCallback)
                return
            }

            processCallback?(.loadMetaComplete, PKMPackageResource(meta: appMeta), triggerParams)
            self.requestRemotePackage(appMeta: appMeta,
                                      metaFromCache: false,
                                      triggerParams: triggerParams,
                                      processCallback: processCallback,
                                      completionCallback: completionCallback)
        }
    }

    /// 使用本地meta然后再去异步请求远端meta
    func useLocalMetaAndRequestRemote(with triggerParams: PKMAppTriggerParams,
                                      localMeta: PKMBaseMetaProtocol?,
                                      processCallback: PKMProcessCallback?,
                                      completionCallback: PKMCompletionCallback?) {
        guard let localMeta = localMeta, !triggerParams.isPreview() else {
            requestMetaAndPkg(with: triggerParams,
                              processCallback: processCallback,
                              completionCallback: completionCallback)
            return
        }

        OPMonitor(kEventName_op_common_load_meta_start)
            .addTag(.appLoad)
            .setTriggerParams(triggerParams)
            .flush()

        processCallback?(.loadMetaComplete, PKMPackageResource(meta: localMeta, metaFromCache: true), triggerParams)

        OPMonitor(kEventName_op_common_load_meta_result)
            .addTag(.appLoad)
            .setTriggerParams(triggerParams)
            .addCategoryValue("meta_cache", 1)
            .timing()
            .setResultTypeSuccess()
            .flush()

        requestRemotePackage(appMeta: localMeta,
                             metaFromCache: true,
                             triggerParams: triggerParams,
                             processCallback: processCallback,
                             completionCallback: completionCallback)

        //延迟发起异步更新请求最新的meta和pkg
        DispatchQueue.global().asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(4)) {
            var newStrategy = triggerParams.strategy.copy()
            newStrategy.loadType = .update
            let newTriggerParam = PKMAppTriggerParams(uniqueID: triggerParams.uniqueID, bizeType: triggerParams.bizType, appVersion: triggerParams.appVersion, previewToken: triggerParams.previewToken, strategy: newStrategy, metaBuilder: triggerParams.metaBuilder)
            // 异步更新时也要回调对应的process状态
            processCallback?(.loadMetaStart, nil, newTriggerParam)
            processCallback?(.loadMetaProcess, nil, newTriggerParam)
            self.requestMetaAndPkg(with: newTriggerParam, processCallback: { prepareProgress, pkgResource, triggerParams in
                processCallback?(prepareProgress, pkgResource, triggerParams)
                if prepareProgress.process == .loadMetaComplete, let remoteMeta = pkgResource?.meta {
                    self.reportPrehandleAccuracyMonitor(with: newTriggerParam, localMeta: localMeta, remoteMeta: remoteMeta)
                }
            }, completionCallback: completionCallback)
        }
    }

    /// 请求远端pkg
    func requestRemotePackage(appMeta: PKMBaseMetaProtocol,
                              metaFromCache: Bool,
                              triggerParams: PKMAppTriggerParams,
                              processCallback: PKMProcessCallback?,
                              completionCallback: PKMCompletionCallback?) {
        guard let appMeta = appMeta as? AppMetaProtocol else {
            let result = PKMPrepareResult(success: false, error: PKMError(domain: .PkgError, msg: "cannot convert to AppMetaProtocol"))
            completionCallback?(result, nil, triggerParams)
            return
        }

        // 这边后面要根据应用形态来区分调用的接口
        requestGadgetRemotePackage(appMeta: appMeta,
                                   metaFromCache: metaFromCache,
                                   triggerParams: triggerParams,
                                   processCallback: processCallback,
                                   completionCallback: completionCallback)
    }

    /// 请求小程序的远端pkg
    func requestGadgetRemotePackage(appMeta: AppMetaProtocol,
                                    metaFromCache: Bool,
                                    triggerParams: PKMAppTriggerParams,
                                    processCallback: PKMProcessCallback?,
                                    completionCallback: PKMCompletionCallback?) {
        let trace = PKMUtil.monitorTrace(with: triggerParams.uniqueID, bizType: triggerParams.bizType, isPreivew: triggerParams.isPreview())

        let priority = triggerParams.strategy.pkgDownloadPriority

        let pkgRequest = PKMPackageRequest(appMeta: appMeta, packageType: .pkg, loadType: triggerParams.strategy.loadType, priority: priority, extra: triggerParams.strategy.extra, tarce: trace)

        OPMonitor(kEventName_op_common_load_package_start)
            .addTag(.appLoad)
            .setTriggerParams(triggerParams)
            .flush()

        let loadPkgResult = OPMonitor(kEventName_op_common_load_package_result)
            .addTag(.appLoad)
            .setTriggerParams(triggerParams)
            .timing()

        let pkmMeta = appMeta as? PKMBaseMetaProtocol

        packageFetcher.downloadPackage(with: pkgRequest) { reader in
            let progress = PKMPrepareProgress(process: .loadPkgReady)
            processCallback?(progress, PKMPackageResource(meta: pkmMeta, pkgReader: reader, metaFromCache: metaFromCache), triggerParams)
        } progress: { receive, expect, url in
            let progress = PKMPrepareProgress(process: .loadPkgProgress, pkgReceiveSize: receive, pkgExpectedSize: expect, url: url)
            processCallback?(progress, PKMPackageResource(meta: pkmMeta, pkgReader: nil, metaFromCache: metaFromCache), triggerParams)
        } complete: { error, isCancelled, reader in
            var packageCache = 0
            if let createLoadStatus = reader?.originReader?.createLoadStatus(),
                createLoadStatus.rawValue >= BDPPkgFileLoadStatus.downloaded.rawValue {
                packageCache = 1
            }

            let pkgCtx = BDPPackageContext(appMeta: appMeta, packageType: .pkg, packageName: nil, trace: trace)
            let pkgSource = PKMDiffPackageDownloader.packageSourceType(with: pkgCtx)
            loadPkgResult.addCategoryValue("package_cache", packageCache)
            loadPkgResult.addCategoryValue("package_source", pkgSource.rawValue)
            guard error == nil, reader?.originReader != nil else {
                loadPkgResult.setError(error).timing().setResultTypeFail().flush()
                let pkgError = PKMError(domain: .PkgError, msg: "package donwload failed", originError: error)
                let result = PKMPrepareResult(success: false, error: pkgError)
                completionCallback?(result, PKMPackageResource(meta: pkmMeta, pkgReader: nil, metaFromCache: metaFromCache), triggerParams)
                Self.logger.info(logId: "\(String.LoggerPrefix) package donwload failed: \(String(describing: error)) or reader is nil")
                return
            }
            let result = PKMPrepareResult(success: true, error: nil)
            processCallback?(PKMPrepareProgress(process: .loadPkgComplete), PKMPackageResource(meta: pkmMeta, pkgReader: reader, metaFromCache: metaFromCache), triggerParams)
            completionCallback?(result, PKMPackageResource(meta: pkmMeta, pkgReader: reader, metaFromCache: metaFromCache), triggerParams)
            loadPkgResult.setResultTypeSuccess().timing().flush()
        }
    }

    func needBatchGadgetMetas(launchAppID: String) -> [String : String] {
        var params = [String : String]()

        // 获取定制化小程序appIDs
        let prehandleCustomizeConfig = BDPPreloadHelper.prehandleCustomizeConfig()
        if prehandleCustomizeConfig.enable {
            let prehandleCustomizeAppIDs = prehandleCustomizeConfig.customizePrehandleAppIDs
            Self.logger.info("[PreloadSettings] gadgetLaunch batch customs: \(prehandleCustomizeAppIDs)")
            prehandleCustomizeAppIDs.forEach {
                params[$0] = ""
            }
        }

        let appPool = PKMAppPoolManager.sharedInstance.appPoolWith(pkmType: .gadget)
        // 获取最近常用小程序,以进行批量meta拉取
        LaunchInfoAccessorFactory.launchInfoAccessor(type: .gadget)?.queryTop(most: BDPPreloadHelper.clientStrategySingleMaxCount(), beforeDays: BDPPreloadHelper.clientStrategyBeforeDays()).forEach({
            let appInfo = findLocalLatestMetaAndInstalledWith(appPool: appPool, uniqueID: PKMUniqueID(appID: $0, identifier: nil), appVersion: nil)
            params[$0] = appInfo?.appVersion ?? ""
        })

        // 批量请求的meta需要去除当前启动小程序
        params.removeValue(forKey: launchAppID)

        return params
    }
}

extension PKMTriggerManager: PKMTriggerProtocol {
    public func triggerOpenAppUpdate(with triggerParams: PKMAppTriggerParams,
                                     processCallback: PKMProcessCallback?,
                                     completionCallback: PKMCompletionCallback?) {
        processCallback?(.loadMetaStart, nil, triggerParams)

        let (localMeta, lastUpdateTime) = localAppMetaInfo(with: triggerParams, poolManager: PKMAppPoolManager.sharedInstance)

        let triggerStrategy = triggerParams.strategy

        let updateStrategy = triggerStrategy.updateStrategy(PKMTriggerStrategyContext(localMeta: localMeta, timestamp: lastUpdateTime), beforeInvoke: nil)

        Self.logger.info("\(String.LoggerPrefix) trigger with uniqueID: \(triggerParams.uniqueID), bizType: \(triggerParams.bizType.toString()), appVersion: \(String(describing: triggerParams.appVersion)), isPreview: \(triggerParams.isPreview()), updateStrategy:\(updateStrategy.rawValue)")

        processCallback?(.loadMetaProcess, nil, triggerParams)

        switch updateStrategy {
        case .forceRemote:
            requestMetaAndPkg(with: triggerParams, processCallback: processCallback, completionCallback: completionCallback)
        case .tryRemote:
            tryRequestRemote(with: triggerParams, localMeta: localMeta, processCallback: processCallback, completionCallback: completionCallback)
        case .useLocal:
            useLocalMetaAndRequestRemote(with: triggerParams, localMeta: localMeta, processCallback: processCallback, completionCallback: completionCallback)
        }
    }
}

extension PKMTriggerManager {
    func reportPrehandleAccuracyMonitor(with triggerParams: PKMAppTriggerParams,
                                        localMeta: PKMBaseMetaProtocol,
                                        remoteMeta: PKMBaseMetaProtocol) {
        guard let pkgMeta = localMeta as? PKMBaseMetaPkgProtocol, let readType = packageFetcher.packageReadTypes(with: triggerParams.uniqueID, bizType: triggerParams.bizType, pkgName: pkgMeta.packageName())?.first else {
            Self.logger.warn("\(String.LoggerPrefix) meta not PKMBaseMetaPkgProtocol or readType is invalid")
            return
        }

        let prehandleInfo = packageFetcher.prehandeInfo(with: triggerParams.uniqueID, bizType: triggerParams.bizType, pkgName: pkgMeta.packageName())
        let prehandleSceneName = prehandleInfo.0
        let preUpdatePullType = prehandleInfo.1

        let prehandleEffective = localMeta.appVersion == remoteMeta.appVersion
        OPMonitor(EPMClientOpenPlatformGadgetPrehandleCode.op_prehandle_accuracy)
            .setTriggerParams(triggerParams)
            .addMap(["cache_version" : localMeta.appVersion,
                     "async_version" : remoteMeta.appVersion,
                     "prehandle_effective" : prehandleEffective ? 1 : 0,
                     "package_type" : BDPPkgFileReadTypeInfo(BDPPkgFileReadType(rawValue: readType.intValue) ?? BDPPkgFileReadType.unknown),
                     "prehandle_scene" : prehandleSceneName,
                     "pull_type" : preUpdatePullType
                    ])
            .flush()
    }
}

extension PKMPrepareProgress {
    static let loadMetaStart = PKMPrepareProgress(process: .loadMetaStart)
    static let loadMetaProcess = PKMPrepareProgress(process: .loadMetaProcess)
    static let loadMetaComplete = PKMPrepareProgress(process: .loadMetaComplete)
}

fileprivate extension String {
    static let LoggerPrefix = "[PKMTriggerManager]"
}

fileprivate extension OPMonitor {
    func setTriggerParams(_ triggerParams: PKMAppTriggerParams) -> OPMonitor {
        let loadType = triggerParams.strategy.loadType
        addCategoryValue(kEventKey_load_type, loadType.toString())
        addCategoryValue("usePKM", true)

        let bdpUniqueID = PKMUtil.configBDPUniqueID(triggerParams.uniqueID, appType: triggerParams.bizType, isPreview: triggerParams.isPreview())
        setUniqueID(bdpUniqueID)
        return self
    }
}

