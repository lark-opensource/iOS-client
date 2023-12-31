//
//  SystemContentParser.swift
//  Action
//
//  Created by kongkaikai on 2019/2/17.
//

import UIKit
import Foundation
import LarkModel
import RichLabel
import LarkRichTextCore
import LarkUIKit

public typealias LarkCoreUtils = LarkRichTextCoreUtils

public extension LarkCoreUtils {
    private typealias Key = NSString
    private typealias RangeKey = (range: NSRange, key: Key)
    private typealias SystemContentParseResult = (value: NSString, textLinks: [LKTextLink])
    typealias OnLinkTap = (SystemContent.ContentValue) -> Void
    typealias Result = (text: String, textLinks: [LKTextLink])

    /// 挂起的 style
    static func formSheetStyle() -> UIModalPresentationStyle {
        return .formSheet
    }

    /// 为了解决iphone在modal view下出现键盘问题 而使用的style
    static func autoAdaptStyle() -> UIModalPresentationStyle {
        return Display.phone ? .fullScreen : .formSheet
    }

    // 便于一次替换包装方式
    @inline(__always)
    static private func wap(_ key: NSString) -> String {
        return "{\(key)}"
    }

    static func parseSystemContent(_ content: SystemContent, chatterForegroundColor: UIColor, onLinkTap: OnLinkTap?) -> Result {
        var template: NSString = content.template as NSString
        let contents = content.systemContentValues
        let oldContents = content.values
        let itemActions = content.itemActions
        var rangeOffset = 0
        var textLinks: [LKTextLink] = []
        let wapperLength = ("{}" as NSString).length

        // 获取用于替换的key
        let keys: [Key] = Array(Set(contents.keys).union(oldContents.keys))
            .filter { content.template.contains($0) } as [Key]

        // 获取‘key’对应的从前到后的排序的‘range‘
        let rangekeys = self.sortedRanges(with: keys, template: template)

        // 遍历所有的（range, key）
        for rangekey in rangekeys {
            // 获取对应的 contentValue
            if let contentValue = contents[rangekey.key as String] {

                // 解析contentValue，生成对应的“LKTextLink”(这一步会自动算出Range），以及对应的替换“key”的字符串
                let result = parse(
                    systemType: content.systemType,
                    systemContentValue: contentValue,
                    itemActions: itemActions,
                    with: rangekey.range.location + rangeOffset,
                    chatterForegroundColor: chatterForegroundColor,
                    onLinkTap: onLinkTap,
                    version: content.version
                )

                // 用解析结果中的 “value” 替换掉原有的key
                template = template.replacingCharacters(
                    in: NSRange(location: rangekey.range.location + rangeOffset, length: rangekey.range.length),
                    with: result.value as String
                    ) as NSString

                // 记录新的 TextLink
                textLinks += result.textLinks

                // 算出“key”、“value”替换前后 Range的offset
                rangeOffset += result.value.length - rangekey.key.length - wapperLength
            } else if let value = oldContents[rangekey.key as String] {
                // 用解析结果中的 “value” 替换掉原有的key
                template = template.replacingCharacters(
                    in: NSRange(location: rangekey.range.location + rangeOffset, length: rangekey.range.length),
                    with: value
                    ) as NSString

                // 算出“key”、“value”替换前后 Range的offset
                rangeOffset += (value as NSString).length - rangekey.key.length - wapperLength
            }
        }

        return (template as String, textLinks)
    }

    /// 获取‘key’对应的‘range‘并按照从前到后的顺序排序
    static private func sortedRanges(with keys: [Key], template: NSString) -> [RangeKey] {
        var results = [RangeKey]()

        for key in keys {
            // 如果模板中有对应的key，则记录Key对应的Range
            let range = template.range(of: wap(key))
            if range.location != NSNotFound {
                results.append((range, key))
            }
        }

        // 从前到后排序
        return results.sorted { $0.range.location < $1.range.location }
    }

