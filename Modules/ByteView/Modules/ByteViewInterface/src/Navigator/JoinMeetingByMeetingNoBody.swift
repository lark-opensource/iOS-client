//
//  JoinMeetingByMeetingNoBody.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/6/30.
//

import Foundation

/// /client/videochat/meetingno/join
public struct JoinMeetingByMeetingNoBody: CodablePathBody {
    public static let path = "/client/videochat/meetingno/join"
    public let no: String

    public init(no: String) {
        self.no = no
    }
}
