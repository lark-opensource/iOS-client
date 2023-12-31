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
        let reporter = try? resolver.resolve(assert: LogReportService.self) as? SecurityPolicy.LogReporter
        reporter?.config()
    }

    public func cacheValidate(policyModel: PolicyModel,
                              authEntity: AuthEntity? = nil,
                              config: ValidateConfig? = nil) -> ValidateResult {
        let validateResult = manager.checkSecurityPolicy(policyModel: policyModel, authEntity: authEntity, config: config ?? ValidateConfig())
        return validateResult
    }

    public func asyncValidate(policyModel: PolicyModel,
                              authEntity: AuthEntity? = nil,
                              config: ValidateConfig? = nil,
                              complete: @escaping (ValidateResult) -> Void) {
        manager.checkSecurityPolicy(policyModel: policyModel, authEntity: authEntity, config: config ?? ValidateConfig()) { validateResult in
            complete(validateResult)
        }
    }

    public func asyncValidate(policyModels: [PolicyModel],
                              config: ValidateConfig?,
                              complete: @escaping ([String: ValidateResult]) -> Void) {
        manager.checkSecurityPolicy(policyModels: policyModels, config: config ?? ValidateConfig()) { validateMap in
            complete(validateMap)
        }
    }

    public func showInterceptDialog(policyModel: PolicyModel) {
        manager.showInterceptDialog(policyModel: policyModel)
    }

    public func isEnableFastPass(policyModel: PolicyModel) -> Bool {
        manager.isEnableFastPass(policyModel: policyModel)
    }

    func markSceneCacheDeletable() {
        manager.markSceneCacheDeletable()
        SPLogger.info("security policy mark result cache need deleted")
    }

    public func handleSecurityAction(securityAction: SecurityActionProtocol) {
        DispatchQueue.main.async {
            if let fgService = try? self.resolver.resolve(assert: SCFGService.self),
               fgService.realtimeValue(.enableSecurityUserContainerOpt) {
                let decision = try? self.resolver.resolve(assert: SecurityPolicyActionDecision.self)
                decision?.handleAction(securityAction)
            } else {
                @Provider var decision: SecurityPolicyActionDecision  // global
                decision.handleAction(securityAction)
            }
        }
    }
    
    public func dlpMaxDetectingTime() -> Int {
        settings.int(SCSettingKey.dlpMaxCheckTime)
    }
}
