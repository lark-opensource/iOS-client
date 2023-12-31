//
//  EMAAppPreUpdateManager.swift
//  EEMicroAppSDK
//
//  Created by laisanpin on 2022/8/3.
//  预安装重构-预安装

import Foundation
import LKCommonsLogging
import ECOProbe
import OPSDK
import OPWebApp
import ECOProbeMeta
import OPGadget
import OPFoundation

/// 预拉策略细分枚举
enum EMAPreUpdatePullStrategyReason: Int {
    // 未知情况
    case unknown = -1
    // 预拉取策略为本地策略
    case client = 0
    // 预拉取策略为服务端push
    // Note:这个case iOS不会有. Android在Push的方法中进行了上报, 这是不符合预期的, 因为这个点是针对'预拉'场景
    case server_push = 1
    // 预拉取策略为服务端策略
    // Note:这个case iOS不会有. Android这个case是H5上报的, 这是不符合预期的, 因为这个点是针对小程序预拉的业务场景
    case server_pull_default = 2
    // 预拉取策略为服务端策略(前提是客户端策略FG关闭)
    case server_disable_client = 3
    // 预拉取策略为服务端策略(前提是先走了本地策略, 但是本地策略数据不足降级走了服务端策略)
    case server_pull_less_client_min_count = 4
    // 预拉策略为从settings中读取的定制化数据
    case settings_customize = 5
}

/// 小程序预安装工具类(线程安全)
@objcMembers
final class EMAGadgetPreUpdateManager: EMAAppPreUpdateManager, EMAPackagePreInfoProvider {
    // 最近获取预安装信息时间
    private var lastCheckUpdateTaskTime: TimeInterval = 0

    private lazy var batchGadgetLoader = {
        OPGadgetLoader()
    }()

    // meta读写所
    private lazy var batchMetaLock = {
        NSLock()
    }()

    // 批量拉取meta Map表
    private lazy var batchMetaInfoMap = {
        [String : OPBizMetaProtocol]()
    }()

