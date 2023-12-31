//
//  OPPackageUpdateServer.swift
//  OPSDK
//
//  Created by laisanpin on 2022/3/23.
//  技术方案: https://bytedance.feishu.cn/docx/doxcnvkVGnpBgzefnP4wtZeMcdg
//  端侧技术文档: https://bytedance.feishu.cn/wiki/wikcnnf2ZEIH2xwMFVctA0TzAFf

import Foundation
import ECOInfra
import ECOProbe
import LKCommonsLogging
import LarkContainer
import OPFoundation

// 止血配置获取单例
@objcMembers
public final class OPPackageSilenceUpdateServer: NSObject, OPPackageSilenceUpdateProtocol {
    static let logger = Logger.oplog(OPPackageSilenceUpdateProtocol.self, category: "OPPackageSilenceUpdateServer")
    // 本地存储配置信息Key
    static let updateInfoKey = "OPPackageSilenceUpdateInfoKey"
    // 小程序启动时间Key
    static let appLastLoadTimeKey = "OPAppLastLoadTimeKey"
    // 单例对象
    public static let shared = OPPackageSilenceUpdateServer()

    private let updateQueue = DispatchQueue(label: "com.bytedance.OPSDK.silenceUpdate", attributes: .init(rawValue: 0))

    // 启动时间读写锁
    private let launchTimeMapLock = NSLock()
    // 更新止血信息表的锁
    private let updateInfoMapLock = NSLock()
    // 止血配置拉取是否完成
    public var fetchUpdateInfoIsFinish = true
    // 止血配置存储表
    private var leastAppVerionInfoMap: [String : OPPackageSlinceUpdateInfoProtocol]?
    // 应用最近一次冷启动时间戳(单位:ms)
    private var appLaunchTimeMap: [String : TimeInterval]?
    // 拉取失败后的重试次数(用户没设置则默认为3次)
    private var retryCount = 3
    // 延迟拉取时间(单位:ms, 用户没设置则默认为3000ms)
    private var delayFetchInterval = 3000

    private override init() {
        super.init()
    }

    public func fetchSilenceUpdateSettings(_ uniqueIDs: [OPAppUniqueID]) {
        fetchSilenceUpdateSettings(uniqueIDs, needSorted: true)
    }

    public func fetchSilenceUpdateSettings(_ uniqueIDs: [OPAppUniqueID], needSorted: Bool) {
        if uniqueIDs.isEmpty {
            Self.logger.warn("[silenceUpdate] uniqueID array is empty")
            return
        }

        updateQueue.async {
            guard self.fetchUpdateInfoIsFinish else {
                Self.logger.error("[silenceUpdate] updateInfo is fetching")
                return
            }

            self.fetchUpdateInfoIsFinish = false

            Self.logger.info("[silenceUpdate] start fetching")

            // 延迟发起网络请求
            let delaySecond = DispatchTimeInterval.milliseconds(self.delayFetchInterval)
            self.updateQueue.asyncAfter(deadline: .now() + delaySecond) {
                // 请求前先同步一下settings中的配置
                self.updateConfigFromSettings()

                // 重置缓存信息
                self.clearCache()

                //判断这边是否需要根据应用按照时间戳来排序, 由大到小
                let sortedIDs = needSorted ? self.sortUniqueIDsByLaunchTime(uniqueIDs) : uniqueIDs

                self.requestSilenceUpdateSettings(appIDs: sortedIDs.map({ $0.appID }), retryCount: self.retryCount)
            }
        }
    }

    public func getSilenceUpdateInfo(_ uniqueID: OPAppUniqueID) -> OPPackageSlinceUpdateInfoProtocol? {
        if leastAppVerionInfoMap == nil {
            Self.logger.info("[silenceUpdate] sync updateInfo from disk")
            updateLeastAppVerionInfoMap(getLocal(Self.updateInfoKey) as? [String : [String : String]])
        }

        updateInfoMapLock.lock()
        let updateInfo = leastAppVerionInfoMap?[uniqueID.appID]
        updateInfoMapLock.unlock()
        Self.logger.info("[silenceUpdate] \(uniqueID.fullString) updateInfo gadgetVersion: \(String(describing: updateInfo?.gadgetMobile)) h5OfflineVersion: \(String(describing: updateInfo?.h5OfflineVersion))")
        return updateInfo
    }

