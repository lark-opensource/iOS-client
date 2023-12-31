//
//  CalendarSubscribeTracer.swift
//  Calendar
//
//  Created by ByteDance on 2023/7/21.
//

import UIKit
import Foundation
import ThreadSafeDataStructure
import LKCommonsLogging

class CalendarSubscribeTracer {
    struct TracerParam {
        var calendarID: String
        var subscribeTime: CFTimeInterval // 订阅的时间
    }
    
    private let tracerID = "cal_calendar_latency_dev"
    private var subscribeCalendars: SafeDictionary<String, TracerParam> = [:] + .readWriteLock
    private let logger = Logger.log(CalendarSubscribeTracer.self, category: "calendar.subscribe.tracer")

    func subscribeStart(calendarID: String) {
        subscribeCalendars[calendarID] = TracerParam(calendarID: calendarID,
                                                     subscribeTime: CACurrentMediaTime())
    }

    func loadingDone(calendarID: String) {
        if let param = subscribeCalendars[calendarID] {
            let viewTypeStr = CalendarTracer.ViewType(mode: CalendarDayViewSwitcher().mode).rawValue
            let cost = Int((CACurrentMediaTime() - param.subscribeTime) * 1000)
            CalendarTracer.shareInstance.writeEvent(
                eventId: tracerID,
                params: ["click": "sub_calendar_sidebar_loading",
                         "calendar_id": param.calendarID,
                         "cost_time": cost,
                         "view_type": viewTypeStr])

            logger.info("subscribe loading done calendarID \(calendarID) cost \(cost)")
            subscribeCalendars.removeValue(forKey: calendarID)
        }
    }

}
