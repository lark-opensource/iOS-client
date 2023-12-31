//
//  SecurityPolicyAssembly.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/8/22.
//

import Foundation
import LarkContainer
import LarkAssembler
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra

public final class SecurityPolicyAssembly: LarkAssemblyInterface {
    public init() { }

    public func registContainer(container: Container) {
        let userContainer = container.inObjectScope(SCContainerSettings.userScope)
        userContainer.register(SecurityPolicyService.self) { resolver in
            guard Self.enableSecurityPolicyV2 else {
                return try SecurityPolicyIMP(resolver: resolver)
            }
            return try SecurityPolicyV2.SecurityPolicyIMP(resolver: resolver)
        }
        userContainer.register(LogReportService.self) { resolver in
            guard Self.enableSecurityPolicyV2 else {
                return try SecurityPolicy.LogReporter(userResolver: resolver)
            }
            return try SecurityPolicyV2.LogReporter(userResolver: resolver)

        }
        userContainer.register(SecurityPolicyActionDecision.self) { resolver in
            guard Self.enableSecurityPolicyV2 else {
                return SecurityPolicyActionDecisionImp(resolver: resolver)
            }
            return SecurityPolicyV2.SecurityPolicyActionDecisionImp(resolver: resolver)
        }
        userContainer.register(SceneEventService.self) { resolver in
            guard Self.enableSecurityPolicyV2 else {
                return SecurityPolicy.EventManager(userResolver: resolver)
            }
            return SecurityPolicyV2.EventManager(userResolver: resolver)
        }
        userContainer.register(SecurityPolicyInterceptService.self) { resolver in
            guard Self.enableSecurityPolicyV2 else {
                return SecurityPolicyInterceptorIMP(resolver: resolver)
            }
            return try SecurityPolicyV2.SecurityPolicyInterceptorIMP(resolver: resolver)
        }
        guard Self.enableSecurityPolicyV2 else {
            // V1 独有
            userContainer.register(SecurityPolicyCacheProtocol.self) { resolver in
                try StrategyEngineSceneCache(resolver: resolver)
            }
            userContainer.register(DLPManagerProtocol.self) { resolver in
                try DLPManager(resolver: resolver)
            }
            userContainer.register(SceneFallbackResultProtocol.self) { resolver in
                SceneFallbackResultManager(userResolver: resolver)
            }
            return
        }
        // V2 独有
        userContainer.register(PolicyModelFactory.self) { resolver in
            try SecurityPolicyV2.PolicyModelFactoryImp(resolver: resolver)
        }
        userContainer.register(SecurityUpdateNotificationCenterService.self) { resolver in
            try SecurityPolicyV2.SecurityUpdateNotificationCenter(userResolver: resolver)
        }
        userContainer.register(SecurityPolicyCacheService.self) { resolver in
            try SecurityPolicyV2.SecurityPolicyCacheManager(resolver: resolver)
        }
        userContainer.register(DLPValidateService.self) { resolver in
            try SecurityPolicyV2.DLPManager(resolver: resolver)
        }
        userContainer.register(FallbackResultProtocol.self) { resolver in
            try SecurityPolicyV2.FallbackResultManager(userResolver: resolver)
        }
        userContainer.register(SecurityPolicyV2.SecurityPolicyCacheMigrator.self) { resolver in
            SecurityPolicyV2.SecurityPolicyCacheMigrator(userResolver: resolver)
        }
    }
}

extension SecurityPolicyAssembly {
    public static let enableSecurityPolicyV2: Bool = {
        let storage = SCKeyValue.globalMMKV(business: .securityPolicy())
        let value = storage.bool(forKey: SettingsImp.CodingKeys.enableSecurityV2.rawValue)
        SCLogger.info("enable_security_v2: \(value)")
        return value
    }()
}
