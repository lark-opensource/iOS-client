//
//  LarkWidgetAssembly.swift
//  LarkWidget
//
//  Created by ZhangHongyun on 2020/12/2.
//

import Foundation
import UIKit
import Swinject
import BootManager
import LarkAccountInterface
import LarkAssembler
import AppContainer

public final class LarkWidgetAssembly: LarkAssemblyInterface {

    public init() { }

    public func registLaunch(container: Container) {
        NewBootManager.register(WidgetLaunchTask.self)
        NewBootManager.register(WidgetDataLaunchTask.self)
    }

    public func registContainer(container: Container) {
        container.register(WidgetAccountDelegateService.self) { _ in
            return WidgetAccountTaskDelegate()
        }
    }

    public func registLauncherDelegate(container: Container) {
        (LauncherDelegateFactory(delegateProvider: {
            container.resolve(WidgetAccountDelegateService.self)!
        }), LauncherDelegateRegisteryPriority.middle)
    }

    public func registBootLoader(container: Container) {
        (WidgetAppDelegate.self, DelegateLevel.default)
    }
}

/// App 生命周期
final class WidgetAppDelegate: ApplicationDelegate {

    static let config = Config(name: "WidgetService", daemon: true)

    required init(context: AppContext) {
        context.dispatcher.add(observer: self) { (_, _: WillEnterForeground) in
            LarkWidgetService.share.applicationWillEnterForeground()
        }
        context.dispatcher.add(observer: self) { (_, _: DidEnterBackground) in
            LarkWidgetService.share.applicationDidEnterBackground()
        }
        context.dispatcher.add(observer: self) { (_, message: OpenURL) in
            LarkWidgetService.share.applicationDidOpenURL(message.url)
        }
    }
}
