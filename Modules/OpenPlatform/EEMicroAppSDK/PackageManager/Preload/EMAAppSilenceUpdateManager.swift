//
//  EMAAppSilenceUpdateManager.swift
//  EEMicroAppSDK
//
//  Created by laisanpin on 2022/8/5.
//

import Foundation
import LKCommonsLogging
import OPSDK
import TTMicroApp

public typealias SilenceUpdateCompletion = (Result<[String : OPPackageSlinceUpdateInfoProtocol]?, EMAPreloadError>) -> Void

class EMAAppSilenceUpdateManager: NSObject {
    static let logger = Logger.oplog(OPPackageSilenceUpdateProtocol.self, category: "EMAAppSilenceUpdateManager")

    // 本地存储配置信息Key
    static let updateInfoKey = "EMAPackageSilenceUpdateInfoKey"
    // 小程序启动时间Key
    static let appLastLoadTimeKey = "EMAAppLastLoadTimeKey"

    public let appType: OPAppType

    // 止血配置拉取是否完成
    public var fetchUpdateInfoIsFinish = true

    let workQueue: DispatchQueue

    // 启动时间读写锁
    let launchTimeMapLock = NSLock()
    // 更新止血信息表的锁
    let updateInfoMapLock = NSLock()
    // 止血配置存储表
    var leastAppVerionInfoMap: [String : OPPackageSlinceUpdateInfoProtocol]?
    // 应用最近一次冷启动时间戳(单位:ms)
    var appLaunchTimeMap: [String : TimeInterval]?
    // 拉取失败后的重试次数(用户没设置则默认为3次)
    var retryCount = 3
    // 延迟拉取时间(单位:ms, 用户没设置则默认为3000ms)
    var delayFetchInterval = 3000

    init(appType: OPAppType) {
        self.appType = appType
        self.workQueue = DispatchQueue(label: "com.bytedance.AppSilenceUpdate.\(appType.rawValue)", qos: .utility, attributes: .init(rawValue: 0))
    }

    func fetchSilenceUpdateSettings(_ uniqueIDs: [OPAppUniqueID], needSorted: Bool, completion: @escaping SilenceUpdateCompletion) {
        if uniqueIDs.isEmpty {
            Self.logger.warn("[AppSilence] \(OPAppTypeToString(appType)) uniqueID array is empty")
            return
        }

        workQueue.async {
            guard self.fetchUpdateInfoIsFinish else {
                Self.logger.error("[AppSilence] \(OPAppTypeToString(self.appType)) updateInfo is fetching")
                return
            }

            self.fetchUpdateInfoIsFinish = false

            Self.logger.info("[AppSilence] \(OPAppTypeToString(self.appType)) start fetching")

            // 延迟发起网络请求
            let delaySecond = DispatchTimeInterval.milliseconds(self.delayFetchInterval)
            self.workQueue.asyncAfter(deadline: .now() + delaySecond) {
                // 请求前先同步一下settings中的配置
                self.updateConfigFromSettings()

                // 重置缓存信息
                self.clearCache()

                //判断这边是否需要根据应用按照时间戳来排序, 由大到小
                let sortedIDs = needSorted ? self.sortUniqueIDsByLaunchTime(uniqueIDs) : uniqueIDs

                self.requestSilenceUpdateSettings(appIDs: sortedIDs.map({ $0.appID }), retryCount: self.retryCount, completion: completion)
            }
        }
    }
}

extension EMAAppSilenceUpdateManager: OPPackageSilenceUpdateProtocol {
    public func fetchSilenceUpdateSettings(_ uniqueIDs: [OPAppUniqueID]) {
        fetchSilenceUpdateSettings(uniqueIDs, needSorted: true)
    }

    public func fetchSilenceUpdateSettings(_ uniqueIDs: [OPAppUniqueID], needSorted: Bool) {
        fetchSilenceUpdateSettings(uniqueIDs, needSorted: needSorted) { result in
            switch result {
            case .success(_):
                break
            case .failure(let error):
                Self.logger.warn("[AppSilence]" + error.errorMsg)
            }
        }
    }

    public func getSilenceUpdateInfo(_ uniqueID: OPAppUniqueID) -> OPPackageSlinceUpdateInfoProtocol? {
        if leastAppVerionInfoMap == nil {
            Self.logger.info("[AppSilence] \(OPAppTypeToString(appType)) sync updateInfo from disk")
            updateLeastAppVerionInfoMap(getLocal(getKvStorage(), Self.updateInfoKey) as? [String : [String : String]])
        }

        let updateInfo = safeGetLeastAppInfo(uniqueID)
        Self.logger.info("[AppSilence] \(OPAppTypeToString(appType)) \(uniqueID.fullString) updateInfo gadgetVersion: \(String(describing: updateInfo?.gadgetMobile)) h5OfflineVersion: \(String(describing: updateInfo?.h5OfflineVersion))")
        return updateInfo
    }

