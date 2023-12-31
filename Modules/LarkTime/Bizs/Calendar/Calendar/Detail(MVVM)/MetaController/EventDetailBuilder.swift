//
//  EventDetailBuilder.swift
//  Calendar
//
//  Created by Rico on 2021/3/15.
//

import Foundation
import EventKit
import UIKit
import LarkContainer

// 一些可选项，都是Bool值，可用于埋点、配置等
struct EventDetailOptions: OptionSet, CustomDebugStringConvertible, CustomStringConvertible {

    let rawValue: Int

    // 是否从RSVP进入
    static let isFromRSVP = EventDetailOptions(rawValue: 1 << 0)

    // 是否从VC进入
    static let isFromVideoMeeting = EventDetailOptions(rawValue: 1 << 1)

    // 是否从chat进入
    static let isFromChat = EventDetailOptions(rawValue: 1 << 2)

    // 是否需要isForReview逻辑
    static let needCalculateIsForReview = EventDetailOptions(rawValue: 1 << 3)

    var description: String {
        return """
            isFromRSVP: \(contains(.isFromRSVP)),
            isFromVideoMeeting: \(contains(.isFromVideoMeeting)),
            isFromChat: \(contains(.isFromChat)),
            needCalculateIsForReview: \(contains(.needCalculateIsForReview)),
            """
    }

    var debugDescription: String {
        return description
    }
}

/// 日程详情页入口
/// 作用：1.根据入口判断冲突视图是否展示
public enum EventDetailScene: String {
    /// 日历tab内部场景（未进行细分，后续有细分需求可扩增）
    case calendarView
    /// 会议群
    case chat
    /// VC
    case vc
    /// 大搜
    case search
    /// 邀请卡片
    case inviteCard
    /// 分享卡片
    case shareCard
    /// 转让卡片
    case transferCard
    /// RSVP 卡片
    case rsvpCard
    /// Feed 事件提醒
    case calendarFeedCard
    /// URL 链接：日程链接进入详情页的场景有很多，直接点击裸链、mail里查看日程等，
    /// 用户层表现可能不是直接点击url，但底层实际是通过url进入的详情页。
    /// 当对具体的业务场景没有进行定义时，默认为 url 入口（例如mail里查看），
    /// 有对业务场景进行定义时，使用具体业务场景（例如 vc)
    case url
    /// 在线提醒
    case reminder
    /// 离线通知
    case offlineNotification
}

struct EventDetailBuilder {

    let options: EventDetailOptions
    let scene: EventDetailScene

    init(options: EventDetailOptions, scene: EventDetailScene) {
        self.options = options
        self.scene = scene
    }

    static func prepare(options: EventDetailOptions = [], scene: EventDetailScene = .calendarView) -> EventDetailBuilder {
        EventDetailBuilder(options: options, scene: scene)
    }

    /// 通过本地日程打开详情页
    /// - Parameter ekEvent: 本地日历对象
    /// - Returns: 详情页ViewController
    static func build(userResolver: UserResolver, ekEvent: EKEvent) -> UIViewController {
        prepare().build(userResolver: userResolver, ekEvent: ekEvent)
    }

    /// 通过本地日程打开详情页
    /// - Parameter ekEvent: 本地日历对象
    /// - Returns: 详情页ViewController
    func build(userResolver: UserResolver, ekEvent: EKEvent) -> UIViewController {
        let reformer = EventDetailLocalDataReformer(ekEvent: ekEvent, scene: scene)
        let detailVC = detailViewController(userResolver: userResolver, from: reformer)
        return detailVC
    }

    /// 通过ChatId打开详情页
    /// - Parameter chatId: chatId
    /// - Returns: 详情页ViewController
    static func build(userResolver: UserResolver, chatId: String) -> UIViewController {
        prepare(scene: .chat).build(userResolver: userResolver, chatId: chatId)
    }

    /// 通过ChatId打开详情页
    /// - Parameter chatId: chatId
    /// - Returns: 详情页ViewController
    func build(userResolver: UserResolver,
               chatId: String) -> UIViewController {
        let reformer = EventDetailChatDataReformer(chatId: chatId, userResolver: userResolver, scene: scene)
        let detailVC = detailViewController(userResolver: userResolver,
                                            from: reformer,
                                            additionalOptions: [.isFromChat])
        return detailVC
    }

    /// 通过日程关键参数打开详情页
    /// - Parameters:
    ///   - key: key
    ///   - calendarId: 所属日历ID
    ///   - originalTime: originalTime
    /// - Returns: 详情页ViewController
    static func build(userResolver: UserResolver,
                      key: String,
                      calendarId: String,
                      originalTime: Int64,
                      startTime: Int64? = nil,
                      endTime: Int64? = nil,
                      actionSource: CalendarTracer.ActionSource,
                      scene: EventDetailScene) -> UIViewController {
        prepare(scene: scene)
            .build(userResolver: userResolver,
                   key: key,
                   calendarId: calendarId,
                   originalTime: originalTime,
                   startTime: startTime,
                   endTime: endTime,
                   actionSource: actionSource
            )
    }

