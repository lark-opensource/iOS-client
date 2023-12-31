//
//  SecurityPolicyValidateResultCache.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/8/8.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkPolicyEngine
import LarkContainer

extension SecurityPolicyValidateResultCache: ValidateResultProtocol {
    var uuid: String {
        return validateResponse.uuid
    }
    
    var policySetKeys: [String]? {
        return validateResponse.policySetKeys
    }
    
    var canReport: Bool {
        return validateResponse.type == .local || validateResponse.type == .remote
    }
    
    func validateResult(userResolver: UserResolver, logInfos: [ValidateLogInfo]) -> ValidateResult {
        let allow = validateResponse.allow ? ValidateResultType.allow : ValidateResultType.deny
        let source = validateResponse.actions.first?.validateResource ?? .unknown
        let result = ValidateResult(userResolver: userResolver, result: allow,
                                    extra: ValidateExtraInfo(resultSource: source,
                                                             errorReason: nil,
                                                             resultMethod: resultMethod,
                                                             isCredible: isCredible,
                                                            logInfos: logInfos,
                                                            rawActions: rawActions))
        return result
    }

    var isCredible: Bool {
        if let expirationTime = expirationTime, expirationTime < CACurrentMediaTime() {
            return false
        }
        return !self.needDelete.isTrue
        && validateResponse.type.validateResultMethod != .downgrade
        && validateResponse.type.validateResultMethod != .fallback
    }
    
    var isAllow: Bool {
        return validateResponse.allow
    }
    
    var shouldFallback: Bool {
        return false
    }
    
    var actions: [Action] {
        return validateResponse.actions
    }
    
    var resultMethod: ValidateResultMethod {
        return .cache
    }
    
    private var rawActions: String {
        guard let actionModel = actions.first?.rustActionModel else {
            return ""
        }
        return actionModel.rawActionModelString
    }
}
