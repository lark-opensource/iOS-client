//
//  JoinInterviewBody.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/6/30.
//

import Foundation

/// People Interview, /client/videochat/interview/join
public struct JoinInterviewBody: CodablePathBody {
    /// /client/videochat/interview/join
    public static let path = "/client/videochat/interview/join"

    public let id: String
    public let role: JoinMeetingRole
    public let no: String?

    public init(id: String, role: JoinMeetingRole, no: String?) {
        self.id = id
        self.role = role
        self.no = no
    }
}
