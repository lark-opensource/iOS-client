//
//  OPPerformanceMonitorTimer.swift
//  OPFoundation
//
//  Created by 尹清正 on 2021/3/29.
//

import Foundation

fileprivate let DefaulTimerTriggerInterval: TimeInterval = 5

/// 定义一个统一的timer，性能检测工具可以订阅该timer来实现逻辑的定时触发，而不用去考虑timer的一些细节
class OPPerformanceMonitorTimer {

    /// singleton
    static let shared = OPPerformanceMonitorTimer()

    var timer: Timer?

    /// 存储所有订阅
    private var subscriberStorage: [String: TimerSubscriber] = [:]

    /// 为了保护subscriberStorage线程安全的锁
    private let semaphore = DispatchSemaphore(value: 1)

    private init() {
        let triggerInterval = OPPerformanceMonitorConfigProvider.performanceTimerInterval ?? DefaulTimerTriggerInterval
        let timer = Timer(timeInterval: triggerInterval, repeats: true, block: { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            self.semaphore.wait()
            let allSubscribers = self.subscriberStorage.values
            self.semaphore.signal()

            for subscriber in allSubscribers {
                DispatchQueue.global().async { [weak subscriber] in
                    subscriber?.trigger()
                }
            }
        })
        RunLoop.main.add(timer, forMode: .common)
        timer.fire()

        self.timer = timer
    }


    /// 订阅定时器
    /// - Parameters:
    ///   - id: 每个订阅者的唯一id，如果使用同样的id订阅，会覆盖先前的订阅
    ///   - block: 触发时要执行的逻辑
    func subscribe(with id: String, block: @escaping ()->()) {
        let subscriber = TimerSubscriber(block: block)

        semaphore.wait()
        subscriberStorage[id] = subscriber
        semaphore.signal()
    }


    /// 取消某个订阅
    /// - Parameter id: 订阅时指定的id
    func dispose(with id: String) {
        semaphore.wait()
        subscriberStorage.removeValue(forKey: id)
        semaphore.signal()
    }

    deinit {
        timer?.invalidate()
    }
}

extension OPPerformanceMonitorTimer {
    private class TimerSubscriber {
        /// 触发时要执行的逻辑
        private let block: ()->()

        init(block: @escaping ()->()) {
            self.block = block
        }

        func trigger() {
            block()
        }
    }
}
