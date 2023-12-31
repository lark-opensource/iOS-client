//
//  Throttler.swift
//  UniverseDesignDatePicker
//
//  Created by LiangHongbin on 2021/12/24.
//

import Foundation
class Throttler {
    private let lock = DispatchSemaphore(value: 1)
    private let delay: TimeInterval
    //each throttler have a unique private task queue
    private let queue = DispatchQueue(label: "throttlerQueue\(arc4random())")
    private let taskQueue: DispatchQueue
    private var currentWorkItem: DispatchWorkItem = DispatchWorkItem(block: {})
    private var previousRun: Date = Date.distantPast
    private let executeLast: Bool
    func call(action: @escaping (() -> Void)) {
        lock.wait()
        defer { lock.signal() }
        queue.async {
            self.currentWorkItem.cancel()

            self.currentWorkItem = DispatchWorkItem { [weak self] in
                self?.previousRun = Date()
                self?.taskQueue.async { action() }
            }
            let time = (-self.previousRun.timeIntervalSinceNow) > self.delay ? 0 : self.delay
            if time != 0 && !self.executeLast {
                return
            }
            self.queue.asyncAfter(deadline: .now() + time, execute: self.currentWorkItem)
        }
    }

    init(delay: TimeInterval,
         executeLast: Bool = false,
         queue: DispatchQueue = .main) {
        self.executeLast = executeLast
        self.delay = delay
        self.taskQueue = queue
    }
}
