//
//  LarkMessageCardAssembly.swift
//  LarkMessageCard
//
//  Created by ByteDance on 2022/11/28.
//

import Foundation
import LarkAssembler
import BootManager
import Swinject
import LarkRustClient
import LarkFeatureGating
import LarkSetting
import UniversalCardInterface
import UniversalCardBase

public final class LarkMessageCardAssembly: LarkAssemblyInterface {

    public init() {}

    public func registLaunch(container:Container) {
        // FG 不开, 不执行 Task
        NewBootManager.register(SetupLarkMessageCardTask.self)
    }
    
    public func registServerPushHandler(container: Container) {
        
    }
    
    public func registContainer(container: Container) {
        container.register(MessageCardContextManagerProtocol.self) { (_) ->
            MessageCardContextManagerProtocol in
            return MessageCardContextManager()
        }.inObjectScope(.container)
        
        container.register(MessageCardEnvService.self) { (_) ->
            MessageCardEnvService in
            return MessageCardEnvironment()
        }.inObjectScope(.container)

        container.register(MessageCardLayoutService.self) { (_) ->
            MessageCardLayoutService in
            return MessageCardLayout()
        }.inObjectScope(.container)
    }

}
