//
//  WorkplaceAssembly.swift
//  WorkplaceMod
//
//  Created by Meng on 2022/6/14.
//

import Foundation
import Swinject
import LarkAssembler
import LarkWorkplace
import LarkContainer
import EENavigator

#if MessengerMod
import LarkForward
#endif

public final class WorkplaceAssembly: LarkAssemblyInterface {
    public init() {}

    public func getSubAssemblies() -> [LarkAssemblyInterface]? {
        return [
            LarkWorkplaceAssembly()
        ]
    }

    public func registContainer(container: Container) {
        let user = container.inObjectScope(WorkplaceScope.userScope)
        // let userGraph = container.inObjectScope(WorkplaceScope.userGraph)

        user.register(WorkPlaceDependency.self) { r in
            return WorkplaceDependencyImpl(userResolver: r)
        }
    }

#if MessengerMod
    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(WorkplaceForwardBlockBody.self).factory(WorkplaceForwardBlockHandler.init(resolver:))
    }

    @_silgen_name("Lark.LarkForward_LarkForwardMessageAssembly_regist.WorkplaceAssembly")
    public static func providerRegister() {
        ForwardAlertFactory.register(type: WorkplaceForwardBlockProvider.self)
    }
#endif
}
