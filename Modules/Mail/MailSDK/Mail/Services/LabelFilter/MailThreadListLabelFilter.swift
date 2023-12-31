//
//  MailThreadListLabelFilter.swift
//  MailSDK
//
//  Created by majx on 2019/10/22.
//

import Foundation
// Thread List Label Filter Rules
// Normal:
//    1. Inbox
//        hide all system label
//        show all custom label
//    2. Flagged
//        show one of (inbox || archive) label
//        show all custom label
//    3. Draft
//        show one of (inbox || archive)  label
//        show all custom label
//    4. Sent
//        show one of (inbox || archive) label
//        show all custom label
//    5. Archive
//        hide all system label
//        show all custom label
//    6. Delete
//        hide all system label
//        show all custom label
//    7. Spam
//        hide all system label
//        show all custom label
//    8. Custom
//        show one of (inbox || archive) label
//        hide self label
//        show other custom label
// Owner:
//    1.  Inbox
//        show Shared label
//        hide other system label
//        show all custom  label
//    2. Flagged
//        show  Inbox label
//        hide other system label
//        show all custom label
//    3. Draft
//        show Shared label
//        hide other system label
//        show all custom  label
//    4. Sent
//        show Shared label
//        hide other system label
//        show all custom  label
//    5. Archive
//        show Shared label
//        hide other system label
//        show all custom  label
//    6. Trash
//        show Shared label
//        hide other system label
//        show all custom  label
//    7. Spam
//        show Shared label
//        hide other system label
//        show all custom  label
//    8.Shared
//        show Inbox label
//        hide other system label
//        show all custom  label
//    9. Custom
//        show Shared label
//        hide other system label
//        hide self label
//        show other custom label
struct MailThreadListLabelFilter: MailLabelsFilter {
    static func filterLabels(_ allLabelds: [MailClientLabel],
                      atLabelId: String,
                      permission: MailPermissionCode,
                      useCssColor: Bool) -> [MailClientLabel] {
        return filterLabels(allLabelds, atLabelId: atLabelId, permission: permission)
    }

    static func filterLabels(_ allLabelds: [MailClientLabel],
                             atLabelId: String,
                             permission: MailPermissionCode) -> [MailClientLabel] {
        let currentLabel = MailLabelId(rawValue: atLabelId) ?? MailLabelId.Custom
        var allLabelds = allLabelds

        var filteredLabels = allLabelds.filter { (labelModel) -> Bool in
            let labelId = labelModel.id
            /// normal mail
            if permission == .none {
                switch currentLabel {
                case .Inbox, .Important, .Other, .Archived, .Trash, .Spam, .Search, .Folder, .Stranger, .SearchTrashAndSpam:
                    return showCustomLabel(labelId)
                case .Flagged, .Draft, .Sent, .Scheduled:
                    return showInboxOrArchiveAndCustomLabel(labelId)
                case .Custom:
                    if showInboxOrArchiveAndCustomLabel(labelId) {
                        return hideCurrentLabel(labelId, currentLabel: atLabelId)
                    } else {
                        return false
                    }
                case .Shared, .Unread, .Outbox:
                    return false
                }
            } else if permission == .owner {
                /// share mail in owner permission
                switch currentLabel {
                case .Inbox, .Important, .Other, .Draft, .Sent, .Archived, .Trash, .Spam, .Search, .Scheduled, .Folder, .Stranger, .SearchTrashAndSpam:
                    return showShareLabelAndCustomLabels(labelId)
                case .Flagged, .Shared:
                    return showInboxLabelAndCustomLabels(labelId)
                case .Custom:
                    if showShareLabelAndCustomLabels(labelId) {
                        return hideCurrentLabel(labelId, currentLabel: atLabelId)
                    } else {
                        return false
                    }
                case .Unread, .Outbox:
                    return false
                }
            } else {
                if currentLabel != .Shared {
                    /// share mail in view permission
                    return showShareLabel(labelId)
                }
                return false
            }
        }

        /// sort labels at flagged thread
        if currentLabel == .Flagged {
            filteredLabels = filteredLabels.sorted(by: { (label1, label2) -> Bool in
                return label1.id == Mail_LabelId_Inbox
            })
        }

        filteredLabels = filteredLabels.filter({ !$0.isSystem && $0.tagType == .label })

        // label颜色过滤
        filteredLabels = filteredLabels.map({ label in
            var newLabel = label
            let config = MailLabelTransformer.transformLabelColor(backgroundColor: label.bgColor)
            newLabel.fontColor = config.fontToHex(alwaysLight: false)
            newLabel.bgColor = config.bgToHex(alwaysLight: false)
            newLabel.colorType = config.colorType
            return newLabel
        })

        return filteredLabels
    }
}
