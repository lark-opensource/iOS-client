//
//  Functional.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/12/16.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

typealias Debounce<T> = (T) -> Void
typealias Throttle<T> = (T) -> Void

func debounce<T>(interval: DispatchTimeInterval, queue: DispatchQueue = .main, action: @escaping Debounce<T>) -> Debounce<T> {
    var fireTime = DispatchTime.now()
    return { param in
        fireTime = DispatchTime.now()
        queue.asyncAfter(deadline: fireTime + interval) {
            if fireTime + interval <= DispatchTime.now() {
                action(param)
            }
        }
    }
}

/// 轻量级 throttle 实现，等价于 leading = true, trailing = false。适用于点击事件节流
func throttle<T>(interval: DispatchTimeInterval, action: @escaping Throttle<T>) -> Throttle<T> {
    var fireTime = DispatchTime.now()
    var lastFireTime = DispatchTime.now()
    var isFirstTime = true
    return { param in
        fireTime = DispatchTime.now()
        if isFirstTime || fireTime >= lastFireTime + interval {
            isFirstTime = false
            lastFireTime = fireTime
            action(param)
        }
    }
}

/// 相对于上面的简易版，提供了完整的 trailing 支持，适用于数据层面的节流
class _Throttle<T> {
    private var lastInvokeTime: DispatchTime?
    private var worker: DispatchWorkItem?
    private var lastThrottledParam: T?

    // Input
    let interval: DispatchTimeInterval
    let action: (T) -> Void
    let queue: DispatchQueue
    let trailing: Bool

    init(interval: DispatchTimeInterval, queue: DispatchQueue = .main, trailing: Bool = true, action: @escaping (T) -> Void) {
        self.interval = interval
        self.queue = queue
        self.action = action
        self.trailing = trailing
    }

    private func shouldInvoke(_ time: DispatchTime) -> Bool {
        if let lastInvokeTime = lastInvokeTime {
            return time >= lastInvokeTime + interval
        } else {
            return true
        }
    }

    private func resetTimer() {
        let worker = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let time = DispatchTime.now()
            if self.shouldInvoke(time) {
                self.trailingCall()
                return
            }
            self.resetTimer()
        }
        queue.asyncAfter(deadline: .now() + interval, execute: worker)
        self.worker = worker
    }

    private func invoke() {
        guard let lastParam = lastThrottledParam else { return }
        lastThrottledParam = nil
        lastInvokeTime = DispatchTime.now()
        action(lastParam)
    }

    private func trailingCall() {
        worker?.cancel()
        worker = nil
        if trailing {
            invoke()
        }
    }

    func call(_ param: T) {
        let time = DispatchTime.now()
        let canInvoke = shouldInvoke(time)
        lastThrottledParam = param

        if canInvoke {
            invoke()
        }

        if worker == nil {
            resetTimer()
        }
    }
}
