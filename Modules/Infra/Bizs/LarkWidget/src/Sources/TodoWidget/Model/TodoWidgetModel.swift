//
//  TodoWidgetModel.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/5/9.
//

import Foundation

public struct TodoWidgetModel: Codable, Equatable {

    public var items: [TodoItem]
    public var totalCount: Int
    public var todoNewLink: String
    public var todoTabLink: String
    public var is24Hour: Bool

    public init(items: [TodoItem],
                totalCount: Int,
                todoNewLink: String,
                todoTabLink: String,
                is24Hour: Bool) {
        self.items = items
        self.totalCount = totalCount
        self.todoNewLink = todoNewLink
        self.todoTabLink = todoTabLink
        self.is24Hour = is24Hour
    }

    /// 最近的一个未过期日程的过期时间（此时应该触发 Widget 的刷新，提示该日程已过期）
    public var nearestTodoDate: Date? {
        var now = Date()
        return items.compactMap({ $0.dueDate })
                    .filter({ $0 > now })
                    .sorted(by: <)
                    .first
    }
}

extension TodoWidgetModel {

    public static var emptyData: TodoWidgetModel {
        return TodoWidgetModel(
            items: [],
            totalCount: 0,
            todoNewLink: WidgetLink.newTask,
            todoTabLink: WidgetLink.todoTab,
            is24Hour: true
        )
    }
}
