//
//  LarkMonitorAssembly.swift
//  LarkMonitor
//
//  Created by PGB on 2020/3/9.
//

import Foundation
import RxSwift
import Swinject
import EENavigator
import RustPB
import LarkRustClient
import LarkContainer
import BootManager
import LarkDebugExtensionPoint
import LarkAssembler

public final class LarkMonitorAssembly: LarkAssemblyInterface {
    public init() { }

    public func registLaunch(container: Container) {
        NewBootManager.register(ScreenshotMonitorLaunchTask.self)
        NewBootManager.register(ScreenCapturedMonitorLaunchTask.self)
        NewBootManager.register(LarkMemoryPressureMonitor.self)
        NewBootManager.register(LarkPowerLogMonitorLaunchTask.self)
    }

    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushDataCorrupt, DataCorruptPushHandler.init(resolver:))
    }

    public func registDebugItem(container: Container) {
        ({ScreenShotFindControllerItem()}, SectionType.debugTool)
    }
}
