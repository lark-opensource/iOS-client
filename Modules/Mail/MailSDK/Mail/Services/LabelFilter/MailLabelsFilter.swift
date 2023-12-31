//
//  MailLabelFilter.swift
//  MailSDK
//
//  Created by majx on 2019/10/22.
//

import Foundation

// MARK: - MailLabelId Enum
enum MailLabelId: String {
    typealias RawValue = String

    case Inbox     = "INBOX"
    case Important = "IMPORTANT"
    case Scheduled = "SCHEDULED"
    case Other     = "OTHER"
    case Archived = "ARCHIVED"
    case Spam     = "SPAM"
    case Sent     = "SENT"
    case Draft    = "DRAFT"
    case Trash    = "TRASH"
    case Outbox   = "OUTBOX"
    case Search   = "SEARCH"
    case Unread   = "UNREAD"
    case Shared   = "SHARE"
    case Flagged  = "FLAGGED"
    case Custom   = "CUSTOM"
    case Folder   = "FOLDER"
    case Stranger = "STRANGER"
    case SearchTrashAndSpam = "SEARCH_TRASH_AND_SPAM"
}

// MARK: - MailLabelsFilter
// server will return all labels
// but we need show different labels for different scenarios
// so you should use different filter rules for different scenarios
protocol MailLabelsFilter {
    static func filterLabels(_ allLabelds: [MailClientLabel],
                      atLabelId: String,
                      permission: MailPermissionCode) -> [MailClientLabel]

    static func filterLabels(_ allLabelds: [MailClientLabel],
                      atLabelId: String,
                      permission: MailPermissionCode,
                      useCssColor: Bool) -> [MailClientLabel]
}

// MARK: - All Filter Rules
extension MailLabelsFilter {
   static func showCustomLabel(_ labelId: String ) -> Bool {
        let label = MailLabelId(rawValue: labelId) ?? MailLabelId.Custom
        if label == .Custom {
            return true
        }
        return false
    }

   static func showShareLabel(_ labeldId: String) -> Bool {
        let label = MailLabelId(rawValue: labeldId) ?? MailLabelId.Custom
        if label == .Shared {
            return true
        }
        return false
    }

    static func showInboxAndCustomLabel(_ labeldId: String ) -> Bool {
        let label = MailLabelId(rawValue: labeldId) ?? MailLabelId.Custom
        if label == .Inbox || label == .Custom {
            return true
        }
        if label == .Important || label == .Other {
            return false
        }
        return false
    }

   static func showInboxOrArchiveAndCustomLabel(_ labeldId: String ) -> Bool {
        let label = MailLabelId(rawValue: labeldId) ?? MailLabelId.Custom
        if label == .Inbox || label == .Archived || label == .Custom {
            return true
        }
        return false
    }

   static func showCurrentLabelAndCustomLabels(_ labeldId: String, currentLabel: String) -> Bool {
        if labeldId == currentLabel {
            return true
        }
        let label = MailLabelId(rawValue: labeldId) ?? MailLabelId.Custom
        if label == .Custom {
            return true
        }
        return false
    }

   static func showInboxLabelAndCustomLabels(_ labeldId: String ) -> Bool {
           let label = MailLabelId(rawValue: labeldId) ?? MailLabelId.Custom
           if label == .Inbox || label == .Custom {
               return true
           }
           return false
       }

   static func showShareLabelAndCustomLabels(_ labeldId: String) -> Bool {
        let label = MailLabelId(rawValue: labeldId) ?? MailLabelId.Custom
        if label == .Shared || label == .Custom {
            return true
        }
        return false
    }

   static func hideCurrentLabel(_ labeldId: String, currentLabel: String) -> Bool {
        if labeldId == currentLabel {
            return false
        }
        return true
    }
}
