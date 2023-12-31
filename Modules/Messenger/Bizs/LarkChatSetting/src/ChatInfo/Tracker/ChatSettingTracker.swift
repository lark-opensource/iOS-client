//
//  ChatSettingTracker.swift
//  LarkChatSetting
//
//  Created by kongkaikai on 2019/12/13.
//

import UIKit
import Foundation
import Homeric
import LarkModel
import LKCommonsTracker
import LarkMessengerInterface
import LarkSnsShare
import LarkCore
import RustPB
import UniverseDesignColor

final class ChatSettingTracker {
    static func getShareFromType(isFormQRcodeEntrance: Bool, isFromShare: Bool) -> String {
        var type = ""
        if isFormQRcodeEntrance {
            type = "qrcodeEntrance"
        } else {
            type = isFromShare ? "share" : "add_members"
        }
        return type
    }

    static func getGroupType(isExternal: Bool, isPublic: Bool) -> String {
        var type = ""
        if isExternal {
            type = "external"
        } else {
            type = isPublic ? "public" : "private"
        }
        return type
    }
}

// MARK: - Common
extension ChatSettingTracker {
    static func trackType(chat: Chat) -> String {
        if chat.isPublic {
            if chat.isCrossTenant {
                // 公开外部群（不会有这个情况）
                return ""
            } else {
                // 公开内部群
                return "public"
            }
        } else {
            if chat.isCrossTenant {
                // 私有外部群
                return "external"
            } else {
                // 私有内部群
                return "private"
            }
        }
    }

    static func trackMode(chat: Chat) -> String {
        // 话题
        if chat.chatMode == .threadV2 {
            return "topic"
        }
        // 对话
        return "classic"
    }
}

// MARK: - ChatInfoMemberCellAndItem
extension ChatSettingTracker {
    static func infoMemberIMChatPinClickAddView(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "group_member_add",
                                           "target": "im_group_member_add_view" ]
        if chat != nil {
            params += IMTracker.Param.chat(chat)
        }
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    static func infoMemberIMChatPinClickDelView(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "group_member_del",
                                          "target": "im_group_member_del_view" ]
        if chat != nil {
            params += IMTracker.Param.chat(chat)
        }
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    static func imChatSettingClickAddGroup(chat: Chat) {
        // 创建群组（仅单聊会话设置页面）(27)
        var params: [AnyHashable: Any] = ["click": "group_create",
                                          "target": "im_group_create_view"]
        if chat != nil {
            params += IMTracker.Param.chat(chat)
        }
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    // 点击聊天背景
    static func imChatSettingClickChatBackground(chat: Chat) {
        var params: [AnyHashable: Any] = ["click": "chat_background",
                                          "target": "none"]
        if chat != nil {
            params += IMTracker.Param.chat(chat)
        }
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }
}

// MARK: - ChatInfoMemberView
extension ChatSettingTracker {
    static func infoMemberIMChatSettingClick(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "member_avatar",
                                           "target": "profile_main_view" ]
        if chat != nil {
            params += IMTracker.Param.chat(chat)
        }
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }
}

// MARK: - ChatInfo-Main

extension ChatSettingTracker {
    // ↓↓↓↓ ChatInfoViewModel ↓↓↓↓
//    static func trackShareClick() {
//        Tracker.post(TeaEvent(Homeric.CHAT_CONFIG_SHARE_CLICK))
//    }

//    static func trackAutoTranslateSetting() {
//        Tracker.post(TeaEvent(Homeric.AUTOTRANSLATE_SETTING))
//    }

    static func trackAddNewClick(chatId: String) {
        Tracker.post(TeaEvent(Homeric.CHAT_CONFIG_ADD_MEMBER_CLICK, params: ["source": "chat_config_btn", "chat_id": chatId]))
    }

    static func trackAddNewGroupMemberClick() {
        Tracker.post(TeaEvent(Homeric.ADD_NEW_GROUP_MEMBER_CLICK))
    }

    // 移除置顶
    static func trackRemoveShortCut(chatId: String) {
        Tracker.post(TeaEvent(Homeric.SHORTCUT_CHAT_REMOVE, category: "Feed", params: ["chat_id": chatId]))
    }

    // 添加置顶
    static func trackAddShortCut(chatId: String, isThread: Bool = false) {
        var params = ["chat_id": chatId]
        if isThread {
            params["type"] = "channel"
        }
        Tracker.post(
            TeaEvent(
                Homeric.SHORTCUT_CHAT_ADD,
                category: "Feed",
                params: params
            )
        )
    }

    // 添加或移除置顶
    static func trackTopSet(_ isEnable: Bool) {
        Tracker.post(TeaEvent(Homeric.CHAT_CONFIG_TOP_SET, params: ["set_value": isEnable ? "top" : "untop"]))
    }

    static func trackSetFeedCardsIntoBox(type: String, from: String, chatId: String, isMute: Bool) {
        Tracker.post(TeaEvent(Homeric.MOVE_TO_CHATBOX, params: ["chat_type": type, "set_from": from, "chat_id": chatId, "is_mute": isMute]))
    }

    static func trackDeleteFeedCardsFromBox(type: String, from: String, notification: Bool, chatId: String) {
        Tracker.post(TeaEvent(Homeric.REMOVE_FROM_CHATBOX,
                              params: ["chat_type": type,
                                       "chat_id": chatId,
                                       "set_from": from,
                                       "notification": notification ? "on" : "off"])
        )
    }

    static func trackChat(mute: Bool, chat: Chat) {
        let chatType = chat.trackType
        let chatId = chat.id
        if mute {
            Tracker.post(TeaEvent(Homeric.CHAT_MUTE, params: ["chat_type": chatType, "set_from": "chat_setting", "chat_id": chatId]))
        } else {
            Tracker.post(TeaEvent(Homeric.CHAT_UNMUTE, params: ["chat_type": chatType, "set_from": "chat_setting", "chat_id": chatId]))
        }
    }

    static func trackUnreadPositionSet(_ isLast: Bool) {
        Tracker.post(TeaEvent(Homeric.CHAT_CONFIG_UNREAD_POSITION_SET, params: ["set_value": isLast ? "first" : "last"]))
    }

    static func trackEditNickNameSave(chat: Chat, newName: String) {
        var params = chat.chatInfoForTrack
        params["count"] = newName.count
        Tracker.post(TeaEvent(Homeric.IM_CHAT_CONFIG_EDIT_ALIAS_SAVE_CLICK, params: params))
    }

    static func trackChatNameSave(chat: Chat, newName: String) {
        var params = chat.chatInfoForTrack
        params["count"] = newName.count
        Tracker.post(TeaEvent(Homeric.IM_CHAT_NAME_SAVE_CLICK, params: params))
    }

//    static func trackChatMemberPageShow(chat: Chat) {
//        Tracker.post(TeaEvent(Homeric.IM_CHAT_MENBER_PAGE_SHOW, params: chat.chatInfoForTrack))
//    }

    static func trackExitChatClick(chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_EXIT_CHAT_CLICK, params: chat.chatInfoForTrack))

        var params: [AnyHashable: Any] = [ "click": "confirm",
                                           "target": "none" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_QUIT_GROUP_CONFIRM_CLICK, params: params))
    }

    enum TransmitChatOwnerSource: String {
        case chatManage = "chat_manage"
        case chatExit = "chat_exit"
    }

    static func trackTransmitChatOwner(chat: Chat, source: TransmitChatOwnerSource) {
        var params = chat.chatInfoForTrack
        params["source"] = source.rawValue
        Tracker.post(TeaEvent(Homeric.IM_CHAT_MANAGE_ASSIGN_OWNER_CONFIRM_CLICK, params: params))
    }
}

// MARK: - ChatInfo-GroupInfo

extension ChatSettingTracker {
//    static func trackAvatarClick() {
//        Tracker.post(TeaEvent(Homeric.CHAT_CONFIG_AVATAR_CLICK))
//    }

//    static func trackNameEditClick() {
//        Tracker.post(TeaEvent(Homeric.CHAT_CONFIG_NAME_EDIT_CLICK))
//    }

//    static func trackDescEditClick() {
//        Tracker.post(TeaEvent(Homeric.CHAT_CONFIG_DESC_EDIT_CLICK))
//    }

    // GroupInfo - QRCode
//    static func saveGroupQRCodeImage(
//        isExternal: Bool,
//        isPublic: Bool,
//        isFormQRcodeEntrance: Bool,
//        isFromShare: Bool
//    ) {
//        let type = getGroupType(isExternal: isExternal, isPublic: isPublic)
//        let shareFromType = getShareFromType(isFormQRcodeEntrance: isFormQRcodeEntrance, isFromShare: isFromShare)
//        Tracker.post(TeaEvent(Homeric.QRCODE_SAVE, params: ["type": type, "source": shareFromType]))
//    }

    static func shareGroupQRCodeImage() {
        Tracker.post(TeaEvent(Homeric.QRCODE_SHARE))
    }

//    static func chatQRcodeShareToWechat(
//        isExternal: Bool,
//        isPublic: Bool
//    ) {
//        let type = self.getGroupType(isExternal: isExternal, isPublic: isPublic)
//        Tracker.post(
//            TeaEvent(
//                Homeric.CHAT_QRCODE_SHARE_TO_WECHAT,
//                params: ["type": type]
//            )
//        )
//    }

