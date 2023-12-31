//
//  LarkAssemblyBuilder.swift
//  LarkContainer
//
//  Created by yangjing.sniper on 2021/12/23.
//

import Foundation
import LarkAccountInterface
import LarkContainer

@resultBuilder
public struct PassportStateDelegateFactory {
    public static func buildBlock(_ components: (PassportDelegateFactory, PassportDelegatePriority)...) {
        components.forEach { compent in
            PassportDelegateRegistry.register(factory: compent.0, priority: compent.1)
        }
    }
}

@resultBuilder
public struct LaunchDelegateFactory {
    public static func buildBlock(_ components: (LauncherDelegateFactory, LauncherDelegateRegisteryPriority)...) {
        components.forEach { compent in
            LauncherDelegateRegistery.register(factory: compent.0, priority: compent.1)
        }
    }
}

@resultBuilder
public struct UnloginWhitelistFactory {
    public static func buildBlock(_ components: String...) {
        components.forEach { compent in
            UnloginWhitelistRegistry.registerUnloginWhitelist(compent)
        }
    }
}

// MARK: Helper
extension Container {
    public func whenPassportDelegate(factory: () -> PassportDelegate) -> PassportDelegate {
        let enableUserScope = self.resolve(PassportService.self)?.enableUserScope ?? false
        if enableUserScope {
            return factory()
        } else {
            return DummyPassportDelegate()
        }
    }
    public func whenLauncherDelegate(factory: () -> LauncherDelegate) -> LauncherDelegate {
        let enableUserScope = self.resolve(PassportService.self)?.enableUserScope ?? false
        if enableUserScope {
            return DummyLauncherDelegate()
        } else {
            return factory()
        }
    }
}
