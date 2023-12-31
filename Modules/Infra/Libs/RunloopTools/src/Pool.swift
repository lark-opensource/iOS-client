//
//  Pool.swift
//  RunloopTools
//
//  Created by KT on 2020/2/11.
//

import Foundation
import ThreadSafeDataStructure

protocol PoolResponseable: AnyObject {
    func afterAddTask()
    func afterDeleteTask()
}

final class Pool {
    private var tasks: SafeDictionary<Priority, [Task]> = [:] + .readWriteLock
    weak var reciver: PoolResponseable?

    func addTask(_ task: Task) {
        var tasks = self.tasks[task.priority] ?? []
        tasks.append(task)
        self.tasks[task.priority] = tasks
        self.reciver?.afterAddTask()
    }

    /// 清理Pool
    /// - Parameter scope: 注册的服务级别
    func clear(scope: Scope) {
        self.customFilter { $0.scope != .user }
    }

    /// 删除已经执行完成的任务
    func deleteFinished() {
        self.customFilter { $0.state != .finished }
    }

    var sortedTask: [Task] {
        // 高优排序
        let sortedTasks = self.tasks.sorted { $0.0 > $1.0 }
        let allTasks = sortedTasks.flatMap { $0.1 }
        return allTasks
    }

    var isEmpty: Bool {
        return self.tasks.flatMap { $0.value }.isEmpty
    }

    private func customFilter(_ isIncluded: (Task) throws -> Bool) rethrows {
        let allKeys = self.tasks.keys
        try allKeys.forEach { (priority) in
            var tasks = self.tasks[priority]
            tasks = try tasks?.filter(isIncluded)
            self.tasks[priority] = tasks
        }
        self.reciver?.afterDeleteTask()
    }
}
