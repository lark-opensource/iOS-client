//
//  InMeetActiveSpeakerViewModel.swift
//  ByteView
//
//  Created by kiri on 2021/5/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker
import ByteViewNetwork
import ByteViewRtcBridge

protocol InMeetActiveSpeakerListener: AnyObject {
    func didChangeActiveSpeaker(_ rtcUid: RtcUID?, oldValue: RtcUID?)
    func didChangeLastActiveSpeaker(_ rtcUid: RtcUID, oldValue: RtcUID?)
}

extension InMeetActiveSpeakerListener {
    func didChangeActiveSpeaker(_ rtcUid: RtcUID?, oldValue: RtcUID?) {}
    func didChangeLastActiveSpeaker(_ rtcUid: RtcUID, oldValue: RtcUID?) {}
}

final class InMeetActiveSpeakerViewModel: InMeetDataListener, RtcActiveSpeakerListener, InMeetParticipantListener {
    static let logger = Logger.ui

    private let meeting: InMeetMeeting
    private let maxRecordTime: UInt
    private let criticalTime: UInt
    private let timeBase: Float
    private let rankBase: Float
    private let tickTime: Int
    private let minSpeakerVolume: Int
    private let holdSeconds: Double
    private let maxIndex: Int
    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        let asConfig = meeting.setting.activeSpeakerConfig
        self.timeBase = log2(asConfig.timeBase)
        self.rankBase = asConfig.rankBase
        self.maxRecordTime = asConfig.maxRecordTime / asConfig.tickTime
        self.criticalTime = asConfig.tickTimeMill >= asConfig.reportInterval ? asConfig.tickTimeMill / asConfig.reportInterval : 1
        self.tickTime = Int(asConfig.tickTime)
        self.minSpeakerVolume = asConfig.minSpeakerVolume
        self.holdSeconds = Double(asConfig.holdTimeMs) / 1000
        let vsConfig = meeting.setting.videoSortConfig
        self.maxIndex = Int(vsConfig.maxIndex)

