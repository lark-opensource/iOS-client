//
//  TodoTexts.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/5/13.
//

import Foundation
import LarkLocalizations
import LarkTimeFormatUtils

public enum TodoTexts {

    private static var language: Lang { WidgetI18n.language }

    static var textNoTasks: String {
        BundleI18n.LarkWidget.Lark_TasksWidget_TaskCenter_NoTasks(lang: language)
    }

    static var textShortTitle: String {
        BundleI18n.LarkWidget.Lark_TasksWidget_Ongoing_Title(lang: language)
    }

    static var textLongTitle: String {
        BundleI18n.LarkWidget.Lark_TasksWidget_OngoingTasks_Title(lang: language)
    }

    static func textShortFormattedDueTime(_ todo: TodoItem) -> String {
        // https://bytedance.feishu.cn/wiki/wikcncomscp8CYMBjCfFG3HVIMf
        guard let date = todo.dueDate else { return "" }
        if todo.isAllDay || !date.isToday {
            let option = Options(
                datePrecisionType: .day,
                dateStatusType: .relative,
                lang: language
            )
            return TimeFormatUtils.formatDate(from: date, with: option)
        } else {
            let option = Options(
                is12HourStyle: false,
                timePrecisionType: .minute,
                lang: language
            )
            return TimeFormatUtils.formatTime(from: date, with: option)
        }
    }

    static func textLongFormattedDueTime(_ todo: TodoItem, is24Hour: Bool) -> String {
        // https://bytedance.feishu.cn/wiki/wikcncomscp8CYMBjCfFG3HVIMf
        // 和新版任务中心保持格式统一
        guard let date = todo.dueDate else { return "" }
        let timeString: String
        if todo.isAllDay {
            var options = TimeFormatUtils.defaultOptions
            options.is12HourStyle = !is24Hour
            options.dateStatusType = .relative
            timeString = TimeFormatUtils.formatDate(from: date, with: options)
        } else {
            var options = TimeFormatUtils.defaultOptions
            options.is12HourStyle = !is24Hour
            options.timePrecisionType = .minute
            options.dateStatusType = .relative
            options.timeFormatType = .long
            timeString = TimeFormatUtils.formatDateTime(from: date, with: options)
        }
        return BundleI18n.LarkWidget.Todo_Task_TimeDue(timeString, lang: language)
    }
}
