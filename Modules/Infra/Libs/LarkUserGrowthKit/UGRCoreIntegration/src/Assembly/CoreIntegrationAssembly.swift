//
//  CoreIntegrationAssembly.swift
//  UGRCoreIntegration
//
//  Created by shizhengyu on 2021/3/2.
//

import Foundation
import AppContainer
import LKCommonsLogging
import Swinject
import LarkRustClient
import LarkAccountInterface
import UGContainer
import UGRule
import UGCoordinator
import LarkAssembler
import LarkNavigator

// MARK: - Assembly
public final class CoreIntegrationAssembly: LarkAssemblyInterface {
    public init() {}

    static let log = Logger.log(CoreIntegrationAssembly.self, category: "ug.reach.assembly")

    public func registContainer(container: Container) {
        let user = container.inObjectScope(.userV2)
        let userGraph = container.inObjectScope(.userGraph)

        user.register(UGReachAPI.self) { (r) -> UGReachAPI in
            let rustClient = try r.resolve(assert: RustService.self)
            return RustUGReachAPI(client: rustClient, scheduler: scheduler)
        }

        user.register(ReachCoreService.self) { (r) -> ReachCoreService in
            return CoreDispatcher(userResolver: r, reachAPI: try r.resolve(assert: UGReachAPI.self))
        }

        userGraph.register(PluginContainerDependency.self) { (r) -> PluginContainerDependency in
            let coreService = try r.resolve(assert: ReachCoreService.self)
            return PluginContainerDependencyImpl(coreService: coreService)
        }

        user.register(PluginContainerService.self) { (r) -> PluginContainerService in
            let dependency = try r.resolve(assert: PluginContainerDependency.self)
            return PluginContainerServiceImpl(dependency: dependency, navigator: r.navigator)
        }

        user.register(UGRuleService.self) { (_) -> UGRuleService in
            return UGRuleManager()
        }

        user.register(UGCoordinatorService.self) { (r) -> UGCoordinatorService in
            return UGCoordinatorManager(userResolver: r)
        }
    }

    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushUgScenarioInfo, PushScenarioInfoHandler.init(resolver:))
    }
}
