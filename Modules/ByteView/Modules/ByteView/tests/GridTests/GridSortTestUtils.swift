//
//  GridSortTestUtils.swift
//  ByteView-Unit-Tests
//
//  Created by YizhuoChen on 2023/5/5.
//

import Foundation
@testable import ByteView
@testable import ByteViewNetwork
@testable import ByteViewSetting

struct MeetingMockData {
    static let meetingId = "test_meeting_id"
}

struct ParticipantMockData {

    static func new(id: String, type: ParticipantType = .larkUser, isCalling: Bool = false) -> Participant {
        Participant(meetingId: MeetingMockData.meetingId, id: "\(id)", type: type, deviceId: isCalling ? "" : "\(id)_did", interactiveId: "\(id)_iid")
    }

    static let myself = new(id: "myself")
}

func room(_ id: String) -> Participant { ParticipantMockData.new(id: id, type: .room) }
func person(_ id: String) -> Participant { ParticipantMockData.new(id: id) }
func callingRoom(_ id: String) -> Participant { ParticipantMockData.new(id: id, type: .room, isCalling: true) }
func callingPerson(_ id: String) -> Participant { ParticipantMockData.new(id: id, isCalling: true) }
