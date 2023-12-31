//
//  Error+Calendar.swift
//  Calendar
//
//  Created by zhu chao on 2018/7/31.
//  Copyright © 2018年 EE. All rights reserved.
//

import Foundation
import LarkRustClient
import RustPB
import ServerPB

// 错误码治理: https://bytedance.feishu.cn/docx/doxcnsDbwGOTFGqCwqqDOiHUXlf#doxcnGIkCscwyUQC0EyxC7wyitb
extension Error {
    public func errorType() -> ErrorType {
        if let rcError = self as? RCError,
           case let .businessFailure(error) = rcError,
           let errorType = ErrorType(rawValue: error.errorCode) {
            return errorType
        }
        return .unknown
    }

    public func errorCode() -> Int32? {
        if let rcError = self as? RCError, case let .businessFailure(error) = rcError {
            // errorCode 是新版本的错误码，新版错误码 SDK 做了重定义。见 RustPB.Basic_V1_Auth_ErrorCode 枚举
            return error.errorCode
        }
        do {
            let text = self.localizedDescription
            let regex = try NSRegularExpression(pattern: "ErrorCode: \\d{3,10}")
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            let str = results.map { String(text[Range($0.range, in: text)!]) }.first
            guard let code = str?.components(separatedBy: " ").last else {
                return nil
            }
            return Int32(code)
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return nil
        }
    }

    public func info() -> String {
        if let rustError = self as? RCError {
            return rustError.description
        } else {
            return self.localizedDescription
        }
    }

    // 正常情况下一个错误码对应一个错误提示文案，这种情况下errorScene默认为.none
    // 在一个错误码在不同场景下有不同文案的需求时，会启用errorScene，即ErrorType和errorScene两个元素共同确定一个文案
    // 返回类型为optional是为了方便调用方实现自己的默认文案
    public func getTitle(errorScene: ErrorScene = .none) -> String? {
        guard let errorCode = self.errorCode(),
              let errorType = ErrorType(rawValue: errorCode) else {
            return nil
        }
        return ErrorI18n(errorType, errorScene).getTitle()
    }

    // 在提示弹窗除了显示标题还需要显示内容的时候，调用此方法
    public func getMessage(errorScene: ErrorScene = .none) -> String? {
        guard let errorCode = self.errorCode(),
              let errorType = ErrorType(rawValue: errorCode) else {
            return nil
        }

        return ErrorI18n(errorType, errorScene).getMessage()
    }

    // 在提示弹窗的确认button需要文案时，调用此方法
    public func getConfirmTitle(errorScene: ErrorScene = .none) -> String? {
        guard let errorCode = self.errorCode(),
              let errorType = ErrorType(rawValue: errorCode) else {
            return nil
        }
        return ErrorI18n(errorType, errorScene).getConfirmTitle()
    }

    /// 直接获取server返回的文案，通常已经根据环境语言翻译好
    public func getServerDisplayMessage() -> String? {
        if let rcError = self as? RCError, case let .businessFailure(error) = rcError {
            return error.displayMessage
        }
        return nil
    }
}

extension Error {
    public var isGroupMeetingLimitError: Bool {
        let codes: [CalendarFoundation.ErrorType] = [
            .meetingAttendeesCountExceedTenantLimitErr,
            .meetingAttendeesCountExceedCrossTenantLimitErr,
            .joinMeetingCountExceedTenantLimitErr,
            .joinMeetingCountExceedCrossTenantLimitErr
        ]
        return codes.map { $0.rawValue }.contains(errorCode())
    }
}

struct ErrorI18n: Hashable {
    private var errorType: ErrorType
    private var errorScene: ErrorScene

    init(_ errorType: ErrorType, _ errorScene: ErrorScene) {
        self.errorType = errorType
        self.errorScene = errorScene
    }

