//
// Created by maozhixiang.lip on 2022/11/5.
//

import Foundation
import ByteViewNetwork
import ByteViewUI

public protocol LynxVoteViewModelListener {
    func meetingDidChange(_ meeting: LynxMeetingInfo)
    func votesDidChange(_ votes: [VoteStatisticInfo])
}

public protocol LynxVoteViewModel {
    var httpClient: HttpClient { get }
    var lynxMeeting: LynxMeetingInfo { get }
    var scene: LynxSceneInfo { get }
    var votes: [VoteStatisticInfo] { get }
    func showToast(_ content: String, icon: LynxToastIconType?, duration: TimeInterval?)
    func showToolbarGuide(type: String, content: String)
    func showUserProfile(uid: String)
    func present(_ vc: UIViewController, regularConfig: DynamicModalConfig, compactConfig: DynamicModalConfig)
    func addListener(_ listener: LynxVoteViewModelListener)
}

extension LynxVoteViewModel {
    var userId: String { lynxMeeting.myself.user.id }

    func showToast(_ content: String, icon: LynxToastIconType? = nil, duration: TimeInterval? = nil) {
        self.showToast(content, icon: icon, duration: duration)
    }
}

public enum LynxToastIconType: Int {
    case success
    case warning
    case error
}

public struct LynxSceneInfo {
    public static let unknown = Self.init(isRegular: false, size: .zero)
    public var isRegular: Bool
    public var size: CGSize
    public init(isRegular: Bool, size: CGSize) {
        self.isRegular = isRegular
        self.size = size
    }
    var dict: [String: Any] {
        [
            "isRegular": self.isRegular,
            "size": self.size.dict
        ]
    }
}

public struct LynxMeetingInfo: Equatable {
    public var meetingID: String
    public var meetingSubType: MeetingSubType
    public var myself: ParticipantInfo
    public init(meetingID: String, meetingSubType: MeetingSubType, myself: ParticipantInfo) {
        self.meetingID = meetingID
        self.meetingSubType = meetingSubType
        self.myself = myself
    }

    public struct ParticipantInfo: Equatable {
        public var user: ByteviewUser
        public var role: Participant.MeetingRole
        public init(user: ByteviewUser, role: Participant.MeetingRole) {
            self.user = user
            self.role = role
        }
    }

    var dict: [String: Any] {
        [
            "meetingID": self.meetingID,
            "meetingSubType": self.meetingSubType.rawValue,
            "myself": [
                "user": self.myself.user.dict,
                "role": self.myself.role.rawValue
            ]
        ]
    }
}