    static func chatQRcodeShareChannel(
        type: LarkShareItemType,
        isExternal: Bool,
        isPublic: Bool,
        chat: Chat
    ) {
        var channel = ""
        switch type {
        case .wechat:
            channel = "wechat"
        case .weibo:
            channel = "weibo"
        case .qq:
            channel = "qq"
        case .more(let ctx):
            channel = "more"
        case .custom:
            channel = "feishu"
        default:
            break
        }

        /// 在「群二维码/群链接分享途径选择」页面，发生动作（71）
        var params: [AnyHashable: Any] = [ "click": "lark",
                                           "target": "public_multi_select_share_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_GROUP_QR_LINK_SHARE_TO_CLICK, params: params))

        let type = self.getGroupType(isExternal: isExternal, isPublic: isPublic)
        Tracker.post(
            TeaEvent(
                Homeric.CHAT_QRCODE_SHARE_CHANNEL,
                params: ["channel": channel, "type": type]
            )
        )
    }
}

// MARK: - ChatInfo-GroupChatter

extension ChatSettingTracker {
    static func trackRemoveMemberClick(chat: Chat) {
        Tracker.post(TeaEvent(Homeric.CHAT_CONFIG_REMOVE_MEMBER_CLICK))
        Tracker.post(TeaEvent(Homeric.IM_GROUP_MEMBER_DEL_VIEW, params: IMTracker.Param.chat(chat)))
    }

    static func trackFindMemberClick(chat: Chat) {
        Tracker.post(TeaEvent(Homeric.CHAT_CONFIG_FIND_MEMBER_CLICK))
        ///在「移除群成员」页面，发生动作事件(80)
        var params: [AnyHashable: Any] = [ "click": "search",
                                           "target": "none" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_GROUP_MEMBER_DEL_CLICK, params: params))
    }

    static func filterNonTeamMembers() {
        Tracker.post(TeaEvent(Homeric.FILTER_NON_TEAM_MEMBERS))
    }
}

// MARK: - ChatInfo-GroupSetting
extension ChatSettingTracker {
//    static func viewJoinLeaveHistory() {
//        Tracker.post(TeaEvent(Homeric.VIEW_JOIN_LEAVER_HISTORY))
//    }

    /// 转让群主
//    static func trackTransferClick(chatId: String) {
//        Tracker.post(TeaEvent(Homeric.CHAT_CONFIG_TRANSFER_CLICK))
//        Tracker.post(TeaEvent(Homeric.IM_CHAT_GR_TRANSFER, params: ["chat_id": chatId]))
//    }

    /// 退出群组
    static func trackExitGroup(chat: Chat) {
        let params = ["type": trackType(chat: chat), "mode": trackMode(chat: chat)]
        Tracker.post(TeaEvent(Homeric.GROUP_EXIT, params: params))
        Tracker.post(TeaEvent(Homeric.IM_CHAT_GR_QUIT_CLICK, params: ["chat_id": chat.id]))
        Tracker.post(TeaEvent(Homeric.IM_QUIT_GROUP_CONFIRM_VIEW, params: IMTracker.Param.chat(chat)))
    }

    /// 群发言权限设置
    static func groupSettingPermission(chatID: String, type: Chat.PostType, chatType: Chat.ChatMode) {
        var chatTypeStr = ""
        if chatType == .threadV2 {
            chatTypeStr = "group_topic"
        } else {
            chatTypeStr = "group"
        }

        var typeStr = ""
        switch type {
        case .anyone:
            typeStr = "anyone"
        case .onlyAdmin:
            typeStr = "only_admin"
        case .whiteList:
            typeStr = "onlyCertain"
        @unknown default:
            typeStr = "anyone"
        }

        let param = ["chatid": chatID,
                     "type": typeStr,
                     "chat_type": chatTypeStr]

        Tracker.post(TeaEvent(Homeric.GROUP_SETTING_PERMISSION, params: param))
    }

    static func invalidateGroupShareHistory() {
        Tracker.post(TeaEvent(Homeric.INVALIDATE_GROUP_SHARE_HISTORY_MOBILE))
    }

    static func trackQrcodeShareConfirmed(
        isExternal: Bool,
        isPublic: Bool,
        isFormQRcodeEntrance: Bool,
        isFromShare: Bool
    ) {
        let type = self.getGroupType(isExternal: isExternal, isPublic: isPublic)
        let shareFromType = self.getShareFromType(
            isFormQRcodeEntrance: isFormQRcodeEntrance,
            isFromShare: isFromShare
        )
        Tracker.post(TeaEvent(Homeric.QRCODE_SHARE_CONFIRMED, params: ["type": type, "source": shareFromType]))
    }
}

// MARK: - Edu
extension ChatSettingTracker {
    // 家校群二维码页面点击【分享】按钮，点击一次上报一次：
    enum EduShareChannelScene: Int {
        case qrcode = 1 // 群二维码
        case link = 2 // 邀请链接
    }

    /// 在「会话设置」页面，发生动作事件(25)
    static func imChatSettingClickPersonShare(chat: Chat) {
        var params: [AnyHashable: Any] = ["click": "share_profile",
                                          "target": "public_multi_select_share_view"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    /// 在「会话设置」页面，发生动作事件(26)
    static func imChatSettingClickShare(chat: Chat) {
        var params: [AnyHashable: Any] = ["click": "share_group_card",
                                          "target": "im_share_group_view"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }
}

// MARK: - ChatInfo-GroupSetting-Approve

extension ChatSettingTracker {
    static func trackGroupApplicationPass() {
        Tracker.post(TeaEvent(Homeric.GROUP_APPLICATION_PASS))
    }

    static func trackGroupApplicationReject() {
        Tracker.post(TeaEvent(Homeric.GROUP_APPLICATION_REJECT))
    }

    static func trackJoinGroupByGroupCard(isMember: Bool, isExternal: Bool, isPublic: Bool) {
        let type = self.getGroupType(isExternal: isExternal, isPublic: isPublic)
        Tracker.post(TeaEvent(Homeric.JOIN_GROUP_BY_GROUP_CARD, params: [
            "type": type,
            "action": isMember ? "enterjoinedgroup" : "joinnewgroup"
        ]))
    }

    static func trackJoinGroupByQRCode(isMember: Bool, isExternal: Bool, isPublic: Bool) {
        let type = self.getGroupType(isExternal: isExternal, isPublic: isPublic)
        Tracker.post(TeaEvent(Homeric.JOIN_GROUP_BY_QRCODE, params: [
            "type": type,
            "action": isMember ? "enterjoinedgroup" : "joinnewgroup"
        ]))
    }

    static func trackApplyToInviteMember(_ hasNote: Bool) {
        Tracker.post(TeaEvent(Homeric.APPLY_TO_INVITE_MEMBER_TO_THE_GROUP, params: ["is_note": hasNote ? "y" : "n"]))
    }

    static func trackApplyToJoinGroupByGroupCard(_ hasNote: Bool) {
        Tracker.post(TeaEvent(Homeric.APPLY_TO_JOIN_GROUP_BY_GROUP_CARD, params: ["is_note": hasNote ? "y" : "n"]))
    }

    static func trackApplyToJoinGroupByQRCode(_ hasNote: Bool) {
        Tracker.post(TeaEvent(Homeric.APPLY_TO_JOIN_GROUP_BY_QRCODE, params: ["is_note": hasNote ? "y" : "n"]))
    }
}

// 新设置页埋点方法
extension ChatSettingTracker {
    enum TransferGroupSource: String {
        case manageGroup = "manage_group"
        case exitGroup = "exit_group"
    }

    /// 新设置页埋点方法: 更改入群验证
    static func newTrackApproveInvitationSetting(_ isOn: Bool, memberCount: Int, chatId: String) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_MANAGE_MEMBERSHIP_APPROVAL_SWITCH,
                              params: ["status": isOn ? "off_to_on" : "on_to_off",
                                       "chat_id": chatId,
                                       "member_count": "\(memberCount)"
                              ]))
    }

    /// 新设置页埋点方法:更改新成员进群的系统消息提示策略
    static func newTrackChatManageEnterGroup(_ type: Chat.SystemMessageVisible.Enum, memberCount: Int, chatId: String) {
        let status: String
        switch type {
        case .allMembers:
            status = "everyone"
        case .onlyOwner:
            status = "admin_only"
        case .notAnyone:
            status = "no_one"
        case .unknown:
            status = "unknown"
        @unknown default:
            status = "unknown"
        }
        Tracker.post(TeaEvent(Homeric.IM_CHAT_MANAGE_ENTER_GROUP_NOTICE_SETTING,
                              params: ["status": status,
                                       "chat_id": chatId,
                                       "member_count": "\(memberCount)"
                              ]))
    }

