//
//  LarkDowngradeTask.swift
//  LarkDowngrade
//
//  Created by sniperYJ on 2023/9/1.
//

import Foundation
import UIKit
import LKCommonsLogging


public enum LarkUniversalDowngradeTaskStatus {
    case normal(Bool) ///is normal status bool value means whether change status if is true means upgrade
    case downgraded(Bool) ///is downgrade status is bool value is true means downgrade
    case error(String)
}

public typealias UniversalDowngradeAction = ([String: Any?]?) -> Void

public class LarkUniversalDowngradeTask {
    static var logger = Logger.log(LarkUniversalDowngradeTask.self)
    public var key: String
    public var needConsecutive = false
    public var status: LarkUniversalDowngradeTaskStatus = .normal(false)
    public var doDowngrade: UniversalDowngradeAction = { status in }
    public var doNormal: UniversalDowngradeAction = { status in }
    public var allMeetStrategyList: [LarkUniversalDowngradeStrategy]?
    public var oneOfStrategyList: [LarkUniversalDowngradeStrategy]?
    public var timeInterval: UInt64 = UINT64_MAX
    public let timeStamp = CACurrentMediaTime()
    /// downgrade ignore count
    private var ignoreCount: UInt64 = 0
    private var maxIgnoreTime = 60

    init(key: String) {
        self.key = key
    }

    /// start handle task
    /// - Parameter effectRules: Rules that are already in effect
    /// - Returns:  current task status && current effect rules
    public func handleDowngradeOrUpgreade(effectRules: Set<String>) -> (LarkUniversalDowngradeTaskStatus, Set<String>?) {
        if !judgeRuleAvailable() {
            self.status = .error("\(self) allMeetList && one of MeetList conflict")
            return (self.status, nil)
        }
        var effectRules = effectRules
        if ignoreCount * timeInterval >= maxIgnoreTime {
            effectRules.removeAll()
        }
        if needConsecutive {
            let res = handleNormalStatus(effectRules: effectRules)
            switch res.0 {
            case .normal(_):
                return handleDowngradeStatus(effectRules: effectRules)
            case .downgraded(_),
                    .error(_):
                return res
            }
        } else {
            switch self.status {
            case .normal(_):
                return handleNormalStatus(effectRules: effectRules)
            case .downgraded(_):
                return handleDowngradeStatus(effectRules: effectRules)
            case let .error(errorString):
                self.status = .error(errorString)
                return (self.status, nil)
            }
        }
    }

    public func updatePrivateDataIfNeed() {
        if let allMeetStrategys = allMeetStrategyList {
            for strategy in allMeetStrategys {
                if let performanceStrategy = strategy as? LarkPerformanceStrategy {
                    performanceStrategy.updatePrivateDataIfNeeded()
                }
            }
        }
        if let oneOfStrategyList = oneOfStrategyList {
            for strategy in oneOfStrategyList {
                if let performanceStrategy = strategy as? LarkPerformanceStrategy {
                    performanceStrategy.updatePrivateDataIfNeeded()
                }
            }
        }
    }

    public func clearPrivateDataIfNeed() {
        if let allMeetStrategys = allMeetStrategyList {
            for strategy in allMeetStrategys {
                if let performanceStrategy = strategy as? LarkPerformanceStrategy {
                    performanceStrategy.clearPrivateDataIfNeeded()
                }
            }
        }
        if let oneOfStrategyList = oneOfStrategyList {
            for strategy in oneOfStrategyList {
                if let performanceStrategy = strategy as? LarkPerformanceStrategy {
                    performanceStrategy.clearPrivateDataIfNeeded()
                }
            }
        }
    }

    private func handleNormalStatus(effectRules: Set<String>) -> (LarkUniversalDowngradeTaskStatus, Set<String>?) {
        if let allMeetStrategys = allMeetStrategyList {
            return processNormalAllMeetStrategy(effectRules: effectRules, allMeetStrategys: allMeetStrategys)
        }
        if let oneOfStrategyList = oneOfStrategyList {
            return processNormalOneOfStrategy(effectRules: effectRules, oneOfStrategyList: oneOfStrategyList)
        }
        self.status = .error("\(self) allMeetList && one of MeetList all nil")
        return (self.status, nil)
    }

    private func processNormalAllMeetStrategy(effectRules: Set<String>,
                                              allMeetStrategys: [LarkUniversalDowngradeStrategy]) -> (LarkUniversalDowngradeTaskStatus, Set<String>?) {
        var currentEffectRules: Set<String> = []
        var callbackData: [String: Any?] = [:]
        for strategy in allMeetStrategys {
            let res = strategy.shouldDowngrade(effectRules: effectRules)
            switch res.0 {
            case let .normal(isDowngrade):
                if isDowngrade.0 {
                    if let tempRules = res.1 {
                        callbackData[strategy.strategyKey] = isDowngrade.1
                        currentEffectRules = currentEffectRules.union(tempRules)
                    }
                } else {
                    self.status = .normal(false)
                    return (self.status, nil)
                }
            case let .error(errorString):
                self.status = .error(errorString)
                return (self.status, nil)
            case .ignore:
                ignoreCount = ignoreCount + 1
                self.status = .normal(false)
                return (self.status, nil)
            }
        }
        doDowngrade(callbackData)
        ignoreCount = 0
        self.status = .downgraded(true)
        return (self.status, currentEffectRules)
    }

