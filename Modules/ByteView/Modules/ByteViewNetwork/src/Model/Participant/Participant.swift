//
//  Participant.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/11/18.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon

/// 参会人对象
/// - Videoconference_V1_Participant
public struct Participant: Equatable {
    public init(meetingId: String,
                userId: String,
                type: ParticipantType,
                deviceId: String,
                interactiveId: String,
                status: Status,
                isHost: Bool,
                offlineReason: OfflineReason,
                deviceType: DeviceType,
                settings: ParticipantSettings,
                joinTime: Int64,
                capabilities: VideoChatCapabilities,
                inviter: ByteviewUser?,
                ongoingMeetingId: String?,
                ongoingMeetingInteractiveId: String?,
                role: Role,
                pstnInfo: PSTNInfo?,
                meetingRole: MeetingRole,
                isMeetingOwner: Bool,
                micHandsUpTime: Int64,
                cameraHandsUpTime: Int64,
                sortName: String,
                isLarkGuest: Bool,
                tenantId: String,
                tenantTag: TenantTag,
                seqId: Int64,
                globalSeqId: Int64,
                rtcJoinId: String,
                breakoutRoomId: String,
                callMeInfo: CallMeInfo,
                offlineReasonDetails: [OfflineReasonDetail],
                leaveTime: Int64,
                breakoutRoomStatus: BreakoutRoomStatus?,
                sortID: Int64?,
                refuseReplyTime: Int64,
                replaceOtherDevice: Bool
    ) {
        self.meetingId = meetingId
        self.user = ByteviewUser(id: userId, type: type, deviceId: deviceId)
        self.interactiveId = interactiveId
        self.status = status
        self.isHost = isHost
        self.offlineReason = offlineReason
        self.deviceType = deviceType
        self.settings = settings
        self.joinTime = joinTime
        self.capabilities = capabilities
        self.inviter = inviter
        self.ongoingMeetingId = ongoingMeetingId
        self.ongoingMeetingInteractiveId = ongoingMeetingInteractiveId
        self.role = role
        self.pstnInfo = pstnInfo
        self.meetingRole = meetingRole
        self.isMeetingOwner = isMeetingOwner
        self.micHandsUpTime = micHandsUpTime
        self.cameraHandsUpTime = cameraHandsUpTime
        self.sortName = sortName
        self.isLarkGuest = isLarkGuest
        self.tenantId = tenantId
        self.tenantTag = tenantTag
        self.seqId = seqId
        self.globalSeqId = globalSeqId
        self.rtcJoinId = rtcJoinId
        self.breakoutRoomId = breakoutRoomId
        self.callMeInfo = callMeInfo
        self.offlineReasonDetails = offlineReasonDetails
        self.leaveTime = leaveTime
        self.breakoutRoomStatus = breakoutRoomStatus
        self.sortID = sortID
        self.refuseReplyTime = refuseReplyTime
        self.replaceOtherDevice = replaceOtherDevice
    }

    public init(meetingId: String, id: String, type: ParticipantType, deviceId: String, interactiveId: String) {
        self.init(meetingId: meetingId, userId: id, type: type, deviceId: deviceId, interactiveId: interactiveId, status: .unknown,
                  isHost: false, offlineReason: .unknown, deviceType: .unknown, settings: .init(), joinTime: 0, capabilities: .init(),
                  inviter: nil, ongoingMeetingId: nil, ongoingMeetingInteractiveId: nil, role: .unknown, pstnInfo: nil, meetingRole: .participant,
                  isMeetingOwner: false, micHandsUpTime: 0, cameraHandsUpTime: 0, sortName: "", isLarkGuest: false, tenantId: "",
                  tenantTag: .standard, seqId: 0, globalSeqId: 0, rtcJoinId: "", breakoutRoomId: "", callMeInfo: .init(),
                  offlineReasonDetails: [], leaveTime: 0, breakoutRoomStatus: nil, sortID: nil, refuseReplyTime: 0, replaceOtherDevice: false)
    }

    public let user: ByteviewUser

    /// 所属会议id
    public var meetingId: String

    /// 交互ID，记录每一次完整的交互
    public let interactiveId: String

    /// 用户状态
    public var status: Status

    /// 是否为主持人
    public var isHost: Bool

    /// 参会者不在线原因
    public var offlineReason: OfflineReason

    /// 设备平台
    public var deviceType: DeviceType

    /// 参会者设置
    public var settings: ParticipantSettings

    /// 最后一次join time
    public var joinTime: Int64

    /// 参会者能力
    public var capabilities: VideoChatCapabilities

    /// 邀请人
    public var inviter: ByteviewUser?

    /// 在会中的meeting_id
    public var ongoingMeetingId: String?

    /// 在会中的interactive_id
    public var ongoingMeetingInteractiveId: String?

    /// 用户角色
    public var role: Role = .unknown

    /// 如果是PSTN或者SIP这一类用户，PSTNInfo包含地址信息
    public var pstnInfo: PSTNInfo?

    /// 会议中角色
    public var meetingRole: MeetingRole
    /// 是否是会议owner
    public var isMeetingOwner: Bool

