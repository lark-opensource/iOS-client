//
//  ConfigAssembly.swift
//  LarkAppConfig
//
//  Created by 李晨 on 2019/11/19.
//

import Foundation
import Swinject
import LarkContainer
import LarkRustClient
import LarkEnv
import LarkAssembler

public final class ConfigAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        container.register(AppConfiguration.self) { (_) -> AppConfiguration in
            return ConfigurationManager.shared
        }
    }

    public func registPushHandler(container: Container) {
        getRegistPush(pushCenter: container.pushCenter)
    }

    private func getRegistPush(pushCenter: PushNotificationCenter) -> [Command: RustPushHandlerFactory] {

        let factories: [Command: RustPushHandlerFactory] = [
            // 通用配置下发
            .pushSettings: {
                GeneralConfigSettingsPushHandler(pushCenter: pushCenter)
            }
        ]
        return factories
    }

    @_silgen_name("Lark.LarkEnv_EnvDelegateRegistry_regist.configAssembly")
    public static func assembleEnvDelegate() {
        EnvDelegateRegistry.register(factory: EnvDelegateFactory(delegateProvider: { () -> EnvDelegate in
            LarkAppConfigEnvDelegate()
        }))
    }
}
