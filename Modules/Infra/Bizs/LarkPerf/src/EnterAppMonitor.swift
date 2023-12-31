//
//  EnterAppMonitor.swift
//  LarkPerf
//
//  Created by Yiming Qu on 2020/2/5.
//

import UIKit
import Foundation
import LKCommonsLogging
import LKCommonsTracker

/*

 feed & toMainShow end trigger mainRender end

 +------------------------------timeline-------------------------------->

 +-------+ +------------------------------------------------------------+
 |       | |                                                            |
 |       | |                       mainRender                           |
 |       | |                                                            |
 |       | +------------------------------------------------------------+
 |       | +------------------------------------------------------------+
 |       | |          |        |              |            |            |
 | Login | | toPolicy | policy | toOnboarding | onboarding | toMainShow |
 |       | |          |        |              |            |            |
 |       | +------------------------------------------------------------+
 |       |      +-----------------+
 |       |      |                 |
 |       |      |   feed (async)  |
 |       |      |                 |
 +-------+      +-----------------+

 */

let enterAppkey: String = "enter_app"

public enum EnterAppMetricKey: String {
    /// login success -> request feed finish & feed VC didAppear
    case mainRender = "enter_app_to_main_render"
    /// login success -> request user policy start
    case toPolicy = "enter_app_to_get_user_policy"
    /// request user policy start  -> request user policy finish
    case policy = "get_user_policy"
    /// request user policy finish -> request onboarding status start
    case toOnboarding = "get_user_policy_to_get_onboarding"
    /// request onboarding status start -> request onboarding status finish
    case onboarding = "get_onboarding"
    /// request onboarding status finish -> feed VC did Appaer
    case toMainShow = "get_onboarding_to_main_show"
    /// request feed start -> request feed finish
    case feed = "get_feed"
}

public enum EnterAppCategoryKey: String {
    case endType = "end_type"
}

public enum EnterAppCategoryEndType: String {
    case mainRender = "main_render"
    case toOnboarding = "to_onboarding"
    case toUserPolicy = "to_user_policy"
}

public enum EnterAppExtraKey: String {
    case userId = "user_id"
}

public struct EnterAppStep: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    // equal to EnterAppStep(rawValue: 0), fix wanring for swift5.2
    public static let none = EnterAppStep([])
    public static let login = EnterAppStep(rawValue: 1)
    public static let signPolicy = EnterAppStep(rawValue: 1 << 1)
    public static let onboarding = EnterAppStep(rawValue: 1 << 2)
    public static let feedShow = EnterAppStep(rawValue: 1 << 3)
    public static let feedLoadSuccess = EnterAppStep(rawValue: 1 << 4)
    public static let feedLoadFail = EnterAppStep(rawValue: 1 << 5)
}

///
///  enter app monitor
/// login success to first view show time
/// https://bytedance.feishu.cn/docs/doccnlP1aYEnYsJErWAbR4OovVg#
///
public final class EnterAppMonitor {
    /// instance
    public static let shared = EnterAppMonitor()

    /// start  metrics
    public func start(key: EnterAppMetricKey) {
        let startTime = CACurrentMediaTime()
        start(key: key, startTime: startTime)
    }

    /// end  metrics
    public func end(key: EnterAppMetricKey) {
        let endTime = CACurrentMediaTime()
        end(key: key, endTime: endTime)
    }

    /// set extra info
    public func set(key: EnterAppExtraKey, value: String) {
        queue.async {
            if !self.processStarted { return }
            self.extraDic[key] = value
        }
    }

    /// update  step
    public func update(step: EnterAppStep) {
        let time = CACurrentMediaTime()
        queue.async {
            if step == .login {
                // new process start
                self.cleanData()
                self.start(key: .mainRender, startTime: time)
            }
            self.steps = self.steps.union(step)
            if self.steps.contains([.feedShow, .feedLoadSuccess])
                || self.steps.contains([.feedShow, .feedLoadFail]) {
                self.end(key: .mainRender, endTime: time)
            }
        }
    }

    static let logger = Logger.log(EnterAppMonitor.self, category: "enterapp.monitor")

    private var enterAppTimeDic: [EnterAppMetricKey: String] = [:]

    private var startTimeDic: [EnterAppMetricKey: CFTimeInterval] = [:]

    private var extraDic: [EnterAppExtraKey: String] = [:]

    private var steps: EnterAppStep = .none

    private var queue: DispatchQueue = DispatchQueue(label: "enterapp.monitor", qos: .utility)

    private var needUpload: Bool {
        guard let endType = endType else {
            return false
        }
        switch endType {
        case .mainRender:
            return true
        case .toOnboarding, .toUserPolicy:
            return false
        }
    }

    private var endType: EnterAppCategoryEndType? {
        if steps.contains(.login), !steps.contains(.signPolicy), !steps.contains(.onboarding) {
            return .mainRender
        } else if steps.contains(.login),
            steps.contains(.signPolicy) {
            return .toUserPolicy
        } else if steps.contains(.login),
            !steps.contains(.signPolicy),
            steps.contains(.onboarding) {
            return .toOnboarding
        } else {
            return nil
        }
    }

    private var processStarted: Bool {
        return steps.contains(.login)
    }

    private func start(key: EnterAppMetricKey, startTime: CFTimeInterval) {
        queue.async {
            if !self.processStarted { return }
            if self.startTimeDic[key] != nil { return }
            self.startTimeDic[key] = startTime
        }
    }

    private func end(key: EnterAppMetricKey, endTime: CFTimeInterval) {
        queue.async {
            if !self.processStarted { return }
            if self.enterAppTimeDic[key] != nil { return }
            if let startTime = self.startTimeDic[key] {
                self.enterAppTimeDic[key] = "\((endTime - startTime) * 1_000)"
            }
            if key == .mainRender {
                // after mainRender 3s
                self.queue.asyncAfter(deadline: .now() + 3, execute: {
                    self.uploadEnterAppTime()
                })
            }
        }
    }

    private func uploadEnterAppTime() {
        if !needUpload { return }
        guard enterAppTimeDic[.mainRender] != nil else {
            assertionFailure() // 上传的时候必须存在启动时间主参数
            return
        }
        let metric: [String: String] = enterAppTimeDic.reduce([String: String]()) { (result, arg) -> [String: String] in
            let (key, value) = arg
            var result = result
            result[key.rawValue] = value
            return result
        }
        let extra: [String: String] = extraDic.reduce([String: String]()) { (result, arg) -> [String: String] in
            let (key, value) = arg
            var result = result
            result[key.rawValue] = value
            return result
        }
        guard let endType = endType else {
            EnterAppMonitor.logger.error("unknown endType type: \(steps.rawValue)")
            return
        }
        Tracker.post(SlardarEvent(
            name: enterAppkey,
            metric: metric,
            category: [
                EnterAppCategoryKey.endType.rawValue: endType.rawValue
            ],
            extra: extra)
        )
        EnterAppMonitor.logger.info("EnterApp Time: \(metric)")
        cleanData()
    }

    private func cleanData() {
        enterAppTimeDic = [:]
        startTimeDic = [:]
        extraDic = [:]
        steps = .none
    }

}