    /// 新设置页埋点方法: 更改新成员退群的系统消息提示策略
    static func newTrackChatManageLeaveGroup(_ type: Chat.SystemMessageVisible.Enum, memberCount: Int, chatId: String) {
        let status: String
        switch type {
        case .allMembers:
            status = "everyone"
        case .onlyOwner:
            status = "admin_only"
        case .notAnyone:
            status = "no_one"
        case .unknown:
            status = "unknown"
        @unknown default:
            status = "unknown"
        }
        Tracker.post(TeaEvent(Homeric.IM_CHAT_MANAGE_EXIT_GROUP_NOTICE_SETTING,
                              params: ["status": status,
                                       "chat_id": chatId,
                                       "member_count": "\(memberCount)"
                              ]))
    }

    /// 新设置页埋点方法: 更改谁可以向此群发邮件设置项
    static func mailPermissionTrack(_ type: ChatSettingMailPermissionType, memberCount: Int, chatId: String) {
        let status: String
        switch type {
        case .unknown:
            status = "unknown"
        case .groupAdmin:
            status = "admin_only"
        case .groupMembers:
            status = "group_member"
        case .organizationMembers:
            status = "team_member"
        case .all:
            status = "everyone"
        case .allNot:
            status = "no_one"
        }
        Tracker.post(TeaEvent(Homeric.IM_CHAT_MANAGE_SEND_EMAIL_PERMISSION_SETTING,
                              params: ["status": status,
                                       "chat_id": chatId,
                                       "member_count": "\(memberCount)"
                              ]))
    }

    /// 新设置页埋点方法: 限制发言权限点击确认
    static func newBanningSettingType(_ type: Chat.PostType, memberCount: Int, enabledMbrCount: Int, chatId: String) {
        let enabled_count: Int
        let status: String
        switch type {
        case .anyone:
            status = "everyone"
            enabled_count = memberCount
        case .onlyAdmin:
            status = "admin_only"
            enabled_count = 1
        case .whiteList:
            status = "few_member"
            enabled_count = enabledMbrCount
        case .unknownPostType:
            status = "unknown"
            enabled_count = 0
        @unknown default:
            assert(false, "new value")
            status = "unknown"
            enabled_count = 0
        }
        Tracker.post(TeaEvent(Homeric.IM_CHAT_MANAGE_MSG_PERMISSION_SETTING,
                              params: ["status": status,
                                       "chat_id": chatId,
                                       "enabled_count": "\(enabled_count)",
                                       "member_count": "\(memberCount)"
                              ]))
    }

    /// 新设置页埋点方法: 更改仅群主可编辑群信息开关
//    static func newEditInfo(isOn: Bool, memberCount: Int, chatId: String) {
//        Tracker.post(TeaEvent(Homeric.IM_CHAT_MANAGE_EDIT_GROUP_INFO_SWITCH,
//                              params: ["status": isOn ? "off_to_on" : "on_to_off",
//                                       "chat_id": chatId,
//                                       "member_count": "\(memberCount)"
//                              ]))
//    }

    /// 新设置页埋点方法: 仅群主可添加群成员、分享群
//    static func newShareAndAddNewPermission(isOn: Bool, memberCount: Int, chatId: String) {
//        Tracker.post(TeaEvent(Homeric.IM_CHAT_MANAGE_SHARE_GROUP_SWITCH,
//                              params: ["status": isOn ? "off_to_on" : "on_to_off",
//                                       "chat_id": chatId,
//                                       "member_count": "\(memberCount)"
//                              ]))
//
//    }

    /// 新设置页埋点方法: 更改仅群主可@all开关
//    static func newAtAll(isOn: Bool, memberCount: Int, chatId: String) {
//        Tracker.post(TeaEvent(Homeric.IM_CHAT_MANAGE_AT_ALL_SWITCH,
//                              params: ["status": isOn ? "off_to_on" : "on_to_off",
//                                       "chat_id": chatId,
//                                       "member_count": "\(memberCount)"
//                              ]))
//    }

    /// 新设置页埋点方法: 点击查看群成员进退群历史
    static func newViewJoinLeaveHistory(chatId: String) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_MANAGE_JOIN_LEAVE_HISTORY_CLICK,
                              params: ["chat_id": chatId]))
    }

    /// 新设置页埋点方法: 点击查看群分享历史
    static func newShareHistoryClick(chatId: String) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_MANAGE_SHARING_HISTORY_CLICK,
                              params: ["chat_id": chatId]))
    }

    /// 新设置页埋点方法: 转让群主
    static func newTrackTransferClick(source: TransferGroupSource, chatId: String, chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_MANAGE_ASSIGN_GROUP_OWNER_PAGE_VIEW,
                              params: ["source": source.rawValue,
                                       "chat_id": chatId
                              ]))
        var params: [AnyHashable: Any] = [ "click": "transfer_group_owner",
                                           "target": "none" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_QUIT_GROUP_CONFIRM_CLICK, params: params))
    }

    /// 新设置页埋点方法: 转为普通群组（会议群）
    static func newTrackToNormalGroupClicked(createTime: TimeInterval, chatId: String) {
        let currentTIme: TimeInterval = NSDate().timeIntervalSince1970
        let hours = Int(currentTIme - createTime) / 3600
        Tracker.post(TeaEvent(Homeric.IM_CHAT_MANAGE_CONVERT_TO_STANDARD_GROUP_CLICK,
                              params: ["time_lapse_since_group_created": "\(hours)",
                                       "chat_id": chatId
                              ]))
    }
}

// 会议群转普通群
extension ChatSettingTracker {
    static func trackToNormalGroupPopupClicked(_ accept: Bool) {
        Tracker.post(TeaEvent(Homeric.CAL_TRANSFORM_POPUP, params: [
            "action_type": accept ? "yes" : "no",
            "source": "setting"
        ]))
    }
}

extension ChatSettingTracker {
    static func trackSwitchMailSend(on: Bool) {
        Tracker.post(
            TeaEvent(
                Homeric.EMAIL_GROUP_SETTINGS_CHANGED,
                params: ["switch": on ? 1 : 0]
            )
        )
    }
}

// MARK: 群链接
extension ChatSettingTracker {
    static func trackChatLinkCreate(
        isFromChatShare: Bool,
        isFromShareLink: Bool,
        isExternal: Bool,
        isPublic: Bool
    ) {
        var source = ""
        if isFromShareLink {
            source = isFromChatShare ? "share_share" : "add_members_share"
        } else {
            source = isFromChatShare ? "share_copy" : "add_members_copy"
        }

        let type = self.getGroupType(isExternal: isExternal, isPublic: isPublic)
        Tracker.post(
            TeaEvent(
                Homeric.CHAT_LINK_CREATE,
                params: ["source": source, "type": type]
            )
        )
    }

    static func trackChatLinkShareChannel(
        type: LarkShareItemType,
        isExternal: Bool,
        isPublic: Bool
    ) {
        var channel = ""
        switch type {
        case .wechat:
            channel = "wechat"
        case .weibo:
            channel = "weibo"
        case .qq:
            channel = "qq"
        case .copy:
            channel = "copy"
        case .more:
            channel = "more"
        case .custom:
            channel = "feishu"
        default:
            break
        }

        let type = self.getGroupType(isExternal: isExternal, isPublic: isPublic)
        Tracker.post(
            TeaEvent(
                Homeric.CHAT_LINK_SHARE_CHANNEL,
                params: ["channel": channel, "type": type]
            )
        )
    }

//    static func trackChatLinkShareToWechat(
//        isExternal: Bool,
//        isPublic: Bool
//    ) {
//        let type = self.getGroupType(isExternal: isExternal, isPublic: isPublic)
//        Tracker.post(
//            TeaEvent(
//                Homeric.CHAT_LINK_SHARE_TO_WECHAT,
//                params: ["type": type]
//            )
//        )
//    }
}

// MARK: GroupInfoViewController
extension ChatSettingTracker {
    static func trackerInfoIMDeitGroupInfoView(chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_INFO_VIEW, params: IMTracker.Param.chat(chat)))
    }
}

// MARK: 群头像定制
extension ChatSettingTracker {
    /// 在群设置里的首页面，点击“群头像区域"进入群头像的设置页面
    static func trackGroupProfilePicEnter() {
        Tracker.post(TeaEvent(Homeric.GROUPPROFILE_PIC_ENTER))
    }

