//
//  MeetingSessionContext.swift
//  ByteView
//
//  Created by kiri on 2022/7/29.
//

import Foundation
import ByteViewMeeting
import ByteViewNetwork
import LarkMedia
import ByteViewSetting

extension MeetingSession {
    var autoShareScreen: Bool {
        get { attr(.autoShareScreen, false) }
        set { setAttr(newValue, for: .autoShareScreen) }
    }

    var isShareScreen: Bool {
        get { attr(.isShareScreen, false) }
        set { setAttr(newValue, for: .isShareScreen) }
    }

    var isFromPush: Bool {
        switch self.meetingEntry {
        case .voipPush, .push:
            return true
        default:
            return false
        }
    }

    var isCallKitFromVoIP: Bool {
        switch self.meetingEntry {
        case .voipPush:
            return true
        default:
            return false
        }
    }

    var canShowAudioToast: Bool {
        get { attr(.canShowAudioToast, true) }
        set { setAttr(newValue, for: .canShowAudioToast) }
    }

    var isInterprationGuideShowed: Bool {
        get { attr(.interprationGuide, false) }
        set { setAttr(newValue, for: .interprationGuide) }
    }

    var meetType: MeetingType {
        if let info = videoChatInfo {
            return info.type
        } else if startCallParams != nil || enterpriseCallParams != nil {
            return .call
        } else if lobbyInfo != nil {
            return .meet
        } else {
            return .unknown
        }
    }

    /// 当前会议是否被通话保持
    var isHeldByCallkit: Bool {
        get { attr(.isHeldByCallkit, false) }
        set { setAttr(newValue, for: .isHeldByCallkit) }
    }

    var localSetting: MicCameraSetting {
        get { attr(.localSetting, .none) }
        set { setAttr(newValue, for: .localSetting) }
    }

    var interviewQuestionnaireInfo: InterviewQuestionnaireInfo? {
        get { attr(.interviewQuestionnaireInfo, nil) }
        set { setAttr(newValue, for: .interviewQuestionnaireInfo) }
    }

    var account: ByteviewUser {
        if let account = service?.account {
            return account
        } else {
            return ByteviewUser(id: userId, type: .unknown)
        }
    }

    var larkRouter: LarkRouter? {
        service?.larkRouter
    }

    var httpClient: HttpClient {
        if let client = service?.httpClient {
            return client
        } else {
            return HttpClient(userId: userId)
        }
    }

    var push: MeetingPushCenter? {
        return service?.push
    }

    var setting: MeetingSettingManager? {
        return service?.setting
    }

    var precheckVendorType: VideoChatInfo.VendorType {
        get { attr(.precheckVendorType, .larkRtc) }
        set { setAttr(newValue, for: .precheckVendorType) }
    }

    var precheckRtcRuntimeParams: [String: Any]? {
        get { attr(.precheckRtcRuntimeParams, nil) }
        set { setAttr(newValue, for: .precheckRtcRuntimeParams) }
    }

    var imChatId: String {
        get { attr(.imChatId, "") }
        set { setAttr(newValue, for: .imChatId) }
    }

    var callInType: CallInType {
        if let info = videoChatInfo {
            return info.callInType(accountId: userId)
        } else {
            return .vc
        }
    }

    var slaTracker: SLATracks {
        if let tracker = attr(.slaTracker, type: SLATracks.self) {
            return tracker
        } else if let setting = service?.setting {
            let tracker = SLATracks(setting.slaTimeoutConfig)
            setAttr(tracker, for: .slaTracker)
            return tracker
        } else {
            return SLATracks(.default)
        }
    }

    var breakoutRoomId: String? {
        service?.setting.breakoutRoomId
    }

    // MARK: - 以下会议纪要数据存储在Session，避免进出等候室数据管理器析构导致数据错误

    /// 当前激活的议程ID
    /// 只在NotesDataManager里面使用
    var lastHintAgendaID: String? {
        get { attr(.lastHintAgendaID, nil) }
        set { setAttr(newValue, for: .lastHintAgendaID) }
    }

    /// 需要显示新议程提示
    /// 每次活跃议程ID变化时置为true，当最新议程被显示后，置为false，并记录最新议程ID
    var shouldShowNewAgendaHint: Bool {
        get { attr(.shouldShowNewAgendaHint, false) }
        set { setAttr(newValue, for: .shouldShowNewAgendaHint) }
    }

    /// 需要显示外部权限提示
    var shouldShowPermissionHint: Bool {
        get { attr(.shouldShowPermissionHint, false) }
        set { setAttr(newValue, for: .shouldShowPermissionHint) }
    }

    /// 外部权限提示内容
    var permissionHintContent: String? {
        get { attr(.permissionHintContent, nil) }
        set { setAttr(newValue, for: .permissionHintContent) }
    }

    var inMeetingKey: InMeetingKey? {
        get { attr(.inMeeingKey, type: InMeetingKey.self) }
        set { setAttr(newValue, for: .inMeeingKey) }
    }

    var isE2EeMeeting: Bool {
        get { attr(.isE2EeMeeting, false) }
        set { setAttr(newValue, for: .isE2EeMeeting) }
    }

    /// 需要显示彩色的 Notes 按钮
    var shouldShowColorfulNotesButton: Bool {
        get { attr(.shouldShowColorfulNotesButton, true) }
        set { setAttr(newValue, for: .shouldShowColorfulNotesButton) }
    }
}

private extension MeetingAttributeKey {
    static let autoShareScreen: MeetingAttributeKey = "vc.autoShareScreen"
    static let canShowAudioToast: MeetingAttributeKey = "vc.canShowAudioToast"
    static let isHeldByCallkit: MeetingAttributeKey = "vc.isHeldByCallkit"
    static let localSetting: MeetingAttributeKey = "vc.localSetting"
    static let interviewQuestionnaireInfo: MeetingAttributeKey = "vc.interviewQuestionnaireInfo"
    static let precheckVendorType: MeetingAttributeKey = "vc.precheckVendorType"
    static let precheckRtcRuntimeParams: MeetingAttributeKey = "vc.precheckRtcRuntimeParams"
    static let imChatId: MeetingAttributeKey = "vc.imChatId"
    static let slaTracker: MeetingAttributeKey = "vc.slaTracker"
    static let interprationGuide: MeetingAttributeKey = "vc.interprationGuide"
    static let lastHintAgendaID: MeetingAttributeKey = "vc.lastHintAgendaID"
    static let shouldShowNewAgendaHint: MeetingAttributeKey = "vc.shouldShowNewAgendaHint"
    static let shouldShowPermissionHint: MeetingAttributeKey = "vc.shouldShowPermissionHint"
    static let permissionHintContent: MeetingAttributeKey = "vc.permissionHintContent"
    static let inMeeingKey: MeetingAttributeKey = "vc.inMeetingKey"
    static let isE2EeMeeting: MeetingAttributeKey = "vc.isE2EeMeeting"
    static let shouldShowColorfulNotesButton: MeetingAttributeKey = "vc.shouldShowColorfulNotesButton"
    static let isShareScreen: MeetingAttributeKey = "vc.isShareScreen"
}
