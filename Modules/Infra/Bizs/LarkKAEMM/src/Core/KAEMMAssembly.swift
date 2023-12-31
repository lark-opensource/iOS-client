//
//  KAEMMAssembly.swift
//  LarkKAEMM
//
//  Created by Crazy凡 on 2021/9/6.
//

import Foundation
import Swinject
import EENavigator
import LarkAccountInterface
#if canImport(SangforSDK)
import BootManager
#endif
import LKCommonsLogging
import LarkAssembler
/// LarkKAEMM 集成入口
public final class KAEMMAssembly: Assembly, LarkAssemblyInterface {
    private static let logger = Logger.log(KAEMMAssembly.self, category: "Module.KAEMMAssembly")

    public init() {}

    public func assemble(container: Container) {
        #if !IS_NOT_DEFAULT
        Self.logger.info("KAEMM: Skip init")
        #else
        Self.logger.info("KAEMM: Normal init")
        #endif

        registLaunch(container: container)
        registContainer(container: container)
        registLauncherDelegate(container: container)
    }

    public func registLaunch(container: Container) {
        #if !IS_NOT_DEFAULT
        #else
        #if canImport(SangforSDK)
        NewBootManager.register(KAVPNInitTask.self)
        #endif
        #endif
    }

    public func registContainer(container: Container) {
        #if !IS_NOT_DEFAULT
        #else
        container.register(KAVPNWrapperInterface.self) { _ -> KAVPNWrapperInterface in
            return KAVPNWrapper()
        }.inObjectScope(.user)
        #endif
    }

    public func registLauncherDelegate(container: Container) {
        (LauncherDelegateFactory {
            KAEMMCustomLauncherDelegate(container: container)
        }, LauncherDelegateRegisteryPriority.middle)
        #if !IS_NOT_DEFAULT
        #else
        (LauncherDelegateFactory {
            KAEMMLauncherDelegate(container: container)
        }, LauncherDelegateRegisteryPriority.middle)
        #endif
    }
}
