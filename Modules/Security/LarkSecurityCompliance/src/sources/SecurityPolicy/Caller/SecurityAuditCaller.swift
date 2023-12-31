//
//  SecurityAuditCaller.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/11/16.
//

import Foundation
import LarkSecurityAudit
import LarkContainer
import LarkSecurityComplianceInterface

final class SecurityAuditCaller {
    private let securityAudit = SecurityAudit()
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    func checkAuth(params: AuthEntity) -> ValidateResult {
        let securityAuditResult = securityAudit.checkAuthWithErrorType(permType: params.permType, object: params.entity)
        let validaterResult = wrapAuditAuthResult(auditAuthResult: securityAuditResult)
        return validaterResult
    }

    private func wrapAuditAuthResult(auditAuthResult: (AuthResult, AuthResultErrorReason?)) -> ValidateResult {
        let (authResult, authErrorInfo) = auditAuthResult
        let result = authResult.validateResultType
        let extra = ValidateExtraInfo(resultSource: .securityAudit,
                                      errorReason: authErrorInfo?.validateErrorReason,
                                      isCredible: result != .error,
                                      logInfos: [])
        return ValidateResult(userResolver: userResolver, result: result, extra: extra)
    }

}
