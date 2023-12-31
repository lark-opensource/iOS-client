//
//  FPSMonitorHelper.swift
//  LarkCore
//
//  Created by lichen on 2018/11/27.
//

import Foundation

/// 监听某一时间段内 FPS

public final class FPSMonitorHelper: MonitorHelperProtocol {

    public struct Result {
        public let fps: Double
        public let fpsArray: [Double]
        public let duration: TimeInterval
        public let params: [String: String]?

        public init(fps: Double, fpsArray: [Double], duration: TimeInterval, params: [String: String]?) {
            self.fps = fps
            self.fpsArray = fpsArray
            self.duration = duration
            self.params = params
        }
    }

    static let fpsKey = "fps.monitor.key"                   // fps 数据 key 存储一个  fps 数组
    static let fpsParamsKey = "fps.monitor.params.key"      // 一些外部传进来的参数 key
    static let fpsStartKey = "fps.Tracker.start.key"        // task 开始时间 key
    static let fpsCallbackKey = "fps.monitor.callback.key"  // task callback
    static let fpsIntervalKey = "fps.monitor.interval.key"  // 多次回调间隔 key

    public static let shared = FPSMonitorHelper()

    public var refreshInterval: TimeInterval = 0.1 // fps 刷新间隔

    let queue: DispatchQueue = DispatchQueue(label: "fps.monitor.helper")

    var tasks: [MonitorHelperTask] = []
    var frameCount: Int = 0
    var lastTimestamp: TimeInterval = 0
    var lastFPS: TimeInterval = 0

    /// 开始一个 fps 监控 task
    ///
    /// - Parameters:
    ///   - task: task name
    ///   - interval: 多次回调间隔 默认只在 task 结束的时候回调
    ///   - bind: bind object
    ///   - callback: fps 回调 block
    public func startTrackFPS(
        task: String,
        interval: TimeInterval = 0,
        bind: NSObject? = nil,
        callback: @escaping (Result) -> Void) {
        self.start(task: task, bind: bind) { (task) in
            task.extra[FPSMonitorHelper.fpsStartKey] = Date().timeIntervalSince1970
            task.extra[FPSMonitorHelper.fpsCallbackKey] = callback
            if interval > 0 {
                task.extra[FPSMonitorHelper.fpsIntervalKey] = interval
            }
        }
    }

    ///  结束一个 fps 监控 task
    ///
    /// - Parameters:
    ///   - task: task name
    ///   - bind: bind object
    ///   - params: 自定义一些上传参数
    public func endTrackFPS(task: String, bind: NSObject? = nil, params: [String: String]? = nil) {
        self.stop(task: task, bind: bind) { (task) in
            task.extra[FPSMonitorHelper.fpsParamsKey] = params
        }
    }

    func start(task: MonitorHelperTask, repetition: Bool) {
        self.startTimerIfNeeded()
    }

    func stop(task: MonitorHelperTask) {
        self.stopTimerIfNeeded()

        guard let callback = task.extra[FPSMonitorHelper.fpsCallbackKey] as? (Result) -> Void,
            let startTime = task.extra[FPSMonitorHelper.fpsStartKey] as? TimeInterval else {
            assertionFailure()
            return
        }
        let params = task.extra[FPSMonitorHelper.fpsParamsKey] as? [String: String]
        self.handle(task: task, startTime: startTime, params: params, callback: callback)
    }

    var displayLink: CADisplayLink?

    deinit {
        self.stopTimer()
    }

    func startTimerIfNeeded() {
        if !self.tasks.isEmpty {
            if self.displayLink == nil {
                self.displayLink = createDisplayLink()
            }

            guard let displayLink = self.displayLink,
                !displayLink.isPaused else {
                return
            }
            displayLink.add(to: RunLoop.main, forMode: .common)
            displayLink.isPaused = false
            self.frameCount = 0
            self.lastTimestamp = displayLink.timestamp
        }
    }

    func stopTimerIfNeeded() {
        if self.tasks.isEmpty {
            self.stopTimer()
        }
    }

    private func stopTimer() {
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = 0
    }

    private func createDisplayLink() -> CADisplayLink {
        let displayLink = CADisplayLink(
            target: FPSMonitorHelperProxy(self),
            selector: #selector(updateFPS(displayLink:))
        )
        displayLink.preferredFramesPerSecond = 60
        return displayLink
    }

    @objc
    fileprivate func updateFPS(displayLink: CADisplayLink) {
        if lastTimestamp == 0 { lastTimestamp = displayLink.timestamp }
        frameCount += 1
        let interval = displayLink.timestamp - lastTimestamp
        if interval < self.refreshInterval { return }
        lastTimestamp = displayLink.timestamp
        if interval > 0 {
            lastFPS = Double(frameCount) / interval
        }
        self.frameCount = 0
        let fps = self.lastFPS
        self.queue.async { [weak self] in
            self?.refresh(fps: fps)
        }
    }

    private func refresh(fps: Double) {
        self.tasks.forEach { (task) in
            if var fpsArray = task.extra[FPSMonitorHelper.fpsKey] as? [Double] {
                fpsArray.append(lastFPS)
                task.extra[FPSMonitorHelper.fpsKey] = fpsArray
            } else {
                task.extra[FPSMonitorHelper.fpsKey] = [fps]
            }

            let now = Date().timeIntervalSince1970
            if let interval = task.extra[FPSMonitorHelper.fpsIntervalKey] as? TimeInterval,
                let startTime = task.extra[FPSMonitorHelper.fpsStartKey] as? TimeInterval,
                now - startTime > interval,
                let callback = task.extra[FPSMonitorHelper.fpsCallbackKey] as? (Result) -> Void {
                self.handle(task: task, startTime: startTime, params: [:], callback: callback)
                task.extra[FPSMonitorHelper.fpsStartKey] = now
            }
        }
    }

    private func handle(
        task: MonitorHelperTask,
        startTime: TimeInterval,
        params: [String: String]?,
        callback: (Result) -> Void
    ) {
        let result: Result
        let interval = Date().timeIntervalSince1970 - startTime
        if let fpsArray = task.extra[FPSMonitorHelper.fpsKey] as? [TimeInterval], !fpsArray.isEmpty {
            let fps = fpsArray.reduce(0, +) / Double(fpsArray.count)
            result = Result(fps: fps, fpsArray: fpsArray, duration: interval, params: params)
        } else {
            var fps: Double = 0
            if interval > 0 {
                fps = Double(self.frameCount) / interval
            }
            result = Result(fps: fps, fpsArray: [fps], duration: interval, params: params)
        }
        callback(result)
    }
}

public final class FPSMonitorHelperProxy {

    weak var helper: FPSMonitorHelper?

    public init(_ helper: FPSMonitorHelper) {
        self.helper = helper
    }

    @objc
    public func updateFPS(displayLink: CADisplayLink) {
        self.helper?.updateFPS(displayLink: displayLink)
    }
}
