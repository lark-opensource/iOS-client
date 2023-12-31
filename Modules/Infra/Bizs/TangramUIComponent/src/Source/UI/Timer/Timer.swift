//
//  Timer.swift
//  UDDemo
//
//  Created by houjihu on 2021/4/11.
//

import Foundation

/// 计时器
final class Timer {
    /// 计时器状态
    private enum State {
        /// 开始
        case resumed
        /// 暂停
        case suspend
        /// 取消
        case cancel
    }

    private var state: State = .suspend

    private var internalTimer: DispatchSourceTimer?

    private var handler: ((Timer) -> Void)

    private let timerInterval: Int

    /// 初始化计时器
    /// - Parameters:
    ///   - timerInterval: 刷新时间间隔
    ///   - handler: 回调
    init(timerInterval: Int, handler: @escaping ((Timer) -> Void)) {
        self.timerInterval = timerInterval
        self.handler = handler
    }

    private lazy var timerQueue: DispatchQueue = { DispatchQueue.global(qos: .default) }()

    /// 开始计时
    public func start() {
        if state == .resumed {
            return
        }
        if internalTimer == nil {
            let timer = DispatchSource.makeTimerSource(queue: timerQueue)
            timer.setEventHandler(handler: { [weak self] in
                guard let `self` = self else { return }
                DispatchQueue.main.async {
                    self.handler(self)
                }
            })
            let interval = DispatchTimeInterval.seconds(timerInterval)
            timer.schedule(deadline: .now() + interval, repeating: interval)
            internalTimer = timer
        }
        internalTimer?.resume()
        state = .resumed
    }

    /// 暂停计时
    public func pause() {
        if state == .suspend {
            return
        }
        internalTimer?.suspend()
        state = .suspend
    }

    /// 停止计时
    public func stop() {
        if state == .cancel {
            return
        }
        if state == .suspend {
            internalTimer?.resume()
        }
        internalTimer?.cancel()
        internalTimer = nil
        state = .cancel
    }

    deinit {
        stop()
        print("timer denit")
    }
}