    /// 举手申请发言的时间
    public var micHandsUpTime: Int64

    /// 举手申请开摄像头的时间
    public var cameraHandsUpTime: Int64

    /// store a name for sort
    public var sortName: String

    /// lark游客，技术侧统一命名
    public var isLarkGuest: Bool

    /// 参会人所属租户ID
    public var tenantId: String

    public var tenantTag: TenantTag

    public var seqId: Int64

    /// 全局participants维度的seqID
    public var globalSeqId: Int64

    /// 能保证会中一定唯一的ID，作为RTC入会标
    public var rtcJoinId: String

    /// 用户所在讨论组ID
    public var breakoutRoomId: String

    /// 如果该用户离会，离会产生的细节
    public var offlineReasonDetails: [OfflineReasonDetail]

    public var callMeInfo: CallMeInfo

    ///如果参会人当前idle，则是最后一次离会时间
    public var leaveTime: Int64

    /// 拒绝回复的时间
    public var refuseReplyTime: Int64

    /// 不想引起Participant本身变化的属性放在这里
    private let associatedProps = ParticipantAssociateProperties()

    /// 用户信息，设置userInfo不会改变Participant
    public var userInfo: ParticipantUserInfo? {
        get { associatedProps.userInfo }
        set { associatedProps.userInfo = newValue }
    }

    /// 绑定的对象，目前仅用于自己连接的会议室
    public var binder: Participant? {
        get { associatedProps.binder }
        set { associatedProps.binder = newValue }
    }

    public var breakoutRoomStatus: BreakoutRoomStatus?

    public var sortID: Int64?

    public var replaceOtherDevice: Bool
}

extension Participant {
    private class ParticipantAssociateProperties: Equatable {
        @RwAtomic
        var userInfo: ParticipantUserInfo?

        @RwAtomic
        var binder: Participant?

        /// 这个类里的属性不影响participant的判等
        static func == (lhs: Participant.ParticipantAssociateProperties, rhs: Participant.ParticipantAssociateProperties) -> Bool {
            true
        }
    }

    public struct BreakoutRoomStatus: Equatable {
        public var needHelp: Bool
        public var hostSetBreakoutRoomID: String
    }
}

extension Participant {
    public enum Status: Int, Hashable {
        /// 未知状态，向后兼容
        case unknown // = 0
        /// 请求会议中
        case calling // = 1
        /// 在当前通话中
        case onTheCall // = 2
        /// 在当前会话呼叫中
        case ringing // = 3
        /// 不在会议中，已经离开会议。
        case idle // = 4
    }

    /// OfflineReason 字段只在IDLE状态下才有效
    public enum OfflineReason: Int, Hashable {
        case unknown // = 0
        /// 因忙线不在线
        case busy // = 1
        /// 因拒绝不在线
        case refuse // = 2
        /// 因无响应不在线
        case ringTimeout // = 3
        /// 被踢出会议
        case kickOut // = 4
        /// 主动离开会议
        case leave // = 5
        /// 主持人结束会议
        case end // = 6
        /// 邀请被取消
        case cancel // = 7
        /// 会议室超时
        case overtime // = 8
        /// 接听其他会议导致结束
        case acceptOther // = 9
        /// 10 和 11 被 byteview-pb 使用，如果是两边都需要用到的类型需要跳过这两个数字
        case forbiddenTarget = 12
        /// 因加入等候室导致当前participant变为 idle
        case joinLobby // = 13
        /// 呼叫异常
        case callException // = 14
        /// 会议达到单人能停留的最大时间，因此人员离会
        case autoEnd // = 15
        ///因为设备或者网络不安全，离开会议
        case leaveBecauseUnsafe // = 17
        // 主持人将嘉宾改为了观众
        case webinarSetFromParticipantToAttendee // = 18
        // 主持人将观众改为了嘉宾
        case webinarSetFromAttendeeToParticipant // = 19
        // 会中设备切换
        case otherDeviceReplaced = 22
    }

    public enum OfflineReasonDetail: Int, Hashable {

        /// 未知
        case unknown // = 0

        /// 在其它设备上接听
        case acceptElsewhere // = 1

        /// 在其它设备上挂断
        case refuseElsewhere // = 2
    }

    public enum DeviceType: Int, Hashable {
        case unknown // = 0
        /// 桌面端
        case desktop // = 1
        /// 移动端
        case mobile // = 2
        /// WEB端
        case web // = 3
    }

    public enum MeetingRole: Int, Hashable, Codable {
        /// 默认参会人
        case participant // = 0
        /// 主持人
        case host // = 1
        /// 联席主持人
        case coHost // = 2
        /// WEBINAR 观众
        case webinarAttendee // = 3
    }

    public struct VideoChatCapabilities: Equatable {
        /// 是否具有支持vc follow
        public var follow: Bool
        /// 是否支持被转移共享者
        public var followPresenter: Bool
        /// 所具备的follow的能力，主要用于判断是否支持生产某一策略生产的数据
        public var followProduceStrategyIds: [String]
        /// 是否可被设置为传译员
        public var becomeInterpreter: Bool
        /// 是否可以被设置为主持人
        public var canBeHost: Bool
        /// 是否可以被设置为联席主持人
        public var canBeCoHost: Bool

