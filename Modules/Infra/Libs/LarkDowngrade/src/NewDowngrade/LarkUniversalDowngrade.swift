//
//  LarkUniversalDowngradeService.swift
//  Lark
//
//  Created by SniperYJ on 2023/9/10.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LKCommonsTracker
import LKCommonsLogging
import EEAtomic

class LarkUniversalDowngradeUtility {
    static private var uploadedKey: [String: String] = [:]
    static private var unfairLock = os_unfair_lock_s()
    static func uploadDowngradeTask(key: String, isDynamic: Bool) {
        os_unfair_lock_lock(&unfairLock); defer { os_unfair_lock_unlock(&unfairLock) }
        if (uploadedKey[key] == nil) {
            let startEvent = TeaEvent("universal_downgrade_event", params: ["task": key, "type": isDynamic ? "dymanicDowngrade": "staticDowngrade"])
            Tracker.post(startEvent)
            uploadedKey[key] = key
        }
    }

    static func uploadUpgradeTask(key: String) {
        os_unfair_lock_lock(&unfairLock); defer { os_unfair_lock_unlock(&unfairLock) }
        if (uploadedKey[key] == nil) {
            let startEvent = TeaEvent("universal_downgrade_event", params: ["task": key, "type": "dynamicUpgrade"])
            Tracker.post(startEvent)
            uploadedKey[key] = key
        }
    }
}

public class LarkUniversalDowngradeService {
    static var logger = Logger.log(LarkUniversalDowngradeService.self)
    public static let shared = LarkUniversalDowngradeService()
    public var config: LarkUniversalDowngradeConfig = LarkUniversalDowngradeConfig()
    public var deviceScore: Double = 100

    private var downgradeTaskManager: LarkUniversalDowngradeTaskManager
    private let downgradeProcessQueue: DispatchQueue = DispatchQueue(label: "com.lark.downgradeCheck")
    private let downgradeOnce = AtomicOnce()
    private var timer: DispatchSourceTimer?

    //MARK: - interface
    /// Quickly create  performance downgrade tasks
    /// LarkUniversalDowngradeService.shared.staticDowngrade(key: "testTask", strategies: .overCPU() |&| .overDeviceCPU()
    /// - Parameters:
    ///   - key: key
    ///   - strategies: performanceStrategytype
    ///   - doDowngrade: downgrade action
    ///   - doNormal: nornal action
    public func staticDowngrade(key: String,
                                strategies: [String: LarkPerformanceStrategyType],
                                doDowngrade: UniversalDowngradeAction,
                                doNormal: UniversalDowngradeAction) {
        guard isDowngradeStrategyAvailable(key: key) else {
            doNormal(nil)
            return
        }
        var performanceRules: [String: LarkUniversalDowngradeRule] = [:]
        strategies.values.forEach { performanceType in
            performanceRules[performanceType.getKey()] = performanceType.getPerformanceRule()
        }
        staticDowngrade(key: key, strategies: [LarkPerformanceStrategy(strategyKey: "LarkPerformanceCustomStrategy", strategys: performanceRules)], doDowngrade: doDowngrade, doNormal: doNormal)
    }

    /// Refer to the previous method
    /// LarkUniversalDowngradeService.shared.staticDowngrade(key: "testTask", strategies: .overCPU() ||| .overDeviceCPU()
    /// - Parameters:
    ///   - key: Refer to the previous method
    ///   - strategies: Refer to the previous method
    ///   - doDowngrade: Refer to the previous method
    ///   - doNormal: Refer to the previous method
    public func staticDowngrade(key: String,
                                strategies: [LarkPerformanceStrategyType],
                                doDowngrade: UniversalDowngradeAction,
                                doNormal: UniversalDowngradeAction) {
        guard isDowngradeStrategyAvailable(key: key) else {
            doNormal(nil)
            return
        }
        var performanceRules: [LarkUniversalDowngradeRule] = []
        strategies.forEach { performanceType in
            performanceRules.append(performanceType.getPerformanceRule())
        }
        staticDowngrade(key: key, strategies: [LarkPerformanceStrategy(strategyKey: "LarkPerformanceCustomStrategy", strategys: performanceRules)], doDowngrade: doDowngrade, doNormal: doNormal)
    }