    /// 通过日程关键参数打开详情页
    /// - Parameters:
    ///   - key: key
    ///   - calendarId: 所属日历ID
    ///   - originalTime: originalTime
    /// - Returns: 详情页ViewController
    func build(userResolver: UserResolver,
               key: String,
               calendarId: String,
               originalTime: Int64,
               startTime: Int64? = nil,
               endTime: Int64? = nil,
               actionSource: CalendarTracer.ActionSource) -> UIViewController {
        let reformer = EventDetailDataReformer(userResolver: userResolver,
                                               key: key,
                                               calendarId: calendarId,
                                               originalTime: originalTime,
                                               startTime: startTime,
                                               endTime: endTime,
                                               actionSource: actionSource,
                                               scene: scene)
        let detailVC = detailViewController(userResolver: userResolver, from: reformer)
        return detailVC
    }

    /// 通过会议室视图Instance打开详情页（无权限日程）
    /// - Parameter roomInstance: 会议室视图日程Instance
    /// - Returns: 详情页ViewController
    static func build(userResolver: UserResolver, roomInstance: RoomViewInstance) -> UIViewController {
        prepare().build(userResolver: userResolver, roomInstance: roomInstance)
    }

    /// 通过会议室视图Instance打开详情页（无权限日程）
    /// - Parameter roomInstance: 会议室视图日程Instance
    /// - Returns: 详情页ViewController
    func build(userResolver: UserResolver, roomInstance: RoomViewInstance) -> UIViewController {
        let reformer = EventDetailMeetingRoomLimitDataReformer(roomInstance: roomInstance, userResolver: userResolver, scene: scene)
        let detailVC = detailViewController(userResolver: userResolver, from: reformer)
        return detailVC
    }

    /// 通过RSVP卡片入口进入
    /// - Parameters:
    ///   - rsvpEvent: 日程数据
    ///   - rsvpString: rsvp文本
    /// - Returns: 详情页ViewController
    static func build(userResolver: UserResolver,
                      rsvpEvent: EventDetail.Event,
                      rsvpString: String) -> UIViewController {
        prepare(scene: .rsvpCard)
            .build(userResolver: userResolver, rsvpEvent: rsvpEvent, rsvpString: rsvpString)
    }

    /// 通过RSVP卡片入口进入
    /// - Parameters:
    ///   - rsvpEvent: 日程数据
    ///   - rsvpString: rsvp文本
    /// - Returns: 详情页ViewController
    func build(userResolver: UserResolver,
               rsvpEvent: EventDetail.Event,
               rsvpString: String) -> UIViewController {
        let reformer = EventDetailRSVPCommentDataReformer(
            event: rsvpEvent,
            rsvpString: rsvpString,
            userResolver: userResolver,
            scene: scene
        )
        let detailVC = detailViewController(userResolver: userResolver, from: reformer,
                                            additionalOptions: [.needCalculateIsForReview,
                                                                .isFromRSVP])
        return detailVC
    }

    /// 通过VC UniqueID打开
    /// - Parameters:
    ///   - uniqueId: UniqueID
    ///   - startTime: startTime
    /// - Returns: 详情页ViewController
    static func build(userResolver: UserResolver,
                      uniqueId: String,
                      startTime: Int64,
                      instance_start_time: Int64,
                      instance_end_time: Int64,
                      original_time: Int64,
                      vchat_meeting_id: String,
                      key: String) -> UIViewController {
        prepare(scene: .vc)
            .build(userResolver: userResolver,
                   uniqueId: uniqueId,
                   startTime: startTime,
                   instance_start_time: instance_start_time,
                   instance_end_time: instance_end_time,
                   original_time: original_time,
                   vchat_meeting_id: vchat_meeting_id,
                   key: key)
    }

    /// 通过VC UniqueID打开
    /// - Parameters:
    ///   - uniqueId: UniqueID
    ///   - startTime: startTime
    /// - Returns: 详情页ViewController
    func build(userResolver: UserResolver,
               uniqueId: String,
               startTime: Int64,
               instance_start_time: Int64,
               instance_end_time: Int64,
               original_time: Int64,
               vchat_meeting_id: String,
               key: String) -> UIViewController {
        let reformer = EventDetailVideoMeetingDataReformer(userResolver: userResolver,
                                                           uniqueId: uniqueId,
                                                           startTime: startTime,
                                                           instance_start_time: instance_start_time,
                                                           instance_end_time: instance_end_time,
                                                           original_time: original_time,
                                                           vchat_meeting_id: vchat_meeting_id,
                                                           key: key, scene: scene)
        let detailVC = detailViewController(userResolver: userResolver,
                                            from: reformer,
                                            additionalOptions: [.needCalculateIsForReview,
                                                                .isFromVideoMeeting,
                                                                .isFromChat])
        return detailVC
    }

