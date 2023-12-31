//
//  TodayEventDependency.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/11.
//

public protocol TodayEventDependency {
    /// 创建button
    func createEventCardVCButton(_ info: ScheduleCardButtonModel) -> UIButton

    /// 移除button
    func removeVCBtn(uniqueId: String)

    /// 更新新Button状态
    func updateButtonStatus(_ info: ScheduleCardButtonModel)

    /// 移除全部button
    func removeAllVCBtn()
}
