//
//  BootTaskRegistry.swift
//  BootManager
//
//  Created by sniperj on 2021/4/19.
//

import Foundation

/// Factory
public typealias BootTaskProvider = (BootContext) throws -> BootTask

internal final class BootTaskRegistry {
    internal static var defaultTasksProvider: [TaskIdentify: BootTaskProvider] = [RunloopAndCpuIdleTask.identify: RunloopAndCpuIdleTask.init(context:)]

    internal static var tasksProvider: [TaskIdentify: BootTaskProvider] = defaultTasksProvider

    /// 注册启动Task
    /// - Parameters:
    ///   - task: Task.Type
    ///   - provider: Task工厂
    internal static func register<T: BootTask&Identifiable>(
        _ task: T.Type,
        provider: @escaping BootTaskProvider) {
        let key = task.identify
        assert(!self.tasksProvider.keys.contains(key), "key: \(key) has been registried")
        self.tasksProvider[key] = provider
    }

    /// 从Provider中初始化Task
    /// - Parameter taskIdentify: Task唯一ID
    internal static func resolve(_ taskIdentify: TaskIdentify, context: BootContext) -> BootTask? {
        guard let provider = self.tasksProvider[taskIdentify] else { return nil }
        do {
            let task = try provider(context)
            task.identify = taskIdentify
            return task
        } catch {
            assertionFailure("task: \(taskIdentify) init failed, error: \(error)")
            NewBootManager.logger.info("boot_resolve_task \(taskIdentify) error", error: error)
            return nil
        }
    }

    internal static func clear() {
        self.tasksProvider = defaultTasksProvider
    }
}