        public init(follow: Bool,
                    followPresenter: Bool,
                    followProduceStrategyIds: [String],
                    becomeInterpreter: Bool,
                    canBeHost: Bool,
                    canBeCoHost: Bool) {
            self.follow = follow
            self.followPresenter = followPresenter
            self.followProduceStrategyIds = followProduceStrategyIds
            self.becomeInterpreter = becomeInterpreter
            self.canBeHost = canBeHost
            self.canBeCoHost = canBeCoHost
        }

        public init() {
            self.init(follow: false, followPresenter: false, followProduceStrategyIds: [], becomeInterpreter: false,
                      canBeHost: false, canBeCoHost: false)
        }
    }

    public enum Role: Int, Hashable, Codable {
        case unknown // = 0
        case interviewer // = 1
        case interviewee // = 2
    }

    public enum CallMeIdleReason: Int, Hashable, Codable {
        case unknown // = 0 未知
        case ringTimeout // = 1 超时
        case kickout // = 2 被踢出会议
        case leave // = 3 主动离开会议
        case switchaudio // = 4 主动切换音频
        case cancel // = 5 邀请被取消
        case refuse // = 6 呼叫被拒绝
        case busy // = 7 PSTN忙线中
        case callException // = 8 呼叫异常
        case phoneUnbind // = 9 未绑定手机号
        case quotaUsedUp // = 10 租户余额不足
        case adminQuotaUsedUp // = 11 admin配置余额不足
        case disableOutgoing // = 12 禁止电话外呼
    }

    public struct CallMeInfo: Equatable {
        public var status: Status
        public var callmeIdleReason: CallMeIdleReason
        public var callMeRtcJoinID: String

        public init(status: Status,
                    callmeIdleReason: CallMeIdleReason, callMeRtcJoinID: String) {
            self.status = status
            self.callmeIdleReason = callmeIdleReason
            self.callMeRtcJoinID = callMeRtcJoinID
        }

        public init() {
            self.init(status: .unknown, callmeIdleReason: .unknown, callMeRtcJoinID: String())
        }
    }
}

public extension Participant {
    var type: ParticipantType { user.type }
    var deviceId: String { user.deviceId }
    var hostSetBreakoutRoomID: String { breakoutRoomStatus?.hostSetBreakoutRoomID ?? "" }
}

extension Participant: ParticipantIdConvertible {
    public var participantId: ParticipantId {
        ParticipantId(id: user.id, type: user.type, deviceId: user.deviceId, bindInfo: pstnInfo.map({ BindInfo(id: $0.bindId, type: $0.bindType)}))
    }
}

extension Participant: CustomStringConvertible {

    public var description: String {
        String(
            indent: "Participant",
            "status: \(status)",
            "user: \(user)",
            "interactiveId: \(interactiveId)",
            "rtcJoinId: \(rtcJoinId)",
            "joinTime: \(joinTime)",
            "breakoutRoomId: \(breakoutRoomId)",
            "role: \(role)",
            "meetingRole: \(meetingRole)",
            "guest: \(isLarkGuest)",
            "tenantTag: \(tenantTag)",
            "offlineReason: \(offlineReason)",
            "deviceType: \(deviceType)",
            "pstn: (\(pstnInfo?.bindType), \(pstnInfo?.bindId), \(pstnInfo?.pstnSubType)",
            "settings: \(settings)",
            "capabilities: \(capabilities)",
            "leaveTime: \(leaveTime)",
            "breakoutRoomStatus: \(breakoutRoomStatus)",
            "sortId: \(sortID)",
            "replyTime: \(refuseReplyTime)",
            "replaceOtherDevice: \(replaceOtherDevice)"
        )
    }
}

extension Participant.VideoChatCapabilities: CustomStringConvertible {
    public var description: String {
        String(indent: "Capabilities",
               "follow=\(follow.toInt)",
               "followPresenter=\(followPresenter.toInt)",
               "followProduce=\(followProduceStrategyIds)",
               "interpret=\(becomeInterpreter.toInt)",
               "canBeHost=\(canBeHost.toInt)",
               "canBeCoHost=\(canBeCoHost.toInt)"
        )
    }
}

extension Participant.MeetingRole: CustomStringConvertible {
    var pbType: PBParticipant.ParticipantMeetingRole {
        PBParticipant.ParticipantMeetingRole(rawValue: self.rawValue) ?? .participant
    }

    public var description: String {
        switch self {
        case .participant:
            return "participant"
        case .host:
            return "host"
        case .coHost:
            return "coHost"
        case .webinarAttendee:
            return "webinarAttendee"
        }
    }
}

extension Participant.Status: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .calling:
            return "calling"
        case .onTheCall:
            return "onTheCall"
        case .ringing:
            return "ringing"
        case .idle:
            return "idle"
        }
    }
}
