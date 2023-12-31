//
//  UrgentTracker.swift
//  LarkUrgent
//
//  Created by chengzhipeng-bytedance on 2018/9/17.
//

import Foundation
import Homeric
import LarkCore
import LarkModel
import LKCommonsTracker

public final class UrgentTracker {
    static func trackMessageUrgentSend() {
        Tracker.post(TeaEvent(Homeric.BUZZ_SENT, category: "message"))
    }

    static func trackUnreadCheckboxSelect() {
        Tracker.post(TeaEvent(Homeric.BUZZ_UNREAD_CHECKBOX, category: "message"))
    }

    static func trackBuzzCancelBlock() {
        Tracker.post(TeaEvent(Homeric.COLLABORATION_CANCEL_BLOCK, params: ["scene": "Buzz"]))
    }

    // 移动端「加急确认页」的展示
    static func trackImDingConfirmView(chat: Chat,
                                       message: Message) {
        var params: [AnyHashable: Any] = [:]
        params += IMTracker.Param.chat(chat)
        params += IMTracker.Param.message(message)
        Tracker.post(TeaEvent(Homeric.IM_DING_CONFIRM_VIEW, params: params))
    }

    // 移动端「加急确认页」，发生动作事件
    static func trackImDingConfirmClick(click: String,
                                        target: String,
                                        chat: Chat,
                                        message: Message) {
        var params: [AnyHashable: Any] = ["click": click,
                                          "target": target]
        params += IMTracker.Param.chat(chat)
        params += IMTracker.Param.message(message)
        Tracker.post(TeaEvent(Homeric.IM_DING_CONFIRM_CLICK, params: params))
    }

    // 移动端「选择接收人页」的展示
    static func trackImDingReceiverSelectView(chat: Chat,
                                              message: Message) {
        var params: [AnyHashable: Any] = [:]
        params += IMTracker.Param.chat(chat)
        params += IMTracker.Param.message(message)
        Tracker.post(TeaEvent(Homeric.IM_DING_RECEIVER_SELECT_VIEW, params: params))
    }

    // 移动端「选择接收人页」，发生动作事件
    static func trackImDingReceiverSelectClick(click: String,
                                               target: String,
                                               isAllUnreadMemberSelected: Bool? = nil,
                                               chat: Chat,
                                               message: Message) {
        var params: [AnyHashable: Any] = ["click": click,
                                          "target": target,
                                          "is_all_unread_member_selected": isAllUnreadMemberSelected == true ? "true" : "false"]
        params += IMTracker.Param.chat(chat)
        params += IMTracker.Param.message(message)
        Tracker.post(TeaEvent(Homeric.IM_DING_RECEIVER_SELECT_CLICK,
                              params: params))
    }

    //「加急失败回执页」的展示
    static func trackImDingFailedReturnView(chat: Chat,
                                            message: Message) {
        var params: [AnyHashable: Any] = [:]
        params += IMTracker.Param.chat(chat)
        params += IMTracker.Param.message(message)
        Tracker.post(TeaEvent(Homeric.IM_DING_FAILED_RETURN_VIEW, params: params))
    }

    //「加急失败回执页」，发生动作事件
    static func trackImDingFailedReturnClick(click: String,
                                             target: String,
                                             chat: Chat,
                                             message: Message) {
        var params: [AnyHashable: Any] = ["click": click,
                                          "target": target]
        params += IMTracker.Param.chat(chat)
        params += IMTracker.Param.message(message)
        Tracker.post(TeaEvent(Homeric.IM_DING_FAILED_RETURN_CLICK, params: params))
    }

    // 提醒添加加急电话到通讯录的页面展示时上报
    static func trackImDingMsgOnboardingView() {
        Tracker.post(TeaEvent("im_ding_msg_onboarding_view"))
    }

    // 提醒添加加急电话到通讯录页面的点击行为
    static func trackImDingMsgOnboardingClick(isAdd: Bool) {
        var params: [AnyHashable: Any] = ["click": isAdd ? "add" : "cancel"]
        Tracker.post(TeaEvent("im_ding_msg_onboarding_click", params: params))
    }

    // 添加加急电话到通讯录状态变化时上报（只记录真正打开/关闭的最终结果）
    static func trackSettingDingAddToAddressClick(isOpen: Bool) {
        var params: [AnyHashable: Any] = ["result": isOpen ? "open" : "close"]
        Tracker.post(TeaEvent("setting_ding_add_to_address_click", params: params))
    }
}
