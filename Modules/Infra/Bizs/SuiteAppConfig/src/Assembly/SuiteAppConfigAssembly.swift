//
//  SuiteAppConfigAssembly.swift
//  SuiteAppConfig
//
//  Created by Yiming Qu on 2021/2/2.
//

import Foundation
import Swinject
import LarkAccountInterface
import LarkAssembler

public final class SuiteAppConfigAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        container.register(AppConfigService.self) { _ -> AppConfigService in
            return AppConfigManager.shared
        }
    }

    public func registLauncherDelegate(container: Container) {
        (LauncherDelegateFactory(delegateProvider: {
            SuiteAppConfigLauncherDelegate()
        }), LauncherDelegateRegisteryPriority.low)
    }
}
