//
//  UploadShareStatusRequest.swift
//  ByteViewNetwork
//
//  Created by fakegouremt on 2023/3/14.
//

import Foundation
import ServerPB

/// UPLOAD_SHARE_STATUS = 88007
/// - ServerPB_Videochat_UploadShareStatusRequest
public struct UploadShareStatusRequest {
    public static let command: NetworkCommand = .server(.uploadShareStatus)
    public typealias Response = ShareVideoChatResponse

    public init(meetingMeta: MeetingMeta, shareID: String, shareType: ShareType, shareScreenStatus: ShareScreenStatus?) {
        self.meetingMeta = meetingMeta
        self.shareID = shareID
        self.shareType = shareType
        self.shareScreenStatus = shareScreenStatus
    }

    /// meetingID 路由
    public var meetingMeta: MeetingMeta

    /// 共享场景唯一ID
    public var shareID: String

    /// 根据 shareType 路由不同的 status 结构
    public var shareType: ShareType

    public var shareScreenStatus: ShareScreenStatus?

    public enum ShareType: Int, Hashable {
        case unknown // = 0
        case shareScreen // = 1
    }

    public struct ShareScreenStatus {

        public init(status: Status) {
            self.status = status
        }

        public var status: Status

        public enum Status: Int, Hashable {
            case unknown // = 0
            case firstFrameReceived // = 1
        }
    }

}

/// Videoconference_V1_UploadShareStatusResponse
public struct UploadShareStatusResponse {}

extension UploadShareStatusRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_UploadShareStatusRequest
    func toProtobuf() throws -> ServerPB_Videochat_UploadShareStatusRequest {
        var request = ProtobufType()
        request.meetingMeta = meetingMeta.spbType
        request.shareID = shareID
        request.shareType = shareType.pbType
        if let shareScreenStatus = shareScreenStatus?.pbType {
            request.shareScreenStatus = shareScreenStatus
        }
        return request
    }
}

extension UploadShareStatusResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_UploadShareStatusResponse
    init(pb: ServerPB_Videochat_UploadShareStatusResponse) throws {}
}

extension UploadShareStatusRequest.ShareType {
    var pbType: ServerPB_Videochat_UploadShareStatusRequest.ShareType {
        switch self {
        case .unknown: return .unknown
        case .shareScreen: return .shareScreen
        }
    }
}

extension UploadShareStatusRequest.ShareScreenStatus {
    var pbType: ServerPB_Videochat_UploadShareStatusRequest.ShareScreenStatus {
        var shareScreenStatus = ServerPB_Videochat_UploadShareStatusRequest.ShareScreenStatus()
        shareScreenStatus.status = status.pbType
        return shareScreenStatus
    }
}

extension UploadShareStatusRequest.ShareScreenStatus.Status {
    var pbType: ServerPB_Videochat_UploadShareStatusRequest.ShareScreenStatus.Status {
        switch self {
        case .unknown: return .unknown
        case .firstFrameReceived: return .firstFrameReceived
        }
    }
}
