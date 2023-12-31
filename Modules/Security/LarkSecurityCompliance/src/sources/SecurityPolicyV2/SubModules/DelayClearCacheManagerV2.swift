//
//  DelayClearCacheManager.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/12/8.
//

import RustSDK
import Foundation
import LarkContainer
import LarkPolicyEngine
import LarkAccountInterface
import LarkSecurityComplianceInfra
import LarkSecurityComplianceInterface

extension SecurityPolicyV2 {
    final class DelayClearCacheManager: UserResolverWrapper {
        private let settings: SCSettingService
        private let modelFactory: PolicyModelFactory
        @SafeWrapper private(set) var ipPolicyModelMap: [String: TimeInterval?] = [:]
        var clearCacheBlock: (([String]) -> Void)?
        private var timer: Timer?
        private let delayTime: Int
        private let pollingTime: Int

        let userResolver: UserResolver

        init(userResolver: UserResolver) throws {
            self.userResolver = userResolver
            settings = try userResolver.resolve(assert: SCSettingService.self)
            modelFactory = try userResolver.resolve(assert: PolicyModelFactory.self)
            delayTime = settings.int(.fileStrategyDelayCleanTime)
            pollingTime = settings.int(.fileStrategyDelayCleanInaccuracy)
            modelFactory.ipModels.forEach { ipPolicyModelMap.updateValue(nil, forKey: $0.taskID) }
            let notificationCenter = try userResolver.resolve(assert: SecurityUpdateNotificationCenterService.self)
            notificationCenter.registeObserver(observer: self)
        }

        private func removeSuccessUpdatedPolicyModel(successPolicyModel: [PolicyModel]) {
            if self.timer == nil { return }
            successPolicyModel.forEach {
                guard self.ipPolicyModelMap[$0.taskID] != nil else { return }
                self.ipPolicyModelMap.updateValue(nil, forKey: $0.taskID)
            }
            self.cancelTimerIfNeed()
        }

        private func updatePolicyTimeStamp() {
            let currentTime = Self.ntpTime
            self.ipPolicyModelMap.forEach { policyModelPair in
                let policyModel = policyModelPair.key
                guard policyModelPair.value != nil else {
                    self.ipPolicyModelMap.updateValue(currentTime, forKey: policyModel)
                    return
                }
            }
            self.fireTimerIfNeed()
        }

        private func fireTimerIfNeed() {
            guard timer == nil else { return }
            SecurityPolicy.logger.info("security policy: delay clear cache manager: timer is start")
            self.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(pollingTime), repeats: true) { [weak self] _ in
                SecurityPolicy.logger.info("security policy: delay clear cache manager: timer finish tic")
                guard let self else { return }
                self.clearCacheBlock?(self.removeNeededCleanPolicyModel())
            }
        }

        private func cancelTimerIfNeed() {
            if let timer = self.timer,
               !self.isPolicyModelNeedClear() {
                timer.invalidate()
                self.timer = nil
                SecurityPolicy.logger.info("security policy: delay clear cache manager: all policy model is updated, timer is cancled")
            }
        }

        private func updateIPPolicyModelMap(newIPInfo: [PolicyModel]) {
            ipPolicyModelMap = newIPInfo.reduce(into: [String: TimeInterval?](), { result, element in
                guard let timeStamp = ipPolicyModelMap[element.taskID] else {
                    result.updateValue(nil, forKey: element.taskID)
                    return
                }
                result.updateValue(timeStamp, forKey: element.taskID)
            })
        }

        private func removeNeededCleanPolicyModel() -> [String] {
            let currentTime = Self.ntpTime
            let neededUpdateTaskID = ipPolicyModelMap.compactMap { policyModelPair -> String? in
                guard let timeStamp = policyModelPair.value else { return nil }
                let taskID = policyModelPair.key
                let delta = currentTime - timeStamp
                if Int(fabs(delta)) >= delayTime {
                    self.ipPolicyModelMap.updateValue(nil, forKey: taskID)
                    return taskID
                }
                return nil
            }
            cancelTimerIfNeed()
            return neededUpdateTaskID
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
                SecurityPolicy.logger.error("security policy: failed to get ntp time")
                return Date().timeIntervalSince1970
            }
        }
    }
}

extension SecurityPolicyV2.DelayClearCacheManager: SecurityUpdateObserver {
    func notify(trigger: SecurityPolicyV2.UpdateTrigger) {
        SecurityPolicy.logger.info("security policy: security_policy_manager: get update cache signal from trigger:\(trigger)")
        switch trigger {
        case .networkChange, .becomeActive, .constructor:
            updatePolicyTimeStamp()
        default:
            break
        }
        updateIPPolicyModelMap(newIPInfo: modelFactory.ipModels)
    }
}

extension SecurityPolicyV2.DelayClearCacheManager: StrategyEngineCallerObserver {
    func notify(validateResult: SecurityPolicyV2.StrategyEngineCallerObserverParam) {
        let (successed, _) = validateResult.successdAndFailedPolicyModels
        removeSuccessUpdatedPolicyModel(successPolicyModel: successed)
    }
}
