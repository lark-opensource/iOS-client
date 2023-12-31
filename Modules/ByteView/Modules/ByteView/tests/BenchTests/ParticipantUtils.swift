//
//  ParticipantUtils.swift
//  ByteView-Unit-Tests
//
//  Created by liujianlong on 2023/9/13.
//

import RustPB
import ByteViewNetwork
import SwiftProtobuf

extension BinaryDecodingOptions {
    static let discardUnknownFieldsOption: BinaryDecodingOptions = {
        var options = BinaryDecodingOptions()
        options.discardUnknownFields = true
        return options
    }()
}

private var deviceID: Int = 1

func loadParticipantChangPush(url: URL, meetingID: String) throws {
    let file = try FileHandle(forReadingFrom: url)
    var msgs: [FramedMessage] = []
    while let msg = try FramedMessage.from(file) {
        if let command = Basic_V1_Command(rawValue: msg.header.cmd) {
            if command == .pushMeetingParticipantChange {
                var pb = try Videoconference_V1_MeetingParticipantChange(serializedData: msg.payload, options: .discardUnknownFieldsOption)
                pb.meetingID = meetingID
            }
        }
        msgs.append(msg)
    }
}
