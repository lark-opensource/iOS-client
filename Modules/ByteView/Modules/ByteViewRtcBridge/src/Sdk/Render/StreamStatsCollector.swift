//
//  StreamStatsCollector.swift
//  ByteView
//
//  Created by kiri on 2022/10/9.
//

import Foundation
import ByteViewCommon

final class StreamStatsCollector {
    private let statsLock = NSRecursiveLock()
    private var _subscriptionCount: Int = 0
    var subscriptionCount: Int { withStatsLock { _subscriptionCount } }

    private func withStatsLock<T>(action: () -> T) -> T {
        statsLock.lock()
        defer { statsLock.unlock() }
        return action()
    }

    func onSubscribeStream(key: RtcStreamKey) {
        let cnt = withStatsLock {
            _subscriptionCount += 1
            return _subscriptionCount
        }
        Logger.streamManager.info("[StreamStats] Stream Count: \(cnt)")
    }

    func onUnsubscribeStream(key: RtcStreamKey) {
        let cnt = withStatsLock {
            _subscriptionCount -= 1
            return _subscriptionCount
        }
        Logger.streamManager.info("[StreamStats] Stream Count: \(cnt)")
    }

    func reset() {
        withStatsLock {
            _subscriptionCount = 0
        }
    }
}
