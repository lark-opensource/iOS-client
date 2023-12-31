//
//  MailMessageListLabelsFilter.swift
//  MailSDK
//
//  Created by majx on 2019/10/22.
//

import Foundation

// Message List Label Filter Rules
// Normal:
//    1. Inbox
//        show Inbox label
//        show all Custom label
//    2. Flag
//        show one of (inbox || archive)
//        show all Custom label
//    3. Draft
//        show one of (inbox || archive)
//        show all Custom label
//    4. Sent
//        show one of (inbox || archive)
//        show all Custom label
//    5.Archive
//        show Archive label
//        show all Custom label
//    6. Trash
//        show Trash label
//        show all Custom label
//    7. Spam
//        show Spam label
//        show all Custom label
//    8. Custom
//        show one of (inbox || archive)
//        show all Custom label
//    9. Smart Inbox Labels
//        show Inbox label
//        show all Custom label
//
// Owner:
//    1. Inbox
//        show Shared then show Inbox label
//        show all Custom label
//    2. Flag
//        show Inbox then show Shared label
//        show all Custom label
//    3. Draft
//        show Shared then show one of (inbox || archive)
//        show all Custom label
//    4. Sent
//        show Shared then show one of (inbox || archive)
//        show all Custom label
//    5. Archive
//        show Shared then show Archive label
//        show all Custom label
//    6. Trash
//        show Shared then show Trash label
//        show all Custom label
//    7. Spam
//        show Shared then show Spam label
//        show all Custom label
//    8. Custom
//        show Shared then show one of (inbox || archive)
//        show all Custom label
// Other:
//    show shared Label
//    hide all custom Label

struct MailMessageListLabelsFilter: MailLabelsFilter {
    static func filterLabels(_ allLabelds: [MailClientLabel],
                             atLabelId: String,
                             permission: MailPermissionCode) -> [MailClientLabel] {
        return filterLabels(allLabelds, atLabelId: atLabelId, permission: permission, useCssColor: false)
    }

    static func filterLabels(_ allLabelds: [MailClientLabel],
                             atLabelId: String,
                             permission: MailPermissionCode,
                             useCssColor: Bool) -> [MailClientLabel] {
        let currentLabel = MailLabelId(rawValue: atLabelId) ?? MailLabelId.Custom
        var allLabelds = allLabelds

        /// deal the share label
        if currentLabel == .Flagged {
            /// put Inbox label at head in Flagged label
            if let inboxLabelIndex = allLabelds.firstIndex(where: { MailLabelId(rawValue: $0.id) == .Inbox }) {
                let inboxLabel = allLabelds[inboxLabelIndex]
                allLabelds.remove(at: inboxLabelIndex)
                allLabelds.insert(inboxLabel, at: 0)
            } else {

            }
        } else if let shareLabelIndex = allLabelds.firstIndex(where: { MailLabelId(rawValue: $0.id) == .Shared }) {
            /// put share label at head
            var shareLabel = allLabelds[shareLabelIndex]
            allLabelds.remove(at: shareLabelIndex)
            shareLabel.fontColor = UIColor.ud.N600.hex6 ?? "#3370FF"
            shareLabel.bgColor = UIColor.ud.N300.hex6 ?? "#E1EAFF"
            allLabelds.insert(shareLabel, at: 0)
        }

        var filteredLabels = allLabelds.filter { (labelModel) -> Bool in
            let labelId = labelModel.id
            if labelModel.tagType == .folder {
                return false
            }
            /// normal mail
            if permission == .none {
                switch currentLabel {
                case .Inbox, .Archived, .Trash, .Spam, .Folder:
                    return showCurrentLabelAndCustomLabels(labelId, currentLabel: atLabelId)
                case .Important, .Other, .Stranger:
                    return showInboxAndCustomLabel(labelId)
                case .Flagged, .Draft, .Sent, .Custom, .Search, .Scheduled, .SearchTrashAndSpam:
                    return showInboxOrArchiveAndCustomLabel(labelId)
                case .Shared:
                    return showShareLabel(labelId)
                case .Unread, .Outbox:
                    return false
                }
            } else if permission == .owner {
                /// share mail in owner permission
                switch currentLabel {
                case .Inbox, .Archived, .Trash, .Spam, .Folder:
                    if showShareLabel(labelId) || showCurrentLabelAndCustomLabels(labelId, currentLabel: atLabelId) {
                        return true
                    } else {
                        return false
                    }
                case .Important, .Other, .Stranger:
                    return showInboxAndCustomLabel(labelId)
                case .Flagged, .Draft, .Sent, .Custom, .Shared, .Search, .Scheduled, .SearchTrashAndSpam:
                    if showShareLabel(labelId) || showInboxLabelAndCustomLabels(labelId) {
                        return true
                    } else {
                        return false
                    }
                case .Unread, .Outbox:
                    return false
                }
            } else {
                /// share mail in view permission
                return showShareLabel(labelId)
            }
        }
        // 包含Important / Other 替换成Inbox 再去重
        filteredLabels = filteredLabels.map({ label -> MailClientLabel in
            if label.id == Mail_LabelId_Important || label.id == Mail_LabelId_Other {
                var newLabel = label
                newLabel.id = Mail_LabelId_Inbox
                return newLabel
            } else {
                return label
            }
        })
        func removeDuplicates(_ array: [MailClientLabel]) -> [MailClientLabel] {
            var result = [MailClientLabel]()
            var containInbox = false
            for value in array {
                if value.id == Mail_LabelId_Inbox {
                    if !containInbox {
                        result.append(value)
                        containInbox = true
                    }
                } else {
                    result.append(value)
                }
            }
            return result
        }

        var uniqueLabels = removeDuplicates(filteredLabels)

        uniqueLabels = uniqueLabels.filter({ !$0.isSystem })

        // label颜色过滤
        uniqueLabels = uniqueLabels.map({ label in
            var newLabel = label
            let config = MailLabelTransformer.transformLabelColor(backgroundColor: label.bgColor)
            var alwaysLight = true
            if FeatureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)), #available(iOS 13.0, *) {
                alwaysLight = false
            }
            if useCssColor {
                // webview使用的色值
                newLabel.fontColor = config.cssFontToHex(alwaysLight: alwaysLight)
                newLabel.bgColor = config.cssBgToHex(alwaysLight: alwaysLight)
            } else {
                // native使用，读信首帧优化，titleView使用native渲染
                newLabel.fontColor = config.fontToHex(alwaysLight: alwaysLight)
                newLabel.bgColor = config.bgToHex(alwaysLight: alwaysLight)
            }
            newLabel.colorType = config.colorType
            print("-------------------------------------- font: \(newLabel.fontColor) bg: \(newLabel.bgColor)")
            return newLabel
        })

        return uniqueLabels
    }
}
