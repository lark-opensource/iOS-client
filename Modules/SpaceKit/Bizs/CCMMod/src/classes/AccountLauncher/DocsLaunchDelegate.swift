//
//  DocsLaunchDelegate.swift
//  Lark
//
//  Created by weidong fu on 2018/12/13.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import LarkRustClient
import SpaceKit
import RxSwift
import LarkAccountInterface
import LarkPerf
import RunloopTools
import LarkAppConfig
import BootManager

public final class DocsLaunchDelegate: LauncherDelegate {
    public let name: String = "DocsSDK"
    private let resolver: Resolver
    var docsViewControllerFactory: DocsViewControllerFactory {
        return resolver.resolve(DocsViewControllerFactory.self)!
    }

    public init(resolver: Resolver) {
        self.resolver = resolver
    }

    func doTask(_ context: LauncherContext, task: @escaping () -> Void) {
        if NewBootManager.shared.context.launchOptions != nil {
            task()
        } else {
            RunloopDispatcher.shared.addTask { task() }
        }
    }

    public func afterLoginSucceded(_ context: LauncherContext) {
        doTask(context) {
            self.docsViewControllerFactory.larkUserDidLogin(nil, nil) // account参数目前没有使用，所以传入nil
        }
    }

    public func beforeLogout() {
        docsViewControllerFactory.handleBeforeUserLogout()
    }

    public func afterLogout(_ context: LauncherContext) {
        docsViewControllerFactory.larkUserDidLogout(nil, nil) // account参数目前没有使用，所以传入nil
    }

    public func beforeSwitchAccout() {
        docsViewControllerFactory.handleBeforeUserSwitchAccout()
    }

    public func afterSwitchAccout(error: Error?) -> Observable<Void> {
        docsViewControllerFactory.didFinishSwitchAccount(error)
        return .just(())
    }
}