    /// 在群设置里，点击群名称后，点击“群头像”，进去群头像设置页面
    static func trackGroupProfileNameEnter(chat: Chat) {
        Tracker.post(TeaEvent(Homeric.GROUPPROFILE_NAME_ENTER))
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_AVATAR_VIEW, params: IMTracker.Param.chat(chat)))
    }

    /// 在群头像设置里，点击“保存”按钮群头像（53）
    static func trackGroupProfileSave(chat: Chat) {
        Tracker.post(TeaEvent(Homeric.GROUPPROFILE_SAVE))
        var params: [AnyHashable: Any] = [ "click": "save",
                                           "target": "im_edit_group_info_view"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_AVATAR_CLICK, params: params))
    }

    /// 上传头像图片（54）
    static func trackGroupProfileUploadAvatarPictures(chatInfo: [String: Any]) {
        var params: [AnyHashable: Any] = [ "click": "avatar_image",
                                           "target": "none"]
        guard let chat = chatInfo["chat"] as? Chat else { return }
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_AVATAR_CLICK, params: params))
    }

    /// custom_text_avatar：自定义文字头像(是否选择了文字头像)（56）
    static func trackGroupProfileCustomTextAvatarUnchoose(chatInfo: [String: Any]) {
        var params: [AnyHashable: Any] = [ "click": "custom_text_avatar",
                                           "target": "none",
                                           "status": "choose_to_unchoose"]
        guard let chat = chatInfo["chat"] as? Chat else { return }
        params += IMTracker.Param.chat(chat)
        //取消选择文字头像
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_AVATAR_CLICK, params: params))
    }

    /// custom_text_avatar：自定义文字头像(是否选择了文字头像)（56）
    static func trackGroupProfileCustomTextAvatarChoose(chatInfo: [String: Any]) {
        var params: [AnyHashable: Any] = [ "click": "custom_text_avatar",
                                           "target": "none",
                                           "status": "unchoose_to_choose"]
        guard let chat = chatInfo["chat"] as? Chat else { return }
        params += IMTracker.Param.chat(chat)
        //选择文字头像
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_AVATAR_CLICK, params: params))
    }

    /// avatar_text：头像文字输入框（57）
    static func trackGroupProfileAvatarTextInputBox(chatInfo: [String: Any]) {
        var params: [AnyHashable: Any] = [ "click": "avatar_text",
                                           "target": "none"]
        guard let chat = chatInfo["chat"] as? Chat else { return }
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_AVATAR_CLICK, params: params))
    }

    /// avatar_color：头像颜色选择（58）（59）
    static func trackGroupProfileAvatarColorSelection(_ color: UIColor, chatInfo: [String: Any]) {
        var colorString = ""
        if color.isEqual(to: UIColor.ud.colorfulBlue) {
            colorString = "colorfulBlue"
        } else if color.isEqual(to: UIColor.ud.colorfulPurple) {
            colorString = "colorfulPurple"
        } else if color.isEqual(to: UIColor.ud.T600) {
            colorString = "T600"
        } else if color.isEqual(to: UIColor.ud.G600) {
            colorString = "G600"
        } else if color.isEqual(to: UIColor.ud.L600) {
            colorString = "L600"
        } else if color.isEqual(to: UIColor.ud.Y600) {
            colorString = "Y600"
        } else if color.isEqual(to: UIColor.ud.O600) {
            colorString = "O600"
        } else if color.isEqual(to: UIColor.ud.colorfulCarmine) {
            colorString = "colorfulCarmine"
        }
        var params: [AnyHashable: Any] = [ "click": "avatar_color",
                                           "target": "none",
                                           "color": colorString]
        guard let chat = chatInfo["chat"] as? Chat else { return }
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_AVATAR_CLICK, params: params))
    }

    /// cancel：取消（60）
    static func trackGroupProfileCancel(chatInfo: [String: Any]) {
        var params: [AnyHashable: Any] = [ "click": "cancel",
                                           "target": "im_edit_group_info_view"]
        guard let chat = chatInfo["chat"] as? Chat else { return }
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_AVATAR_CLICK, params: params))
    }
}

extension UIColor {
    func isEqual(to otherColor: UIColor) -> Bool {
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        otherColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return (NSInteger)((r1 - r2) * 255) == 0 &&
               (NSInteger)((g1 - g2) * 255) == 0 &&
               (NSInteger)((b1 - b2) * 255) == 0 &&
               (NSInteger)((a1 - a2) * 255) == 0
    }
}

// MARK: MessengerChatExtension
extension ChatSettingTracker {
    // 在群设置里点击群公告
    static func trackClickAnnouncementWithType(_ type: RustPB.Basic_V1_Chat.TypeEnum) {
        var str = ""
        switch type {
        case .p2P:
            str = "p2P"
        case .group:
            str = "group"
        case .topicGroup:
            str = "topicGroup"
        @unknown default:
            break
        }
        Tracker.post(TeaEvent(Homeric.ANNOUNCEMENT_VIEW,
                              params: ["announcement_view_loacation": "sidebar", "chat_type": str]))
    }

    // 在设置里点击搜索
//    static func trackClickHistory(chatType: Int) {
//        Tracker.post(TeaEvent(Homeric.CLICK_CHAT_HISTORY,
//                              params: ["chat_type": chatType]))
//    }
}

enum ChatSettingDeleteMemberSource: String {
    case sectionDel = "section_del_mobile"
    case listMore = "list_more_mobile"
    case swipe_mobile = "item_swipe_mobile"
}

enum ChatSettingCheckGroupQRCodeSource: String {
    case shareIcon = "share_icon"
    case qrCodeCell = "qr_code_cell"
}