    public func canSilenceUpdate(leastAppVersion: String, metaAppVersion: String) -> Bool {
        let result = BDPVersionManager.compareVersion(leastAppVersion, with: metaAppVersion)
        Self.logger.info("[AppSilence] \(OPAppTypeToString(appType)) leastAppVersion: \(leastAppVersion), metaAppVersion:\(metaAppVersion), result: \(result)")
        return result == 1
    }

    public func canSilenceUpdate(uniqueID: OPAppUniqueID, metaAppVersion: String?) -> Bool {
        assert(false, "[AppSilence] subclass should override")
        Self.logger.error("[AppSilence] subclass should override")
        return false
    }

    public func canSilenceUpdate(uniqueID: OPAppUniqueID,
                                 metaAppVersion: String?,
                                 launchLeastAppVersion: String?) -> Bool {
        // 如果没有meta中没有应用版本,则认为不满足止血要求(Android/iOS双端对齐)
        guard let metaAppVersion = metaAppVersion else {
            Self.logger.warn("[AppSilence] \(OPAppTypeToString(appType)) metaAppVersion is nil")
            return false
        }
        // 如果applink中配置的止血版本比应用版本高, 则认为满足止血条件; 否则比对settings上配置的止血版本
        if let _launchLeastAppVersion = launchLeastAppVersion,
            canSilenceUpdate(leastAppVersion: _launchLeastAppVersion, metaAppVersion: metaAppVersion) {
            Self.logger.info("[AppSilence] \(OPAppTypeToString(appType)) app: \(uniqueID.fullString) can silenceUpdate, launchLeastAppVersion: \(_launchLeastAppVersion), metaAppVersion: \(metaAppVersion)")
            return true
        }
        return canSilenceUpdate(uniqueID: uniqueID, metaAppVersion: metaAppVersion)
    }

    // 更新应用冷启动时间戳(单位:ms)
    public func updateAppLaunchTime(_ uniqueID: OPAppUniqueID) {
        let launchTime = Date().timeIntervalSince1970 * 1000
        // 这边异步延迟去记录,避免影响小程序启动
        let storage = getKvStorage()
        self.workQueue.asyncAfter(deadline: .now() + .milliseconds(Int.UpdateLaunchTimeDelay)) {
            if self.appLaunchTimeMap == nil {
                Self.logger.info("[AppSilence] \(OPAppTypeToString(self.appType)) sync lastLaunchTime from disk")
                let localAppLaunchTimeMap = self.getLocal(storage, Self.appLastLoadTimeKey) as? [String: TimeInterval] ?? [String : TimeInterval]()
                self.safeSetAppLaunchTimeMap(localAppLaunchTimeMap)
            }
            Self.logger.info("[AppSilence] \(OPAppTypeToString(self.appType)) set uniqueID: \(uniqueID.fullString) launchTime: \(launchTime)")
            self.safeUpdateAppLaunchTimeMap(uniqueID, launchTime)
            self.saveLocal(storage, self.appLaunchTimeMap, Self.appLastLoadTimeKey)
        }
    }

    public func enableSlienceUpdate() -> Bool {
        return BDPPreloadHelper.silenceEnable()
    }
}

