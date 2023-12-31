//
//  V3ListViewModel+Group.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/29.
//

import Foundation
import LarkTimeFormatUtils
import LarkEnv
import EventKit
import UniverseDesignIcon
import CTFoundation

// MARK: - Group

extension V3ListViewModel {

    func makeSections(_ items: [V3ListCellData], type: FilterTab.GroupField?, sections: [Rust.TaskSection]?, refs: [Rust.ContainerTaskRef]?) -> [V3ListSectionData] {
        let beginTime = CFAbsoluteTimeGetCurrent()
        defer {
            V3Home.logger.info("make sections consume \(CFAbsoluteTimeGetCurrent() - beginTime), count: \(items.count), type: \(type?.rawValue ?? 0)")
        }
        guard let type = type else {
            V3Home.assertionFailure()
            return []
        }
        switch type {
        case .empty: return makeNoGroup(items)
        case .custom: return makeCustomGroup(items, sections: sections, refs: refs)
        default: return makeSystemGroup(items, group: type)
        }
    }

    /// 无分组
    private func makeNoGroup(_ items: [V3ListCellData]) -> [V3ListSectionData] {
        guard !items.isEmpty else { return [] }
        var section = V3ListSectionData()
        section.items = items
        return [section]
    }

    /// 系统内置的分组
    private func makeSystemGroup(_ items: [V3ListCellData], group: FilterTab.GroupField) -> [V3ListSectionData] {
        guard [.startTime, .dueTime, .creator, .owner, .source].contains(group) else {
            V3Home.assertionFailure()
            return []
        }
        var sections = makeSections(group)
        items.forEach { cd in
            let result = sectionParam(cd, group: group)
            let firstIndex = sections.firstIndex(where: { $0.sectionId == result.sectionId })
            guard let index = firstIndex else {
                var section = V3ListSectionData(sectionId: result.sectionId)
                let isFold = getFoldState(sectionId: result.sectionId)
                section.header = makeSectionHeader(
                    titleIcon: result.sourceIcon,
                    title: result.name,
                    users: result.users,
                    isFold: isFold
                )
                increaseHeaderCount(&section)
                section.items.append(cd)
                sections.append(section)
                return
            }
            increaseHeaderCount(&sections[index])
            sections[index].items.append(cd)
        }
        // 计算header layout
        sections = sections.map { section in
            var new = section
            new.header?.layoutInfo = section.header?.makeLayoutInfo()
            return new
        }
        return sections.sorted { s0, s1 in
            return s0.sectionId.localizedStandardCompare(s1.sectionId) == .orderedAscending
        }
    }

    /// 构建分组： 开始截止时间分组比较特殊, 就算没有数据也要保留所有分组
    private func makeSections(_ group: FilterTab.GroupField) -> [V3ListSectionData] {
        if group == .dueTime {
            return V3ListTimeGroup.DueTime.allCases.map { type in
                var section = V3ListSectionData(sectionId: type.sectionId)
                let isFold = getFoldState(sectionId: type.sectionId)
                var header = makeSectionHeader(title: type.title, isFold: isFold)
                header.dueTimeType = type
                section.header = header
                return section
            }
        }
        if group == .startTime {
            return V3ListTimeGroup.StartTime.allCases.map { type in
                var section = V3ListSectionData(sectionId: type.sectionId)
                let isFold = getFoldState(sectionId: type.sectionId)
                var header = makeSectionHeader(title: type.title, isFold: isFold)
                header.startTimeType = type
                section.header = header
                return section
            }
        }
        return [V3ListSectionData]()
    }