    func getTitle() -> String? {
        // 配置的时候需要区分业务错误码和系统错误码，对于系统错误码例如noNetworkError，需要配置所有scene
        let map: [ErrorI18n: String] = [
            ErrorI18n(.calendarIsNotPublicErr, .none): BundleI18n.Calendar.Calendar_Share_ExpiredAndJoinFailedTip, // 8001
            ErrorI18n(.calendarIsAlreadyUnsubscribedErr, .none): BundleI18n.Calendar.Calendar_Share_ExpiredAndJoinFailedTip, // 8002
            ErrorI18n(.calendarEventIsRemovedOrDeletedErr, .none): BundleI18n.Calendar.Calendar_Share_ExpiredAndJoinFailedTip, // 8003
            ErrorI18n(.calendarEventIsPrivacyErr, .none): BundleI18n.Calendar.Calendar_Share_ExpiredAndJoinFailedTip, // 8004
            ErrorI18n(.calendarEventIsExceedTheUpperLimitErr, .none): BundleI18n.Calendar.Calendar_Share_GuestLimitJoinTip, // 8005
            ErrorI18n(.calendarEventSourceIsGoogleErr, .none): BundleI18n.Calendar.Calendar_Share_ExpiredAndJoinFailedTip, // 8006
            ErrorI18n(.calendarEventIsNotFoundErr, .none): BundleI18n.Calendar.Calendar_Share_ExpiredAndJoinFailedTip, // 8007
            ErrorI18n(.attendeeNumberExceedsLimit, .none): BundleI18n.Calendar.Calendar_Alert_GroupNumLimitTitle, // 8008
            ErrorI18n(.userAlreadyDismissedErr, .none): BundleI18n.Calendar.Calendar_Detail_ReplyRSVPResigned, // 8016
            ErrorI18n(.versionNotSupportNeedUpgradeErr, .none): BundleI18n.Calendar.Calendar_Common_UpgradeTip, // 8019
            ErrorI18n(.unableSendRSVPCommentErr, .none): BundleI18n.Calendar.Calendar_Detail_ReplyRSVPNotFriend, // 8031
            ErrorI18n(.antiDirtRiskErr, .none): BundleI18n.Calendar.Calendar_Toast_CalendarSensitiveContent, // 8032
//            ErrorI18n(.eventDeletedError, .none): BundleI18n.Calendar.Calendar_Common_EventHasBeenDeleteTip, //10_000
            ErrorI18n(.offline, .none): BundleI18n.Calendar.Calendar_Detail_NoNetwork, // 10_008
            ErrorI18n(.offline, .eventSave): BundleI18n.Calendar.Calendar_Detail_NoNetwork, // 10_008
            ErrorI18n(.offline, .eventShare): BundleI18n.Calendar.Calendar_Detail_NoNetwork, // 10_008
            ErrorI18n(.offline, .meetingNotes): BundleI18n.Calendar.Calendar_Notes_ConnectErrorLater,
            ErrorI18n(.attendeeNumberExceedsLimit, .eventSave): BundleI18n.Calendar.Calendar_Edit_SaveLimit, // 10_011
            ErrorI18n(.attendeeNumberExceedsLimit, .eventShare): BundleI18n.Calendar.Calendar_Share_ShareLimit, // 10_011
            ErrorI18n(.userNotInMeetingChat, .none): BundleI18n.Calendar.Calendar_Alert_GroupNumLimitTitle, // 10_016,
            ErrorI18n(.resourceNotFoundErr, .none): BundleI18n.Calendar.Calendar_MeetingRoom_QRCodeExpired,
            ErrorI18n(.resourceIsDisabledErr, .none): BundleI18n.Calendar.Calendar_MeetingRoom_QRCodeExpired,
            ErrorI18n(.freqLimitReachedErr, .none): BundleI18n.Calendar.Calendar_MeetingRoom_QRCodeExpired,
            ErrorI18n(.differentenantsErr, .none): BundleI18n.Calendar.Calendar_MeetingRoom_NoPermissionToReserveMeetingRoom,
            ErrorI18n(.crossTenantAccessForbiddenErr, .none): BundleI18n.Calendar.Calendar_MeetingRoom_NoPermissionToReserveMeetingRoom,
            ErrorI18n(.disableEncryptEvent, .eventSave): BundleI18n.Calendar.Calendar_NoKeyNoSave_Toast,
            ErrorI18n(.eventEncryptErr, .none): BundleI18n.Calendar.Calendar_NoKeyNoOperate_Toast,
            ErrorI18n(.eventCreateEncryptErr, .none): BundleI18n.Calendar.Calendar_NoKeyNoOperate_Toast,
            ErrorI18n(.eventUpdateEncryptErr, .none): BundleI18n.Calendar.Calendar_NoKeyNoOperate_Toast,
            ErrorI18n(.eventDecryptErr, .none): BundleI18n.Calendar.Calendar_NoKeyNoOperate_Toast,
            ErrorI18n(.eventDecryptErr, .eventDetail): BundleI18n.Calendar.Calendar_NoKeyNoView_GreyText,
            ErrorI18n(.joinCurEventAttendeeNumberLimitErr, .none):
                BundleI18n.Calendar.Calendar_G_GuestFullContactToJoin,
            ErrorI18n(.joinCurEventAttendeeNumberLimitCrossTenantErr, .none):
                BundleI18n.Calendar.Calendar_G_GuestFullContactToJoin,
            ErrorI18n(.createNotesAddCollaboratorIllegality, .meetingNotes): BundleI18n.Calendar.Calendar_Edit_NoCreateNoteContact,
            ErrorI18n(.newEventNotSyncToServer, .none): BundleI18n.Calendar.Calendar_G_OopsWrongRetry
        ]
        // 找不到对应 scene 的特化文案，用 none scene 兜底
        return map[self] ?? map[ErrorI18n(self.errorType, .none)]
    }

