//
//  EMMInternalServiceImp.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/10/27.
//

import LarkEMM
import LarkWaterMark
import LarkSecurityComplianceInfra
import LarkContainer

final class InternalServiceImp: LarkEMMInternalService, UserResolverWrapper {

    let userResolver: UserResolver

    init(resolver: UserResolver) {
        userResolver = resolver
    }

    func onWaterMarkViewCovered(_ window: UIWindow) {
        let waterMarkService = try? userResolver.resolve(assert: WaterMarkService.self)
        waterMarkService?.onWaterMarkViewCoveredWithContext(.some(window: window))
    }
}
