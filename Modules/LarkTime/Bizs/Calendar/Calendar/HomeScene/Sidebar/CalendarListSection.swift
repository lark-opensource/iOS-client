//
//  CalendarListSection.swift
//  Calendar
//
//  Created by huoyunjie on 2021/9/7.
//

import Foundation

struct CalendarListSectionContent: Hashable {
    static func == (lhs: CalendarListSectionContent, rhs: CalendarListSectionContent) -> Bool {
        return lhs.sourceTitle == rhs.sourceTitle
    }

    var sourceTitle: String = ""
    var data: [SidebarModelData] = []

    func hash(into hasher: inout Hasher) {
        hasher.combine(sourceTitle)
    }
}

enum CalendarListSection {
    /// 我管理的
    case larkMine(CalendarListSectionContent)
    /// 订阅日历
    case larkSubscribe(CalendarListSectionContent)
    /// 三方日历 - google
    case google(CalendarListSectionContent)
    /// 三方日历 - exchange
    case exchange(CalendarListSectionContent)
    /// 本地日历
    case local(CalendarListSectionContent)

    var content: CalendarListSectionContent {
        switch self {
        case let .larkMine(content),
             let .larkSubscribe(content),
             let .exchange(content),
             let .google(content),
             let .local(content):
            return content
        }
    }

    var tag: Int {
        switch self {
        case .larkMine: return 4
        case .larkSubscribe: return 3
        case .google: return 2
        case .exchange: return 1
        case .local: return 0
        }
    }

    var count: Int {
        return content.data.count
    }

    func reset(with data: [SidebarModelData]) -> CalendarListSection {
        var content = self.content
        content.data = data
        switch self {
        case .larkMine:
            return .larkMine(content)
        case .larkSubscribe:
            return .larkSubscribe(content)
        case .google:
            return .google(content)
        case .exchange:
            return .exchange(content)
        case .local:
            return .local(content)
        }
    }
}

// MARK: Sort
extension CalendarListSection {
    func sortedList() -> CalendarListSection {
        let sort: ((SidebarModelData, SidebarModelData) -> Bool) = { l, r in
            if l.isVisible == r.isVisible {
                return l.weight > r.weight
            }
            return l.isVisible
        }
        let sourceSort: ((SidebarModelData, SidebarModelData) -> Bool) = {
            l, r in
            return l.source == .timeContainer
        }
        switch self {
        case var .larkMine(content):
            var data = content.data.sorted(by: sort)
            /// 根据 source 进行排序，timeContainer 在前
            data = data.sorted(by: sourceSort)
            /// 用户主日历排在第一
            if let index = data.firstIndex(where: { d in
                if d.source == .calendar,
                   let cal = d as? CalendarSidebarModelData,
                   cal.calendar.isAvailablePrimaryCalendar() {
                    return true
                }
                return false
            }){
                let primaryCalendar = data.remove(at: index)
                data.insert(primaryCalendar, at: 0)
            }
            content.data = data
            return .larkMine(content)
        case var .larkSubscribe(content):
            content.data.sort(by: sort)
            return .larkSubscribe(content)
        case var .google(content):
            content.data.sort(by: sort)
            return .google(content)
        case var .exchange(content):
            content.data.sort(by: sort)
            return .exchange(content)
        case var .local(content):
            let data = content.data.sorted { l, r in
                if l.isVisible == r.isVisible {
                    return l.displayName > r.displayName
                }
                return l.isVisible
            }
            content.data = data
            return .local(content)
        }
    }
}

// MARK: HASHABLE
extension CalendarListSection: Hashable {

    static func == (lhs: CalendarListSection, rhs: CalendarListSection) -> Bool {
        switch (lhs, rhs) {
        case (larkMine, larkMine):
            return true
        case (larkSubscribe, larkSubscribe):
            return true
        case let (google(lhsContent), google(rhsContent)),
             let (exchange(lhsContent), exchange(rhsContent)),
             let (local(lhsContent), local(rhsContent)):
            return lhsContent.sourceTitle == rhsContent.sourceTitle
        default:
            return false
        }
    }

}
