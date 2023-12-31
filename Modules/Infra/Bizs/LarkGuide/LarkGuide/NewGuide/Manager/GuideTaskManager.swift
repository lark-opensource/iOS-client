//
//  GuideTaskManager.swift
//  LarkGuide
//
//  Created by zhenning on 2020/6/28.
//

import Foundation
import UIKit
import LarkGuideUI
import LKCommonsLogging
import ThreadSafeDataStructure

public protocol GuideTaskManagerDelegate: AnyObject {
    func onExcuteGuideTask(guideTask: GuideTask, finishHandler: @escaping () -> Void)
}

final class GuideTaskManager {
    private static let logger = Logger.log(GuideTaskManager.self, category: "LarkGuide")

    private var taskQueue: SafeArray<GuideTask> = [] + .readWriteLock
    weak var taskManagerDelegate: GuideTaskManagerDelegate?
    // 任务读取加锁
    private let taskAddLock: NSLock = NSLock()
    // 任务移除加锁
    private var taskRemoveLock: NSLock = NSLock()
    // 当前正在展示的引导Key
    private(set) var currShowingGuideKey: String?

    init() {
    }

    /// 往任务队列中添加任务
    func addTask(guideTask: GuideTask) {
        Self.logger.debug("[LarkGuide]: addTask before taskQueue = \(taskQueue)")
        /// 若队列中已有该任务，则丢弃
        guard !taskQueue.contains(where: { $0.key == guideTask.key }) else {
            Self.logger.debug("[LarkGuide]: addTask taskQueue already contains taskKey = \(guideTask.key)")
            return
        }
        taskAddLock.lock()
        defer { taskAddLock.unlock() }

        // 1. 判断队列是否存在任务
        if let firstTask = taskQueue.first {
            // 2. 判断可视区域是否发生变化
            if firstTask.viewAreaKey == guideTask.viewAreaKey {
                // 3. 插入合适的位置
                // sort by task priority
                let index = getTaskIndex(priority: Int(guideTask.priority))
                taskQueue.insert(guideTask, at: index)
                Self.logger.debug("[LarkGuide]: addTask", additionalData: [
                    "index": "\(index)",
                    "viewAreaKey": "\(guideTask.viewAreaKey)",
                    "guideTask.key": "\(guideTask.key)"
                ])
            } else {
                // when view area changed, reload task queue
                taskQueue.removeAll()
                taskQueue.append(guideTask)
                Self.logger.debug("[LarkGuide]: addTask scope changed",
                                              additionalData: [
                                                "viewAreaKey": "\(guideTask.viewAreaKey)",
                                                "guideKey": "\(guideTask.key)"
                ])
            }
            Self.logger.debug("[LarkGuide]: addTask firstTask",
                                          additionalData: [
                                            "current viewAreaKey": "\(guideTask.viewAreaKey)",
                                            "first viewAreaKey": "\(firstTask.viewAreaKey)"
            ])
        } else {
            taskQueue.append(guideTask)
        }
        Self.logger.debug("[LarkGuide]: addTask after taskQueue = \(taskQueue)")
    }

    /// 通过key移除任务
    @discardableResult
    func removeTask(key: String) -> Bool {
        taskRemoveLock.lock()
        defer { taskRemoveLock.unlock() }

        // 判断是否存在
        guard let taskIndex = taskQueue.firstIndex(where: { $0.key == key }) else {
            return false
        }
        taskQueue.remove(at: taskIndex)
        Self.logger.debug("[LarkGuide]: removeTask taskIndex = \(taskIndex), taskQueue = \(taskQueue)")
        return true
    }

    /// 通过key移除一组任务
    func removeTasks(keys: [String]) {
        keys.forEach {
            removeTask(key: $0)
        }
    }

