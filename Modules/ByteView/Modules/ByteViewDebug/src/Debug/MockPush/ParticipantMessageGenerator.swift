//
//  ParticipantMessageGenerator.swift
//  ByteViewDebug
//
//  Created by liujianlong on 2023/9/23.
//

import Foundation
import RustPB

class ParticipantMessageGenerator {
    enum PushType {
        case participant
        case webinarAttendee
        case webinarPanelList
    }

    let userID: String
    let meetingID: String
    let pushType: PushType
    var participants: [Videoconference_V1_Participant]

    private var rng: RandomNumberGenerator?

    init(userID: String,
         meetingID: String,
         pushType: PushType = .participant,
         count: Int,
         rng: RandomNumberGenerator? = nil) {
        self.userID = userID
        self.meetingID = meetingID
        self.pushType = pushType
        self.participants = makeParticipants(count: count,
                                             userID: userID,
                                             isAttendee: pushType == .webinarAttendee)
    }


    func generateInitialMessage() -> Videoconference_V1_MeetingParticipantChange {
        var msg = Videoconference_V1_MeetingParticipantChange()
        msg.meetingID = self.meetingID
        msg.upsertParticipants = self.participants
        return msg
    }

    func generateChangeMsg(changeCount: Int, removeCount: Int) -> Videoconference_V1_MeetingParticipantChange {
        var msg = Videoconference_V1_MeetingParticipantChange()
        msg.meetingID = self.meetingID
        if changeCount == 0 && removeCount == 0
            || changeCount + removeCount > self.participants.count {
            return msg
        }
        let indices: [Int]
        if var rng = self.rng {
            indices = (0..<self.participants.count).shuffled(using: &rng)
            self.rng = rng
        } else {
            indices = (0..<self.participants.count).shuffled()
        }
        var changed = [Videoconference_V1_Participant]()
        var removed = [Videoconference_V1_Participant]()
        for idx in indices[0..<changeCount] {
            self.participants[idx].settings.isMicrophoneMuted = !self.participants[idx].settings.isMicrophoneMuted
            changed.append(self.participants[idx])
        }

        for idx in indices[changeCount..<changeCount+removeCount] {
            removed.append(self.participants[idx])
        }
        msg.upsertParticipants = changed
        msg.removeParticipants = removed
        if pushType == .webinarAttendee {
            msg.attendeeNum = Int64(self.participants.count)
        }
        return msg
    }

    func generateEndMsg() -> Videoconference_V1_MeetingParticipantChange {
        var msg = Videoconference_V1_MeetingParticipantChange()
        msg.meetingID = self.meetingID
        msg.removeParticipants = self.participants
        return msg
    }

}

private var deviceID: Int = 1
private func makeParticipants(count: Int,
                              userID: String,
                              isAttendee: Bool = false) -> [Videoconference_V1_Participant] {
    var participant = Videoconference_V1_Participant()
    participant.id = userID
    participant.deviceType = .mobile
    participant.status = .onTheCall
    var settings = Videoconference_V1_ParticipantSettings()
    settings.isMicrophoneMuted = true
    settings.isCameraMuted = true
    if isAttendee {
        participant.participantRoleSettings.meetingRole = .webinarAttendee
    } else {
        participant.participantRoleSettings.meetingRole = .participant
    }
    participant.settings = settings
    let participants = (deviceID..<deviceID + count).map { idx in
        var p = participant
        if isAttendee {
            p.settings.nickname = "MockAttendee-\(idx + 1)"
            p.settings.inMeetingName = "MockAttendee-\(idx + 1)"
        } else {
            p.settings.nickname = "MockParticipant-\(idx + 1)"
            p.settings.inMeetingName = "MockParticipant-\(idx + 1)"
        }
        p.deviceID = "\(idx + 1)"
        return p
    }
    deviceID += count
    return participants
}
