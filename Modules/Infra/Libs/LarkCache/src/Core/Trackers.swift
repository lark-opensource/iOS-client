//
//  Trackers.swift
//  LarkBaseService
//
//  Created by 李晨 on 2020/8/20.
//

import UIKit
import Foundation
import LKCommonsTracker
import ThreadSafeDataStructure

/// 收集每个
final class CacheCleanTracker {
    private struct Item {
        var bytes: Int
        var costTime: Int
        var identifier: String
    }

    private var items: SafeArray<Item> = [] + .semaphore

    func addItem(bytes: Int, costTime: Int, forIdentifier identifier: String) {
        items.append(.init(bytes: bytes, costTime: costTime, identifier: identifier))
    }

    func flush() {
        for item in items.getImmutableCopy() {
            let event = SlardarEvent(
                name: "lark_cache_default_clean",
                metric: [
                    "size": item.bytes,
                    "cost": item.costTime
                ],
                category: [
                    "identifier": transform(item.identifier)
                ],
                extra: [:]
            )
            Tracker.post(event)
        }
    }
}

final class TaskCleanTracker {
    enum State {
        case idle
        case running
    }

    enum FailedReason: Int, Comparable {
        case none
        case cancel
        case timeout
        case exception

        mutating func merge(reason: FailedReason) {
            self = max(self, reason)
        }

        func reasonStr() -> String {
            switch self {
            case .none:
                return "none"
            case .cancel:
                return "cancel"
            case .timeout:
                return "timeout"
            case .exception:
                return "exception"
            }
        }

        static func < (lhs: Self, rhs: Self) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
    private(set) var state: State = .idle
    private(set) var failedReason: FailedReason = .none
    private(set) var results: SafeDictionary<String, TaskResult> = [:] + .semaphore
    private(set) var startTime: TimeInterval = 0
    private(set) var endTime: TimeInterval = 0
    private(set) var taskCount: Int = 0
    private(set) var taskCompletedCount: Int = 0
    private(set) var exceptionTasks: SafeArray<String> = [] + .semaphore

    func start(taskCount: Int) {
        guard self.state == .idle else { return }
        self.startTime = CACurrentMediaTime()
        self.state = .running
        self.taskCount = taskCount
    }

    func record(result: TaskResult, forTask taskName: String) {
        guard self.state == .running else { return }
        let taskName = transform(taskName)
        if !result.completed {
            self.failedReason.merge(reason: .exception)
            self.exceptionTasks.append(taskName)
        } else {
            self.taskCompletedCount += 1
        }
        self.results[taskName] = result
    }

    func complete() {
        guard self.state == .running else { return }
        self.endTime = CACurrentMediaTime()
        self.flush()
    }

    func timeout() {
        guard self.state == .running else { return }
        self.failedReason.merge(reason: .timeout)
        self.endTime = CACurrentMediaTime()
        self.flush()
    }

    func cancel() {
        guard self.state == .running else { return }
        self.failedReason.merge(reason: .cancel)
        self.endTime = CACurrentMediaTime()
        self.flush()
    }

    private func flush() {
        var events = [SlardarEvent]()
        var totalCleanBytes = 0
        var totalCleanCount = 0
        // task 粒度数据上报
        for (name, result) in results.getImmutableCopy() {
            var cleanCount = 0
            var cleanBytes = 0
            result.sizes.forEach { size in
                switch size {
                case .bytes(let bytes):
                    cleanBytes += bytes
                    totalCleanBytes += bytes
                case .count(let count):
                    cleanCount += count
                    totalCleanCount += count
                }
            }
            let event = SlardarEvent(
                name: "lark_cache_task_clean",
                metric: [
                    "latency": result.costTime,
                    "bytes": cleanBytes,
                    "count": cleanCount,
                    "completed": result.completed
                ],
                category: [
                    "task_name": name,
                ],
                extra: [:]
            )
            events.append(event)
        }

        // 整体数据上报
        let event = SlardarEvent(
            name: "lark_cache_task_total_clean",
            metric: [
                "latency": (endTime - startTime) * 1_000,
                "bytes": totalCleanBytes,
                "count": totalCleanCount,
                "percentage": CGFloat(results.count) / CGFloat(taskCount)
            ],
            category: [
                "completed": taskCount == taskCompletedCount ? 1 : 0,
                "failed_reason": failedReason.reasonStr()
            ],
            extra: [
                "exception_tasks": exceptionTasks.getImmutableCopy().joined(separator: ",")
            ]
        )
        events.append(event)

        reset()

        DispatchQueue.global(qos: .utility).async {
            events.forEach(Tracker.post(_:))
        }
    }

    private func reset() {
        self.state = .idle
        self.failedReason = .none
        self.results.removeAll()
        self.exceptionTasks.removeAll()
        self.startTime = 0
        self.endTime = 0
        self.taskCount = 0
        self.taskCompletedCount = 0
    }
}

func transform(_ key: String) -> String {
    return key.replacingOccurrences(of: " ", with: "_")
        .replacingOccurrences(of: ".", with: "_")
        .replacingOccurrences(of: "-", with: "_")
        .replacingOccurrences(of: "/", with: "_")
}

// MARK: Assert Tracker

enum AssertEvent: String {
    case saveFile
    case initYYCache
    case missCleanConfig
}

func assert(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String = String(),
    event: AssertEvent,
    extra: [AnyHashable: Any]? = nil,
    file: String = #fileID,
    line: Int = #line
) {
    guard !condition() else { return }
    assertionFailure(message(), event: event, extra: extra, file: file, line: line)
}

func assertionFailure(
    _ message: @autoclosure () -> String = String(),
    event: AssertEvent,
    extra: [AnyHashable: Any]? = nil,
    file: String = #fileID,
    line: Int = #line
) {
    var extra = extra ?? [:]
    let msg = message()
    extra["msg"] = msg
    extra["file"] = file
    extra["line"] = "\(line)"

    Tracker.post(SlardarEvent(
        name: "lark_cache_assert",
        metric: [:],
        category: ["scene": event.rawValue],
        extra: extra
    ))
    Cache.logger.error("message: \(msg), event: \(event)", file: file, line: line)
    assertionFailure("message: \(msg), event: \(event)")
}
