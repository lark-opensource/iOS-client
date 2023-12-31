//
//  LarkUniversalDowngradeTaskManager.swift
//  LarkDowngrade
//
//  Created by SniperYJ on 2023/9/2.
//

import Foundation
import UIKit
import LKCommonsLogging
import LKCommonsTracker


public class LarkUniversalDowngradeTaskManager {
    static var logger = Logger.log(LarkUniversalDowngradeTaskManager.self)
    var downgradeList: [String] = []
    var downgradeTasks: [String: LarkUniversalDowngradeTask] = [:]
    private var unfairLock = os_unfair_lock_s()
    private var taskLock = os_unfair_lock_s()
    private var config: LarkUniversalDowngradeConfig

    func addTask(task: LarkUniversalDowngradeTask) {
        os_unfair_lock_lock(&taskLock); defer { os_unfair_lock_unlock(&taskLock) }
        self.downgradeList.append(task.key)
        self.downgradeTasks[task.key] = task
    }

    func removeTask(key: String) {
        os_unfair_lock_lock(&taskLock); defer { os_unfair_lock_unlock(&taskLock) }
        self.downgradeList.removeAll(where: {$0 != key})
        self.downgradeTasks.removeValue(forKey: key)
    }

    init(downgradeConfig: LarkUniversalDowngradeConfig) {
        self.config = downgradeConfig
    }

    public func updateNormalConfig(downgradeConfig: LarkUniversalDowngradeConfig) {
        self.config = downgradeConfig
    }

    public func processDowngradeTask(time: Double) {
        os_unfair_lock_lock(&unfairLock); defer { os_unfair_lock_unlock(&unfairLock) }
        var p_downgradedTasks: [String] = []
        var upgradedTasks: [String] = []
        var effectRules: Set<String> = []
        downgradeTasks.values.forEach { downgradeTask in
            downgradeTask.updatePrivateDataIfNeed()
            //judge task's interval is available
            if UInt64(ceil(time - downgradeTask.timeStamp)) % downgradeTask.timeInterval == 0 {
                let res = downgradeTask.handleDowngradeOrUpgreade(effectRules: effectRules)
                switch res.0 {
                case let .downgraded(statusChange):
                    if statusChange {
                        p_downgradedTasks.append(downgradeTask.key)
                        if let tempRules = res.1 {
                            effectRules = effectRules.union(tempRules)
                        }
                    }
                    break
                case let .normal(statusChange):
                    if statusChange {
                        upgradedTasks.append(downgradeTask.key)
                        if let tempRules = res.1 {
                            effectRules = effectRules.union(tempRules)
                        }
                    }
                    break
                case let .error(errorString):
                    LarkUniversalDowngradeTaskManager.logger.error(errorString)
                    break
                }
            }
        }

        for key in p_downgradedTasks {
            LarkUniversalDowngradeUtility.uploadDowngradeTask(key: key, isDynamic: true)
        }

        for key in upgradedTasks {
            LarkUniversalDowngradeUtility.uploadUpgradeTask(key: key)
        }

        LarkUniversalDowngradeTaskManager.logger.info("LarkUniversalDowngradeTaskManager processDowngrade: \(String(describing: p_downgradedTasks)) processUpgrade: \(String(describing: upgradedTasks))")
    }
}
