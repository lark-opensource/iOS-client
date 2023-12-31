//
//  InMeetUserProfileAction.swift
//  ByteView
//
//  Created by kiri on 2021/4/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

final class InMeetUserProfileAction: InMeetDataListener {
    private let meeting: InMeetMeeting
    private var callTopic: String?
    private var meetTopic: String?
    private var lastPendingAction: UserAction?
    init(meeting: InMeetMeeting) {
        self.meeting = meeting
    }

    func gotoUserProfile(userId: String, completion: (() -> Void)? = nil) {
        let sponsor = meeting.info.sponsor
        let meetingId = meeting.meetingId
        let action = UserAction(userId: userId, sponsor: sponsor, completion: completion)
        self.lastPendingAction = action
        let participantService = meeting.httpClient.participantService
        participantService.participantInfo(pid: action.participantId, meetingId: meetingId, completion: { [weak self] in
            if self?.lastPendingAction?.participantId == action.participantId {
                self?.lastPendingAction?.sponsorName = $0.name
                self?.updateRequestIfNeeded()
            }
        })
        if meeting.type == .call {
            let other = meeting.participant.otherParticipant
            if let other = other {
                participantService.participantInfo(pid: other, meetingId: meetingId) { [weak self] ap in
                    self?.callTopic = ap.name
                    self?.updateRequestIfNeeded()
                }
            } else {
                callTopic = ""
                updateRequestIfNeeded()
            }
        } else {
            if let info = meeting.data.inMeetingInfo {
                meetTopic = info.meetingSettings.topic
                updateRequestIfNeeded()
            } else {
                meeting.data.addListener(self, fireImmediately: false)
            }
        }
    }

    private func updateRequestIfNeeded() {
        if lastPendingAction == nil { return }
        let topic = meeting.type == .call ? callTopic : meetTopic
        if let topic = topic, let action = lastPendingAction, let sponsorName = action.sponsorName {
            let service = meeting.service
            Util.runInMainThread {
                service.router.setWindowFloating(true)
                service.larkRouter.gotoUserProfile(userId: action.userId, meetingTopic: topic, sponsorName: sponsorName,
                                                   sponsorId: action.sponsorId, meetingId: service.meetingId)
            }
            self.lastPendingAction = nil
            meeting.data.removeListener(self)
            action.completion?()
        }
    }

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        if lastPendingAction != nil, meeting.type == .meet {
            meetTopic = meeting.data.roleStrategy.displayTopic(topic: inMeetingInfo.meetingSettings.topic)
            updateRequestIfNeeded()
        }
    }

    private struct UserAction {
        let userId: String
        let sponsor: ByteviewUser
        let completion: (() -> Void)?
        var sponsorId: String { sponsor.id }
        var sponsorName: String?
        var participantId: ParticipantId {
            ParticipantId(id: sponsorId, type: sponsor.type)
        }
    }
}

extension InMeetUserProfileAction {
    static func show(userId: String, meeting: InMeetMeeting) {
        guard let holder = InMeetAsyncActionHolder.current else { return }
        let action = InMeetUserProfileAction(meeting: meeting)
        holder.hold(action)
        action.gotoUserProfile(userId: userId) { [weak action, weak holder] in
            if let obj = action {
                holder?.remove(obj)
            }
        }
    }
}
