//
//  SecurityRetryManager.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/12/5.
//

import Foundation
import LKCommonsLogging
import ServerPB
import LarkSecurityComplianceInterface
import LarkPolicyEngine
import LarkContainer
import LarkSecurityComplianceInfra

extension SecurityPolicyV2 {
    final class SecurityPolicyRetryManager: UserResolverWrapper {
        private var currentRetryTask: SecurityPolicyRetryTask?
        private(set) var retryList: [PolicyModel: Int] = [:]
        private let retryTime: Int
        private let delayTime: Int

        var retryBlock: (() -> Void)?

        let userResolver: UserResolver

        init(userResolver: UserResolver) throws {
            self.userResolver = userResolver
            let settings = try userResolver.resolve(assert: SCSettingService.self)
            retryTime = settings.int(.fileStrategyRetryMaxCount)
            delayTime = settings.int(.fileStrategyRetryDelayTime)
        }

        private func retryAuthPolicyModels(failList: [PolicyModel],
                                   trigger: StrategyEngineCallTrigger) {
            switch trigger {
            case .retry:
                self.minusRetryList(list: failList)
            default:
                self.refiltedRetryList(list: failList)
                if self.currentRetryTask == nil { break }
                return
            }
            let loggerMsg = "security policy: security policy retry manager: receive retry signal, trigger is \(trigger)"
            if self.retryList.isEmpty {
                SecurityPolicy.logger.info(loggerMsg + ",not need to retry")
                return
            }
            SecurityPolicy.logger.info(loggerMsg)
            self.currentRetryTask = SecurityPolicyRetryTask()
            self.currentRetryTask?.retryBlock = self.retryBlock
            self.currentRetryTask?.retryAuthPolicyModels(delayTime: self.delayTime)
        }

        func clearRetryTask() {
            if self.currentRetryTask != nil {
                SecurityPolicy.logger.info("security policy: security policy retry manager: clean current retry task")
            }
            self.currentRetryTask = nil

        }

        private func updateRetryList(successList: [PolicyModel]) {
            successList.forEach {
                self.retryList.removeValue(forKey: $0)
            }
            if self.retryList.isEmpty {
                SecurityPolicy.logger.info("security policy: security policy retry manager: retry list is empty, stop retry")
                self.clearRetryTask()
            }

        }

        private func minusRetryList(list: [PolicyModel]) {
            if retryList.isEmpty { return }
            list.forEach {
                if var count = retryList[$0] {
                    count -= 1
                    // swiftlint:disable empty_count
                    if count == 0 {
                        retryList.removeValue(forKey: $0)
                        return
                    }
                    // swiftlint:enable empty_count
                    // 这个写法如果 retry 配的是负数会有问题，有机会修复一下
                    retryList.updateValue(count, forKey: $0)
                }
            }
        }

        private func refiltedRetryList(list: [PolicyModel]) {
            list.forEach {
                // TODO: 可以简化成一行
                if retryList[$0] != nil {
                    retryList.updateValue(retryTime, forKey: $0)
                    return
                }
                retryList[$0] = retryTime
            }

        }
    }
}

extension SecurityPolicyV2.SecurityPolicyRetryManager: StrategyEngineCallerObserver {
    func notify(validateResult: SecurityPolicyV2.StrategyEngineCallerObserverParam) {
        let (succeussedModels, failedModels) = validateResult.successdAndFailedPolicyModels
        updateRetryList(successList: succeussedModels)
        retryAuthPolicyModels(failList: failedModels, trigger: validateResult.trigger)
    }
}

extension SecurityPolicyV2 {
    final class SecurityPolicyRetryTask {
        var retryBlock: (() -> Void)?
        func retryAuthPolicyModels(delayTime: Int) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delayTime)) { [weak self] in
                guard let self else { return }
                self.retryBlock?()
            }
        }
    }
}
