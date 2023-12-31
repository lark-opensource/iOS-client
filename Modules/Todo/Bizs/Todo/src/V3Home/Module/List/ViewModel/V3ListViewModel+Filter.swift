//
//  V3ListViewModel+Filter.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/29.
//

import Foundation
import RustPB

// MARK: - Filter

extension V3ListViewModel {

    /// 过滤出当前视图的todo
    func filterTasks(by filters: Rust.ViewFilters?, from allTasks: [Rust.Todo]?) -> [Rust.Todo]? {
        guard let allTasks = allTasks else {
            V3Home.logger.info("task is nil")
            return nil
        }
        guard let filters = filters else {
            V3Home.logger.info("filter is nil")
            return allTasks
        }
        let tasks = allTasks.filter { todo in
            return filter(todo, conjunction: filters.conjunction, conditons: filters.conditions)
        }
        return tasks
    }

    /// 统计当前视图下的未完成任务个数
    func filterInProgressCount(_ container: Rust.TaskContainer?, from filters: Rust.ViewFilters?, in allTodos: [Rust.Todo]?) -> String? {
        guard let container = container, [ContainerKey.owned.rawValue, ContainerKey.followed.rawValue].contains(container.key), let allTodos = allTodos else {
            return nil
        }
        guard let filters = filters else {
            return nil
        }
        // 修改状态为未完成
        let conditions = filters.conditions.map { condition in
            if condition.fieldKey == FieldKey.completeStatus.rawValue {
                var newCondition = condition
                var value = Rust.FieldFilterValue()
                value.taskCompleteStatusValue.taskCompleteStatus = .uncompleted
                newCondition.fieldFilterValue = [value]
                return newCondition
            }
            return condition
        }
        let cnt = allTodos.reduce(0) { partialResult, todo in
            if filter(todo, conjunction: filters.conjunction, conditons: conditions) {
                return partialResult + 1
            }
            return partialResult
        }
        if cnt >= 1_000 {
            return "999+"
        } else if cnt <= 0 {
            return nil
        } else {
            return "\(cnt)"
        }
    }

    private func filter(_ todo: Rust.Todo, conjunction: Rust.ViewFilterConjunction, conditons: [Rust.ViewCondition]) -> Bool {
        guard !conditons.isEmpty else { return true }
        var result = true
        conditons.forEach { condition in
            var flag = true
            switch FilterFiled.type(condition.fieldKey) {
            case .memeber:
                flag = memberFilter(todo, by: condition)
            case .completeStatus:
                flag = completeStatusFilter(todo, by: condition)
            default: break
            }
            switch conjunction {
            case .and: result = result && flag
            case .or: result = result || flag
            default: break
            }
        }
        return result
    }

    private struct FilterFiled {
        static let members = [
            FieldKey.assignee.rawValue,
            FieldKey.creator.rawValue,
            FieldKey.assigner.rawValue,
            FieldKey.follower.rawValue
        ]

        static func type(_ fieldKey: String) -> FilterType {
            if FilterFiled.members.contains(where: { $0 == fieldKey }) {
                return .memeber
            } else if FieldKey.completeStatus.rawValue == fieldKey {
                return .completeStatus
            }
            return .default
        }

        enum FilterType {
            case memeber
            case completeStatus
            // 端上目前不支持的
            case `default`
        }
    }

    // 人员过滤
    private func memberFilter(_ todo: Rust.Todo, by condition: Rust.ViewCondition) -> Bool {
        var flag = true
        let (key, predicate, value) = (condition.fieldKey, condition.predicate, condition.fieldFilterValue)
        guard let first = value.first(where: { $0.hasMemberValue }) else { return flag }
        let (todoMemberIds, memberID) = (memberIds(todo, by: key), String(first.memberValue.memberID))
        switch predicate {
        case .include: flag = todoMemberIds.contains(where: { $0 == memberID })
        case .exclude: flag = !todoMemberIds.contains(where: { $0 == memberID })
        case .empty: flag = todoMemberIds.isEmpty
        case .notEmpty: flag = !todoMemberIds.isEmpty
        @unknown default: break
        }
        return flag
    }

    private func memberIds(_ todo: Rust.Todo, by filedKey: String) -> [String] {
        switch filedKey {
        case FieldKey.assignee.rawValue: return todo.assignees.map(\.assigneeID)
        case FieldKey.creator.rawValue: return [todo.creatorID]
        case FieldKey.assigner.rawValue: return todo.assignees.map(\.assignerID)
        case FieldKey.follower.rawValue: return todo.followers.map(\.followerID)
        default: return []
        }
    }

    /// 状态过滤器，比较特殊只有equal
    private func completeStatusFilter(_ todo: Rust.Todo, by condition: Rust.ViewCondition) -> Bool {
        switch completeStatusValue(from: condition) {
        case .completed: return todo.isComleted(completeService)
        case .uncompleted: return !todo.isComleted(completeService)
        @unknown default: return true
        }
    }

    /// 获取筛选字段中状态的值
    /// - Parameter condtion: 筛选
    /// - Returns: default is all
    func completeStatusValue(from condition: Rust.ViewCondition) -> Rust.CompleteStatusValue {
        guard condition.fieldKey == FieldKey.completeStatus.rawValue else {
            return .all
        }
        guard let first = condition.fieldFilterValue.first(where: { $0.hasTaskCompleteStatusValue }) else {
            return .all
        }
        return first.taskCompleteStatusValue.taskCompleteStatus
    }
}