    /// 移除任务
    @discardableResult
    func removeTask(guideTask: GuideTask) -> Bool {
        taskRemoveLock.lock()
        defer { taskRemoveLock.unlock() }

        // 判断是否存在
        guard let taskIndex = taskQueue.firstIndex(where: { $0.key == guideTask.key }) else {
            return false
        }
        taskQueue.remove(at: taskIndex)
        Self.logger.debug("[LarkGuide]: removeTask taskIndex = \(taskIndex), taskQueue = \(taskQueue)")
        return true
    }

    /// 如果未指定特定任务，默认执行当前队列中的第一个
    /// @params: guideKey 可指定执行某个引导任务
    /// @params: isGuideShowing 是否有guide在显示
    /// @params: taskExcutingHandler 任务执行状态回调,isShowing表示是否在显示
    func excuteGuideTaskIfNeeded(guideKey: String? = nil,
                                 isGuideShowing: Bool,
                                 taskExcutingHandler: @escaping ((_ isShowing: Bool) -> Void)) {
        /// 任务执行处理
        let taskExcuteBlock = {
            // 如果当前没有在执行的任务（当前可视区域）
            guard !isGuideShowing,
                  let firstTask = self.taskQueue.first else {
                return
            }
            /// 默认执行第一个
            var excuteTask = firstTask
            /// check是否指定移除某个guide
            if let guideKey = guideKey,
               let guideTask = self.taskQueue.first(where: {
                    $0.key == guideKey
               }) {
                excuteTask = guideTask
            }
            // excute first task in queue
            taskExcutingHandler(true)
            // refresh current showing guide
            self.currShowingGuideKey = excuteTask.key
            if let willAppearHandler = excuteTask.willAppearHandler {
                willAppearHandler(excuteTask.key)
                Self.logger.debug("[LarkGuide]: guide task willAppearHanlder called",
                                             additionalData: [
                                                "guideKey": "\(excuteTask.key)"
                                             ])
            }
            self.taskManagerDelegate?.onExcuteGuideTask(guideTask: excuteTask, finishHandler: {
                taskExcutingHandler(false)
                self.currShowingGuideKey = nil
            })
            // excute didAppearHandler
            if let didAppearHandler = excuteTask.didAppearHandler {
                didAppearHandler(excuteTask.key)
            }
            // when guide is showing, remove it from the queue.
            if self.taskQueue.count > 0 {
                self.taskQueue.remove(at: 0)
                Self.logger.debug("[LarkGuide]: taskQueue begin remove first task, taskQueue = \(self.taskQueue)")
            }
        }

        Self.logger.debug("[LarkGuide]: excuteGuideTask",
                                      additionalData: [
                                        "isGuideShowing": "\(isGuideShowing)",
                                        "taskQueue": "\(taskQueue)",
                                        "guideKey": "\(String(describing: guideKey))"
        ])

        /// 执行任务
        if !Thread.current.isMainThread {
            DispatchQueue.main.async {
                taskExcuteBlock()
            }
            Self.logger.debug("[LarkGuide]: excuting Task not in main thread!! taskQueue = \(taskQueue)")
        } else {
            taskExcuteBlock()
        }
    }

    /// 移除队列中指定的key任务
    func removeTasksInQueueByKeys(removeKeys: [String]) {
        Self.logger.debug("[LarkGuide]: removeTasksInQueue",
                                      additionalData: [
                                        "removeKeys": "\(removeKeys)",
                                        "taskQueue": "\(taskQueue)"
        ])

        let _taskQueue = self.taskQueue.getImmutableCopy()
        _taskQueue.forEach { (task) in
            if let index = self.taskQueue.firstIndex(where: { _ in removeKeys.contains(task.key) }) {
                self.taskQueue.remove(at: index)
            }
        }
    }
}

// MARK: - Util

extension GuideTaskManager {
    // 根据优先级，获取插入任务在队列的位置
    func getTaskIndex(priority: Int) -> Int {
        var index = 0
        taskQueue.map { $0.priority }.forEach {
            if $0 > priority {
                index += 1
            }
        }
        return index
    }
}
