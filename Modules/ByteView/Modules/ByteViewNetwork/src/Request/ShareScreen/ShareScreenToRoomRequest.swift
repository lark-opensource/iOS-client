//
//  ShareScreenToRoomRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 本地投屏
/// - SHARE_SCREEN_TO_ROOM = 2324
/// - Videoconference_V1_ShareScreenToRoomRequest
public struct ShareScreenToRoomRequest {
    public static let command: NetworkCommand = .rust(.shareScreenToRoom)
    public typealias Response = ShareScreenToRoomResponse

    public init(shareCode: String, meetingNo: String, meetingId: String?, url: String?, confirmSetting: ConfirmSetting?, whiteboardSettings: WhiteboardSettings?) {
        self.shareCode = shareCode
        self.meetingNo = meetingNo
        self.meetingId = meetingId
        self.url = url
        self.confirmSetting = confirmSetting
        self.whiteboardSettings = whiteboardSettings
    }

    /// 共享码
    public var shareCode: String

    /// 9位会议号，和共享码二选一
    public var meetingNo: String

    /// 用户在点投屏的时候，已经在这个会中了
    public var meetingId: String?

    /// MagicShare 分享路径
    public var url: String?

    /// 是否需要判断二次弹窗
    public var confirmSetting: ConfirmSetting?

    public var whiteboardSettings: WhiteboardSettings?

    public enum ConfirmSetting: Int, CustomStringConvertible {
        /// 已二次确认，不需要弹窗
        case confirmed // = 0

        /// 不需要
        case neverNeed // = 1

        /// 仅跨租户时需要
        case onlyCrossTanent // = 2

        /// 始终需要
        case always // = 3

        public var description: String {
            switch self {
            case .confirmed:
                return "confirmed"
            case .neverNeed:
                return "neverNeed"
            case .onlyCrossTanent:
                return "onlyCrossTanent"
            case .always:
                return "always"
            }
        }
    }
}

/// - Videoconference_V1_ShareScreenToRoomResponse
public struct ShareScreenToRoomResponse {

    /// 视频会议信息
    public var info: VideoChatInfo

    public var confirmationInfo: ConfirmationInfo

    public struct ConfirmationInfo {

        public var needConfirm: Bool

        public var roomInfo: RoomInfo

        /// 透传VC从Room服务获取的信息，端上按需自行使用
        public struct RoomInfo {
            public var roomID: Int64

            /// room 租户id
            public var tanentID: Int64

            /// 会议室全名
            public var fullName: String
        }
    }
}

extension ShareScreenToRoomRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_ShareScreenToRoomRequest
    func toProtobuf() throws -> Videoconference_V1_ShareScreenToRoomRequest {
        var request = ProtobufType()
        request.shareCode = shareCode
        request.meetingNo = meetingNo
        request.source = .vcFromUser
        request.shareType = .screen
        if let meetingId = meetingId, !meetingId.isEmpty {
            request.meetingID = meetingId
        }
        if let url = url {
            var magicInfo = ProtobufType.MagicShareInfo()
            magicInfo.url = url
            magicInfo.lifeTime = .permanent
            magicInfo.options = .init()
            magicInfo.options.defaultFollow = true
            magicInfo.options.forceFollow = false
            request.magicShareInfo = magicInfo
            request.shareType = .magicShare
        }
        if let confirmSetting = confirmSetting {
            switch confirmSetting {
            case .neverNeed: request.confirmSetting = .neverNeed
            case .always: request.confirmSetting = .always
            case .confirmed: request.confirmSetting = .confirmed
            case .onlyCrossTanent: request.confirmSetting = .onlyCrossTanent
            }
        }
        if let whiteboardSettings = whiteboardSettings {
            var info = Videoconference_V1_ShareScreenToRoomRequest.WhiteboardInfo()
            info.whiteboardSettings = whiteboardSettings.pbType
            request.whiteboardInfo = info
            request.shareType = .whiteBoard
        }
        return request
    }
}

extension ShareScreenToRoomResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_ShareScreenToRoomResponse
    init(pb: Videoconference_V1_ShareScreenToRoomResponse) throws {
        self.info = pb.info.vcType
        self.confirmationInfo = pb.confirmationInfo.vcType
    }
}

extension ShareScreenToRoomRequest: CustomStringConvertible {
    public var description: String {
        let validUrl = url ?? ""
        return String(indent: "ShareScreenToRoomRequest",
               "shareCode:\(shareCode)",
               "meetingNo:\(meetingNo)",
               "meetingId:\(meetingId)",
               "url:\(validUrl.hash)",
               "confirmSetting:\(confirmSetting)",
               "whiteboardSettings:\(whiteboardSettings)"
        )
    }
}
