//
//  GetRecordInfoRequest.swift
//  ByteViewNetwork
//
//  Created by fakegourmet on 2022/6/20.
//

import Foundation
import ServerPB

/// 获取录制信息
/// - MGET_VC_TAB_RECORD_INFO = 89216
/// - ServerPB_Videochat_tab_v2_MGetRecordInfoRequest
public struct GetRecordInfoRequest {
    public static let command: NetworkCommand = .server(.mgetVcTabRecordInfo)
    public typealias Response = GetRecordInfoResponse

    public init(recordMeetingIDs: [String], minutesMeetingIDs: [String]) {
        self.recordMeetingIDs = recordMeetingIDs
        self.minutesMeetingIDs = minutesMeetingIDs
    }

    /// logoType 为 RECORD 的会议
    public var recordMeetingIDs: [String]

    /// logoType 为 LARK_MINUTES 的会议
    public var minutesMeetingIDs: [String]

}

/// - ServerPB_Videochat_tab_v2_MGetRecordInfoResponse
public struct GetRecordInfoResponse {

    public var recordInfo: [String: TabDetailRecordInfo]
}

extension GetRecordInfoRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_tab_v2_MGetRecordInfoRequest
    func toProtobuf() throws -> ServerPB_Videochat_tab_v2_MGetRecordInfoRequest {
        var request = ProtobufType()
        request.recordMeetingIds = recordMeetingIDs
        request.minutesMeetingIds = minutesMeetingIDs
        return request
    }
}

extension GetRecordInfoResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_tab_v2_MGetRecordInfoResponse
    init(pb: ServerPB_Videochat_tab_v2_MGetRecordInfoResponse) throws {
        self.recordInfo = pb.recordInfo.mapValues { $0.vcType }
    }
}
