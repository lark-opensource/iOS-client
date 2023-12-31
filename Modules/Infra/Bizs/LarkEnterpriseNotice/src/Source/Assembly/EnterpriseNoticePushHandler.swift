//
//  EnterpriseNoticePushHandler.swift
//  LarkEnterpriseNotice
//
//  Created by ByteDance on 2023/4/18.
//

import Foundation
import LarkRustClient
import ServerPB
import LarkContainer

enum EnterpriseNoticeStatus: Int {
    /// 推送新的弹窗
    case new = 1

    /// 弹窗已确认状态同步
    case confirm = 2

    /// 弹窗被删除
    case delete = 3
}

public struct PushEnterpriseNoticeMessage: PushMessage {
    var status: EnterpriseNoticeStatus
    var card: EnterpriseNoticeCard
    init(status: EnterpriseNoticeStatus, card: EnterpriseNoticeCard) {
        self.status = status
        self.card = card
    }
}

final class EnterpriseNoticePushHandler: UserPushHandler {

    private var pushCenter: PushNotificationCenter? {
        return try? userResolver.userPushCenter
    }

    func process(push message: ServerPB_Subscriptions_dialog_PushSubscriptionsDialogRequest) throws {
        guard let pushCenter = self.pushCenter else { return }
        let card = message.subscriptionsDialog
        let status = EnterpriseNoticeStatus(rawValue: message.pushType.rawValue) ?? .new
        let pushMessage = PushEnterpriseNoticeMessage(status: status, card: card)
        pushCenter.post(pushMessage)
    }
}
