//
//  VideoChatInfo.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/11/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon

/// 会议信息
/// - NOTIFY_VIDEO_CHAT = 2210
/// - Videoconference_V1_VideoChatInfo
public struct VideoChatInfo: Equatable {
    public init(id: String,
                type: MeetingType,
                participants: [Participant],
                groupId: String,
                info: String,
                inviterId: String,
                inviterType: ParticipantType,
                hostId: String,
                hostType: ParticipantType,
                hostDeviceId: String,
                force: Bool,
                endReason: EndReason,
                actionTime: MeetingActionTime?,
                seqId: Int64,
                settings: VideoChatSettings,
                vendorType: VendorType,
                startTime: Int64,
                meetNumber: String,
                msg: MsgInfo?,
                meetingSource: MeetingSource,
                isVoiceCall: Bool,
                sponsor: ByteviewUser,
                tenantId: String,
                isLarkMeeting: Bool,
                meetingOwner: ByteviewUser?,
                isExternalMeetingWhenRing: Bool,
                sid: String?,
                breakoutRoomInfos: [BreakoutRoomInfo],
                rtcInfo: MeetingRtcInfo?,
                rtmInfo: MeetingRTMInfo?,
                isCrossWithKa: Bool,
                uniqueId: String,
                webinarAttendeeNum: Int,
                relationTagWhenRing: CollaborationRelationTag?,
                e2EeJoinInfo: E2EEJoinInfo?,
                ringtone: String?) {
        self.id = id
        self.host = ByteviewUser(id: hostId, type: hostType, deviceId: hostDeviceId)
        self.type = type
        self.participants = participants
        self.groupId = groupId
        self.info = info
        self.inviterId = inviterId
        self.inviterType = inviterType
        self.force = force
        self.endReason = endReason
        self.actionTime = actionTime
        self.seqId = seqId
        self.settings = settings
        self.vendorType = vendorType
        self.startTime = startTime
        self.meetNumber = meetNumber
        self.msg = msg
        self.meetingSource = meetingSource
        self.isVoiceCall = isVoiceCall
        self.sponsor = sponsor
        self.tenantId = tenantId
        self.isLarkMeeting = isLarkMeeting
        self.meetingOwner = meetingOwner
        self.isExternalMeetingWhenRing = isExternalMeetingWhenRing
        self.sid = sid
        self.breakoutRoomInfos = breakoutRoomInfos
        self.rtcInfo = rtcInfo
        self.rtmInfo = rtmInfo
        self.isCrossWithKa = isCrossWithKa
        self.uniqueId = uniqueId
        self.webinarAttendeeNum = webinarAttendeeNum
        self.relationTagWhenRing = relationTagWhenRing
        self.e2EeJoinInfo = e2EeJoinInfo
        self.ringtone = ringtone
    }

    /// 会议关联的内部信息
    /// NOTE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    /// 以下字段必须与 CreateVideoChatResponse 保持一致
    public var id: String

    /// 主持人的id，可以从participant中查, 已弃用，3.2起使用host_device_id
    public var host: ByteviewUser

    /// 会议类型，call，或者是meet
    public var type: MeetingType

    /// participants信息
    public var participants: [Participant]

    /// 多人会议时的群组ID
    public var groupId: String

    /// 第三方会议详情信息，Json格式
    public var info: String

    /// 用于显示发起邀请的人
    public var inviterId: String

    ///邀请人类型
    public var inviterType: ParticipantType

    /// 是否强制加入
    public var force: Bool

    /// 仅结束时使用，表明结束原因
    public var endReason: EndReason

    /// action产生时间
    public var actionTime: MeetingActionTime?

    /// 服务端VideoChatInfo的自增id
    public var seqId: Int64

    /// 多人会议设置（最大人数限制在该结构体中）
    public var settings: VideoChatSettings

    /// 会议SDK，必传
    public var vendorType: VendorType

    ///会议开始时间
    public var startTime: Int64

    /// 会议号/MeetingID
    public var meetNumber: String

    /// 会议提示信息
    public var msg: MsgInfo?

    ///会议来源：用户还是日历
    public var meetingSource: MeetingSource

    /// 是否是1v1语音通话
    public var isVoiceCall: Bool

    /// 会议发起人
    public var sponsor: ByteviewUser

    /// 会议所属租户ID
    public var tenantId: String

    /// 会议类型 true -> Lark会议 , false -> 飞书会议
    public var isLarkMeeting: Bool

    /// 会议组织者
    public var meetingOwner: ByteviewUser?

    /// 是否为外部会议，仅在响铃推送是使用
    public var isExternalMeetingWhenRing: Bool

    /// 服务端推送的sid，打点用
    public var sid: String?

    public var breakoutRoomInfos: [BreakoutRoomInfo]

    /// rtc info
    public var rtcInfo: MeetingRtcInfo?

    /// rtc登录信息
    public var rtmInfo: MeetingRTMInfo?

    /// 私有化互通
    public var isCrossWithKa: Bool

    public var relationTagWhenRing: CollaborationRelationTag?

    /// 日程会议需要的uniqueID
    public var uniqueId: String