    /// 系统内置分组的通用参数
    private struct SectionParamResult {
        var sectionId: String = ""
        var name: String?
        var users: [Assignee]?
        var sourceIcon: UIImage?
    }
    private func sectionParam(_ cd: V3ListCellData, group: FilterTab.GroupField) -> SectionParamResult {
        var result = SectionParamResult()
        switch group {
        case .startTime:
            let tc = curTimeContext
            let type = V3ListTimeGroup.startTime(startTime: cd.todo.startTimeForDisplay(tc.timeZone), timeContext: tc)
            result.name = type.title
            result.sectionId = type.sectionId
        case .dueTime:
            let tc = curTimeContext
            let type = V3ListTimeGroup.dueTime(dueTime: cd.todo.dueTimeForDisplay(tc.timeZone), timeContext: tc)
            result.name = type.title
            result.sectionId = type.sectionId
        case .owner:
            if cd.todo.isNoAssignee {
                let title = I18N.Todo_New_NoOwners_Tab_Title
                result.name = title
                // 加前缀是为了让排序能排到最后
                result.sectionId = "ZZZZZZZZZZZZZZZZZZZZZZZZZZ_\(title)_\(title.hash)"
            } else {
                let avatars = cd.todo.assignees
                    .map(Assignee.init(model:))
                    .sorted { s0, s1 in
                        let first = "\(s0.name)_\(s0.identifier)"
                        let second = "\(s1.name)_\(s1.identifier)"
                        return first.localizedStandardCompare(second) == .orderedAscending
                    }
                result.users = avatars
                let idsString = avatars.map(\.identifier).joined()
                // 单个负责人还是需要按照名字排序+hash；多负责人AB和BA在一个分组
                result.sectionId = "\(avatars.count)_\(avatars.map(\.name).joined())_\(idsString)"
            }
        case .creator:
            result.users = [Assignee(model: Assignee.RustModel(user: cd.todo.creator))]
            result.sectionId = "\(cd.todo.creator.name)_\(cd.todo.creator.userID)"
        case .source:
            result.name = I18N.Todo_New_SpecificSource_Others
            let id = result.name
            result.sectionId = "D_\(id)_\(id.hash)"
            let todo = cd.todo
            switch cd.todo.origin.type {
            case .href:
                switch cd.todo.source {
                case .doc, .docx:
                    if case .href(let href) = todo.origin.element, !href.url.isEmpty {
                        let title = href.title.isEmpty ? I18N.Todo_Task_UnnamedDocPlaceholder : href.title
                        result.name = title
                        result.sectionId = "B_\(title)_\(href.url.components(separatedBy: "#").first)"
                        result.sourceIcon = UDIcon.getIconByKey(
                            .fileLinkWordOutlined,
                            iconColor: UIColor.ud.iconN1,
                            size: ListConfig.Section.titleIconSize
                        )
                    }
                case .oapi:
                    if case .href(let href) = todo.origin.element {
                        let title = todo.origin.displayI18NName
                        result.name = title
                        result.sectionId = "C_\(title)"
                        result.sourceIcon = UDIcon.getIconByKey(
                            .robotOutlined,
                            iconColor: UIColor.ud.iconN1,
                            size: ListConfig.Section.titleIconSize
                        )
                    }
                @unknown default: break
                }
            case .chat:
                if case .chat(let chat) = todo.origin.element, todo.readable(for: .todoOrigin) {
                    let name = chat.chatName.isEmpty ? chat.link : chat.chatName
                    result.name = name
                    result.sectionId = "A_\(name)_\(chat.chatID)"
                    result.sourceIcon = UDIcon.getIconByKey(
                        .chatOutlined,
                        iconColor: UIColor.ud.iconN1,
                        size: ListConfig.Section.titleIconSize
                    )
                }
            @unknown default: break
            }
        default: V3Home.assertionFailure()
        }
        return result
    }

    /// 自定义分组
    private func makeCustomGroup(_ items: [V3ListCellData], sections: [Rust.TaskSection]?, refs: [Rust.ContainerTaskRef]?) -> [V3ListSectionData] {
        guard let sections = sections else {
            return []
        }
        let containerId = curContainerID
        let curSections = sections.filter { $0.containerID == curContainerID }
        return curSections
            .sorted(by: { $0.rank < $1.rank })
            .map { section in
                var data = V3ListSectionData(sectionId: section.guid, isCustom: true)
                if let refs = refs {
                    let todoIds = refs.filter { $0.containerGuid == containerId && $0.sectionGuid == section.guid }.map(\.taskGuid)
                    data.items = items.filter { todoIds.contains($0.todo.guid) }
                }
                let isFold = getFoldState(sectionId: section.guid)
                data.header = {
                    let title = section.displayName
                    let isFold = getFoldState(sectionId: section.guid)
                    var header = makeSectionHeader(title: title, isFold: isFold, hasMore: isTaskList ? isTaskEditableInContainer : true)
                    header.totalCount = data.items.count
                    header.layoutInfo = header.makeLayoutInfo()
                    return header
                }()
                data.footer = V3ListSectionFooterData(
                    isShow: isTaskList ? isTaskEditableInContainer : isOwnedView,
                    isFold: isFold)
                return data
            }
    }

