//
//  SCTimer.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2023/2/2.
//

import Foundation
import ThreadSafeDataStructure

public struct TimerCongfig {
    let timerInterval: Int

    let disableWhileBackground: Bool

    public init(timerInterval: Int, disableWhileBackground: Bool = false) {
        self.timerInterval = timerInterval
        self.disableWhileBackground = disableWhileBackground
    }
}

public final class SCTimer {

    public var handler: (() -> Void)?

    private var isTerminating: Bool = false

    private var config: TimerCongfig

    private var started: Bool = false

    public init(config: TimerCongfig) {
        self.config = config

        guard config.disableWhileBackground else { return }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }

    @objc
    func onDidBecomeActive() {
        self.startTimerIfNeed()
    }

    @objc
    func onDidEnterBackground() {
        self.realStopTimer()
    }

    @objc
    func onWillEnterForeground() {
        self.startTimerIfNeed()
    }

    @objc
    func onWillTerminate() {
        self.isTerminating = true
        self.realStopTimer()
    }

    private func startTimerIfNeed() {
        guard started else { return }
        realStartTimer()
    }

    private lazy var timerQueue: DispatchQueue = { DispatchQueue.global(qos: .default) }()

    private let lock: DispatchSemaphore = DispatchSemaphore(value: 1)

    private var timer: SafeAtomic<DispatchSourceTimer?> = nil + .readWriteLock

    // 对外开放接口，只有当外部主动触发timer启动的时候才将started置为true
    public func startTimer() {
        started = true
        realStartTimer()
    }

    private func realStartTimer() {
        self.realStopTimer()
        lock.wait()
        defer {
            lock.signal()
        }
        let timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer.schedule(deadline: .now(), repeating: .seconds(config.timerInterval), leeway: .microseconds(1))
        timer.setEventHandler(handler: { [weak self] in
            guard let self = self else { return }
            if self.isTerminating { return }
            self.handler?()
        })
        timer.resume()
        self.timer.value = timer
    }

    // 对外开放接口，只有当外部主动触发timer停止的时候才将started置为false
    public func stopTimer() {
        started = false
        self.realStopTimer()
    }

    private func realStopTimer() {
        lock.wait()
        defer {
            lock.signal()
        }
        let timer = self.timer.value
        self.timer.value = nil
        timer?.cancel()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        realStopTimer()
    }
}
