//
//  RustPB+TransformedError.swift
//  ByteView
//
//  Created by 李凌峰 on 2019/9/20.
//

import Foundation
import ByteViewNetwork

extension JoinCalendarMeetingResponse.TypeEnum {

    var transformedVCError: VCError? {
        switch self {
        case .calendarSuccess,
             .calendarMeetingNeedExtension:
            return nil
        case .calendarVcBusy:
            return .hostIsInVC
        case .calendarVoipBusy:
            return .hostIsInVOIP
        case .calendarMeetingEnded:
            return .meetingHasFinished
        case .calendarMeetingOutOfDate:
            return .meetingExpired
        case .calendarParticipantLimitExceed:
            return .participantsOverload
        case .calendarVersionLow:
            return .hostVersionLow
        default:
            return .unknown
        }
    }
}

extension JoinMeetingResponse.TypeEnum {

    var transformedVCError: VCError? {
        switch self {
            // 3.26 会中加入/发起新会议vcBusy deviceRinging 状态表示成功
        case .success, .meetingNeedExtension, .deviceRinging, .vcBusy:
            return nil
        case .voipBusy:
            return .hostIsInVOIP
        case .participantLimitExceed:
            return .participantsOverload
        case .meetingEnded:
            return .meetingHasFinished
        case .meetingOutOfDate:
            return .meetingExpired
        case .versionLow:
            return .hostVersionLow
        case .meetingNumberInvalid:
            return .meetingNumberInvalid
        case .meetingNumberNotCertificated:
            return .uncertifiedMeeting
        case .meetingLocked:
            return .meetingLocked
        case .chatPostNoPermission:
            return .bannedFromCreating
        case .tenantInBlacklist:
            return .tenantInBlacklist
        case .versionIncompatible:
            return .versionIncompatible
        default:
            return .unknown
        }
    }
}

extension JoinMeetingPrecheckResponse.CheckType {

    var transformedVCError: VCError? {
        switch self {
            // 3.26 会中加入/发起新会议deviceInMeeting deviceRinging状态表示成功
        case .success, .deviceInMeeting, .deviceRinging:
            return nil
        case .meetingEnded:
            return .meetingHasFinished
        case .participantLimitExceed:
            return .participantsOverload
        case .meetingLocked:
            return .meetingLocked
        case .meetingNumberInvalid:
            return .meetingNumberInvalid
        case .voipBusy:
            return .otherDeviceVoIP
        case .versionLow:
            return .hostVersionLow
        case .chatPostNoPermission:
            return .chatPostNoPermission
        case .tenantInBlacklist:
            return .tenantInBlacklist
        case .calendarOutOfDate:
            return .meetingExpired
        case .interviewNoPermission:
            return .interviewNoPermission
        case .interviewOutOfDate:
            return .interviewOutOfDate
        case .collaborationBlocked:
            return .collaborationBlocked
        case .collaborationBeBlocked:
            return .collaborationBeBlocked
        case .collaborationNoRights:
            return .collaborationNoRights
        case .reservationOutOfDate:
            return .reservationOutOfDate
        default:
            return .unknown
        }
    }
}
