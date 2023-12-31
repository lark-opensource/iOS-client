//
//  Navigation.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/5/11.
//

import Foundation
import LKCommonsTracker
import Homeric

/// 导航栏相关埋点
extension FeedTracker {
    struct Navigation {}
}

extension FeedTracker.Navigation {
    struct Click {
        /// 点击全局搜索框
        static func Search() {
            var params: [AnyHashable: TeaDataType] = [:]
            params["click"] = "search"
            params["target"] = "search_main_view"
            Tracker.post(TeaEvent(Homeric.NAVIGATION_TOP_CLICK, params: params))
        }

        /// 点击feed页面的「+」号
        static func Plus() {
            var params: [AnyHashable: TeaDataType] = [:]
            params["click"] = "feed_plus"
            params["target"] = "feed_plus_view"
            Tracker.post(TeaEvent(Homeric.NAVIGATION_TOP_CLICK, params: params))
        }

        /// 点击feed页面的头像
        static func Avatar() {
            var params: [AnyHashable: TeaDataType] = [:]
            params["click"] = "avatar"
            params["target"] = "setting_main_view"
            Tracker.post(TeaEvent(Homeric.NAVIGATION_TOP_CLICK, params: params))
        }

        /// 点击feed页面的个人状态
        static func PersonalStatus() {
            var params: [AnyHashable: TeaDataType] = [:]
            params["click"] = "personal_status"
            params["target"] = "setting_personal_status_view"
            Tracker.post(TeaEvent(Homeric.NAVIGATION_TOP_CLICK, params: params))
        }
    }
}

extension FeedTracker {
    struct Plus {}
}

extension FeedTracker.Plus {
    /// 搜索框旁「feed+号下拉页」的展示
    static func View() {
        Tracker.post(TeaEvent(Homeric.FEED_PLUS_VIEW))
    }

    struct Click {
        /// 创建群组
        static func CreateGroup() {
            var params: [AnyHashable: TeaDataType] = [:]
            params["click"] = "group_create"
            params["target"] = "im_group_create_view"
            Tracker.post(TeaEvent(Homeric.FEED_PLUS_CLICK, params: params))
        }

        /// 扫一扫
        static func Scan() {
            var params: [AnyHashable: TeaDataType] = [:]
            params["click"] = "scan_QR_code"
            params["target"] = "lark_app_add_external_contact_scan_qrcode_view"
            Tracker.post(TeaEvent(Homeric.FEED_PLUS_CLICK, params: params))
        }

        /// 添加外部联系人页
        static func InviteExternal() {
            var params: [AnyHashable: TeaDataType] = [:]
            params["click"] = "contact_add_external_view"
            params["target"] = "contact_add_external_view"
            Tracker.post(TeaEvent(Homeric.FEED_PLUS_CLICK, params: params))
        }

        /// 创建团队
        static func CreateTeam() {
            var params: [AnyHashable: TeaDataType] = [:]
            params["click"] = "mobile_create_team"
            params["target"] = "feed_create_team_type_view"
            Tracker.post(TeaEvent(Homeric.FEED_PLUS_CLICK, params: params))
        }

        /// 创建文档
        static func CreateDocs() {
            var params: [AnyHashable: TeaDataType] = [:]
            params["click"] = "create_docs"
            params["target"] = "ccm_docs_page_view"
            Tracker.post(TeaEvent(Homeric.FEED_PLUS_CLICK, params: params))
        }

        /// 创建会议
        static func NewMeeting() {
            var params: [AnyHashable: TeaDataType] = [:]
            params["click"] = "new_meeting"
            params["target"] = "vc_meeting_pre_view"
            Tracker.post(TeaEvent(Homeric.FEED_PLUS_CLICK, params: params))
        }

        /// 加入会议
        static func JoinMeeting() {
            var params: [AnyHashable: TeaDataType] = [:]
            params["click"] = "join_meeting"
            params["target"] = "vc_meeting_pre_view"
            Tracker.post(TeaEvent(Homeric.FEED_PLUS_CLICK, params: params))
        }

        /// 会议室投屏
        static func ShareScreen() {
            var params: [AnyHashable: TeaDataType] = [:]
            params["click"] = "share_screen"
            params["target"] = "vc_meeting_sharewindow_view"
            Tracker.post(TeaEvent(Homeric.FEED_PLUS_CLICK, params: params))
        }
    }
}
