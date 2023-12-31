//
//  MailProfileStatistics.swift
//  LarkContact
//
//  Created by tefeng liu on 2022/1/6.
//

import Foundation
import LKCommonsTracker

final class MailProfileStatistics {
    private enum Key: String {
        case emailContactProfileView = "email_contact_profile_view"
        case emailContactProfileClick = "email_contact_profile_click"
    }

    enum Action: String {
        case edit
        case delete
        case add = "add_to_mail_contact"
        case clickAddress = "mail_address"
    }
}

extension MailProfileStatistics {
    static func view(accountType: String) {
        Tracker.post(TeaEvent(Key.emailContactProfileView.rawValue,
                              params: ["mail_account_type": accountType]))
    }

    static func action(_ action: Action, accountType: String) {
        Tracker.post(TeaEvent(Key.emailContactProfileClick.rawValue,
                              params: ["mail_account_type": accountType,
                                       "click": action.rawValue,
                                       "target": "none"]))
    }
}
