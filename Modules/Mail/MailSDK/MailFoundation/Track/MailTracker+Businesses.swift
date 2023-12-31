//
//  MailTracker+Businesses.swift
//  MailSDK
//
//  Created by NewPan on 2020/1/17.
//

import Foundation

extension MailTracker {
    enum SourcesType {
        case threadAction
        case threadActionB
        case threadItemAction
        case threadList
        case threadSlide
        case messageAction
        case notification
        case chatSideBar
        case mailAddressMenu
        case editorDeleteButton
        case toolbar
        case searchBar
        case new
        case mailTo
        case mailAIChat
        case editAgain
        case composeButton
        case messageActionReply
        case messageActionReplyAll
        case messageActionForward
        case messageQuickActionReply
        case messageQuickActionReplyAll
        case messageQuickActionForward
        case mailAddressRightMenu
        case inboxDraft
        case imCard
        case messageItem
        case outbox
        case outOfOffice
        case folderManage
        case emlAsAttachment
        case feedDraftAction
    }

    enum LabelType {
        case system
        case user
    }

    class func source(type: SourcesType) -> String {
        switch type {
        case .threadAction:
            return "thread_action"
        case .threadActionB:
            return "thread_action_b"
        case .threadItemAction:
            return "thread_item_action"
        case .threadList:
            return "thread_list"
        case .threadSlide:
            return "thread_slide"
        case .messageAction:
            return "message_action"
        case .notification:
            return "notification"
        case .chatSideBar:
            return "chat_side_bar"
        case .mailAddressMenu:
            return "mail_address_menu"
        case .editorDeleteButton:
            return "editor_delete_button"
        case .toolbar:
            return "toolbar"
        case .searchBar:
            return "search_bar"
        case .composeButton, .mailTo, .new, .editAgain, .emlAsAttachment:
            return "compose_button"
        case .messageActionReply:
            return "message_action_reply"
        case .messageActionReplyAll:
            return "message_action_reply_all"
        case .messageActionForward:
            return "message_action_forward"
        case .messageQuickActionReply:
            return "message_quick_action_reply"
        case .messageQuickActionReplyAll:
            return "message_quick_action_reply_all"
        case .messageQuickActionForward:
            return "message_quick_action_forward"
        case .mailAddressRightMenu:
            return "mail_address_right_menu"
        case .inboxDraft:
            return "inbox_draft"
        case .imCard:
            return "im_card"
        case .messageItem:
            return "message_item"
        case .outbox:
            return "outbox"
        case .outOfOffice:
            return "out_of_office"
        case .folderManage:
            return "folder_manage"
        case .mailAIChat:
            return "mail_ai_chat"
        case .feedDraftAction:
            return "feed_draft_action"
        }
    }

    class func editType(type: SourcesType) -> String? {
        switch type {
        case .new:
            return "new_mail"
        case .messageActionReply, .messageQuickActionReply:
            return "reply"
        case .messageQuickActionReplyAll, .messageActionReplyAll:
            return "reply_all"
        case .messageActionForward, .messageQuickActionForward:
            return "forward"
        case .outbox, .editAgain:
            return "edit_again"
        case .inboxDraft, .messageItem:
            return "open_draft"
        case .mailTo, .mailAddressRightMenu:
            return "mail_to"
        case .emlAsAttachment:
            return "send_as_eml_attachment"
        case .mailAIChat:
            return "mail_ai_chat"
        default:
            return nil
        }
    }

    class func labelType(type: LabelType) -> String {
        switch type {
        case .system:
            return "system"
        case .user:
            return "user"
        }
    }

    class func getLabelType(isSystemLabel: Bool) -> String {
        if isSystemLabel {
            return MailTracker.labelType(type: .system)
        } else {
            return MailTracker.labelType(type: .user)
        }
    }

    class func isMultiselectParamKey() -> String {
        return "is_multiselect"
    }

    class func labelIDParamKey() -> String {
        return "label_id"
    }

    class func threadIDsParamKey() -> String {
        return "thread_ids"
    }

    class func toParamKey() -> String {
        return "to"
    }

    class func sourceParamKey() -> String {
        return "source"
    }

    class func threadCountParamKey() -> String {
        return "thread_count"
    }

    class func labelTypeParamKey() -> String {
        return "label_type"
    }

    class func draftIdParamKey() -> String {
        return "draft_id"
    }

    class func imageCountParamKey() -> String {
        return "image_count"
    }

    class func attachmentCountParamKey() -> String {
        return "attachment_count"
    }

    class func toCountParamKey() -> String {
        return "to_count"
    }

    class func ccCountParamKey() -> String {
        return "cc_count"
    }

    class func bccCountParamKey() -> String {
        return "bcc_count"
    }

    class func hasSubjectParamKey() -> String {
        return "has_subject"
    }

    class func searchSessionParamKey() -> String {
        return "search_session"
    }

    class func searchIndexParamKey() -> String {
        return "search_index"
    }

    class func statusTypeParamKey() -> String {
        return "status_type"
    }

    class func hasImageParamKey() -> String {
        return "has_image"
    }

    class func hasOnlyTextParamKey() -> String {
        return "has_onlytxt"
    }

    class func textRowsParamKey() -> String {
        return "sum_txtrow"
    }
}

extension MailTracker {
    static let WelcomeLetterThreadID = "wce-a4403d04-a35c-434a-b449-81b7d6f5b383"
    static let WelcomeLetterLinkSuffix = "#welcomeLarkMail"
}

extension MailTracker.SourcesType {
    func supportUndo() -> Bool {
        if FeatureManager.open(FeatureKey(fgKey: .threadCustomSwipeActions, openInMailClient: true)) && !Store.settingData.mailClient {
            return self == .threadSlide
        } else {
            return false
        }
    }
}
