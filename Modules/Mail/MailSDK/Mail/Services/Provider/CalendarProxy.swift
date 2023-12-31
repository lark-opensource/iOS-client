//
//  CalendarProxy.swift
//  MailSDK
//
//  Created by majx on 2019/9/25.
//

import Foundation


public protocol CalendarProxy {
    func showCalendarEventDetail(eventKey: String, calendarId: String, originalTime: Int64, from controller: UIViewController)
    func formattCalenderTime(startTime: Int64, endTime: Int64, isAllDay: Bool, is12HourStyle: Bool) -> String?
    func formattCalenderWeekday(date: Date) -> String?
    func formattCalenderDate(date: Date) -> String?
    func showCalendarEditorVC(originEventModel: CalendarEventModel?,
                              title: String,
                              vc: UIViewController,
                              callBack: @escaping CalendarEventResult)
}