    func getMessage() -> String? {
        let map: [ErrorI18n: String] = [
            ErrorI18n(.meetingAttendeesCountExceedTheUpperLimitErr, .none): BundleI18n.Calendar.Calendar_Alert_GroupNumLimitDes1, // 8008
            ErrorI18n(.userNotInMeetingChat, .none): BundleI18n.Calendar.Calendar_Alert_GroupNumLimitDes3// 10_016
        ]
        return map[self]
    }

    func getConfirmTitle() -> String? {
        let map: [ErrorI18n: String] = [
            ErrorI18n(.userNotInMeetingChat, .none): BundleI18n.Calendar.Calendar_Common_Confirm// 10_016
        ]
        return map[self]
    }

}

public enum ErrorScene {
    case none
    case eventSave
    case eventShare
    case eventDetail
    case meetingNotes
}

public enum ErrorType: Int32 {
    case unknown = -2_147_483_648
    // server Error https://codebase.byted.org/repo/ee/today/common/-/blob/calendar_errors/calendar_errors.go
    case calendarIsNotPublicErr = 8001
    case calendarIsAlreadyUnsubscribedErr = 8002
    case calendarEventIsRemovedOrDeletedErr = 8003
    case calendarEventIsPrivacyErr = 8004
    case calendarEventIsExceedTheUpperLimitErr = 8005
    case calendarEventSourceIsGoogleErr = 8006
    case calendarEventIsNotFoundErr = 8007
    case meetingAttendeesCountExceedTheUpperLimitErr = 8008
    case upgradeMeetingNoAuthorityErr = 8009
    case eventIsNotFoundErr = 8010
    case calendarEventRefIsNotFoundErr = 8011
    case calendarIsNotFoundError = 8012
    case eventStartTimeLessThanEndTimeErr = 8013
    case deleteCalendarNoAuthorityErr = 8014
    case calendarIdNotFoundErr = 8015
    case userAlreadyDismissedErr = 8016
    case forbiddenErr = 8017
    case userIsSubscribeSelfPrimaryCalendarErr = 8018
    case versionNotSupportNeedUpgradeErr = 8019
    case upgradeExternalMeetingErr = 8020
    case noLongerAllStuffCalendarErr = 8021
    case transferEventToOriginalOrganizerErr = 8022
    case otherTenantUserJoinMeetingEventErr = 8023
    case chatUserCountUpToTenantCountLimitErr = 8024
    case resourceSeizeClosedErr = 8025
    case resourceNotFoundErr = 8026
    case resourceIsDisabledErr = 8027
    case businessUnpaidErr = 8028
    case differentenantsErr = 8029
    case subscribeCalendarExceedTheUpperLimitErr = 8030
    case unableSendRSVPCommentErr = 8031
    case antiDirtRiskErr = 8032
    case checkShareEventRelatedPermissionErr = 8033
    case freqLimitReachedErr = 8034
    case paramInBlackListErr = 8035
    case calendarOwnerChange2NotOwnerErr = 8036
    case calendarGroupMemberOwnerErr = 8037
    case switchEventCalendarErr = 8038
    case getLockFailedErr = 8039
    case crossTenantAccessForbiddenErr = 8040
    case joinEventNoPermissionErr = 8041
    case createFollowEventNoPermissionErr = 8042
    case createExceptionEventNoPermissionErr = 8043
    case meetingAttendeesCountExceedTenantLimitErr = 8044
    case meetingAttendeesCountExceedCrossTenantLimitErr = 8045
    case joinMeetingCountExceedTenantLimitErr = 8046
    case joinMeetingCountExceedCrossTenantLimitErr = 8047
    case inValidApplinkEventErr = 8048
    case invalidRequestParamErr = 8049
    case calendarWriterReachLimitErr = 8050
    case calendarTypeNotSupportErr = 8051
    case calendarIsDeletedErr = 8052
    case calendarIsPrivateErr = 8053
    case joinEventRichAttendeeNumberLimitErr = 8055
    case eventEncryptErr = 8057
    case eventCreateEncryptErr = 8058
    case eventUpdateEncryptErr = 8059
    case eventDecryptErr = 8060
    case calendarEventCheckInApplinkNoPermission = 8061
    case calendarEventCheckInNotEnabled = 8062
    case joinCurEventAttendeeNumberLimitErr = 8071
    case joinCurEventAttendeeNumberLimitCrossTenantErr = 8072
    case instanceInfoErrorInMeetingNotesFG = 8080
    case getNotesInstanceNotFound = 8082
    case createNotesAddCollaboratorIllegality = 8088
    case calendarServerCustomizeErr = 8099 // 端上收到此错误码，显示服务端文案
    case calendarZoomAuthenticationFailed = 8201 // zoom账号认证失效，需要重新绑定
    case cachedMyAIEventInfoNotFoundErr = 8063 // 日程信息加载失败，请稍后重试
    case cachedMyAIEventInfoCreatedErr = 8064 // AI卡片日程已创建完成，请勿重复操作
    case createOrBindNotesAccessForbiddenErr = 8084 // 创建纪要,关联纪要鉴权未通过

    // sdk Error https://codebase.byted.org/repo/lark/rust-sdk/-/blob/wschannel/src/idl/client/basic/v1/errors.rs
    /// 网络错误
    case offline = 100_052 // 原 10_020
    case networkLibraryError = 100_053 // 原 10_021
    case timeout = 100_054 // 原 10_029
    /// SDK 业务错误
    case eventSharedInSyncing = 102_001 // 原 10_010
    case invalidCalendarEvent = 102_002 // 原 10_026
    case attendeeNumberExceedsLimit = 102_003 // 原 10_011
    case userNotInMeetingChat = 102_004 // 原 10_016
    case exceedMaxVisibleCalNum = 102_005
    case disableEncryptEvent = 102_011
    case newEventNotSyncToServer = 102_020
    /// 通用业务错误
    case forbidSendMessageInChat = 4042
    case invalidCipherFailedToSendMessage = 311_100
}