    public init() {
        super.init(appType: .gadget)
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: BDPNetworking.reachabilityChangedNotification(), object: nil)
    }

    /// 拉取预安装配置信息
    public func fetchPreUpdateSettings() {
        // 这边延迟拉取, 防止启动过程中资源占用
        requestAppUpdateInfoDelay(Int(BDPPreloadHelper.checkDelayAfterLaunch()))
    }

    /// 预安装推送 item数据结构:["appID" : "xxxx","latency" : @(10), "extraJson" : "xxx"]
    public func pushPreUpdateSettings(_ item: Any) {
        self.workQueue.async {
            guard let pushInfo = item as? [String: Any],
                  let updateInfo = self.configAppUpdateInfo(pushInfo) else {
                Self.logger.warn("\(String.GadgetUpdateTag) invalid push info")
                return
            }

            let extensionUpdateInfoArray = self.extensionAppUpdateInfoArray([updateInfo])

            let preloadHandleInfoArray = self.configPreloadHandlerArray(extensionUpdateInfoArray.filter {
                $0.ext_type == String.Gadget
            }, scene: BDPPreloadScene.PreloadPush, listener: self, injector: self)

            Self.logger.info("\(String.GadgetUpdateTag) start fetch \(preloadHandleInfoArray.count) update info from push")

            BDPPreloadHandlerManager.sharedInstance.handlePkgPreloadEvent(preloadInfoList: preloadHandleInfoArray)
        }
    }

    private func gadgetRequestAppInfoArray(_ gadgetMetas: [AppMetaProtocol]) -> [[String : String]] {
        var requestAppInfo = [[String : String]]()
        for meta in gadgetMetas {
            if let gadgetMeta = meta as? GadgetMeta {
                requestAppInfo.append(["app_id" : BDPSafeString(gadgetMeta.uniqueID.appID),
                                       "app_version" : BDPSafeString(gadgetMeta.appVersion)])
            }
        }

        // 原逻辑: 限制请求数量
        if requestAppInfo.count > Int.MaxCountPerRequest {
            requestAppInfo = Array(requestAppInfo.prefix(Int.MaxCountPerRequest))
        }

        return requestAppInfo
    }

    @objc func reachabilityChanged()  {
        self.workQueue.async {
            let minTimeSinceLastCheck = BDPPreloadHelper.minTimeSinceLastCheck()
            guard Date().timeIntervalSince1970 - self.lastCheckUpdateTaskTime > minTimeSinceLastCheck else {
                Self.logger.info("\(String.GadgetUpdateTag) network change check too often")
                return
            }

            guard BDPCurrentNetworkType() == String.Wifi else {
                Self.logger.info("\(String.GadgetUpdateTag) network changed,but isn't wifi")
                return
            }

            let checkDelay = BDPPreloadHelper.networkChangeCheckDelay()

            self.workQueue.asyncAfter(deadline: .now() + .seconds(Int(checkDelay))) {
                Self.logger.info("\(String.GadgetUpdateTag) network change, request app update info")
                //不延迟,直接请求预安装信息
                self.requestAppUpdateInfoDelay(0)
            }
        }
    }

    /// 延迟请求预安装信息
    private func requestAppUpdateInfoDelay(_ second: Int) {
        self.workQueue.asyncAfter(deadline: .now() + .seconds(second)) {
            guard EMAAppEngine.current()?.account?.accountToken != nil else {
                Self.logger.warn("\(String.WebAppUpdateTag) EMAAppEngine not ready")
                return
            }

            // 判断是否需要拉取预安装信息(方法内部已经打印日志)
            guard self.checkIfNeedFetchInfo() else {
                return
            }

            guard self.fetchUpdateInfoIsFinish else {
                Self.logger.warn("\(String.GadgetUpdateTag) last fetch is not finish")
                return
            }

            self.fetchUpdateInfoIsFinish = false

            // 更新检查时间
            self.lastCheckUpdateTaskTime = Date().timeIntervalSince1970

            // 原逻辑-删除本地过期包
            BDPAppLoadManager.shareService().deleteExpiredPkg()

            // 根据开关决定走本地策略还是服务端策略
            if BDPPreloadHelper.clientStrategyEnable() {
                self.localFetchAppUpdateInfo()
            } else {
                self.remoteFetchAppUpdateInfo(pullStrategyReason: .server_disable_client)
            }
        }
    }

    /// 获取配置在settings中的定制化数据
    func customizePrehandleInfos() -> [BDPPreloadHandleInfo] {
        let prehandleCustomizeConfig = BDPPreloadHelper.prehandleCustomizeConfig()
        guard prehandleCustomizeConfig.enable else {
            Self.logger.info("\(String.GadgetUpdateTag) [PreloadSettings] fetch customize not enable")
            return []
        }

        let appIDArray = prehandleCustomizeConfig.customizePrehandleAppIDs

        Self.logger.info("\(String.GadgetUpdateTag) [PreloadSettings] start prehandle: \(appIDArray)")

        let preloadHandleInfoArray = appIDArray.map {
            BDPPreloadHandleInfo(uniqueID: OPAppUniqueID(appID: $0, identifier: nil, versionType: .current, appType: .gadget), scene: BDPPreloadScene.PreloadPull, scheduleType: .toBeScheduled, extra: [String.PreUpdatePullType : BDPPrehandleDataSource.settings.rawValue], listener: self, injector: self)
        }

        preloadHandleInfoArray.forEach {
            self.reportPullMonitor($0.uniqueID, pullType: .settings, pullStrategyReason: .settings_customize)
        }

        return preloadHandleInfoArray
    }

    // 根据本地数据来进行预拉
    private func localFetchAppUpdateInfo() {
        guard let appIDArray = LaunchInfoAccessorFactory.launchInfoAccessor(type: .gadget)?.queryTop(most: BDPPreloadHelper.clientStrategySingleMaxCount(), beforeDays: BDPPreloadHelper.clientStrategyBeforeDays()),
            appIDArray.count >= BDPPreloadHelper.clientStrategyMinAppCount() else {
            Self.logger.info("\(String.GadgetUpdateTag) local data not enough, request remote")
            remoteFetchAppUpdateInfo(pullStrategyReason: .server_pull_less_client_min_count)
            return
        }

        Self.logger.info("\(String.GadgetUpdateTag) start update \(appIDArray) info from local")

        let preloadHandleInfoArray = appIDArray.map {
            BDPPreloadHandleInfo(uniqueID: OPAppUniqueID(appID: $0, identifier: nil, versionType: .current, appType: .gadget), scene: BDPPreloadScene.PreloadPull, scheduleType: .toBeScheduled, extra: [String.PreUpdatePullType : BDPPrehandleDataSource.local.rawValue], listener: self, injector: self)
        }

        // 是否需要批量拉取meta
        startPrehandle(preloadHandleInfoArray)

        self.fetchUpdateInfoIsFinish = true

        self.updateLastPullTime()

        preloadHandleInfoArray.forEach {
            self.reportPullMonitor($0.uniqueID, pullType: .local, pullStrategyReason: .client)
        }
    }

    // 根据服务端数据进行预拉
    private func remoteFetchAppUpdateInfo(pullStrategyReason: EMAPreUpdatePullStrategyReason) {
        // 小程序应用的请求信息
        let gadgetMetas = MetaLocalAccessorBridge.getAllMetas(appType: .gadget)
        let requestAppInfo = self.gadgetRequestAppInfoArray(gadgetMetas)

        let params = ["app_info_list" : requestAppInfo]

        Self.logger.info("\(String.GadgetUpdateTag) start fetch \(requestAppInfo.count) update info from pull")

        self.requestAppUpdateInfo(params) {[weak self] result in
            guard let `self` = self else {
                Self.logger.error("\(String.GadgetUpdateTag) self is nil")
                return
            }

            self.fetchUpdateInfoIsFinish = true

            switch result {
            case .success(let appUpdateInfoArray):
                let preloadHandleInfoArray = appUpdateInfoArray.filter {
                    // 过滤出是小程序的数据
                    $0.ext_type == String.Gadget
                }.map {
                    BDPPreloadHandleInfo(uniqueID: $0.uniqueID(),
                                         scene: BDPPreloadScene.PreloadPull,
                                         scheduleType: .toBeScheduled,
                                         extra: [String.ApplicationVersion : $0.app_version,
                                                 String.PreUpdatePullType : BDPPrehandleDataSource.sever.rawValue],
                                         listener: self,
                                         injector: self)
                }

                Self.logger.info("\(String.GadgetUpdateTag) preloadHandleInfoArray count: \(preloadHandleInfoArray.count)")

                // 开始预拉取
                self.startPrehandle(preloadHandleInfoArray)

                // 更新最近一次配置拉取成功时间
                self.updateLastPullTime()

                preloadHandleInfoArray.forEach {
                    self.reportPullMonitor($0.uniqueID, pullType: .sever, pullStrategyReason: pullStrategyReason)
                }
            case .failure(let error):
                Self.logger.warn(String.GadgetUpdateTag + error.errorMsg)
            }
        }
    }

    /// 开始进行预处理
    func startPrehandle(_ preloadHandleInfos: [BDPPreloadHandleInfo]) {
        // 获取配置在settings上的定制化应用预安装信息
        let customizePrehandleInfos = customizePrehandleInfos()
        // 组合成最终需要预拉的数组
        let needPrehandleInfos = customizePrehandleInfos + preloadHandleInfos

        guard !needPrehandleInfos.isEmpty else {
            Self.logger.info("\(String.GadgetUpdateTag) need prehandleInfos is empty")
            return
        }

        if BDPBatchMetaHelper.batchMetaConfig().enable {
            let appIDArray = needPrehandleInfos.map {
                return BDPSafeString($0.uniqueID.appID)
            }.removeDuplicateElements()

            // 这边批量请求meta后会将meta信息缓存下来,BDPPreloadHandlerManager会询问是否注入meta.
            // 届时会将批量拉取的meta注入到BDPPreloadHandlerManager中
            batchMeta(appIDArray: appIDArray) { _ in
                BDPPreloadHandlerManager.sharedInstance.handlePkgPreloadEvent(preloadInfoList: needPrehandleInfos)
            }
        } else {
            BDPPreloadHandlerManager.sharedInstance.handlePkgPreloadEvent(preloadInfoList: needPrehandleInfos)
        }
    }

    /// 更新最近一次配置拉取成功时间
    func updateLastPullTime() {
        let time = NSNumber(value: Date().timeIntervalSince1970)
        self.kvStorage()?.setObject(time, forKey: String.LastUpdateTime)
    }

    /// 批量拉取meta
    /// - Parameters:
    ///   - appIDArray: appID数组
    ///   - nextStep: 下一步任务
    private func batchMeta(appIDArray: [String], nextStep: @escaping (_ batchSuccess: Bool) -> Void) {
        var requestMetaMap = [String : String]()
        appIDArray.forEach {
            requestMetaMap[$0] = ""
        }

        Self.logger.info("\(String.GadgetUpdateTag) batch meta \(appIDArray) count: \(appIDArray.count)")

        self.batchGadgetLoader.batchRemoteMetaWith(requestMetaMap, strategy: .preload) {[weak self] resultList, error in
            guard let `self` = self else {
                Self.logger.error("\(String.GadgetUpdateTag) self is nil")
                nextStep(false)
                return
            }

            if let _error = error {
                Self.logger.error("\(String.GadgetUpdateTag) batch meta error: \(_error)")
                nextStep(false)
                return
            }

            guard let resultList = resultList else {
                Self.logger.error("\(String.GadgetUpdateTag) resultList is nil")
                nextStep(false)
                return
            }

            Self.logger.info("\(String.GadgetUpdateTag) batch meta success, meta count: \(resultList.count)")
            self.batchMetaLock.lock()
            self.batchMetaInfoMap.removeAll()
            for (appID, meta, _) in resultList {
                if let gadgetMeta = meta as? OPBizMetaProtocol {
                    self.batchMetaInfoMap[appID] = gadgetMeta
                }
            }
            self.batchMetaLock.unlock()

            nextStep(true)
        }
    }

    // 预拉取数据埋点上报
    private func reportPullMonitor(_ uniqueID: OPAppUniqueID,
                                   pullType: BDPPrehandleDataSource,
                                   pullStrategyReason: EMAPreUpdatePullStrategyReason) {
        OPMonitor(EPMClientOpenPlatformGadgetPrehandleCode.op_prehandle_preupdate_start)
            .addMap(["app_type" : OPAppTypeToString(uniqueID.appType),
                     "app_id" : BDPSafeString(uniqueID.appID),
                     "pull_type" : pullType.rawValue,
                     "pull_time" : Date().timeIntervalSince1970 * 1000,
                     "strategy_reason": pullStrategyReason.rawValue])
            .setUniqueID(uniqueID)
            .flush()
    }
}

