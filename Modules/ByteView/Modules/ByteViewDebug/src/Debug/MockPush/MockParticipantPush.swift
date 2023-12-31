//
//  MockParticipantPush.swift
//  ByteViewDebug
//
//  Created by liujianlong on 2023/7/19.
//

import Foundation
import ByteViewNetwork
import RustPB

final class MockParticipantPush {
    static let queue = DispatchQueue(label: "vc.mockparticipant")

    let msgGenerator: ParticipantMessageGenerator
    let userID: String
    var timer: DispatchSourceTimer?

    init(userID: String,
         meetingID: String,
         pushType: ParticipantMessageGenerator.PushType = .participant,
         count: Int) {
        self.userID = userID
        self.msgGenerator = ParticipantMessageGenerator(userID: userID, meetingID: meetingID, pushType: pushType, count: count)
    }

    func start(intervalMS: Int, changeCount: Int, removeCount: Int) {
        let timer = DispatchSource.makeTimerSource(queue: Self.queue)
        self.timer = timer
        timer.schedule(deadline: .now(), repeating: .milliseconds(intervalMS))
        self.pushMessage(self.msgGenerator.generateInitialMessage())
        timer.setEventHandler { [weak self] in
            guard let self = self else {
                return
            }
            self.pushMessage(self.msgGenerator.generateChangeMsg(changeCount: changeCount, removeCount: removeCount))
        }

        timer.setCancelHandler {
            self.pushMessage(self.msgGenerator.generateEndMsg())
        }
        timer.activate()
    }

    func stop() {
        self.timer?.cancel()
        self.timer = nil
    }

    private func pushMessage(_ msg: Videoconference_V1_MeetingParticipantChange) {
        let msg = MeetingParticipantChange(pb: msg)
        switch msgGenerator.pushType {
        case .participant:
            Push.participantChange.consumePacket(PushPacket(userId: self.userID, contextId: "", command: .rust(.pushMeetingParticipantChange), message: msg))
        case .webinarAttendee:
            Push.webinarAttendeeChange.consumePacket(PushPacket(userId: self.userID, contextId: "", command: .rust(.pushMeetingWebinarAttendeeChange), message: msg))
        case .webinarPanelList:
            Push.webinarAttendeeViewChange.consumePacket(PushPacket(userId: self.userID, contextId: "", command: .rust(.pushMeetingWebinarAttendeeViewChange), message: msg))
        }
    }
}
