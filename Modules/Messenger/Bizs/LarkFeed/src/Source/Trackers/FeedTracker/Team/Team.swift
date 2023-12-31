//
//  Team.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/8/20.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkModel
import RustPB

/// [团队] 相关埋点
extension FeedTracker {
    struct Team {}
}

extension FeedTracker.Team {
    public static func MoreView(teamId: String) {
        var params: [AnyHashable: Any] = [:]
        params["team_id"] = teamId
        Tracker.post(TeaEvent(Homeric.FEED_TEAM_MORE_VIEW, params: params))
    }
}

extension FeedTracker.Team {
    struct Click {
        // 点击团队
        static func Team(teamId: String, isFold: Bool) {
            let params = ["click": "click_team",
                          "target": "none",
                          "team_id": teamId,
                          "is_narrow": isFold ? "true" : "false"]
             Tracker.post(TeaEvent(Homeric.FEED_TEAM_CLICK,
                                   params: params))
        }

        // 点击「···」
        static func MoreTeam(teamId: String) {
            let params = ["click": "more_team",
                          "target": "feed_team_more_view",
                          "team_id": teamId]
            Tracker.post(TeaEvent(Homeric.FEED_TEAM_CLICK,
                                   params: params))
        }

        /// 点击某条会话feed
        public static func Chat(team: Basic_V1_Team, feed: FeedPreview) {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "click_chat"
            params["target"] = "im_chat_main_view"
            params["team_id"] = String(team.id)
            params["chat_id"] = feed.id
            params["is_default_chat"] = String(team.defaultChatID) == feed.id ? "true" : "false"
            params["chat_unread_num"] = feed.basicMeta.unreadCount
            Tracker.post(TeaEvent(Homeric.FEED_TEAM_CLICK, params: params))
        }

        // 添加成员
        public static func AddUser(teamId: String) {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "add_user"
            params["target"] = "feed_team_add_user_view"
            params["team_id"] = teamId
            Tracker.post(TeaEvent(Homeric.FEED_TEAM_MORE_CLICK, params: params))
        }

        // 添加群组
        public static func AddChat(teamId: String) {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "add_chat"
            params["target"] = "feed_team_add_chat_view"
            params["team_id"] = teamId
            Tracker.post(TeaEvent(Homeric.FEED_TEAM_MORE_CLICK, params: params))
        }
        // 创建群组
        public static func CreateChat(teamId: String) {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "create_chat"
            params["target"] = "feed_team_create_chat_view"
            params["team_id"] = teamId
            Tracker.post(TeaEvent(Homeric.FEED_TEAM_MORE_CLICK, params: params))
        }

        // 团队设置
        public static func TeamSetting(teamId: String) {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "team_setting"
            params["target"] = "feed_team_setting_view"
            params["team_id"] = teamId
            Tracker.post(TeaEvent(Homeric.FEED_TEAM_MORE_CLICK, params: params))
        }

        // 团队批量清除badge
        public static func BatchClearTeamBadge(teamId: String, unreadCount: Int, muteUnreadCount: Int) {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "clean_badge"
            params["evoke_type"] = "label_detail_view_click_more"
            params["team_id"] = teamId
            params["target"] = "feed_clean_badge_confirm_view"
            params["clean_badge_mute"] = "\(muteUnreadCount)"
            params["clean_badge_unmute"] = "\(unreadCount)"
            Tracker.post(TeaEvent(Homeric.FEED_TEAM_MORE_CLICK, params: params))
        }

        public static func BatchClearTeamBadgeConfirm(filterType: Feed_V1_FeedFilter.TypeEnum, unreadCount: Int, muteUnreadCount: Int) {
            let clickValue = FeedTracker.Group.Name(groupType: filterType)
            let params: [String: Any] = ["click": "confirm",
                          "target": "none",
                          "clean_tab_name": clickValue,
                          "clean_badge_mute": "\(muteUnreadCount)",
                          "clean_badge_unmute": "\(unreadCount)"]
            Tracker.post(TeaEvent(Homeric.FEED_CLEAN_BADGE_CONFIRM_CLICK, params: params))
        }

        public static func BatchMuteTeamFeedsConfirm(mute: Bool) {
            let params = ["click": "confirm",
                          "target": "none"]
            if mute {
                Tracker.post(TeaEvent(Homeric.FEED_ALL_MUTE_CONFIRM_CLICK,
                                      params: params))
            } else {
                Tracker.post(TeaEvent(Homeric.FEED_ALL_UNMUTE_CONFIRM_CLICK,
                                      params: params))
            }
        }

        public static func BatchMuteTeamFeeds(teamId: String, mute: Bool) {
            var params: [AnyHashable: Any] = [:]
            if mute {
                params["click"] = "all_mute"
                params["target"] = "feed_all_mute_confirm_view"
            } else {
                params["click"] = "all_unmute"
                params["target"] = "feed_all_unmute_confirm_view"
            }
            params["evoke_type"] = "label_detail_view_click_more"
            params["team_id"] = teamId
            Tracker.post(TeaEvent(Homeric.FEED_TEAM_MORE_CLICK, params: params))
        }

        public static func FirstOpenAtAll(teamId: String, openAtAll: Bool) {
            var params: [AnyHashable: Any] = [:]
            if openAtAll {
                params["click"] = "open_at_all"
                params["target"] = "feed_open_at_all_notification_view"
            } else {
                params["click"] = "close_at_all"
                params["target"] = "feed_close_at_all_notification_view"
            }
            params["evoke_type"] = "label_detail_view_click_more"
            params["team_id"] = teamId
            Tracker.post(TeaEvent("feed_team_more_click", params: params))
        }

        public static func AddChatToTeamMenuClick(isCreateTeam: Bool) {
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
    }

    struct View {
        public static func AddChatToTeamMenuView() {
            Tracker.post(TeaEvent(Homeric.FEED_ADD_CHAT_TOTEAM_MENU_VIEW))
        }
    }
}
