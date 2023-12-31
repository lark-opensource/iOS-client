//
//  ThreadActionCalculator.swift
//  MailSDK
//
//  Created by NewPan on 2020/3/4.
//

import Foundation
import RustPB
import LKCommonsLogging
import UniverseDesignTheme

enum ActionType: Int {
    case unknown = 0// 不关心的
    case archive
    case trash
    case unRead
    case read
    case spam
    case notSpam
    case moveToInbox
    case changeLabels
    case delete
    case edit
    case flag
    case unFlag
    case deleteDraft
    case deletePermanently
    case moveToOther
    case moveToImportant
    case moveTo
    case cancelScheduleSend
    case cancelAllScheduleSend
    case contentSearch
    
    case sendSeparaly
    case scheduleSend
    case saveDraft
    case discardDraft
    case priority
    case readReceipt
    case contentDarkMode
    case more
    case allowStranger
    case rejectStranger
    case emlAsAttachment
    case blockSender
}

extension ActionType {
    /// 首页用的
    /// - Parameter actionType: actionType description
    /// - Returns: description
    var threadGroupNumber: Int {
        switch self {
        case .moveToImportant, .moveToOther, .moveTo, .changeLabels:
            return 0
        case .spam, .notSpam, .blockSender:
            return 1
        case .emlAsAttachment:
            return 2
        case .contentSearch:
            return 3
        case .unknown, .archive, .trash, .unRead, .read,
                .moveToInbox, .delete, .edit, .flag, .unFlag,
                .deleteDraft, .deletePermanently, .cancelScheduleSend, .cancelAllScheduleSend, .scheduleSend,
                .discardDraft, .saveDraft, .sendSeparaly, .priority, .readReceipt,
                .contentDarkMode, .more, .allowStranger, .rejectStranger :
            return 1000
        }
    }

    /// 读信页用的，UX真天才
    /// - Parameter actionType: actionType description
    /// - Returns: description
    var messageListThreadGroupNumber: Int {
        switch self {
        case .archive, .moveToImportant, .moveToOther, .moveTo, .moveToInbox, .changeLabels:
            return 0
        case .spam, .notSpam, .blockSender:
            return 1
        case .emlAsAttachment:
            return 2
        case .contentDarkMode:
            return 3
        case .contentSearch:
            return 4
        case .unknown, .trash, .unRead, .read, .delete, .edit, .flag, .unFlag,
                .deleteDraft, .deletePermanently, .cancelScheduleSend, .cancelAllScheduleSend,
                .discardDraft, .scheduleSend, .saveDraft, .sendSeparaly, .priority, .readReceipt,
                .more, .allowStranger, .rejectStranger:
            return 1000
        }
    }

    var mailSendGroupNumber: Int {
        switch self {
        case .priority, .readReceipt:
            return 0
        case .scheduleSend,.saveDraft,.discardDraft, .sendSeparaly:
            return 1
        case .unknown, .trash, .unRead, .read, .notSpam, .delete, .edit, .flag, .unFlag,
                .archive, .moveToImportant, .moveToOther, .moveTo, .moveToInbox,
                .deleteDraft, .deletePermanently, .cancelScheduleSend, .cancelAllScheduleSend,
                .changeLabels, .spam, .contentSearch, .contentDarkMode, .more,
                .allowStranger, .rejectStranger, .emlAsAttachment, .blockSender:
            return 1000
        }
    }
}

struct MailIndexedThreadAction: Hashable {
    var action: ActionType
    var index: Int
    var isOnTop: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(action.hashValue)
    }

    static func == (lhs: MailIndexedThreadAction, rhs: MailIndexedThreadAction) -> Bool {
        return lhs.action == rhs.action
    }
}

class MailThreadActionCalculator {
    static let logger = Logger.log(MailThreadActionCalculator.self, category: "Module.MailThreadActionCalculator")

    static func checkEnable(action: ActionType) -> Bool {
        if Store.settingData.mailClient {
            var actions = [ActionType.archive,
                           ActionType.changeLabels,
                           ActionType.spam,
                           ActionType.notSpam]

            if !FeatureManager.open(.newOutbox) {
                actions.append(.edit)
            }

            return !actions.contains(action)
        }

        return true
    }