    public func dynamicDowngrade(key: String,
                                 needConsecutive: Bool = false,
                                 strategies: [String: LarkPerformanceStrategyType],
                                 timeInterval: UInt64 = 2,
                                 doDowngrade: @escaping UniversalDowngradeAction,
                                 doNormal: @escaping UniversalDowngradeAction) {
        guard isDowngradeStrategyAvailable(key: key) else { return }
        guard !isDowngradeTaskInTaskManager(key: key) else { return }
        var performanceRules: [String: LarkUniversalDowngradeRule] = [:]
        strategies.values.forEach { performanceType in
            performanceRules[performanceType.getKey()] = performanceType.getPerformanceRule()
        }
        dynamicDowngrade(key: key, needConsecutive: needConsecutive, strategies: [LarkPerformanceStrategy(strategyKey: "LarkPerformanceCustomStrategy", strategys: performanceRules)], timeInterval: timeInterval, doDowngrade: doDowngrade, doNormal: doNormal)
    }

    public func dynamicDowngrade(key: String,
                                 needConsecutive: Bool = false,
                                 strategies: [LarkPerformanceStrategyType],
                                 timeInterval: UInt64 = 2,
                                 doDowngrade: @escaping UniversalDowngradeAction,
                                 doNormal: @escaping UniversalDowngradeAction) {
        guard isDowngradeStrategyAvailable(key: key) else { return }
        guard !isDowngradeTaskInTaskManager(key: key) else { return }
        var performanceRules: [LarkUniversalDowngradeRule] = []
        strategies.forEach { performanceType in
            performanceRules.append(performanceType.getPerformanceRule())
        }
        dynamicDowngrade(key: key, needConsecutive: needConsecutive, strategies: [LarkPerformanceStrategy(strategyKey: "LarkPerformanceCustomStrategy", strategys: performanceRules)], timeInterval: timeInterval, doDowngrade: doDowngrade, doNormal: doNormal)
    }

    /// static downgrade method Used when strategies are combined in ‘|&|’
    /// LarkUinversalDowngradeService.shared.staticDowngrade(key: 'xxx', strategies: strategy1 |&| strategy2 |&| strategy3, doNomal: ....)
    /// - Parameters:
    ///   - key: downgrade identify key
    ///   - strategies: this strategies is combined in '&'
    ///   - doDowngrade: downgrade action
    ///   - doNormal: normal action
    public func staticDowngrade(key: String,
                                strategies: [String: LarkUniversalDowngradeStrategy],
                                doDowngrade: UniversalDowngradeAction,
                                doNormal: UniversalDowngradeAction) {
        guard isDowngradeStrategyAvailable(key: key) else {
            doNormal(nil)
            return
        }
        LarkUniversalDowngradeService.logger.info("start staticDowngrade key \(key)")
        var callbackData: [String: Any?] = [:]
        strategies.values.forEach { strategy in
            let res = strategy.shouldDowngrade(effectRules: nil)
            if case let .normal((isDowngrade, resData)) = res.0 {
                if !isDowngrade {
                    doNormal(nil)
                    return
                } else {
                    callbackData[strategy.strategyKey] = resData
                }
            }
        }
        doDowngrade(callbackData)
        LarkUniversalDowngradeUtility.uploadDowngradeTask(key: key, isDynamic: false)
    }

