//
//  BGTaskSchedulerDelegate.swift
//  AFgzipRequestSerializer
//
//  Created by 李勇 on 2020/2/11.
//

import UIKit
import Foundation
import AppContainer
import LKCommonsLogging
import LKCommonsTracker
import Homeric
import LarkAssembler
import EENavigator

/// 日志工具
private struct LKBGLoggerImpl: LKBGLogger {
    private let logger = Logger.log(LarkBGTaskScheduler.self)

    func debug(_ message: String, error: Error?, file: String, method: String, line: Int) {
        logger.debug(message, additionalData: nil, error: error, file: file, function: method, line: line)
    }

    func info(_ message: String, error: Error?, file: String, method: String, line: Int) {
        logger.info(message, additionalData: nil, error: error, file: file, function: method, line: line)
    }

    func error(_ message: String, error: Error?, file: String, method: String, line: Int) {
        logger.error(message, additionalData: nil, error: error, file: file, function: method, line: line)
    }
}

/// 打点工具
private struct LKBGTrackerImpl: LKBGTracker {
    func refresh(metric: [String: Any], category: [String: Any], extra: [String: Any]) {
        Tracker.post(SlardarEvent(name: Homeric.BGTASK_REFRESH, metric: metric, category: category, extra: extra))
    }

    func processing(metric: [String: Any], category: [String: Any], extra: [String: Any]) {
        Tracker.post(SlardarEvent(name: Homeric.BGTASK_PROCESSING, metric: metric, category: category, extra: extra))
    }
}

var EVENTNAME: String = "background_and_foreground_event"
var EVENTENTERBACKGROUND = "enter_background"
var EVENTENTERFOREGROUND = "enter_foreground"

/// 接入LarkBGTaskScheduler，让Lark具备使用BackgroundTasks的能力
public final class BGTaskSchedulerDelegate: ApplicationDelegate {
    public static let config = Config(name: "BGTaskScheduler", daemon: true)

    required public init(context: AppContext) {
        // 设置日志工具
        LarkBGTaskScheduler.shared.logger = LKBGLoggerImpl()
        // 设置打点工具
        LarkBGTaskScheduler.shared.tracker = LKBGTrackerImpl()

        // 监听PerformFetch
        context.dispatcher.add(observer: self) { (_, context: PerformFetch) in
            LarkBGTaskScheduler.shared.applicationPerformFetch(completionHandler: context.completionHandler)
        }
        // 监听进入后台事件
        context.dispatcher.add(observer: self) { (_, _: DidEnterBackground) in
            Tracker.post(SlardarEvent(name: EVENTNAME,
                                      metric: [EVENTENTERBACKGROUND: "1"],
                                      category: [:],
                                      extra: [:]))
            LarkBGTaskScheduler.shared.applicationDidEnterBackground()
        }
        // 监听进入前台事件
        context.dispatcher.add(observer: self) { (_, _: WillEnterForeground) in
            Tracker.post(SlardarEvent(name: EVENTNAME,
                                      metric: [EVENTENTERFOREGROUND: "1"],
                                      category: [:],
                                      extra: [:]))
            LarkBGTaskScheduler.shared.applicationWillEnterForeground()
        }
        // SceneDelegate和AppDelegate对于UI事件回调是互斥的，所以需要根据iOS13来区别添加
        if #available(iOS 13, *) {
            // 监听进入后台事件
            context.dispatcher.add(observer: self) { (_, context: SceneDidEnterBackground) in
                // 所有scene都进入后台才进行通知
                let otherScenes = UIApplication.shared.windowApplicationScenes.filter({ $0 != context.scene })
                if otherScenes.contains(where: { $0.activationState == .foregroundActive }) { return }

                LarkBGTaskScheduler.shared.applicationDidEnterBackground()
            }
            // 监听进入前台事件
            context.dispatcher.add(observer: self) { (_, _: SceneWillEnterForeground) in
                // 任一scene进入前台就进行通知
                LarkBGTaskScheduler.shared.applicationWillEnterForeground()
            }
        }
    }
}
