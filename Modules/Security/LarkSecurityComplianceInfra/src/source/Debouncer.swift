//
//  Debouncer.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2023/9/21.
//

import Foundation

public final class Debouncer {

    // Callback to be debounced
    // Perform the work you would like to be debounced in this callback.
    public var callback: (() -> Void)?

    private let interval: TimeInterval // Time interval of the debounce window

    public init(interval: TimeInterval) {
        self.interval = interval
    }

    private var timer: Timer?

    deinit {
        self.timer?.invalidate()
    }

    // Indicate that the callback should be called. Begins the debounce window.
    public func call() {
        // Invalidate existing timer if there is one
        DispatchQueue.main.async {
            self.timer?.invalidate()
            // Begin a new timer from now
            self.timer = Timer.scheduledTimer(withTimeInterval: self.interval, repeats: false, block: { [weak self] _ in
                assert(self?.callback != nil)
                self?.callback?()
                self?.callback = nil
            })
        }
    }
}
