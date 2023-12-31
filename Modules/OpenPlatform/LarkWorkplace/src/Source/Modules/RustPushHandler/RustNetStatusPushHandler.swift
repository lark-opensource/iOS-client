//
//  RustNetStatusPushHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/5/18.
//

import Foundation
import LarkContainer
import AppContainer
import LarkRustClient
import RustPB
import LKCommonsLogging

/// Rust 网络状态变更通知
struct PushNetStatus: PushMessage, Hashable {
    static var netStatus: Rust.NetStatus = .evaluating

    let netStatus: Rust.NetStatus

    init(netStatus: Rust.NetStatus) {
        self.netStatus = netStatus
    }
}

/// Rust 网络通知监听
final class RustNetStatusPushHandler: BaseRustPushHandler<RustPB.Basic_V1_DynamicNetStatusResponse> {
    static let logger = Logger.log(RustNetStatusPushHandler.self)

    override func doProcessing(message: RustPB.Basic_V1_DynamicNetStatusResponse) {
        Self.logger.info("rust pushed net status", additionalData: [
            "netStatus": "\(message.netStatus)"
        ])
        PushNetStatus.netStatus = message.netStatus
        let message = PushNetStatus(netStatus: message.netStatus)
        BootLoader.container.globalPushCenter.post(message, replay: true)
    }
}
