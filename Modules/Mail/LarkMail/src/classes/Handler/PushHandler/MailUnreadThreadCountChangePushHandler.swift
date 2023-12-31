//
//  MailUnreadThreadCountChangePushHandler.swift
//  Action
//
//  Created by NewPan on 2019/6/17.
//

import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging

class MailUnreadThreadCountChangePushHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? resolver.userPushCenter }

    func process(push: MailUpdateUnreadThreadCountPushResponse) throws {
        self.pushCenter?.post(MailUnreadThreadCountChangePush(count: push.count,
                                                             tabUnreadColor: push.tabUnreadColor,
                                                             countMap: push.countMap,
                                                             colorMap: push.colorMap))
    }
}

struct MailUnreadThreadCountChangePush: PushMessage {
    let count: Int64
    let tabUnreadColor: Email_Client_V1_UnreadCountColor

    let countMap: [String: Int64]
    let colorMap: [String: Email_Client_V1_UnreadCountColor]

    init(count: Int64,
                tabUnreadColor: Email_Client_V1_UnreadCountColor,
                countMap: [String: Int64],
                colorMap: [String: Email_Client_V1_UnreadCountColor]) {
        self.count = count
        self.tabUnreadColor = tabUnreadColor
        self.countMap = countMap
        self.colorMap = colorMap
    }
}
