//
//  SwitchUserUnifyMonitor.swift
//  LarkPerf
//
//  Created by tangyunfei.tyf on 2020/3/19.
//

import UIKit
import Foundation
import LKCommonsLogging
import LKCommonsTracker
import AppContainer

private let switchUserUnifyMonitorName = "switch_user_time"

public final class SwitchUserUnifyMonitor: NSObject {

    static let logger = Logger.log(SwitchUserUnifyMonitor.self, category: "SwitchUserUnify.monitor")

    /// instance
    public static let shared = SwitchUserUnifyMonitor()
    private var queue: DispatchQueue = DispatchQueue(label: "SwitchUserUnify.monitor", qos: .utility)

    private var metricTimeDic: [MetricKey: String] = [:]
    private var startTimeDic: [MetricKey: CFTimeInterval] = [:]
    private var customMetricTimeDic: [String: String] = [:]
    private var customStartTimeDic: [String: CFTimeInterval] = [:]
    private var extraDic: [ExtraKey: String] = [:]

    private var fastSwitch: Bool = false
    private var crossEnv: Bool = false
    private var switchFailed: Bool = false
    private var promptSwitch: Bool = false

    private var steps: SwitchUserUnifyStep = .none

    private var contextId: String = ""

    override init() {
        super.init()
        self.refreshContextId()
    }

    /// update  step
    public func update(step: SwitchUserUnifyStep) {
        queue.async {
            switch step {
            case .confirmSwitchCost:
                self.cleanData()
            case .fastSwitch:
                self.fastSwitch = true
            case .crossEnv:
                self.crossEnv = true
            case .switchFailed:
                self.switchFailed = true
                self.end(key: .switchUserFinish)
            case .promptSwitch:
                self.promptSwitch = true
            case .renderFeedCost:
                self.end(key: .renderFeedCost)
            default:
                break
            }

            self.steps = self.steps.union(step)
            if self.steps.contains([.confirmSwitchCost, .renderFeedCost]) {
                self.end(key: .switchUserFinish)
            }
        }
    }

    /// start  metrics
    public func start(key: MetricKey) {
        let startTime = CACurrentMediaTime()
        start(key: key, startTime: startTime)
    }

    /// end  metrics
    public func end(key: MetricKey) {
        let endTime = CACurrentMediaTime()
        end(key: key, endTime: endTime)
    }

    /// start custom mertics
    public func start(customKey: String) {
        let startTime = CACurrentMediaTime()
        start(customKey: customKey, startTime: startTime)
    }

    /// end  custom metrics
    public func end(customKey: String) {
        let endTime = CACurrentMediaTime()
        end(customKey: customKey, endTime: endTime)
    }

    /// set extra info
    public func setExtra(key: ExtraKey, value: String) {
        queue.async {
            if !self.didStart { return }
            self.extraDic[key] = value
        }
    }

    private func start(key: MetricKey, startTime: CFTimeInterval) {
        queue.async {
            if self.startTimeDic[key] != nil { return }
            self.startTimeDic[key] = startTime

            ClientPerf.shared.startEvent(key.rawValue, time: startTime, parentContext: self.contextId)
        }
    }

    private func end(key: MetricKey, endTime: CFTimeInterval) {
        queue.async {
            if !self.didStart { return }
            if self.metricTimeDic[key] != nil { return }
            if let startTime = self.startTimeDic[key] {
                let time = (endTime - startTime) * 1_000
                self.metricTimeDic[key] = "\(time)"
            }
            ClientPerf.shared.endEvent(key.rawValue, time: endTime, parentContext: self.contextId)
            if key == .switchUserFinish {
                self.upload()
                self.refreshContextId()
            }
        }
    }

    private func start(customKey: String, startTime: CFTimeInterval) {
        queue.async {
            if self.customStartTimeDic[customKey] != nil { return }
            self.customStartTimeDic[customKey] = startTime
        }
    }

    private func end(customKey: String, endTime: CFTimeInterval) {
        queue.async {
            if !self.didStart { return }
            if self.customMetricTimeDic[customKey] != nil { return }
            if let startTime = self.customStartTimeDic[customKey] {
                self.customMetricTimeDic[customKey] = "\((endTime - startTime) * 1_000)"
            }
        }
    }

    private func refreshContextId() {
        self.contextId = ContextIdGenerator.generate()
    }

