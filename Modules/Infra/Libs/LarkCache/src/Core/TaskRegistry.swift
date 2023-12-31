//
//  TaskRegistry.swift
//  LarkCache
//
//  Created by Supeng on 2020/8/11.
//

import Foundation

/// CleanTask注册模块
public enum CleanTaskRegistry {
    /// task provider
    public typealias TaskProvider = () -> CleanTask

    final class TaskWrapper {
        enum Status {
            case initial
            case running
        }

        let task: TaskProvider
        var status: Status = .initial

        init(task: @escaping TaskProvider) {
            var taskInstance: CleanTask?
            self.task = {
                if let taskInstance {
                    return taskInstance
                }
                taskInstance = task()
                return taskInstance ?? {
                    #if DEBUG
                    fatalError("unexpected")
                    #else
                    task()
                    #endif
                }()
            }
        }
    }

    static var allTasks: [TaskWrapper] = [TaskWrapper(task: { DefaultCacheCleanTask() })]

    /// 注册一个CleanTask
    public static func register(cleanTask: @autoclosure @escaping TaskProvider) {
        allTasks.append(TaskWrapper(task: cleanTask))
    }
}
