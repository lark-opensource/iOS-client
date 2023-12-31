//
//  SetupURLProtocolTask.swift
//  ByteView_Example
//
//  Created by kiri on 2023/11/21.
//

import Foundation
import BootManager
import AppContainer
import LarkContainer
import LarkRustClient
import LarkRustHTTP

final class SetupURLProtocolTask: FlowBootTask, Identifiable { // Global
    static var identify = "SetupURLProtocolTask"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        @Provider var rustService: GlobalRustService // Global
        // rusthttp urlprotocol config
        // 使用一个用户无关的全局client来直接往rust发消息
        RustHttpManager.rustService = { rustService }
        // wait TTNet and rust init finish. this task should ok
        rustService.wait {
            RustHttpManager.ready = true
        }
    }
}