    public func canSilenceUpdate(leastAppVersion: String, metaAppVersion: String) -> Bool {
        let result = VersionHelper.compareVersions(versionFirst: leastAppVersion, versionSecond: metaAppVersion)
        Self.logger.info("[silenceUpdate] leastAppVersion: \(leastAppVersion), metaAppVersion:\(metaAppVersion), result: \(result)")
        return result == 1
    }

    /// 是否满足止血条件
    /// - Returns: 是否满足止血条件
    public func canSilenceUpdate(uniqueID: OPAppUniqueID, metaAppVersion: String?) -> Bool {
        guard uniqueID.versionType != .preview else {
            Self.logger.info("[silenceUpdate] preview app not support silenceUpdate")
            return false
        }
        // 如果没有meta中没有应用版本,则认为不满足止血要求(Android/iOS双端对齐)
        guard let metaAppVersion = metaAppVersion else {
            Self.logger.warn("[silenceUpdate] metaAppVersion is nil")
            return false
        }

        guard let updateInfo = getSilenceUpdateInfo(uniqueID) else { return false }
        if uniqueID.appType == .gadget {
            return canSilenceUpdate(leastAppVersion: updateInfo.gadgetMobile, metaAppVersion: metaAppVersion)
        } else if uniqueID.appType == .webApp {
            return canSilenceUpdate(leastAppVersion: updateInfo.h5OfflineVersion, metaAppVersion: metaAppVersion)
        } else {
            return false
        }
    }

    /// 产品化止血能力是否可用(当前类FG已开启全量)
    public func enableSlienceUpdate() -> Bool {
        return true
    }
}

extension OPPackageSilenceUpdateServer {
    // 更新应用冷启动时间戳(单位:ms)
    public func updateAppLaunchTime(_ uniqueID: OPAppUniqueID) {
        // 延迟5秒记录时间,避免在冷启动阶段抢占资源, 对TTI造成影响
        updateQueue.asyncAfter(deadline: .now() + .seconds(5)) {
            self.private_updateAppLaunchTime(uniqueID)
        }
    }

    public func private_updateAppLaunchTime(_ uniqueID: OPAppUniqueID) {
        let launchTime = NSDate().timeIntervalSince1970 * 1000
        launchTimeMapLock.lock()
        if self.appLaunchTimeMap == nil {
            Self.logger.info("[silenceUpdate] sync lastLaunchTime from disk")
            appLaunchTimeMap = self.getLocal(Self.appLastLoadTimeKey) as? [String: TimeInterval] ?? [String : TimeInterval]()
        }
        Self.logger.info("[silenceUpdate] set uniqueID: \(uniqueID.fullString) launchTime: \(launchTime)")
        appLaunchTimeMap?[uniqueID.appID] = launchTime
        launchTimeMapLock.unlock()
        saveLocal(self.appLaunchTimeMap, Self.appLastLoadTimeKey)
    }

