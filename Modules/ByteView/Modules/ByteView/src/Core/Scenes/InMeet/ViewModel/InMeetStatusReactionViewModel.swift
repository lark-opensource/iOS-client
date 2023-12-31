//
//  InMeetStatusReactionViewModel.swift
//  ByteView
//
//  Created by lutingting on 2022/8/29.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker
import ByteViewSetting

protocol InMeetStatusReactionViewModelObserver: AnyObject {
    func shouldShowStatusReactionRedTip(_ count: Int)
    func handsUpReactionCountChanged(_ count: Int, attendeeCount: Int)
}

extension InMeetStatusReactionViewModelObserver {
    func shouldShowStatusReactionRedTip(_ count: Int) {}
    func handsUpReactionCountChanged(_ count: Int, attendeeCount: Int) {}
}

final class InMeetStatusReactionViewModel: InMeetDataListener {
    let meeting: InMeetMeeting
    let context: InMeetViewContext
    private(set) var handsUpParticipants: [Participant] = []
    private(set) var redTipCount = 0
    private var shouldShowRedTip = false
    private var currentToastDescriptor: AnchorToastDescriptor?
    var count: Int = 0
    var attendeeCount: Int = 0

    var showHandsUpStatus: Bool {
        let isHostOrCohost = meeting.setting.hasCohostAuthority
        let isSharer = meeting.shareData.isSelfSharingContent
        return isHostOrCohost || isSharer
    }

    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.context = resolver.viewContext
        meeting.data.addListener(self)
        meeting.push.notice.addObserver(self)
        meeting.push.inMeetingChange.addObserver(self)
        meeting.setting.addListener(self, for: .hasCohostAuthority)
        context.addListener(self, for: [.participantsDidAppear, .participantsDidDisappear])
    }

    private let observers = Listeners<InMeetStatusReactionViewModelObserver>()
    func addObserver(_ observer: InMeetStatusReactionViewModelObserver, fireImmediately: Bool = true) {
        observers.addListener(observer)
        if fireImmediately {
            if redTipCount > 0 {
                observer.shouldShowStatusReactionRedTip(redTipCount)
            }
            // swiftlint:disable empty_count
            if count > 0 || attendeeCount > 0 {
                observer.handsUpReactionCountChanged(count, attendeeCount: attendeeCount)
            }
            // swiftlint:enable empty_count
        }
    }

    func removeObserver(_ observer: InMeetStatusReactionViewModelObserver) {
        observers.removeListener(observer)
    }

    private var isParticipantsViewAppeared = false {
        didSet {
            if oldValue != isParticipantsViewAppeared {
                didChangeParticipantsAppear()
            }
        }
    }

    func didChangeHandsUpParticipants() {
        if !isParticipantsViewAppeared {
            shouldShowRedTip = true
        }

        let handsup = meeting.participant.currentRoom.nonRingingDict.map(\.value).statusHandsUp + meeting.participant.attendee.nonRingingDict.map(\.value).statusHandsUp
        updateStatusHandsUpParticipants(handsup, forceUpdateTips: true)
    }

    private func updateStatusHandsUpParticipants(_ participants: [Participant], forceUpdateTips: Bool = false) {
        let handsUp = participants
        let isChanged = handsUp.map { $0.user } != self.handsUpParticipants.map { $0.user }
        if isChanged {
            self.handsUpParticipants = handsUp
        }
        if !isParticipantsViewAppeared, forceUpdateTips || isChanged {
            updateTips()
        }
    }

    private func updateTips() {
        if shouldShowRedTip {
            updateRedTip(showHandsUpStatus ? handsUpParticipants.count : 0)
        }
    }

    private func didChangeParticipantsAppear() {
        if isParticipantsViewAppeared {
            updateRedTip(0)
        }
    }

    private func updateRedTip(_ count: Int) {
        redTipCount = count
        observers.forEach { $0.shouldShowStatusReactionRedTip(count) }
    }
}

extension InMeetStatusReactionViewModel: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        switch change {
        case .participantsDidAppear:
            isParticipantsViewAppeared = true
        case .participantsDidDisappear:
            isParticipantsViewAppeared = false
        default:
            break
        }
    }
}

extension InMeetStatusReactionViewModel: InMeetingChangedInfoPushObserver {
    func didReceiveInMeetingChangedInfo(_ data: InMeetingData) {
        if data.type == .hostConditionEmojiHandsDown {
            Toast.show(I18n.View_G_YourHandPutDown)
        }
    }
}

extension InMeetStatusReactionViewModel: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .hasCohostAuthority, !showHandsUpStatus {
            updateRedTip(0)
            if let toast = self.currentToastDescriptor, toast.type == .participants {
                AnchorToast.dismiss(toast)
            }
        }
    }
}

extension InMeetStatusReactionViewModel: VideoChatNoticePushObserver {
    func didReceiveNotice(_ notice: VideoChatNotice) {
        guard meeting.meetingId == notice.meetingID, notice.type == .handsUpToast else { return }

        let uid = notice.extra["uid"] ?? ""
        let count = Int(notice.extra["count"] ?? "0") ?? 0
        let deviceId = notice.extra["device_id"] ?? ""
        let userType = Int(notice.extra["user_type"] ?? "0") ?? 0
        let role = notice.extra["role"] ?? ""
        let toastType: AnchorToastType = role == "attendee" ? .attendees : .participants
        if toastType == .attendees {
            attendeeCount = count
        } else {
            self.count = count
        }
        let pid = ParticipantId(id: uid, type: .init(rawValue: userType), deviceId: deviceId)
        // swiftlint:disable empty_count
        if self.showHandsUpStatus && count > 0 && !(count == 1 && uid == meeting.userId) {
            let participantService = meeting.httpClient.participantService
            participantService.participantInfo(pid: pid, meetingId: meeting.meetingId) { ap in
                let title = count > 1 ? I18n.View_G_NumberRaisedHand(count) : I18n.View_G_NameRaisedHand(ap.name)
                if self.context.isSketchMenuEnabled || self.context.isWhiteboardMenuEnabled {
                    Toast.show(title, duration: 5.0) { [weak self] in
                        self?.didChangeHandsUpParticipants()
                    }
                } else {
                    let toast = AnchorToastDescriptor(type: toastType, title: title)
                    toast.identifier = .handsUp
                    toast.sureAction = { [weak self] in
                        toast.hasClosed = true
                        self?.didChangeHandsUpParticipants()
                    }
                    self.currentToastDescriptor = toast
                    AnchorToast.show(toast)
                }
                VCTracker.post(name: .vc_meeting_onthecall_popup_view, params: [.content: "hands_up_num"])
            }
        } else {
            if self.showHandsUpStatus && count == 0 {
                if let toast = self.currentToastDescriptor, toast.type == toastType {
                    AnchorToast.dismiss(toast)
                }
                updateRedTip(0)
            }
        }
        // swiftlint:enable empty_count

        observers.forEach { $0.handsUpReactionCountChanged(self.count, attendeeCount: attendeeCount) }
    }
}