// MARK: 数据更新等私有方法
extension EMAAppSilenceUpdateManager {
    // 发起获取止血配置信息请求
    private func requestSilenceUpdateSettings(appIDs: [String], retryCount: Int, completion: @escaping SilenceUpdateCompletion) {
        if retryCount == 0 {
            fetchUpdateInfoIsFinish = true
            completion(.failure(EMAPreloadError(errorMsg: "retryCount is 0")))
            return
        }

        if appIDs.isEmpty {
            fetchUpdateInfoIsFinish = true
            completion(.failure(EMAPreloadError(errorMsg: "appIDs is empty")))
            return
        }

        // 剩余重试次数
        let remainRequestCount = retryCount - 1

        Self.logger.info("[AppSilence] \(OPAppTypeToString(appType)) start request SilenceUpdate settings appIDs: \(appIDs), remainRequestCount: \(remainRequestCount)")

        let requestParams = ["app_ids" : appIDs]

        guard let config = BDPNetworkRequestExtraConfiguration.defaultConfig() else {
            Self.logger.error("[AppSilence] \(OPAppTypeToString(appType)) create request config failed")
            requestSilenceUpdateSettings(appIDs: appIDs, retryCount: remainRequestCount, completion: completion)
            return
        }
        config.method = .POST

        guard let url = URL.opURL(domain: OPApplicationService.current.domainConfig.openDomain, path: .OPNetwork.OPPath.appInterface, resource: .OPNetwork.OPInterface.silenceUpdateInfo) else {
            Self.logger.error("[AppSilence] \(OPAppTypeToString(appType)) config URL faild")
            requestSilenceUpdateSettings(appIDs: appIDs, retryCount: remainRequestCount, completion: completion)
            return
        }

        // 这边提前获取storage对象,避免在网络请求回来前,有切换租户操作导致数据存储到错误租户的数据库中
        let storage = getKvStorage()

        EMANetworkRequestManager().task(withRequestUrl: url.absoluteString, parameters: requestParams, extraConfig: config) {[weak self] error, jsonObj, response in
            guard let `self` = self else {
                // 单例不会出现这个case, 这边只是为了解包self
                Self.logger.info("[AppSilence] self is nil")
                return
            }
            // 放到任务线程中执行
            self.workQueue.async {
                guard error == nil else {
                    Self.logger.error("[AppSilence] \(OPAppTypeToString(self.appType)) request get error: \(String(describing: error))")
                    self.requestSilenceUpdateSettings(appIDs: appIDs, retryCount: remainRequestCount, completion: completion)
                    return
                }

                if let res = jsonObj as? [String : Any],
                   let data = res["data"] as? [String : Any],
                   let leastAppVersionDic = data["least_app_version_setting"] as? [String : [String : String]] {
                    let localLeastAppVersionDic = self.getLocal(storage, Self.updateInfoKey) as? [String : [String : String]]
                    let mergedLeastAppVersionDic = self.mergeLocalAndRemoteLeastAppVersionDic(localDic: localLeastAppVersionDic, remoteDic: leastAppVersionDic)
                    self.saveLocal(storage, mergedLeastAppVersionDic, Self.updateInfoKey)
                    self.updateLeastAppVerionInfoMap(mergedLeastAppVersionDic)

                    // 这边读取加一下锁
                    self.updateInfoMapLock.lock()
                    let leastAppVersionMap = self.leastAppVerionInfoMap
                    self.updateInfoMapLock.unlock()
                    self.fetchUpdateInfoIsFinish = true
                    completion(.success(leastAppVersionMap))
                } else {
                    Self.logger.error("[AppSilence] \(OPAppTypeToString(self.appType)) request failed json: \(String(describing: jsonObj))")
                    self.requestSilenceUpdateSettings(appIDs: appIDs, retryCount: remainRequestCount, completion: completion)
                }
            }
        }
    }

    // 合并本地与远程请求过来的止血配置信息
    private func mergeLocalAndRemoteLeastAppVersionDic(localDic: [String : [String : String]]?, remoteDic: [String : [String : String]]?) -> [String : [String : String]]? {
        Self.logger.info("[AppSilence] \(OPAppTypeToString(appType)) merge local and remote data")
        guard let localDic = localDic else {
            return remoteDic
        }

        guard let remoteDic = remoteDic else {
            return localDic
        }

        var _localDic = localDic

        // 如果本地和远程都有某个key存在时,使用远程请求过来的值
        _localDic.merge(remoteDic, uniquingKeysWith: {$1})

        return _localDic
    }

    // 更新止血配置信息表
    private func updateLeastAppVerionInfoMap(_ leastAppVersionDic: [String : [String : String]]?) {
        guard let _leastAppVersionDic = leastAppVersionDic else {
            Self.logger.warn("[AppSilence] \(OPAppTypeToString(appType)) update leastAppVersionMap fail, input is nil")
            return
        }

        var tmpDic = [String : OPPackageSlinceUpdateInfoProtocol]()
        for (appId, versionInfo) in _leastAppVersionDic {
            let info = EMAPackageSilenceUpdateInfo(gadgetMobile: versionInfo["gadget_mobile"] ?? "", h5OfflineVersion: versionInfo["h5_offline"] ?? "")
            tmpDic[appId] = info
        }

        safeSetLeastAppVerionInfoMap(tmpDic)
    }

    // 从settings中更新相关配置信息
    private func updateConfigFromSettings() {
        if let manager = ECOConfig.service() as? EMAConfigManager, let config = manager.getLatestDictionaryValue(for: "configSchemaParameterLittleAppList") {
            self.retryCount = config["retryTimes"] as? Int ?? 3
            self.delayFetchInterval = config["delay"] as? Int ?? 3000
            Self.logger.info("[AppSilence] \(OPAppTypeToString(appType)) get retryCount:\(self.retryCount), delay: \(self.delayFetchInterval)")
        } else {
            Self.logger.warn("[AppSilence] \(OPAppTypeToString(appType)) cannot get configSchemaParameterLittleAppList from settings")
        }
    }