extension EMAGadgetPreUpdateManager: BDPPreloadHandleListener, BDPPreloadHandleInjector {
    public func onPackageResult(success: Bool, handleInfo: BDPPreloadHandleInfo, error: OPError?) {
        guard success else {
            return
        }
        // 逻辑与Android对齐. 成功了记录一下次数
        let times = self.todayDownloadTimes()
        self.updateTodayDownloadTimes(times + 1)
    }

    public func onInjectInterceptor(scene: BDPPreloadScene,  handleInfo: BDPPreloadHandleInfo) -> [BDPPreHandleInterceptor]? {
        let commonInterceptor = self.commonInterceptorArray()

        // 应用版本拦截
        let appVersionInterceptor = {(info: BDPPreloadHandleInfo) -> BDPInterceptorResponse in
            if info.uniqueID.appType == .gadget {
                guard let updateInfoAppVersion = info.extra?[String.ApplicationVersion] as? String else {
                    // 没有传入应用版本则不拦截
                    Self.logger.warn("\(String.GadgetUpdateTag) cannot get updateInfoAppVersion from extra \(BDPSafeString(info.uniqueID.appID))")
                    return BDPInterceptorResponse(intercepted: false)
                }

                guard let gadgetMeta = MetaLocalAccessorBridge.getMetaWithUniqueId(uniqueID: info.uniqueID) as? GadgetMeta else {
                    Self.logger.warn("\(String.GadgetUpdateTag) cannot get gadget meta: \(BDPSafeString(info.uniqueID.appID))")
                    // 如果没有本地meta, 则不拦截
                    return BDPInterceptorResponse(intercepted: false)
                }

                guard !updateInfoAppVersion.isEmpty, !gadgetMeta.appVersion.isEmpty else {
                    Self.logger.warn("\(String.GadgetUpdateTag) applicationVersion or meta appVersion is empty")
                    //如果有一个版本为空字符串, 则不拦截
                    return BDPInterceptorResponse(intercepted: false)
                }

                let result = BDPVersionManager.compareVersion(updateInfoAppVersion, with: gadgetMeta.appVersion)
                let needIntercept = result != 1
                return BDPInterceptorResponse(intercepted: needIntercept, interceptedType: .cached)
            } else {
                // 预期外的类型则进行拦截
                Self.logger.error("\(String.GadgetUpdateTag) unexpected appType: \(info.uniqueID.appType), appID: \(info.uniqueID.appID)")
                return BDPInterceptorResponse(intercepted: true, interceptedType: .error, interceptedMsg: "unexpected appType: \(info.uniqueID.appType), appID: \(info.uniqueID.appID)")
            }
        }

        let interceptorArray = commonInterceptor + [appVersionInterceptor]

        return interceptorArray
    }