    /// 构建header
    private func makeSectionHeader(
        titleIcon: UIImage? = nil,
        title: String? = nil,
        users: [Assignee]? = nil,
        isFold: Bool = false,
        hasMore: Bool = false
    ) -> V3ListSectionHeaderData {
        var header = V3ListSectionHeaderData()
        header.isFold = isFold
        header.badgeCount = 0
        header.totalCount = 0
        if let titleText = title {
            header.titleInfo = (titleIcon, titleText)
        }
        if let users = users {
            if users.count > 1 {
                let maxCount = 5
                let prefixs = Array(users.prefix(maxCount)).map { CheckedAvatarViewData(icon: .avatar($0.avatar)) }
                let viewData = AvatarGroupViewData(avatars: prefixs, style: .normal, remainCount: users.count > maxCount ? users.count - maxCount : nil)
                header.multiUsers = viewData
            } else {
                if let user = users.first {
                    header.singleUser = (avatar: user.avatar, name: user.name)
                }
            }
        }
        header.users = users
        header.hasMore = hasMore
        return header
    }

    private func increaseHeaderCount(_ section: inout V3ListSectionData) {
        guard let header = section.header else { return }
        var h = header
//        if !section.isCustom, isBadgeItem(section.sectionId) {
//            if let cnt = h.badgeCount {
//                h.badgeCount = cnt + 1
//            }
//        } else {
//        }
        if let cnt = h.totalCount {
            h.totalCount = cnt + 1
        }
        section.header = h
    }

    func decreaseHeaderCount(_ section: inout V3ListSectionData) {
        guard let header = section.header else { return }
        var h = header
//        if !section.isCustom, isBadgeItem(section.sectionId) {
//            if let cnt = h.badgeCount {
//                h.badgeCount = cnt - 1
//            }
//        } else {
//        }
        if let cnt = h.totalCount {
            h.totalCount = cnt - 1
        }
        section.header = h
    }

    /// 获取todo可以展示的badge个数
    private func isBadgeItem(_ sectionId: String) -> Bool {
        guard let settingService = settingService, settingService.value(forKeyPath: \.listBadgeConfig).enable, isOwnedView else {
            return false
        }
        let type = settingService.value(forKeyPath: \.listBadgeConfig).type
        switch type {
        case .overdue:
            if sectionId == V3ListTimeGroup.DueTime.overDue.sectionId {
                return true
            }
        case .overdueAndToday:
            if sectionId == V3ListTimeGroup.DueTime.overDue.sectionId ||
                sectionId == V3ListTimeGroup.DueTime.today.sectionId {
                return true
            }
        default: break
        }
        return false
    }

}

// MARK: - 分组

enum V3ListTimeGroup {

    enum StartTime: CaseIterable {
        // 已开始
        case started
        // 今天
        case today
        // 明天
        case tomorrow
        // 未来七天
        case next7Days
        // 以后
        case later
        // 未安排时间
        case noTime

        var title: String {
            switch self {
            case .started: return I18N.Todo_TaskSection_Ongoing_Text
            case .today: return I18N.Todo_Menu_Today
            case .tomorrow: return I18N.Todo_Menu_Tomorrow
            case .next7Days: return I18N.Todo_Menu_Next7Days
            case .later: return I18N.Todo_New_MuchMuchLater_Title
            case .noTime: return I18N.Todo_New_NotScheduled_Title
            }
        }

        // 用于排序
        var sectionId: String {
            switch self {
            case .started: return "A_\(title)"
            case .today: return "B_\(title)"
            case .tomorrow: return "C_\(title)"
            case .next7Days: return "D_\(title)"
            case .later: return "E_\(title)"
            case .noTime: return "F_\(title)"
            }
        }

        func defaultStartTime(by offset: Int64, timeZone: TimeZone, isAllDay: Bool) -> Int64 {
            var date: Date?
            let oneDay: Double = 24 * 60 * 60
            switch self {
            case .started: date = Date(timeIntervalSinceNow: -oneDay)
            case .today: date = Date()
            case .tomorrow: date = Date(timeIntervalSinceNow: oneDay)
            case .next7Days: date = Date(timeIntervalSinceNow: 7 * oneDay)
            case .later: date = Date(timeIntervalSinceNow: 8 * oneDay)
            case .noTime: date = nil
            }
            if let date = date {
                if isAllDay {
                    let julianDay = JulianDayUtil.julianDay(from: date, in: timeZone)
                    return JulianDayUtil.startOfDay(for: julianDay, in: utcTimeZone)
                } else {
                    let time = Utils.DueTime.defaultDaytime(
                        byOffset: offset,
                        date: date,
                        timeZone: timeZone
                    )
                    return Int64(time.timeIntervalSince1970)
                }
            }
            return 0
        }

    }

    // 截止时间
    enum DueTime: CaseIterable {
        // 已逾期
        case overDue
        // 今天
        case today
        // 明天
        case tomorrow
        // 未来七天
        case next7Days
        // 以后
        case later
        // 未安排时间
        case noTime

