//
//  TodayPlanModel.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/2.
//

import Foundation
import RustPB

class TodayPlanModel {
    typealias CalendarType = RustPB.Calendar_V1_CalendarEvent.Source

    let baseModel: TodayEventBaseModel
    let detailModel: TodayEventDetailModel
    let startTime: NSAttributedString
    let calendarType: CalendarType
    let needShowTime: Bool

    init(baseModel: TodayEventBaseModel,
         detailModel: TodayEventDetailModel,
         startTime: NSAttributedString,
         calendarType: CalendarType,
         needShowTime: Bool) {
        self.baseModel = baseModel
        self.detailModel = detailModel
        self.startTime = startTime
        self.calendarType = calendarType
        self.needShowTime = needShowTime
    }
}