    public func onInjectMeta(uniqueID: OPAppUniqueID, handleInfo: BDPPreloadHandleInfo) -> OPBizMetaProtocol? {
        self.batchMetaLock.lock()
        let meta = self.batchMetaInfoMap[BDPSafeString(uniqueID.appID)]
        self.batchMetaLock.unlock()
        return meta
    }
}

/// H5离线应用预安装工具类(线程安全)
@objcMembers
final class EMAWebAppPreUpdateManager: EMAAppPreUpdateManager, EMAPackagePreInfoProvider {
    // 最近获取预安装信息时间
    private var lastCheckUpdateTaskTime: TimeInterval = 0

    private let webAppMetaProvider = OPWebAppMetaProvider()

    public init() {
        super.init(appType: .webApp)
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: BDPNetworking.reachabilityChangedNotification(), object: nil)
    }
    /// 拉取预安装配置信息
    public func fetchPreUpdateSettings() {
        self.requestAppUpdateInfoDelay(Int(BDPPreloadHelper.checkDelayAfterLaunch()))
    }

    /// 预安装推送 item数据结构:["appID" : "xxxx","latency" : @(10), "extraJson" : "xxx"]
    public func pushPreUpdateSettings(_ item: Any) {
        self.workQueue.async {
            guard let pushInfo = item as? [String : Any],
                  let updateInfo = self.configAppUpdateInfo(pushInfo) else {
                Self.logger.warn("\(String.WebAppUpdateTag) invalid push info")
                return
            }

            let extensionUpdateInfoArray = self.extensionAppUpdateInfoArray([updateInfo])

            let preloadHandleInfoArray = self.configPreloadHandlerArray(extensionUpdateInfoArray.filter {
                $0.ext_type == String.WebOffline
            }, scene: BDPPreloadScene.PreloadPush, listener: self, injector: self)

            Self.logger.info("\(String.WebAppUpdateTag) start fetch \(preloadHandleInfoArray.count) update info from push")

            BDPPreloadHandlerManager.sharedInstance.handlePkgPreloadEvent(preloadInfoList: preloadHandleInfoArray)
        }
    }

    private func webAppRequestAppInfoArray(_ webAppMetas: [OPBizMetaProtocol]) -> [[String : String]] {
        var requestAppInfo = webAppMetas.map {
            ["app_id" : BDPSafeString($0.uniqueID.appID),
             "app_version" : BDPSafeString($0.applicationVersion)]
        }

        // 原逻辑: 限制请求数量
        if requestAppInfo.count > Int.MaxCountPerRequest {
            requestAppInfo = Array(requestAppInfo.prefix(Int.MaxCountPerRequest))
        }

        return requestAppInfo
    }
    
    @objc func reachabilityChanged()  {
        self.workQueue.async {
            let minTimeSinceLastCheck = BDPPreloadHelper.minTimeSinceLastCheck()
            guard Date().timeIntervalSince1970 - self.lastCheckUpdateTaskTime > minTimeSinceLastCheck else {
                Self.logger.info("\(String.WebAppUpdateTag) network change check too often")
                return
            }

            guard BDPCurrentNetworkType() == String.Wifi else {
                Self.logger.info("\(String.WebAppUpdateTag) network changed,but isn't wifi")
                return
            }

            let checkDelay = BDPPreloadHelper.networkChangeCheckDelay()

            self.workQueue.asyncAfter(deadline: .now() + .seconds(Int(checkDelay))) {
                Self.logger.info("\(String.WebAppUpdateTag) network change, request app update info")
                self.requestAppUpdateInfoDelay(0)
            }
        }
    }

    private func requestAppUpdateInfoDelay(_ second: Int) {
        self.workQueue.asyncAfter(deadline: .now() + .seconds(second)) {
            guard EMAAppEngine.current()?.account?.accountToken != nil else {
                Self.logger.warn("\(String.WebAppUpdateTag) EMAAppEngine not ready")
                return
            }

            // 判断是否需要拉取预安装信息(方法内部已经打印日志)
            guard self.checkIfNeedFetchInfo() else {
                return
            }

            guard self.fetchUpdateInfoIsFinish else {
                Self.logger.warn("\(String.WebAppUpdateTag) last fetch is not finish")
                return
            }

            self.fetchUpdateInfoIsFinish = false

            let allOfflineH5Metas = self.webAppMetaProvider.getAllOfflineH5Metas()
            //应用数据为空，直接return
            if allOfflineH5Metas.count < 1 {
                Self.logger.warn("requestAppUpdateInfoDelay allOfflineH5Metas is empty, should return")
                return
            }

            // webApp的请求信息
            let requestAppInfo = self.webAppRequestAppInfoArray(allOfflineH5Metas)

            Self.logger.info("\(String.WebAppUpdateTag) start fetch \(requestAppInfo.count) update info from pull")

            let params = ["app_info_list" : requestAppInfo]

            self.requestAppUpdateInfo(params) { [weak self] result in
                guard let `self` = self else {
                    Self.logger.error("\(String.WebAppUpdateTag) self is nil")
                    return
                }

                self.fetchUpdateInfoIsFinish = true
                self.lastCheckUpdateTaskTime = Date().timeIntervalSince1970

                switch result {
                case .success(let appUpdateInfoArray):
                    let preloadHandleInfoArray = self.configPreloadHandlerArray(appUpdateInfoArray.filter {
                        // 过滤出是H5离线应用的数据
                        $0.ext_type == String.WebOffline
                    }, scene: BDPPreloadScene.PreloadPull, listener: self, injector: self)

                    Self.logger.info("\(String.WebAppUpdateTag) start preload \(preloadHandleInfoArray.count) from preUpdate pull")

                    BDPPreloadHandlerManager.sharedInstance.handlePkgPreloadEvent(preloadInfoList: preloadHandleInfoArray)

                    // 更新最近一次配置拉取成功时间
                    let time = NSNumber(value: Date().timeIntervalSince1970)
                    self.kvStorage()?.setObject(time, forKey: String.LastUpdateTime)
                case .failure(let error):
                    Self.logger.warn(String.WebAppUpdateTag + error.errorMsg)
                }
            }
        }
    }
}

