//
//  InMeetAudioViewModel.swift
//  ByteView
//
//  Created by kiri on 2021/5/14.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import AVFoundation
import LarkMedia

final class InMeetAudioViewModel {
    static let logger = Logger.ui

    var meeting: InMeetMeeting { resolver.meeting }

    private var isFirstTryMuteSelf: Bool = true

    let disposeBag = DisposeBag()
    let resolver: InMeetViewModelResolver
    private let audioSessionTracker: InMeetAudioSessionTracker

    init(resolver: InMeetViewModelResolver) {
        self.resolver = resolver
        self.audioSessionTracker = InMeetAudioSessionTracker(service: resolver.meeting.service)

        bindAudioSwitch()
        checkNearbyRoom()
    }

    private func bindAudioSwitch() {
        let output = meeting.audioDevice.output
        ProximityMonitor.updateAudioOutput(route: output.currentOutput, isMuted: output.isMuted)
        output.addListener(self)
    }

    private var nearbyRoomMuter: NearbyRoomMuter?
    /// 若与附近Room在同一会中，则需要muteSelf、以避免回声
    private func checkNearbyRoom() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let nearbyRoomMuter = NearbyRoomMuter(meeting: self.meeting)
            if !nearbyRoomMuter.done {
                nearbyRoomMuter.onCompletion = { [weak self] in
                    self?.nearbyRoomMuter = nil
                }
                self.nearbyRoomMuter = nearbyRoomMuter
            }
        }
    }
}

extension InMeetAudioViewModel: AudioOutputListener {
    func didChangeAudioOutput(_ output: AudioOutputManager, reason: AudioOutputChangeReason) {
        ProximityMonitor.updateAudioOutput(route: output.currentOutput, isMuted: output.isMuted)
    }
}

extension InMeetAudioViewModel {
    private class NearbyRoomMuter: InMeetParticipantListener, InMeetRtcNetworkListener {
        @RwAtomic var isConnected: Bool
        @RwAtomic var done = false
        @RwAtomic var isFullParticipantsRecevied: Bool
        var onCompletion: (() -> Void)?
        let meeting: InMeetMeeting
        init(meeting: InMeetMeeting) {
            self.meeting = meeting
            self.isFullParticipantsRecevied = meeting.participant.isFullParticipantsReceived
            self.isConnected = meeting.rtc.network.reachableState == .connected
            if !self.isFullParticipantsRecevied {
                meeting.participant.addListener(self)
            }
            if !self.isConnected {
                meeting.rtc.network.addListener(self)
            }
            trigger()
        }

        func didChangeRtcReachableState(_ state: InMeetRtcReachableState) {
            if state == .connected {
                self.isConnected = true
                self.trigger()
            }
        }

        func didChangeGlobalParticipants(_ output: InMeetParticipantOutput) {
            if meeting.participant.isFullParticipantsReceived {
                self.isFullParticipantsRecevied = true
                self.trigger()
            }
        }

        private func trigger() {
            if !self.done, self.isFullParticipantsRecevied, self.isConnected {
                self.done = true
                self.run()
                onCompletion?()
            }
        }

        private func run() {
            // 需保证 已有参会人信息 && rtc join channel完成（因为需要跟在setupSettings之后)
            if let nearbyRoomID = self.meeting.joinMeetingParams?.nearbyRoomID,
               meeting.participant.find(in: .global, { $0.type == .room && $0.user.id == nearbyRoomID }) != nil {
                // 确保覆盖Toast.showAudioContent的初始toast
                self.meeting.canShowAudioToast = false
                // nolint-next-line: magic number
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.meeting.canShowAudioToast = true
                }

                if !self.meeting.microphone.isMuted {
                    self.meeting.microphone.muteMyself(true, source: .nearby_room, showToastOnSuccess: false, completion: nil)
                    Logger.audio.info("mic off for room recognized by ultrawave")
                }

                // 连接蓝牙或线控耳机时，不需要扬声器静音
                let currentOutput = self.meeting.audioDevice.output.currentOutput
                let isOutputAutoMuteEnabled = currentOutput == .speaker || currentOutput == .receiver
                if isOutputAutoMuteEnabled && !self.meeting.audioDevice.output.isMuted {
                    self.meeting.audioDevice.output.setMuted(true)
                    Logger.audioSession.info("AudioOutput muted for room recognized by ultrawave")
                }
                Toast.show(BundleI18n.ByteView.View_MV_MicAndSpeakerOff)
            }
        }
    }
}

extension InMeetMeeting {
    func disableAudioToastFor(interval: DispatchTimeInterval) {
        self.canShowAudioToast = false
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
            self?.canShowAudioToast = true
        }
    }
}
