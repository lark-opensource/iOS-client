//
//  CreateVideoChatRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/11/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 创建会议，返回VideoChatInfo信息
/// - CREATE_VIDEO_CHAT = 2205
/// - Videoconference_V1_CreateVideoChatRequest
public struct CreateCallRequest {
    public static let command: NetworkCommand = .rust(.createVideoChat)
    public typealias Response = VideoChatInfo

    /// - parameters:
    ///     - id: 被叫人ID
    ///     - idType: 被叫人ID类型
    ///     - secureChatId: 密聊ID
    ///     - isVoiceCall: 是否是语音通话
    public init(id: String, idType: IdType, secureChatId: String, isVoiceCall: Bool, isE2EeMeeting: Bool = false) {
        self.id = id
        self.idType = idType
        self.secureChatId = secureChatId
        self.isVoiceCall = isVoiceCall
        self.isE2EeMeeting = isE2EeMeeting
    }

    /// 被叫人ID
    public var id: String
    /// 被叫人ID类型
    public var idType: IdType
    /// 密聊ID
    public var secureChatId: String
    /// 是否是语音通话
    public var isVoiceCall: Bool
    ///
    public var isE2EeMeeting: Bool

    public enum IdType {
        case unknown
        /// 预约ID
        case reservationId
        case userId
        /// 办公电话直呼用户 ID，通过 IM 单聊页面或用户 profile 页呼出
        case directCallUserID
        /// 办公电话直呼电话号码，通过拨号盘呼出
        case directCallPhoneNumber
        /// 办公电话直呼电话号码，招聘电话
        case directCallCandidate
        /// ip_Phone拨打
        case callByIpPhone
        /// 招聘电话
        case recruitmentPhone
    }
}

extension CreateCallRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_CreateVideoChatRequest

    func toProtobuf() throws -> ProtobufType {
        var request = ProtobufType()
        switch idType {
        case .userId:
            request.participantIds = [id]
        case .reservationId:
            request.reservationID = id
        case .directCallUserID:
            var pstnInfo = PSTNInfo()
            pstnInfo.bindId = id
            pstnInfo.bindType = .lark
            pstnInfo.participantType = .pstnUser
            pstnInfo.pstnSubType = .enterprisePhone
            request.pstnInfo = pstnInfo.pbType
        case .directCallPhoneNumber:
            var pstnInfo = PSTNInfo()
            pstnInfo.mainAddress = id
            pstnInfo.participantType = .pstnUser
            pstnInfo.pstnSubType = .enterprisePhone
            request.pstnInfo = pstnInfo.pbType
        case .directCallCandidate:
            var pstnInfo = PSTNInfo()
            pstnInfo.bindId = id
            pstnInfo.bindType = .people
            pstnInfo.participantType = .pstnUser
            request.pstnInfo = pstnInfo.pbType
        case .callByIpPhone:
            var pstnInfo = PSTNInfo()
            pstnInfo.mainAddress = id
            pstnInfo.participantType = .pstnUser
            pstnInfo.pstnSubType = .ipPhone
            request.pstnInfo = pstnInfo.pbType
        case .recruitmentPhone:
            var pstnInfo = PSTNInfo()
            pstnInfo.mainAddress = id
            pstnInfo.participantType = .pstnUser
            pstnInfo.bindType = .people
            pstnInfo.pstnSubType = .recruitmentPhone
            request.pstnInfo = pstnInfo.pbType
        default:
            break
        }
        request.groupID = secureChatId
        request.topic = ""
        request.type = .call
        request.share = false
        request.isVoiceCall = isVoiceCall
        request.vendorType = .rtc
        let ntpTime = Int64(Date().timeIntervalSince1970 * 1000)
        var actionTime = PBActionTime()
        actionTime.invite = ntpTime
        request.actionTime = actionTime

        var videoChatSettings = PBVideoChatSettings()
        videoChatSettings.isE2EeMeeting = isE2EeMeeting
        request.meetingSettings = videoChatSettings

        return request
    }
}

extension CreateCallRequest: CustomStringConvertible {
    public var description: String {
        let ID: String
        switch idType {
        case .directCallPhoneNumber, .directCallCandidate, .callByIpPhone, .recruitmentPhone:
            ID = String(id.count)
        default:
            ID = id
        }
        return String(indent: "CreateCallRequest",
                      "id: \(ID)",
                      "idType: \(idType)",
                      "secureChatId: \(secureChatId)",
                      "isVoiceCall: \(isVoiceCall)",
                      "isE2EeMeeting: \(isE2EeMeeting)"
                    )
    }
}
