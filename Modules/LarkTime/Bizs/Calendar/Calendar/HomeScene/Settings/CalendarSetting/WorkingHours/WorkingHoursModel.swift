//
//  WorkingHoursModel.swift
//  Calendar
//
//  Created by zhouyuan on 2019/5/17.
//

import Foundation
import CalendarFoundation
import RustPB

struct WorkingHoursModel {
    private var workHourSetting: SettingModel.WorkHourSetting
    let firstWeekday: DaysOfWeek
    var settingChanged: ((SettingModel.WorkHourSetting) -> Void)?
    var is12HourStyle: Bool
    init(firstWeekday: DaysOfWeek, is12HourStyle: Bool, workHourSetting: SettingModel.WorkHourSetting) {
        self.workHourSetting = workHourSetting
        self.firstWeekday = firstWeekday
        self.is12HourStyle = is12HourStyle
    }

    func enableWorkHour() -> Bool {
        return workHourSetting.enableWorkHour
    }

    mutating func changeEnableWorkHour(_ enableWorkHour: Bool) {
        workHourSetting.enableWorkHour = enableWorkHour
        if workHourSetting.isFirstSet && enableWorkHour {
            workHourSetting.workHourItems = getDefaultworkHourItems()
        }
        workHourSetting.isFirstSet = false
        settingChanged?(workHourSetting)
    }

    func getSetWorkingHoursViewContent() -> SetWorkingHoursViewContent {
        var workHourItems = [DaysOfWeek: SettingModel.WorkHourSpan]()
        workHourSetting.workHourItems.forEach { (pbWeekDayValue, workHourItem) in
            if let rawValue = Int(pbWeekDayValue),
                let dayOfWeek = RustPB.Calendar_V1_DayOfWeek(rawValue: rawValue),
                !workHourItem.spans.isEmpty {
                workHourItems[DaysOfWeek.fromPB(pb: dayOfWeek)] = workHourItem.spans.first!
            }
        }
        return SetWorkingHoursViewModel(workHourItems: workHourItems)
    }

    mutating func resetWorkHourSetting(_ workHourSetting: SettingModel.WorkHourSetting) {
        self.workHourSetting = workHourSetting
    }

    mutating func deleteWorkHourItem(daysOfWeek: DaysOfWeek) {
        let pbWeekDayValue = "\(daysOfWeek.toPb().rawValue)"
        workHourSetting.workHourItems.removeValue(forKey: pbWeekDayValue)
        settingChanged?(workHourSetting)
    }

    mutating func changeIs12HourStyle(is12HourStyle: Bool) {
        self.is12HourStyle = is12HourStyle
    }

    mutating func addWorkHourItem(daysOfWeek: DaysOfWeek) {
        let pbWeekDayValue = "\(daysOfWeek.toPb().rawValue)"
        workHourSetting.workHourItems[pbWeekDayValue] = getNewWorkHourItem()
        settingChanged?(workHourSetting)
    }

    mutating func updateWorkHourItem(daysOfWeek: DaysOfWeek,
                                     startMinute: Int32, endMinute: Int32) {
        let pbWeekDayValue = "\(daysOfWeek.toPb().rawValue)"
        workHourSetting.workHourItems[pbWeekDayValue]
            = getNewWorkHourItem(startMinute: startMinute, endMinute: endMinute)
        settingChanged?(workHourSetting)
    }

    mutating func resetAllWorkItem(startMinute: Int32, endMinute: Int32) {
        let allKeys = workHourSetting.workHourItems.keys
        allKeys.forEach { (key) in
            workHourSetting.workHourItems[key]
                = getNewWorkHourItem(startMinute: startMinute, endMinute: endMinute)
        }
        settingChanged?(workHourSetting)
    }

    /// 第一次设置  默认 周一到周五 朝九晚五
    private func getDefaultworkHourItems() -> [String: WorkHourItem] {
        var weekday = DaysOfWeek.monday
        var workHourItems: [String: WorkHourItem] = [:]
        (0..<5).forEach { (_) in
            let pbWeekDayValue = "\(weekday.toPb().rawValue)"
            workHourItems[pbWeekDayValue] = getNewWorkHourItem()
            weekday = weekday.next()
        }
        return workHourItems
    }

    private func getNewWorkHourItem(startMinute: Int32? = nil,
                                    endMinute: Int32? = nil) -> WorkHourItem {
        var span = WorkHourSpan()
        span.startMinute = startMinute ?? 540 // 默认 9:00 - 17:00
        span.endMinute = endMinute ?? 1020
        var workHourItem = WorkHourItem()
        workHourItem.spans = [span]
        return workHourItem
    }
}

struct SetWorkingHoursViewModel: SetWorkingHoursViewContent {
    var workHourItems: [DaysOfWeek: SettingModel.WorkHourSpan]
}
