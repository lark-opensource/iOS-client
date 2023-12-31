//
// Created by liujianlong on 2022/11/10.
//

import Foundation
import ServerPB

/// command: GET_WEBINAR_ROLE = 89101
public struct GetWebinarRoleRequest {
    public static let command: NetworkCommand = .server(.getWebinarRole)
    public typealias Response = GetWebinarRoleResponse

    public var meetingID: Int64?
    public var meetingNo: String?
    public var uniqueID: Int64?

    public init(meetingID: Int64? = nil, meetingNo: String? = nil, uniqueID: Int64? = nil) {
        self.meetingID = meetingID
        self.meetingNo = meetingNo
        self.uniqueID = uniqueID
    }
}

public struct GetWebinarRoleResponse {
    public var role: Participant.MeetingRole?
}

extension GetWebinarRoleResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_calendar_GetWebinarRoleResponse
    init(pb: ServerPB_Videochat_calendar_GetWebinarRoleResponse) throws {
        self.role = .init(rawValue: pb.role.rawValue)
    }
}

extension GetWebinarRoleRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_calendar_GetWebinarRoleRequest
    func toProtobuf() throws -> ServerPB_Videochat_calendar_GetWebinarRoleRequest {
        var request = ProtobufType()
        if let val = meetingID {
            request.meetingID = val
        }
        if let val = meetingNo {
            request.meetingNo = val
        }
        if let val = uniqueID {
            request.uniqueID = val
        }
        return request
    }
}
