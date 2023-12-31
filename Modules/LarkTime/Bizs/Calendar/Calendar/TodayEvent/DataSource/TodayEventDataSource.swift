//
//  TodayEventDataSource.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/7.
//

import Foundation
import RxRelay
import RxSwift
import LarkContainer

class TodayEventDataSource: TodayEventDataSourceInterface, UserResolverWrapper {
    private struct TodayEventDataSourceLogInfo: Codable {
        var eventID: String
        var serverID: String
        var startTime: Int64
        var endTime: Int64
        var remainTime: Int64
        var isAllDay: Bool
        var videoMeetingType: Int

        func description() -> String {
            return "{" + "eventID: \(eventID), "
            + "serverID: \(serverID), "
            + "startTime: \(startTime), "
            + "endTime: \(endTime), "
            + "remainTime: \(remainTime), "
            + "isAllDay: \(isAllDay), "
            + "videoMeetingType: \(videoMeetingType), "
            + "}"
        }
    }
    @ScopedInjectedLazy private var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy private var rustPushService: RustPushService?

    private let queue = DispatchQueue(label: "TodayEventDataSource.serialQueue", qos: .default)
    private lazy var queueScheduler: SchedulerType = SerialDispatchQueueScheduler(queue: queue, internalSerialQueueName: queue.label)

    let userResolver: UserResolver
    private let todayPlanSubject = PublishSubject<TodayEventData>()
    private let scheduleCardSubject = PublishSubject<TodayEventData>()
    private let disposeBag = DisposeBag()

    var todayPlanObservable: Observable<TodayEventData> {
        return todayPlanSubject.asObservable()
    }
    var scheduleCardObservable: Observable<TodayEventData> {
        return scheduleCardSubject.asObservable()
    }

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        listenPush()
    }

    // 在todayPlanObservable和scheduleCardObservable被监听后进行调用
    func getData() {
        calendarApi?.getTodayReminderCalendarInstance()
            .observeOn(queueScheduler)
            .subscribe(onNext: { [weak self] instanceResponse in
                guard let self = self else { return }
                TodayEvent.logInfo("getTodayReminderCalendarInstance instanceCount: \(instanceResponse.instances.count), " +
                                   "eventsCount: \(instanceResponse.todayFeedViewEvents.count)")
                self.dealWithData(instances: instanceResponse.instances, todayFeedEvents: instanceResponse.todayFeedViewEvents)
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.todayPlanSubject.onError(error)
                self.scheduleCardSubject.onError(error)
            }).disposed(by: disposeBag)
    }

    private func dealWithData(instances: [CalendarEventInstance], todayFeedEvents: [String: TodayFeedViewEvent] ) {
        var todayPlanData: [CalendarEventInstance] = []
        var scheduleCard: [CalendarEventInstance] = []
        var logInfo: [TodayEventDataSourceLogInfo] = []
        for instance in instances {
            // 距当前时间十分钟以上的展示在今日安排中，十分钟以内的展示在卡片中
            logInfo.append(TodayEventDataSourceLogInfo(eventID: instance.eventID,
                                                       serverID: instance.eventServerID,
                                                       startTime: instance.startTime,
                                                       endTime: instance.endTime,
                                                       remainTime: instance.startTime - Int64(Date().timeIntervalSince1970),
                                                       isAllDay: instance.isAllDay,
                                                       videoMeetingType: todayFeedEvents[instance.eventID]?.videoMeeting.videoMeetingType.rawValue ?? -1))
            if instance.startTime - Int64(Date().timeIntervalSince1970) > 60 * 10
                || TodayEventUtils.isAllday(instance: instance)
                || !TodayEventUtils.isIn24Hours(startTime: instance.startTime, endTime: instance.endTime) {
                todayPlanData.append(instance)
            } else {
                scheduleCard.append(instance)
            }
        }
        TodayEvent.logInfo("TodayEventData: \(logInfo.map({ $0.description() })), "
                           + "todayPlanDataCount: \(todayPlanData.count), "
                           + "scheduleCardCount: \(scheduleCard.count)")
        todayPlanSubject.onNext(TodayEventData(instances: todayPlanData, todayFeedEvents: todayFeedEvents))
        scheduleCardSubject.onNext(TodayEventData(instances: scheduleCard, todayFeedEvents: todayFeedEvents))
    }

    private func listenPush() {
        rustPushService?.rxTodayInstanceChanged
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                TodayEvent.logInfo("sdk push data")
                self.getData()
            }).disposed(by: disposeBag)
    }
}
