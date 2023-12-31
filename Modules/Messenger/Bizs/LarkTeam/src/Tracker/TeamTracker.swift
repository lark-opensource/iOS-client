//
//  TeamTracker.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/8/19.
//

import Foundation
import Homeric
import LKCommonsTracker
import LarkModel

final class TeamTracker {
    /// 「创建团队页」的展示
    static func trackImCreateTeamView() {
        Tracker.post(TeaEvent(Homeric.IM_CREATE_TEAM_VIEW))
    }

    /// 在「创建团队页」的动作事件
    static func trackImCreateTeamClick(click: String,
                                       target: String,
                                       isSuccess: Bool? = nil) {
        var params: [String: String] = ["click": click,
                                        "target": target]
        if let isSuccess = isSuccess {
            params["is_success"] = isSuccess ? "true" : "false"
        }
        Tracker.post(TeaEvent(Homeric.IM_CREATE_TEAM_CLICK, params: params))
    }

    /// 「添加成员数超限弹窗页」的展示
    static func trackImTeamCreateFailPopupView() {

    }

    /// 「退出团队的弹窗提示页面」的展示
    static func trackFeedTeamExitView(isTeamOwner: Bool) {
        Tracker.post(TeaEvent(Homeric.FEED_TEAM_EXIT_VIEW, params: ["is_team_owner": isTeamOwner ? "true" : "false"]))
    }

    /// 「退出团队的弹窗提示页面」的点击
    static func trackFeedTeamExitClick(click: String,
                                       target: String) {
        Tracker.post(TeaEvent(Homeric.FEED_TEAM_EXIT_CLICK, params: ["click": click,
                                                                     "target": target
        ]))
    }

    /// 「转让团队所有者」页面的展示
    static func trackImTransferTeamOwnerView() {
        Tracker.post(TeaEvent(Homeric.IM_TRANSFER_TEAM_OWNER_VIEW))
    }

    /// 「转让团队所有者」页面的点击
    static func trackImTransferTeamOwnerClick(click: String,
                                              target: String,
                                              newOwnerId: String? = nil) {
        var params: [String: String] = ["click": click,
                                        "target": target]
        if let newOwnerId = newOwnerId {
            params["new_team_owner"] = newOwnerId
        }
        Tracker.post(TeaEvent(Homeric.IM_TRANSFER_TEAM_OWNER_CLICK,
                              params: params,
                              md5AllowList: ["new_team_owner"]
        ))
    }

    /// 「团队删除/解散页面」的展示
    static func trackImTeamDeleteView() {
        Tracker.post(TeaEvent(Homeric.IM_TEAM_DELETE_VIEW))
    }

    /// 「团队删除/解散页面」的点击
    static func trackImTeamDeleteClick(click: String,
                                       target: String) {
        let params: [String: String] = ["click": click,
                                        "target": target]
        Tracker.post(TeaEvent(Homeric.IM_TEAM_DELETE_CLICK,
                              params: params))

    }

    /// 「团队设置页」的展示
    static func trackImTeamSettingView() {
        Tracker.post(TeaEvent(Homeric.IM_TEAM_SETTING_VIEW))
    }

    /// 「团队设置页」的展示
    static func trackImTeamSettingClick(click: String,
                                        target: String,
                                        isMemberChanged: Bool? = nil,
                                        isAddGroupToggleChanged: Bool? = nil,
                                        addGroupToggle: String? = nil,
                                        isAddMemberToggleChanged: Bool? = nil,
                                        addMemberToggle: String? = nil) {
        var params: [String: String] = ["click": click,
                                        "target": target]
        if let isMemberChanged = isMemberChanged,
           let isAddGroupToggleChanged = isAddGroupToggleChanged,
           let isAddMemberToggleChanged = isAddMemberToggleChanged,
           let addMemberToggle = addMemberToggle,
           let addGroupToggle = addGroupToggle {
            params["is_member_changed"] = isMemberChanged ? "true" : "false"
            params["is_create_group_toggle_changed"] = isAddGroupToggleChanged ? "true" : "false"
            params["is_add_group_and_member_toggle_changed"] = isAddMemberToggleChanged ? "true" : "false"
            params["add_group_and_member_toggle"] = addMemberToggle
            params["create_group_toggle"] = addGroupToggle
        }
        Tracker.post(TeaEvent(Homeric.IM_TEAM_SETTING_CLICK,
                              params: params))
    }

    ///「团队权限管理页」的展示
    static func trackImTeamAuthorityManagementView(addMemberToggle: String,
                                                   addGroupToggle: String) {
        Tracker.post(TeaEvent(Homeric.IM_TEAM_AUTHORITY_MANAGEMENT_VIEW,
                              params: ["add_group_and_member_toggle": addMemberToggle,
                                       "create_group_toggle": addGroupToggle
        ]))
    }

    /// 「团队权限管理页」的点击
    static func trackImTeamAuthorityManagementClick(click: String,
                                                    target: String?) {
        var params: [String: String] = ["click": click]
        if let target = target {
            params["target"] = target
        }
        Tracker.post(TeaEvent(Homeric.IM_TEAM_AUTHORITY_MANAGEMENT_CLICK, params: params))
    }

    /// 「团队下创建群组页」的展示
    static func trackImTeamCreateChatView(groupMode: String) {
        Tracker.post(TeaEvent(Homeric.IM_TEAM_CREATE_CHAT_VIEW,
                              params: ["group_mode": groupMode]))
    }

