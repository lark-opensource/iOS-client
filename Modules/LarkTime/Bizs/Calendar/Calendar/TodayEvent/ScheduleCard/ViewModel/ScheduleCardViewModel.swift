//
//  ScheduleCardViewModel.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/18.
//

import LarkContainer

class ScheduleCardViewModel {
    let model: ScheduleCardModel
    let todayEventDependency: TodayEventDependency

    init(model: ScheduleCardModel,
         todayEventDependency: TodayEventDependency) {
        self.model = model
        self.todayEventDependency = todayEventDependency
    }
}
