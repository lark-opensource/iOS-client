//
//  Assembly.swift
//  LarkPushTokenUploader
//
//  Created by 李晨 on 2020/2/11.
//

import Foundation
import Swinject
import LarkAccountInterface
import AppContainer
import BootManager
import LarkAssembler
import LarkContainer

public final class LarkPushTokenUploaderAssembly: LarkAssemblyInterface {

    public init() {}

    public func registContainer(container: Container) {
        let user = container.inObjectScope(.user(type: .foreground))
        user.register(LarkPushTokenUploaderService.self) { r -> LarkPushTokenUploaderService in
            return LarkPushTokenUploader(userResolver: r)
        }

        user.register(LarkCouldPushUserListService.self) { r -> LarkCouldPushUserListService in
            return LarkCouldPushUserListUploadImp(userResolver: r)
        }

        let backgroundUser = container.inObjectScope(.user(type: .background))
        backgroundUser.register(LarkBackgroundUserResetTokenService.self) { r -> LarkBackgroundUserResetTokenService in
            return LarkBackgroundUserResetTokenServiceImp(userResolver: r)
        }
    }

    public func registBootLoader(container: Container) {
        (RegisteNotificationApplicationDelegate.self, DelegateLevel.default)
    }

    public func registPassportDelegate(container: Container) {
        (PassportDelegateFactory(delegateProvider: {
            RegisterPushDelegate(resolver: container)
        }), PassportDelegatePriority.low)
    }
}