    private func processNormalOneOfStrategy(effectRules: Set<String>,
                                            oneOfStrategyList: [LarkUniversalDowngradeStrategy]) -> (LarkUniversalDowngradeTaskStatus, Set<String>?) {
        var isIgnore = false
        var callbackData: [String: Any?] = [:]
        for strategy in oneOfStrategyList {
            let res = strategy.shouldDowngrade(effectRules: effectRules)
            switch res.0 {
            case let .normal(isDowngrade):
                if isDowngrade.0 {
                    if let tempRules = res.1 {
                        callbackData[strategy.strategyKey] = isDowngrade.1
                        ignoreCount = 0
                        doDowngrade(callbackData)
                        self.status = .downgraded(true)
                        return (self.status, tempRules)
                    } else {
                        self.status = .error("\(self) effectRules error")
                        return (self.status, nil)
                    }
                }
            case let .error(errorString):
                LarkUniversalDowngradeTask.logger.error(errorString)
                break
            case .ignore:
                isIgnore = true
                break
            }
        }
        if isIgnore {
            ignoreCount += 1
        }
        self.status = .normal(false)
        return (self.status, nil)
    }

    private func handleDowngradeStatus(effectRules: Set<String>) -> (LarkUniversalDowngradeTaskStatus, Set<String>?) {
        if let oneOfStrategyList = oneOfStrategyList {
            return processDowngradeOneOfStrategy(effectRules: effectRules, oneOfStrategyList: oneOfStrategyList)
        }

        if let allMeetStrategys = allMeetStrategyList {
            return processDowngradeAllMeetStrategy(effectRules: effectRules, allMeetStrategys: allMeetStrategys)
        }
        self.status = .error("\(self) allMeetList && one of MeetList all nil")
        return (self.status, nil)
    }

    private func processDowngradeAllMeetStrategy(effectRules: Set<String>,
                                                 allMeetStrategys: [LarkUniversalDowngradeStrategy]) -> (LarkUniversalDowngradeTaskStatus, Set<String>?) {
        var isIgnore = false
        var callbackData: [String: Any?] = [:]
        for strategy in allMeetStrategys {
            let res = strategy.shouldUpgrade(effectRules: effectRules)
            switch res.0 {
            case let .normal(isUpgrade):
                if isUpgrade.0 {
                    if let tempRules = res.1 {
                        callbackData[strategy.strategyKey] = isUpgrade.1
                        doNormal(callbackData)
                        ignoreCount = 0
                        self.status = .normal(true)
                        return (self.status, tempRules)
                    } else {
                        self.status = .error("\(self) effectRules error")
                        return (self.status, nil)
                    }
                }
            case .ignore:
                isIgnore = true
                break
            case let .error(errorString):
                LarkUniversalDowngradeTask.logger.error(errorString)
                break
            }
        }
        if isIgnore {
            ignoreCount += 1
        }
        self.status = .downgraded(false)
        return (self.status, nil)
    }

    private func processDowngradeOneOfStrategy(effectRules: Set<String>,
                                               oneOfStrategyList: [LarkUniversalDowngradeStrategy]) -> (LarkUniversalDowngradeTaskStatus, Set<String>?) {
        var currentEffectRules: Set<String> = []
        var callbackData: [String: Any?] = [:]
        for strategy in oneOfStrategyList {
            let res = strategy.shouldUpgrade(effectRules: effectRules)
            switch res.0 {
            case let .normal(isUpgrade):
                if isUpgrade.0 {
                    if let tempRules = res.1 {
                        callbackData[strategy.strategyKey] = isUpgrade.1
                        currentEffectRules = currentEffectRules.union(tempRules)
                    }
                } else {
                    self.status = .downgraded(false)
                    return (self.status, nil)
                }
            case .ignore:
                ignoreCount = ignoreCount + 1
                self.status = .downgraded(false)
                return (self.status, nil)
            case let .error(errorString):
                self.status = .error(errorString)
                return (self.status, nil)
            }
        }
        doNormal(callbackData)
        ignoreCount = 0
        self.status = .normal(true)
        return (self.status, currentEffectRules)
    }

    private func judgeRuleAvailable() -> Bool {
        if allMeetStrategyList == nil,
           oneOfStrategyList == nil {
            assertionFailure("allMeetStrategyList and OneOfStrategyList all nil")
            return false
        }
        if let _ = allMeetStrategyList,
           let _ = oneOfStrategyList {
            assertionFailure("allMeetStrategyList or OneOfStrategyList just have one")
            return false
        }
        return true
    }
}
