//
//  Task.swift
//  RunloopTools
//
//  Created by KT on 2020/2/11.
//

import Foundation
import LKCommonsLogging

public typealias Action = () -> Void

public final class Task {
    public private(set) var priority: Priority
    public private(set) var scope: Scope
    public private(set) var taskAction: Action
    public private(set) var needCheck = false
    public private(set) var state: TaskState = .pending

    public private(set) var identify: String

    public private(set) var isWaiteCPUFree = false {
        didSet {
            guard isWaiteCPUFree else { return }
            self.needCheck = true
        }
    }

    init(priority: Priority, scope: Scope, taskAction: @escaping Action, identify: String?) {
        self.priority = priority
        self.scope = scope
        self.taskAction = taskAction
        self.identify = identify ?? Task.uIdentify()
    }

    func exec() {
        Task.logger.info("RunloopDispatcher Do Task: \(description)")
        self.state = .doing
        self.taskAction()
        self.state = .finished
    }

    /// CPU空闲执行
    @discardableResult
    public func waitCPUFree() -> Task {
        self.isWaiteCPUFree = true
        return self
    }

    @discardableResult
    public func withPriority(_ priority: Priority) -> Task {
        self.priority = priority
        return self
    }

    @discardableResult
    public func withScope(_ scope: Scope) -> Task {
        self.scope = scope
        return self
    }

    @discardableResult
    public func withIdentify(_ identify: String) -> Task {
        self.identify = identify
        return self
    }

    /// 子线程异步执行
    @discardableResult
    public func async() -> Task {
        let task = self.taskAction
        self.taskAction = {
            DispatchQueue.global().async { task() }
        }
        return self
    }

    // MARK: - private
    private static let logger = Logger.log(Task.self)
    private static var bucket: Int32 = 0

    @inline(__always)
    private static func uIdentify() -> String {
        return String(OSAtomicIncrement32(&bucket) & Int32.max)
    }
}

extension Task: CustomStringConvertible {
    public var description: String {
        return "priority: \(priority.value), identify: \(identify), scope: \(scope)"
    }
}