    /// actions has ordered by PM's doc, do not upset it.
    /// actions 已经按照产品文档排序, 不要打乱循序.
    static func calculateThreadActions(fromLabel: String, labelIDs: [String],
                                       isMutilSelect: Bool, isMessageList: Bool, senderAddresses: [String], myAddress: String? = nil, isRead: Bool? = nil) -> [MailIndexedThreadAction] {
        var actions: [(action: ActionType, isOnTop: Bool)]
        switch fromLabel {
        case MailLabelId.Inbox.rawValue:
            actions = MailLabelId.getInboxThreadActions(labelIDs: labelIDs, isMutilSelect: isMutilSelect, isMessageList: isMessageList, isRead: isRead)
        case MailLabelId.Important.rawValue:
            actions = MailLabelId.getImportantThreadActions(labelIDs: labelIDs, isMutilSelect: isMutilSelect, isMessageList: isMessageList, isRead: isRead)
        case MailLabelId.Other.rawValue:
            actions = MailLabelId.getOtherThreadActions(labelIDs: labelIDs, isMutilSelect: isMutilSelect, isMessageList: isMessageList, isRead: isRead)
        case MailLabelId.Shared.rawValue:
            actions = MailLabelId.getShareThreadActions(labelIDs: labelIDs, isMutilSelect: isMutilSelect, isMessageList: isMessageList, isRead: isRead)
        case MailLabelId.Draft.rawValue:
            actions = MailLabelId.getDraftThreadActions(labelIDs: labelIDs, isMutilSelect: isMutilSelect, senderAddresses: senderAddresses, isMessageList: isMessageList, isRead: isRead, myAddress: myAddress)
        case MailLabelId.Sent.rawValue:
            actions = MailLabelId.getSentThreadActions(labelIDs: labelIDs,
                                                       isMutilSelect: isMutilSelect,
                                                       senderAddresses: senderAddresses,
                                                       isMessageList: isMessageList,
                                                       isRead: isRead,
                                                       myAddress: myAddress)
        case MailLabelId.Archived.rawValue:
            actions = MailLabelId.getArchivedThreadActions(labelIDs: labelIDs, isMutilSelect: isMutilSelect, isMessageList: isMessageList, isRead: isRead)
        case MailLabelId.Trash.rawValue:
            actions = MailLabelId.getTrashThreadActions(labelIDs: labelIDs, isMutilSelect: isMutilSelect, isMessageList: isMessageList, isRead: isRead)
        case MailLabelId.Spam.rawValue:
            actions = MailLabelId.getSpamThreadActions(labelIDs: labelIDs, isMutilSelect: isMutilSelect, isMessageList: isMessageList, isRead: isRead)
        case MailLabelId.Outbox.rawValue:
            actions = MailLabelId.getOutboxThreadActions(labelIDs: labelIDs, isMutilSelect: isMutilSelect, isMessageList: isMessageList)
        case MailLabelId.Scheduled.rawValue:
            actions = MailLabelId.getScheduledThreadActions(labelIDs: labelIDs, isMutilSelect: isMutilSelect, isMessageList: isMessageList, isRead: isRead)
        case MailLabelId.Folder.rawValue:
            actions = MailLabelId.getInboxThreadActions(labelIDs: labelIDs, isMutilSelect: isMutilSelect, isMessageList: isMessageList, isRead: isRead)
        case MailLabelId.Stranger.rawValue:
            if FeatureManager.open(FeatureKey(fgKey: .stranger, openInMailClient: false)) {
                if FeatureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)), #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
                    actions = [(ActionType.contentDarkMode, true)]
                } else {
                    actions = []
                }
            } else {
                actions = MailLabelId.getInboxThreadActions(labelIDs: labelIDs, isMutilSelect: isMutilSelect, isMessageList: isMessageList, isRead: isRead)
            }
        default: // FLAG, SEARCH or custom label
            actions = MailLabelId.getDefaultThreadActions(labelIDs: labelIDs, isMutilSelect: isMutilSelect, isMessageList: isMessageList, isRead: isRead)
        }
        actions = actions.filter({ (action, _) in
            return checkEnable(action: action)
        })
        return actions.enumerated().map { (idx, action) -> MailIndexedThreadAction in
            return MailIndexedThreadAction(action: action.action, index: idx, isOnTop: action.isOnTop)
        }
    }

    static func calculateThreadListThreadActions(fromLabel: String, cellViewModel: MailThreadListCellViewModel) -> [MailIndexedThreadAction] {
        guard let labelIDs = cellViewModel.labelIDs else {
            logger.error("calculateThreadListThreadActions labels is empty")
            return [MailIndexedThreadAction]()
        }
        return calculateThreadActions(fromLabel: fromLabel,
                                      labelIDs: labelIDs,
                                      isMutilSelect: true,
                                      isMessageList: false,
                                      senderAddresses: cellViewModel.senderAddresses,
                                      isRead: nil)
    }

    static func calculateThreadActions(fromLabel: String, cellViewModel: MailThreadListCellViewModel) -> [MailIndexedThreadAction] {
        guard let labelIDs = cellViewModel.labelIDs else {
            logger.error("calculateThreadActions labels is empty")
            return [MailIndexedThreadAction]()
        }
        return calculateThreadActions(fromLabel: fromLabel,
                                      labelIDs: labelIDs,
                                      isMutilSelect: false,
                                      isMessageList: false,
                                      senderAddresses: cellViewModel.senderAddresses,
                                      isRead: nil)
    }

    static func calculateSearchThreadListThreadActions(cellViewModel: MailSearchCellViewModel, fromLabel: String) -> [MailIndexedThreadAction] {
        let fromLabelID: String = {
            if fromLabel == Mail_LabelId_SEARCH {
                return calculateRecommendedLabel(labelIDs: cellViewModel.fullLabels, fromLabel: fromLabel)
            } else {
                return fromLabel
            }
        }()
        return calculateThreadActions(fromLabel: fromLabelID,
                                      labelIDs: cellViewModel.fullLabels,
                                      isMutilSelect: true, isMessageList: false,
                                      senderAddresses: cellViewModel.senderAddresses, isRead: nil)
    }

    static func calculateMessageListThreadActions(fromLabel: String, labelIDs: [String], senders: [String], isRead: Bool, myAddress: String?) -> [MailIndexedThreadAction] {
        calculateThreadActions(fromLabel: fromLabel,
                               labelIDs: labelIDs,
                               isMutilSelect: false,
                               isMessageList: true,
                               senderAddresses: senders,
                               myAddress: myAddress,
                               isRead: isRead)
    }

    static func calculateRecommendedLabel(labelIDs: [String], fromLabel: String) -> String {
        if fromLabel == Mail_LabelId_SEARCH_TRASH_AND_SPAM,
           let folder = MailTagDataManager.shared.getFolderModel(labelIDs) {
            return folder.id
        } else if labelIDs.contains(MailLabelId.Inbox.rawValue) {
            return MailLabelId.Inbox.rawValue
        } else if labelIDs.contains(MailLabelId.Archived.rawValue) {
            return MailLabelId.Archived.rawValue
        } else if labelIDs.contains(MailLabelId.Shared.rawValue) {
            return MailLabelId.Shared.rawValue
        } else if labelIDs.contains(MailLabelId.Sent.rawValue) {
            return MailLabelId.Sent.rawValue
        } else {
            // 默认用 flag 兜底.
            return MailLabelId.Flagged.rawValue
        }
    }

    static func getSearchMutilSelectThreadActions(indexedThreadActions: [MailIndexedThreadAction]) -> [MailIndexedThreadAction] {
        // search 只显示下面这几种，按照List顺序显示
        
        var actionsList: [(action: ActionType, isOnTop: Bool)] = [
            (ActionType.moveToInbox, true),
            (ActionType.trash, true),
            (ActionType.read, true),
            (ActionType.unRead, true),
            (ActionType.moveTo, false)
        ]
        
        if !Store.settingData.mailClient {
            actionsList.insert((ActionType.archive, true), at: 0)
            actionsList.append((ActionType.changeLabels, false))
            actionsList.append((ActionType.spam, false))
        }
        if FeatureManager.open(.emlAsAttachment, openInMailClient: false) {
            actionsList.append(contentsOf: [
                (ActionType.emlAsAttachment, false)
            ])
        }
        if FeatureManager.open(.blockSender, openInMailClient: false) {
            actionsList.append(contentsOf: [
                (ActionType.blockSender, false)
            ])
        }
        
        return indexedThreadActions.compactMap { (action) -> MailIndexedThreadAction? in
            if let index = actionsList.firstIndex(where: { $0.0 == action.action }) {
                return MailIndexedThreadAction(action: action.action, index: index, isOnTop: actionsList[index].isOnTop)
            } else {
                return nil
            }
        }
    }

    static func messageListIsIncomingAndOutgoingMail(senderAddresses: [String], myAddress: String?) -> Bool {
        // 如果发件人除了自己还有别人, 即认为是往来邮件.
        guard let myEmail = myAddress else {
            return false
        }
        let othersAddressed = senderAddresses.filter { (sender) -> Bool in
            !sender.elementsEqual(myEmail)
        }
        if !othersAddressed.isEmpty {
            return true
        }
        return false
    }
}

