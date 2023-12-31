//
//  SKImmersionTask.swift
//  SKFoundation
//
//  Created by 邱沛 on 2020/1/14.
//

import Foundation

public final class SKImmersionTask {
    private let taskInterval: Double
    private let event: () -> Void
    private var timer: Timer?
    public var isImmersion: Bool = false
    public init(taskInterval: Double, event: @escaping () -> Void) {
        self.taskInterval = taskInterval
        self.event = event
    }

    deinit {
        self.timer?.invalidate()
    }

    public func resume() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: taskInterval, repeats: false, block: { _ in self.event() })
    }

    public func invalidate() {
        self.timer?.invalidate()
    }
}
