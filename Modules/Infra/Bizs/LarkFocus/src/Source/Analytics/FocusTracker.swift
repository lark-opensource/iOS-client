//
//  FocusTracker.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/10/15.
//

import Foundation
import Homeric
import LKCommonsTracker

enum FocusTracker {

    // MARK: 状态列表页

    static var isFirstLoadFocusList: Bool = true

    /// 打开详情页面，并加载列表完成
    static func didShowFocusList(focusList: [UserFocusStatus], activeStatus: UserFocusStatus?) {
        guard isFirstLoadFocusList else { return }
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_VIEW, params: [
            "status_num": focusList.count,
            "is_status_on": (activeStatus != nil).string
        ]))
        isFirstLoadFocusList = false
    }

    /// 点击了状态卡片的展开按钮
    static func didTapExpandButton(_ status: UserFocusStatus) {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_CLICK, params: [
            "click": "more",
            "target": "setting_personal_status_float_view",
            "status_id": status.id
        ]))
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_FLOAT_VIEW, params: [
            "status_id": status.id
        ]))
    }

    /// 点击了状态卡片的折叠按钮
    static func didTapFoldButton(_ status: UserFocusStatus) {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_CLICK, params: [
            "click": "up",
            "target": "none",
            "status_id": status.id
        ]))
    }

    /// 点击了创建新状态按钮
    static func didTapAddNewFocusButton() {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_CLICK, params: [
            "click": "add_status",
            "target": "setting_personal_status_add_change_view"
        ]))
    }

    /// 点击了状态设置按钮
    static func didTapFocusSettingButton() {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_CLICK, params: [
            "click": "more_status",
            "target": "setting_personal_status_detail_view"
        ]))
    }

    /// 点击了状态编辑按钮
    static func didTapFocusEditButton(_ status: UserFocusStatus) {
        // Analytics
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_FLOAT_CLICK, params: [
            "click": "more_setting",
            "target": "setting_personal_status_add_change_view",
            "status_id": status.id
        ]))
    }

    /// 从列表中开启某个状态
    static func turnOnFocusStatus(_ status: UserFocusStatus) {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_CLICK, params: [
            "click": "change_status",
            "status_id": status.id,
            "status": "on",
            "target": "none"
        ]))
    }

    /// 点击时间标签开启某个状态
    static func turnOnFocusStatus(_ status: UserFocusStatus, withPeriod period: FocusPeriod) {
        guard !period.isCustomized else { return }
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_FLOAT_CLICK, params: [
            "status_id": status.id,
            "click": "fixed_time",
            "icon_duration": period.analyticName,
            "status": "on",
            "target": "none"
        ]))
    }

    /// 点击“其他时间”标签
    static func turnOnFocusStatusWithCustomTag(_ status: UserFocusStatus) {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_FLOAT_CLICK, params: [
            "status_id": status.id,
            "click": "other_time",
            "target": "setting_personal_status_time_change_view"
        ]))
    }

    /// 从列表中关闭某个状态
    static func turnOffFocusStatus(_ status: UserFocusStatus) {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_CLICK, params: [
            "status_id": status.id,
            "click": "change_status",
            "status": "off",
            "target": "none"
        ]))
    }

    /// 点击时间标签关闭某个状态
    static func turnOffFocusStatus(_ status: UserFocusStatus, withPeriod period: FocusPeriod) {
        if period.isCustomized {
            Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_FLOAT_CLICK, params: [
                "status_id": status.id,
                "click": "customized_time",
                "target": "none"
            ]))
        } else {
            Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_FLOAT_CLICK, params: [
                "status_id": status.id,
                "click": "fixed_time",
                "icon_duration": period.analyticName,
                "status": "off",
                "target": "none"
            ]))
        }
    }

    // MARK: 时间选择器

    /// 打开时间选择器页面
    static func didShowTimePicker(_ status: UserFocusStatus) {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_TIME_CHANGE_VIEW, params: [
            "status_id": status.id
        ]))
    }

    /// 点击了时间选择器的“开启”按钮
    static func didTapConfirmButtonOnTimePicker(_ status: UserFocusStatus, date: Date) {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_TIME_CHANGE_CLICK, params: [
            "click": "open",
            "target": "setting_personal_status_float_view",
            "time": "\(Int(date.timeIntervalSince1970))",
            "status_id": status.id
        ]))
    }

    /// 点击了时间选择器的“取消”按钮
    static func didTapCancelButtonOnTimePicker(_ status: UserFocusStatus) {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_TIME_CHANGE_CLICK, params: [
            "click": "cancel",
            "target": "setting_personal_status_float_view",
            "status_id": status.id
        ]))
    }

    // MARK: 新建/修改状态页面

    enum FocusDetailPageType: String {
        case create = "create"
        case edit = "change"
    }

    /// “新建/修改”页面展示
    static func didShowFocusDetailPage(pageType: FocusDetailPageType, status: UserFocusStatus) {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_ADD_CHANGE_VIEW, params: [
            "page_type": pageType.rawValue,
            "status_card": status.eventName
        ]))
    }

    static func didTapCancelButtonOnDetailPage(pageType: FocusDetailPageType, status: UserFocusStatus) {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_ADD_CHANGE_CLICK, params: [
            "click": "cancel",
            "target": "none",
            "page_type": pageType.rawValue,
            "status_card": status.eventName
        ]))
    }

    static func didTapSaveButtonOnDetailPage(pageType: FocusDetailPageType, status: UserFocusStatus) {
        var params: [String: Any] = [
            "click": "save",
            "target": "none",
            "notification_status": status.isNotDisturbMode ? "mute" : "unmute",
            "page_type": pageType.rawValue,
            "status_card": status.eventName
        ]
        if let isSyncSettingOn = status.isSyncSettingOn {
            params["automatic_status"] = isSyncSettingOn ? "auto" : "nonauto"
        }
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_ADD_CHANGE_CLICK, params: params))
    }

    static func didChangeStatusNameInDetailPage(pageType: FocusDetailPageType, status: UserFocusStatus) {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_ADD_CHANGE_CLICK, params: [
            "click": "change_status_name",
            "target": "none",
            "page_type": pageType.rawValue,
            "status_card": status.eventName
        ]))
    }

    static func didChangeStatusIconInDetailPage(pageType: FocusDetailPageType, status: UserFocusStatus) {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_ADD_CHANGE_CLICK, params: [
            "click": "change_emoji",
            "target": "none",
            "page_type": pageType.rawValue,
            "status_card": status.eventName
        ]))
    }

    static func didShowStatusNameOutOfRangeToast() {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_TEXT_OVER_TOAST_VIEW))
    }

    static func didTapDeleteButtonInEditPage() {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_ADD_CHANGE_CLICK, params: [
            "click": "delete_status",
            "target": "setting_personal_status_detail_change_confirm_view",
            "page_type": FocusDetailPageType.edit.rawValue,
            "status_card": UserFocusType.custom.analyticsName
        ]))
    }

    // MARK: “删除状态”确认弹窗

    static func didShowDeletionAlert() {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_DETAIL_CHANGE_CONFIRM_VIEW))
    }

    static func didTapConfirmButtonInDeletionAlert() {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_DETAIL_CHANGE_CONFIRM_CLICK, params: [
            "click": "delete",
            "target": "setting_personal_status_add_change_view"
        ]))
    }

    static func didTapCancelButtonInDeletionAlert() {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_DETAIL_CHANGE_CONFIRM_CLICK, params: [
            "click": "cancel",
            "target": "setting_personal_status_add_change_view"
        ]))
    }

    // MARK: 个人状态总设置页

    static func didShowFocusSettingPage() {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_DETAIL_VIEW))
    }

    static func didTapBackButtonInSettingPage(syncSetting: [Int64: Bool]) {
        var params: [String: Any] = [
            "click": "back",
            "target": "none"
        ]
        if let leaveSetting = syncSetting[Int64(FocusSyncType.isSynOnLeave.rawValue)] {
            params["holiday_automatic_status"] = leaveSetting ? "automatic" : "nonautomatic"
        }
        if let meetingSetting = syncSetting[Int64(FocusSyncType.isSynOnLeave.rawValue)] {
            params["meeting_automatic_status"] = meetingSetting ? "automatic" : "nonautomatic"
        }
        if let scheduleSetting = syncSetting[Int64(FocusSyncType.isSynOnLeave.rawValue)] {
            params["calendar_automatic_status"] = scheduleSetting ? "automatic" : "nonautomatic"
        }
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_DETAIL_CLICK, params: params))
    }

    static func didTapStatusRowInSettingPage(status: UserFocusStatus) {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_DETAIL_CLICK, params: [
            "click": "status_icon",
            "target": "setting_personal_status_add_change_view",
            "status_card": status.eventName
        ]))
    }

    static func didTapCreateNewStatusInSettingPage() {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_DETAIL_CLICK, params: [
            "click": "add_status",
            "target": "setting_personal_status_add_change_view"
        ]))
    }

    static func didToggleShowAllStatusInSettingPage(isExpanded: Bool) {
        Tracker.post(TeaEvent(Homeric.SETTING_PERSONAL_STATUS_DETAIL_CLICK, params: [
            "click": "all_status",
            "target": "none",
            "show_status": isExpanded ? "wide" : "narrow"
        ]))
    }
}

