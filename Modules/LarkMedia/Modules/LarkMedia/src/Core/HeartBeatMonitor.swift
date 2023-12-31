//
//  HeartBeatMonitor.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/12/12.
//

import Foundation
import LKCommonsLogging

protocol HeartBeatMonitorDelegate: AnyObject, Hashable {
    func didTimeout()
}

extension HeartBeatMonitorDelegate {
    func didTimeout() {}
}

class HeartBeatMonitor<T: HeartBeatMonitorDelegate> {

    let logger = Logger.log(HeartBeatMonitor.self, category: "LarkMedia.HeartBeatMonitor")

    private enum State {
        case suspended
        case resumed
    }
    private var state: State = .suspended

    @RwAtomic
    private var observableMap: [TimeInterval: WeakRef<T>] = [:]

    private let queue = DispatchQueue(label: "LarkMedia.HeartBeat")

    /// 检测间隔(s)
    private let interval: Int
    /// 最大时间(s)
    private let duration: Double

    private let timer: DispatchSourceTimer

    init(interval: Int, duration: Double) {
        self.interval = interval
        self.duration = duration
        self.timer = DispatchSource.makeTimerSource(queue: queue)
        setup()
    }

    deinit {
        timer.setEventHandler {}
        timer.cancel()
        // 防止 crash
        resume()
    }

    private func setup() {
        timer.setEventHandler(handler: DispatchWorkItem { [weak self] in
            self?.checkHeartBeat()
        })
        timer.schedule(deadline: .now(), repeating: .seconds(interval))
    }

    private func resume() {
        guard state == .suspended else {
            return
        }
        state = .resumed
        timer.resume()
    }

    private func suspend() {
        guard state == .resumed else {
            return
        }
        state = .suspended
        timer.suspend()
    }

    private func checkHeartBeat() {
        let currentTime = Date().timeIntervalSince1970
        for (startTime, obj) in observableMap {
            if let obj = obj.value, currentTime - startTime > duration {
                logger.warn("observable heart beat timeout: \(obj)")
                obj.didTimeout()
                removeObservable(obj)
            }
        }
    }

    func addObservable(_ obj: T) {
        logger.debug("add observable: \(obj)")
        observableMap[Date().timeIntervalSince1970] = WeakRef(obj)
        if !observableMap.isEmpty {
            resume()
        }
    }

    func removeObservable(_ obj: T) {
        if let index = observableMap.firstIndex(where: { (_, v) in
            v.value == obj
        }) {
            logger.debug("remove observable: \(obj)")
            observableMap.remove(at: index)
        }
        if observableMap.isEmpty {
            suspend()
        }
    }
}

extension SceneMediaConfig: HeartBeatMonitorDelegate {
    func didTimeout() {
        AudioTracker.shared.trackAudioBusinessEvent(event: AudioTrackKey.mediaLockLeak.rawValue, params: ["object": scene])
    }
}

extension AudioSessionScenarioWrapper: HeartBeatMonitorDelegate {
    func didTimeout() {
        AudioTracker.shared.trackAudioBusinessEvent(event: AudioTrackKey.audioSessionScenarioLeak.rawValue, params: ["object": scenario.name])
    }
}
