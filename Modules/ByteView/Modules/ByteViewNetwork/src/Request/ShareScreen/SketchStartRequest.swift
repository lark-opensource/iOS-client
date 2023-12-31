//
//  SketchStartRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// CMD: SKETCH_START
/// - ServerPB_Videochat_sketch_SketchStartRequest
public struct SketchStartRequest {
    public static let command: NetworkCommand = .server(.sketchStart)
    public typealias Response = SketchStartResponse

    public init(meetingId: String,
                shareScreenId: String,
                breakoutRoomId: String?) {
        self.meetingId = meetingId
        self.shareScreenId = shareScreenId
        self.breakoutRoomId = breakoutRoomId
    }

    public var meetingId: String

    public var shareScreenId: String

    public var breakoutRoomId: String?
}


/// ServerPB_Videochat_SketchStartResponse
public struct SketchStartResponse {

    /// 用于表示，会议中其他人是否可以开启标注
    public var canOtherSketch: Bool
}

extension SketchStartRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_sketch_SketchStartRequest
    func toProtobuf() throws -> ServerPB_Videochat_sketch_SketchStartRequest {
        var req = ProtobufType()
        req.meetingID = meetingId
        req.shareScreenID = shareScreenId
        if let id = RequestUtil.normalizedBreakoutRoomId(breakoutRoomId) {
            req.breakoutMeetingID = id
            req.associateType = .breakoutMeeting
        } else {
            req.associateType = .meeting
        }
        return req
    }
}

extension SketchStartResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_sketch_SketchStartResponse
    init(pb: ServerPB_Videochat_sketch_SketchStartResponse) throws {
        self.canOtherSketch = pb.canOtherSketch
    }
}
