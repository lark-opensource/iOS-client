//
//  PolicyEngineAssembly.swift
//  LarkSecurityCompliance
//
//  Created by 汤泽川 on 2022/10/14.
//

import Foundation
import LarkAssembler
import Swinject
import LarkPolicyEngine
import LarkContainer
import LarkAccountInterface
import LarkSnCService
import CommonCrypto
import ByteDanceKit
import LarkSecurityComplianceInfra

public protocol SensitivityControlSnCService: SnCService { }

extension LarkPSDAServiceImpl: SensitivityControlSnCService { }

final class PolicyEngineAssembly: LarkAssemblyInterface {

    func registContainer(container: Container) {
        let userContainer = container.inObjectScope(SCContainerSettings.userScope)
        userContainer.register(PolicyEngineSnCService.self) { resolver in
            let userService = try resolver.resolve(assert: PassportUserService.self)
            return PolicyEngineSnCServiceImpl(userID: userService.user.userID)
        }

        userContainer.register(PolicyEngineService.self) { resolver in
            guard let service = try? resolver.resolve(assert: PolicyEngineSnCService.self) else {
                assertionFailure("PolicyEngineSnCService can not be nil.")
                throw ContainerError.noResolver
            }
            let engine = PolicyEngine(service: service)
            Self.configStrategyEngine(engine: engine)
            return engine
        }
    }

    private static func configStrategyEngine(engine: PolicyEngineService) {
        engine.register(parameter: Parameter(key: "DEVICE_TERMINAL", value: {
            return 4
        }))
        engine.register(parameter: Parameter(key: "DEVICE_OS", value: {
            return 5
        }))
    }
}
