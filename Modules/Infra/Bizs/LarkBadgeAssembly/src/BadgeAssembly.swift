//
//  BadgeAssembly.swift
//  LarkBadgeAssembly
//
//  Created by su on 2022/5/13.
//

import Foundation
import LarkAccountInterface
import Swinject
import LarkBadge
import LarkAssembler
import BootManager

// MARK: - Assembly
public final class BadgeAssembly: LarkAssemblyInterface {

    public init() {}

    public func registLaunch(container: Container) {
#if DEBUG
        NewBootManager.register(SetupLarkBadgeTask.self)
#endif
    }

    public func registLauncherDelegate(container: Container) {
        (LauncherDelegateFactory {
            LarkBadgeDelegate(resolver: container)
        }, LauncherDelegateRegisteryPriority.low)
    }
}
