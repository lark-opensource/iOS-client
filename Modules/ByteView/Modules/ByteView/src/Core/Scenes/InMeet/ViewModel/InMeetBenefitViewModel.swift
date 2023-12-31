//
//  InMeetBenefitViewModel.swift
//  ByteView
//
//  Created by helijian.666 on 2023/10/5.
//

import Foundation
import ByteViewNetwork

protocol InMeetBenefitInfoListener: AnyObject {
    func didChangeBenefitInfo(_ benefit: BenefitInfo?, oldValue: BenefitInfo?)
}

// 权益信息
struct BenefitInfo: Equatable {
    enum BenefitType: Equatable {
        case maxParticipant(Bool)
        case maxTime(Bool)
    }
    /* 具体权益 */
    var benefits: [BenefitType]

    static func == (lhs: BenefitInfo, rhs: BenefitInfo) -> Bool {
        return lhs.benefits == rhs.benefits
    }
}

final class InMeetBenefitViewModel: InMeetingChangedInfoPushObserver, MyselfListener {
    private let meeting: InMeetMeeting
    private let logger = Logger.meeting
    private let listeners = Listeners<InMeetBenefitInfoListener>()
    var meetingOwner: ByteviewUser? {
        didSet {
            guard oldValue != meetingOwner else { return }
            isMeetingOwner = meetingOwner?.participantId.larkUserId == meeting.myself.user.participantId.larkUserId
        }
    }
    private var isMeetingOwner: Bool {
        didSet {
            guard oldValue != isMeetingOwner else { return }
            self.benefit = createBeneift()
        }
    }
    var shouldShowBenefitInfo: Bool
    var benefit: BenefitInfo? {
        didSet {
            guard oldValue != benefit else { return }
            listeners.forEach { $0.didChangeBenefitInfo(benefit, oldValue: oldValue)}
        }
    }

    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.meetingOwner = meeting.info.meetingOwner
        self.shouldShowBenefitInfo = !meeting.isWebinarAttendee
        isMeetingOwner = meetingOwner?.participantId.larkUserId == meeting.myself.user.participantId.larkUserId
        benefit = createBeneift()
        meeting.push.inMeetingChange.addObserver(self)
        meeting.addMyselfListener(self)
    }

    func addListener(_ listener: InMeetBenefitInfoListener, fireImmediately: Bool = true) {
        listeners.addListener(listener)
        if fireImmediately, shouldShowBenefitInfo {
            listener.didChangeBenefitInfo(benefit, oldValue: nil)
        }
    }

    // 1v1 升级时，暂存meetingOwner
    func didReceiveInMeetingChangedInfo(_ data: InMeetingData) {
        guard data.meetingID == meeting.meetingId, data.type == .upgradeMeeting else { return }
        meetingOwner = data.meetingOwner
    }

    private func createBeneift() -> BenefitInfo? {
        guard shouldShowBenefitInfo else { return nil }
        // 面试会议不显示扩容和升级按钮
        // 1v1不提供会议时间升级服务，会中仅meetingOwner需要展示扩容按钮，且需要为免费版本
        // 目前免费版本通过planTimeLimit来确定，具体正式方案后续等后端和boss侧确定后再更改
        let maxPlanTime: Int32 = 1440
        let canUpgrade: Bool = meeting.type != .call && !meeting.isInterviewMeeting && isMeetingOwner && meeting.setting.billingSetting.planTimeLimit < maxPlanTime && meeting.setting.billingSetting.planTimeLimit > 0
        // 1v1不提供扩容服务，会中仅meetingOwner需要展示扩容按钮
        let canExpand: Bool = meeting.type != .call && !meeting.isInterviewMeeting && isMeetingOwner
        return BenefitInfo(benefits: [.maxParticipant(canExpand), .maxTime(canUpgrade)])
    }

    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        shouldShowBenefitInfo = myself.meetingRole != .webinarAttendee
        benefit = createBeneift()
    }
}
