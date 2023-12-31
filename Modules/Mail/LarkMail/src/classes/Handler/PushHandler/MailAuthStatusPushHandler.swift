//
//  MailAuthStatusPushHandler.swift
//  LarkSDK
//
//  Created by tefeng liu on 2019/11/17.
//

import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging

extension MailOAuthStatusPushResponse.Status {
    var toPushStatus: MailOauthStatusPush.Status {
        switch self {
        case .unknown:
            return .unknown
        case .success:
            return .success
        case .fail:
            return .fail
        case .revoke:
            return .revoke
        @unknown default:
            assertionFailure("check this")
            return .unknown
        }
    }
}

class MailAuthStatusPushHandler: UserPushHandler {

    func process(push: MailOAuthStatusPushResponse) throws {
        var setting = push.setting
        if push.account.accountSelected.isSelected {
            setting = push.account.mailSetting
        } else if let selectedAccount = push.account.sharedAccounts.first(where: { $0.accountSelected.isSelected }) {
            setting = selectedAccount.mailSetting
        }
        let change = MailOauthStatusPush(authStatus: push.status.toPushStatus, emailAddress: push.emailAddress, setting: setting)

        let success = change.authStatus == .success
        NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_SETTING_AUTH_STATUS_CHANGED,
                                        object: nil,
                                        userInfo: [Notification.Name.Mail.MAIL_OAUTH_IS_SUCCESS_KEY: success,
                                                   Notification.Name.Mail.MAIL_SETTING_DATA_KEY: change.setting])
        if success {
            NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_SETTING_CHANGED_BYPUSH,
                                            object: change.setting)
        }
    }
}