    /// 解析’SystemContent.SystemContentValue‘，返回‘一段文本’和一组‘TextLink’
    static private func parse(
        systemType: SystemContent.SystemType,
        systemContentValue value: SystemContent.SystemContentValue,
        itemActions: [Int32: SystemContent.SystemMessageItemAction],
        with offset: Int,
        chatterForegroundColor: UIColor,
        onLinkTap: OnLinkTap?,
        version: Int32
    ) -> SystemContentParseResult {

        // save result
        var texts = [String]()
        var textLinks = [LKTextLink]()

        // “，”增加的offset为“，”的长度
        let commaOffset = (BundleI18n.LarkCore.Lark_Legacy_SystemMessageSeparatorComma as NSString).length

        var offset_ = offset
        for (index, singleValue) in value.contentValues.enumerated() {

            // 可点击长度应该是“value”对应的长度
            let length = (singleValue.value as NSString).length
            let range = NSRange(location: offset_, length: length)

            texts.append(singleValue.value)

            let isTapable = self.checkSystemContentIsTapable(
                systemType: systemType,
                contentValue: singleValue,
                itemActions: itemActions,
                version: version
            )
            // 名字本身不可点击的不用生成‘textLink’
            if isTapable {
                let textLink = parse(
                    systemType: systemType,
                    contentValue: singleValue,
                    range: range,
                    chatterForegroundColor: chatterForegroundColor,
                    onLinkTap: onLinkTap
                )
                textLinks.append(textLink)
            }

            // 最后一个名字不用加“,”的长度
            offset_ += length + (index == value.contentValues.count - 1 ? 0 : commaOffset)
        }

        // 关键字之间需要加“，”
        return (texts.joined(separator: BundleI18n.LarkCore.Lark_Legacy_SystemMessageSeparatorComma) as NSString,
                textLinks)
    }

    /// 解析’SystemContent.ContentValue‘，如果可点击则返回‘TextLink’，否则返回’nil‘
    static private func parse(
        systemType: SystemContent.SystemType,
        contentValue value: SystemContent.ContentValue,
        range: NSRange,
        chatterForegroundColor: UIColor,
        onLinkTap: OnLinkTap?
    ) -> LKTextLink {

        let customAttributes: [NSAttributedString.Key: Any]?

        if case .inviteAtChatters = systemType, case .user = value.type {
            customAttributes = [.foregroundColor: chatterForegroundColor.cgColor]
        } else {
            customAttributes = nil
        }

        var textLink = LKTextLink(range: range, type: .link, attributes: customAttributes)
        textLink.linkTapBlock = { (_, _) in
            onLinkTap?(value)
        }

        return textLink
    }

    static private func checkSystemContentIsTapable(
        systemType: SystemContent.SystemType,
        contentValue value: SystemContent.ContentValue,
        itemActions: [Int32: SystemContent.SystemMessageItemAction],
        version: Int32
    ) -> Bool {
        /// .userCheckOthersTelephone 为老的系统消息类型（version = 0）；
        /// 且 SystemContent.ContentValueType 为 .unknown 类型
        /// 因此这里做特化，需要渲染成可点击
        if systemType == .userCheckOthersTelephone { return true }
        if version == 1 {
            // [团队]系统消息做特化。特化原因：老版本也会下发该系统消息，isClickable设置为false，所以新版本需要忽略isClickable
            if systemType == .createTeamChatV2Manager || systemType == .bindChatIntoTeamManager {
                return value.type == .text ? false : true
            }
            var isSupportAction = true
            if value.type == .action, let action = itemActions[value.actionID]?.action {
                return action.isSupportAction()
            }
            return value.isClickable && isSupportAction
        }
        return SystemContent.SystemType.tapableTypes.contains(systemType)
            && SystemContent.ContentValueType.supportLinkTypes.contains(value.type)
    }
}

/// 支持点击的content类型。
/// The types of content can you tap.
fileprivate extension SystemContent.ContentValueType {
    static let supportLinkTypes: [SystemContent.ContentValueType] = [.user, .chatter, .url, .chat, .action, .bot]
}

