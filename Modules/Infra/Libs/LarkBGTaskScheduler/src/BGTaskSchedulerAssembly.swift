//
//  BGTaskSchedulerAssembl.swift
//  LarkBGTaskScheduler
//
//  Created by su on 2022/5/13.
//

import Foundation
import LarkAssembler
import Swinject
import BootManager
import LarkAccountInterface
import AppContainer

public final class BGTaskSchedulerAssembly: LarkAssemblyInterface {

    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(SetupBGTask.self)
        NewBootManager.register(BGTaskSwitch.self)
    }

    public func registPassportDelegate(container: Container) {
        (PassportDelegateFactory {
            return BGTaskSchedulerAccountDelegate()
        }, PassportDelegatePriority.low)
    }

    public func registBootLoader(container: Container) {
        (BGTaskSchedulerDelegate.self, DelegateLevel.default)
    }
}
