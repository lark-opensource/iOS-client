//
//  PushTabNotificationHandler.swift
//  Moment
//
//  Created by zc09v on 2021/6/16.
//

import Foundation
import LarkRustClient
import ServerPB
import LarkContainer

struct TabNotificationInfo: PushMessage {
    public let readPostTimestamp: Int64
    public let lastPostTimestamp: Int64

    public init(readPostTimestamp: Int64,
                lastPostTimestamp: Int64) {
        self.readPostTimestamp = readPostTimestamp
        self.lastPostTimestamp = lastPostTimestamp
    }
}

final class PushTabNotificationHandler: UserPushHandler {

    private var userPushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: ServerPB_Moments_PushMomentsTabNotificationRequest) throws {

        guard let userPushCenter = self.userPushCenter else { return }

        userPushCenter.post(TabNotificationInfo(readPostTimestamp: message.readPostTimestamp,
                                                 lastPostTimestamp: message.lastPostTimestamp))
    }
}
