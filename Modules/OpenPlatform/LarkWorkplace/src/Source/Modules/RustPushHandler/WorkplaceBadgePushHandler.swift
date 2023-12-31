//
//  WorkplaceBadgePushHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/5/26.
//

import Foundation
import RustPB
import AppContainer
import LarkRustClient
import LarkOPInterface
import LarkContainer
import LKCommonsLogging

/// Rust Badge更新通知
struct BadgeUpdateMessage: PushMessage, Hashable {
    let pushRequest: Rust.PushOpenAppBadgeNodesRequest

    init(pushRequest: Rust.PushOpenAppBadgeNodesRequest) {
        self.pushRequest = pushRequest
    }
}

/// Rust Badge push 通知监听
final class WorkplaceBadgePushHandler: UserPushHandler {
    static let logger = Logger.log(WorkplaceBadgePushHandler.self)

    func process(push message: Rust.PushOpenAppBadgeNodesRequest) throws {
        let pushCenter = try userResolver.userPushCenter
        let nodesLogInfo: [[String: String]] = message.noticeNodes.map({ [
            "appId": $0.appID,
            "feature": "\($0.feature)",
            "needShow": "\($0.needShow)",
            "updateTime": "\($0.updateTime)",
            "badgeNum": "\($0.badgeNum)",
            "version": "\($0.version)"
        ] })
        Self.logger.info("did receive badge push", additionalData: [
            "sid": message.sid,
            "nodesCount": "\(message.noticeNodes.count)",
            "nodes": "\(nodesLogInfo)"
        ])
        let postMessage = BadgeUpdateMessage(pushRequest: message)
        pushCenter.post(postMessage)
    }
}
