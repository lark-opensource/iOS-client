//
//  ScheduleCardModel.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/7.
//

import Foundation
import CalendarFoundation
import RustPB

class ScheduleCardModel: EventFeedCardModel {
    let baseModel: TodayEventBaseModel
    let detailModel: TodayEventDetailModel
    let sortTime: Int64
    let cardID: String
    let cardType: CalendarFoundation.EventFeedCardType = .event
    var remainingTime: Int64
    let duration: Int64
    let tag: String?
    let serverID: String
    let eventID: String
    let startTime: Int64
    let btnID: String?
    let btnModel: ScheduleCardBtnType

    init(baseModel: TodayEventBaseModel,
         detailModel: TodayEventDetailModel,
         sortTime: Int64,
         cardID: String,
         remainingTime: Int64,
         duration: Int64,
         tag: String?,
         serverID: String,
         eventID: String,
         startTime: Int64,
         btnID: String?,
         btnModel: ScheduleCardBtnType) {
        self.baseModel = baseModel
        self.detailModel = detailModel
        self.sortTime = sortTime
        self.cardID = cardID
        self.remainingTime = remainingTime
        self.duration = duration
        self.tag = tag
        self.serverID = serverID
        self.eventID = eventID
        self.startTime = startTime
        self.btnID = btnID
        self.btnModel = btnModel
    }
}

class EventFeedCardViewMananger {
    let cardView: EventFeedCardView

    init(cardView: EventFeedCardView) {
        self.cardView = cardView
    }
}