extension EMAWebAppPreUpdateManager: BDPPreloadHandleListener, BDPPreloadHandleInjector {
    public func onPackageResult(success: Bool,handleInfo: BDPPreloadHandleInfo, error: OPError?) {
        guard success else {
            return
        }
        // 逻辑与Android对齐. 成功了记录一下次数
        let times = self.todayDownloadTimes()
        self.updateTodayDownloadTimes(times + 1)
    }

    public func onInjectInterceptor(scene: BDPPreloadScene,  handleInfo: BDPPreloadHandleInfo) -> [BDPPreHandleInterceptor]? {
        let commonInterceptor = self.commonInterceptorArray()
        // 应用版本拦截
        let appVersionInterceptor = {[weak self] (info: BDPPreloadHandleInfo) -> BDPInterceptorResponse in
            guard let `self` = self else {
                Self.logger.error("\(String.WebAppUpdateTag) self is nil, donot intercept")
                return BDPInterceptorResponse(intercepted: false)
            }

            if info.uniqueID.appType == .webApp {
                guard let updateInfoAppVersion = info.extra?[String.ApplicationVersion] as? String else {
                    // 没有传入应用版本则不拦截
                    Self.logger.warn("\(String.WebAppUpdateTag) cannot get updateInfoAppVersion from extra \(BDPSafeString(info.uniqueID.appID))")
                    return BDPInterceptorResponse(intercepted: false)
                }

                do {
                    let webMeta = try self.webAppMetaProvider.getLocalMeta(with: info.uniqueID)

                    guard !updateInfoAppVersion.isEmpty, !webMeta.applicationVersion.isEmpty else {
                        Self.logger.warn("\(String.WebAppUpdateTag) applicationVersion or meta application is empty")
                        return BDPInterceptorResponse(intercepted: false)
                    }

                    let result = BDPVersionManager.compareVersion(updateInfoAppVersion, with: webMeta.applicationVersion)
                    let needIntercept = result != 1
                    return BDPInterceptorResponse(intercepted: needIntercept, interceptedType: .cached)
                } catch {
                    Self.logger.warn("\(String.WebAppUpdateTag) cannot get web meta: \(BDPSafeString(info.uniqueID.appID)), error: \(String(describing: error))")
                    // 本地如果没有meta, 则不拦截
                    return BDPInterceptorResponse(intercepted: false)
                }
            } else {
                Self.logger.error("\(String.WebAppUpdateTag) unexpected appType: \(info.uniqueID.appType), appID: \(info.uniqueID.appID)")
                return BDPInterceptorResponse(intercepted: true, interceptedType: .error, interceptedMsg: "unexpected appType: \(info.uniqueID.appType), appID: \(info.uniqueID.appID)")
            }
        }

        let interceptorArray = commonInterceptor + [appVersionInterceptor]

        return interceptorArray
    }
}

