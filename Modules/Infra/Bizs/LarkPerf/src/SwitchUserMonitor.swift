//
//  SwitchUserMonitor.swift
//  LarkPerf
//
//  Created by Miaoqi Wang on 2020/2/17.
//

import UIKit
import Foundation
import LKCommonsLogging
import LKCommonsTracker

private let switchUserMonitorName = "switch_user"

/// https://bytedance.feishu.cn/docs/doccnNonVlgv3xvGVP0GmD0Golc#
public final class SwitchUserMonitor {

    static let logger = Logger.log(SwitchUserMonitor.self, category: "switchUser.monitor")

    /// instance
    public static let shared = SwitchUserMonitor()
    private var queue: DispatchQueue = DispatchQueue(label: "switchUser.monitor", qos: .utility)

    private var metricTimeDic: [MetricKey: String] = [:]
    private var startTimeDic: [MetricKey: CFTimeInterval] = [:]
    private var customMetricTimeDic: [String: String] = [:]
    private var customStartTimeDic: [String: CFTimeInterval] = [:]
    private var extraDic: [ExtraKey: String] = [:]

    private var isRedirect: Bool = false
    private var isVerify: Bool { steps.contains(.verify) }
    private var isFastSwitch: Bool { steps.contains(.fastSwitch) }
    private var endType: EndType {
        return .mainRender
    }

    private var steps: SwitchUserStep = .none

    /// update  step
    public func update(step: SwitchUserStep) {
        let time = CACurrentMediaTime()
        queue.async {
            if step == .startSwitch {
                // new process clean data
                self.cleanData()
            }
            if step == .loadFinish {
                self.end(key: .toLoadingFinish, endTime: time)
            }
            if step == .feedShow {
                self.end(key: .toFeed, endTime: time)
            }
            self.steps = self.steps.union(step)
            if self.steps.contains([.feedShow, .feedLoadSuccess, .loadFinish])
                || self.steps.contains([.feedShow, .feedLoadFail, .loadFinish]) {
                self.end(key: .toMainRender, endTime: time)
                self.end(key: .switchUser, endTime: time)
            }
        }
    }

    private var verifySwitchUserStatusTime: CFTimeInterval = 0.0

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
            if key == .switchEnvSetDeviceId {
                self.isRedirect = true
            }
            self.startTimeDic[key] = startTime
        }
    }

    private func end(key: MetricKey, endTime: CFTimeInterval) {
        queue.async {
            if !self.didStart { return }
            if self.metricTimeDic[key] != nil { return }
            if let startTime = self.startTimeDic[key] {
                var time = (endTime - startTime) * 1_000
                if key == .verifySwitchUserStatus {
                    self.verifySwitchUserStatusTime = time
                } else if key == .switchUser || key == .toLoadingFinish || key == .toFeed {
                    time += self.verifySwitchUserStatusTime
                }
                self.metricTimeDic[key] = "\(time)"
            }
            if key == .switchUser {
                self.upload()
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

    var didStart: Bool {
        return startTimeDic[.switchUser] != nil
    }
}

extension SwitchUserMonitor {

    private func upload() {
        guard metricTimeDic[.switchUser] != nil else {
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
            name: switchUserMonitorName,
            metric: metric,
            category: [
                CategoryKey.endType: endType.rawValue,
                CategoryKey.isRedirect: "\(isRedirect)",
                CategoryKey.isVerify: "\(isVerify)",
                CategoryKey.isFastSwitch: "\(isFastSwitch)"
            ],
            extra: extra)
        )
        SwitchUserMonitor.logger.info("""
            switch user metric: \(metric) \
            isRedirect: \(isRedirect) \
            isVerify: \(isVerify) \
            isFastSwitch: \(isFastSwitch)
            extra: \(extra)
            """
        )
        cleanData()
    }

    private func cleanData() {
        metricTimeDic = [:]
        startTimeDic = [:]
        customMetricTimeDic = [:]
        customStartTimeDic = [:]
        extraDic = [:]
        isRedirect = false
        steps = .none
        verifySwitchUserStatusTime = 0.0
    }
}

extension SwitchUserMonitor {
    public enum MetricKey: String {
        case verifySwitchUserStatus = "begin_verify_switch_user_status"
        case switchUser = "begin_switch_to_main_render"
        case toFeed = "begin_switch_to_feed"
        case toLoadingFinish = "begin_switch_to_loading_finish"
        case switchEnvSetDeviceId = "begin_switch_to_set_redirect_device_id"
        case switchUserRequest = "switch_user"
        case afterSwitch = "after_switch"
        case toGetOnboarding = "after_switch_to_get_onboarding"
        case feed = "get_feed"
        case toMainRender = "get_onboarding_to_main_render"
    }

    public enum ExtraKey: String {
        case fromUserId = "user_id"
        case toUserId = "to_user_id"
    }

    enum EndType: String {
        case mainRender = "main_render"
    }

    enum CategoryKey {
        static let isRedirect = "is_redirect"
        static let isVerify = "is_verify"
        static let endType = "end_type"
        static let isFastSwitch = "is_fast_switch"
    }

    public struct SwitchUserStep: OptionSet {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        // equal to SwitchUserStep(rawValue: 0), fix wanring for swift5.2
        public static let none = SwitchUserStep([])
        public static let verify = SwitchUserStep(rawValue: 1)
        public static let loadFinish = SwitchUserStep(rawValue: 1 << 1)
        public static let feedShow = SwitchUserStep(rawValue: 1 << 2)
        public static let feedLoadSuccess = SwitchUserStep(rawValue: 1 << 3)
        public static let feedLoadFail = SwitchUserStep(rawValue: 1 << 4)
        public static let startSwitch = SwitchUserStep(rawValue: 1 << 5)
        public static let fastSwitch = SwitchUserStep(rawValue: 1 << 6)
    }

}