// MARK: 新群设置页打点
struct NewChatSettingTracker {
    // 点击群信息section
    static func imChatSettingInfoClick(chatId: String, isAdmin: Bool) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_INFO_CLICK,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue
                              ]))
    }

    static func imChatSettingClickEditGroupInfo(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "edit_group_info",
                                           "target": "im_edit_group_info_view"]
        params += IMTracker.Param.chat(chat)
        //「群信息编辑」页面（17）
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }
    // 在群信息中点击修改群头像
    static func imChatSettingEditAvatarClick(chatId: String, isAdmin: Bool, chat: Chat) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_EDIT_AVATAR_CLICK,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue
                              ]))
    }

    // 点击保存群头像修改
    static func imChatSettingEditAvatarSaveClick(chatId: String,
                                                 isAdmin: Bool,
                                                 isUploadPhoto: Bool,
                                                 isChooseTitle: Bool,
                                                 titleIndex: Int,
                                                 isInputTitle: Bool,
                                                 isChooseColor: Bool,
                                                 colorHex: Int32) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_EDIT_AVATAR_SAVE_CLICK,
                              params: ["chat_id": chatId,
                                       "upload_photo": isUploadPhoto,
                                       "choose_title": isChooseTitle,
                                       "title_char_order": "\(titleIndex)",
                                       "imput_title": isInputTitle,
                                       "choose_color": isChooseColor,
                                       "color_selection": "\(colorHex)",
                                       "member_type": memberType.rawValue
                              ]))
    }

    static func variousAvatarSaveClick(chat: Chat,
                                       isWord: Bool,
                                       isImage: Bool,
                                       isFill: Bool,
                                       isTick: Bool,
                                       isEnter: Bool) {
        func stringValueFor(_ value: Bool) -> String {
            return value ? "true" : "false"
        }
        var params: [AnyHashable: Any] = [ "click": "save",
                                           "target": "none",
                                           "is_image": stringValueFor(isImage),
                                           "is_word": stringValueFor(isWord),
                                           "color_type": isFill ? "fill" : "border",
                                           "is_tick": stringValueFor(isTick),
                                           "is_enter": stringValueFor(isEnter)]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("im_edit_group_avatar_click", params: params))
    }

    /// 保存群头像
    static func genericAvatarSaveClick(chat: Chat, trackInfo: GenericAvatarTrackInfo) {

        func stringValueFor(_ value: Bool) -> String {
            return value ? "true" : "false"
        }
        var params: [AnyHashable: Any] = [ "click": "save",
                                           "target": "none",
                                           "is_image": stringValueFor(trackInfo.isImage),
                                           "is_word": stringValueFor(trackInfo.isWord),
                                           "color_type": trackInfo.colorType,
                                           "is_stiching": trackInfo.isStiching,
                                           "is_customize": stringValueFor(trackInfo.isCustomize),
                                           "start_color": trackInfo.startColor,
                                           "end_color": trackInfo.endColor,
                                           "is_recommend": stringValueFor(trackInfo.isRecommend)]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("im_edit_group_avatar_click", params: params))
    }

    // 在群信息中点击修改群名称
    static func imChatSsettingEditTitleClick(chatId: String, isAdmin: Bool) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_EDIT_TITLE_CLICK,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue
                              ]))
    }

    static func imEditGroupInfoGroupNameClick(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "group_name",
                                           "target": "im_edit_group_name_view"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_INFO_CLICK, params: params))
    }

    static func imEditGroupInfoGroupAvatarClick(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "group_avatar",
                                           "target": "im_edit_group_avatar_view"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_INFO_CLICK, params: params))
    }

    /// (群名称编辑)页面（61）
    static func imEditGroupNameView(chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_NAME_VIEW, params: IMTracker.Param.chat(chat)))
    }

    /// 在(群名称编辑)页面，发生动作事件（62）
    static func imEditGroupNameSaveClick(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "save",
                                           "target": "im_edit_group_info_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_NAME_CLICK, params: params))
    }

    // 点击保存群名称
    static func imChatSettingEditTitleSaveClick(chatId: String,
                                                isAdmin: Bool,
                                                altered: Bool,
                                                charCount: Int) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_EDIT_TITLE_SAVE_CLICK,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue,
                                       "altered": altered,
                                       "char_count": charCount
                              ]))
    }

    // 在群信息中点击修改群描述
    static func imChatSettingEditDescriptionClick(chatId: String, isAdmin: Bool) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_EDIT_DESCRIPTION_CLICK,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue
                              ]))
    }

    static func imEditGroupInfoDescriptionClick(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "group_description",
                                           "target": "im_edit_group_description_view"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_INFO_CLICK, params: params))
    }

    // 点击保存群描述
    static func imChatSettingEditDescriptionSaveClick(chatId: String,
                                                      isAdmin: Bool,
                                                      altered: Bool,
                                                      charCount: Int,
                                                      chat: Chat) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_EDIT_DESCRIPTION_SAVE_CLICK,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue,
                                       "altered": altered,
                                       "char_count": charCount
                              ]))
        //(群描述编辑)页面，发生动作事件时上报（64）
        var params: [AnyHashable: Any] = [ "click": "save",
                                           "target": "im_edit_group_info_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_DESCRIPTION_CLICK, params: params))
    }

    //(群描述编辑)页面（63）
    static func imEditGroupDescriptionView(chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_DESCRIPTION_VIEW, params: IMTracker.Param.chat(chat)))
    }

    // 群邮箱选项
    static func imEditGroupInfoEmailClick(chat: Chat) {
        var params: [AnyHashable: Any] = ["click": "email",
                                          "target": "none"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_INFO_CLICK, params: params))
    }

    static func imEditGroupInfoGetEmailClick(chat: Chat) {
        var params: [AnyHashable: Any] = ["click": "get_email",
                                          "target": "none"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_INFO_CLICK, params: params))
    }

    static func imEditGroupInfoEmailCopyClick(chat: Chat) {
        var params: [AnyHashable: Any] = ["click": "copy",
                                          "target": "none"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_INFO_CLICK, params: params))
    }

    static func imEditGroupInfoEmailPermissionClick(chat: Chat) {
        var params: [AnyHashable: Any] = ["click": "permission",
                                          "target": "none"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_INFO_CLICK, params: params))
    }

    // 在群信息中点击编辑pano标签
    static func imChatSettingEditPanoClick(chatId: String, isAdmin: Bool) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_EDIT_PANO_CLICK,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue
                              ]))
    }

    // 查看群二维码
    static func imChatSettingQrcodePageView(chatId: String,
                                            isAdmin: Bool,
                                            source: ChatSettingCheckGroupQRCodeSource,
                                            chat: Chat) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_QRCODE_PAGE_VIEW,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue,
                                       "source": source.rawValue
                              ]))
        var params: [AnyHashable: Any] = [ "click": "group_QR",
                                           "target": "im_group_QR_view"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_SHARE_GROUP_CLICK, params: params))
    }

    static func imEditGroupInfoQRClick(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "group_QR",
                                           "target": "im_group_QR_view"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_EDIT_GROUP_INFO_CLICK, params: params))
    }

    static func imGroupQRView(chat: Chat) {
        //(群二维码)页面（两种入口：一是「会话设置」页面直接点击群二维码；二是「群分享」页面点击群二维码(65)
        Tracker.post(TeaEvent(Homeric.IM_GROUP_QR_VIEW, params: IMTracker.Param.chat(chat)))
    }

    /// 「群二维码/群链接分享途径选择」页面（70）
    static func imGroupQRLinkShareToView(chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_GROUP_QR_LINK_SHARE_TO_VIEW, params: IMTracker.Param.chat(chat)))
    }

    // 点击分享群二维码
    static func imChatSettingQrcodeShareClick(chatId: String,
                                              isChange: Bool,
                                              isAdmin: Bool,
                                              time: ExpireTime,
                                              chat: Chat) {
        let expirationPeriod: String
        let valid_period: String
        switch time {
        case .forever:
            expirationPeriod = "permanent"
            valid_period = "permanent"
        case .oneYear:
            expirationPeriod = "1_year"
            valid_period = "within_1_year"
        case .sevenDays:
            expirationPeriod = "1_week"
            valid_period = "within_7_days"
        }
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_QRCODE_SHARE_CLICK,
                              params: ["chat_id": chatId,
                                       "altered_expiration_period": isChange,
                                       "expiration_period": expirationPeriod,
                                       "member_type": memberType.rawValue
                              ]))

        var shareParams: [AnyHashable: Any] = [ "click": "share",
                                                "target": "im_group_QR_share_to_view",
                                                "valid_period": valid_period]
        shareParams += IMTracker.Param.chat(chat)
        //share：分享(66)(67)
        Tracker.post(TeaEvent(Homeric.IM_GROUP_QR_CLICK, params: shareParams))
    }

    // 保存群二维码
    static func imChatSettingQrcodeSaveClick(chatId: String,
                                             isChange: Bool,
                                             isAdmin: Bool,
                                             time: ExpireTime,
                                             chat: Chat) {
        let expirationPeriod: String
        let valid_period: String
        switch time {
        case .forever:
            expirationPeriod = "permanent"
            valid_period = "permanent"
        case .oneYear:
            expirationPeriod = "1_year"
            valid_period = "within_1_year"
        case .sevenDays:
            expirationPeriod = "1_week"
            valid_period = "within_7_days"
        }
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_QRCODE_SAVE_CLICK,
                              params: ["chat_id": chatId,
                                       "altered_expiration_period": isChange,
                                       "expiration_period": expirationPeriod,
                                       "member_type": memberType.rawValue
                              ]))
        //save：保存图片(68)(69)
        var targetParams: [AnyHashable: Any] = [ "click": "save",
                                                 "target": "none",
                                                 "valid_period": valid_period]
        targetParams += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_GROUP_QR_CLICK, params: targetParams))
    }

    // 查看群链接
    static func imChatSettingChatLinkPageView(chatId: String,
                                              isAdmin: Bool,
                                              chat: Chat) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CHAT_LINK_PAGE_VIEW,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue
                              ]))

        var groupLinkParams: [AnyHashable: Any] = [ "click": "group_link",
                                           "target": "im_group_link_view" ]
        groupLinkParams += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_SHARE_GROUP_CLICK, params: groupLinkParams))
        Tracker.post(TeaEvent(Homeric.IM_GROUP_LINK_VIEW, params: IMTracker.Param.chat(chat)))
    }

    // 复制群链接
    static func imChatSettingChatLinkCopyClick(chatId: String,
                                               isAdmin: Bool,
                                               isChange: Bool,
                                               time: ExpireTime,
                                               chat: Chat) {
        let expirationPeriod: String
        let valid_period: String
        switch time {
        case .forever:
            expirationPeriod = "permanent"
            valid_period = "permanent"
        case .oneYear:
            expirationPeriod = "1_year"
            valid_period = "within_1_year"
        case .sevenDays:
            expirationPeriod = "1_week"
            valid_period = "within_7_days"
        }
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CHAT_LINK_COPY_CLICK,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue,
                                       "altered_expiration_period": isChange,
                                       "expiration_period": expirationPeriod
                              ]))
        var targetParams: [AnyHashable: Any] = [ "click": "copy",
                                                 "valid_period": valid_period,
                                                 "target": "none" ]
        targetParams += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_GROUP_LINK_CLICK, params: targetParams))
    }

    // 分享群链接
    static func imChatSettingChatLinkShareClick(chatId: String,
                                               isAdmin: Bool,
                                               isChange: Bool,
                                               time: ExpireTime,
                                               chat: Chat) {
        let expirationPeriod: String
        let valid_period: String
        switch time {
        case .forever:
            expirationPeriod = "permanent"
            valid_period = "permanent"
        case .oneYear:
            expirationPeriod = "1_year"
            valid_period = "within_1_year"
        case .sevenDays:
            expirationPeriod = "1_week"
            valid_period = "within_7_days"
        }
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CHAT_LINK_SHARE_CLICK,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue,
                                       "altered_expiration_period": isChange,
                                       "expiration_period": expirationPeriod
                              ]))

        var qrLinkParams: [AnyHashable: Any] = [ "click": "share",
                                                 "valid_period": valid_period,
                                                 "target": "im_group_QR_link_share_to_view" ]
        qrLinkParams += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_GROUP_LINK_CLICK, params: qrLinkParams))
    }

    // 查看群成员列表/section页面
    static func imChatSettingMemberListPageView(chatId: String,
                                                isAdmin: Bool,
                                                source: String) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_MEMBER_LIST_PAGE_VIEW,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue,
                                       "source": source
                              ]))
    }

    /// 在「移除群成员」页面，发生动作事件 (81)
    static func imGroupMemberDelClickCancel(chat: Chat) {
        var params: [AnyHashable: Any] = ["click": "cancel",
                                          "target": "none" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_GROUP_MEMBER_DEL_CLICK, params: params))
    }

    // 移除群成员
    static func imChatSettingDelMemberClick(chatId: String,
                                            source: ChatSettingDeleteMemberSource) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_DEL_MEMBER_CLICK,
                              params: ["chat_id": chatId,
                                       "source": source.rawValue
                              ]))
    }

    /// (移除群成员)页面，发生动作（79）
    static func imGroupMemberDelClick(chat: Chat) {
        var params: [AnyHashable: Any] = ["click": "confirm",
                                          "target": "im_chat_setting_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_GROUP_MEMBER_DEL_CLICK, params: params))
    }

    // 添加群成员
    static func imChatSettingAddMemberClick(chatId: String,
                                            isAdmin: Bool,
                                            count: Int,
                                            isPublic: Bool,
                                            chatType: MessengerChatType,
                                            source: AddMemberSource) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_ADD_MEMBER_CLICK,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue,
                                       "source": source.rawValue,
                                       "count": "\(count)",
                                       "type": chatType.rawValue,
                                       "mode": MessengerChatMode.getTypeWithIsPublic(isPublic).rawValue
                              ]))
    }

    // 导出群成员ui展示
    static func imGroupMemberExportView(chat: Chat) {
        Tracker.post(TeaEvent("im_group_member_export_view",
                              params: IMTracker.Param.chat(chat)))
    }

    // 导出群成员点击
    static func imGroupMemberExportClick(chat: Chat, success: Bool) {
        var params: [AnyHashable: Any] = ["click": "export_member_list",
                                          "target": "none",
                                          "status": success ? "success" : "fail"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("im_group_member_export_click",
                              params: params))
    }

    // 单聊添加人
    static func imChatSettingAddMemberToP2pClick(chatId: String) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_ADD_MEMBER_TO_P2P_CLICK,
                              params: ["chat_id": chatId]))
    }

    // 点击群公告icon
    static func imChatAnnouncementClick(chat: Chat,
                                        isAdmin: Bool) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        let chatType = MessengerChatType.getTypeWithChat(chat)
        let chatMode = MessengerChatMode.getTypeWithIsPublic(chat.isPublic)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_ANNOUNCEMENT_CLICK,
                              params: ["chat_id": chat.id,
                                       "member_type": memberType.rawValue,
                                       "chat_type": chatType.rawValue,
                                       "external": chat.isCrossTenant,
                                       "chat_mode": chatMode.rawValue
                              ]))

        var params: [AnyHashable: Any] = [ "click": "announcement",
                                           "target": "im_group_announcement_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    // 点击Pin icon
    static func imOldPinClick(chat: Chat,
                               isAdmin: Bool) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        let chatType = MessengerChatType.getTypeWithChat(chat)
        let chatMode = MessengerChatMode.getTypeWithIsPublic(chat.isPublic)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_PIN_CLICK,
                              params: ["chat_id": chat.id,
                                       "member_type": memberType.rawValue,
                                       "chat_type": chatType.rawValue,
                                       "external": chat.isCrossTenant,
                                       "chat_mode": chatMode.rawValue
                              ]))

        var params: [AnyHashable: Any] = [ "click": "pin",
                                           "target": "im_chat_pin_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    // 点击新群置顶 icon
    static func imChatPinClick(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "top"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    // 点击（群）日历 icon
    static func imChatCalClick(chat: Chat,
                               isAdmin: Bool) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        let chatType = MessengerChatType.getTypeWithChat(chat)
        let chatMode = MessengerChatMode.getTypeWithIsPublic(chat.isPublic)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_CAL_CLICK,
                              params: ["chat_id": chat.id,
                                       "member_type": memberType.rawValue,
                                       "chat_type": chatType.rawValue,
                                       "external": chat.isCrossTenant,
                                       "chat_mode": chatMode.rawValue
                              ]))

        var params: [AnyHashable: Any] = [ "click": "cal",
                                           "target": "cal_calendar_chat_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    // 点击会议纪要（会议群）
    static func imChatMinutesClick(chatId: String,
                                   isAdmin: Bool) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_MINUTES_CLICK,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue
                              ]))
    }

    static func imChatSettingClickCalView(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "meeting_docs",
                                           "target": "im_chat_cal_view" ]
        params += IMTracker.Param.chat(chat)
        //「会议纪要」页面(29)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    // 点击日程（会议群）
    static func imChatEventClick(chatId: String,
                                 isAdmin: Bool) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_EVENT_CLICK,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue
                              ]))
    }

    static func imChatSettingClickDetailView(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "event",
                                           "target": "cal_event_detail_view" ]
        params += IMTracker.Param.chat(chat)
        //「日程」页面(28)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    static func imChatSettingClickDetailTaskView(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "task",
                                           "target": "todo_im_chat_todo_list_view" ]
        params += IMTracker.Param.chat(chat)
        //「任务」页面(27)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    static func imChatSettingClickSearchHistory(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "search",
                                           "target": "im_chat_history_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    ///消息（移动端）(35)
    static func imChatSettingClickMessage(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "message",
                                           "target": "im_chat_history_message_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    ///云文档（移动端）(36)
    static func imChatSettingClickMessageDoc(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "doc",
                                           "target": "im_chat_history_doc_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    ///文件（移动端）(37)
    static func imChatSettingClickMessageFile(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "file",
                                           "target": "im_chat_history_file_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    ///图片（移动端）(38)
    static func imChatSettingClickMessageImage(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "image",
                                           "target": "im_chat_history_image_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    ///链接（移动端）(39)
    static func imChatSettingClickMessageLink(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "link",
                                           "target": "im_chat_history_link_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    // 点击群管理
    static func imChatSettingManageClick(chatId: String) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_MANAGE_CLICK,
                              params: ["chat_id": chatId
                              ]))
    }

    static func imChatSettingAliasClick(chat: Chat) {
        //（24）alias：我在本群的昵称
        var params: [AnyHashable: Any] = [ "click": "alias",
                                           "target": "im_edit_alias_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    static func imChatSettingDeleteMessagesClick(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "empty_history_msg",
                                           "target": "im_chat_empty_history_confirm_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    static func imChatSettingDeleteMessagesConfirmView(chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_EMPTY_HISTORY_CONFIRM_VIEW, params: IMTracker.Param.chat(chat)))
    }

    static func imChatSettingDeleteMessagesConfirmClick(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "empty",
                                           "target": "im_chat_setting_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_EMPTY_HISTORY_CONFIRM_CLICK, params: params))
    }

    // 点击我在本群的昵称
//    static func imChatSettingAliasClick(chatId: String,
//                                        isAdmin: Bool) {
//        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
//        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_ALIAS_CLICK,
//                              params: ["chat_id": chatId,
//                                       "member_type": memberType.rawValue
//                              ]))
//    }

    static func imEditAliasView(chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_EDIT_ALIAS_VIEW, params: IMTracker.Param.chat(chat)))
    }

    // 保存我在本群的昵称
    static func imChatSettingAliasSaveClick(chatId: String,
                                            isAdmin: Bool,
                                            altered: Bool,
                                            charCount: Int,
                                            chat: Chat) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_ALIAS_SAVE_CLICK,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue,
                                       "altered": altered,
                                       "chat_count": "\(charCount)"
                              ]))

        var params: [AnyHashable: Any] = [ "click": "save",
                                           "target": "im_chat_setting_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_EDIT_ALIAS_CLICK, params: params))
    }

    // 更改添加到置顶开关
    static func imChatSettingQuickswitcherSwitch(isOn: Bool,
                                                 isAdmin: Bool,
                                                 chat: Chat) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        let status = isOn ? "off_to_on" : "on_to_off"
        let chatType = MessengerChatType.getTypeWithChat(chat)
        let chatMode = MessengerChatMode.getTypeWithIsPublic(chat.isPublic)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_QUICKSWITCHER_SWITCH,
                              params: ["chat_id": chat.id,
                                       "member_type": memberType.rawValue,
                                       "status": status,
                                       "chat_type": chatType.rawValue,
                                       "external": chat.isCrossTenant,
                                       "chat_mode": chatMode.rawValue
                              ]))

        var params: [AnyHashable: Any] = [ "click": "quickswitcher_switch",
                                           "target": "im_chat_setting_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    // 更改进入会话定位到设置项
    static func imChatSettingStartFromMsgSetting(position: LarkModel.Chat.MessagePosition.Enum,
                                                 isAdmin: Bool,
                                                 chat: Chat) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        let status: String
        switch position {
        case .recentLeft:
            status = "where_i_left_off"
        case .newestUnread:
            status = "most_recent_unread"
        case .unknown:
            status = ""
        @unknown default:
            fatalError("unknown type")
        }
        let chatType = MessengerChatType.getTypeWithChat(chat)
        let chatMode = MessengerChatMode.getTypeWithIsPublic(chat.isPublic)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_START_FROM_MSG_SETTING,
                              params: ["chat_id": chat.id,
                                       "member_type": memberType.rawValue,
                                       "status": status,
                                       "chat_type": chatType.rawValue,
                                       "external": chat.isCrossTenant,
                                       "chat_mode": chatMode.rawValue
                              ]))
    }

    // 更改自动翻译开关
    static func imChatSettingAutoTranslationSwitch(isOn: Bool,
                                                   isAdmin: Bool,
                                                   chat: Chat) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        let status = isOn ? "off_to_on" : "on_to_off"
        let chatType = MessengerChatType.getTypeWithChat(chat)
        let chatMode = MessengerChatMode.getTypeWithIsPublic(chat.isPublic)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_AUTO_TRANSLATION_SWITCH,
                              params: ["chat_id": chat.id,
                                       "member_type": memberType.rawValue,
                                       "status": status,
                                       "chat_type": chatType.rawValue,
                                       "external": chat.isCrossTenant,
                                       "chat_mode": chatMode.rawValue
                              ]))

        var params: [AnyHashable: Any] = [ "click": "auto_translation_switch",
                                           "target": "im_chat_setting_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    // 免打扰开关
    static func imChatSettingMuteSwitch(isOn: Bool, chat: Chat, isAdmin: Bool, myUserId: String) {
        let status = isOn ? "on" : "off"
        let chatType = MessengerChatType.getTypeWithChat(chat)
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        let chatTypeDetail = TrackerUtils.getChatTypeDetail(chat: chat, myUserId: myUserId)
        var params: [AnyHashable: Any] = [ "click": "mute_taggle",
                                           "target": "none",
                                           "status": status,
                                           "chat_id": chat.id,
                                           "chat_type": chatType.rawValue,
                                           "chat_type_detail": chatTypeDetail,
                                           "member_type": memberType.rawValue,
                                           "is_inner_group": !chat.isCrossTenant ? "true" : "false",
                                           "is_public_group": chat.isPublic ? "true" : "false"]
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    // @所有人不提醒
    static func imChatSettingMuteAtAllSwitch(isOn: Bool, chat: Chat, isAdmin: Bool, myUserId: String) {
        let status = isOn ? "on" : "off"
        let chatType = MessengerChatType.getTypeWithChat(chat)
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        let chatTypeDetail = TrackerUtils.getChatTypeDetail(chat: chat, myUserId: myUserId)
        var params: [AnyHashable: Any] = [ "click": "mute_at_all_taggle",
                                           "target": "none",
                                           "status": status,
                                           "chat_id": chat.id,
                                           "chat_type": chatType.rawValue,
                                           "chat_type_detail": chatTypeDetail,
                                           "member_type": memberType.rawValue,
                                           "is_inner_group": !chat.isCrossTenant ? "true" : "false",
                                           "is_public_group": chat.isPublic ? "true" : "false"]
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    // 会话盒子
    static func imChatSettingChatBoxSwitch(isOn: Bool, chat: Chat, isAdmin: Bool, myUserId: String) {
        let status = isOn ? "on" : "off"
        let chatType = MessengerChatType.getTypeWithChat(chat)
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        let chatTypeDetail = TrackerUtils.getChatTypeDetail(chat: chat, myUserId: myUserId)
        var params: [AnyHashable: Any] = [ "click": "chatbox_taggle",
                                           "target": "none",
                                           "status": status,
                                           "chat_id": chat.id,
                                           "chat_type": chatType.rawValue,
                                           "chat_type_detail": chatTypeDetail,
                                           "member_type": memberType.rawValue,
                                           "is_inner_group": !chat.isCrossTenant ? "true" : "false",
                                           "is_public_group": chat.isPublic ? "true" : "false"]
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    // 点击退出群组
    static func imChatSettingLeaveClick(chatId: String, isAdmin: Bool) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_LEAVE_CLICK,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue
                              ]))
    }

    static func imChatSettingGroupConfirmClick(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "quit_group",
                                           "target": "im_quit_group_confirm_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    // 确认退出群组
//    static func imChatSettingLeaveConfirmClick(chatId: String, isAdmin: Bool) {
//        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
//        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_LEAVE_CONFIRM_CLICK,
//                              params: ["chat_id": chatId,
//                                       "member_type": memberType.rawValue
//                              ]))
//    }

    // 点击解散群组
    static func imChatSettingDisbandClick(chatId: String, chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_DISBAND_CLICK,
                              params: ["chat_id": chatId
                              ]))
        Tracker.post(TeaEvent(Homeric.IM_DISMISS_GROUP_CONFIRM_VIEW, params: IMTracker.Param.chat(chat)))
    }

    static func imChatSettingDismissGroupConfirmClick(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "dismiss_group",
                                           "target": "im_dismiss_group_confirm_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    // 确认解散群组
    static func imChatSettingDisbandConfirmClick(chatId: String, chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_DISBAND_CONFIRM_CLICK,
                              params: ["chat_id": chatId
                              ]))
        var params: [AnyHashable: Any] = [ "click": "confirm",
                                           "target": "none" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_DISMISS_GROUP_CONFIRM_CLICK, params: params))
    }

    /// 在「解散群组二次确认」页面，发生动作事件 （96）
    static func imQuitGroupConfirmClickCancel(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "cancel",
                                           "target": "none" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_QUIT_GROUP_CONFIRM_CLICK, params: params))
    }

    /// 在「解散群组二次确认」页面，发生动作事件 （100）
    static func imDismissGroupConfirmClick(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "cancel",
                                           "target": "im_chat_setting_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_DISMISS_GROUP_CONFIRM_CLICK, params: params))
    }

    // 举报
    static func imChatSettingReportClick(chatId: String) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_REPORT_CLICK,
                              params: ["chat_id": chatId
                              ]))
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: [ "click": "report",
                                                                       "target": "none" ]))
    }

    static func imChatSettingReportNoneClick(chat: Chat) {
        var params: [AnyHashable: Any] = [ "click": "report",
                                           "target": "none" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }
}

