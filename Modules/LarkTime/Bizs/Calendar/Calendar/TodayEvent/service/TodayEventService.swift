//
//  TodayEventService.swift
//  Calendar
//
//  Created by chaishenghua on 2023/9/6.
//

protocol TodayEventService {
    /// 是否是12小时制
    var is12HourStyle: Bool { get }

    /// 跳转到详情
    func jumpToDetailPage(detailModel: TodayEventDetailModel, from vc: UIViewController)
}
