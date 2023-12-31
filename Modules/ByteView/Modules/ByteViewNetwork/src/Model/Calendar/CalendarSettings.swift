//
//  CalendarSettings.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import ServerPB
import SwiftProtobuf

typealias PBCalendarSettingsIntelligentMeetingSetting = Videoconference_V1_CalendarIntelligentMeetingSetting
typealias PBCalendarSettingsFeatureStatus = Videoconference_V1_CalendarIntelligentMeetingSetting.FeatureStatus
typealias ServerPBCalendarSettingsIntelligentMeetingSetting = ServerPB_Videochat_calendar_CalendarIntelligentMeetingSetting
typealias ServerPBCalendarSettingsFeatureStatus = ServerPB_Videochat_calendar_CalendarIntelligentMeetingSetting.FeatureStatus

/// Videoconference_V1_CalendarVCSettings
public struct CalendarSettings: Codable {
    public init(vcSecuritySetting: SecuritySetting,
                canJoinMeetingBeforeOwnerJoined: Bool,
                muteMicrophoneWhenJoin: Bool,
                putNoPermissionUserInLobby: Bool,
                autoRecord: Bool,
                isPartiUnmuteForbidden: Bool,
                backupHostUids: [String],
                onlyHostCanShare: Bool,
                onlyPresenterCanAnnotate: Bool,
                isPartiChangeNameForbidden: Bool,
                isAudienceChangeNameForbidden: Bool,
                isAudienceImForbidden: Bool,
                isAudienceHandsUpForbidden: Bool,
                isAudienceReactionForbidden: Bool,
                interpretationSetting: InterpretationSetting,
                panelistPermission: PanelistPermission,
                rehearsalMode: Bool,
                intelligentMeetingSetting: CalendarSettingsIntelligentMeetingSetting) {
        self.vcSecuritySetting = vcSecuritySetting
        self.canJoinMeetingBeforeOwnerJoined = canJoinMeetingBeforeOwnerJoined
        self.muteMicrophoneWhenJoin = muteMicrophoneWhenJoin
        self.putNoPermissionUserInLobby = putNoPermissionUserInLobby
        self.autoRecord = autoRecord
        self.isPartiUnmuteForbidden = isPartiUnmuteForbidden
        self.backupHostUids = backupHostUids
        self.onlyHostCanShare = onlyHostCanShare
        self.onlyPresenterCanAnnotate = onlyPresenterCanAnnotate
        self.isPartiChangeNameForbidden = isPartiChangeNameForbidden
        self.isAudienceChangeNameForbidden = isAudienceChangeNameForbidden
        self.isAudienceImForbidden = isAudienceImForbidden
        self.isAudienceHandsUpForbidden = isAudienceHandsUpForbidden
        self.isAudienceReactionForbidden = isAudienceReactionForbidden
        self.interpretationSetting = interpretationSetting
        self.panelistPermission = panelistPermission
        self.rehearsalMode = rehearsalMode
        self.intelligentMeetingSetting = intelligentMeetingSetting
    }

    public var vcSecuritySetting: SecuritySetting

    public var canJoinMeetingBeforeOwnerJoined: Bool

    public var muteMicrophoneWhenJoin: Bool

    public var putNoPermissionUserInLobby: Bool

    public var autoRecord: Bool

    public var isPartiUnmuteForbidden: Bool

    public var backupHostUids: [String]

    public var onlyHostCanShare: Bool

    public var onlyPresenterCanAnnotate: Bool

    public var isPartiChangeNameForbidden: Bool

    public var isAudienceChangeNameForbidden: Bool

    public var isAudienceImForbidden: Bool

    public var isAudienceHandsUpForbidden: Bool

    public var isAudienceReactionForbidden: Bool

    public var interpretationSetting: InterpretationSetting

    public var panelistPermission: PanelistPermission

    public var rehearsalMode: Bool

    // 非pb字段
    public var isOrganizer: Bool = false

    public var speakerCanInviteOthers = false

    public var speakerCanSeeOtherSpeakers = true

    public var audienceCanInviteOthers = false

    public var audienceCanSeeOtherSpeakers = true

    public var intelligentMeetingSetting = CalendarSettingsIntelligentMeetingSetting()

    public enum SecuritySetting: Int, Hashable, Codable {
        case `public` // = 0
        case sameTenant // = 1
        case onlyCalendarGuest // = 2
    }
}

#if !DEBUG && !ALPHA
extension ServerPB_Videochat_calendar_CalendarVCSettings: SwiftProtobuf.MessageJSONLarkExt {}
#endif