    // 应用上一次启动时间,如果未记录则返回-1;(单位:ms)
    public func lastLaunchTime(_ uniqueID: OPAppUniqueID) -> TimeInterval {
        launchTimeMapLock.lock()
        if appLaunchTimeMap == nil {
            Self.logger.info("[silenceUpdate] sync lastLaunchTime from disk")
            appLaunchTimeMap = getLocal(Self.appLastLoadTimeKey) as? [String: TimeInterval] ?? [String : TimeInterval]()
        }
        let timestamp = appLaunchTimeMap?[uniqueID.appID] ?? -1
        launchTimeMapLock.unlock()
        return timestamp
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

    /// 是否满足止血要求
    /// - Parameters:
    ///   - uniqueID: 应用ID
    ///   - metaAppVersion: meta信息中的应用版本
    ///   - launchLeastAppVersion: applink中配置的止血版本
    /// - Returns: 是否满足止血要求
    public func canSilenceUpdate(uniqueID: OPAppUniqueID,
                                 metaAppVersion: String?,
                                 launchLeastAppVersion: String?) -> Bool {
        // 如果没有meta中没有应用版本,则认为不满足止血要求(Android/iOS双端对齐)
        guard let metaAppVersion = metaAppVersion else {
            Self.logger.warn("[silenceUpdate] metaAppVersion is nil")
            return false
        }
        // 如果applink中配置的止血版本比应用版本高, 则认为满足止血条件; 否则比对settings上配置的止血版本
        if let _launchLeastAppVersion = launchLeastAppVersion,
            canSilenceUpdate(leastAppVersion: _launchLeastAppVersion, metaAppVersion: metaAppVersion) {
            Self.logger.info("[silenceUpdate] app: \(uniqueID.fullString) can silenceUpdate, launchLeastAppVersion: \(_launchLeastAppVersion), metaAppVersion: \(metaAppVersion)")
            return true
        }
        return canSilenceUpdate(uniqueID: uniqueID, metaAppVersion: metaAppVersion)
    }

    // 发起获取止血配置信息请求
    private func requestSilenceUpdateSettings(appIDs: [String], retryCount: Int) {
        if retryCount == 0 {
            Self.logger.info("[silenceUpdate] retryCount is 0")
            fetchUpdateInfoIsFinish = true
            return
        }

        if appIDs.isEmpty {
            Self.logger.warn("[silenceUpdate] appIDs is empty")
            fetchUpdateInfoIsFinish = true
            return
        }

        // 剩余重试次数
        let remainRequestCount = retryCount - 1

        Self.logger.info("[silenceUpdate] start request SilenceUpdate settings appIDs: \(appIDs), remainRequestCount: \(remainRequestCount)")

        let requestParams = ["app_ids" : appIDs]

        guard let config = BDPNetworkRequestExtraConfiguration.defaultConfig() else {
            Self.logger.error("[silenceUpdate] create request config failed")
            requestSilenceUpdateSettings(appIDs: appIDs, retryCount: remainRequestCount)
            return
        }
        config.method = .POST

        let _ = OPMonitor(EPMClientOpenPlatformCommonBandageCode.mp_fetch_silence_update_result).addCategoryValue("fetch_type", "START").flush()

        guard let url = URL.opURL(domain: OPApplicationService.current.domainConfig.openDomain, path: .OPNetwork.OPPath.appInterface, resource: .OPNetwork.OPInterface.silenceUpdateInfo) else {
            Self.logger.error("[silenceUpdate] config URL faild")
            requestSilenceUpdateSettings(appIDs: appIDs, retryCount: remainRequestCount)
            return
        }

        EMANetworkRequestManager().task(withRequestUrl: url.absoluteString, parameters: requestParams, extraConfig: config) {[weak self] error, jsonObj, response in
            guard let `self` = self else {
                // 单例不会出现这个case, 这边只是为了解包self
                Self.logger.info("[silenceUpdate] self is nil")
                return
            }
            // 放到任务线程中执行
            self.updateQueue.async {
                guard error == nil else {
                    Self.logger.error("[silenceUpdate] request get error: \(String(describing: error))")
                    self.requestSilenceUpdateSettings(appIDs: appIDs, retryCount: remainRequestCount)
                    return
                }

                if let res = jsonObj as? [String : Any],
                   let data = res["data"] as? [String : Any],
                   let leastAppVersionDic = data["least_app_version_setting"] as? [String : [String : String]] {
                    let localLeastAppVersionDic = self.getLocal(Self.updateInfoKey) as? [String : [String : String]]
                    let mergedLeastAppVersionDic = self.mergeLocalAndRemoteLeastAppVersionDic(localDic: localLeastAppVersionDic, remoteDic: leastAppVersionDic)
                    self.saveLocal(mergedLeastAppVersionDic, Self.updateInfoKey)
                    self.updateLeastAppVerionInfoMap(mergedLeastAppVersionDic)
                    let _ = OPMonitor(EPMClientOpenPlatformCommonBandageCode.mp_fetch_silence_update_result).addCategoryValue("fetch_type", "SUCCESS").setResultTypeSuccess().flush()
                    self.fetchUpdateInfoIsFinish = true
                    Self.logger.info("[silenceUpdate] request success silenceUpdate apps: \(leastAppVersionDic.keys)")
                } else {
                    Self.logger.error("[silenceUpdate] request failed json: \(String(describing: jsonObj))")

                    self.requestSilenceUpdateSettings(appIDs: appIDs, retryCount: remainRequestCount)
                }
            }
        }
    }

    // 合并本地与远程请求过来的止血配置信息
    private func mergeLocalAndRemoteLeastAppVersionDic(localDic: [String : [String : String]]?, remoteDic: [String : [String : String]]?) -> [String : [String : String]]? {
        Self.logger.info("[silenceUpdate] merge local and remote data")
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
            Self.logger.warn("[silenceUpdate] update leastAppVersionMap fail, input is nil")
            return
        }
        updateInfoMapLock.lock()
        var tmpDic = [String : OPPackageSlinceUpdateInfoProtocol]()
        for (appId, versionInfo) in _leastAppVersionDic {
            let info = OPPackageSilenceUpdateInfo(gadgetMobile: versionInfo["gadget_mobile"] ?? "", h5OfflineVersion: versionInfo["h5_offline"] ?? "")
            tmpDic[appId] = info
        }
        leastAppVerionInfoMap = tmpDic
        updateInfoMapLock.unlock()
    }

