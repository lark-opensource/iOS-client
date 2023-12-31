//
//  MemoryLeakTracker.swift
//  ByteViewTracker
//
//  Created by kiri on 2023/8/29.
//

import Foundation
import ByteViewCommon

public struct MemoryLeakTracker {

    /// 监控object是否泄漏
    /// - parameters:
    ///     - object: 被监控的对象
    ///     - event: 泄漏后要发送的事件
    ///     - delay: 多长时间后检测对象是否被释放，默认10秒
    public static func addJob<T: AnyObject>(_ object: T, event: DevTrackEvent, delay: DispatchTimeInterval = .seconds(10),
                                            associatedKey: String? = nil,
                                            file: String = #fileID, function: String = #function, line: Int = #line) {
        addJob(event: event, delay: delay, associatedKey: associatedKey,
               file: file, function: function, line: line) { [weak object] in object != nil }
    }

    /// 监控object是否泄漏
    /// - parameters:
    ///     - object: 被监控的对象
    ///     - event: 泄漏后要发送的事件
    ///     - delay: 多长时间后检测对象是否被释放，默认10秒
    public static func addJob(event: DevTrackEvent, delay: DispatchTimeInterval = .seconds(10),
                              associatedKey: String? = nil,
                              file: String = #fileID, function: String = #function, line: Int = #line,
                              isLeak: @escaping () -> Bool) {
        if AppInfo.shared.applicationState != .active {
            MemoryLeakDispatcher.shared.addJob(event: event, delay: delay, associatedKey: associatedKey,
                                               file: file, function: function, line: line, isLeak: isLeak)
            return
        }
        let startTime = CACurrentMediaTime()
        var trackEvent = event.toEvent()
        Queue.tracker.async {
            TrackCommonParams.fill(event: &trackEvent)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if isLeak() {
                let appState = AppInfo.shared.applicationState
                if appState != .active {
                    Logger.dev.warn("memoryLeak detected in \(appState.logDescription), action = \(event.action.actionName)")
                    MemoryLeakDispatcher.shared.addJob(event: event, delay: delay, associatedKey: associatedKey,
                                                       file: file, function: function, line: line, isLeak: isLeak)
                } else {
                    Queue.tracker.async {
                        trackEvent.params[.latency] = Int((CACurrentMediaTime() - startTime) * 1000)
                        if let associatedKey, let items = associatedItems[associatedKey] {
                            trackEvent.params[.content] = Set(items.compactMap { $0.item == nil ? nil : $0.name }).joined(separator: ",")
                        }
                        VCTracker.shared.trackDirectly(event: trackEvent, for: [.tea], fillCommonParams: false,
                                                       file: file, function: function, line: line)
                    }
                }
                assertionFailure("memory leak!")
            }
            if let associatedKey {
                Queue.tracker.async {
                    associatedItems.removeValue(forKey: associatedKey)
                }
            }
        }
    }

    public static func addAssociatedItem(_ item: AnyObject, name: String, for key: String) {
        Queue.tracker.async { [weak item] in
            if item != nil {
                associatedItems[key, default: []].append(MemoryLeakAssociatedItem(name: name, item: item))
            }
        }
    }

    private static var associatedItems: [String: [MemoryLeakAssociatedItem]] = [:]
}

//public protocol MemoryLeakAss

private struct MemoryLeakAssociatedItem {
    let name: String
    weak var item: AnyObject?
}

private class MemoryLeakDispatcher {
    static let shared = MemoryLeakDispatcher()
    private var jobItems: [JobItem] = []

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func didBecomeActive() {
        Queue.tracker.async {
            let items = self.jobItems
            self.jobItems = []
            items.forEach { item in
                MemoryLeakTracker.addJob(event: item.event, delay: item.delay, file: item.file, function: item.function, line: item.line,
                                         isLeak: item.isLeak)
            }
        }
    }

    func addJob(event: DevTrackEvent, delay: DispatchTimeInterval, associatedKey: String?, file: String, function: String, line: Int,
                isLeak: @escaping () -> Bool) {
        Queue.tracker.async {
            self.jobItems.append(JobItem(event: event, delay: delay, associatedKey: associatedKey, file: file, function: function, line: line, isLeak: isLeak))
        }
    }

    struct JobItem {
        let event: DevTrackEvent
        let delay: DispatchTimeInterval
        let associatedKey: String?
        let file: String
        let function: String
        let line: Int
        let isLeak: () -> Bool
    }
}