    /// static downgrade method Used when strategies are combined in ‘|||’
    ///  LarkUinversalDowngradeService.shared.staticDowngrade(key: 'xxx', strategies: strategy1 ||| strategy2 ||| strategy3, doNomal: ....)
    /// - Parameters:
    ///   - key: key
    ///   - strategies: this strategies is combined in '|'
    ///   - doDowngrade: downgrade action
    ///   - doNormal: normal action
    public func staticDowngrade(key: String,
                                strategies: [LarkUniversalDowngradeStrategy],
                                doDowngrade: UniversalDowngradeAction,
                                doNormal: UniversalDowngradeAction) {
        guard isDowngradeStrategyAvailable(key: key) else {
            doNormal(nil)
            return
        }
        LarkUniversalDowngradeService.logger.info("start staticDowngrade key \(key)")
        strategies.forEach { strategy in
            let res = strategy.shouldDowngrade(effectRules: nil)
            if case let .normal((isDowngrade, resData)) = res.0 {
                if isDowngrade {
                    doDowngrade([strategy.strategyKey: resData])
                    LarkUniversalDowngradeUtility.uploadDowngradeTask(key: key, isDynamic: false)
                    return
                }
            }
        }
        doNormal(nil)
    }

    /// dynamic downgrade used when strategies are combind in '|||'
    /// - Parameters:
    ///   - key: key
    ///   - strategies: this strategies is combined in '|||'
    ///   - timeInterval: dynamic check strategy is should downgrade's timeinterval
    ///   - doDowngrade: downgrade action
    ///   - doNormal: upgrade action
    public func dynamicDowngrade(key: String,
                                 needConsecutive: Bool = false,
                                 strategies: [LarkUniversalDowngradeStrategy],
                                 timeInterval: UInt64 = 2,
                                 doDowngrade: @escaping UniversalDowngradeAction,
                                 doNormal: @escaping UniversalDowngradeAction) {
        guard isDowngradeStrategyAvailable(key: key) else { return }
        guard !isDowngradeTaskInTaskManager(key: key) else { return }
        LarkUniversalDowngradeService.logger.info("start dynamicDowngrade key \(key)")
        let task = LarkUniversalDowngradeTask(key: key)
        task.oneOfStrategyList = strategies
        task.needConsecutive = needConsecutive
        task.doNormal = doNormal
        task.doDowngrade = doDowngrade
        task.timeInterval = timeInterval
        self.downgradeTaskManager.addTask(task: task)
        startTimer()
    }

    /// Refer to the previous method
    /// - Parameters:
    ///   - key: key
    ///   - strategys: this strategies is combined in '|&|'
    ///   - timeInterval: Refer to the previous method
    ///   - doDowngrade: Refer to the previous method
    ///   - doNormal: Refer to the previous method
    public func dynamicDowngrade(key: String,
                                 needConsecutive: Bool = false,
                                 strategys: [String: LarkUniversalDowngradeStrategy],
                                 timeInterval: UInt64 = 2,
                                 doDowngrade: @escaping UniversalDowngradeAction,
                                 doNormal: @escaping UniversalDowngradeAction) {
        guard isDowngradeStrategyAvailable(key: key) else { return }
        guard !isDowngradeTaskInTaskManager(key: key) else { return }
        LarkUniversalDowngradeService.logger.info("start dynamicDowngrade key \(key)")
        let task = LarkUniversalDowngradeTask(key: key)
        var strategyList: [LarkUniversalDowngradeStrategy] = []
        strategys.values.forEach { strategy in
            strategyList.append(strategy)
        }
        task.allMeetStrategyList = strategyList
        task.needConsecutive = needConsecutive
        task.doNormal = doNormal
        task.doDowngrade = doDowngrade
        task.timeInterval = timeInterval
        self.downgradeTaskManager.addTask(task: task)
        startTimer()
    }

    public func removeDynamicDowngradeTask(key: String) {
        self.downgradeTaskManager.removeTask(key: key)
    }