/// 离线包预安装管理基类
class EMAAppPreUpdateManager: NSObject {
    static let logger = Logger.oplog(EMAAppPreUpdateManager.self, category: "EMAAppPreUpdateManager")

    /// 拉取配置信息是否已经完成
    public var fetchUpdateInfoIsFinish = true

    let workQueue: DispatchQueue

    let appType: OPAppType

    init(appType: OPAppType) {
        self.appType = appType
        self.workQueue = DispatchQueue(label: "com.bytedance.EMAAppPreUpdate.\(appType.rawValue)",
                                       qos: .utility ,attributes: .init(rawValue: 0))
    }

    func requestAppUpdateInfo(_ params: [String : Any], completion: @escaping(_ result: Result<[EMAAppUpdateInfo], EMAPreloadError>) -> Void) {
        EMANetworkManager.shared().postUrl(EMAAPI.getUpdateAppInfos(), params: params, completionWithJsonData: {[weak self] json, error in
            guard let `self` = self else {
                Self.logger.error("\(String.PreUpdateTag) self is nil")
                return
            }

            self.workQueue.async {
                guard error == nil else {
                    completion(.failure(EMAPreloadError(errorMsg: "request updateInfo failed: \(String(describing: error))")))
                    return
                }

                guard let _json = json as? NSDictionary,
                      let data = _json.bdp_arrayValue(forKey:"data") as? [[String : Any]] else {
                    completion(.failure(EMAPreloadError(errorMsg: "request updateInfo success, but json is invalid")))
                    return
                }

                var error: NSError?
                guard let appUpdateInfoArray = EMAAppUpdateInfo.arrayOfAppUpdateInfo(fromDictionaries: data, error: &error) as? [EMAAppUpdateInfo] else {
                    Self.logger.warn("\(String.PreUpdateTag) \(OPAppTypeToString(self.appType)) convert to EMAAppUpdateInfo array failed: \(String(describing: error))")
                    completion(.failure(EMAPreloadError(errorMsg: "convert to EMAAppUpdateInfo array failed: \(String(describing: error))")))
                    return
                }

                completion(.success(self.extensionAppUpdateInfoArray(appUpdateInfoArray)))
            }
        }, eventName: "getUpdateAppInfos", requestTracing: nil)
    }

