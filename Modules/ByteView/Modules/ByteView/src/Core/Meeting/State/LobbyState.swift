//
//  LobbyState.swift
//  ByteView
//
//  Created by kiri on 2021/2/25.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewMeeting
import LarkMedia
import ByteViewUI
import ByteViewSetting

class BaseLobbyState: MeetingComponent, VCManageResultPushObserver {
    let lobbyInfo: LobbyInfo
    private let session: MeetingSession
    private var httpClient: HttpClient { session.httpClient }
    required init?(session: MeetingSession, event: MeetingEvent, fromState: MeetingState) {
        guard let info = event.lobbyInfo else { return nil }
        self.session = session
        self.lobbyInfo = info
        entry(from: fromState, session: session)
    }

    func willReleaseComponent(session: MeetingSession, event: MeetingEvent, toState: MeetingState) {
        exit()
    }

    func entry(from: MeetingState, session: MeetingSession) {
        session.setting?.updatePrestartContext(.lobbyInfo(lobbyInfo))
        let meetingId = lobbyInfo.meetingId

        session.audioDevice?.lockState()
        session.audioDevice?.output.setPadMicSpeakerDisabledIfNeeded()

        //可感知耗时埋点存在一种情况: preview/ringing -> waiting -> onthecall，此时需要把onthecall的开始埋点删除
        OnthecallReciableTracker.cancelStartOnthecall()
        if from == .onTheCall {
            // 会中被移入等候室，更新interactiveId
            TrackContext.shared.updateContext(for: session.sessionId, block: { $0.update(interactiveId: lobbyInfo.lobbyParticipant?.interactiveId) })
            // 移除弹窗
            ByteViewDialogManager.shared.triggerAutoDismiss()
        }
        httpClient.send(StartHeartbeatRequest(meetingId: meetingId, type: .vclobby))
        session.push?.vcManageResult.addObserver(self)
    }

    func exit() {
        httpClient.send(StopHeartbeatRequest(meetingId: lobbyInfo.meetingId, type: .vclobby))
    }

    func didReceiveManageResult(_ message: VCManageResult) {
        if message.meetingID == session.meetingId, message.type == .meetinglobby {
            session.log("didReceiveLobbyAction: \(message.action)")
            switch message.action {
            case .vcMeetingNotSupport:
                session.log("meeting not support lobby")
                Toast.show(I18n.View_M_RemovedFromLobby)
                session.leave(.lobbyNotSupport)
            case .hostreject:
                session.leave(.hostRejectLobby)
            case .meetingend:
                session.leave(.meetingHasFinished)
            default:
                break
            }
        }
    }
}

final class LobbyState: BaseLobbyState {
    override func entry(from: MeetingState, session: MeetingSession) {
        super.entry(from: from, session: session)
        if lobbyInfo.lobbyParticipant?.joinReason == .hostMove {
            session.audioDevice?.output.moveToLobby()
        }
        session.service?.router.startRoot(LobbyBody(session: session))
    }
}

final class PreLobbyState: BaseLobbyState {
    override func entry(from: MeetingState, session: MeetingSession) {
        super.entry(from: from, session: session)
        session.service?.router.startRoot(PrelobbyBody(session: session), animated: false)
    }
}
