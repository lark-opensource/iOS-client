//
//  QueryMeetingRelatedDocsRequest.swift
//  ByteViewNetwork
//
//  Created by ByteDance on 2023/9/25.
//

import Foundation
import RustPB

/// Videoconference_V1_VcQueryMeetingRelatedDocsRequest
/// VC_QUERY_MEETING_RELATED_DOCS = 89502
/// // 获取共享面板中会议相关文档
public struct QueryMeetingRelatedDocsRequest {
    public static let command: NetworkCommand = .rust(.vcQueryMeetingRelatedDocs)
    public typealias Response = QueryMeetingRelatedDocsResponse
    /// 会议ID
    public var meetingID: String

    public init(meetingId: String) {
        self.meetingID = meetingId
    }
}

public struct QueryMeetingRelatedDocsResponse {
    /// 会议相关文档，包括纪要文档和日程相关文档
    public var meetingRelatedDocs: [VcDocs] = []

    public init(docs: [VcDocs]) {
        self.meetingRelatedDocs = docs
    }
}

extension QueryMeetingRelatedDocsRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_VcQueryMeetingRelatedDocsRequest
    func toProtobuf() throws -> Videoconference_V1_VcQueryMeetingRelatedDocsRequest {
        var request = ProtobufType()
        request.meetingID = meetingID
        return request
    }
}

extension QueryMeetingRelatedDocsResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_VcQueryMeetingRelatedDocsResponse
    init(pb: Videoconference_V1_VcQueryMeetingRelatedDocsResponse) throws {
        self.meetingRelatedDocs = pb.meetingRelatedDocs.map({ $0.vcType })
    }
}
