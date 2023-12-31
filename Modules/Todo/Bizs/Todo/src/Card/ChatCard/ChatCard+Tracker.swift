//
//  ChatCard+Tracker.swift
//  Todo
//
//  Created by wangwanxin on 2021/5/13.
//

import Foundation

extension ChatCard {
    enum Track {}
}

extension ChatCard.Track: TrackerConvertible {
    /// 埋点 event
    enum TrackerEvent: String, TrackerEventKeyConvertible {
        /// 查看卡片
        case cardView = "todo_card_view"

        /// 在「todo卡片」发生动作事件
        case cardClick = "todo_card_click"

        /// 点击跳转任务中心
        case listCardClick = "todo_bot_list_card_click"

        var eventKey: String { rawValue }
    }

    enum TrackType: String {
        case remind
        case notification
        case share
        case new
    }

    struct CommonParameters {
        var guid: String
        var messageId: String
        var type: TrackType
    }

    /// 查看卡片
    static func viewCard(with commonParams: CommonParameters) {
        let params = [
            "task_id": commonParams.guid,
            "msg_id": commonParams.messageId,
            "type": commonParams.type.rawValue
        ]
        trackEvent(.cardView, with: params)
    }

    /// detail: 点击「查看任务详情」
    static func clickDetail(with commonParams: CommonParameters) {
        let params = [
            "task_id": commonParams.guid,
            "msg_id": commonParams.messageId,
            "type": commonParams.type.rawValue,
            "click": "detail",
            "target": "todo_task_detail_view"
        ]
        trackEvent(.cardClick, with: params)
    }

    /// check_box: 点击「完成」框
    static func clickCheckBox(with commonParams: CommonParameters, fromState: CompleteState) {
        var params = TrackerUtil.getClickCheckBoxParam(with: commonParams.guid, fromState: fromState, role: .todo)
        params["msg_id"] = commonParams.messageId
        params["type"] = commonParams.type.rawValue
        trackEvent(.cardClick, with: params)
    }

    /// check_box: 点击「完成」框（no-auth 状态）
    static func clickNoAuthCheckBox(with commonParams: CommonParameters) {
        let params = [
            "task_id": commonParams.guid,
            "msg_id": commonParams.messageId,
            "type": commonParams.type.rawValue,
            "click": "check_box",
            "target": "none",
            "status": "no_authorization"
        ]
        trackEvent(.cardClick, with: params)
    }

    /// follow:点击「关注」或者点击「取消关注」
    static func clickFollow(with commonParams: CommonParameters, isFollowed: Bool) {
        let params = [
            "task_id": commonParams.guid,
            "msg_id": commonParams.messageId,
            "type": commonParams.type.rawValue,
            "click": "follow",
            "target": "none",
            "status": isFollowed ? "unfollow_to_follow" : "follow_to_unfollow"
        ]
        trackEvent(.cardClick, with: params)
    }

    /// profile:唤起profile页时
    static func clickProfile(with commonParams: CommonParameters) {
        let params = [
            "task_id": commonParams.guid,
            "msg_id": commonParams.messageId,
            "type": commonParams.type.rawValue,
            "click": "profile",
            "target": "profile_main_view"
        ]
        trackEvent(.cardClick, with: params)
    }

    /// 点击每日提醒跳转任务中心
    static func clickDailyReminderBtn() {
        let params = ["click": "check_more", "target": "todo_center_task_list_view"]
        trackEvent(.listCardClick, with: params)
    }

    /// 点击卡片打开任务中心
    static func clickOpenCenter(with commonParams: CommonParameters) {
        let params = [
            "task_id": commonParams.guid,
            "msg_id": commonParams.messageId,
            "type": commonParams.type.rawValue,
            "click": "check_more",
            "target": "todo_center_task_list_view"
        ]
        trackEvent(.cardClick, with: params)
    }

}
