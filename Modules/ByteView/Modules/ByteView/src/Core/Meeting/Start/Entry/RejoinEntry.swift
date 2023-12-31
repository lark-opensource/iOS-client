//
//  RejoinEntry.swift
//  ByteView
//
//  Created by kiri on 2023/6/18.
//

import Foundation
import ByteViewMeeting
import ByteViewNetwork
import ByteViewUI
import ByteViewTracker

extension MeetingPrechecker {
    func handleRejoinEntry(_ session: MeetingSession, params: RejoinParams, completion: @escaping PrecheckOutput) {
        guard let service = session.service else { return }
        log.info("handleRejoinEntry, params = \(params)")

        let context = MeetingPrecheckContext(service: service)
        let entrance = RejoinEntrance(params: params, context: context)
        session.precheckEntrance = entrance
        entrance.precheck(context: context) {
            switch $0 {
            case .success:
                completion(.success(.rejoin))
            case .failure(let e):
                completion(.failure(e))
            }
        }
    }
}

extension MeetingSession {
    func rejoinMeeting(_ params: RejoinParams) {
        self.isE2EeMeeting = params.info.settings.isE2EeMeeting
        switch params.type {
        case .registerClientInfo:
            self.rejoinWithRegisterClientInfo(forceDeblock: false, info: params.info)
        case .streamingLost:
            self.service?.router.startRoot(ConnectFailedBody(session: self), animated: false)
        }
    }

    private func rejoinWithRegisterClientInfo(forceDeblock: Bool, info: VideoChatInfo) {
        OnthecallReciableTracker.startEnterOnthecall()
        slaTracker.startEnterOnthecall()
        // 生成hud
        let hud = self.service?.larkRouter.showLoading(with: I18n.View_VM_Loading)
        let role = info.participant(byUser: self.account)?.meetingRole ?? .participant
        self.isE2EeMeeting = info.settings.isE2EeMeeting
        // 会议rejoin请求
        rejoinMeeting(forceDeblock: forceDeblock, meetingRole: role, leaveOnError: false) { [weak self] r in
            hud?.remove()
            if let error = r.error {
                OnthecallReciableTracker.cancelStartOnthecall()
                self?.slaTracker.endEnterOnthecall(success: self?.slaTracker.isSuccess(error: error.toVCError()) ?? false)
                self?.handleRegisterClientInfoError(error.toVCError(), info: info)
            }
        }
    }

    private func handleRegisterClientInfoError(_ error: VCError, info: VideoChatInfo) {
        if error == .hostIsInVC {
            // 如果其他设备上vc忙线则弹出alertview
            // 弹出alert弹框
            ByteViewDialog.Builder()
                .id(.exitCallByJoinMeeting)
                .title(I18n.View_M_JoinMeetingQuestion)
                .message(I18n.View_M_LeaveAndJoinQuestion)
                .leftTitle(I18n.View_G_CancelButton)
                .leftHandler({ [weak self] _ in
                    self?.leave()
                })
                .rightTitle(I18n.View_G_ConfirmButton)
                .rightHandler({ [weak self] _ in
                    JoinTracks.trackLarkHint()
                    self?.rejoinWithRegisterClientInfo(forceDeblock: true, info: info)
                })
                .show()
        } else {
            if error == .unknown {
                Toast.show(I18n.View_M_FailedToJoinMeeting)
            } else if error.isHandled {
                // 忽略经过通用错误处理的 Error
            } else {
                Toast.show(error.description)
            }
            leave()
        }
    }
}
