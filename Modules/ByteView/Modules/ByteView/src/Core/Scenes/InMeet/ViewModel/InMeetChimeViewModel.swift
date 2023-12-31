//
//  InMeetChimeViewModel.swift
//  ByteView
//
//  Created by fakegourmet on 2023/4/27.
//

import Foundation
import ByteViewSetting

final class InMeetChimeViewModel: InMeetParticipantListener {

    /// 替换播放器
    typealias AudioPlayer = LocalAudioPlayer

    static let logger = Logger.audio

    private let meeting: InMeetMeeting
    private let player: ChimePlayer<AudioPlayer>
    private let strategy: ChimeStrategy

    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        self.player = ChimePlayerFactory<AudioPlayer>().create(meeting: meeting)
        self.strategy = ChimeStrategyFactory().create(meeting: meeting)

        meeting.addListener(self)
        meeting.participant.addListener(self, fireImmediately: false)

        // 自己入会，但替代入会不需要提示音
        if strategy.shouldPlaySelfChime && !meeting.myself.replaceOtherDevice {
            player.play(.enterMeeting)
        }
    }

    func didChangeGlobalParticipants(_ output: InMeetParticipantOutput) {
        defer { strategy.update() }
        guard strategy.shouldPlayOtherChime else {
            return
        }
        let change = output.modify.nonRinging
        // 非本人离会；被替代离会不需要提示音
        if change.removes.contains(where: { $0.value != meeting.myself && $0.value.offlineReason != .otherDeviceReplaced }) {
            player.schedule(.leaveMeeting)
        }
        // 非本人入会；替代入会不需要提示音
        if change.inserts.contains(where: { $0.value != meeting.myself && !$0.value.replaceOtherDevice }) {
            player.schedule(.enterMeeting)
        }
    }
}

extension InMeetChimeViewModel: InMeetMeetingListener {
    func willReleaseInMeetMeeting(_ meeting: InMeetMeeting) {
        // 自己离会
        // deinit 时机略晚，放 release 回调中
        if strategy.shouldPlaySelfChime && meeting.myself.offlineReason != .otherDeviceReplaced {
            player.play(.leaveMeeting)
        }
    }
}
