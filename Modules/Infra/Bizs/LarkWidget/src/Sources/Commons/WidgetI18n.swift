//
//  WidgetI18n.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/5/16.
//

import Foundation
import LarkLocalizations
import LarkTimeFormatUtils

public enum WidgetI18n {

    @UserDefaultEncoded(key: WidgetDataKeys.authInfo, default: .normalInfo(isFeishu: true))
    private static var authInfo: WidgetAuthInfo

    public static var language: Lang = {
        return Lang(rawValue: authInfo.appLanguage)
    }()
}

extension WidgetI18n {

    public static var todoWidgetTitle: String {
        BundleI18n.LarkWidget.Lark_TasksWidget_TaskCenter_Name(lang: language)
    }

    public static var todoWidgetDescription: String {
        BundleI18n.LarkWidget.Lark_TasksWidget_TaskCenter_QuickAccess_Desc(lang: language)
    }

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
        /* 设计稿和 PRD 不一致，按要求先改成设计稿的样式
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
         */
        let option = Options(
            datePrecisionType: .day,
            dateStatusType: .relative,
            lang: language
        )
        return TimeFormatUtils.formatDate(from: date, with: option)
    }

    static func textLongFormattedDueTime(_ todo: TodoItem, is24Hour: Bool) -> String {
        // https://bytedance.feishu.cn/wiki/wikcncomscp8CYMBjCfFG3HVIMf
        guard let date = todo.dueDate else { return "" }
        let option = Options(
            is12HourStyle: !is24Hour,
            timeFormatType: .long,
            timePrecisionType: .minute,
            datePrecisionType: .day,
            dateStatusType: .relative,
            shouldRemoveTrailingZeros: false,
            lang: language
        )
        let timeString: String
        if todo.isAllDay {
            timeString = TimeFormatUtils.formatFullDate(from: date, with: option)
        } else {
            timeString = TimeFormatUtils.formatFullDateTime(from: date, with: option)
        }
        return BundleI18n.LarkWidget.Todo_Task_TimeDue(timeString, lang: language)
    }
}
