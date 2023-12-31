//
//  TodoWidgetProvider.swift
//  Lark
//
//  Created by Hayden Wang on 2022/5/9.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents
import LarkWidget
import LarkLocalizations
import LarkExtensionServices

struct TodoWidgetProvider: TimelineProvider {

    typealias Entry = TodoEntry

    @UserDefaultEncoded(key: WidgetDataKeys.authInfo, default: .normalInfo(isFeishu: true))
    private var authInfo: WidgetAuthInfo

    @UserDefaultEncoded(key: WidgetDataKeys.todoData, default: .emptyData)
    private var todoWidgetData: TodoWidgetModel

    @UserDefaultEncoded(key: WidgetDataKeys.displayedTodoData, default: .emptyData)
    private var todoWidgetDataDisplayed: TodoWidgetModel

    func placeholder(in context: Context) -> TodoEntry {
        return TodoEntry(date: Date(),
                         authInfo: authInfo,
                         model: todoWidgetData)
    }

    func getSnapshot(in context: Context,
                     completion: @escaping (TodoEntry) -> Void) {
        let snapshotEntry = TodoEntry(date: Date(),
                                      authInfo: authInfo,
                                      model: todoWidgetData)
        completion(snapshotEntry)
    }

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<TodoEntry>) -> Void) {

        // 更新 Widget 中使用到的 host、language 等信息
        WidgetAuthInfo.updateEnvironmentVariables(with: authInfo)

        let todoWidgetData = todoWidgetData
        // 在最近一个任务完成时刷新 Widget
        var reloadPolicy: TimelineReloadPolicy = .after(.nextDay)
        if let nextTriggerTime = todoWidgetData.nearestTodoDate, nextTriggerTime < .nextDay {
            reloadPolicy = .after(nextTriggerTime.addingTimeInterval(1))
        }
        let timeline = Timeline(
            entries: [TodoEntry(date: Date(), authInfo: authInfo, model: todoWidgetData)],
            policy: reloadPolicy
        )
        completion(timeline)

        // 写入 displayedTodoData
        WidgetDataManager.setWidgetData(todoWidgetData, byKey: WidgetDataKeys.displayedTodoData)

        // 飞书任务 Widget 展示埋点
        ExtensionTracker.shared.trackTeaEvent(key: "public_widget_view", params: [
            "product_line": "todo",
            "size": context.family.trackName
        ])
    }
}

struct TodoEntry: TimelineEntry {
    let date: Date
    let authInfo: WidgetAuthInfo
    let model: TodoWidgetModel
}