    /// 获取EMAAppUpdateInfo(源数据)中extension中的EMAAppUpdateInfo对象.
    /// 因为extension的数据才是有意义的. 但是extension中appVersion是包版本,需要从源数据更新.
    func extensionAppUpdateInfoArray(_ appUpdateInfoArray: [EMAAppUpdateInfo]) -> [EMAAppUpdateInfo] {
        var unwrapArray = [EMAAppUpdateInfo]()
        for appUpdateInfo in appUpdateInfoArray {
            let appVersion = BDPSafeString(appUpdateInfo.app_version)
            let appID = BDPSafeString(appUpdateInfo.app_id)
            if let extensionArray = OPUnsafeObject(appUpdateInfo.extensions) as? [EMAAppUpdateInfo] {
                for innerAppUpdateInfo in extensionArray {
                    innerAppUpdateInfo.app_id = appID
                    innerAppUpdateInfo.app_version = appVersion
                    unwrapArray.append(innerAppUpdateInfo)
                }
            }
        }
        return unwrapArray
    }

    /// 根据EMAAppUpdateInfo数组构造BDPPreloadHandleInfo.
    /// EMAAppUpdateInfo最外层的app_version 是应用版本. extensions中的EMAAppUpdateInfo的app_version是包版本
    /// - Parameter appUpdateInfoArray: EMAAppUpdateInfo 数组(来自extension中的数据)
    /// - Returns: BDPPreloadHandleInfo 数组
    func configPreloadHandlerArray(_ appUpdateInfoArray: [EMAAppUpdateInfo],
                                   scene: BDPPreloadScene,
                                   listener: BDPPreloadHandleListener,
                                   injector: BDPPreloadHandleInjector) -> [BDPPreloadHandleInfo] {
        appUpdateInfoArray.map {
            BDPPreloadHandleInfo(uniqueID: $0.uniqueID(),
                                 scene: scene,
                                 scheduleType: .toBeScheduled,
                                 extra: [String.ApplicationVersion : $0.app_version],
                                 listener: listener,
                                 injector: injector)
        }
    }

    /// 根据推送过来的数据构造EMAAppUpdateInfo对象
    ///  Note: 推送过来的JSONString中没有appID, 这边需要从字典中解析appID,然后赋值给对象
    func configAppUpdateInfo(_ item: [String: Any]) -> EMAAppUpdateInfo? {
        guard let appID = item["appID"] as? String,
              let extraJson = item["extraJson"] as? String else {
            Self.logger.warn("\(String.PreUpdateTag) \(OPAppTypeToString(appType)) item invalid: \(item)")
            return nil
        }

        var error: JSONModelError?
        guard let updateInfo = EMAAppUpdateInfo(string: extraJson, error: &error),
              error == nil else {
            Self.logger.warn("\(String.PreUpdateTag) \(OPAppTypeToString(appType)) config app update info failed: \(String(describing: error))")
            return nil
        }

        updateInfo.app_id = appID

        return updateInfo
    }

