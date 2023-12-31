//
//  TodoItem.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/5/9.
//

import Foundation

public struct TodoItem: Codable, Equatable {

    var id: String

    /// 国际化处理过的名称
    var title: String

    /// Unix 标准时间戳，单位是 s
    var deadline: Int64?

    var isAllDay: Bool

    var hasPermission: Bool

    var appLink: String

    var dueDate: Date? {
        guard let deadline = deadline else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(deadline))
    }

    var isExpired: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date()
    }

    var isToday: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate.isToday
    }

    public init(id: String, title: String, deadline: Int64?, isAllDay: Bool, hasPermission: Bool, appLink: String) {
        self.id = id
        self.title = title
        self.deadline = deadline
        self.isAllDay = isAllDay
        self.hasPermission = hasPermission
        self.appLink = appLink
    }
}
