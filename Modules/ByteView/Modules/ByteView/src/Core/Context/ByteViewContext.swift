//
//  ByteViewContext.swift
//  ByteView
//
//  Created by chentao on 2020/9/21.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import Reachability
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import EEAtomic
import QuartzCore
import ByteViewSetting
import LarkMedia
import ByteViewUI

/// 管理ByteView各对象（伪单例）的生命周期（user scope）。负责ByteView模块的初始化和销毁。
final class ByteViewContext {
    private let logDescription: String

    init(userId: String) {
        self.logDescription = ContextMonitor.measure(.logTag) {
            // 这里metadataDescription耗时太长，这里只取序号
            "ByteViewContext(\(ContextCounter.seqId.increment()))[\(userId)]"
        }
        ContextMonitor.allTasks {
            AsyncHelper.log("init \(logDescription)")
            _setup(userId: userId)
        }
    }

    deinit {
        AsyncHelper.log("deinit \(logDescription)")
        _destroy()
    }

    private func _setup(userId: String) {
        AsyncHelper.runInBackground {
            AsyncHelper.setup(userId: userId)
        }
    }

    private func _destroy() {
        let ts = CACurrentMediaTime()
        NoticeService.destroy()
        LanguageIconManager.destroy()
        ParticipantService.clearCache()
        ParticipantRelationTagService.clearAllCache()

        AsyncHelper.runInBackground {
            AsyncHelper.destroy()
        }
        let duration = (CACurrentMediaTime() - ts) * 1000
        AsyncHelper.log("destory \(logDescription): \(duration) ms")
    }
}

/// async
extension ByteViewContext {

    private class AsyncHelper {
        private static let queue = DispatchQueue(label: "lark.byteview.context.asyncQueue", qos: .default)

        static func runInBackground(_ block: @escaping () -> Void) {
            queue.asyncAfter(deadline: .now(), execute: block)
        }

        static func setup(userId: String) {
            ContextMonitor.measureAsyncTask(.planeTracker) {
                VCTracker.shared.setup(for: .plane) {
                    PlaneTracker(userId: userId)
                }
            }

            ContextMonitor.measureAsyncTask(.tools) {
                ProximityMonitor.isSharingScreen = false
                Keyboard.initialize()
            }

            ContextMonitor.measureAsyncTask(.reachability) {
                try? Reachability.shared.startNotifier()
            }

            ContextMonitor.measureAsyncTask(.track) {
                TrackContext.shared.reset(userId: userId)
            }
        }

        static func destroy() {
            Reachability.shared.stopNotifier()
        }

        static func log(_ msg: String, file: String = #fileID, function: String = #function, line: Int = #line) {
            Queue.logger.async {
                Logger.context.info(msg, file: file, function: function, line: line)
            }
        }
    }
}

extension ByteViewContext {
    private class ContextCounter {
        static var seqId = AtomicUInt64(0)
        static var isFirst: Bool { seqId.value < 2 }
    }

    private class ContextMonitor {
        private static var metrics: [String: Double] = [:]

        static func allTasks(code: () -> Void) {
            AsyncHelper.runInBackground {
                metrics = [:]
            }
            let startTime = CACurrentMediaTime()
            code()
            let endTime = CACurrentMediaTime()
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                let isBackground = UIApplication.shared.applicationState == .background
                AsyncHelper.runInBackground {
                    var duration = endTime - startTime
                    if let offset = metrics[Point.logTag.rawValue] {
                        duration += offset
                    }
                    AsyncHelper.log("task: total, cost: \(Util.formatTime(duration))")
                    metrics["total"] = duration

                    var event = TrackEvent(name: .vc_initialization_time)
                    let category: [String: Any] = [
                        "status": isBackground ? 1 : 0,
                        "is_first": ContextCounter.isFirst ? 1 : 0
                    ]
                    event.slardar = .init(metric: metrics, category: category)
                    VCTracker.post(event, platforms: [.slardar])
                }
            }
        }

        @discardableResult
        static func measure<T>(_ point: Point, code: () -> T) -> T {
            let startTime = CACurrentMediaTime()
            let obj = code()
            let endTime = CACurrentMediaTime()
            AsyncHelper.runInBackground {
                let duration = endTime - startTime
                let key = point.rawValue
                AsyncHelper.log("task: \(key), cost: \(Util.formatTime(duration))")
                metrics[key] = duration
            }
            return obj
        }

        static func measureAsyncTask(_ point: Point, code: () -> Void) {
            let startTime = CACurrentMediaTime()
            code()
            let duration = CACurrentMediaTime() - startTime
            let key = point.rawValue
            AsyncHelper.log("async task: \(key), cost: \(Util.formatTime(duration))")
            metrics[key] = duration
        }
    }

    enum Point: String, Equatable {
        case logTag
        case meetingPush
        case callKit
        case reachability
        case meetNotifyService
        case dependencies
        case tools
        case audioSession
        case debug
        case config
        case prefetchConfig
        case prefetchConfigOnColdStart
        case labService
        case track
        case mediaMutex
        case asyncHelper
        case planeTracker
        case threadMonitor
    }
}
