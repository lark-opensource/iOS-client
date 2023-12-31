//
//  SetVcImNoticeInfoCloseRequest.swift
//  ByteViewNetwork
//
//  Created by lutingting on 2022/11/11.
//

import Foundation
import RustPB

/// SET_VC_IM_NOTICE_INFO_CLOSE = 89220; // 关闭会议事件卡片
/// Videoconference_V1_SetVcImNoticeInfoCloseRequest
public struct SetVcImNoticeInfoCloseRequest {
    public static let command: NetworkCommand = .rust(.setVcImNoticeInfoClose)

    public let meetingIds: [String]

    public init(meetingIds: [String]) {
        self.meetingIds = meetingIds
    }
}

extension SetVcImNoticeInfoCloseRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_SetVcImNoticeInfoCloseRequest
    func toProtobuf() throws -> Videoconference_V1_SetVcImNoticeInfoCloseRequest {
        var request = ProtobufType()
        request.meetingIds = meetingIds
        return request
    }
}
