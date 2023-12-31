//
//  InMeetMyselfViewModel.swift
//  ByteView
//
//  Created by kiri on 2022/8/18.
//

import Foundation
import ByteViewTracker
import ByteViewNetwork

/// 处理myself的settings变化
final class InMeetMyselfViewModel: InMeetViewModelComponent, MyselfListener {
    private let meeting: InMeetMeeting
    private let logger = Logger.meeting

    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        handleInitialSettings()
        meeting.addMyselfListener(self, fireImmediately: false)
    }

    private func handleInitialSettings() {
        let settings = meeting.myself.settings
        if let room = settings.targetToJoinTogether, room.type == .room {
            if Display.phone {
                /// pad在topBar上显示tips
                VCTracker.post(name: .vc_toast_status, params: ["toast_name": "ultrasonic_sync_join_success", "connect_type": "onthecall"])
                Toast.show(I18n.View_G_WowPairedRoomAudio)
            }
        } else if settings.audioMode == .noConnect && !meeting.audioModeManager.isJoinPstnCalling {
            // 无音频入会toast异化
            Toast.show(I18n.View_MV_NoConnectCantHearOther)
        } else if settings.audioMode == .pstn {
            Toast.show(I18n.View_MV_UsinPhoneAudio)
        }
        meeting.audioDevice.output.setNoConnect(settings.audioMode != .internet)
    }

    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        let settings = myself.settings
        let oldSettings = oldValue?.settings
        if settings == oldSettings { return }
        Logger.ui.info("handle myself settings changed: \(settings), oldValue: \(oldSettings)")

        handleJoinTogether(settings.targetToJoinTogether, oldValue: oldSettings?.targetToJoinTogether)
    }

    private func handleJoinTogether(_ target: ByteviewUser?, oldValue: ByteviewUser?) {
        guard Display.phone else { return }
        if let room = oldValue, room.type == .room, target == nil {
            let participantService = meeting.httpClient.participantService
            participantService.participantInfo(pid: room, meetingId: meeting.meetingId, completion: { [weak self] info in
                if self != nil {
                    VCTracker.post(name: .vc_toast_status, params: ["toast_name": "ultrasonic_sync_disconnect"])
                    Toast.show(I18n.View_MV_DisconnectRoomAlready_Toast(info.name))
                }
            })
        }
    }
}
