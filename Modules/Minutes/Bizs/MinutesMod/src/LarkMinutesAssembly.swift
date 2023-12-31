//
//  NavigatorAssembly.swift
//  ByteView
//
//  Created by panzaofeng on 2020/4/10.
//

import Foundation
import Swinject
import AppContainer
import LarkAssembler
import MinutesDependency

public final class LarkMinutesAssembly: LarkAssemblyInterface {

    public init() { }

    public func getSubAssemblies() -> [LarkAssemblyInterface]? {
        MinutesCoreAssembly()
        #if MessengerMod
        MinutesMessengerAssembly()
        #endif
        #if CCMMod
        MinutesCCMAssembly()
        #endif
    }
}
