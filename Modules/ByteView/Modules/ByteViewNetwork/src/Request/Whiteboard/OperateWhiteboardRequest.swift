//
//  OperateWhiteboardRequest.swift
//  ByteViewNetwork
//
//  Created by helijian on 2023/1/1.
//

import Foundation
import RustPB

/// Videoconference_V1_OperateWhiteboardRequest
public struct OperateWhiteboardRequest {
    public static let command: NetworkCommand = .rust(.operateWhiteboard)
    public typealias Response = OperateWhiteboardResponse
    public enum Action: Int, Hashable {
        case startWhiteboard
        case stopWhiteboard
    }

    public var action: Action
    public var meetingMeta: MeetingMeta
    public var whiteboardSetting: WhiteboardSettings?
    public var whiteboardId: Int64?

    public init(action: Action, meetingMeta: MeetingMeta,
                whiteboardSetting: WhiteboardSettings? = nil, whiteboardId: Int64? = nil) {
        self.action = action
        self.meetingMeta = meetingMeta
        self.whiteboardSetting = whiteboardSetting
        self.whiteboardId = whiteboardId
    }
}

public struct OperateWhiteboardResponse {
    public var whiteboardInfo: WhiteboardInfo
}

extension OperateWhiteboardRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_OperateWhiteboardRequest
    func toProtobuf() throws -> Videoconference_V1_OperateWhiteboardRequest {
        var request = ProtobufType()
        switch action {
        case .startWhiteboard:
            request.action = .startWhiteboard
        case .stopWhiteboard:
            request.action = .stopWhiteboard
        }
        request.meetingMeta = meetingMeta.pbType
        if let whiteboardSetting = whiteboardSetting {
            request.whiteboardSettings = whiteboardSetting.pbType
        }
        if let whiteboardId = whiteboardId {
            request.whiteboardID = whiteboardId
        }
        return request
    }
}

extension OperateWhiteboardResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_OperateWhiteboardResponse
    init(pb: Videoconference_V1_OperateWhiteboardResponse) throws {
        self.whiteboardInfo = pb.whiteboardInfo.vcType
    }
}