        meeting.data.addListener(self)
        meeting.participant.addListener(self)
        meeting.rtc.engine.addAsListener(self)
    }

    /// rtcUid, 之前最后一个发言的人（如果当前有人发言，就是当前发言的人）
    private(set) var lastActiveSpeaker: RtcUID?
    /// rtcUid, 当前正在发言的人
    private(set) var currentActiveSpeaker: RtcUID?
    /// rtcUid, 倒数第二个发言的人
    private(set) var secondLastActiveSpeaker: RtcUID?
    private(set) var activeSpeakerIdentifier: ByteviewUser?
    private let listeners = Listeners<InMeetActiveSpeakerListener>()

    func addListener(_ listener: InMeetActiveSpeakerListener, fireImmediately: Bool = true) {
        listeners.addListener(listener)
        if fireImmediately {
            if let asId = currentActiveSpeaker {
                listener.didChangeActiveSpeaker(asId, oldValue: nil)
            }
            if let asId = lastActiveSpeaker {
                listener.didChangeLastActiveSpeaker(asId, oldValue: nil)
            }
        }
    }

    func removeListener(_ listener: InMeetActiveSpeakerListener) {
        listeners.removeListener(listener)
    }

    private var filteredSpeakerIds: Set<RtcUID> = []

    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        //过滤掉同传参会人
        let filteredSpeakerIds = Set(meeting.participant.currentRoom.nonRingingDict.filter({ $0.value.isInterpreter }).map { $0.value.rtcUid })
        calcAsQueue.async { [weak self] in
            self?.filteredSpeakerIds = filteredSpeakerIds
        }
    }

    func didReceiveRtcVolumeInfos(_ infos: [RtcAudioVolumeInfo]) {
        calcAsQueue.async { [weak self] in
            guard let self = self else { return }
            let speakers = infos.filter { !self.filteredSpeakerIds.contains($0.uid) }
            self.calculateActiveSpeaker(audioVolumeOfSpeakers: speakers)
        }
        let minSpeakerVolume = minSpeakerVolume
        monitorQueue.async { [weak self] in
            guard let self = self else { return }
            infos.filter { $0.nonlinearVolume > minSpeakerVolume }.forEach { asInfo in
                guard let p = self.meeting.participant.find(rtcUid: asInfo.uid, in: .activePanels),
                      p.settings.isMicrophoneMutedOrUnavailable, p.user != self.meeting.account else {
                          return
                      }
                VCTracker.post(name: .vc_mute_status_conflict_dev,
                               params: [.from_source: "active_speaker", "target_device_id": p.rtcUid])
            }
        }
    }

    private let calcAsQueue = DispatchQueue(label: "lark.vc.as.calcActiveSpeaker", qos: .userInitiated)
    private let monitorQueue = DispatchQueue(label: "lark.vc.as.monitor", qos: .userInitiated)
    private var currentRecordTime: UInt = 0
    private var validVolumeRecords: [[RtcAudioVolumeInfo]] = []
    private var lastEmptyLogTime: TimeInterval = 0

    /// active user 算法文档: https://bytedance.feishu.cn/space/doc/doccn9VMQp6VgYaMNoIkZh#
    private func calculateActiveSpeaker(audioVolumeOfSpeakers: [RtcAudioVolumeInfo]) {
        // 记录次数处理
        currentRecordTime += 1
        if audioVolumeOfSpeakers.isEmpty {
            validVolumeRecords.append([])
            updateActiveSpeakerUid(nil)
            return
        }

        // 不发言时volume=0；发言时volume in [-127, 0)，且音量与volume正相关
        let validVolumeInfos = audioVolumeOfSpeakers.filter { $0.nonlinearVolume < 0 && $0.nonlinearVolume > minSpeakerVolume }
        if validVolumeInfos.isEmpty {
            let current = Date.timeIntervalSinceReferenceDate
            if current - lastEmptyLogTime > 60 {
                // 这个log太频繁了，限制一下1分钟打印一次
                lastEmptyLogTime = current
                Self.logger.debug("the valid volume of speakers is empty when calculate active speaker")
            }
        } else {
            lastEmptyLogTime = 0
        }
        // 如果达到了计算的临界点则开始计算
        if currentRecordTime == 0 || currentRecordTime % (criticalTime) == 0 {
            let ranks = validVolumeInfos.map { $0.nonlinearVolume }.uniqued().sorted(by: >).enumerated()
                .reduce(into: [:]) { $0[$1.1] = $1.0 + 1 }

            // 计算权重排名
            let weights = validVolumeInfos.map { (info) -> (RtcUID, Float) in
                let rank = ranks[info.nonlinearVolume] ?? 0
                let time = validVolumeRecords.map { $0.filter { $0.uid == info.uid }.count }.reduce(0, +)
                let rw = rank > 0 ? rankBase / Float(rank) : 0.0
                let tw = time > 1 ? log2(Float(time)) / timeBase : 0.0
                let weight = rw + tw
                return (info.uid, weight)
            }.sorted { $0.1 > $1.1 }
            let uid = weights.first?.0
            updateActiveSpeakerUid(uid)
        }

        // 缓存用户说话次数
        validVolumeRecords.append(validVolumeInfos)
        if currentRecordTime > maxRecordTime {
            validVolumeRecords.removeFirst()
        }
    }

    var holdingActiveSpeaker: (RtcUID, TimeInterval)?

    private func updateActiveSpeakerUid(_ asUid: RtcUID?) {
        if let asUid = asUid {
            //过滤掉自己静音的情况
            if meeting.myself.rtcUid == asUid, meeting.microphone.isMuted {
                return
            }
            updateActiveSpeaker(asUid)
        } else {
            if holdSeconds > 0 {
                // 无人发言时，AS延迟一段时间后才消失
                if let oldId = self.currentActiveSpeaker, holdingActiveSpeaker == nil {
                    Self.logger.debug("start holding old active speaker: \(oldId)")
                    let startTime = Date().timeIntervalSince1970
                    holdingActiveSpeaker = (oldId, startTime)
                    DispatchQueue.global().asyncAfter(deadline: .now() + holdSeconds) { [weak self] in
                        self?.calcAsQueue.async { [weak self] in
                            if self?.holdingActiveSpeaker?.1 == startTime {
                                self?.updateActiveSpeaker(nil)
                            }
                        }
                    }
                }
            } else {
                updateActiveSpeaker(nil)
            }
        }
    }

    private func updateActiveSpeaker(_ asUid: RtcUID?) {
        self.holdingActiveSpeaker = nil
        if self.currentActiveSpeaker == asUid {
            return
        }
        Self.logger.debug("active speaker id = \(asUid)")
        let oldId = self.currentActiveSpeaker
        self.currentActiveSpeaker = asUid
        if let currentId = asUid, currentId != self.lastActiveSpeaker {
            let oldLastId = self.lastActiveSpeaker
            self.secondLastActiveSpeaker = self.lastActiveSpeaker
            self.lastActiveSpeaker = currentId
            self.listeners.forEach { $0.didChangeLastActiveSpeaker(currentId, oldValue: oldLastId) }
        }
        self.listeners.forEach { $0.didChangeActiveSpeaker(asUid, oldValue: oldId) }
    }
}

struct ActiveSpeakerSpeakingTime {
    let start: Double
    var end: Double?

    /// 在距离 now 之前 period 秒之内是否说过话，now 在外界传入可以消除一次循环中多次获取 Date() 的耗时
    func isSpeaking(in period: Double, now: Double?) -> Bool {
        let _now = now ?? Date().timeIntervalSinceReferenceDate
        if let end = end {
            return (_now - end) <= period
        } else {
            return true
        }
    }
}

struct ActiveSpeakerInfo {
    let rtcUid: RtcUID
    let pid: ByteviewUser
    var speakingTimes: [ActiveSpeakerSpeakingTime] = []
    var isSpeaking: Bool = true

    func speakingSeconds(in timeScope: Int) -> Double {
        let now = Date().timeIntervalSinceReferenceDate
        let startScopeTime = now - Double(timeScope)
        var speakingSeconds: Double = 0
        var index = speakingTimes.count - 1
        while index >= 0 {
            if let endTime = speakingTimes[index].end, endTime <= startScopeTime {
                break
            }
            if let endTime = speakingTimes[index].end {
                speakingSeconds += (endTime - max(speakingTimes[index].start, startScopeTime))
            } else {
                speakingSeconds += (now - max(speakingTimes[index].start, startScopeTime))
            }
            index -= 1
        }
        return speakingSeconds
    }
}
