//
//  MailMessageListActionFactory.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/17.
//

import UIKit
import LKCommonsLogging
import UniverseDesignIcon

class MailMessageListActionFactory {
    static let logger = Logger.log(MailMessageListActionFactory.self, category: "Module.MailMessageListActionFactory")
    private var contentSwitchToLM = true
    struct ActionsStyleConfig {
        let type: ActionType
        let icon: UIImage
        let title: String
        let iconAlwaysTemplate: Bool

        init(type: ActionType, icon: UIImage, title: String, iconAlwaysTemplate: Bool = true) {
            self.type = type
            self.icon = icon
            self.title = title
            self.iconAlwaysTemplate = iconAlwaysTemplate
        }
    }

    func threadActionBarTopActions(threadActions: [MailIndexedThreadAction], labelId: String, autoRead: Bool) -> [ActionsStyleConfig] {
        var items: [ActionsStyleConfig] = []
        let maxDisplayCount = 3
        for action in threadActions {
            /// 最多展示三个.
            if items.count >= maxDisplayCount {
                break
            }

            if !action.isOnTop {
                continue
            }
//                if readFlag, action == .unRead { continue }
//                // spam下面，隐藏删除功能，只保留彻底删除，产品需求
//                if labelId == Mail_LabelId_Spam, action == .trash { continue }
//                if unspamFlag, action == .notSpam, labelId == Mail_LabelId_Spam { continue }
            if let config = getActionConfig(type: action.action) {
                items.append(config)
            } else {
                MailMessageListActionFactory.logger.error("cannot find config for given \(action)")
            }
        }
        return items
    }

    /// 顶部tabbar展示的items
    func messageListTopActions(threadActions: [MailIndexedThreadAction],
                               labelId: String,
                               autoRead: Bool,
                               isShareEmail: Bool,
                               isShareOwner: Bool,
                               isInSharedAccount: Bool,
                               isFullReadMessage: Bool,
                               isFromChat: Bool) -> [ActionsStyleConfig] {
        guard !isFullReadMessage && !isFromChat else {
            // 读全文和chat时，保留搜索
            if let contentSearch = threadActions.first(where: { $0.action == .contentSearch }), let contentSearchConfig = getActionConfig(type: contentSearch.action) {
                return [contentSearchConfig]
            } else {
                return []
            }
        }
        var items: [ActionsStyleConfig] = threadActionBarTopActions(threadActions: threadActions, labelId: labelId, autoRead: autoRead)

        return items
    }

    func getActionConfig(type: ActionType) -> ActionsStyleConfig? {
        switch type {
        case .moveToOther, .moveToImportant:
            MailMessageListActionFactory.logger.debug("smartInbox fg open all")
        default:
            break
        }
        return actionConfigMap[type]
    }

    func threadActionBarMoreActions(threadActions: [MailIndexedThreadAction], labelId: String, forceMore: Bool = false) -> [ActionsStyleConfig] {
        var items: [ActionsStyleConfig] = []
        for item in threadActions {
            if forceMore, let config = getActionConfig(type: item.action) {
                items.append(config)
            } else if !item.isOnTop, let config = getActionConfig(type: item.action) {
                items.append(config)
            }
        }
        return items
    }

    func getSingleDeletePermanentlyAction() -> ActionsStyleConfig? {
        return actionConfigMap[.deletePermanently]
    }

    /// 顶部more按钮点击后展开的项
    func messageListMoreActions(threadActions: [MailIndexedThreadAction], labelId: String, isFullReadMessage: Bool, isFromChat: Bool, isSwitchToLM: Bool = true) -> [ActionsStyleConfig] {
        if self.contentSwitchToLM != isSwitchToLM {
            resetActionConfigMap(isContentLM: !isSwitchToLM)
        }
        guard !isFullReadMessage && !isFromChat else {
            return []
        }
        return threadActionBarMoreActions(threadActions: threadActions, labelId: labelId, forceMore: false)
    }
    