extension MailLabelId {
    fileprivate static func getDefaultThreadActions(labelIDs: [String], isMutilSelect: Bool, isMessageList: Bool, isRead: Bool?) -> [(ActionType, Bool)] {
        let (threadReadAction, threadFlagAction) = getReadAndFlagThreadActions(labelIDs: labelIDs, isRead: isRead)
        var actions = [(ActionType, Bool)]()
        let moveOrAchive = !labelIDs.contains(MailLabelId.Inbox.rawValue) && labelIDs.contains(MailLabelId.Archived.rawValue) ?
        ActionType.moveToInbox : ActionType.archive
        if FeatureManager.open(.emlAsAttachment, openInMailClient: false) {
            actions.append(contentsOf: [
                (ActionType.emlAsAttachment, false)
            ])
        }
        if isMessageList {
            actions.append(contentsOf: [
                (threadFlagAction, true),
                (ActionType.trash, true),
                (threadReadAction, true),
                (moveOrAchive, false)
            ])
        } else {
            actions.append(contentsOf: [
                (moveOrAchive, true),
                (ActionType.trash, true),
                (threadReadAction, true)
            ])
        }
        
        if FeatureManager.open(FeatureKey(fgKey: .blockSender, openInMailClient: false)) {
            actions.append((ActionType.blockSender, false))
        }
        
        actions.append((ActionType.moveTo, false))
        actions.append(contentsOf: [
            (ActionType.changeLabels, false),
            (ActionType.spam, false)
        ])
        
        if !isMutilSelect && !isMessageList {
            actions.append(contentsOf: [
                (threadFlagAction, false)
            ])
        }
        if isMessageList {
            actions.append((.contentSearch, false))
            if FeatureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)), #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
                actions.append((ActionType.contentDarkMode, false))
            }
        }

        return actions
    }

    fileprivate static func getOutboxThreadActions(labelIDs: [String], isMutilSelect: Bool, isMessageList: Bool) -> [(ActionType, Bool)] {
        var actions = [(ActionType, Bool)]()
        if !isMutilSelect {
            actions.append(contentsOf: [
                (ActionType.delete, true)
            ])
        }
        actions.append((.edit, true))
        if isMessageList {
            actions.append((.contentSearch, true))
            if FeatureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)), #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
                actions.append((ActionType.contentDarkMode, false))
            }
        }
        if FeatureManager.open(FeatureKey(fgKey: .blockSender, openInMailClient: false)) {
            actions.append((ActionType.blockSender, false))
        }
        
        
        return actions
    }

    fileprivate static func getSpamThreadActions(labelIDs: [String], isMutilSelect: Bool, isMessageList: Bool, isRead: Bool?) -> [(ActionType, Bool)] {
        let (threadReadAction, _) = getReadAndFlagThreadActions(labelIDs: labelIDs, isRead: isRead)
        var actions = [(ActionType, Bool)]()
        if FeatureManager.open(.emlAsAttachment, openInMailClient: false) {
            actions.append(contentsOf: [
                (ActionType.emlAsAttachment, false)
            ])
        }
        actions.append(contentsOf: [
            (ActionType.notSpam, !FeatureManager.open(.newSpamPolicy)),
            (ActionType.deletePermanently, true),
            (threadReadAction, true),
            (ActionType.moveTo, false)
        ])
        actions.append((ActionType.changeLabels, false))
        

        if isMessageList {
            actions.append((.contentSearch, false))
            if FeatureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)), #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
                actions.append((ActionType.contentDarkMode, false))
            }
        }
        if FeatureManager.open(FeatureKey(fgKey: .blockSender, openInMailClient: false)) {
            actions.append((ActionType.blockSender, false))
        }
        
        return actions
    }

    fileprivate static func getScheduledThreadActions(labelIDs: [String], isMutilSelect: Bool, isMessageList: Bool, isRead: Bool?) -> [(ActionType, Bool)] {
        let (threadReadAction, threadFlagAction) = getReadAndFlagThreadActions(labelIDs: labelIDs, isRead: isRead)
        var actions = [(ActionType, Bool)]()

        actions.append(contentsOf: [
            (ActionType.trash, true)
        ])
        actions.append(contentsOf: [
            (threadReadAction, true)
        ])
        actions.append(contentsOf: [
            (ActionType.cancelScheduleSend, false)
        ])
        actions.append(contentsOf: [
            (ActionType.cancelAllScheduleSend, false)
        ])
        actions.append((.changeLabels, false))
        if isMessageList {
            actions.append((.contentSearch, false))
            if FeatureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)), #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
                actions.append((ActionType.contentDarkMode, false))
            }
        }
        
        return actions
    }

    fileprivate static func getTrashThreadActions(labelIDs: [String], isMutilSelect: Bool, isMessageList: Bool, isRead: Bool?) -> [(ActionType, Bool)] {
        let (threadReadAction, _) = getReadAndFlagThreadActions(labelIDs: labelIDs, isRead: isRead)
        var actions = [(ActionType, Bool)]()
        if FeatureManager.open(.emlAsAttachment, openInMailClient: false) {
            actions.append(contentsOf: [
                (ActionType.emlAsAttachment, false)
            ])
        }
        if FeatureManager.open(.blockSender, openInMailClient: false) {
            actions.append(contentsOf: [
                (ActionType.blockSender, false)
            ])
        }
        if isMessageList {
            actions.append(contentsOf: [
                (ActionType.deletePermanently, true),
                (threadReadAction, true),
                (ActionType.moveToInbox, false),
                (ActionType.moveTo, false),
                (ActionType.changeLabels, false)
            ])

            actions.append(contentsOf: [
                (ActionType.contentSearch, false)
            ])
            if FeatureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)), #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
                actions.append((ActionType.contentDarkMode, false))
            }
        } else {
            actions.append(contentsOf: [
                (ActionType.moveToInbox, true),
                (ActionType.deletePermanently, true),
                (threadReadAction, true),
                (ActionType.moveTo, false),
                (ActionType.changeLabels, false)
            ])
        }
        return actions
    }

    fileprivate static func getArchivedThreadActions(labelIDs: [String], isMutilSelect: Bool, isMessageList: Bool, isRead: Bool?) -> [(ActionType, Bool)] {
        let (threadReadAction, threadFlagAction) = getReadAndFlagThreadActions(labelIDs: labelIDs, isRead: isRead)
        var actions = [(ActionType, Bool)]()
        if FeatureManager.open(.emlAsAttachment, openInMailClient: false) {
            actions.append(contentsOf: [
                (ActionType.emlAsAttachment, false)
            ])
        }
        if isMessageList {
            actions.append(contentsOf: [
                (threadFlagAction, true),
                (ActionType.trash, true),
                (threadReadAction, true),
                (ActionType.moveToInbox, false)
            ])
        } else {
            actions.append(contentsOf: [
                (ActionType.moveToInbox, true),
                (ActionType.trash, true),
                (threadReadAction, true)
            ])
        }

        actions.append((ActionType.moveTo, false))
        actions.append(contentsOf: [
            (ActionType.changeLabels, false),
            (ActionType.spam, false)
        ])

        if !isMutilSelect && !isMessageList {
            actions.append(contentsOf: [
                (threadFlagAction, false)
            ])
        }
        if isMessageList {
            actions.append((.contentSearch, false))
            if FeatureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)), #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
                actions.append((ActionType.contentDarkMode, false))
            }
        }
        if FeatureManager.open(FeatureKey(fgKey: .blockSender, openInMailClient: false)) {
            actions.append((ActionType.blockSender, false))
        }
        return actions
    }

    fileprivate static func getSentThreadActions(labelIDs: [String], isMutilSelect: Bool, senderAddresses: [String], isMessageList: Bool, isRead: Bool?, myAddress: String?) -> [(ActionType, Bool)] {
        let (threadReadAction, threadFlagAction) = getReadAndFlagThreadActions(labelIDs: labelIDs, isRead: isRead)
        var actions = [(ActionType, Bool)]()
        let isIncomingAndOutgoingMail = MailThreadActionCalculator.messageListIsIncomingAndOutgoingMail(senderAddresses: senderAddresses, myAddress: myAddress)
        var temp: ActionType? = nil
        if labelIDs.contains(MailLabelId.Archived.rawValue) {
            temp = ActionType.moveToInbox
        } else if labelIDs.contains(MailLabelId.Inbox.rawValue) {
            temp = ActionType.archive
        }
        if FeatureManager.open(.emlAsAttachment, openInMailClient: false) {
            actions.append(contentsOf: [
                (ActionType.emlAsAttachment, false)
            ])
        }

        if isMessageList {
            actions.append((threadFlagAction, true))
            actions.append(contentsOf: [
                (ActionType.trash, true),
                (threadReadAction, true)
            ])
            if let temp = temp {
                actions.append((temp, false))
            }
        } else {
            if let temp = temp {
                actions.append((temp, true))
            }
            actions.append(contentsOf: [
                (ActionType.trash, true),
                (threadReadAction, true)
            ])
        }

        actions.append(contentsOf: [
            (ActionType.moveTo, false)
        ])

        actions.append((ActionType.changeLabels, false))
        
        if isIncomingAndOutgoingMail {
            actions.append(contentsOf: [
                (ActionType.spam, false)
            ])
        }

        if !isMutilSelect && !isMessageList {
            actions.append(contentsOf: [
                (threadFlagAction, false)
            ])
        }
        if isMessageList {
            actions.append((.contentSearch, false))
            if FeatureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)), #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
                actions.append((ActionType.contentDarkMode, false))
            }
        }
        return actions
    }

    fileprivate static func getDraftThreadActions(labelIDs: [String], isMutilSelect: Bool, senderAddresses: [String], isMessageList: Bool, isRead: Bool?, myAddress: String?) -> [(ActionType, Bool)] {
        let (threadReadAction, threadFlagAction) = getReadAndFlagThreadActions(labelIDs: labelIDs, isRead: isRead)
        var actions = [(ActionType, Bool)]()
        if isMutilSelect {
            actions.append(contentsOf: [
                (ActionType.deleteDraft, true)
            ])
        }
        if isMessageList {
            actions.append(contentsOf: [
                (threadFlagAction, true)
            ])
        }
        if !isMutilSelect {
            if MailThreadActionCalculator.messageListIsIncomingAndOutgoingMail(senderAddresses: senderAddresses, myAddress: myAddress) {
                actions.append(contentsOf: [
                    (threadReadAction, true)
                ])
            }
        }

        actions.append((ActionType.changeLabels, false))
        if isMessageList {
            if FeatureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)), #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
                actions.append((ActionType.contentDarkMode, false))
            }
        }
        return actions
    }

    fileprivate static func getShareThreadActions(labelIDs: [String], isMutilSelect: Bool, isMessageList: Bool, isRead: Bool?) -> [(ActionType, Bool)] {
        let (threadReadAction, _) = getReadAndFlagThreadActions(labelIDs: labelIDs, isRead: isRead)
        var actions = [(ActionType, Bool)]()
        if !isMutilSelect {
            actions.append(contentsOf: [
                (threadReadAction, true)
            ])
        }
        if isMessageList {
            actions.append((.contentSearch, true))
            if FeatureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)), #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
                actions.append((ActionType.contentDarkMode, false))
            }
        }
        return actions
    }

    fileprivate static func getInboxThreadActions(labelIDs: [String], isMutilSelect: Bool, isMessageList: Bool, isRead: Bool?) -> [(ActionType, Bool)] {
        return getCommonThreadActions(fromLabel: MailLabelId.Inbox.rawValue, labelIDs: labelIDs, isMutilSelect: isMutilSelect, isMessageList: isMessageList, isRead: isRead)
    }

    fileprivate static func getImportantThreadActions(labelIDs: [String], isMutilSelect: Bool, isMessageList: Bool, isRead: Bool?) -> [(ActionType, Bool)] {
        return getCommonThreadActions(fromLabel: MailLabelId.Important.rawValue, labelIDs: labelIDs, isMutilSelect: isMutilSelect, isMessageList: isMessageList, isRead: isRead)
    }

    fileprivate static func getOtherThreadActions(labelIDs: [String], isMutilSelect: Bool, isMessageList: Bool, isRead: Bool?) -> [(ActionType, Bool)] {
        return getCommonThreadActions(fromLabel: MailLabelId.Other.rawValue, labelIDs: labelIDs, isMutilSelect: isMutilSelect, isMessageList: isMessageList, isRead: isRead)
    }

    // Inbox、Important、Other 三个 label 的 actions 基本一样，抽个方法减少代码体积
    static func getCommonThreadActions(fromLabel: String, labelIDs: [String], isMutilSelect: Bool, isMessageList: Bool, isRead: Bool?) -> [(ActionType, Bool)] {
        let (threadReadAction, threadFlagAction) = getReadAndFlagThreadActions(labelIDs: labelIDs, isRead: isRead)
        var actions = [(ActionType, Bool)]()
        if FeatureManager.open(.emlAsAttachment, openInMailClient: false) {
            actions.append(contentsOf: [
                (ActionType.emlAsAttachment, false)
            ])
        }

        if isMessageList {
            actions.append((threadFlagAction, true))
            actions.append(contentsOf: [
                (ActionType.trash, true),
                (threadReadAction, true),
                (ActionType.archive, false)
            ])
        } else {
            actions.append(contentsOf: [
                (ActionType.archive, true),
                (ActionType.trash, true),
                (threadReadAction, true)
            ])
        }

        switch fromLabel {
        case MailLabelId.Important.rawValue:
            actions.append((ActionType.moveToOther, false))
        case MailLabelId.Other.rawValue:
            actions.append((ActionType.moveToImportant, false))
        default:
            break
        }

        actions.append(contentsOf: [
            (ActionType.moveTo, false),
            (ActionType.changeLabels, false),
            (ActionType.spam, false)
        ])
        
        if FeatureManager.open(FeatureKey(fgKey: .blockSender, openInMailClient: false)) {
            actions.append((ActionType.blockSender, false))
        }
        
        if !isMutilSelect && !isMessageList {
            actions.append(contentsOf: [
                (threadFlagAction, false)
            ])
        }
        if isMessageList {
            actions.append((.contentSearch, false))
            if FeatureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)), #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
                actions.append((ActionType.contentDarkMode, false))
            }
        }
        return actions
    }

    static func getReadAndFlagThreadActions(labelIDs: [String], isRead: Bool?) -> (ActionType, ActionType) {
        let threadReadAction: ActionType
        if let isRead = isRead {
            threadReadAction = isRead ? .unRead : .read
        } else {
            threadReadAction = !labelIDs.contains(MailLabelId.Unread.rawValue) ? .unRead : .read
        }

        var threadFlagAction = ActionType.flag
        if labelIDs.contains(MailLabelId.Flagged.rawValue) {
            threadFlagAction = .unFlag
        }
        return (threadReadAction, threadFlagAction)
    }
}
