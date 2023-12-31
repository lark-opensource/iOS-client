//
//  CreateVCTabMeetingImRecordDocRequest.swift
//  ByteViewNetwork
//
//  Created by bytedance on 2022/10/16.
//

import Foundation
import ServerPB

/// CREATE_VC_TAB_IM_RECORD_DOC ByteviewCommand = 89219
/// 独立tab生成会中聊天文档
/// ServerPB_Videochat_tab_v2_CreateVCTabMeetingImRecordDocRequest
public struct CreateVCTabMeetingImRecordDocRequest {
    public static let command: NetworkCommand = .server(.createVcTabImRecordDoc)

    public init(meetingId: String) {
        self.meetingId = meetingId
    }

    public var meetingId: String
}

extension CreateVCTabMeetingImRecordDocRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_tab_v2_CreateVCTabMeetingImRecordDocRequest
    func toProtobuf() throws -> ServerPB_Videochat_tab_v2_CreateVCTabMeetingImRecordDocRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        return request
    }
}
