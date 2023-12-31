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

final class SecurityPolicyRetryManager: UserResolverWrapper {
    private var currentRetryTask: SecurityPolicyRetryTask?
    @ScopedProvider private var settings: Settings?
    var retryList: [PolicyModel: Int] = [:]

    private var retryTime: Int { settings?.fileStrategyRetryMaxCount ?? 2 }

    private var delayTime: Int { settings?.fileStrategyRetryDelayTime ?? 5 }

    var retryBlock: (() -> Void)?

    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func retryAuthPolicyModels(failList: [PolicyModel],
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
            SPLogger.info(loggerMsg + ",not need to retry")
            return
        }
        SPLogger.info(loggerMsg)
        self.currentRetryTask = SecurityPolicyRetryTask()
        self.currentRetryTask?.retryBlock = self.retryBlock
        self.currentRetryTask?.retryAuthPolicyModels(delayTime: self.delayTime)
    }

    func clearRetryTask() {
        if self.currentRetryTask != nil {
            SPLogger.info("security policy: security policy retry manager: clean current retry task")
        }
        self.currentRetryTask = nil

    }

    func updateRetryList(successList: [PolicyModel]) {
        if self.retryList.isEmpty { return }
        if successList.isEmpty { return }
        successList.forEach {
            self.retryList.removeValue(forKey: $0)
        }
        if self.retryList.isEmpty {
            SPLogger.info("security policy: security policy retry manager: retry list is empty, stop retry")
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
                retryList.updateValue(count, forKey: $0)
            }
        }
    }

    private func refiltedRetryList(list: [PolicyModel]) {
        list.forEach {
            if retryList[$0] != nil {
                retryList.updateValue(retryTime, forKey: $0)
                return
            }
            retryList[$0] = retryTime
        }

    }
}

final class SecurityPolicyRetryTask {
    var retryBlock: (() -> Void)?
    func retryAuthPolicyModels(delayTime: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delayTime)) { [weak self] in
            guard let self else { return }
            self.retryBlock?()
        }
    }
}