extension NewChatSettingTracker {
    // 发言限制打点
    static func messageRestrictionClickTrack(postType: Chat.PostType,
                                      chat: Chat,
                                      myUserId: String,
                                      isOwner: Bool,
                                      extra: [String: String] = [:]) {
        let status: String
        switch postType {
        case .onlyAdmin:
            status = "only_group_owner_and_admin"
        case .anyone:
            status = "all"
        case .whiteList:
            status = "some_member"
        @unknown default:
            assertionFailure("unknown type")
            status = ""
        }
        var extra = extra
        extra["target"] = "none"
        extra["status"] = status
        NewChatSettingTracker.imGroupManageClick(
            chat: chat,
            myUserId: myUserId,
            isOwner: isOwner,
            isAdmin: chat.isGroupAdmin,
            clickType: "message_restriction",
            extra: extra)
    }

    static func imGroupMemberView(chat: Chat, myUserId: String, isOwner: Bool, isAdmin: Bool) {
        let chatType = TrackerUtils.getChatType(chat: chat)
        let chatTypeDetail = TrackerUtils.getChatTypeDetail(chat: chat, myUserId: myUserId)
        let memberType = MessengerMemberType.getNewTypeWithIsAdmin(isOwner: isOwner, isAdmin: isAdmin, isBot: chat.chatter?.type == .bot)
        let botCount = chat.chatterCount - chat.userCount
        Tracker.post(TeaEvent(Homeric.IM_GROUP_MEMBER_VIEW,
                              params: ["chat_id": chat.id,
                                       "chat_type": chatType,
                                       "chat_type_detail": chatTypeDetail,
                                       "bot_count": botCount,
                                       "is_inner_group": !chat.isCrossTenant ? "true" : "false",
                                       "is_public_group": chat.isPublic ? "true" : "false",
                                       "member_type": memberType.rawValue
                              ]))
    }