    // 这里原先是直接返回map，改动是因为在切换内容区DM后 按钮的文案和图标要更新，因此要提供一个刷新map的方法
    private lazy var actionConfigMap: [ActionType: ActionsStyleConfig] = {
        return self.getActionConfigMap()
    }()
    
    func resetActionConfigMap(isContentLM: Bool) {
        self.contentSwitchToLM = !isContentLM
        actionConfigMap = self.getActionConfigMap()
    }
    
    private func getActionConfigMap() -> [ActionType: ActionsStyleConfig] {
        var  map = [ActionType.archive: ActionsStyleConfig(type: ActionType.archive,
                                                           icon: UDIcon.archiveOutlined.withRenderingMode(.alwaysTemplate),
                                                           title: BundleI18n.MailSDK.Mail_ThreadList_ActionArchived),
                    ActionType.flag: ActionsStyleConfig(type: ActionType.flag,
                                                        icon: Resources.mail_action_flag.withRenderingMode(.alwaysTemplate),
                                                        title: ""),
                    ActionType.unFlag: ActionsStyleConfig(type: ActionType.unFlag,
                                                          icon: Resources.mail_action_unflag.withRenderingMode(.alwaysOriginal).ud.withTintColor(UIColor.ud.colorfulRed),
                                                        title: ""),
                    ActionType.trash: ActionsStyleConfig(type: ActionType.trash,
                                                         icon: UDIcon.deleteTrashOutlined.withRenderingMode(.alwaysTemplate),
                                                         title: BundleI18n.MailSDK.Mail_ThreadAction_Trash),
                    ActionType.unRead: ActionsStyleConfig(type: ActionType.unRead,
                                                          icon: UDIcon.unreadOutlined.withRenderingMode(.alwaysTemplate),
                                                          title: BundleI18n.MailSDK.Mail_ThreadAction_Unread),
                    ActionType.read: ActionsStyleConfig(type: ActionType.read,
                                                        icon: UDIcon.markReadOutlined.withRenderingMode(.alwaysTemplate),
                                                        title: BundleI18n.MailSDK.Mail_ThreadAction_Read),
                    ActionType.spam: ActionsStyleConfig(type: ActionType.spam,
                                                        icon: UDIcon.spamOutlined.withRenderingMode(.alwaysTemplate),
                                                        title: FeatureManager.open(.newSpamPolicy)
                                                        ? BundleI18n.MailSDK.Mail_MarkSpam_Button
                                                        : BundleI18n.MailSDK.Mail_ReportTrash_ReportMobile),
                    ActionType.notSpam: ActionsStyleConfig(type: ActionType.notSpam,
                                                           icon: UDIcon.notspamOutlined.withRenderingMode(.alwaysTemplate),
                                                           title: FeatureManager.open(.newSpamPolicy)
                                                           ? BundleI18n.MailSDK.Mail_NotSpam_Button
                                                           : BundleI18n.MailSDK.Mail_ThreadAction_NotSpam),
                    ActionType.moveToInbox: ActionsStyleConfig(type: ActionType.moveToInbox,
                                                               icon: UDIcon.inboxOutlined.withRenderingMode(.alwaysTemplate),
                                                               title: BundleI18n.MailSDK.Mail_ThreadAction_Inbox),
                    ActionType.moveToOther: ActionsStyleConfig(type: ActionType.moveToOther,
                                                               icon: UDIcon.inboxOutlined.withRenderingMode(.alwaysTemplate),
                                                               title: BundleI18n.MailSDK.Mail_SmartInbox_MoveToOthers),
                    ActionType.moveToImportant: ActionsStyleConfig(type: ActionType.moveToImportant,
                                                                   icon: UDIcon.priorityOutlined.withRenderingMode(.alwaysTemplate),
                                                                   title: BundleI18n.MailSDK.Mail_SmartInbox_MoveToImportant),
                    ActionType.changeLabels: ActionsStyleConfig(type: ActionType.changeLabels,
                                                                icon: UDIcon.labelChangeOutlined.withRenderingMode(.alwaysTemplate),
                                                                title: BundleI18n.MailSDK.Mail_ThreadAction_ChangeLabels),
                    ActionType.delete: ActionsStyleConfig(type: ActionType.delete,
                                                          icon: UDIcon.deleteTrashOutlined.withRenderingMode(.alwaysTemplate),
                                                          title: BundleI18n.MailSDK.Mail_ThreadAction_Delete),
                    ActionType.edit: ActionsStyleConfig(type: ActionType.edit,
                                                        icon: UDIcon.editOutlined.withRenderingMode(.alwaysTemplate),
                                                        title: BundleI18n.MailSDK.Mail_ThreadAction_Edit),
                    ActionType.deleteDraft: ActionsStyleConfig(type: ActionType.deleteDraft,
                                                               icon: UDIcon.deleteTrashOutlined.withRenderingMode(.alwaysTemplate),
                                                               title: BundleI18n.MailSDK.Mail_ThreadAction_Delete),
                    ActionType.moveTo: ActionsStyleConfig(
                        type: ActionType.moveTo,
                        icon: Resources.mail_action_move_to.withRenderingMode(.alwaysTemplate),
                        title: (Store.settingData.folderOpen() ? BundleI18n.MailSDK.Mail_MovetoFolder_Button : BundleI18n.MailSDK.Mail_ThreadAction_MoveToLabel)),
                    ActionType.cancelAllScheduleSend: ActionsStyleConfig(type: ActionType.cancelAllScheduleSend,
                                                                      icon: UDIcon.sentCancelOutlined.withRenderingMode(.alwaysTemplate),
                                                          title: BundleI18n.MailSDK.Mail_SendLater_CancelAllSend),
                    ActionType.cancelScheduleSend: ActionsStyleConfig(type: ActionType.cancelScheduleSend,
                                                                      icon: UDIcon.sentCancelOutlined.withRenderingMode(.alwaysTemplate),
                                                          title: BundleI18n.MailSDK.Mail_CancelScheduledSend_MenuItem),
                    ActionType.contentSearch: ActionsStyleConfig(type: .contentSearch,
                                                                 icon: UDIcon.searchOutlineOutlined.withRenderingMode(.alwaysTemplate),
                                                                 title: BundleI18n.MailSDK.Mail_Search_SearchInEmail),
                    ActionType.contentDarkMode: ActionsStyleConfig(type: .contentDarkMode,
                                                                   icon: contentSwitchToLM
                                                                   ? UDIcon.dayOutlined.withRenderingMode(.alwaysTemplate)
                                                                   : UDIcon.nightOutlined.withRenderingMode(.alwaysTemplate),
                                                                   title: contentSwitchToLM
                                                                   ? BundleI18n.MailSDK.Mail_SwitchToLightMode_Button
                                                                   : BundleI18n.MailSDK.Mail_SwitchToDarkMode_Button),
                    ActionType.emlAsAttachment: ActionsStyleConfig(type: .emlAsAttachment,
                                                                   icon:UDIcon.attachmentOutlined.withRenderingMode(.alwaysTemplate),
                                                                   title: BundleI18n.MailSDK.Mail_MailAttachment_SendAsAttachment),
                    ActionType.blockSender: ActionsStyleConfig(type: .blockSender,
                                                               icon: UDIcon.blockSenderOutlined,
                                                               title: BundleI18n.MailSDK.Mail_BlockTrust_MenuItem),
            ]
            map[ActionType.deletePermanently] = ActionsStyleConfig(type: .deletePermanently,
                                                                   icon: UDIcon.deleteTrashOutlined.withRenderingMode(.alwaysTemplate),
                                                                   title: BundleI18n.MailSDK.Mail_DeletePermanently_MenuItem)
            return map
    }
    
}