extension CalendarSettings {
    public init() {
        self.init(vcSecuritySetting: .public,
                  canJoinMeetingBeforeOwnerJoined: false,
                  muteMicrophoneWhenJoin: false,
                  putNoPermissionUserInLobby: false,
                  autoRecord: false,
                  isPartiUnmuteForbidden: false,
                  backupHostUids: [],
                  onlyHostCanShare: false,
                  onlyPresenterCanAnnotate: false,
                  isPartiChangeNameForbidden: true,
                  isAudienceChangeNameForbidden: false,
                  isAudienceImForbidden: false,
                  isAudienceHandsUpForbidden: false,
                  isAudienceReactionForbidden: false,
                  interpretationSetting: InterpretationSetting(isOpenInterpretation: false,
                                                               interpreterSettings: []),
                  panelistPermission: PanelistPermission(allowSendMessage: true,
                                                         allowSendReaction: true,
                                                         allowRequestRecord: true,
                                                         allowVirtualAvatar: true,
                                                         allowVirtualBackground: true,
                                                         messageButtonStatus: .default),
                  rehearsalMode: false,
                  intelligentMeetingSetting: CalendarSettingsIntelligentMeetingSetting()
        )
    }
}

extension CalendarSettings: ProtobufEncodable, ProtobufDecodable {
    typealias ProtobufType = ServerPB_Videochat_calendar_CalendarVCSettings
    init(pb: ServerPB_Videochat_calendar_CalendarVCSettings) {
        self.vcSecuritySetting = .init(rawValue: pb.vcSecuritySetting.rawValue) ?? .public
        self.canJoinMeetingBeforeOwnerJoined = pb.canJoinMeetingBeforeOwnerJoined
        self.muteMicrophoneWhenJoin = pb.muteMicrophoneWhenJoin
        self.putNoPermissionUserInLobby = pb.putNoPermissionUserInLobby
        self.autoRecord = pb.autoRecord
        self.isPartiUnmuteForbidden = pb.isPartiUnmuteForbidden
        self.backupHostUids = pb.backupHostUids
        self.onlyHostCanShare = pb.onlyHostCanShare
        self.onlyPresenterCanAnnotate = pb.onlyPresenterCanAnnotate
        self.isPartiChangeNameForbidden = pb.isPartiChangeNameForbidden
        self.isAudienceChangeNameForbidden = pb.isAudienceChangeNameForbidden
        self.isAudienceImForbidden = pb.isAudienceImForbidden
        self.isAudienceHandsUpForbidden = pb.isAudienceHandsUpForbidden
        self.isAudienceReactionForbidden = pb.isAudienceReactionForbidden
        self.interpretationSetting = pb.interpretationSetting.vcType
        self.panelistPermission = pb.panelistPermission.vcType
        self.rehearsalMode = pb.rehearsalMode
        self.intelligentMeetingSetting = pb.intelligentMeetingSetting.vcType
    }

    func toProtobuf() -> ServerPB_Videochat_calendar_CalendarVCSettings {
        var settings = ServerPBCalendarVCSettings()
        settings.vcSecuritySetting = .init(rawValue: vcSecuritySetting.rawValue) ?? .public
        settings.autoRecord = autoRecord
        settings.canJoinMeetingBeforeOwnerJoined = canJoinMeetingBeforeOwnerJoined
        settings.putNoPermissionUserInLobby = putNoPermissionUserInLobby
        settings.muteMicrophoneWhenJoin = muteMicrophoneWhenJoin
        settings.isPartiUnmuteForbidden = isPartiUnmuteForbidden
        settings.backupHostUids = backupHostUids
        settings.onlyHostCanShare = onlyHostCanShare
        settings.onlyPresenterCanAnnotate = onlyPresenterCanAnnotate
        settings.isPartiChangeNameForbidden = isPartiChangeNameForbidden
        settings.isAudienceChangeNameForbidden = isAudienceChangeNameForbidden
        settings.isAudienceImForbidden = isAudienceImForbidden
        settings.isAudienceHandsUpForbidden = isAudienceHandsUpForbidden
        settings.isAudienceReactionForbidden = isAudienceReactionForbidden
        settings.interpretationSetting = interpretationSetting.serverPbType
        settings.panelistPermission = panelistPermission.serverPbType
        settings.rehearsalMode = rehearsalMode
        settings.intelligentMeetingSetting = intelligentMeetingSetting.serverPbType
        return settings
    }
}

