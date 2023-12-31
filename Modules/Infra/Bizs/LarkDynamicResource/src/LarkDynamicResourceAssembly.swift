//
//  LarkDynamicResourceAssembly.swift
//  LarkDynamicResource
//
//  Created by Aslan on 2021/4/1.
//

import Foundation
import Swinject
import BootManager
import LarkAssembler
import LarkAccountInterface
import LarkLocalizations

public final class LarkDynamicResourceAssembly: LarkAssemblyInterface {
    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(LarkDynamicResourceTask.self)
        NewBootManager.register(LarkDynamicResourceSyncTask.self)
    }

    public func registLauncherDelegate(container: Container) {
        (LauncherDelegateFactory { LarkDynamicResourceLauncher() }, LauncherDelegateRegisteryPriority.middle)
    }
    
    public func registServerPushHandlerInUserSpace(container: Container) { (.pushTenantBuildResource, DynamicBrandPushHandler.init(resolver:)) }
}

final class LarkDynamicResourceLauncher: LauncherDelegate {
    let name = "LarkDynamicResourceLauncher"

    func beforeLogout() {
        DynamicBrandManager.reset()
        DynamicResourceManager.shared.revert()
        LanguageManager.resetLanguage()
    }
}
