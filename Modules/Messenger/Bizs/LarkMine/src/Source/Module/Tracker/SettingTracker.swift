//
//  SettingTracker.swift
//  LarkMine
//
//  Created by 夏汝震 on 2021/5/17.
//

import Foundation
import LKCommonsTracker
import Homeric

///「设置」页面相关埋点
public struct SettingTracker {
    struct Main {}
    struct Detail {}
}

/// 「头像下的主设置页」的展示
extension SettingTracker.Main {
    static func View() {
        Tracker.post(TeaEvent(Homeric.SETTING_MAIN_VIEW))
    }
}

///「头像下的主设置页」的动作事件
extension SettingTracker.Main {
    struct Click {

        /// 侧边栏点击进到profile
        static func ProfileDetail() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "profile_detail"
            params["target"] = "profile_main_view"
            Tracker.post(TeaEvent(Homeric.SETTING_MAIN_CLICK, params: params))
        }

        /// 点击设置
        static func Setting() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "setting"
            params["target"] = "setting_detail_view"
            Tracker.post(TeaEvent(Homeric.SETTING_MAIN_CLICK, params: params))
        }

        /// 点击个人状态入口
        static func FocusList() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "personal_status"
            params["target"] = "setting_personal_status_view"
            Tracker.post(TeaEvent(Homeric.SETTING_MAIN_CLICK, params: params))
        }

        /// 点击我的二维码与链接
        static func PersonalLink() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "personal_link"
            params["target"] = "onboarding_add_external_contact_qrcode_link_view"
            Tracker.post(TeaEvent(Homeric.SETTING_MAIN_CLICK, params: params))
        }

        /// 加入或创建团队
        static func JoinCreateTeam() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "join_or_create_team"
            params["target"] = "onboarding_team_join_create_upgrade_view"
            Tracker.post(TeaEvent(Homeric.SETTING_MAIN_CLICK, params: params))
        }

        /// 帮助与客服
        static func Help() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "help"
            params["target"] = "hc_help_view"
            Tracker.post(TeaEvent(Homeric.SETTING_MAIN_CLICK, params: params))
        }

        /// 收藏
        static func Favorite() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "favorite"
            params["target"] = "public_favorite_main_view"
            Tracker.post(TeaEvent(Homeric.SETTING_MAIN_CLICK, params: params))
        }

        /// 钱包
        static func Wallet() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "wallet"
            params["target"] = "public_wallet_view"
            Tracker.post(TeaEvent(Homeric.SETTING_MAIN_CLICK, params: params))
        }

        /// 设备登录管理
        static func Device() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "device"
            params["target"] = "public_device_view"
            Tracker.post(TeaEvent(Homeric.SETTING_MAIN_CLICK, params: params))
        }

        /// 勿扰模式
        static func DoNotDisturb() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "do_not_disturb"
            params["target"] = "none"
            Tracker.post(TeaEvent(Homeric.SETTING_MAIN_CLICK, params: params))
        }

        /// 状态
        static func Status() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "status"
            params["target"] = "none"
            Tracker.post(TeaEvent(Homeric.SETTING_MAIN_CLICK, params: params))
        }

        /// sos紧急联系人
        static func Sos() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "sos"
            params["target"] = "im_chat_main_view"
            Tracker.post(TeaEvent(Homeric.SETTING_MAIN_CLICK, params: params))
        }

        /// 移动端认证标识
//        static func Verify() {
//            var params: [AnyHashable: Any] = [:]
//            params["click"] = "madmin_verification"
//            params["target"] = "none"
//            Tracker.post(TeaEvent(Homeric.SETTING_MAIN_CLICK, params: params))
//        }

        /// 点击个人状态设置页入口
        static func FocusSetting() {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "personal_status"
            params["target"] = "setting_personal_status_detail_view"
            Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: params))
        }

        /// 「全局设置页」的点击 -> 「at所有人」开关
//        static func AtAllToggle(status: Bool) {
//            var params: [AnyHashable: Any] = [:]
//            params["click"] = "at_all_toggle"
//            params["target"] = "none"
//            params["status"] = status ? "on" : "off"
//            Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: params))
//        }

        /// 「全局设置页」的点击 -> 「at我的消息」开关
//        static func AtMeToggle(status: Bool) {
//            var params: [AnyHashable: Any] = [:]
//            params["click"] = "at_me_toggle"
//            params["target"] = "none"
//            params["status"] = status ? "on" : "off"
//            Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: params))
//        }

        /// 「全局设置页」的点击 -> 免打扰「展示提醒」开关
        static func ShowMuteRemind(status: Bool) {
            var params: [AnyHashable: Any] = [:]
            params["click"] = "show_mute_remind_toggle"
            params["target"] = "none"
            params["status"] = status ? "on" : "off"
            Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: params))
        }
    }
}

/// 「全局设置页」相关埋点
extension SettingTracker.Detail {
    /// 「全局设置页」的展示
    static func View() {
        Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_VIEW))
    }
}
