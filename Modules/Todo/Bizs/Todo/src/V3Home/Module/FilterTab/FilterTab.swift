//
//  FilterTab.swift
//  Todo
//
//  Created by baiyantao on 2022/8/19.
//

import Foundation
import UniverseDesignColor
import LKCommonsLogging

struct FilterTab { }

// MARK: - Logger

extension FilterTab {
    static let logger = Logger.log(FilterTab.self, category: "Todo.FilterTab")
}

// MARK: - View Config

// UI 配置文件，忽略魔法数检查
// nolint: magic number
extension FilterTab {
    static var imFeedBgBody: UIColor {
        UDColor.getValueByKey(UDColor.Name("imtoken-feed-bg-body")) ?? UDColor.N00 & UDColor.N500
    }
    static var imFeedTextPriSelected: UIColor {
        return UDColor.getValueByKey(UDColor.Name("imtoken-feed-text-pri-selected")) ?? UDColor.B600 & UDColor.N1000
    }
    static var imFeedIconPriSelected: UIColor {
        return UDColor.getValueByKey(UDColor.Name("imtoken-feed-icon-pri-selected")) ?? UDColor.B600 & UDColor.N1000
    }
    static var imFeedFeedFillActive: UIColor {
        return UDColor.getValueByKey(UDColor.Name("imtoken-feed-fill-active")) ?? UIColor.ud.rgb(0x3385FF).withAlphaComponent(0.12) & UIColor.ud.fillActive
    }

    static var contentEdgeInsetLeft: CGFloat { 2.auto() }
    static var contentEdgeInsetRight: CGFloat { 2.auto() }
    static var itemSpacing: CGFloat { 2.auto() }
    static var itemWidthIncrement: CGFloat { 40.auto() }
    static var selectedItemWidthIncrement: CGFloat { 56.auto() }
    static var indicatorHeight: CGFloat { 28 }
    static var verticalPadding: CGFloat { 4 }
    static var menuWidth: CGFloat { 52 }

    enum Item {
        case lineContainer
        case selector
        case archivedNotice

        func height() -> CGFloat {
            switch self {
            case .lineContainer:
                return 48
            case .selector:
                return 44
            case .archivedNotice:
                return 40
            }
        }
    }
}
// enable-lint: magic number

// MARK: - Logger

extension FilterTab {
    static func containerKey2Title(_ key: String) -> String? {
        guard let containerKey = ContainerKey(rawValue: key) else { return nil }
        return containerKey2Title(containerKey)
    }

    static func containerKey2Title(_ key: ContainerKey) -> String? {
        containerKeyTitleDic[key.rawValue]
    }

    private static let containerKeyTitleDic: [String: String] = [
        ContainerKey.owned.rawValue: I18N.Todo_New_OwnedByMe_TabTitle,
        ContainerKey.followed.rawValue: I18N.Todo_New_SubscribedByMe_TabTitle,
        ContainerKey.all.rawValue: I18N.Todo_New_AllTasks_TabTitle,
        ContainerKey.created.rawValue: I18N.Todo_New_CreatedByMe_TabTitle,
        ContainerKey.assigned.rawValue: I18N.Todo_New_AssignedByMe_TabTitle,
        ContainerKey.completed.rawValue: I18N.Todo_New_Completed_TabTitle
    ]

    enum StatusField: Int {
        case uncompleted
        case completed
        case all
    }

    enum GroupField: Int {
        case empty
        case custom
        case owner
        case creator
        case startTime
        case dueTime
        case source
    }

    enum SortingField: Int {
        case custom
        case createTime
        case updateTime
        case completeTime
        case startTime
        case dueTime
    }

    enum Indicator: Equatable {
        case check
        case sorting(isAscending: Bool)
    }

    struct SortingCollection: Equatable {
        var field: SortingField
        var indicator: Indicator

