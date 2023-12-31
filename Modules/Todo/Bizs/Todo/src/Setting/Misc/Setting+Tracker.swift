//
//  Setting+Tracker.swift
//  Todo
//
//  Created by wangwanxin on 2021/6/7.
//

import Foundation

extension Setting {
    enum Track {}
}

extension Setting.Track: TrackerConvertible {

    /// Home埋点 event
    enum TrackerEvent: String, TrackerEventKeyConvertible {
        /// 「任务设置页面」展示时上报
        case viewSettiing = "setting_todo_view"
        /// 在「任务设置页面」发生动作事件
        case settingClick = "setting_todo_click"
        /// 「任务徽标设置页面」展示时上报
        case viewBadgeSetting = "setting_todo_badge_view"
        /// 在「任务徽标设置页面」发生动作事件上报
        case badgeSettingClick = "setting_todo_badge_click"
        /// 「默认提醒时间设置页面」展示时上报
        case viewDefaultReminder = "setting_todo_default_alert_time_view"
        /// 「默认提醒时间设置页面」发生动作事件上报
        case defaultReminderClick = "setting_todo_default_alert_time_click"

        var eventKey: String { rawValue }
    }
}

extension Setting.Track {

    /// 「任务设置页面」展示时上报
    static func viewSetting() {
        trackEvent(.viewSettiing)
    }

    /// task_badge_setting：任务徽标设置
    static func clickBadgeSetting() {
        let param = [
            "click": "task_badge_setting",
            "target": "setting_todo_badge_view"
        ]
        trackEvent(.settingClick, with: param)
    }

    /// 每日提醒设置
    static func clickDailyReminderSetting(isOn: Bool) {
        let status = isOn ? "off_to_on" : "on_to_off"
        let param = [
            "click": "task_alert",
            "target": "setting_todo_view",
            "status": status
        ]
        trackEvent(.settingClick, with: param)
    }

    /// 默认提醒时间设置
    static func clickDefaultReminderSetting() {
        let param = [
            "click": "default_alert_time",
            "target": "setting_todo_default_alert_time_view"
        ]
        trackEvent(.settingClick, with: param)
    }

    /// 「任务徽标设置页面」展示时上报
    static func viewBadgeSetting() {
        trackEvent(.viewBadgeSetting)

    }

    /// allow_badge：允许徽标提示按钮
    static func clickAllowBadge(isOn: Bool) {
        let param = [
            "click": "allow_badge",
            "target": "none",
            "status": isOn ? "off_to_on" : "on_to_off"
        ]
        trackEvent(.badgeSettingClick, with: param)
    }

    /// 「默认提醒时间设置页面」展示时上报
    static func viewDefaultReminder() {
        trackEvent(.viewDefaultReminder)

    }

    /// 「默认提醒时间设置页面」点击保存
    static func defaultReminderClickConfirm(status: String) {
        let param = ["click": "complete", "target": "setting_todo_view", "status": status]
        trackEvent(.defaultReminderClick, with: param)
    }

    /// 「默认提醒时间设置页面」点击取消
    static func defaultReminderClickCancel() {
        let param = ["click": "cancel", "target": "setting_todo_view"]
        trackEvent(.defaultReminderClick, with: param)
    }

    /// badge_type：提示类型
    static func clickBadgeType(type: Rust.ListBadgeType) {
        let param = [
            "click": "badge_type",
            "target": "none",
            "status": type == .overdue ? "overdue" : "overdue_or_due_today"
        ]
        trackEvent(.badgeSettingClick, with: param)
    }
}
