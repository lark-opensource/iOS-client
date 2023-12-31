//
//  CloseInterviewerNoticeRequest.swift
//  ByteViewNetwork
//
//  Created by lutingting on 2022/3/29.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 面试官侧tips 不再提示
/// command: CLOSE_INTERVIEWER_NOTICE = 89375
public struct CloseInterviewerNoticeRequest {
    public static let command: NetworkCommand = .server(.closeInterviewerNotice)

    public var meetingID: String

    public init(meetingID: String) {
        self.meetingID = meetingID
    }
}


extension CloseInterviewerNoticeRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_CloseInterviewerNoticeRequest
    func toProtobuf() throws -> ServerPB_Videochat_CloseInterviewerNoticeRequest {
        var request = ProtobufType()
        request.meetingID = meetingID
        return request
    }
}
