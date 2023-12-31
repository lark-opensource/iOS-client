//
//  TodayEventModel.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/17.
//

struct TodayEventBaseModel {
    let summary: String
    let rangeTime: String
    let location: String
}

struct TodayEventDetailModel {
    let key: String
    let calendarID: String
    let originalTime: Int64
    let startTime: Int64
}