extension CalendarSettings: CustomStringConvertible {
    public var description: String {
        String(indent: "CalendarSettings",
               "security=\(vcSecuritySetting)",
               "canJoinBeforeOwner=\(canJoinMeetingBeforeOwnerJoined.toInt)",
               "muteMic=\(muteMicrophoneWhenJoin.toInt)",
               "lobbyNoPerm=\(putNoPermissionUserInLobby.toInt)",
               "autoRec=\(autoRecord.toInt)",
               "isPartiUnmuteForbidden=\(isPartiUnmuteForbidden.toInt)",
               "backupHostUids=\(backupHostUids)",
               "onlyHostCanShare=\(onlyHostCanShare.toInt)",
               "onlyPresenterCanAnnotate=\(onlyPresenterCanAnnotate.toInt)",
               "isPartiChangeNameForbidden=\(isPartiChangeNameForbidden.toInt)",
               "isAudienceChangeNameForbidden=\(isAudienceChangeNameForbidden.toInt)",
               "isAudienceImForbidden=\(isAudienceImForbidden.toInt)",
               "isAudienceHandsUpForbidden=\(isAudienceHandsUpForbidden.toInt)",
               "isAudienceReactionForbidden=\(isAudienceReactionForbidden.toInt)",
               "interpretationSetting=\(interpretationSetting)",
               "isOrganizer=\(isOrganizer.toInt)",
               "speakerCanInviteOthers=\(speakerCanInviteOthers.toInt)",
               "speakerCanSeeOtherSpeakers=\(speakerCanSeeOtherSpeakers.toInt)",
               "audienceCanInviteOthers=\(audienceCanInviteOthers.toInt)",
               "audienceCanSeeOtherSpeakers=\(audienceCanSeeOtherSpeakers.toInt)",
               "panelistPermission=\(panelistPermission)",
               "rehearsalMode=\(rehearsalMode.toInt)",
               "intelligentMeetingSetting=\(intelligentMeetingSetting)"
        )
    }
}

// MARK: - 日程设置增加AI开关

public struct CalendarSettingsIntelligentMeetingSetting: Codable {
    /// 在妙记中生成智能会议纪要
    public var generateMeetingSummaryInMinutes: CalendarSettingsFeatureStatus = .unknown
    /// 在纪要文档中生成智能会议纪要
    public var generateMeetingSummaryInDocs: CalendarSettingsFeatureStatus = .unknown
    /// 在会议中使用 AI 对话
    public var chatWithAiInMeeting: CalendarSettingsFeatureStatus = .unknown

    public init() {}

    var serverPbType: ServerPBCalendarIntelligentMeetingSetting {
        var setting = ServerPBCalendarIntelligentMeetingSetting()
        setting.generateMeetingSummaryInMinutes = ServerPBCalendarFeatureStatus(rawValue: generateMeetingSummaryInMinutes.rawValue) ?? .unknown
        setting.generateMeetingSummaryInDocs = ServerPBCalendarFeatureStatus(rawValue: generateMeetingSummaryInDocs.rawValue) ?? .unknown
        setting.chatWithAiInMeeting = ServerPBCalendarFeatureStatus(rawValue: chatWithAiInMeeting.rawValue) ?? .unknown
        return setting
    }
}

public enum CalendarSettingsFeatureStatus: Int, Codable {
    /// 按照DISABLED状态处理，不展示开关
    case unknown = 0
    /// 用户不在服务端FG范围内，功能开关不展示
    case disabled // = 1
    /// 功能打开
    case on // = 2
    /// 功能关闭
    case off // = 3

    public var isOn: Bool {
        switch self {
        case .on: return true
        default: return false
        }
    }

    public var isOff: Bool {
        switch self {
        case .off: return true
        default: return false
        }
    }

    public var isValid: Bool {
        switch self {
        case .on, .off: return true
        default: return false
        }
    }
}

extension ServerPBCalendarSettingsIntelligentMeetingSetting {
    var vcType: CalendarSettingsIntelligentMeetingSetting {
        var setting = CalendarSettingsIntelligentMeetingSetting()
        setting.generateMeetingSummaryInMinutes = CalendarSettingsFeatureStatus(rawValue: generateMeetingSummaryInMinutes.rawValue) ?? .unknown
        setting.generateMeetingSummaryInDocs = CalendarSettingsFeatureStatus(rawValue: generateMeetingSummaryInDocs.rawValue) ?? .unknown
        setting.chatWithAiInMeeting = CalendarSettingsFeatureStatus(rawValue: chatWithAiInMeeting.rawValue) ?? .unknown
        return setting
    }
}