    var didStart: Bool {
        return startTimeDic[.confirmSwitchCost] != nil
    }
}

extension SwitchUserUnifyMonitor {

    private func upload() {
        guard metricTimeDic[.confirmSwitchCost] != nil else {
            assertionFailure()
            return
        }
        var metric: [String: String] = metricTimeDic.reduce([String: String]()) { (result, arg) -> [String: String] in
            let (key, value) = arg
            var result = result
            result[key.rawValue] = value
            return result
        }
        metric.merge(customMetricTimeDic, uniquingKeysWith: { (current, _) in current })

        let extra: [String: String] = extraDic.reduce([String: String]()) { (result, arg) -> [String: String] in
            let (key, value) = arg
            var result = result
            result[key.rawValue] = value
            return result
        }

        Tracker.post(SlardarEvent(
            name: switchUserUnifyMonitorName,
            metric: metric,
            category: [
                CategoryKey.fastSwitch: "\(fastSwitch)",
                CategoryKey.crossEnv: "\(crossEnv)",
                CategoryKey.switchFailed: "\(switchFailed)",
                CategoryKey.promptSwitch: "\(promptSwitch)"
            ],
            extra: extra)
        )
        SwitchUserUnifyMonitor.logger.info("switch user metric: \(metric) crossEnv: \(crossEnv) isFastSwitch: \(fastSwitch) extra: \(extra)")
        cleanData()
    }

    private func cleanData() {
        metricTimeDic = [:]
        startTimeDic = [:]
        customMetricTimeDic = [:]
        customStartTimeDic = [:]
        extraDic = [:]
        fastSwitch = false
        crossEnv = false
        switchFailed = false
        promptSwitch = false
        steps = .none
    }
}

extension SwitchUserUnifyMonitor {
    public enum MetricKey: String {
        case confirmSwitchCost = "confirm_switch_cost"
        case sdkSwitchUser = "sdk_switch_user"
        case clearDataCost = "clear_data_cost"
        case sdkGetFeedCardsV2 = "sdk_get_feed_cards_v2"
        case renderAppShellCost = "render_app_shell_cost"
        case renderFeedCost = "render_feed_cost"
        case initSettingDataCost = "init_setting_data_cost"
        case switchUserFinish = "switch_user_finish"
        case fastSwitch = "fast_switch"
        case crossEnv = "cross_env"
        case switchFailed = "switch_failed"
        case promptSwitch = "prompt_switch"
    }

    public enum ExtraKey: String {
        case fromUserId = "user_id"
        case toUserId = "to_user_id"
    }

    enum CategoryKey {
        static let fastSwitch = "fast_switch"
        static let crossEnv = "cross_env"
        static let switchFailed = "switch_failed"
        static let promptSwitch = "prompt_switch"
    }

    public struct SwitchUserUnifyStep: OptionSet {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        // equal to SwitchUserUnifyStep(rawValue: 0), fix wanring for swift5.2
        public static let none = SwitchUserUnifyStep([])
        public static let confirmSwitchCost = SwitchUserUnifyStep(rawValue: 1 << 1)
        public static let fastSwitch = SwitchUserUnifyStep(rawValue: 1 << 2)
        public static let crossEnv = SwitchUserUnifyStep(rawValue: 1 << 2)
        public static let switchFailed = SwitchUserUnifyStep(rawValue: 1 << 2)
        public static let promptSwitch = SwitchUserUnifyStep(rawValue: 1 << 2)
        public static let sdkSwitchUser = SwitchUserUnifyStep(rawValue: 1 << 3)
        public static let clearDataCost = SwitchUserUnifyStep(rawValue: 1 << 4)
        public static let sdkGetFeedCardsV2 = SwitchUserUnifyStep(rawValue: 1 << 5)
        public static let renderAppShellCost = SwitchUserUnifyStep(rawValue: 1 << 6)
        public static let renderFeedCost = SwitchUserUnifyStep(rawValue: 1 << 7)
        public static let initSettingDataCost = SwitchUserUnifyStep(rawValue: 1 << 8)
        public static let switchUserFinish = SwitchUserUnifyStep(rawValue: 1 << 9)
    }

}

final class ContextIdGenerator {
    static func generate() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0...9).map { _ in letters.randomElement()! })
    }
}
