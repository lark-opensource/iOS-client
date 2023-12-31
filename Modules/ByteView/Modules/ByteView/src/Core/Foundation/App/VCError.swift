//
//  VCError.swift
//  ByteView
//
//  Created by 李凌峰 on 2018/9/16.
//

// 参考文档：https://docs.bytedance.net/doc/GcytE2me92uRt1m4z1lvPa

import Foundation
import ByteViewNetwork

struct VCError: Error, Hashable {
    /// 22xxxx是服务端定义的错误码，其余是客户端定义的错误码
    let code: Int
    private let innerError: InnerError
    private init(_ innerError: InnerError) {
        self.innerError = innerError
        switch innerError {
        case .unknown:
            self.code = 0
        case .clientError(let error):
            self.code = error
        case .rustError(let error):
            self.code = error.code
        }
    }

    private enum InnerError: Hashable {
        case unknown
        case rustError(RustBizError)
        /// 客户端错误
        case clientError(Int)
    }
}

extension VCError {
    /// convert from VCError/RustBizError, otherwise unknown
    init(error: Error) {
        if let e = error as? VCError {
            self = e
        } else if let e = error as? RustBizError {
            self.init(.rustError(e))
        } else {
            self = .unknown
        }
    }

    /// Rust或后端错误，https://bytedance.feishu.cn/docs/doccnrymx4SKgYHGG8zzsu9tkWg
    var rustError: RustBizError? {
        switch self.innerError {
        case .rustError(let e):
            return e
        default:
            return nil
        }
    }

    var isHandled: Bool {
        switch self.innerError {
        case .rustError(let e):
            return e.isHandled
        default:
            return false
        }
    }
}