        var isAscending: Bool {
            if case .sorting(let isAscending) = indicator {
                return isAscending
            }
            return true
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            if lhs.field == rhs.field, lhs.indicator == rhs.indicator {
                return true
            }
            return false
        }
    }
}

extension FilterTab.StatusField {
    init(from pb: Rust.ViewFilters) {
        let key = FieldKey.completeStatus.rawValue
        guard let condition = pb.conditions.first(where: { $0.fieldKey == key }),
              condition.predicate == .equal,
              let first = condition.fieldFilterValue.first(where: { $0.hasTaskCompleteStatusValue }) else {
            self = .uncompleted
            return
        }
        switch first.taskCompleteStatusValue.taskCompleteStatus {
        case .uncompleted:
            self = .uncompleted
        case .completed:
            self = .completed
        case .all:
            self = .all
        case .unknown:
            self = .uncompleted
        @unknown default:
            self = .uncompleted
        }
    }

    func appendSelfTo(pb: inout Rust.ViewFilters) {
        let key = FieldKey.completeStatus.rawValue
        guard let conditionIdx = pb.conditions.firstIndex(where: { $0.fieldKey == key }) else {
            return
        }
        var condition = pb.conditions[conditionIdx]
        guard condition.predicate == .equal else { return }
        var value = Rust.FieldFilterValue()
        var completeValue = value.taskCompleteStatusValue
        switch self {
        case .uncompleted:
            completeValue.taskCompleteStatus = .uncompleted
        case .completed:
            completeValue.taskCompleteStatus = .completed
        case .all:
            completeValue.taskCompleteStatus = .all
        }
        value.taskCompleteStatusValue = completeValue
        condition.fieldFilterValue = [value]
        pb.conditions[conditionIdx] = condition
    }

    func title() -> String {
        switch self {
        case .uncompleted:
            return I18N.Todo_New_Ongoing_FilterOption
        case .completed:
            return I18N.Todo_New_Completed_FilterOption
        case .all:
            return I18N.Todo_New_AllTasks_FilterOption
        }
    }
}

extension FilterTab.GroupField {
    init(from pb: Rust.ViewGroups) {
        guard let group = pb.groups.first else {
            self = .empty // 数组为空时，为 empty
            return
        }
        guard let val = FilterTab.GroupField(from: group.fieldKey) else {
            self = .empty
            return
        }
        self = val
    }

    init?(from key: String) {
        switch key {
        case FieldKey.section.rawValue:
            self = .custom
        case FieldKey.assignee.rawValue:
            self = .owner
        case FieldKey.creator.rawValue:
            self = .creator
        case FieldKey.dueTime.rawValue:
            self = .dueTime
        case FieldKey.source.rawValue:
            self = .source
        case FieldKey.startTime.rawValue:
            if FeatureGating.boolValue(for: .startTime) {
                self = .startTime
            } else {
                return nil
            }
        default:
            return nil
        }
    }

    func toPb() -> Rust.ViewGroups {
        var groups = [Rust.ViewGroup]()
        var group = Rust.ViewGroup()
        switch self {
        case .empty:
            groups = []
        case .custom:
            group.fieldKey = FieldKey.section.rawValue
            groups = [group]
        case .owner:
            group.fieldKey = FieldKey.assignee.rawValue
            groups = [group]
        case .creator:
            group.fieldKey = FieldKey.creator.rawValue
            groups = [group]
        case .dueTime:
            group.fieldKey = FieldKey.dueTime.rawValue
            groups = [group]
        case .startTime:
            group.fieldKey = FieldKey.startTime.rawValue
            groups = [group]
        case .source:
            group.fieldKey = FieldKey.source.rawValue
            groups = [group]
        }
        var res = Rust.ViewGroups()
        res.groups = groups
        return res
    }

