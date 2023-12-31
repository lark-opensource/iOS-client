//
//  SettingsBundleAssembly.swift
//  LarkSettingsBundle
//
//  Created by Miaoqi Wang on 2020/3/29.
//

import Foundation
import Swinject
import AppContainer
import BootManager
import LarkAssembler

public final class SettingsBundleAssembly: LarkAssemblyInterface {
    public init() {}

    public func registLaunch(container: Container) {
        NewBootManager.register(SettingBundleTask.self)
    }
}