    public func needDowngrade(key: String,
                                strategies: [LarkPerformanceStrategyType]) -> Bool {
        guard isDowngradeStrategyAvailable(key: key) else {
            return false
        }
        var performanceRules: [LarkUniversalDowngradeRule] = []
        strategies.forEach { performanceType in
            performanceRules.append(performanceType.getPerformanceRule())
        }
        return needDowngrade(key: key, strategies: [LarkPerformanceStrategy(strategyKey: "LarkPerformanceCustomStrategy", strategys: performanceRules)])
    }

    public func needDowngrade(key: String,
                                strategies: [String: LarkPerformanceStrategyType]) -> Bool {
        guard isDowngradeStrategyAvailable(key: key) else {
            return false
        }
        var performanceRules: [String: LarkUniversalDowngradeRule] = [:]
        strategies.values.forEach { performanceType in
            performanceRules[performanceType.getKey()] = performanceType.getPerformanceRule()
        }
        return needDowngrade(key: key, strategies: [LarkPerformanceStrategy(strategyKey: "LarkPerformanceCustomStrategy", strategys: performanceRules)])
    }

    public func needDowngrade(key: String,
                                strategies: [LarkUniversalDowngradeStrategy]) -> Bool {
        guard isDowngradeStrategyAvailable(key: key) else {
            return false
        }
        LarkUniversalDowngradeService.logger.info("start needDowngrade key \(key)")
        for strategy in strategies {
            let res = strategy.shouldDowngrade(effectRules: nil)
            if case let .normal((isDowngrade, _)) = res.0 {
                if isDowngrade {
                    LarkUniversalDowngradeUtility.uploadDowngradeTask(key: key, isDynamic: false)
                    return true
                }
            }
        }
        return false
    }

    public func needDowngrade(key: String,
                                strategies: [String: LarkUniversalDowngradeStrategy]) -> Bool {
        guard isDowngradeStrategyAvailable(key: key) else {
            return false
        }
        LarkUniversalDowngradeService.logger.info("start needDowngrade key \(key)")
        for strategy in strategies.values {
            let res = strategy.shouldDowngrade(effectRules: nil)
            if case let .normal((isDowngrade, _)) = res.0 {
                if !isDowngrade {
                    return false
                }
            }
        }
        LarkUniversalDowngradeUtility.uploadDowngradeTask(key: key, isDynamic: false)
        return true
    }

    //MARK: - init method
    public init(){
        self.config = LarkUniversalDowngradeConfig()
        self.downgradeTaskManager = LarkUniversalDowngradeTaskManager(downgradeConfig: self.config)
    }

    //外部更新Config
    public func updateWithDic(dictionary: [String: Any]) {
        LarkUniversalDowngradeService.logger.info("LarkUniversalDowngradeService_Config: \(String(describing: dictionary))")
        self.config.updateWithDic(dictionary: dictionary)
        self.downgradeTaskManager.updateNormalConfig(downgradeConfig: self.config)
    }
    //MARK: - private method
    private func startTimer() {
        downgradeOnce.once {
            LarkUniversalDowngradeService.logger.info("UniversalDowngradeService start timer")
            timer = DispatchSource.makeTimerSource(queue: downgradeProcessQueue)
            timer?.schedule(deadline: .now(), repeating: .seconds(1))
            timer?.setEventHandler { [weak self] in
                self?.timerFired()
            }
            timer?.resume()
        }
    }

    private func timerFired() {
        //record current time count
        self.downgradeTaskManager.processDowngradeTask(time: CACurrentMediaTime())
    }

    private func isDowngradeStrategyAvailable(key: String) -> Bool {
        if !self.config.enableDowngrade { return false }
        if !self.config.getAvailableTaskList().contains(key) {
            return false
        }
        return true
    }

    private func isDowngradeTaskInTaskManager(key: String) -> Bool {
        if self.downgradeTaskManager.downgradeList.contains(key) {
            assertionFailure("\(key) downgrade task has been registed")
            LarkUniversalDowngradeService.logger.error("\(key) downgrade task has been registed")
            return true
        }
        return false
    }
}
