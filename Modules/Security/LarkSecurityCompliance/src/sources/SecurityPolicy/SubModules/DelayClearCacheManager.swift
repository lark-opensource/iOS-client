//
//  DelayClearCacheManager.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/12/8.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkContainer
import LarkPolicyEngine
import RustSDK
import LarkSecurityComplianceInfra
import LarkAccountInterface

final class DelayClearCacheManager: UserResolverWrapper {
    @ScopedProvider private var strategyEngine: PolicyEngineService?
    @ScopedProvider private var settings: Settings?
    @SafeWrapper private(set) var ipPolicyModelMap: [String: TimeInterval?]
    private(set) var ipPolicyList: [PolicyModel]
    var clearCacheBlock: (([String]) -> Void)?
    private var timer: Timer?
    private let localCache: LocalCache
    
    private static let ipMapChangeLogPrefix = "[ip_policy_changed]"

    private var delayTime: Int {
        settings?.fileStrategyDelayCleanTime ?? 10 * 60
    }

    private var pollingTime: Int {
        settings?.fileStrategyDelayCleanInaccuracy ?? 60
    }

    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        let service = try? userResolver.resolve(assert: PassportUserService.self)
        localCache = LocalCache(cacheKey: SecurityPolicyConstKey.ipPolicyList,
                                userID: service?.user.userID ?? "")
        let ipTaskIDList: [String] = localCache.readCache() ?? []
        ipPolicyList = SecurityPolicyConstKey.staticPolicyModel.filter { policyModel in
            ipTaskIDList.contains { $0 == policyModel.taskID }
        }
        ipPolicyModelMap = [:]
        SPLogger.info("security policy \(Self.ipMapChangeLogPrefix) map changed: init")
        ipTaskIDList.forEach {
            ipPolicyModelMap.updateValue(nil, forKey: $0)
            SPLogger.info("security policy \(Self.ipMapChangeLogPrefix) map changed: init_from_list")
        }
    }

    func removeSuccessUpdatedPolicyModel(successPolicyModel: [PolicyModel]) {
        if self.timer == nil { return }
        successPolicyModel.forEach {
            guard self.ipPolicyModelMap[$0.taskID] != nil else { return }
            self.ipPolicyModelMap.updateValue(nil, forKey: $0.taskID)
            SPLogger.info("security policy \(Self.ipMapChangeLogPrefix) map changed: remove_policy_model")
        }
        self.cancelTimerIfNeed()
    }

    func updatePolicyTimeStamp() {
        let currentTime = Self.ntpTime
        self.ipPolicyModelMap.forEach { policyModelPair in
            let policyModel = policyModelPair.key
            guard policyModelPair.value != nil else {
                self.ipPolicyModelMap.updateValue(currentTime, forKey: policyModel)
                SPLogger.info("security policy \(Self.ipMapChangeLogPrefix) map changed: update_time_stamp")
                return
            }
        }
        self.fireTimerIfNeed()
    }

    func checkPointcutIsControlledByFactors(policyModels: [PolicyModel], factor: [String]) {
        var requestMap: [String: CheckPointcutRequest] = [:]
        policyModels.forEach { element in
            requestMap.updateValue(wrapPolicyModel(policyModel: element, factor: factor), forKey: element.taskID)
        }
        strategyEngine?.checkPointcutIsControlledByFactors(requestMap: requestMap) { [weak self] retMap in
            guard let self else { return }
            SPLogger.info("security policy: check pointcut is controlled: get result: \(retMap)",
                          debugViewMsg: "security policy: check pointcut is controlled: get result")
            self.updateIPPolicyModelMap(newIPInfo: retMap)
        }

    }

    private func fireTimerIfNeed() {
        guard timer == nil else { return }
        let checkTime = pollingTime
        SPLogger.info("security policy: delay clear cache manager: timer is start")
        self.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(checkTime), repeats: true) { [weak self] _ in
            SPLogger.info("security policy: delay clear cache manager: timer finish tic")
            guard let self else { return }
            self.clearCacheBlock?(self.removeNeededCleanPolicyModel())
        }
    }

    private func cancelTimerIfNeed() {
        if let timer = self.timer,
           !self.isPolicyModelNeedClear() {
            timer.invalidate()
            self.timer = nil
            SPLogger.info("security policy: delay clear cache manager: all policy model is updated, timer is cancled")
        }
    }

    private func transIPPolicyModelMapToList() -> [PolicyModel] {
        let list = SecurityPolicyConstKey.staticPolicyModel.filter { policyModel in
            ipPolicyModelMap.contains { $0.key == policyModel.taskID }
        }
        return list
    }

    private func updateIPPolicyModelMap(newIPInfo: [String: Bool]) {
        newIPInfo.forEach { taskIDPair in
            let isIPcontrolled = taskIDPair.value
            let taskID = taskIDPair.key
            if isIPcontrolled {
                if self.ipPolicyModelMap[taskID] != nil {
                    return
                }
                self.ipPolicyModelMap.updateValue(nil, forKey: taskID)
                SPLogger.info("security policy \(Self.ipMapChangeLogPrefix) map changed: ip_controlled")
            } else {
                self.ipPolicyModelMap.removeValue(forKey: taskID)
                SPLogger.info("security policy \(Self.ipMapChangeLogPrefix) map changed: ip_not_controlled")
            }
        }
        let newPolicyModelList = self.transIPPolicyModelMapToList()
        if newPolicyModelList != self.ipPolicyList {
            self.localCache.writeCache(value: self.ipPolicyModelMap.keys.map { $0 })
            self.ipPolicyList = newPolicyModelList
            self.cancelTimerIfNeed()
        }

    }

    private func removeNeededCleanPolicyModel() -> [String] {
        let currentTime = Self.ntpTime
        let neededUpdateTaskID = ipPolicyModelMap.compactMap { policyModelPair -> String? in
            guard let timeStamp = policyModelPair.value else { return nil }
            let taskID = policyModelPair.key
            let delta = currentTime - timeStamp
            if Int(fabs(delta)) >= delayTime {
                self.ipPolicyModelMap.updateValue(nil, forKey: taskID)
                SPLogger.info("security policy \(Self.ipMapChangeLogPrefix) map changed: remove_cache")
                return taskID
            }
            return nil
        }
        cancelTimerIfNeed()
        return neededUpdateTaskID
    }

    private func wrapPolicyModel(policyModel: PolicyModel, factor: [String]) -> CheckPointcutRequest {
        return CheckPointcutRequest(pointKey: policyModel.pointKey.rawValue, entityJSONObject: policyModel.entity.asParams(), factors: factor)
    }

    private func getPolicyResponseMap<T>(policyModels: [PolicyModel], responseMap: [String: T]) -> [PolicyModel: T] {
        var policyResponseMap: [PolicyModel: T] = [:]
        policyModels.forEach { policyModel in
            if let validateResponse = responseMap[policyModel.taskID] {
                policyResponseMap[policyModel] = validateResponse
            }
        }
        return policyResponseMap
    }

    private func isPolicyModelNeedClear() -> Bool {
        if ipPolicyModelMap.isEmpty { return false }
        let timeStampList = ipPolicyModelMap.values.compactMap { $0 }
        return !timeStampList.isEmpty
    }

    // get_ntp_time()方法有获取失败的情况，如果获取失败则使用当前系统时间
    static var ntpTime: TimeInterval {
        let ntpTime = TimeInterval(get_ntp_time() / 1000)
       // ntp_time有获取失败的情况，获取失败的时候返回的值是时间的偏移量，和sdk同学沟可以认为通当ntp_time的值大于2010年的时间戳认为获取成功
        let ntpBaseTimestamp: TimeInterval = 1_262_275_200 // 2010-01-01 00:00
        if ntpTime > ntpBaseTimestamp {
            return ntpTime
        } else {
            SPLogger.error("security policy: failed to get ntp time")
            return Date().timeIntervalSince1970
        }
    }
}