    /// 「团队下创建群组页」的点击
    static func trackImTeamCreateChatClick(click: String,
                                           target: String,
                                           teamId: String,
                                           isAddAsMember: String,
                                           chatId: String) {
        var params: [String: String] = ["click": click,
                                        "target": target,
                                        "team_id": teamId,
                                        "is_add_as_member": isAddAsMember,
                                        "chat_id": chatId]
        Tracker.post(TeaEvent(Homeric.IM_TEAM_CREATE_CHAT_CLICK,
                              params: params))
    }

    static func trackImTeamCreateChatClick(click: String,
                                           target: String) {
        var params: [String: String] = ["click": click,
                                        "target": target]
        Tracker.post(TeaEvent(Homeric.IM_TEAM_CREATE_CHAT_CLICK,
                              params: params))
    }

    // 「添加成员数超限弹窗页」的展示
    static func trackTeamCreateFailPopupView() {
        Tracker.post(TeaEvent(Homeric.IM_TEAM_CREATE_FAIL_POPUP_VIEW, params: ["popup_type": "add_chat"]))
    }

    // 「添加已有群组」
    static func trackBindTeamChat(teamId: String, chatId: String) {
        var params: [String: String] = ["click": "set_mobile",
                                        "team_id": teamId,
                                        "chat_id": chatId]
        Tracker.post(TeaEvent("im_team_add_chat_click", params: params))
    }

    // 在团队成员列表页面 进入群聊
    static func trackTeamMemberListEnterChat(teamId: String, chatId: String) {
        var params: [String: String] = ["click": "enter_chat",
                                        "target": "im_chat_main_view",
                                        "team_id": teamId,
                                        "chat_id": chatId]
        Tracker.post(TeaEvent("feed_team_setting_click", params: params))
    }

    // 创建团队后「添加群组」弹窗的展示
    static func trackAddGroupShow() {
        Tracker.post(TeaEvent("im_add_team_chat_popup_view"))
    }

    // 创建团队后「添加群组」弹窗上的点击
    static func trackAddGroupClick(addChatCnt: Int) {
        let params = ["click": "add",
                      "add_chat_cnt": "\(addChatCnt)",
                      "target": "none"]
        Tracker.post(TeaEvent("im_add_team_chat_popup_click", params: params))
    }

    // 在团队「添加群组」页面发生的动作
    static func trackCreateChatClick(isAddChatDesc: Bool) {
        let params = ["click": "create",
                      "is_add_chat_desc": "\(isAddChatDesc)"]
        Tracker.post(TeaEvent("im_team_create_chat_click", params: params))
    }

    // 团队管理页面
    static func trackTeamSettingClick(teamID: String, click: String) {
        let params = ["click": click,
                      "target": "none",
                      "team_id": "\(teamID)"]
        Tracker.post(TeaEvent(Homeric.FEED_TEAM_SETTING_CLICK, params: params))
    }

    static func trackChatMian(teamID: String) {
        let params = ["click": "team",
                      "target": "none",
                      "team_id": "\(teamID)"]
        Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK, params: params))
    }

    /// 「群组解绑团队确认页面」的点击
    static func imGroupUnbundlingClickTrack(click: String,
                                            chatID: String,
                                            teamID: String,
                                            target: String) {
        var params: [AnyHashable: Any] = ["click": click,
                                          "chat_id": chatID,
                                          "team_id": teamID,
                                          "target": target]
        Tracker.post(TeaEvent(Homeric.IM_GROUP_UNBUNDLING_CLICK,
                              params: params))

    }

    /// 在「群管理页」发生动作事件
    static func imGroupManageClick(chat: Chat, myUserId: String, isOwner: Bool, isAdmin: Bool, clickType: String, extra: [String: String] = [:]) {
        var params: [String: Any] = ["chat_id": chat.id,
                                      "is_inner_group": !chat.isCrossTenant ? "true" : "false",
                                      "is_public_group": chat.isPublic ? "true" : "false"]
        params += extra
        Tracker.post(TeaEvent("im_group_manage_click",
                              params: params))
    }

    static func AddChatToTeamMenuClick(isCreateTeam: Bool) {
        var params: [AnyHashable: Any] = [:]
        if isCreateTeam {
            params["click"] = "create_team"
            params["target"] = "im_create_team_view"
        } else {
            params["click"] = "team"
            params["target"] = "feed_add_chat_toteam_popup_view"
        }
        Tracker.post(TeaEvent(Homeric.FEED_ADD_CHAT_TOTEAM_MENU_CLICK, params: params))
    }

    static func AddChatToTeamPopupClick(teamID: String, isNewTeam: Bool) {
        var params: [AnyHashable: Any] = [:]
        params["click"] = "add"
        params["team_id"] = teamID
        params["is_add_as_member"] = "0"
        if isNewTeam {
            params["team_type"] = "new_team"
        } else {
            params["team_type"] = "old_team"
        }
        Tracker.post(TeaEvent(Homeric.FEED_ADD_CHAT_TOTEAM_POPUP_CLICK, params: params))
    }

    public static func AddChatToTeamMenuView() {
        Tracker.post(TeaEvent(Homeric.FEED_ADD_CHAT_TOTEAM_MENU_VIEW))
    }

    public static func AddChatToTeamPopup() {
        Tracker.post(TeaEvent(Homeric.FEED_ADD_CHAT_TOTEAM_POPUP_VIEW))
    }
}
