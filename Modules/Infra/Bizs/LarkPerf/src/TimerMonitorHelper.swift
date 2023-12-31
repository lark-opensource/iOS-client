//
//  TimerMonitorHelper.swift
//  LarkCore
//
//  Created by lichen on 2018/11/27.
//

import Foundation

/// 监听事件间隔

public final class TimeMonitorHelper: MonitorHelperProtocol {

    public struct Result {
        public let duration: TimeInterval
        public let params: [String: Any]?

        public init(duration: TimeInterval, params: [String: Any]?) {
            self.duration = duration
            self.params = params
        }
    }

    static let startTimeKey = "startTimeKey.monitor.key" // time key
    static let endTimeKey = "endTimeKey.monitor.key" // time key
    static let timeCallbackKey = "time.monitor.calback.key" // time callback key
    static let timeParamsKey = "time.monitor.params.key" // time params key

    var queue: DispatchQueue = DispatchQueue(label: "time.monitor.helper")
    var tasks: [MonitorHelperTask] = []

    public static let shared = TimeMonitorHelper()

    /// 开始一个计时 task
    ///
    /// - Parameters:
    ///   - task: task name
    ///   - bind: bind object
    ///   - callback: call block
    public func startTrack(
        task: String,
        bind: NSObject? = nil,
        callback: @escaping (Result) -> Void) {
        self.start(task: task, bind: bind) { (task) in
            task.extra[TimeMonitorHelper.startTimeKey] = Date().timeIntervalSince1970
            task.extra[TimeMonitorHelper.timeCallbackKey] = callback
        }
    }

    /// 结束一个计时 task
    ///
    /// - Parameters:
    ///   - task: task name
    ///   - bind: bind object
    ///   - params: 自定义上传参数
    public func endTrack(task: String, bind: NSObject? = nil, params: [String: Any]? = nil) {
        let endTime = Date().timeIntervalSince1970
        self.stop(task: task, bind: bind) { (task) in
            task.extra[TimeMonitorHelper.timeParamsKey] = params
            task.extra[TimeMonitorHelper.endTimeKey] = endTime
        }
    }

    func start(task: MonitorHelperTask, repetition: Bool) {
    }

    func stop(task: MonitorHelperTask) {
        guard let callback = task.extra[TimeMonitorHelper.timeCallbackKey] as? (Result) -> Void,
            let startTime = task.extra[TimeMonitorHelper.startTimeKey] as? TimeInterval,
            let endTime = task.extra[TimeMonitorHelper.endTimeKey] as? TimeInterval else {
                assertionFailure()
                return
        }
        let interval = endTime - startTime
        let params = task.extra[TimeMonitorHelper.timeParamsKey] as? [String: Any]
        callback(Result(duration: interval, params: params))
    }
}
