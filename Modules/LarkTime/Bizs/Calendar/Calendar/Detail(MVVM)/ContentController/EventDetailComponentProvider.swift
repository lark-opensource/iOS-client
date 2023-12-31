//
//  EventDetailComponentProvider.swift
//  Calendar
//
//  Created by Rico on 2021/3/18.
//

import Foundation
import CalendarFoundation

enum EventDetailComponent: String {
    // 导航栏
    case navigation
    // 头部功能区
    case header
    // 秘钥不可用内容区
    case undecryptableDetail
    // 日历名称
    case calendar
    // 视频会议
    case videoMeeting
    // zoom会议
    case zoomMeeting
    // 视频直播
    case videoLive
    // 创建者
    case creator
    // 组织者
    case organizer
    // 参与者
    case attendee
    // webinar 嘉宾
    case webinarSpeaker
    // webinar 观众
    case webinarAudience
    // 地点
    case location
    // 描述
    case description
    // 签到
    case checkIn
    // 提醒
    case remind
    // 日程可见性
    case visibility
    // 忙闲
    case freebusy
    // 会议室信息
    case meetingRoom
    // 有效会议
    case meetingNotes
    // 附件
    case attachment
    // 底部交互区（加入日程/RSVP）
    case bottomAction
    // 冲突视图
    case conflict
}

protocol EventDetailComponentProvider {

    func shouldLoadComponent(for componentType: EventDetailComponent) -> Bool

    func buildComponent(for componentType: EventDetailComponent) -> ComponentType?

    var model: EventDetailModel { get }
}