    func title() -> String {
        switch self {
        case .empty:
            return I18N.Todo_New_NoSelectedSection_Option
        case .custom:
            return I18N.Todo_New_Section_GroupBy_Section_Button
        case .owner:
            return I18N.Todo_New_Owner_Text
        case .creator:
            return I18N.Todo_New_Creator_Text
        case .dueTime:
            return I18N.Todo_New_DueTime_Text
        case .startTime:
            return I18N.Todo_New_StartTime_Text
        case .source:
            return I18N.Todo_New_SourceInDetail_Text
        }
    }
}

extension FilterTab.SortingField {
    func title() -> String {
        switch self {
        case .custom:
            return I18N.Todo_New_Sort_CustomSort_Button
        case .createTime:
            return I18N.Todo_New_CreatedAtTime_Text
        case .updateTime:
            return I18N.Todo_New_UpdatedAtTime_Text
        case .completeTime:
            return I18N.Todo_New_CompletedAtTime_Text
        case .dueTime:
            return I18N.Todo_New_DueTime_Text
        case .startTime:
            return I18N.Todo_New_StartTime_Text
        }
    }
}

extension FilterTab.SortingCollection {
    init(from pb: Rust.ViewSorts) {
        guard let sort = pb.sorts.first else {
            self = .init(field: .custom, indicator: .check) // 数组为空时，为 custom
            return
        }
        guard let val = FilterTab.SortingCollection(from: sort.fieldKey, isAscending: sort.order == .asc) else {
            self = .init(field: .custom, indicator: .check)
            return
        }
        self = val
    }

    init?(from key: String, isAscending: Bool? = nil) {
        var indicator: FilterTab.Indicator?
        if let isAscending = isAscending {
            indicator = FilterTab.Indicator.sorting(isAscending: isAscending)
        }
        switch key {
        case FieldKey.createTime.rawValue:
            self = .init(field: .createTime, indicator: indicator ?? .sorting(isAscending: false))
        case FieldKey.updateTime.rawValue:
            self = .init(field: .updateTime, indicator: indicator ?? .sorting(isAscending: false))
        case FieldKey.completeTime.rawValue:
            self = .init(field: .completeTime, indicator: indicator ?? .sorting(isAscending: false))
        case FieldKey.dueTime.rawValue:
            self = .init(field: .dueTime, indicator: indicator ?? .sorting(isAscending: true))
        case FieldKey.startTime.rawValue:
            if FeatureGating.boolValue(for: .startTime) {
                self = .init(field: .startTime, indicator: indicator ?? .sorting(isAscending: true))
            } else {
                return nil
            }
        default:
            return nil
        }
    }

    func toPb() -> Rust.ViewSorts {
        var sorts = [Rust.ViewSort]()
        var sort = Rust.ViewSort()

        switch self.indicator {
        case .check:
            sort.clearOrder()
        case .sorting(let isAscending):
            sort.order = isAscending ? .asc : .desc
        }

        switch self.field {
        case .custom:
            sorts = []
        case .createTime:
            sort.fieldKey = FieldKey.createTime.rawValue
            sorts = [sort]
        case .updateTime:
            sort.fieldKey = FieldKey.updateTime.rawValue
            sorts = [sort]
        case .completeTime:
            sort.fieldKey = FieldKey.completeTime.rawValue
            sorts = [sort]
        case .dueTime:
            sort.fieldKey = FieldKey.dueTime.rawValue
            sorts = [sort]
        case .startTime:
            sort.fieldKey = FieldKey.startTime.rawValue
            sorts = [sort]
        }
        var res = Rust.ViewSorts()
        res.sorts = sorts
        return res
    }
}

extension FilterTab.SortingCollection: LogConvertible {
    var logInfo: String {
        let indicatorInfo: String
        switch indicator {
        case .check:
            indicatorInfo = "c"
        case .sorting(let isAscending):
            indicatorInfo = "s-\(isAscending ? "t" : "f")"
        }
        return "field: \(field.rawValue), indicator: \(indicatorInfo)"
    }
}
