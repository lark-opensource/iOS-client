//
//  DebugAssembly.swift
//  LarkDebug
//
//  Created by CharlieSu on 11/17/19.
//

import Foundation
import EENavigator
import Swinject
import LarkDebugExtensionPoint
import LarkAccountInterface
import AppContainer
import BootManager
import LarkAssembler

public final class DebugAssembly: LarkAssemblyInterface {
    public init() {}
    #if !LARK_NO_DEBUG
    public func registDebugItem(container: Container) {
        ({CommitInfo()}, SectionType.basicInfo)
        ({XcodeInfo()}, SectionType.basicInfo)

        #if canImport(FLEX)
        ({FlexDebugItem()}, SectionType.debugTool)
        #endif
        ({OverlayDebugItem()}, SectionType.debugTool)
        ({FPSDebugItem()}, SectionType.debugTool)
        ({PodInfoItem()}, SectionType.debugTool)
        ({MacConsoleDebugItem()}, SectionType.debugTool)
        ({SandboxItem()}, SectionType.debugTool)
        #if canImport(SocketIO)
        ({SDKProxyInfoItem()}, SectionType.debugTool)
        #endif
    }

    public func registUnloginWhitelist(container: Container) {
        DebugBody.pattern
    }

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute_(type: DebugBody.self) {
            return DebugViewControllerHandler()
        }
    }
    #endif

    public func registLaunch(container: Container) {
        NewBootManager.register(SetupDebugTask.self)
    }
}
