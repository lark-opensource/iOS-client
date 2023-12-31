//
//  NoPermissionRustActionDecision.swift
//  LarkSecurityAndCompliance
//
//  Created by qingchun on 2022/4/8.
//

import Foundation
import LarkContainer
import LarkSecurityComplianceInfra
import LarkSecurityComplianceInterface

protocol NoPermissionRustActionDecision {
    func handleAction(_ model: NoPermissionRustActionModel)
}

let noPermissionCode = 100_000

final class NoPermissionRustActionDecisionImp: NoPermissionRustActionDecision, UserResolverWrapper {

    private var handlers = [NoPermissionRustActionModel.Action: NoPermissionRustActionHandler]()
    @ScopedProvider private var interceptor: NoPermissionActionInterceptor?
    @ScopedProvider private var service: NoPermissionService?
    private var internalInterceptor: NoPermissionActionInterceptorImp? { return interceptor as? NoPermissionActionInterceptorImp }
    let userResolver: UserResolver

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func handleAction(_ actionModel: NoPermissionRustActionModel) {
        let isViewShowing = service?.isNoPermissionViewShowing ?? false
        let isIntercepted = (internalInterceptor?.handleModelAction(actionModel)).isTrue
        if !isViewShowing && isIntercepted {
            return
        }
        if actionModel.code == noPermissionCode {
            guard let handler = getHandlerWithAction(actionModel.action) else {
                SecurityPolicyEventTrack.larkSCSUnknownAction(actionName: actionModel.model?.name ?? "NO_ACTION")
                return
            }
            try? handler.execute(with: actionModel, resolver: userResolver)
        }
    }

    private func getHandlerWithAction(_ action: NoPermissionRustActionModel.Action) -> NoPermissionRustActionHandler? {
        if let handler = handlers[action] {
            return handler
        } else {
            let handler: NoPermissionRustActionHandler? = {
                switch action {
                case .network:
                    return NoPermissionRustActionNetworkHandler()
                case .deviceOwnership:
                    return NoPermissionRustActionDeviceOwnershipHandler()
                case .deviceCredibility:
                    return NoPermissionRustActionDeviceCredibilityHandler()
                case .mfa:
                    return NoPermissionRustActionMFAHandler()
                case .fileblock:
                    return SecurityPolicyFileBlockHandler()
                case .dlp:
                    return SecurityPolicyDLPHandler()
                case .pointDowngrade:
                    return SecurityPolicyPointDowngradeHandler()
                case .universalFallback:
                    return SecurityPolicyUniversalFallbackHandler()
                case .ttBlock:
                    return SecurityPolicyTTCrossTenantSpreadHandler()
                case .unknown:
                    return nil
                }
            }()
            handlers[action] = handler
            return handler
        }
    }
}
