//
//  Authorization.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/11/15.
//

import Foundation
import LarkAccountInterface
import LarkSecurityComplianceInterface
import LarkCache
import LarkContainer
import LarkSecurityComplianceInfra

public struct SecurityPolicyV2 {
    public final class SecurityPolicyIMP: SecurityPolicyService {
        let manager: SecurityPolicyManager
        let settings: SCSettingService
        let resolver: UserResolver

        init(resolver: UserResolver) throws {
            let startInitTime = CACurrentMediaTime()
            self.resolver = resolver
            self.manager = try SecurityPolicyManager(resolver: resolver)
            self.settings = try resolver.resolve(assert: SCSettingService.self)
            let duration = CACurrentMediaTime() - startInitTime
            SecurityPolicyEventTrack.scsSecurityPolicyInit(duration: duration)
            SecurityPolicyEventTrack.scsSecurityPolicyInitVersion()
        }

        public func config() {
            let cleanTask: (() -> CleanTask) = { [weak self] () -> CleanTask in
                guard let self else { return SecurityPolicyEmptyCleanTask() }
                return SecurityPolicyCleanTask(resolver: self.resolver)
            }
            CleanTaskRegistry.register(cleanTask: cleanTask())
    #if SECURITY_DEBUG
            _ = try? resolver.resolve(type: SecurityPolicyDebugService.self)
    #endif
            let reporter = try? resolver.resolve(assert: LogReportService.self) as? LogReporter
            reporter?.config()
            _ = try? resolver.resolve(assert: SecurityUpdateNotificationCenterService.self)
        }

        public func cacheValidate(policyModel: PolicyModel,
                                  authEntity: AuthEntity? = nil,
                                  config: ValidateConfig? = nil) -> ValidateResult {
            let internalConfig = config ?? ValidateConfig()
            let validateResult = manager.checkSecurityPolicy(policyModel: policyModel, authEntity: authEntity, config: internalConfig)
            SecurityPolicyEventTrack.larkSCSSecuritySDKResult(resultGroups: [policyModel: validateResult], function: .cacheValidate, additional: internalConfig.logData)
            return validateResult
        }

        public func asyncValidate(policyModel: PolicyModel,
                                  authEntity: AuthEntity? = nil,
                                  config: ValidateConfig? = nil,
                                  complete: @escaping (ValidateResult) -> Void) {
            let internalConfig = config ?? ValidateConfig()
            self.manager.checkSecurityPolicy(policyModel: policyModel, authEntity: authEntity, config: internalConfig) { validateResult in
                SecurityPolicyEventTrack.larkSCSSecuritySDKResult(resultGroups: [policyModel: validateResult], function: .asyncValidate, additional: internalConfig.logData)
                complete(validateResult)
            }
        }

        public func asyncValidate(policyModels: [PolicyModel],
                                  config: ValidateConfig?,
                                  complete: @escaping ([String: ValidateResult]) -> Void) {
            let internalConfig = config ?? ValidateConfig()
            self.manager.checkSecurityPolicy(policyModels: policyModels, config: internalConfig) { validateMap in
                complete(validateMap)
            }
        }

        public func showInterceptDialog(policyModel: PolicyModel) {
            DispatchQueue.runOnMainQueue {
                self.manager.showInterceptDialog(policyModel: policyModel)
            }
        }

        public func isEnableFastPass(policyModel: PolicyModel) -> Bool {
            manager.isEnableFastPass(policyModel: policyModel)
        }

        public func handleSecurityAction(securityAction: SecurityActionProtocol) {
            DispatchQueue.runOnMainQueue {
                let decision = try? self.resolver.resolve(assert: SecurityPolicyActionDecision.self)
                decision?.handleAction(securityAction)
            }
        }

        public func dlpMaxDetectingTime() -> Int {
            settings.int(SCSettingKey.dlpMaxCheckTime)
        }
    }

}