    static func imGroupAdminView(chat: Chat, myUserId: String, isOwner: Bool, isAdmin: Bool, adminAmount: Int) {
        let chatType = TrackerUtils.getChatType(chat: chat)
        let chatTypeDetail = TrackerUtils.getChatTypeDetail(chat: chat, myUserId: myUserId)
        let memberType = MessengerMemberType.getNewTypeWithIsAdmin(isOwner: isOwner, isAdmin: isAdmin, isBot: chat.chatter?.type == .bot)
        let botCount = chat.chatterCount - chat.userCount
        Tracker.post(TeaEvent(Homeric.IM_GROUP_ADMIN_VIEW,
                              params: ["chat_id": chat.id,
                                       "admin_amount": adminAmount,
                                       "chat_type": chatType,
                                       "chat_type_detail": chatTypeDetail,
                                       "bot_count": botCount,
                                       "is_inner_group": !chat.isCrossTenant ? "true" : "false",
                                       "is_public_group": chat.isPublic ? "true" : "false",
                                       "member_type": memberType.rawValue
                              ]))
    }

    static func imGroupAdminClick(chat: Chat, myUserId: String, isOwner: Bool, isAdmin: Bool, clickType: String) {
        let chatType = TrackerUtils.getChatType(chat: chat)
        let chatTypeDetail = TrackerUtils.getChatTypeDetail(chat: chat, myUserId: myUserId)
        let memberType = MessengerMemberType.getNewTypeWithIsAdmin(isOwner: isOwner, isAdmin: isAdmin, isBot: chat.chatter?.type == .bot)
        let botCount = chat.chatterCount - chat.userCount
        Tracker.post(TeaEvent(Homeric.IM_GROUP_ADMIN_CLICK,
                              params: ["chat_id": chat.id,
                                       "click": clickType,
                                       "chat_type": chatType,
                                       "chat_type_detail": chatTypeDetail,
                                       "bot_count": botCount,
                                       "is_inner_group": !chat.isCrossTenant ? "true" : "false",
                                       "is_public_group": chat.isPublic ? "true" : "false",
                                       "member_type": memberType.rawValue,
                                       "target": "none"
                              ]))
    }

