//
//  FeelGoodAssembly.swift
//  LarkMagic
//
//  Created by mochangxing on 2020/10/19.
//

import Foundation
import Swinject
import BootManager
import LarkRustClient
import LarkAccountInterface
import LarkLocalizations
import LarkAssembler

public final class MagicAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        let userScope = container.inObjectScope(.userV2)
        userScope.register(LarkMagicConfigAPI.self) { r in
            let rustClient = try r.resolve(assert: RustService.self)
            return LarkRustMagicConfigAPI(client: rustClient, scheduler: scheduler)
        }

        getRegistContainer(container: container)
    }

    private func getRegistContainer(container: Container) -> ServiceEntryProtocol {
        let interceptor = LarkMagicInterceptorManager()
        let userScope = container.inObjectScope(.userV2)
        return userScope.register(LarkMagicService.self) { r in
            interceptor.larkMagicDependency = try r.resolve(assert: LarkMagicDependency.self)
            return LarkMagicServiceImpl(interceptorManager: interceptor, userResolver: r)
        }
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(LarkMagicLaunchTask.self)
    }
}
