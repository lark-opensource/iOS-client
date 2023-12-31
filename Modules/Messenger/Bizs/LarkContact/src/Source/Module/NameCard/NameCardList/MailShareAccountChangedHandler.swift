//
//  MailShareAccountChangedHandler.swift
//  LarkContact
//
//  Created by Quanze Gao on 2022/5/25.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface

final class MailShareAccountChangedHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Email_Client_V1_MailSharedAccountChangePushResponse) throws {
        guard let pushCenter = self.pushCenter else { return }
        pushCenter.post(MailShareAccountChangedPush())
    }
}