        var title: String {
            switch self {
            case .overDue: return I18N.Todo_Menu_Overdue
            case .today: return I18N.Todo_Menu_Today
            case .tomorrow: return I18N.Todo_Menu_Tomorrow
            case .next7Days: return I18N.Todo_Menu_Next7Days
            case .later: return I18N.Todo_New_MuchMuchLater_Title
            case .noTime: return I18N.Todo_New_NotScheduled_Title
            }
        }

        var color: UIColor {
            switch self {
            case .overDue: return UIColor.ud.functionDangerContentDefault
            case .today: return UIColor.ud.primaryContentDefault
            default: return UIColor.ud.textCaption
            }
        }

        // 用于排序
        var sectionId: String {
            switch self {
            case .overDue: return "A_\(title)"
            case .today: return "B_\(title)"
            case .tomorrow: return "C_\(title)"
            case .next7Days: return "D_\(title)"
            case .later: return "E_\(title)"
            case .noTime: return "F_\(title)"
            }
        }

        func defaultDueTime(by offset: Int64, timeZone: TimeZone, isAllDay: Bool) -> Int64 {
            var date: Date?
            let oneDay: Double = 24 * 60 * 60
            switch self {
            case .overDue: date = Date(timeIntervalSinceNow: -oneDay)
            case .today: date = Date()
            case .tomorrow: date = Date(timeIntervalSinceNow: oneDay)
            case .next7Days: date = Date(timeIntervalSinceNow: 7 * oneDay)
            case .later: date = Date(timeIntervalSinceNow: 8 * oneDay)
            case .noTime: date = nil
            }
            if let date = date {
                if isAllDay {
                    let julianDay = JulianDayUtil.julianDay(from: date, in: timeZone)
                    return JulianDayUtil.startOfDay(for: julianDay, in: utcTimeZone)
                } else {
                    let time = Utils.DueTime.defaultDaytime(
                        byOffset: offset,
                        date: date,
                        timeZone: timeZone
                    )
                    return Int64(time.timeIntervalSince1970)
                }
            }
            return 0
        }
    }

    static func startTime(startTime: Int64, timeContext: TimeContext) -> V3ListTimeGroup.StartTime {
        if case .start(let startTime) = time(isStart: true, time: startTime, timeContext: timeContext) {
            return startTime
        }
        return .noTime
    }

    private enum TimeType {
        case start(StartTime)
        case due(DueTime)
    }

    private static func time(isStart: Bool, time: Int64, timeContext: TimeContext) -> TimeType {
        guard time > 0 else { return isStart ? .start(.noTime): .due(.noTime) }
        let date = Date(timeIntervalSince1970: TimeInterval(time))
        let canlerdar = getCalender(timeZone: timeContext.timeZone)
        // 以分钟为精度
        if time / 60 <= timeContext.currentTime / 60 {
            return isStart ? .start(.started) : .due(.overDue)
        } else {
            if isInToday(date, in: canlerdar) {
                return isStart ? .start(.today) : .due(.today)
            } else if isInTomorrow(date, in: canlerdar) {
                return isStart ? .start(.tomorrow) : .due(.tomorrow)
            } else if isInNext7Days(date, in: canlerdar) {
                return isStart ? .start(.next7Days) : .due(.next7Days)
            } else {
                return isStart ? .start(.later) : .due(.later)
            }
        }
    }

    static func dueTime(dueTime: Int64, timeContext: TimeContext) -> V3ListTimeGroup.DueTime {
        if case .due(let dueTime) = time(isStart: false, time: dueTime, timeContext: timeContext) {
            return dueTime
        }
        return .noTime
    }

    @inline(__always)
    private static func getCalender(timeZone: TimeZone = utcTimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = EnvManager.env.isChinaMainlandGeo ? (EKWeekday.monday).rawValue : (EKWeekday.sunday).rawValue
        calendar.timeZone = timeZone
        return calendar
    }

    @inline(__always)
    private static func isInToday(_ date: Date, in calendar: Calendar) -> Bool {
        return calendar.isDateInToday(date)
    }

    @inline(__always)
    private static func isInTomorrow(_ date: Date, in calendar: Calendar) -> Bool {
        return calendar.isDateInTomorrow(date)
    }

    @inline(__always)
    private static func isInNext7Days(_ date: Date, in calendar: Calendar) -> Bool {
        guard let next7Days = calendar.date(byAdding: .day, value: +8, to: Date()) else {
            return false
        }
        return calendar.compare(date, to: next7Days, toGranularity: .day) == .orderedAscending
    }
}
