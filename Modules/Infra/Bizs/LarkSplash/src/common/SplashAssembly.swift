//
//  SplashAssembly.swift
//  LarkSplash
//
//  Created by 王元洵 on 2020/10/19.
//

import Foundation
import BootManager
import AppContainer
import Swinject
import LarkAccountInterface
import LarkAssembler

// MARK: - Assembly
public final class SplashAssembly: LarkAssemblyInterface {
    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(SplashLaunchTask.self)
        NewBootManager.register(SplashIdleTask.self)
    }

    public func registLauncherDelegate(container: Container) {
        (LauncherDelegateFactory {
            SplashAccountDelegate()
        }, LauncherDelegateRegisteryPriority.low)
    }

    public func registBootLoader(container: Container) {
        (SplashApplicationDelegate.self, DelegateLevel.default)
    }
}