fileprivate extension SystemContent.SystemMessageItemAction.OneOf_Action {
    func isSupportAction() -> Bool {
        switch self {
        case .chatterTooltip(_):
            return false
        @unknown default:
            return true
        }
    }
}

/// 支持点击的系统消息类型。
/// The types of system message can you tap.
fileprivate extension SystemContent.SystemType {
    static var tapableTypes: [SystemContent.SystemType] {
        return [
            .userStartGroupAndInvite,
            .systemWelcomeUser,
            .userInviteOthersJoin,
            .userQuitGroup,
            .userRemoveOthers,
            .deriveFromP2PChat,
            .userJoinViaShare,
            .transferGroupChatOwner,
            .transferGroupChatOwnerAndQuit,
            .userSyncMessage,
            .userInviteOthersJoinCryptoChat,
            .userStartCryptoGroupAndInvite,
            .userStartGroup,
            .userJoinViaQrCode,
            .userJoinViaGroupLink,
            .userShareDocPermission,
            .userChangeDocPermission,
            .userShareDocFolder,
            .userOpenOnlyAdminPost,
            .userSepecifyMembersPost,
            .userOpenAnyonePost,
            .userStartMeetingGroupAndInvite, // = 35
            .userInviteOthersJoinMeeting, // = 36
            .userQuitMeetingChat, // = 37
            .userDismissedMeetingChat, // = 38
            .userRemoveOthersFromMeeting, // = 40
            .userAddMeetingChat, // = 41
            .inviteChatMember2OutChat, // = 73
            .createChatAndInviteFromChatMember, // = 74
            .autoTranslateGuidance, // = 75,
            .withdrawAddedUser, // = 76
            .inviteAtChatters, // = 88
            .vcMeetingStarted,
            .vcVideoChatStarted,
            .vcCallIntervieweeNoAnswer, // = 101
            .vcCallIntervieweeRefuse, // = 102
            .vcCallInterviewerCancel, // = 103
            .vcCallIntervieweeBusy, // = 104
            .voipIntervieweeNoAnswer, // = 111
            .voipIntervieweeRefuse, // = 112
            .voipInterviewerCancel, // = 113
            .voipIntervieweeBusy, // = 114
            .cancelEmergencyCall, // = 121
            .hangupEmergencyCall, // = 122
            .startEmergencyCall, // = 123
            .meetingTransferToChat, // = 124
            .meetingTransferToChatWithDocURL, // = 125
            .vcCallIntervieweeNotOnline, // = 131
            .voipIntervieweeNotOnline, // = 132
            .userJoinChatAutoMute,
            .emergencyCallNotanswer, // = 139
            .inviteChattersToChatNoPermissionLessThreshold,
            .inviteChattersToChatNoPermissionOverThreshold,
            .saipanRemindOncallReply,
            .saipanRemindOncallDone,
            .saipanRemindOncallAutoDone,
            .saipanAddOncall,
            .userModifyGroupAvatar,
            .userModifyGroupName,
            .userModifyGroupDescription,
            .userTurnOnGroupMail,
            .userTurnOffGroupMail,
            .userChangeGroupMailPermissionOwner,
            .userChangeGroupMailPermissionTenant,
            .userChangeGroupMailPermissionMembers,
            .userChangeGroupMailPermissionEveryone,
            .createP2PSource,
            .userInviteBotJoin, // = 169
            .docTemplateGroupShare,
            .sheetTemplateGroupShare,
            .mindNoteTemplateGroupShare,
            .createCircleAndInviteOthersFromChat,
            .mentionedPersonNotInCircle,
            .inviteMembersToJoinExternalCircle,
            .circleCantAddMembersDueToAdminSettings,
            .circleCantAddManyMembersDueToAdminSettings,
            .joinCircleViaHelpDeskMsgCard,
            .circleWelcomeNewMembers,
            .transferCircleOwner,
            .transferCircleOwnerAndLeave,
            .circleUserChangeDocPermission,
            .userInviteBotJoinCircle,
            .userInviteOthersJoinCircle,
            .userInviteOthersJoinCircleByLink,
            .circleTooManyMembersNotificationMuted,
            .userInviteOthersJoinCircleByQrCode,
            .userInviteOthersJoinCircleByInvitationCard,
            .userModifyCircleAvatar,
            .userModifyCircleDescription,
            .userModifyCircleName,
            .userModifyCircleOwner,
            .userModifyCircleSettings,
            .userSetOnlyCircleOwnerCanPost,
            .userSetOnlyCircleOwnerCanCreateNewTopics,
            .userLeaveCircle,
            .userRemoveCircleDescription,
            .userRemoveCircleMembers,
            .userCreateCircle,
            .userCreateCircleAndInvite,
            .userSyncMessageToCircle,
            .userClearCircleAnnouncement,
            .userWithdrawCircleInvitation,
            .userCreateFaceToFaceChat,
            .welcomeUserJoinFaceToFaceChat,
            .inviteChatMember2Chat,
            .userCreatedGroupAndInvitedOtherChatterChatDepartment,
            .userInviteOthersChatterChatDepartmentJoin,
            .createChatAndInviteFromChatDepartmentMember,
            .userOpenOnlySepecifyMembersPost,
            .userOpenOnlySepecifyMembersPostThread,
            .userRemoveSepecifyMembersPost,
            .userRemoveSepecifyMembersPostThread,
            .userSpecifyMembersPostThread,
            .removeMemberFromAdminList,
            .addMemberToAdminList,
            .userOpenOnlyOwnerAndAdminPost,
            .userOpenOnlyOwnerAndAdminPostThread,
            .adminOpenAnyonePost,
            .adminOpenAnyonePostThread,
            .userChangeGroupMailPermissionOwnerOrAdmin,
            .groupNewMembersViewChatHistoryOn,
            .groupNewMembersViewChatHistoryOff,
            .groupNewMembersCanViewHistoryMessages,
            .circleWelcomeNewMembersNoHistory,
            .userInviteOthersChatterChatDepartmentJoinNew,
            .userInviteOthersChatterChatDepartmentJoinNoHistory,
            .userJoinViaQrNew,
            .userJoinViaQrCodeNoHistory,
            .userJoinChatWelcomeMessage,
            .userJoinChatWelcomeMessageNoHistory,
            .userInviteOthersJoinChatMessage,
            .userInviteOthersJoinChatMessageNoHistory,
            .userJoinViaShareNew,
            .userJoinViaShareNoHistory,
            .userJoinChatByLink,
            .userJoinChatByLinkNoHistory,
            .helpDeskUserJoinChat,
            .helpDeskUserJoinChatNoHistory,
            .upgradeSuperChat,
            // team
            .createTeamAndInviteMembers,
            .updateChatToTeam,
            .inviteMembersJoinTeam,
            .membersJoinTeamFail,
            .transferTeamOwner,
            .modifyTeamName,
            .enableTeamAddMembersPermission,
            .enableTeamCreateChatPermission,
            .closeTeamCreateChatPermission,
            .enableTeamAddMembersPermission,
            .closeTeamAddMembersPermission,
            .dissolveTeamAndUnbindChat,
            .createTeamChat,
            .bindChatIntoTeam,
            .unbindChatWithTeam,
            .membersJoinTeamChatSeeHistorical,
            .membersJoinTeamChatSeeNewMessages,
            .membersJoinTeamChatFail,
            .kickMembersOutTeam,
            .memberLeaveTeam,
            .userCreateTeam,
            .modifyTeamDescription,
            .deleteTeamDescription,
            .createUrgentOnlyOwnerAndAdminOff,
            .modifyTeamAvatar,
            // group admin chore
            .createUrgentOnlyOwnerAndAdminOn,
            .createUrgentOnlyOwnerAndAdminOff
        ]
    }
}
