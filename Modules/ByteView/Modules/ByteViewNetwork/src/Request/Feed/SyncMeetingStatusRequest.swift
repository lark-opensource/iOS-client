//
//  SyncMeetingStatusRequest.swift
//  ByteViewNetwork
//
//  Created by lutingting on 2023/10/26.
//

import Foundation
import RustPB

/// Videoconference_V1_SyncMeetingStatusRequest
public struct SyncMeetingStatusRequest {
    public static let command: NetworkCommand = .rust(.syncMeetingStatus)
    public typealias Response = SyncMeetingStatusResponse
    ///当前报错的meeting_id
    public var meetingID: String?

    public init(meetingID: String?) {
        self.meetingID = meetingID
    }
}

/// Videoconference_V1_SyncMeetingStatusResponse
public struct SyncMeetingStatusResponse {

    /// 会议是否正在进行中
    public var isActive: Bool
}

extension SyncMeetingStatusRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_SyncMeetingStatusRequest
    func toProtobuf() throws -> Videoconference_V1_SyncMeetingStatusRequest {
        var request = ProtobufType()
        if let meetingID = meetingID {
            request.meetingID = meetingID
        }
        return request
    }
}

extension SyncMeetingStatusResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_SyncMeetingStatusResponse

    init(pb: Videoconference_V1_SyncMeetingStatusResponse) {
        self.isActive = pb.isActive
    }
}