extension VCError {
    static func == (lhs: VCError, rhs: VCError) -> Bool {
        return lhs.code == rhs.code
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension VCError: ExpressibleByIntegerLiteral {
    typealias IntegerLiteralType = Int

    init(integerLiteral value: Int) {
        if let error = RustBizError(rawValue: value) {
            self.init(.rustError(error))
        } else if value < 0 {
            self.init(.clientError(value))
        } else {
            self = .unknown
        }
    }
}

/// server error convenience, https://bytedance.feishu.cn/docs/doccnrymx4SKgYHGG8zzsu9tkWg
extension VCError {
    /// 未知错误
    static let unknown: VCError = VCError(.unknown)

    /// 网络错误, 10008, 10009
    static let badNetwork: VCError = 10008
    static let badNetworkV2: VCError = 10009

    /// 主持人（自身）忙碌, 220001
    static let hostBusy: VCError = 220001
    /// 主持人（自身）忙碌, 222301
    static let hostIsInVC: VCError = 222301
    /// 主持人（自身）忙碌, 222302
    static let hostIsInVOIP: VCError = 222302

    /// 对方版本过低, 220002
    static let calleeVersionLow: VCError = 220002
    /// 被叫忙碌, 220003
    static let calleeBusy: VCError = 220003
    /// 服务器内部错误, 220004
    static let serverInternalError: VCError = 220004
    /// 主持人（自身）版本过低, 220005
    static let hostVersionLow: VCError = 220005
    /// 主持人（自身）被禁言, 220006
    static let bannedFromCreating: VCError = 220006

    /// 会议已经结束, 220101
    static let meetingHasFinished: VCError = 220101
    /// 操作无效, 220102
    static let actionRefused: VCError = 220102
    /// 会议号无效/会议不存在, 220301
    static let meetingNumberInvalid: VCError = 220301

    /// 参会者超过最大限制, 220801
    static let participantsOverload: VCError = 220801
    /// 220803
    static let participantStatusNotExcepted: VCError = 220803
    /// 220804
    static let participantRemoveError: VCError = 220804
    /// 220805
    static let participantMuteStatusUpdateError: VCError = 220805
    /// 220806
    static let noPermissionToInvite: VCError = 220806

    /// 记录不存在, 221101
    static let noRecord: VCError = 221101

    /// 231001
    static let shouldHandsUp: VCError = 231001
    /// 231002
    static let shouldCameraHandsUp: VCError = 231002
    /// 231101
    static let shareScreenStartError: VCError = 231101
    /// 231102
    static let shareScreenStopError: VCError = 231102
    /// 231103
    static let shareScreenUnknownError: VCError = 231103
    /// 无权限, 231104
    static let noPermission: VCError = 231104
    /// 231105
    static let transferHostError: VCError = 231105
    /// 本地投屏，投屏码是 room, 231106
    static let roomShareCode: VCError = 231106
    /// 本地投屏通过会议ID，会中无rooms, 231107
    static let shareScreenNoRooms: VCError = 231107
    /// 飞书用户通过会议ID在会议A，投会议A, 231108
    static let shareScreenInThisMeeting: VCError = 231108
    /// 飞书用户通过会议ID在会议A，投会议B, 231109
    static let shareScreenInOtherMeeting: VCError = 231109
    /// 飞书用户通过会议ID在会议A，投有线会议B, 231110
    static let shareScreenInWiredShare: VCError = 231110
    /// 当前用户无法将 GoogleDrive 文件设置为匿名访问, 231206
    static let googleDriveFileNoAnonymousPermission: VCError = 231206
    /// 231214
    static let googleDriveFileNoPublicSharing: VCError = 231214
    /// 231219
    static let shareFollowNotSupportCrossKaMeeting: VCError = 231219
    /// 232302
    static let noPermissionToJoinMeeting: VCError = 232302
    /// 入会失败，不支持替代入会
    static let replaceJoinUnsupported: VCError = 232310
    /// 本地投屏，投屏码无效, 232401
    static let invalidShareCode: VCError = 232401
    /// 本地投屏，无权限入会/投屏, 232402
    static let localShareNoPermission: VCError = 232402
    /// 高管控制， 232501
    static let executiveModeError: VCError = 232501
    /// 会议已被锁定, 232502
    static let meetingLocked: VCError = 232502
    /// 租户被拉入黑名单，不能发起视频会议, 232505
    static let tenantInBlacklist: VCError = 232505
    /// 会议未被认证, 233302
    static let uncertifiedMeeting: VCError = 233302

    /// 检测到对外拨打行为异常，已临时限制你的外呼权限，请稍后再试
    static let PstnOutgoingCallSuspend: VCError = 233313
    /// 一键PSTN入会，该用户类型暂不支持电话呼叫, 233316
    static let pstnInviteNoPhoneNumber: VCError = 233316
    /// 一键PSTN入会，管理员已设置电话号码管控，无法电话呼叫, 233317
    static let pstnInviteNoPhonePermission: VCError = 233317
    /// 合规校验不通过，无法入会/邀请入会
    static let newHitRiskControl: VCError = 233322
    /// 235000
    static let enterprisePhoneNoPermissionError: VCError = 235000
    /// 235001
    static let enterprisePhoneQuotaLimitError: VCError = 235001
    /// 特殊的服务号码,暂不支持拨打此号码, 235002
    static let enterprisePhoneNumberLimitError: VCError = 235002
    /// 不能给自己拨号, 235003
    static let enterprisePhoneCallSelfLimitError: VCError = 235003
    /// 只能拨打大陆的手机号, 235004
    static let enterprisePhoneCallInLandLimitError: VCError = 235004
    /// 余额不足, 235005
    static let enterprisePhoneUserQuotaLimitError: VCError = 235005
    /// 235006
    static let enterprisePhoneAreaCodeLimitError: VCError = 235006
    /// 235008 仅呼叫组织内成员
    static let enterprisePhoneCallerOrgOnlyError: VCError = 235008
    /// IM发言内容不符合用户协议, 235201
    static let notComplyUserAgreement: VCError = 235201
    /// 本地投屏，盒子不支持MagicShare, 236001
    static let magicShareBoxUnsupported: VCError = 236001
    /// 会中(客户端)一键邀请入口和企业办公电话入口 电话限制
    static let PhonePermissionError: VCError = 235009

    static let NotSupportBecomePanelist: VCError = 236000 // 暂不支持设置为嘉宾
    static let DeviceTypeNotSupportBecomeAttendee: VCError = 236001 // 该设备类型不支持设置为观众
    static let DeviceVersionNotSupportBecomeAttendee: VCError = 236002 // 该设备版本不支持设置为观众
    static let noCastWhiteboard: VCError = 236101 // 有线投屏不支持白板

    static let currentIsE2EeMeeting: VCError = 239010 // 当前是端到端加密会议
}

extension VCError {
    /// 会议已过期, -4
    static let meetingExpired: VCError = -4
    /// 其他设备VoIP, -5
    static let otherDeviceVoIP: VCError = -5
    /// 群禁言, -6
    static let chatPostNoPermission: VCError = -6
    /// 开启标注失败, -7
    static let startSketchFailed: VCError = -7
    /// 获取当前标注失败, -8
    static let fetchAllSketchDataFailed: VCError = -8
    /// 无加入面试会议权限, -9
    static let interviewNoPermission: VCError = -9
    /// 面试已过期, -10
    static let interviewOutOfDate: VCError = -10
    /// 会中有不兼容的端, -11
    static let versionIncompatible: VCError = -11
    /// docs网址不支持打开, -12
    static let urlDirty: VCError = -12
    /// 用户取消操作, -13
    static let userCancelOperation: VCError = -13
    /// -14
    static let collaborationBlocked: VCError = -14
    /// -15
    static let collaborationBeBlocked: VCError = -15
    /// -16
    static let collaborationNoRights: VCError = -16
    /// -17
    static let reservationOutOfDate: VCError = -17
    /// -18
    static let isMinutesRecording: VCError = -18
    /// 本地投屏，不能向当前所在会议发起投屏请求, -19
    static let localShareToCurrentMeeting: VCError = -19
    /// 本地投屏，用户取消投屏, -20
    static let localShareCancelled: VCError = -20
    /// 主持人（自身）忙碌, -21
    static let hostIsInRinging: VCError = -21
    /// 麦克风申请权限拒绝
    static let micDenied: VCError = -22
}

extension VCError: CustomStringConvertible {

    var localizedDescription: String {
        description
    }

    var description: String {
        switch self {
        case .badNetwork, .badNetworkV2:
            return I18n.View_VM_ErrorTryAgain
        case .hostBusy, .hostIsInVC, .hostIsInVOIP, .hostIsInRinging:
            return I18n.View_G_CurrentlyInCall
        case .calleeBusy:
            return I18n.View_G_RecipientUnavailable
        case .calleeVersionLow:
            return I18n.View_G_RecipientNeedsUpdate
        case .hostVersionLow:
            return I18n.View_G_UpdateToUse
        case .bannedFromCreating:
            return I18n.View_M_CannotStartMeetings
        case .meetingHasFinished:
            return I18n.View_M_MeetingHasEnded
        case .meetingExpired, .reservationOutOfDate:
            return I18n.View_M_MeetingExpired
        case .participantsOverload:
            return I18n.View_M_CapacityReached
        case .serverInternalError:
            return I18n.View_G_ServerError
        case .executiveModeError:
            return I18n.View_G_ExecutiveModeCall
        case .actionRefused, .noRecord,
             .participantStatusNotExcepted, .participantRemoveError, .participantMuteStatusUpdateError,
             .shareScreenStartError, .shareScreenStopError, .shareScreenUnknownError, .noPermission, .transferHostError:
            return I18n.View_G_NoGroupTryLater_Toast
        case .meetingNumberInvalid:
            return I18n.View_M_InvalidMeetingId
        case .meetingLocked:
            return I18n.View_MV_MeetingLocked_Toast
        case .tenantInBlacklist:
            return I18n.View_G_BlacklistCallsMeetingsUnavailable
        case .otherDeviceVoIP:
            return I18n.View_G_CurrentlyInCall
        case .chatPostNoPermission:
            return I18n.View_M_CannotStartMeetings
        case .startSketchFailed:
            return I18n.View_VM_FailedToStartAnnotating
        case .fetchAllSketchDataFailed:
            return I18n.View_VM_UnableToShowAnnotations
        case .interviewNoPermission:
            return I18n.View_M_NoPermissionToJoinInterview
        case .interviewOutOfDate:
            return I18n.View_M_InterviewLinkExpired
        case .versionIncompatible:
            return I18n.View_N_UpdateAppTryAgain
        case .urlDirty:
            return I18n.View_VM_UnableToOpenLink
        case .noPermissionToJoinMeeting:
            return BundleI18n.ByteView.View_M_NoPermissionToJoinMeeting
        case .invalidShareCode, .shareFollowNotSupportCrossKaMeeting:
            return I18n.View_G_InvalidSharingCodeOrMeetingID
        case .roomShareCode:
            return I18n.View_G_UnableToShareScreenToThisRoom
        case .notComplyUserAgreement:
            return I18n.View_M_SensitiveMessage(Util.appName)
        case .magicShareBoxUnsupported:
            return I18n.View_MV_NoShareDoc
        case .shareScreenNoRooms:
            return I18n.View_G_NoRoomSharingNow
        case .shareScreenInWiredShare:
            return I18n.View_G_AlreadySharingViaHDMI
        case .pstnInviteNoPhoneNumber:
            return I18n.View_G_UnableCallUserType_Toast
        case .pstnInviteNoPhonePermission:
            return I18n.View_G_NumberControl_UnableCall
        case .noPermissionToInvite:
            return I18n.View_G_JoinPermissionUnableInvite_Toast
        case .noCastWhiteboard:
            return I18n.View_G_NoCastWhiteboard
        case .localShareNoPermission:
            return I18n.View_M_NoPermissionToShareMirroring
        default:
            /// displayMessage有时候是MsgInfo的json字符串，不可用来展示。
            return ""
        }
    }
}