    public var webinarAttendeeNum: Int

    /// E2EE 入会秘钥信息
    public var e2EeJoinInfo: E2EEJoinInfo?

    /// 响铃铃声（设备维度），受 admin 及用户个人设置影响
    /// 如果个人未设置，跟随 admin 配置
    public var ringtone: String?

    public enum EndReason: Int, Hashable {
        /// 未知
        case unknown // = 0
        case hangUp // = 1

        /// 心跳断开
        case connectionFailed // = 2

        /// 拨号超时
        case ringTimeout // = 3

        /// SDK 异常
        case sdkException // = 4

        /// 主叫取消
        case cancel // = 5

        /// 被叫拒绝
        case refuse // = 6

        /// 接听其他会议导致结束
        case acceptOther // = 7

        /// 免费试用结束
        case trialTimeout // = 8

        /// 呼叫异常
        case callException // = 9
        case autoEnd // = 10
    }

    /// **************注意**********************
    /// VendorType从2.2.0启用，其枚举值与下面info里面不一致，
    /// info中，sdk的类型使用infoType表示，它的值是字符串“byteRTC”或"zoom"
    /// 从2.2.0之后不推荐再使用info字段来判断sdk类型，因为它是一个json字符串，语义不明确
    public enum VendorType: Int, Hashable {

        /// 未知
        case unknown // = 0

        /// ZOOM SDK
        case zoom // = 1

        /// 自研SDK
        case rtc // = 2

        /// VC-RTC SDK
        case larkRtc // = 3

        /// VC-RTC SDK for pre
        case larkPreRtc // = 4

        /// rtc测试Pre环境
        case larkRtcTestPre = 240

        /// rtc测试高斯环境
        case larkRtcTestGauss = 241

        /// rtc测试环境
        case larkRtcTest = 255
    }

    public enum MeetingSource: Int, Hashable {
        /// 未知
        case unknown // = 0
        case vcFromUser // = 1
        case vcFromCalendar // = 2
        case vcFromInterview // = 3
        case vcFromDoc // = 5
    }
}

extension VideoChatInfo {
    public init() {
        self.init(id: "", type: .meet, participants: [], groupId: "", info: "", inviterId: "", inviterType: .larkUser,
                  hostId: "", hostType: .larkUser, hostDeviceId: "", force: false, endReason: .unknown,
                  actionTime: nil, seqId: 0, settings: .init(), vendorType: .unknown, startTime: 0, meetNumber: "", msg: nil,
                  meetingSource: .unknown, isVoiceCall: false, sponsor: .init(id: "", type: .unknown),
                  tenantId: "", isLarkMeeting: false, meetingOwner: nil,
                  isExternalMeetingWhenRing: false, sid: "", breakoutRoomInfos: [], rtcInfo: nil, rtmInfo: nil, isCrossWithKa: false,
                  uniqueId: "", webinarAttendeeNum: 0, relationTagWhenRing: nil, e2EeJoinInfo: nil, ringtone: nil)
    }
}

extension VideoChatInfo: CustomStringConvertible {

    public var description: String {
        let participantsInfo: String
        if participants.count > 20 {
            participantsInfo = "participants: count=\(participants.count)"
        } else {
            participantsInfo = "participants: \(participants)"
        }
        return String(
            indent: "VideoChatInfo",
            "id: \(id)",
            "host: \(host)",
            "type: \(type)",
            "groupId: \(groupId)",
            "inviterId: \(inviterId)",
            "force: \(force)",
            "endReason: \(endReason)",
            "seqId: \(seqId)",
            "settings: \(settings)",
            "vendorType: \(vendorType)",
            "startTime: \(startTime)",
            "inviterType: \(inviterType)",
            "meetNumber: \(meetNumber)",
            "msg: \(msg)",
            "meetingSource: \(meetingSource)",
            "isVoiceCall: \(isVoiceCall)",
            "sponsor: \(sponsor)",
            "tenantId: \(tenantId)",
            "isLarkMeeting: \(isLarkMeeting)",
            "meetingOwner:\(meetingOwner)",
            "isExternalMeetingWhenRing: \(isExternalMeetingWhenRing)",
            "sid: \(sid)",
            "isOpenBreakoutRoom: \(settings.isOpenBreakoutRoom)",
            participantsInfo,
            "rtcInfo: \(rtcInfo)",
            "rtmInfo: \(rtmInfo?.uid)",
            "isCrossWithKa: \(isCrossWithKa)",
            "uniqueId: \(uniqueId)",
            "webinarAttendeeNum: \(webinarAttendeeNum)",
            "relationTagWhenRing: \(relationTagWhenRing)",
            "E2EeKey: \(e2EeJoinInfo)",
            "ringtone: \(ringtone)"
        )
    }
}

extension VideoChatInfo.MeetingSource: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .vcFromUser:
            return "vcFromUser"
        case .vcFromCalendar:
            return "vcFromCalendar"
        case .vcFromInterview:
            return "vcFromInterview"
        case .vcFromDoc:
            return "vcFromDoc"
        }
    }
}
