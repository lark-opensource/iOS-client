//
//  SecurityPolicyPreProcess.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/9/19.
//

import Foundation
import LarkAccountInterface
import LarkContainer
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra

struct SecurityPolicyPreProcess {
    let settings: SCSettingService
    let fg: SCFGService

    init(userResolver: UserResolver) throws {
        settings = try userResolver.resolve(assert: SCSettingService.self)
        fg = try userResolver.resolve(assert: SCFGService.self)
    }
    
    func check(policyModel: PolicyModel,
               config: ValidateConfig) -> Bool {
        if settings.bool(.disableFileOperate) {
            SecurityPolicy.logger.info("security policy: settings disable file operate is open", additionalData: config, policyModel)
            return false
        }

        if settings.bool(.disableFileStrategy) {
            SecurityPolicy.logger.info("security policy: settings disable file strategy is open", additionalData: config, policyModel)
            return false
        }

        if policyModel.pointKey == .imFileRead,
           settings.bool(.disableFileStrategyShare) {
            SecurityPolicy.logger.info("security policy: settings disable file strategy share is open", additionalData: config, policyModel)
            return false
        }
        // security policy temporarily exempt VC until VC access
        if let vcEntity = policyModel.entity as? VCFileEntity,
           vcEntity.fileBizDomain == .vc {
            SecurityPolicy.logger.info("security policy: vc entity pass", additionalData: config, policyModel)
            return false
        }

        return true
    }
}
