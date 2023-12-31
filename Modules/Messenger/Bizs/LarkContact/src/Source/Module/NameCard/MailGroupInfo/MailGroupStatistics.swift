//
//  MailGroupStatistics.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/12/13.
//

import Foundation
import LKCommonsTracker

final class MailGroupStatistics {
    private enum Key: String {
    case groupEditClick = "contact_email_mail_group_edit_click"
    case groupView = "contact_email_mail_group_view"
    case groupClick = "contact_email_mail_group_click"
    case groupEditView = "contact_email_mail_group_edit_view"
    }
}

extension MailGroupStatistics {
    static func groupEditClick(value: String) {
        var params: [AnyHashable: Any] = [:]
        params["click"] = value
        params["target"] = "none"
        Tracker.post(TeaEvent(Key.groupEditClick.rawValue,
                              params: params))
    }

    static func groupListView() {
        Tracker.post(TeaEvent(Key.groupView.rawValue,
                              params: [:]))
    }

    static func groupListClick() {
        var params: [AnyHashable: Any] = [:]
        params["click"] = "group_detail"
        params["target"] = "none"
        Tracker.post(TeaEvent(Key.groupClick.rawValue,
                              params: params))
    }

    static func groupInfoView() {
        Tracker.post(TeaEvent(Key.groupEditView.rawValue,
                              params: [:]))
    }
}
