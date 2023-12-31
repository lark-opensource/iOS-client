//
//  CallKitAssembly.swift
//  ByteViewMod
//
//  Created by kiri on 2023/6/6.
//

import Foundation
import LarkAssembler
import BootManager
import Swinject
import LarkContainer
import LarkAccountInterface
import AppContainer

final class CallKitAssembly: LarkAssemblyInterface {
    func registLaunch(container: Container) {
        NewBootManager.register(CallKitSetupTask.self)
    }

    func registPassportDelegate(container: Container) {
        (PassportDelegateFactory { CallKitPassportDelegate.shared }, PassportDelegatePriority.middle)
    }

    func registBootLoader(container: Container) {
        (CallKitApplicationDelegate.self, DelegateLevel.default)
    }
}
