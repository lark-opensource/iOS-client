//
//  MailContactChangedHandler.swift
//  LarkContact
//
//  Created by Quanze Gao on 2022/5/17.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface

final class MailContactChangedHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Email_Client_V1_GetMailContactMetaResponse) throws {
        let briefInfos = message.meta.map { MailAccountBriefInfo.transform(from: $0) }
        guard let pushCenter = self.pushCenter else { return }
        pushCenter.post(MailContactChangedPush(briefInfos: briefInfos))
    }
}
