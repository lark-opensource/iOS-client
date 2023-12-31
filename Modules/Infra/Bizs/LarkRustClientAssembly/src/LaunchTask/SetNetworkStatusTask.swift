//
//  SetNetworkStatusTask.swift
//  LarkRustClientAssembly
//
//  Created by 王元洵 on 2021/12/29.
//

import Foundation
import BootManager
import LarkContainer

final class SetNetworkStatusTask: FlowBootTask, Identifiable {
    static var identify = "SetNetworkStatusTask"

    @InjectedLazy private var client: LarkRustClient

    override var runOnlyOnce: Bool { true }

    override func execute(_ context: BootContext) { client.notifyNetworkStatus() }
}
