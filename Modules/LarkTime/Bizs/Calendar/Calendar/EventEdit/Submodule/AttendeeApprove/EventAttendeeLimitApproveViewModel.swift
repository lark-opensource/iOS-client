//
//  EventAttendeeLimitApproveViewModel.swift
//  Calendar
//
//  Created by huoyunjie on 2022/6/14.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa
import LarkTimeFormatUtils
import CalendarFoundation
import EventKit

class EventAttendeeLimitApproveViewModel: UserResolverWrapper {

    struct Approver: Avatar {
        var userName: String
        var avatarKey: String
        var identifier: String = ""
    }

    struct ViewData {
        var reason: String = ""
        var attendeeNumber: String = ""
        var summary: String?
        var time: String?
        var rrule: String?
        var approvers: [Approver] = []
    }

    enum DataStatus {
        case initial
        case failed
        case dataLoaded(ViewData)
    }

    let userResolver: UserResolver

    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?

    /// 参与者数量管控上限
    let underLimit = Int(SettingService.shared().tenantSetting?.attendeeNumberControlConfig.controlAttendeeMaxCount ?? 0)
    /// 参与者数量技术上限
    let upperLimit = Int(SettingService.shared().finalEventAttendeeLimit)

    private var event: CalendarEvent?
    private(set) var rxDataStatus: BehaviorRelay<DataStatus> = .init(value: .initial)
    private(set) var rxReasonViewData: BehaviorRelay<String> = .init(value: "")
    private(set) var rxAttendeeNumberViewData: BehaviorRelay<String> = .init(value: "")
    private let disposeBag = DisposeBag()

    var approveCommitSucceedHandler: (() -> Void)?
    var cancelCommitHandler: (() -> Void)?

    private let calendarId: String
    private let key: String
    private let originalTime: Int64

    init(userResolver: UserResolver, calendarId: String, key: String, originalTime: Int64) {
        self.userResolver = userResolver
        self.calendarId = calendarId
        self.key = key
        self.originalTime = originalTime
        self.initViewData()
    }

    private func initViewData() {
        guard let rustAPI = self.calendarApi else { return }
        rxDataStatus.accept(.initial)
        Observable.zip(rustAPI.getEventPB(calendarId: calendarId, key: key, originalTime: originalTime),
                       rustAPI.getAttendeeNumberControlApprovalInfo())
            .subscribe(onNext: { [weak self] (event, approvers) in
                guard let self = self else { return }
                self.event = event
                let viewData = ViewData(summary: self.summary,
                                        time: self.timeString,
                                        rrule: self.rruleString,
                                        approvers: approvers.values.map({ Approver(userName: $0.name, avatarKey: $0.avatar) }))
                self.rxDataStatus.accept(.dataLoaded(viewData))
            }, onError: { [weak self] _ in
                AttendeeLimitApprove.logError("init attendee number control data error")
                self?.rxDataStatus.accept(.failed)
            }).disposed(by: disposeBag)
    }

    func updateReason(_ reason: String) {
        rxReasonViewData.accept(reason)
    }

    func updateAttendeeNumber(_ number: String) {
        rxAttendeeNumberViewData.accept(number)
    }

    func retryLoad() {
        self.initViewData()
    }

    func commitApprove() -> Observable<Bool> {
        guard let event = event, let rustAPI = self.calendarApi else {
            assertionFailure("event is nil")
            return .just(false)
        }
        return rustAPI.createAttendeeNumberControlApproval(
            calendarID: event.calendarID,
            key: event.key,
            originalTime: event.originalTime,
            summary: event.summary,
            startTime: event.startTime,
            startTimeZone: event.startTimezone,
            endTime: event.endTime,
            endTimeZone: event.endTimezone,
            eventType: (event.rrule.isEmpty && event.originalTime == 0) ? .normal : .recurrence,
            attendeeNumber: Int32(self.rxAttendeeNumberViewData.value) ?? 0,
            reason: self.rxReasonViewData.value
        ).map { _ in true }
    }
}

extension EventAttendeeLimitApproveViewModel {
    // 日程标题
    var summary: String? {
        guard let summary = event?.summary else { return nil }
        return summary.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : event?.summary
    }

    // 日程时间
    var timeString: String? {
        guard let event = event else { return nil }
        let startDate = getDateFromInt64(event.startTime)
        let endDate = getDateFromInt64(event.endTime)
        let isAllDay = event.isAllDay
        let options = Options(timeZone: TimeZone.current,
                              is12HourStyle: calendarDependency?.is12HourStyle.value ?? true,
                              shouldShowGMT: true,
                              timeFormatType: .long,
                              timePrecisionType: .minute,
                              datePrecisionType: .day,
                              dateStatusType: .absolute,
                              shouldRemoveTrailingZeros: false)
        return CalendarTimeFormatter.formatFullDateTimeRange(startFrom: startDate, endAt: endDate, isAllDayEvent: isAllDay, with: options)
    }

    // 重复性规则
    var rruleString: String? {
        if let event = event,
           !event.rrule.isEmpty || event.originalTime != 0 {
            // 重复性日程或例外日程
            return I18n.Calendar_Edit_Yes
        }
        return I18n.Calendar_Edit_No
    }

    // 参与人数量是否有效
    var attendeeNumberIsValid: Bool {
        let text = rxAttendeeNumberViewData.value
        if let number = Int(text),
           (self.underLimit...self.upperLimit).contains(number) {
            return true
        }
        return false
    }
}