    /// 在「群管理页」发生动作事件
    static func imGroupManageClick(chat: Chat, myUserId: String, isOwner: Bool, isAdmin: Bool, clickType: String, extra: [String: String] = [:]) {
        let chatType = TrackerUtils.getChatType(chat: chat)
        let chatTypeDetail = TrackerUtils.getChatTypeDetail(chat: chat, myUserId: myUserId)
        let botCount = chat.chatterCount - chat.userCount
        let memberType = MessengerMemberType.getNewTypeWithIsAdmin(isOwner: isOwner, isAdmin: isAdmin, isBot: chat.chatter?.type == .bot)
        var params: [String: Any] = ["chat_id": chat.id,
                                      "click": clickType,
                                      "chat_type": chatType,
                                      "chat_type_detail": chatTypeDetail,
                                      "bot_count": botCount,
                                      "is_inner_group": !chat.isCrossTenant ? "true" : "false",
                                      "is_public_group": chat.isPublic ? "true" : "false",
                                      "member_type": memberType.rawValue]
        params += extra
        Tracker.post(TeaEvent(Homeric.IM_GROUP_MANAGE_CLICK,
                              params: params))
    }

    /// 「会话设置」页展示
    static func imChatSettingView(chat: Chat,
                                  myUserId: String,
                                  isOwner: Bool,
                                  isAdmin: Bool,
                                  extra: [String: String] = [:]) {
        let chatType = TrackerUtils.getChatType(chat: chat)
        let chatTypeDetail = TrackerUtils.getChatTypeDetail(chat: chat, myUserId: myUserId)
        let memberType = MessengerMemberType.getNewTypeWithIsAdmin(isOwner: isOwner, isAdmin: isAdmin, isBot: chat.chatter?.type == .bot)
        let botCount = chat.chatterCount - chat.userCount
        var params: [String: Any] = ["chat_id": chat.id,
                                     "chat_type": chatType,
                                     "chat_type_detail": chatTypeDetail,
                                     "bot_count": botCount,
                                     "is_inner_group": !chat.isCrossTenant ? "true" : "false",
                                     "is_public_group": chat.isPublic ? "true" : "false",
                                     "member_type": memberType.rawValue]
        params += extra
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_VIEW,
                              params: params))
    }

    ///「群管理页」展示
    static func imGroupManageView(chat: Chat, myUserId: String, isOwner: Bool, isAdmin: Bool) {
        let chatType = TrackerUtils.getChatType(chat: chat)
        let chatTypeDetail = TrackerUtils.getChatTypeDetail(chat: chat, myUserId: myUserId)
        let memberType = MessengerMemberType.getNewTypeWithIsAdmin(isOwner: isOwner, isAdmin: isAdmin, isBot: chat.chatter?.type == .bot)
        let botCount = chat.chatterCount - chat.userCount
        Tracker.post(TeaEvent(Homeric.IM_GROUP_MANAGE_VIEW,
                              params: ["chat_id": chat.id,
                                       "chat_type": chatType,
                                       "chat_type_detail": chatTypeDetail,
                                       "bot_count": botCount,
                                       "is_inner_group": !chat.isCrossTenant ? "true" : "false",
                                       "is_public_group": chat.isPublic ? "true" : "false",
                                       "member_type": memberType.rawValue
                              ]))
    }

    ///在「会话设置」页，发生动作事件
    static func imChatSettingClick(chat: Chat, myUserId: String, isOwner: Bool, isAdmin: Bool, extra: [String: String] = [:]) {
        let chatType = TrackerUtils.getChatType(chat: chat)
        let chatTypeDetail = TrackerUtils.getChatTypeDetail(chat: chat, myUserId: myUserId)
        let memberType = MessengerMemberType.getNewTypeWithIsAdmin(isOwner: isOwner, isAdmin: isAdmin, isBot: chat.chatter?.type == .bot)
        let botCount = chat.chatterCount - chat.userCount
        var params: [String: Any] = ["chat_id": chat.id,
                                     "chat_type": chatType,
                                     "chat_type_detail": chatTypeDetail,
                                     "bot_count": botCount,
                                     "is_inner_group": !chat.isCrossTenant ? "true" : "false",
                                     "is_public_group": chat.isPublic ? "true" : "false",
                                     "member_type": memberType.rawValue]
        params += extra
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK,
                              params: params))
    }

    /// 「允许群被搜索到设置页」展示
    static func chatAllowToBeSearchedTrack(chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_ALLOW_TO_BE_SEARCHED_VIEW, params: IMTracker.Param.chat(chat)))
    }

    /// 在「允许群被搜索到设置页」发生动作事件
    static func chatAllowToBeSearchedClickTrack(chat: Chat,
                                                click: String,
                                                isModifyGroupAvatar: Bool,
                                                isModifyGroupName: Bool,
                                                isAllowToSearch: Bool) {
        let nameLength = chat.name.count
        let description = chat.description.count
        let params: [String: Any] = ["group_name_length": nameLength,
                                     "group_description_length": description,
                                     "is_modify_group_avatar": isModifyGroupAvatar ? "true" : "false",
                                     "is_modify_group_name": isModifyGroupName ? "true" : "false",
                                     "is_allow_to_be_searched": isAllowToSearch ? "true" : "false",
                                     "click": click,
                                     "target": "none"]
        Tracker.post(TeaEvent(Homeric.IM_CHAT_ALLOW_TO_BE_SEARCHED_CLICK,
                              params: params))
    }

    /// 「允许群被搜索到保存提示页」展示
    static func imChatAllowToBeSearchedRemindViewTrack(chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_ALLOW_TO_BE_SEARCHED_REMIND_VIEW, params: IMTracker.Param.chat(chat)))
    }

    /// 在「允许群被搜索到保存提示页」发生动作事件
    static func imChatAllowToBeSearchedRemindClickTrack(click: String, target: String, chat: Chat) {
        var params: [AnyHashable: Any] = ["click": click,
                                          "target": target]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_ALLOW_TO_BE_SEARCHED_REMIND_CLICK,
                              params: params))
    }

    /// 「申请入群」页面的展示
    static func imChatGroupApply(chat: Chat) {
        let params = IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_GROUP_APPLY_VIEW, params: params))
    }

    /// 在「申请入群」页，发生的动作
    static func imChatGroupClick(chat: Chat,
                                 click: String,
                                 isReasonFilled: Bool,
                                 extra: [AnyHashable: Any] = [:]) {
        var params: [AnyHashable: Any] = ["click": click,
                                          "is_reason_filled": isReasonFilled ? "true" : "false"]
        params += extra
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_GROUP_APPLY_CLICK,
                              params: params))
    }

    static func imGroupModeChangeConfirmClick(chat: Chat, toMode: ChatModeSelected) {
        let mode = toMode == .normal ? "normal" : "thread"
        var params: [AnyHashable: Any] = ["click": "transfer", "target": "none", "to_group_mode": mode]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_IM_GROUP_MODE_CHANGE_CONFIRM_CLICK,
                              params: params))
    }
}

// MARK: 翻译助手设置
extension NewChatSettingTracker {
    static func trackTranslateSetting(chat: Chat) {
        var params: [AnyHashable: Any] = ["click": "translation_setting",
                                          "target": "none"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

//    static func trackIsAutoTranslation(chat: Chat, turnOn: Bool) {
//        var params: [AnyHashable: Any] = ["click": "is_auto_translation",
//                                          "target": "none",
//                                          "status": turnOn ? "off_to_on" : "on_to_off"]
//        params += IMTracker.Param.chat(chat)
//        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
//    }

//    static func trackTranslationLanguageSetting(chat: Chat) {
//        var params: [AnyHashable: Any] = ["click": "translation_language_setting",
//                                          "target": "setting_detail_click"]
//        params += IMTracker.Param.chat(chat)
//        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
//    }

    static func trackIsTypingTranslation(chat: Chat, turnOn: Bool, translationLanguage: String) {
        var params: [AnyHashable: Any] = ["click": "is_typing_translation",
                                          "target": "none",
                                          "status": turnOn ? "off_to_on" : "on_to_off",
                                          "translation_language": translationLanguage]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CLICK, params: params))
    }

    // 点击同意/拒绝按钮时上报
    static func trackJoinApplicationClick(chat: Chat, approve: Bool) {
        var params: [AnyHashable: Any] = ["click": approve ? "approve" : "refuse",
                                          "occasion": chat.isAssociatedTeam ? "team" : "other"]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent("im_chat_join_application_click", params: params))
    }
}

extension NewChatSettingTracker {
    // 群成员排序页的展示
    static func groupmemberRankView() {
        Tracker.post(TeaEvent(Homeric.IM_GROUP_MEMBER_RANK_VIEW))
    }

    // 群成员排序页的点击
    static func groupmemberRankViewClick(rankByName: Bool) {
        let params: [AnyHashable: Any] = ["click": rankByName ? "rank_by_name" : "rank_by_join_time",
                                          "target": "none"]
        Tracker.post(TeaEvent(Homeric.IM_GROUP_MEMBER_RANK_CLICK, params: params))
    }
}
