//
//  PrivacyAlertAssembly.swift
//  LarkPrivacyAlert
//
//  Created by quyiming on 2020/4/29.
//

import Foundation
import Swinject
import AppContainer
import BootManager
import LarkAssembler

public final class PrivacyAlertAssembly: LarkAssemblyInterface {

    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(PrivacyCheckTask.self)
        NewBootManager.register(PrivacyBizTask.self)
    }
}
