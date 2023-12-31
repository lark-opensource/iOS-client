//
//  BusyRingingManager.swift
//  ByteView
//
//  Created by 李凌峰 on 2020/3/2.
//

import Foundation
import ByteViewTracker
import ByteViewMeeting
import ByteViewCommon

class BusyRingingManager {
    static let shared = BusyRingingManager()
    var meeting: MeetingSession? { pendingRingingMeeting }
    private var lastPromptKey: String?
    private weak var pendingRingingMeeting: MeetingSession?
    private var isAllowed = false {
        didSet {
            if isAllowed != oldValue {
                updatePrompt()
            }
        }
    }

    private init() {
        MeetingManager.shared.addListener(self)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeAccount),
                                               name: VCNotification.didChangeAccountNotification, object: nil)
    }

    @objc private func didChangeAccount() {
        lastPromptKey = nil
        if let meeting = pendingRingingMeeting {
            handleLastMeeting(meeting)
            pendingRingingMeeting = nil
        }
        isAllowed = false
    }
}

extension BusyRingingManager {
    private func updateRingingPendingMeeting() {
        let pendingMeetings = MeetingManager.shared.sessions.filter {
            $0.sessionType == .vc && $0.isPending && $0.state == .ringing
        }.filter {
            !$0.isCallKit
        }
        let pending = pendingMeetings.max(by: { (m1, m2) in  //取更早进入ringing的会议
            let t1 = m1.meetingRingingTime ?? 0.0
            let t2 = m2.meetingRingingTime ?? 0.0
            return t1 < t2
        })
        if pendingRingingMeeting?.meetingId != pending?.meetingId {
            Logger.ring.info("updateRingingPendingMeeting, pending = \(pending), isAllowed = \(isAllowed)")
            if let meeting = pendingRingingMeeting {
                handleLastMeeting(meeting)
            }
            self.pendingRingingMeeting = pending
            self.updatePrompt()
        }
    }

    private func updatePrompt() {
        Util.runInMainThread {
            if self.isAllowed, let pending = self.pendingRingingMeeting {
                self.showV2(pending)
            } else {
                self.hide()
            }
        }
    }

    private func hide() {
        if let key = self.lastPromptKey {
            Logger.ui.info("hide BusyRinging prompt: key = \(key)")
            self.lastPromptKey = nil
            //（忙线转非忙线，可能存在先出现非忙线，然后再忙线消失，这时候会把响铃的卡片dismiss）
            if let meetingId = RingingCardManager.shared.findSession(meetingId: key.replacingOccurrences(of: Self.BusyRingingKeyStr, with: ""), isBusy: true) {
                Logger.ring.info("busy hide card \(meetingId)")
                RingingCardManager.shared.remove(meetingId: meetingId)
            } else if PromptWindowControllerV2.shared.currentVC != nil {
                Logger.ring.info("busy hide vc \(key)")
                PromptWindowControllerV2.shared.dismissVC()
            }
        }
    }

    private func handleLastMeeting(_ meeting: MeetingSession) {
        MeetingLocalNotificationCenter.shared.removeLocalNotification(meeting.meetingId)
    }

    private func handleCurrentMeeting(_ meeting: MeetingSession) {
        guard let info = meeting.videoChatInfo, let service = meeting.service else { return }
        MeetingLocalNotificationCenter.shared.showLocalNotification(info, service: service)
    }

    static let BusyRingingKeyStr = "BusyRinging|"
    private func showV2(_ meeting: MeetingSession) {
        let key = Self.BusyRingingKeyStr + meeting.meetingId
        if lastPromptKey == key {
            Logger.ring.info("show BusyRinging prompt: ignored, key = \(key)")
        } else {
            Logger.ring.info("show BusyRinging prompt: show, key = \(key), lastKey = \(lastPromptKey)")
            self.hide()
            // 隐藏上一次的，因为存在后来一个响铃先进来，导致前面一个hide不掉，如果放到didLeaveMeetingSession则会短暂的出现2个响铃
            guard let info = meeting.videoChatInfo else { return }
            self.handleCurrentMeeting(meeting)
            switch info.type {
            case .meet:
                RingingCardManager.shared.post(meetingId: meeting.meetingId, type: .inviteBusyRing)
            default:
                RingingCardManager.shared.post(meetingId: meeting.meetingId, type: .callInBusyRing)
            }
            self.lastPromptKey = key
        }
    }
}

extension BusyRingingManager: MeetingManagerListener, MeetingSessionListener {
    func didCreateMeetingSession(_ session: MeetingSession) {
        session.addListener(self)
    }

    func didLeaveMeetingSession(_ session: MeetingSession, event: MeetingEvent) {
        updateRingingPendingMeeting()
    }

    func didEnterState(_ state: MeetingState, from: MeetingState, event: MeetingEvent, session: MeetingSession) {
        if session.isPending {
            if state == .ringing || state == .onTheCall, let current = MeetingManager.shared.currentSession,
               current.state == .start || current.state == .preparing {
                current.leave(.receiveOther)
            } else if state == .ringing {
                updateRingingPendingMeeting()
            }
        } else {
            switch state {
            case .lobby, .prelobby, .onTheCall:
                isAllowed = true
            default:
                isAllowed = false
            }
        }
    }

    func didLeavePending(session: MeetingSession) {
        updateRingingPendingMeeting()
    }
}

extension BusyRingingManager {
    private func doPageTrack() {
        var params: TrackParams = [
            "is_mic_open": false,
            "is_in_duration": true,
            "is_cam_open": false,
            "is_voip": (meeting?.isCallKitFromVoIP ?? false) ? 1 : 0,
            "is_ios_new_feat": 0 // 新特性上线后有效
        ]

        if let meetType = self.pendingRingingMeeting?.meetType, meetType == .call, let callInType = self.pendingRingingMeeting?.callInType {
            switch callInType {
            case .ipPhone, .ipPhoneBindLark:
                params["call_source"] = "ip_phone"
            case .enterprisePhone:
                params["call_source"] = "office_call"
            case .recruitmentPhone:
                params["call_source"] = "recruit_phone"
            default:
                params["call_source"] = "call"
            }
        }

        VCTracker.post(name: .vc_meeting_callee_view, params: params)
    }
}
