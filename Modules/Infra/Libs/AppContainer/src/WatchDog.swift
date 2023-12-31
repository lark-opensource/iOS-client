//
//  WatchDog.swift
//  AppContainer
//
//  Created by liuwanlin on 2018/11/19.
//

import UIKit
import Foundation

public final class WatchDog {
    public static let shared = WatchDog()

    private var pingThread: PingThread?

    public func start(threshold: Double = 0.4, strict: Bool = true, handler: (() -> Void)? = nil) {
        let handler = handler ?? {
            let message = "👮👮👮 Main thread was blocked 👮👮👮"
            if strict {
                assert(UIApplication.shared.applicationState == .background, message)
            } else {
                print(message)
            }
        }
        self.pingThread = PingThread(threshold: threshold, handler: handler)
        self.pingThread?.start()
    }

    deinit {
        self.pingThread?.cancel()
    }
}

final class PingThread: Thread {
    private let semaphore = DispatchSemaphore(value: 0)

    private var isRunning = false
    private var result: DispatchTimeoutResult?

    private let threshold: Double
    private let handler: () -> Void

    init(threshold: Double, handler: @escaping () -> Void) {
        self.handler = handler
        self.threshold = threshold
    }

    override func main() {
        while !self.isCancelled {
            self.isRunning = true

            DispatchQueue.main.async {
                self.isRunning = false
                self.semaphore.signal()
            }

            Thread.sleep(forTimeInterval: self.threshold)

            if self.isRunning {
                self.handler()
            }

            self.result = self.semaphore.wait(timeout: DispatchTime.distantFuture)
        }
    }
}
