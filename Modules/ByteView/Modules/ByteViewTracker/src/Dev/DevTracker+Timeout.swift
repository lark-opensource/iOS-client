//
//  DevTracker+Timeout.swift
//  ByteViewTracker
//
//  Created by kiri on 2022/1/27.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

public extension DevTracker {
    private static let timeoutQueue = DispatchQueue(label: "ByteView.DevTracker.timeout", qos: .userInitiated)
    private static var timeoutEvents: [TimeoutKey: DispatchWorkItem] = [:]

    /// 监控事件是否超时
    /// - parameters:
    ///     - event: 超时后要发送的事件
    ///     - interval: 超时时间
    ///     - key: 用来标记事件的key，常为某个Id
    ///     - isPostLastEvent: 如果有还未超时的历史事件，是否立即发送该历史事件。如果为false，则会清除历史事件。默认为false
    static func timeout(event: DevTrackEvent, interval: DispatchTimeInterval, key: String, isPostLastEvent: Bool = false,
                        file: String = #fileID, function: String = #function, line: Int = #line) {
        let timeoutKey = TimeoutKey(action: event.action, key: key)
        event.params([.start_time: Int64(Date().timeIntervalSince1970 * 1000)])
        let startTime = CACurrentMediaTime()
        let item = DispatchWorkItem {
            event.params([.latency: Int((CACurrentMediaTime() - startTime) * 1000)])
            post(event, file: file, function: function, line: line)
        }
        timeoutQueue.async {
            if let oldValue = timeoutEvents.removeValue(forKey: timeoutKey) {
                if isPostLastEvent {
                    oldValue.perform()
                }
                /// perform并不会cancel队列里的
                oldValue.cancel()
            }
            timeoutEvents[timeoutKey] = item
        }
        timeoutQueue.asyncAfter(deadline: .now() + interval, execute: item)
        timeoutQueue.asyncAfter(deadline: .now() + interval + .milliseconds(100)) {
            if timeoutEvents[timeoutKey] === item {
                timeoutEvents.removeValue(forKey: timeoutKey)
            }
        }
    }

    /// 取消超时事件
    /// - parameters:
    ///     - action: 事件的action
    ///     - key: 用来标记事件的key，常为某个Id
    static func cancelTimeout(_ action: DevTrackEvent.Action, key: String) {
        timeoutQueue.async {
            timeoutEvents.removeValue(forKey: TimeoutKey(action: action, key: key))?.cancel()
        }
    }

    /// 取消所有该类型的事件
    static func cancelAllTimeout(_ action: DevTrackEvent.Action) {
        timeoutQueue.async {
            timeoutEvents = timeoutEvents.filter({ kv in
                if kv.key.action == action {
                    kv.value.cancel()
                    return false
                } else {
                    return true
                }
            })
        }
    }
}

extension DevTracker {
    struct TimeoutKey: Hashable {
        let action: DevTrackEvent.Action
        let key: String
    }
}
