//
//  InMeetJoinRoomProvider.swift
//  ByteView
//
//  Created by kiri on 2022/4/13.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import AVFoundation
import LarkMedia

final class InMeetJoinRoomProvider: JoinRoomTogetherViewModelProvider, InMeetDataListener {
    private let meeting: InMeetMeeting
    let initialRoom: ByteviewUser?
    let isInMeet: Bool = true

    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        self.initialRoom = meeting.myself.settings.targetToJoinTogether
    }

    var shareCodeFilter: GetShareCodeInfoRequest.RoomBindFilter {
        .generic(.meetingId(meeting.meetingId, nil))
    }

    func prepareScan(completion: @escaping () -> Void) {
        meeting.canShowAudioToast = false
        meeting.callCoordinator.muteCallMicrophone(muted: false)
        if #available(iOS 17.0, *), !meeting.isCallKit {
            meeting.microphone.prepareForRecvingUltrawave()
        }
        meeting.audioDevice.output.setNoConnect(true)
        meeting.rtc.engine.setRuntimeParameters(["rtc.au_stop_with_dispose": true])
        meeting.microphone.stopAudioCapture()
        completion()
    }

    func resetAfterScan() {
        if #available(iOS 17.0, *), !meeting.isCallKit {
            meeting.microphone.recoverForRecvingUltrawave()
        }
        if meeting.audioMode == .internet {
            meeting.rtc.engine.setRuntimeParameters(["rtc.au_stop_with_dispose": false])
            meeting.microphone.startAudioCapture(scene: .changeToSystemAudio)
            meeting.audioDevice.output.setNoConnect(false)
        }
        meeting.callCoordinator.muteCallMicrophone(muted: meeting.microphone.isMuted)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {  [weak self] in
            self?.meeting.canShowAudioToast = true
        }
    }

    func connectRoom(_ room: ByteviewUser, completion: @escaping (Result<Void, Error>) -> Void) {
        let request = JoinMeetingTogetherRequest(meetingId: meeting.meetingId, target: room)
        httpClient.send(request, completion: completion)
    }

    func disconnectRoom(_ room: ByteviewUser?, completion: @escaping (Result<Void, Error>) -> Void) {
        var request = ParticipantChangeSettingsRequest(meeting: meeting)
        request.participantSettings.syncRoom = .init(targetToJoinTogether: nil)
        request.participantSettings.audioMode = .internet
        request.changeAudioReason = .changeAudio
        httpClient.send(request, completion: completion)
    }

    func fetchRoomInfo(_ room: ByteviewUser, completion: @escaping (ParticipantUserInfo) -> Void) {
        httpClient.participantService.participantInfo(pid: room, meetingId: meeting.meetingId, completion: completion)
    }

    var shouldDoubleCheckDisconnection: Bool { true }

    var popoverFrom: JoinRoomPopoverFrom { .inMeet }

    var isSharingContent: Bool { meeting.shareData.isSharingContent }

    var supportedInterfaceOrientations: UIInterfaceOrientationMask { .allButUpsideDown }

    var httpClient: HttpClient { meeting.httpClient }
}
