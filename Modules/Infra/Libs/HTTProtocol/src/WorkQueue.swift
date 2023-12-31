//
//  WorkQueue.swift
//  HTTProtocol
//
//  Created by SolaWing on 2023/4/13.
//

import Foundation
import EEAtomic

/// 一般URLProtocol应该跑在调用线程上，但也可能需要跑在特定的queue上.
/// 这个workQueue负责相应的任务调度，保证线程安全
public protocol HTTProtocolWorkQueue: AnyObject {
    // func preconditionOnQueue(message: @autoclosure () -> String, file: StaticString, line: UInt)
    /// 在当前queue的断言
    func isInQueue() -> Bool
    /// async a task into queue
    func `async`(execute: @escaping () -> Void)
    /// async after a interval
    func asyncAfter(interval: TimeInterval, execute: @escaping () -> Void)
    /// if already in queue, run directly
    func run(execute: @escaping () -> Void)
}

class WorkQueue: NSObject, HTTProtocolWorkQueue {
    /// the start thread, may use to check if on startThread. subclass may ensure run on startThread for thread safety
    /// NOTE: should not occupy long time on startThread, this thread normal shared by all instance and callback.
    public let thread: Foundation.Thread
    private let mode: [RunLoop.Mode]
    init(thread: Foundation.Thread, mode: [RunLoop.Mode]) {
        self.thread = thread
        self.mode = mode
    }
    @objc
    private func exec(_ exec: Any) {
        guard let exec = exec as? () -> Void else {
            assertionFailure("wrong callback passed in")
            return
        }
        exec()
    }
    // guard thread safety, and seems it's stable and wont crash with same start thread
    // all Protocol instance shared on same queue. to avoid accumulate on the URLProtocol Thread
    // (system use one thread for all URLProtocol)
    static private var bufferThreadQueue = DispatchQueue(label: "HTTProtocolCallback")

    #if DEBUG
    static var taskCount = AtomicUInt64Cell()
    #endif
    /// 保证代码运行在启动线程上，同时有限制堆积数，不会堵塞其它在启动线程上的回调。
    final public func async(execute: @escaping () -> Void) {
        // 通过serial queue限制 startThread的堆积数，保证URLSession等的调用能即时响应，避免redirect异常
        // 同时也解开startThread对self的强引用和延迟，保证资源的即时释放
        #if DEBUG
        _ = Self.taskCount.increment(order: .relaxed)
        let start = CACurrentMediaTime()
        #endif
        Self.bufferThreadQueue.async { [weak self] in
            #if DEBUG
            let waited = Self.taskCount.decrement(order: .relaxed) - 1
            #endif
            guard let self = self else { return }
            #if DEBUG
            debug("accumulate: \(waited), wait queue: \(CACurrentMediaTime() - start)s")
            #endif
            self.perform(#selector(self.exec(_:)), on: self.thread, with: execute,
                         waitUntilDone: true, modes: self.mode.map { $0.rawValue })
        }
    }
    final func asyncAfter(interval: TimeInterval, execute: @escaping () -> Void) {
        Self.bufferThreadQueue.asyncAfter(deadline: DispatchTime.now() + interval) { [weak self] in
            // one more async to guarentee async order( or time limited task may has priorities )
            self?.async(execute: execute)
        }
    }
    // 和上面区别: 上面总是异步，按asyncOnStartThread调用顺序执行
    // 这个如果已经是startThread，会直接执行，且不保证执行顺序
    final func run(execute: @escaping () -> Void) {
        if Thread.current == thread {
            execute()
        } else {
            self.perform(#selector(exec(_:)), on: thread, with: execute,
                         waitUntilDone: false, modes: mode.map { $0.rawValue })
        }
    }

    func isInQueue() -> Bool {
        Thread.current == thread
    }
}
