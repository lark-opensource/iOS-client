//
//  ExtensionAssembly.swift
//  LarkExtension
//
//  Created by 王元洵 on 2020/10/19.
//

import Foundation
import Swinject
import BootManager
import LarkAccountInterface
import LarkAssembler
import AppContainer

// MARK: - Assembly
public final class ExtensionAssembly: LarkAssemblyInterface {
    public init() {}

    public func registPassportDelegate(container: Container) {
           (PassportDelegateFactory {
               return ExtensionAccountDelegate()
           }, PassportDelegatePriority.middle)
       }

    public func registLaunch(container: Container) {
        NewBootManager.register(ExtensionLaunchTask.self)
    }

    public func registBootLoader(container: Container) {
        (ExtensionAppDelegate.self, DelegateLevel.default)
    }
}
