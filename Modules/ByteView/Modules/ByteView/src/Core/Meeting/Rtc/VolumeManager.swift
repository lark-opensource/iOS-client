//
//  VolumeManager.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/4/8.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewSetting
import ByteViewRtcBridge

private struct VolumeEntry {
    let volume: Int
    let rtcUid: RtcUID
    let time: TimeInterval
}

protocol VolumeManagerDelegate: AnyObject {
    /// 当收到 rtc 用户音量变化的通知，或者过了一段时间以后没收到某用户音量通知时的回调。必定在主线程调用
    func volumeDidChange(to volume: Int, rtcUid: RtcUID)
}

class VolumeManager: RtcActiveSpeakerListener {
    private var orderedCache: [VolumeEntry] = []
    private let listeners = Listeners<VolumeManagerDelegate>()
    private var timer: Timer?
    private let queue = DispatchQueue(label: "lark.byteview.rtc.volumes")
    private static let expirationTime: TimeInterval = 1
    // 计算最小时间间隔，单位秒
    private static let tickTime: UInt = 1
    // 每criticalTime次音量回调计算一次volume，其数值由tickTime计算得出
    private let criticalTime: UInt

    init(engine: InMeetRtcEngine, setting: MeetingSettingManager) {
        let asConfig = setting.activeSpeakerConfig
        let tickTimeMill = Self.tickTime * 1000
        self.criticalTime = tickTimeMill >= asConfig.reportInterval ? tickTimeMill / asConfig.reportInterval : 1
        let timer = Timer(timeInterval: Self.expirationTime, repeats: true, block: { [weak self] _ in
            self?.queue.async {
                self?.checkExpirations()
            }
        })
        RunLoop.main.add(timer, forMode: .default)
        self.timer = timer
        engine.addAsListener(self)
    }

    deinit {
        invalidate()
    }

    func addListener(_ listener: VolumeManagerDelegate) {
        listeners.addListener(listener)
        for volumeEntry in orderedCache {
            listener.volumeDidChange(to: volumeEntry.volume, rtcUid: volumeEntry.rtcUid)
        }
    }

    func removeListener(_ listener: VolumeManagerDelegate) {
        listeners.removeListener(listener)
    }

    func invalidate() {
        timer?.invalidate()
        timer = nil
    }

    private func add(volume: Int, with rtcUid: RtcUID) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let entry = VolumeEntry(volume: volume, rtcUid: rtcUid, time: Date().timeIntervalSince1970)
            self.insert(entry)
            DispatchQueue.main.async {
                self.listeners.forEach { $0.volumeDidChange(to: volume, rtcUid: rtcUid) }
            }
        }
    }

    // O(n), n == current num of items
    private func insert(_ entry: VolumeEntry) {
        orderedCache.removeAll { $0.rtcUid == entry.rtcUid }
        if entry.volume != 0 {
            orderedCache.append(entry)
        }
    }

    // O(k), k == num of items to be deleted
    private func checkExpirations() {
        var toBeDeleted: [VolumeEntry] = []
        while let first = orderedCache.first, Date().timeIntervalSince1970 - first.time > 1 {
            toBeDeleted.append(first)
            orderedCache.removeFirst()
        }
        DispatchQueue.main.async {
            for entry in toBeDeleted {
                self.listeners.forEach { $0.volumeDidChange(to: 0, rtcUid: entry.rtcUid) }
            }
        }
    }

    private var currentRecordTime: UInt = 0
    private var volumnCache: [RtcUID: RtcAudioVolumeInfo] = [:]
    func didReceiveRtcVolumeInfos(_ infos: [RtcAudioVolumeInfo]) {
        guard criticalTime > 1 else {
            for info in infos {
                self.add(volume: info.linearVolume, with: info.uid)
            }
            return
        }
        currentRecordTime += 1
        for info in infos {
            volumnCache[info.uid] = info
        }
        if currentRecordTime == 1 || currentRecordTime % criticalTime == 0 {
            let volumnInfos = volumnCache.values
            for info in volumnInfos {
                self.add(volume: info.linearVolume, with: info.uid)
            }
            volumnCache.removeAll()
        }
    }
}
