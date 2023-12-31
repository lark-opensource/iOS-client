//
//  ResetTaskManager.swift
//  LarkSettingsBundle
//
//  Created by Miaoqi Wang on 2020/3/27.
//

import Foundation
import LKCommonsLogging

public final class ResetTaskManager {
    static let shared = ResetTaskManager()
    static let logger = Logger.log(ResetTaskManager.self, category: "Module.SettingsBundle")

    var tasks: [Priority: [ResetTask]] = [:]
    let taskQueue: DispatchQueue = DispatchQueue(label: "com.lark.settingsBundle.resetTask")

    class func reset(complete: @escaping () -> Void) {
        let resetOrder: [Priority] = [.high, .default, .low]

        func orderReset(orderIndex: Int = 0) {
            guard orderIndex < resetOrder.count else {
                complete()
                return
            }
            let priority = resetOrder[orderIndex]
            guard let tasks = shared.tasks[priority] else {
                orderReset(orderIndex: orderIndex + 1)
                return
            }
            logger.debug("order reset start", additionalData: ["priority": "\(priority)", "count": "\(tasks.count)"])
            let group = DispatchGroup()
            tasks.forEach({ (task) in
                group.enter()
                task {
                    group.leave()
                }
            })
            group.notify(queue: shared.taskQueue) {
                logger.debug("order reset task complete", additionalData: ["priority": "\(priority)"])
                orderReset(orderIndex: orderIndex + 1)
            }
        }

        shared.taskQueue.async {
            orderReset()
        }
    }
}

// MARK: - public
extension ResetTaskManager {

    /// Register reset work
    /// - Parameter priority: high priority first
    /// - Parameter task: reset work whose complete closure `MUST` be called
    public class func register(priority: Priority = .default, task: @escaping ResetTask) {
        shared.taskQueue.async {
            if shared.tasks[priority] == nil {
                shared.tasks[priority] = [task]
            } else {
                shared.tasks[priority]?.append(task)
            }
        }
    }
}

// MARK: - type
extension ResetTaskManager {
    /// Reset task call complete when done
    /// - Parameter complete: complete callback `MUST` be called
    public typealias ResetTask = (_ complete: @escaping () -> Void) -> Void

    public enum Priority: Int {
        case low = 250
        case `default` = 500
        case high = 750
    }
}
