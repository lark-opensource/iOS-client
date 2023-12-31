//
//  BatchTimer.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/11/24.
//

import Foundation
import ThreadSafeDataStructure

final class BatchTimer {

    var handler: (() -> Void)?

    private var isTerminating: Bool = false

    private let timerInterval: Int

    init(timerInterval: Int) {
        self.timerInterval = timerInterval
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
        self.startTimer()
    }

    @objc
    func onDidEnterBackground() {
        self.stopTimer()
    }

    @objc
    func onWillEnterForeground() {
        self.startTimer()
    }

    @objc
    func onWillTerminate() {
        self.isTerminating = true
        self.stopTimer()
    }

    private lazy var timerQueue: DispatchQueue = { DispatchQueue.global(qos: .default) }()

    private let lock: DispatchSemaphore = DispatchSemaphore(value: 1)

    private var timer: SafeAtomic<DispatchSourceTimer?> = nil + .readWriteLock

    func startTimer() {
        lock.wait()
        defer {
            lock.signal()
        }
        self.stopTimer()
        let timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer.schedule(deadline: .now(), repeating: .seconds(timerInterval), leeway: .microseconds(1))
        timer.setEventHandler(handler: { [weak self] in
            guard let self = self else { return }
            if self.isTerminating { return }
            self.handler?()
        })
        timer.resume()
        self.timer.value = timer
    }

    func stopTimer() {
        let timer = self.timer.value
        self.timer.value = nil
        timer?.cancel()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stopTimer()
    }
}
