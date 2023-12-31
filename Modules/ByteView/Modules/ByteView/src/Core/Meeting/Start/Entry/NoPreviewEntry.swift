//
//  SimpleNoPreviewEntry.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/6/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewMeeting
import ByteViewSetting

extension MeetingPrechecker {
    func handleNoPreviewEntry(_ session: MeetingSession, params: NoPreviewParams, completion: @escaping PrecheckOutput) {
        guard let service = session.service else { return }
        log.info("handleNoPreviewEntry start, params = \(params)")
        let context = MeetingPrecheckContext(service: service, slaTracker: session.slaTracker)
        let entrance = NoPreviewEntrance(params: params, context: context)
        session.precheckEntrance = entrance
        entrance.precheck(context: context) {
            switch $0 {
            case .success:
                completion(.success(.noPreview))
            case .failure(let e):
                completion(.failure(e))
            }
        }
    }
}

extension MeetingSession {
    func joinMeetingWithNoPreviewParams(_ params: NoPreviewParams) {
        let lastSetting = setting?.micCameraSetting ?? .default
        self.executeInQueue(source: "joinMeetingWithNoPreviewParams") {
            if self.state == .preparing {
                self.log("joinMeetingWithNoPreviewParams success")
                let hud = self.service?.larkRouter.showLoading(with: I18n.View_VM_Loading, disableUserInteraction: false)
                self.joinMeeting(params.toJoinMeetingParams(lastSetting: lastSetting), leaveOnError: true) { _ in
                    hud?.remove()
                }
            } else {
                self.loge("joinMeetingWithNoPreviewParams failed, current state is \(self.state)")
            }
        }
    }
}

private extension NoPreviewParams {
    func toJoinMeetingParams(lastSetting: MicCameraSetting) -> JoinMeetingParams {
        let id = id
        var params: JoinMeetingParams
        var setting = lastSetting
        if let isOn = mic {
            setting.isMicrophoneEnabled = isOn
        }
        if let isOn = camera {
            setting.isCameraEnabled = isOn
        }
        switch idType {
        case .meetingId:
            params = JoinMeetingParams(joinType: .meetingId(id, nil), meetSetting: setting)
        case .uniqueId:
            params = JoinMeetingParams(joinType: .uniqueId(id), meetSetting: setting)
        case .groupId, .createMeeting:
            params = JoinMeetingParams(joinType: .groupId(id), meetSetting: setting)
        case .meetingNumber:
            params = JoinMeetingParams(joinType: .meetingNumber(id), meetSetting: setting)
        case .interviewUid:
            params = JoinMeetingParams(joinType: .interviewId(id), meetSetting: setting)
        case .reservationId:
            params = JoinMeetingParams(joinType: .reserveId(id), meetSetting: setting)
        }
        params.audioMode = .internet
        return params
    }
}
