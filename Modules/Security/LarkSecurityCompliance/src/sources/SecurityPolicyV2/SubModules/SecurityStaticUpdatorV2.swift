//
//  SecurityStaticUpdator.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/9/15.
//

import Foundation
import LarkContainer
import LarkSecurityComplianceInfra
import LarkSecurityComplianceInterface

extension SecurityPolicyV2 {
    final class SecurityStaticUpdator {
        private let updateFrequencyManager: LarkSecurityComplianceInfra.Debouncer// 用于控制更新频率
        private let policyModelFactory: PolicyModelFactory
        var updateStaticPolicyModel: (([PolicyModel], SecurityPolicyV2.UpdateTrigger) -> Void)?
        private var isFullUpdate = false

        init(userResolver: UserResolver) throws {
            let settings = try userResolver.resolve(assert: SCSettingService.self)
            let interval = settings.int(.fileStrategyUpdateFrequencyControl)
            policyModelFactory = try userResolver.resolve(assert: PolicyModelFactory.self)
            updateFrequencyManager = LarkSecurityComplianceInfra.Debouncer(interval: TimeInterval(interval))
            let noticeCenter = try userResolver.resolve(assert: SecurityUpdateNotificationCenterService.self)
            noticeCenter.registeObserver(observer: self)
        }
    }
}

extension SecurityPolicyV2.SecurityStaticUpdator: SecurityUpdateObserver {
    func notify(trigger: SecurityPolicyV2.UpdateTrigger) {
        switch trigger {
        case .strategyEngine, .becomeActive, .constructor:
            isFullUpdate = true
        default:
            break
        }
        updateFrequencyManager.callback = { [weak self] in
            guard let self else { return }
            SecurityPolicy.logger.info("security policy: security_policy_manager: get update cache signal from trigger: \(trigger), start update static cache")
            let needUpdateModel = self.isFullUpdate ? self.policyModelFactory.staticModels : self.policyModelFactory.ipModels
            self.updateStaticPolicyModel?(needUpdateModel, trigger)
            self.isFullUpdate = false
        }
        updateFrequencyManager.call()
    }
}
