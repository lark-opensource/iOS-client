//
//  MailPageViewTracker.swift
//  MailSDK
//
//  Created by majx on 2020/4/8.
//

import Foundation
import Homeric

struct MailPageViewTracker {
    static let trackNameMap = [
        String(describing: MailHomeController.self): "thread_list",
        String(describing: MailMessageListController.self): "message_list",
//        String(describing: MailSendController.self):            "mail_editor",
        String(describing: MailSettingViewController.self): "mail_setting",
        String(describing: MailCreateTagController.self): "create_label",
        String(describing: MailEditLabelsViewController.self): "change_label",
        String(describing: MailManageLabelsController.self): "manage_label",
        String(describing: MailMoveToLabelViewController.self): "move_to_label",
        String(describing: MailSearchViewController.self): "search",
        String(describing: MailSettingSignatureViewController.self): "signature_setting",
        String(describing: MailSignatureEditViewController.self): "signature_editor",
        String(describing: MailOOOSettingViewController.self): "auto_reply_setting",
        /// those is rename in ShareCollaboratorsViewController:
        /// "send_to_im"
        /// "invite_collaborator_list"
        /// "edit_collaborator_list"
        /// "confirm_collaborator_list"

        /// those is rename in MailSendController:
        /// "mail_editor"
        /// "auto_reply_editor"
    ]

    static func trackPageViewEvent(_ pageTrackName: String) {
        var pageTrackName = pageTrackName
        if let trackName = MailPageViewTracker.trackNameMap[pageTrackName] {
            pageTrackName = trackName
        }
        MailTracker.log(event: Homeric.EMAIL_PAGE_VIEW, params: ["page": pageTrackName])
    }
}