// MARK: - Extensions

private extension Bool {

    var string: String {
        return self ? "true" : "false"
    }
}

private extension FocusPeriod {

    var analyticName: String {
        switch self {
        case .minutes30:    return "30"
        case .hour1:        return "60"
        case .hour2:        return "120"
        case .hour4:        return "240"
        case .untilTonight: return "tonight"
        case .customized:   return ""
        case .preset:       return ""
        case .noEndTime:    return ""
        }
    }

    var isCustomized: Bool {
        switch self {
        case .customized:   return true
        case .preset:       return true
        default:            return false
        }
    }
}

private extension UserFocusType {

    var analyticsName: String {
        switch self {
        case .noDisturb:    return "do_not_disturb"
        case .inMeeting:    return "in_meeting"
        case .onLeave:      return "in_holiday"
        case .custom:       return "customized"
        @unknown default:            return "unknown"
        }
    }
}

private extension UserFocusTypeV2 {

    var analyticsName: String {
        switch self {
        case .systemV2:     return "system"
        case .commonV2:     return "common"
        case .customV2:     return "customized"
        case .unknownV2:    return "unknown"
        @unknown default:   return "unknown"
        }
    }
}

private extension UserFocusStatus {

    /// 该状态是否开启了同步设置，nil 表示没有同步设置
    var isSyncSettingOn: Bool? {
        guard hasSyncSettings, !syncSettings.isEmpty else { return nil }
        for value in syncSettings.values {
            if value { return true }
        }
        return false
    }
}