    // 清理内存缓存
    private func clearCache() {
        updateInfoMapLock.lock()
        leastAppVerionInfoMap = nil
        updateInfoMapLock.unlock()

        launchTimeMapLock.lock()
        appLaunchTimeMap = nil
        launchTimeMapLock.unlock()
    }

    // 从settings中更新相关配置信息
    private func updateConfigFromSettings() {
        if let manager = ECOConfig.service() as? EMAConfigManager, let config = manager.getLatestDictionaryValue(for: "configSchemaParameterLittleAppList") {
            self.retryCount = config["retryTimes"] as? Int ?? 3
            self.delayFetchInterval = config["delay"] as? Int ?? 3000
            Self.logger.info("[silenceUpdate] get retryCount:\(self.retryCount), delay: \(self.delayFetchInterval)")
        } else {
            Self.logger.warn("[silenceUpdate] cannot get configSchemaParameterLittleAppList from settings")
        }
    }

    private func saveLocal(_ dictionary: [String: Any]?, _ key: String) {
        guard let storage = getKvStorage() else {
            Self.logger.warn("[silenceUpdate] cannot get TMAKVStorage")
            return
        }

        guard let data = dictionary else {
            Self.logger.warn("[silenceUpdate] data is nil")
            return
        }

        storage.setObject(data, forKey: key)
    }

    private func getLocal(_ key: String) -> [String : Any]? {
        guard let storage = getKvStorage() else {
            Self.logger.warn("[silenceUpdate] cannot get TMAKVStorage")
            return nil
        }
        return storage.object(forKey: key) as? [String : Any]
    }

    private func getKvStorage() -> TMAKVStorage? {
        return OPSDKConfigProvider.kvStorageProvider?(.gadget)
    }
}


class OPPackageSilenceUpdateInfo: OPPackageSlinceUpdateInfoProtocol {
    var gadgetMobile: String
    var h5OfflineVersion: String
    init(gadgetMobile: String, h5OfflineVersion: String) {
        self.gadgetMobile = gadgetMobile
        self.h5OfflineVersion = h5OfflineVersion
    }
}
