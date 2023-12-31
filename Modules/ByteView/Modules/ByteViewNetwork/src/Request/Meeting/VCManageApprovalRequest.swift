//
//  ManageApprovalRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - VC_MANAGE_APPROVAL
/// - Videoconference_V1_VCManageApprovalRequest
public struct VCManageApprovalRequest {
    public static let command: NetworkCommand = .rust(.vcManageApproval)

    public init(meetingId: String, breakoutRoomId: String?, approvalType: ApprovalType, approvalAction: ApprovalAction,
                users: [ByteviewUser]) {
        self.meetingId = meetingId
        self.breakoutRoomId = breakoutRoomId
        self.approvalType = approvalType
        self.approvalAction = approvalAction
        self.users = users
    }

    public var meetingId: String

    public var breakoutRoomId: String?

    public var approvalType: ApprovalType

    public var approvalAction: ApprovalAction

    public var users: [ByteviewUser]

    /// 审核类型
    public enum ApprovalType: Int, Hashable {

        /// 等候室参会人审核
        case meetinglobby = 1

        /// 举手
        case putUpHands // = 2

        /// 讨论组请求主持人协助
        case breakoutRoomUserNeedHelp // = 3

        /// 摄像头举手
        case putUpHandsInCam // = 4
    }

    /// 审核状态
    public enum ApprovalAction: Int, Hashable {

        /// 审核通过
        case pass = 1

        /// 审核拒绝
        case reject // = 2

        /// 全部审核通过
        case allPass // = 3

        /// 全部审核拒绝
        case allReject // = 4

        /// 会议不支持该能力
        case meetingNotSupport // = 5
    }
}

extension VCManageApprovalRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_VCManageApprovalRequest
    func toProtobuf() throws -> Videoconference_V1_VCManageApprovalRequest {
        var request = ProtobufType()
        request.approvalType = .init(rawValue: approvalType.rawValue) ?? .unknown
        request.approvalAction = .init(rawValue: approvalAction.rawValue) ?? .unknownaction
        request.users = users.map({ $0.pbType })
        request.meetingID = meetingId
        if let id = RequestUtil.normalizedBreakoutRoomId(breakoutRoomId) {
            request.breakoutRoomID = id
        }
        return request
    }
}
