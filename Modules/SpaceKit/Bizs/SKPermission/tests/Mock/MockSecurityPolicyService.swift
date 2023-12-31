//
//  MockSecurityPolicyService.swift
//  SKPermission-Unit-Tests
//
//  Created by Weston Wu on 2023/4/24.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkContainer

class MockSecurityPolicyService: SecurityPolicyService {

    var result = ValidateResult(userResolver: Container.shared.getCurrentUserResolver(compatibleMode: true),
                                result: .unknown,
                                extra: ValidateExtraInfo(resultSource: .unknown,
                                                         errorReason: nil,
                                                         resultMethod: nil))

    func cacheValidate(policyModel: PolicyModel, authEntity: AuthEntity?, config: ValidateConfig?) -> ValidateResult {
        return result
    }

    func asyncValidate(policyModel: PolicyModel, authEntity: AuthEntity?, config: ValidateConfig?, complete: @escaping (ValidateResult) -> Void) {
        complete(result)
    }

    func asyncValidate(policyModels: [PolicyModel], config: ValidateConfig?, complete: @escaping ([String : ValidateResult]) -> Void) {
        complete([:])
    }

    func showInterceptDialog(policyModel: PolicyModel) {}

    func isEnableFastPass(policyModel: PolicyModel) -> Bool { false }

    func config() {}

    func clearStrategyAuthCache() {}

    func getCache() -> String { "" }

    func getRetryList() -> String { "" }

    func getIPList() -> String { "" }

    func getStaticCache() -> String { "" }

    func getSceneCache() -> String { "" }

    func handleSecurityAction(securityAction: LarkSecurityComplianceInterface.SecurityActionProtocol) {
        
    }
    func dlpMaxDetectingTime() -> Int { 0 }
}
