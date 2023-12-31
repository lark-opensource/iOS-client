//
//  Trigger.swift
//  RunloopTools
//
//  Created by KT on 2020/2/11.
//

import Foundation
import LKCommonsLogging

public protocol Triggerable: AnyObject {
    func setup()
    func clean()
    var reciver: TriggerResponseable? { get set }
}

public protocol TriggerResponseable: AnyObject {
    func willTrigger() -> Bool
    func didAddObserver()
    func didRemoveObserver()
}

final class RunloopTrigger: Triggerable {
    private static let logger = Logger.log(RunloopTrigger.self)
    weak var reciver: TriggerResponseable?

    func setup() {
        guard self.observer == nil else { return }
        let activityToObserve: CFRunLoopActivity = [.beforeWaiting, .exit]
        let observer = CFRunLoopObserverCreateWithHandler(
            kCFAllocatorDefault,        // allocator
            activityToObserve.rawValue, // activities
            true,                       // repeats
            Int.max                     // order after CA transaction commits
        ) { [weak self] (_, _) in
            guard RunloopDispatcher.enable, TriggerThrottle.pass else { return }
            TriggerThrottle.success = self?.reciver?.willTrigger() ?? false
        }
        self.observer = observer
        CFRunLoopAddObserver(runloop, observer, CFRunLoopMode.defaultMode)
        self.reciver?.didAddObserver()
        RunloopTrigger.logger.info("RunloopTrigger Add observer")
    }

    func clean() {
        guard let observer = self.observer else { return }
        CFRunLoopRemoveObserver(runloop, observer, CFRunLoopMode.defaultMode)
        self.observer = nil
        self.reciver?.didRemoveObserver()
        RunloopTrigger.logger.info("RunloopTrigger clean observer")
    }

    // MARK: - private
    private var observer: CFRunLoopObserver?

    private var runloop: CFRunLoop {
        return RunLoop.main.getCFRunLoop()
    }
}

/// 失败后重试，按照fib数递增
final class TriggerThrottle {
    private static var step: Int32 = 0
    private static var cursor: Int32 = 1
    private static var fibCursor: Int32 = 2 // f(3) = 2

    static var pass: Bool {
        OSAtomicIncrement32(&step)
        return step >= cursor
    }

    static var success: Bool = true {
        didSet {
            if success {
                step = 0
                cursor = 1
                fibCursor = 2
            } else {
                cursor = fib(OSAtomicIncrement32(&fibCursor))
            }
        }
    }

    static func fib(_ current: Int32) -> Int32 {
        if current == 0 { return 0 }
        if current == 1 { return 1 }

        return fib(current - 1) + fib(current - 2)
    }
}
