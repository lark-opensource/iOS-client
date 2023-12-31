//
//  Debounce.swift
//  LarkKeyboardView
//
//  Created by zc09v on 2020/7/7.
//

import Foundation
final class Debouncer {
    private var timerDict: [String: DispatchSourceTimer] = [:]
    private var queue: DispatchQueue?
    private var semaphore: DispatchSemaphore = DispatchSemaphore(value: 1)
    public init(queue: DispatchQueue? = DispatchQueue.main) {
        self.queue = queue
    }

    public func debounce(indentify: String, duration: TimeInterval, action: @escaping () -> Void) {
        semaphore.wait()
        let existTimer = self.timerDict[indentify]
        existTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: self.queue)
        timer.schedule(deadline: DispatchTime.now() + duration, repeating: DispatchTimeInterval.never)
        timer.setEventHandler {
            action()
        }
        self.timerDict[indentify] = timer
        timer.resume()
        semaphore.signal()
    }
}
