//
//  OPBadgePushHandler.swift
//  LarkOPInterface
//
//  Created by ByteDance on 2023/10/16.
//

import Foundation
import LKCommonsLogging
import RustPB
import LarkContainer
import LarkRustClient

public struct OPBadgeUpdateMessage: PushMessage, Hashable {
    let pushRequest: OPBadgeRustAlias.PushOpenAppBadgeNodesRequest

    init(pushRequest: OPBadgeRustAlias.PushOpenAppBadgeNodesRequest) {
        self.pushRequest = pushRequest
    }
}

/// Rust Badge push 通知监听
public final class OPBadgePushHandler: UserPushHandler {
    static let logger = Logger.log(OPBadgePushHandler.self)

    public func process(push message: OPBadgeRustAlias.PushOpenAppBadgeNodesRequest) throws {
        let pushCenter = try userResolver.userPushCenter
        let nodesLogInfo: [[String: String]] = message.noticeNodes.map({ [
            "appId": $0.appID,
            "needShow": "\($0.needShow)",
            "badgeNum": "\($0.badgeNum)",
            "version": "\($0.version)",
            "feature": "\($0.feature)",
            "updateTime": "\($0.updateTime)"
        ] })
        Self.logger.info("[OPBadge] did receive badge push", additionalData: [
            "sid": message.sid,
            "nodesCount": "\(message.noticeNodes.count)",
            "nodes": "\(nodesLogInfo)"
        ])
        let postMessage = OPBadgeUpdateMessage(pushRequest: message)
        pushCenter.post(postMessage)
    }
}
