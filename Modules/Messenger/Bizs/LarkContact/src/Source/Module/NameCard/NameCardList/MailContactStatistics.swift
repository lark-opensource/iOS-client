//
//  MailContactStatistics.swift
//  LarkContact
//
//  Created by Quanze Gao on 2022/6/24.
//

import Foundation
import LKCommonsTracker

final class MailContactStatistics {
    private enum Key: String {
        case contactEmailContactView = "contact_email_contact_view"
        case contactEmailContactClick = "contact_email_contact_click"
    }
}

extension MailContactStatistics {
    static func view(accountType: String) {
        Tracker.post(TeaEvent(Key.contactEmailContactView.rawValue,
                              params: ["mail_account_type": accountType]))
    }

    static func addContact(accountType: String) {
        Tracker.post(TeaEvent(Key.contactEmailContactClick.rawValue,
                              params: ["mail_account_type": accountType,
                                       "click": "add_contact",
                                       "target": "none"]))
    }
}