    /// Share途径打开详情页
    /// - Parameters:
    ///   - key: key
    ///   - calendarID: calendarID
    ///   - originalTime: originalTime
    ///   - token: 分享Token
    ///   - messageId: messageID
    /// - Returns: 详情页ViewController
    static func build(userResolver: UserResolver,
                      key: String,
                      calendarID: String,
                      originalTime: Int64,
                      token: String?,
                      messageId: String,
                      isFromAPNS: Bool,
                      scene: EventDetailScene) -> UIViewController {
        prepare(scene: scene)
            .build(userResolver: userResolver,
                   key: key,
                   calendarID: calendarID,
                   originalTime: originalTime,
                   token: token,
                   messageId: messageId,
                   isFromAPNS: isFromAPNS)
    }

    /// Share途径打开详情页
    /// - Parameters:
    ///   - key: key
    ///   - calendarID: calendarID
    ///   - originalTime: originalTime
    ///   - token: 分享Token
    ///   - messageId: messageID
    /// - Returns: 详情页ViewController
    func build(userResolver: UserResolver,
               key: String,
               calendarID: String,
               originalTime: Int64,
               token: String?,
               messageId: String,
               isFromAPNS: Bool) -> UIViewController {
        let reformer = EventDetailShareDataReformer(
            userResolver: userResolver,
            key: key,
            calendarId: calendarID,
            originalTime: originalTime,
            token: token,
            messageId: messageId,
            actionSource: isFromAPNS ? CalendarTracer.ActionSource.off_line : CalendarTracer.ActionSource.msg_share,
            scene: scene
        )
        let detailVC = detailViewController(userResolver: userResolver,
                                            from: reformer,
                                            additionalOptions: [.needCalculateIsForReview])
        return detailVC
    }

    /// 分享卡片进入，不需要鉴权
    /// - Parameters:
    ///   - key: key
    ///   - calendarID: calendarID
    ///   - originalTime: originalTime
    ///   - startTime: startTime
    /// - Returns: 详情页ViewController
    static func buildByFourFoldTuplesWith(userResolver: UserResolver,
                                          key: String,
                                          calendarID: String,
                                          originalTime: Int64,
                                          startTime: Int64?,
                                          source: String? = nil,
                                          isFromAPNS: Bool,
                                          scene: EventDetailScene) -> UIViewController {
        prepare(scene: scene)
            .buildByFourFoldTuplesWith(userResolver: userResolver,
                                       key: key,
                                       calendarID: calendarID,
                                       originalTime: originalTime,
                                       startTime: startTime,
                                       source: source,
                                       isFromAPNS: isFromAPNS)
    }

    /// 分享卡片进入，不需要鉴权
    /// - Parameters:
    ///   - key: key
    ///   - calendarID: calendarID
    ///   - originalTime: originalTime
    ///   - startTime: startTime
    /// - Returns: 详情页ViewController
    func buildByFourFoldTuplesWith(userResolver: UserResolver,
                                   key: String,
                                   calendarID: String,
                                   originalTime: Int64,
                                   startTime: Int64?,
                                   source: String? = nil,
                                   isFromAPNS: Bool) -> UIViewController {
        let reformer = EventDetailFourFoldTuplesDataReformer(userResolver: userResolver,
                                                             key: key,
                                                             calendarId: calendarID,
                                                             originalTime: originalTime,
                                                             startTime: startTime,
                                                             source: source,
                                                             actionSource: isFromAPNS ? CalendarTracer.ActionSource.msg_share : CalendarTracer.ActionSource.off_line, scene: scene)

        let detailVC = detailViewController(userResolver: userResolver,
                                            from: reformer,
                                            additionalOptions: [])
        return detailVC
    }

}

extension EventDetailBuilder {
    private func detailViewController(userResolver: UserResolver,
                                      from reformer: EventDetailViewModelDataReformer,
                                      additionalOptions: EventDetailOptions = []) -> UIViewController {
        let viewModel = EventDetailMetaViewModel(reformer: reformer,
                                                 options: options.union(additionalOptions),
                                                 userResolver: userResolver)
        let viewController = EventDetailMetaViewController(viewModel: viewModel)

        EventDetail.logInfo("""
            EventDetailBuilder:
            scene: \(scene.rawValue)
            reformer:
            \(reformer.description)
            options:
            \(options.description)
            """)
        return viewController
    }
}
