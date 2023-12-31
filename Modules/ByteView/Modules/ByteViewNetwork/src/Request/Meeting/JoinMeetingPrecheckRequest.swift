//
//  JoinMeetingPrecheckRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/11/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 视频会议入会前置检测
/// - JOIN_MEETING_PRE_CHECK = 2351
/// - ServerPB_Videochat_JoinMeetingPreCheckRequest
public struct JoinMeetingPrecheckRequest {
    public static let command: NetworkCommand = .server(.joinMeetingPreCheck)
    public typealias Response = JoinMeetingPrecheckResponse

    public init(id: String, idType: IDType, needInfo: Bool, interviewRole: Participant.Role?) {
        self.id = id
        self.idType = idType
        self.needInfo = needInfo
        self.interviewRole = interviewRole
    }

    /// joinMeeting检测所用到的id，包含 meetingID, groupID,uniqueID,meetingNO, 被呼叫的目标userID
    public var id: String

    public var idType: IDType

    public var needInfo: Bool

    /// 面试场景下使用，需要检测的角色
    public var interviewRole: Participant.Role?

    public enum IDType: Int, Equatable {
        case unknown // = 0
        case meetingid // = 1
        case uniqueid // = 2
        case groupid // = 3
        case meetingno // = 4

        /// 面试UniqueID;
        case interviewuid // = 5
        case callTargetUser // = 6

        /// 预约号
        case reservationID // = 7
    }
}

/// ServerPB_Videochat_JoinMeetingPreCheckResponse
public struct JoinMeetingPrecheckResponse {

    public var checkType: CheckType

    public var associatedVcInfo: AssociatedVideoChatInfo

    public var vendorType: VideoChatInfo.VendorType

    public var rtcParameter: String?

    public var isE2Ee: Bool

    public enum CheckType: Int, Equatable {
        case unknown // = 0
        case success // = 1

        /// 会议已结束
        case meetingEnded // = 2

        /// 会议人数达到上限
        case participantLimitExceed // = 3

        /// 会议已被锁定
        case meetingLocked // = 4

        /// meetingNO已失效
        case meetingNumberInvalid // = 5

        /// voip忙线
        case voipBusy // = 6

        /// 版本不支持
        case versionLow // = 7

        /// 当前设备已在会中
        case deviceInMeeting // = 8

        /// 当前设备在响铃状态
        case deviceRinging // = 9

        /// 群禁言，无权限发起视频会议
        case chatPostNoPermission // = 10

        /// 租户被拉入黑名单，不能发起视频会议
        case tenantInBlacklist // = 11

        /// 日程已过期（只在uniqueID检测日程详情页面使用）
        case calendarOutOfDate // = 12

        /// 无加入面试会议权限
        case interviewNoPermission // = 13

        /// 面试已过期
        case interviewOutOfDate // = 14

        /// 跳过15， 与room编号保持一致
        case collaborationBlocked = 16

        /// 需要申请协作权限, 需要申请权限通过后才能发起视频会议
        case collaborationNoRights // = 17

        /// 协作权限被屏蔽, 无法对他发起视频会议
        case collaborationBeBlocked // = 18

        /// 预约过期
        case reservationOutOfDate // = 19
    }

    public struct AssociatedVideoChatInfo: Equatable {
        public init(uniqueId: String?, vcInfos: [VideoChatInfo]) {
            self.uniqueId = uniqueId
            self.vcInfos = vcInfos
        }

        public var uniqueId: String?

        /// 绑定群聊组的VideoChat信息
        public var vcInfos: [VideoChatInfo]
    }
}

extension JoinMeetingPrecheckRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_JoinMeetingPreCheckRequest
    func toProtobuf() throws -> ServerPB_Videochat_JoinMeetingPreCheckRequest {
        var request = ProtobufType()
        request.id = id
        request.idType = .init(rawValue: idType.rawValue) ?? .unknown
        if needInfo {
            request.isNeedAssociatedVcInfo = true
        }
        if let interviewRole = interviewRole {
            request.interviewRole = .init(rawValue: interviewRole.rawValue) ?? .unknowRole
        }
        return request
    }
}

extension JoinMeetingPrecheckResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_JoinMeetingPreCheckResponse
    init(pb: ServerPB_Videochat_JoinMeetingPreCheckResponse) {
        self.checkType = .init(rawValue: pb.checkType.rawValue) ?? .unknown
        self.associatedVcInfo = .init(pb: pb.associatedVcInfo)
        self.vendorType = .init(rawValue: pb.vendorType.rawValue) ?? .unknown
        if pb.hasRtcParameter {
            self.rtcParameter = pb.rtcParameter
        } else {
            self.rtcParameter = nil
        }
        self.isE2Ee = pb.isE2Ee
    }
}

extension JoinMeetingPrecheckResponse.AssociatedVideoChatInfo: ProtobufDecodable {
    typealias ProtobufType = ServerPB_Videochat_JoinMeetingPreCheckResponse.AssociatedVideoChatInfo
    init(pb: ServerPB_Videochat_JoinMeetingPreCheckResponse.AssociatedVideoChatInfo) {
        self.uniqueId = pb.hasUniqueID ? pb.uniqueID : nil
        self.vcInfos = pb.vcInfos.map({ .init(serverPb: $0) })
    }
}

extension JoinMeetingPrecheckRequest: CustomStringConvertible {
    public var description: String {
        String(indent: "JoinMeetingPrecheckRequest",
               "id: \(id.hash)",
               "idType: \(idType)",
               "needInfo: \(needInfo)",
               "interviewRole: \(interviewRole)"
        )
    }
}
