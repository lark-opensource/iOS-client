//
//  CalendarPreloadTask.swift
//  Calendar
//
//  Created by JackZhao on 2023/5/6.
//

import RxSwift
import Foundation
import LarkSetting
import LarkPreload
import BootManager
import LarkContainer
import LKCommonsLogging

final class CalendarPreloadTask: UserFlowBootTask, Identifiable {
    private static let logger = LKCommonsLogging.Logger.log(CalendarPreloadTask.self, category: "Calendar")

    enum PreloadScene: String {
        case calendar_resource_init = "calendar_resource_init"
    }
    static var identify = "CalendarPreloadTask"
    @ScopedInjectedLazy var timeZoneService: TimeZoneService?
    @ScopedInjectedLazy var meetingRoomHomeTracer: MeetingRoomHomeTracer?
    @ScopedInjectedLazy var calendarSelectTracer: CalendarSelectTracer?
    static var dayTimeZoneView: DayTimeZoneView? = DayTimeZoneView()
    static var dayAdditionalTimeZoneView: DayTimeZoneView? = DayTimeZoneView(isShowIcon: false)

    override var scope: Set<BizScope> { return [.calendar] }

    override func execute(_ context: BootContext) {
        let start = CACurrentMediaTime()
        PreloadMananger.shared.addTask(preloadName: PreloadScene.calendar_resource_init.rawValue,
                                       biz: .Calendar,
                                       preloadType: .OtherType,
                                       hasFeedback: false,
                                       taskAction: { [weak self] in
            Self.logger.info("\(Self.identify) excuted success, cost = \(CACurrentMediaTime() - start) from login")
            // preload bundle init
            _ = BundleI18n.Calendar.Calendar_Setting_LocalCalendars
            // preload timeZoneService init
            _ = self?.timeZoneService
            // preload meetingRoomHomeTracer init
            _ = self?.meetingRoomHomeTracer
            // preload calendarSelectTracer init
            _ = self?.calendarSelectTracer
            // preload eventStoreCalendars，节省日历冷启动耗时
            _ = LocalCalendarManager.eventStoreCalendars
            // preload schedulers，低端机耗时16ms
            _ = InstanceServiceCache.schedulers()
            // preload dayTimeZoneView, 低端机耗时15+ms
            DispatchQueue.main.async {
                _ = Self.dayTimeZoneView
                _ = Self.dayAdditionalTimeZoneView
            }
        },
                                       stateCallBack: nil,
                                       moment: .runloopIdle,
                                       lowDeviceEnable: true)
    }
}

public struct InstanceServiceCache {
    public static let schedulers = {
        return (
            requestApi: ConcurrentDispatchQueueScheduler(qos: .default),
            accessData: SerialDispatchQueueScheduler(queue: accessDataQueue, internalSerialQueueName: accessDataQueue.label),
            updateNoti: MainScheduler.asyncInstance
        )
    }
    public static let accessDataQueue = DispatchQueue(label: "lark.calendar.instance.service.accessData")
}
