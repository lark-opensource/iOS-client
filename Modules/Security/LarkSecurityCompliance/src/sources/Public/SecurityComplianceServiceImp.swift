//
//  SecurityComplianceService.swift
//  SecurityComplianceServiceImp
//
//  Created by qingchun on 2022/5/25.
//

import LarkContainer
import LarkSecurityComplianceInfra
import LarkSecurityComplianceInterface

final class SecurityComplianceServiceImp: SecurityComplianceService, UserResolverWrapper {

    let userResolver: UserResolver

    init(resolver: UserResolver) {
        userResolver = resolver
    }

    var state: NoPermissionState {
        if let service = try? userResolver.resolve(assert: NoPermissionService.self),
            let vc = service.currentVC as? NoPermissionViewController {
            return actionToState(vc.viewModel.model.action)
        }
        return .idle
    }

    func actionToState(_ action: NoPermissionRustActionModel.Action) -> NoPermissionState {
        switch action {
        case .deviceCredibility, .network, .deviceOwnership, .mfa:
            return .limited
        case .fileblock, .pointDowngrade, .universalFallback, .dlp, .ttBlock, .unknown:
            return .idle
        }
    }
}
