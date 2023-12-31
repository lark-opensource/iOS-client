//
//  LeanModeAssembly.swift
//  LarkLeanMode
//
//  Created by 袁平 on 2020/3/1.
//

import Foundation
import Swinject
import RustPB
import LarkContainer
import LarkRustClient
import LarkSetting
import BootManager
import LarkAssembler
import LarkAccountInterface

public final class LeanModeAssembly: LarkAssemblyInterface {

    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(LeanModeLaunchTask.self)
    }

    public func registContainer(container: Container) {
        let user = container.inObjectScope(.userV2)

        user.register(LeanModeAPI.self) { (resolver) -> LeanModeAPI in
            let rustService = try resolver.resolve(assert: RustService.self)
            return RustLeanModeAPI(client: rustService, userID: resolver.userID)
        }

        user.register(LeanModeService.self) { (resolver) -> LeanModeService in
            let leanModeAPI = try resolver.resolve(assert: LeanModeAPI.self)
            let dependency = try resolver.resolve(assert: LeanModeDependency.self)
            let passportService = try resolver.resolve(assert: PassportUserService.self)
            let fgService = try resolver.resolve(assert: FeatureGatingService.self)
            return LeanModeServiceImpl(userResolver:resolver,
                                       leanModeAPI: leanModeAPI,
                                       leanModeDependency: dependency,
                                       passportService: passportService,
                                       fgService: fgService)
        }
    }

    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushLeanModeStatusAndAuthority, LeanModeStatusPushHandler.init(resolver:))
        (Command.pushLeanModePatchTaskFailed, LeanModeSwitchFailedPushHandler.init(resolver:))
        (Command.pushCleanData, LeanModeDataCleanPushHandler.init(resolver:))
    }
}
