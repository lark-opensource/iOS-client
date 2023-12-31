//
//  CalendarProvider.swift
//  LarkMail
//
//  Created by majx on 2019/9/25.
//

import Foundation
import MailSDK
import LarkModel
import LarkUIKit
import EENavigator
import LarkTimeFormatUtils
import Swinject
import UniverseDesignToast
import LarkContainer
#if CalendarMod
import CalendarFoundation
import Calendar
import UIKit
#endif

class CalendarProvider: CalendarProxy {
    private let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }
    // 打开日程详情
    func showCalendarEventDetail(eventKey: String, calendarId: String, originalTime: Int64, from controller: UIViewController) {
#if CalendarMod
        let body = CalendarEventDetailFromMail(eventKey: eventKey,
                                               calendarId: calendarId,
                                               originalTime: originalTime)
        resolver.navigator.push(body: body, from: controller)
#endif
    }
    // 从写信页进入日历边界页面

    func showCalendarEditorVC(originEventModel: CalendarEventModel?,
                              title: String,
                              vc: UIViewController,
                              callBack: @escaping CalendarEventResult) {
#if CalendarMod
        let legoInfo: EventEditLegoInfo = .none(adding: [.id(.datePicker),
                                                                          .id(.timeZone),
                                                                          .id(.location),
                                                                          .id(.videoMeeting),
                                                                          .id(.meetingRoom)])
        var editMode = EventEditMode.create
        if let originData = originEventModel,
            let adaptData = originData as? MailCalendarEvent {
            editMode = EventEditMode.edit(event: adaptData)
        }
        let interceptor = EventEditInterceptor.onlyResult(callBack: callBack)
        if let impl = try? resolver.resolve(assert: CalendarInterface.self) {
            let result = impl.getEventEditController(legoInfo: legoInfo,
                                                     editMode: editMode,
                                                     interceptor: interceptor,
                                                     title: title)

            switch result {
                case .success(let controller):
                    resolver.navigator.present(controller, from: vc)
                case .error(let error):
                    UDToast().showTips(with: error, on: vc.view)
            }
        }
#endif
    }

    func formattCalenderTime(startTime: Int64, endTime: Int64, isAllDay: Bool, is12HourStyle: Bool) -> String? {
        let startTime = Date(timeIntervalSince1970: TimeInterval(startTime))
        let endTime = Date(timeIntervalSince1970: TimeInterval(endTime))
        let customOptions = Options(
            timeZone: TimeZone.current,
            is12HourStyle: is12HourStyle,
            timePrecisionType: .minute,
            datePrecisionType: .day,
            dateStatusType: .absolute,
            shouldRemoveTrailingZeros: false)
#if CalendarMod
        return CalendarTimeFormatter.formatFullDateTimeRange(
            startFrom: startTime,
            endAt: endTime,
            isAllDayEvent: isAllDay,
            with: customOptions)
#else
        return nil
#endif
    }

    func formattCalenderWeekday(date: Date) -> String? {
        let customOptions = Options(
            timeZone: TimeZone.current,
            is12HourStyle: false,
            timeFormatType: .short,
            timePrecisionType: .minute,
            datePrecisionType: .day
        )
        let weekdayStr = TimeFormatUtils.formatWeekday(from: date, with: customOptions)
        return weekdayStr
    }

    func formattCalenderDate(date: Date) -> String? {
        let customOptions = Options(
            timeZone: TimeZone.current,
            is12HourStyle: false,
            timeFormatType: .long,
            timePrecisionType: .minute,
            datePrecisionType: .day
        )
        let dateStr = TimeFormatUtils.formatDate(from: date, with: customOptions)
        return dateStr
    }
}
