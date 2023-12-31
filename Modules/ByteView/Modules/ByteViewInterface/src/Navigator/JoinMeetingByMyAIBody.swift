//
//  JoinMeetingByMyAIBody.swift
//  ByteViewInterface
//
//  Created by 陈乐辉 on 2023/8/18.
//

import Foundation

public struct JoinMeetingByMyAIBody: CodablePathBody {
    public static let path = "/client/myai/meetingId/join"
    public let meetingNumber: String
    public let meetingId: String

    public init(meetingNumber: String, meetingId: String) {
        self.meetingNumber = meetingNumber
        self.meetingId = meetingId
    }
}

extension JoinMeetingByMyAIBody: CustomStringConvertible {
    public var description: String {
        "JoinMeetingBody(meetingNumber: \(meetingNumber), meetingId: \(meetingId))"
    }
}