    /// 检查是否需要更新(根据上一次更新时间来判断)
    func checkIfNeedFetchInfo() -> Bool {
        // 与原逻辑一致, 如果没有上次更新时间,则放过
        guard let lastLaunchTime = self.kvStorage()?.object(forKey: String.LastUpdateTime) as? NSNumber else {
            Self.logger.warn("\(String.PreUpdateTag) \(OPAppTypeToString(appType)) ema_last_update_time is nil")
            return true
        }

        let minTimeSinceLastPullUpdateInfo = BDPPreloadHelper.preUpdateMinTimeSinceLastPull()

        guard (Date().timeIntervalSince1970 - lastLaunchTime.doubleValue) > minTimeSinceLastPullUpdateInfo else {
            Self.logger.info("\(String.PreUpdateTag) \(OPAppTypeToString(appType)) requst too often")
            return false
        }

        return true
    }

    func kvStorage() -> TMAKVStorage? {
        guard let kvStorage = (BDPModuleManager(of: appType).resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol)?.sharedLocalFileManager().kvStorage else {
            Self.logger.error("\(String.PreUpdateTag) \(OPAppTypeToString(appType)) can not get TMAKVStorage")
            return nil
        }
        return kvStorage
    }

    // 通用拦截器
    func commonInterceptorArray() -> [BDPPreHandleInterceptor] {
        // 无网络情况下拦截
        let networkInterceptor = EMAInterceptorUtils.networkInterceptor()
        // 非wifi情况下拦截
        let cellularInterceptor = EMAInterceptorUtils.cellularInterceptor()
        // 一天下载次数限制拦截
        let oneDayMaxCountInterceptor = {[weak self] (info: BDPPreloadHandleInfo) -> BDPInterceptorResponse in
            guard let `self` = self else {
                Self.logger.error("\(String.PreUpdateTag) self is nil, donot intercept")
                return BDPInterceptorResponse(intercepted: false)
            }

            let maxTimesOneDay = BDPPreloadHelper.preUpdateMaxTimesOneDay()
            let needIntercept = maxTimesOneDay < self.todayDownloadTimes()
            return BDPInterceptorResponse(intercepted: needIntercept, interceptedType: .exceedMaxDownloadTimesOneDay)
        }

        return [networkInterceptor, cellularInterceptor, oneDayMaxCountInterceptor]
    }

    func todayDownloadTimes() -> Int {
        guard let kvStorage = self.kvStorage() else {
            Self.logger.error("\(String.PreUpdateTag) \(OPAppTypeToString(appType)) kvStorage is nil, return 0 times")
            return 0
        }

        guard let date = NSDate().btd_string(withFormat: "yyyy-MM-dd"),
              let downloadTimeMap = (kvStorage.object(forKey: String.TodayDownloadTime) as? [String : Any]),
              let todayDownloadTime = downloadTimeMap[date] as? Int else {
            Self.logger.info("\(String.PreUpdateTag) \(OPAppTypeToString(appType)) can not get today download time")
            return 0
        }

        return todayDownloadTime
    }

    func updateTodayDownloadTimes(_ times: Int) {
        guard let kvStorage = self.kvStorage() else {
            Self.logger.error("\(String.PreUpdateTag) \(OPAppTypeToString(appType)) kvStorage is nil")
            return
        }

        guard let date = NSDate().btd_string(withFormat: "yyyy-MM-dd") else {
            Self.logger.info("\(String.PreUpdateTag) \(OPAppTypeToString(appType)) can not get today download time")
            return
        }

        let downloadTimesMap = [date : times]

        kvStorage.setObject(downloadTimesMap, forKey: String.TodayDownloadTime)
    }
}

extension Array where Element: Hashable {
    /// 去除数组中重复元素
    func removeDuplicateElements() -> Array {
        var buffer = Array()
        var added = Set<Element>()
        for elem in self {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }
}

fileprivate extension String {
    // 日志打印tag
    static let PreUpdateTag = "[EMAAppPreUpdate]"
    static let GadgetUpdateTag = "[EMAGadgetPreUpdate]"
    static let WebAppUpdateTag = "[EMAWebAppPreUpdate]"

    // kvStorage存储使用key
    static let LastUpdateTime = "ema_last_update_time"
    static let TodayDownloadTime = "ema_today_download_time"

    // EMAUpdateInfo中应用类型字符串
    static let Gadget = "gadget"
    static let WebOffline = "web_offline"

    static let ApplicationVersion = "applicationVersion"
    static let Wifi = "wifi"
    // 预拉取数据来源
    static let PreUpdatePullType = "PreUpdatePullType"
}

fileprivate extension Int {
    //每次请求最大应用数
    static let MaxCountPerRequest = 200
}
