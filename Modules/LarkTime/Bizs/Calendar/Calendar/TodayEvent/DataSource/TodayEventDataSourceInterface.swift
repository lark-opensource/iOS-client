//
//  TodayEventDataSourceInterface.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/7.
//
import RxSwift

enum TodayEventDataState {
    /// 正在拉取
    case loading
    /// 拉取完成
    case done
}

struct TodayEventData {
    let instances: [CalendarEventInstance]
    let todayFeedEvents: [String: TodayFeedViewEvent]
}

protocol TodayEventDataSourceInterface {
    var todayPlanObservable: Observable<TodayEventData> { get }
    var scheduleCardObservable: Observable<TodayEventData> { get }

    func getData()
}
