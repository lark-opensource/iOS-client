//
//  PushEntry.swift
//  ByteView
//
//  Created by kiri on 2023/6/18.
//

import Foundation
import ByteViewMeeting
import ByteViewTracker

extension MeetingPrechecker {
    func handlePushEntry(_ session: MeetingSession, params: JoinMeetingMessage, completion: @escaping PrecheckOutput) {
        guard let service = session.service else { return }
        log.info("handlePushEntry, message = \(params)")
        let context = MeetingPrecheckContext(service: service)
        let entrance = PushEntrance(params: params, context: context)
        session.precheckEntrance = entrance
        entrance.precheck(context: context) {
            switch $0 {
            case .success:
                completion(.success(.push))
            case .failure(let e):
                completion(.failure(e))
            }
        }
    }
}

extension MeetingSession {
    func joinMeetingWithPushMessage(_ message: JoinMeetingMessage) {
        let info = message.info
        self.isE2EeMeeting = info.settings.isE2EeMeeting
        if let another = MeetingManager.shared.findSession(meetingId: info.id, sessionType: .vc),
            another.sessionId != self.sessionId, another.state != .preparing {
            // 通过推送队列进入preparing的session，进入状态机再检查一次。another.state != .preparing是为了避免互相leave
            self.loge("startPreparing failed: found another session \(another)")
            // skip handleMeetingEnd
            self.leave(.receiveOther.handleMeetingEndManually())
            another.sendToMachine(info: info)
        } else {
            self.joinWithPushMessage(message)
        }
    }

    private func joinWithPushMessage(_ message: JoinMeetingMessage) {
        let type = message.type
        assert(type == .push || type == .registerClientInfo, "create session from abnormal push type: \(type)")
        let info = message.info
        self.isE2EeMeeting = info.settings.isE2EeMeeting
        DevTracker.post(.criticalPath(.meeting_entry).category(.meeting).params([.env_id: sessionId, .from_source: "push.\(message.source)"]))
        if let myself = info.participant(byUser: self.account), myself.status == .ringing {
            log("joinWithPush success: status is ringing")
            // 响铃 VideoChatInfo 由 CallKit 先处理，CallKit 无法处理的，回退到
            callCoordinator.reportNewIncomingCall(info: info, myself: myself) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(.downgradeToAppRinging):
                    self.log("reportNewIncomingCall success: result is downgradeToAppRinging")
                    self.sendEvent(.noticeRinging(info))
                case .success(.succeed):
                    self.log("reportNewIncomingCall success: result is succeed")
                    self.sendEvent(.noticeRinging(info))
                default:
                    self.log("reportNewIncomingCall failed: result is \(result)")
                    self.leave(.filteredByCallKit)
                }
            }
        } else {
            log("joinWithPush success")
            callCoordinator.requestStartCall(action: { $0(.success(Void())) }, completion: { [weak self] _ in
                self?.sendToMachine(info: info)
            })
        }
    }
}
