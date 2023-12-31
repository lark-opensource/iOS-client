//
//  LarkByteViewAssembly.swift
//  LarkByteView
//
//  Created by chentao on 2019/4/18.
//

import Foundation
import Swinject
import AppContainer
import LarkAssembler
#if canImport(ByteViewDebug)
import ByteViewDebug
import LarkDebugExtensionPoint
#endif

public final class LarkByteViewAssembly: LarkAssemblyInterface {

    public init() {}

    public func registDebugItem(container: Container) {
        #if canImport(ByteViewDebug)
        ({ ByteViewDebugItem() }, SectionType.debugTool)
        #endif
    }

    public func getSubAssemblies() -> [LarkAssemblyInterface]? {
        VCCoreAssembly()
        #if LarkMod
        VCLarkAssembly()
        #endif
        #if CallKitMod
        CallKitAssembly()
        #endif
        #if TabMod
        TabAssembly()
        #endif
        #if HybridMod
        VCHybridAssembly()
        #endif
        #if MessengerMod
        VCMessengerAssembly()
        #endif
        #if CalendarMod
        VCCalendarAssembly()
        #endif
        #if canImport(ByteViewDebug)
        ByteViewDebugAssembly()
        #endif
    }
}
