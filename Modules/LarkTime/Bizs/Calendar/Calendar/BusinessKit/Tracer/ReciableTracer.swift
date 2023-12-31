//
//  ReciableTracer.swift
//  Alamofire
//
//  Created by lianghongbin on 2020/8/19.
//

import Foundation
import AppReciableSDK
import ThreadSafeDataStructure

public final class ReciableTracer {
    private var keyMap: SafeDictionary<ReciableKey, DisposedKey> = [:] + .readWriteLock
    public static let shared: ReciableTracer = ReciableTracer()

    private let calendarDiagram = "cal_diagram"
    private let calendarBotCard = "cal_bot_card"
    private let calendarEventDetail = "cal_event_detail"
    private let calendarEventCreate = "cal_event_create"
    private let calReplyRsvp = "cal_reply_rsvp"

    // 打开完整添加页 - 编辑日程
    public func recStartAddFull() {
        recTracerStart(scene: Scene.CalEventDetail, event: .addFullEvent, page: calendarDiagram)
    }

    public func recEndAddFull() {
        recTracerEnd(scene: Scene.CalEventDetail, event: .addFullEvent, page: calendarDiagram)
    }

    // 切换视图
    public func recStartSwitch() {
        recTracerStart(scene: Scene.CalDiagram, event: .switchDiagram, page: calendarDiagram)
    }

    public func recEndSwitch() {
        recTracerEnd(scene: Scene.CalDiagram, event: .switchDiagram, page: calendarDiagram)
    }

    // 打开日程详情页
    public func recStartEventDetail() {
        recTracerStart(scene: Scene.CalEventDetail, event: .checkEvent, page: calendarDiagram)
    }

    public func recEndEventDetail() {
        recTracerEnd(scene: Scene.CalEventDetail, event: .checkEvent, page: calendarDiagram)
    }

    // 日程通知卡片 - 回复RSVP（接受/拒绝/待定）
    public func recStartBotReply() {
        recTracerStart(scene: Scene.CalBot, event: .replyRsvp, page: calendarBotCard)
    }

    public func recEndBotReply() {
        recTracerEnd(scene: Scene.CalBot, event: .replyRsvp, page: calendarBotCard)
    }

    // 日程详情页-转发日程
    public func recStartTransf() {
        recTracerStart(scene: Scene.CalEventDetail, event: .shareEvent, page: calendarEventDetail)
    }

    public func recEndDelTransf() {
        recTracerEnd(scene: Scene.CalEventDetail, event: .shareEvent, page: calendarEventDetail)
    }

    // 日程详情页-删除日程
    public func recStartDelEvent() {
        recTracerStart(scene: Scene.CalEventDetail, event: .deleteEvent, page: calendarEventDetail)
    }

    public func recEndDelEvent() {
        recTracerEnd(scene: Scene.CalEventDetail, event: .deleteEvent, page: calendarEventDetail)
    }

    // 日程详情页-编辑日程
    public func recStartEditEvent() {
        recTracerStart(scene: Scene.CalEventEdit, event: .editEvent, page: calendarEventDetail)
    }

    public func recEndEditEvent() {
        recTracerEnd(scene: Scene.CalEventEdit, event: .editEvent, page: calendarEventDetail)
    }

    // 日程详情页-回复RSVP
    public func recStartDetailRSVP() {
        recTracerStart(scene: Scene.CalEventDetail, event: .replyRsvp, page: calendarEventDetail)
    }

    public func recEndDetailRSVP() {
        recTracerEnd(scene: Scene.CalEventDetail, event: .replyRsvp, page: calendarEventDetail)
    }

    // 日程详情页-进入/创建视频会议
    public func recStartJumpVideo() {
        recTracerStart(scene: Scene.CalEventDetail, event: .enterVideo, page: calendarEventDetail)
    }

    public func recEndJumpVideo() {
        recTracerEnd(scene: Scene.CalEventDetail, event: .enterVideo, page: calendarEventDetail)
    }

    // 日程详情页-进入/创建会议群
    public func recStartMeeting() {
        recTracerStart(scene: Scene.CalEventDetail, event: .enterMeeting, page: calendarEventDetail)
    }

    public func recEndMeeting() {
        recTracerEnd(scene: Scene.CalEventDetail, event: .enterMeeting, page: calendarEventDetail)
    }

    // 日程详情页-进入/创建会议纪要
    public func recStartToDoc() {
        recTracerStart(scene: Scene.CalEventDetail, event: .enterMinutes, page: calendarEventDetail)
    }

    public func recEndToDoc() {
        recTracerEnd(scene: Scene.CalEventDetail, event: .enterMinutes, page: calendarEventDetail)
    }

    // 日程详情页-查看参与者
    public func recStartCheckAttendee() {
        recTracerStart(scene: Scene.CalEventDetail, event: .checkAttendee, page: calendarEventDetail)
    }

    public func recEndCheckAttendee() {
        recTracerEnd(scene: Scene.CalEventDetail, event: .checkAttendee, page: calendarEventDetail)
    }

    // 创建日程-保存日程
    public func recStartSaveEvent() {
        recTracerStart(scene: Scene.CalEventEdit, event: .saveEvent, page: calendarEventCreate)
    }

    public func recEndSaveEvent() {
        recTracerEnd(scene: Scene.CalEventEdit, event: .saveEvent, page: calendarEventCreate)
    }

    public func recTracerStart(scene: Scene, event: Event, page: String) {
        let recKey = ReciableKey(scene: scene, event: event.rawValue, page: page)
        let val = AppReciableSDK.shared.start(biz: Biz.Calendar, scene: scene, event: event, page: page)
        keyMap[recKey] = val
    }

    public func recTracerEnd(scene: Scene, event: Event, page: String) {
        let recKey = ReciableKey(scene: scene, event: event.rawValue, page: page)
        guard let val = keyMap.removeValue(forKey: recKey) else {
            // 没有开始的直接返回
            return
        }
        AppReciableSDK.shared.end(key: val)
    }

    // Event枚举类型缺少"cal_click_tab"，适配过程中无法入参，只能保留之前的接口
    public func recTracerStart(scene: Scene, event: String, page: String) {
        let recKey = ReciableKey(scene: scene, event: event, page: page)
        let val = AppReciableSDK.shared.start(biz: Biz.Calendar, scene: scene, event: event, page: page)
        keyMap[recKey] = val
    }

    public func recTracerEnd(scene: Scene, event: String, page: String) {
        let recKey = ReciableKey(scene: scene, event: event, page: page)
        guard let val = keyMap.removeValue(forKey: recKey) else {
            // 没有开始的直接返回
            return
        }
        AppReciableSDK.shared.end(key: val)
    }

    public func recTracerError(errorType: ErrorType, scene: Scene, event: Event, userAction: String, page: String, errorCode: Int, errorMessage: String) {
        let error = ErrorParams(biz: Biz.Calendar,
                                scene: scene,
                                event: event,
                                errorType: errorType,
                                errorLevel: ErrorLevel.Fatal,
                                errorCode: errorCode,
                                userAction: userAction,
                                page: page,
                                errorMessage: errorMessage)
        AppReciableSDK.shared.error(params: error)
    }
}
struct ReciableKey: Hashable, Equatable {
    var scene: Scene
    var event: String
    var page: String

    public static func == (lhs: ReciableKey, rhs: ReciableKey) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(scene)
        hasher.combine(event)
        hasher.combine(page)
    }
}