    private func saveLocal(_ storage: TMAKVStorage?, _ dictionary: [String: Any]?, _ key: String) {
        guard let storage = storage else {
            Self.logger.warn("[AppSilence] \(OPAppTypeToString(appType)) cannot get TMAKVStorage")
            return
        }

        guard let data = dictionary else {
            Self.logger.warn("[AppSilence] \(OPAppTypeToString(appType)) data is nil")
            return
        }

        storage.setObject(data, forKey: key)
    }

    // 清理内存缓存
    private func clearCache() {
        safeSetLeastAppVerionInfoMap(nil)
        safeSetAppLaunchTimeMap(nil)
    }

    // 根据启动时间对uniqueID进行排序
    public func sortUniqueIDsByLaunchTime(_ uniqueIDs: [OPAppUniqueID]) -> [OPAppUniqueID] {
        let sortedIDs = uniqueIDs.sorted { firstID, secondID in
            let firstLaunchTime = self.lastLaunchTime(firstID)
            let secondLaunchTime = self.lastLaunchTime(secondID)
            return firstLaunchTime > secondLaunchTime
        }

        return sortedIDs
    }

    // 应用上一次启动时间,如果未记录则返回-1;(单位:ms)
    public func lastLaunchTime(_ uniqueID: OPAppUniqueID) -> TimeInterval {
        if appLaunchTimeMap == nil {
            Self.logger.info("[AppSilence] \(OPAppTypeToString(appType)) sync lastLaunchTime from disk")
            let localAppLaunchTimeMap = getLocal(getKvStorage(), Self.appLastLoadTimeKey) as? [String: TimeInterval] ?? [String : TimeInterval]()
            safeSetAppLaunchTimeMap(localAppLaunchTimeMap)
        }
        let timestamp = safeGetAppLaunchTime(uniqueID)
        return timestamp
    }

    private func getLocal(_ storage: TMAKVStorage?, _ key: String) -> [String : Any]? {
        guard let storage = storage else {
            Self.logger.warn("[AppSilence] \(OPAppTypeToString(appType)) cannot get TMAKVStorage")
            return nil
        }
        return storage.object(forKey: key) as? [String : Any]
    }

    private func getKvStorage() -> TMAKVStorage? {
        guard let kvStorage = (BDPModuleManager(of: appType).resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol)?.sharedLocalFileManager().kvStorage else {
            Self.logger.error("[AppSilenceUpate] \(OPAppTypeToString(self.appType)) can not get TMAKVStorage")
            return nil
        }
        return kvStorage
    }
}

// MARK: 提供线程安全的读写方法
extension EMAAppSilenceUpdateManager {
    // 设置止血应用信息Map
    private func safeSetLeastAppVerionInfoMap(_ newMap: [String : OPPackageSlinceUpdateInfoProtocol]?) {
        updateInfoMapLock.lock()
        leastAppVerionInfoMap = newMap
        updateInfoMapLock.unlock()
    }

    // 根据uniqueID获取对应的止血信息
    private func safeGetLeastAppInfo(_ uniqueID: OPAppUniqueID) -> OPPackageSlinceUpdateInfoProtocol? {
        var appInfo: OPPackageSlinceUpdateInfoProtocol? = nil
        updateInfoMapLock.lock()
        appInfo = leastAppVerionInfoMap?[uniqueID.appID]
        updateInfoMapLock.unlock()
        return appInfo
    }

    // 设置应用启动时间Map
    private func safeSetAppLaunchTimeMap(_ newMap: [String : TimeInterval]?) {
        launchTimeMapLock.lock()
        appLaunchTimeMap = newMap
        launchTimeMapLock.unlock()
    }

    // 更新应用启动时间Map(单位: 毫秒)
    private func safeUpdateAppLaunchTimeMap(_ uniqueID: OPAppUniqueID, _ launchTime: TimeInterval) {
        launchTimeMapLock.lock()
        appLaunchTimeMap?[uniqueID.appID] = launchTime
        launchTimeMapLock.unlock()
    }

    // 根据uniqueID获取对应的启动时间(默认值为-1, 单位: 毫秒)
    private func safeGetAppLaunchTime(_ uniqueID: OPAppUniqueID) -> TimeInterval {
        var launchTime: TimeInterval = -1
        launchTimeMapLock.lock()
        if let _launchTime = appLaunchTimeMap?[uniqueID.appID] {
            launchTime = _launchTime
        }
        launchTimeMapLock.unlock()
        return launchTime
    }
}

class EMAPackageSilenceUpdateInfo: OPPackageSlinceUpdateInfoProtocol {
    let gadgetMobile: String
    let h5OfflineVersion: String
    init(gadgetMobile: String, h5OfflineVersion: String) {
        self.gadgetMobile = gadgetMobile
        self.h5OfflineVersion = h5OfflineVersion
    }
}

fileprivate extension Int {
    // 延迟更新应用启动时间(单位:毫秒)
    static let UpdateLaunchTimeDelay = 5000
}
