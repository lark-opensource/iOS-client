//
//  VideoChatSettings.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/11/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 视频会议的设置
/// - Videoconference_V1_VideoChatSettings
public struct VideoChatSettings: Equatable {
    public init(topic: String,
                isMicrophoneMuted: Bool,
                isCameraMuted: Bool,
                subType: MeetingSubType,
                maxParticipantNum: Int32,
                maxVideochatDuration: Int32,
                planType: PlanType,
                shouldEarlyJoin: Bool,
                isLocked: Bool,
                isMuteOnEntry: Bool,
                planTimeLimit: Int32,
                securitySetting: SecuritySetting,
                i18nDefaultTopic: I18nDefaultTopic?,
                lastSecuritySetting: SecuritySetting?,
                featureConfig: FeatureConfig?,
                allowPartiUnmute: Bool,
                sipSetting: SIPSetting?,
                isOwnerJoinedMeeting: Bool,
                onlyHostCanShare: Bool,
                manageCapabilities: ManageCapabilities,
                onlyHostCanReplaceShare: Bool,
                maxSoftRtcNormalMode: Int32,
                rtcProxy: RTCProxy?,
                isMeetingOpenInterpretation: Bool,
                meetingSupportLanguages: [InterpreterSetting.LanguageType],
                isBoxSharing: Bool,
                onlyPresenterCanAnnotate: Bool,
                countdownDuration: Int32?,
                isOpenBreakoutRoom: Bool,
                h323Setting: H323Setting?,
                isQuotaMeeting: Bool,
                isPartiChangeNameForbidden: Bool,
                isSupportNoHost: Bool,
                autoManageInfo: AutoManageInfo?,
                breakoutRoomSettings: BreakoutRoomSettings?,
                useImChat: Bool,
                bindChatId: String,
                panelistPermission: PanelistPermission,
                attendeePermission: AttendeePermission,
                webinarSettings: WebinarSettings?,
                isE2EeMeeting: Bool,
                notePermission: NotesPermission,
                intelligentMeetingSetting: IntelligentMeetingSetting
    ) {
        self.topic = topic
        self.isMicrophoneMuted = isMicrophoneMuted
        self.isCameraMuted = isCameraMuted
        self.subType = subType
        self.maxParticipantNum = maxParticipantNum
        self.maxVideochatDuration = maxVideochatDuration
        self.planType = planType
        self.shouldEarlyJoin = shouldEarlyJoin
        self.isLocked = isLocked
        self.isMuteOnEntry = isMuteOnEntry
        self.planTimeLimit = planTimeLimit
        self.securitySetting = securitySetting
        self.i18nDefaultTopic = i18nDefaultTopic
        self.lastSecuritySetting = lastSecuritySetting
        self.featureConfig = featureConfig
        self.allowPartiUnmute = allowPartiUnmute
        self.sipSetting = sipSetting
        self.isOwnerJoinedMeeting = isOwnerJoinedMeeting
        self.onlyHostCanShare = onlyHostCanShare
        self.manageCapabilities = manageCapabilities
        self.onlyHostCanReplaceShare = onlyHostCanReplaceShare
        self.maxSoftRtcNormalMode = maxSoftRtcNormalMode
        self.rtcProxy = rtcProxy
        self.isMeetingOpenInterpretation = isMeetingOpenInterpretation
        self.meetingSupportLanguages = meetingSupportLanguages
        self.isBoxSharing = isBoxSharing
        self.onlyPresenterCanAnnotate = onlyPresenterCanAnnotate
        self.countdownDuration = countdownDuration
        self.isOpenBreakoutRoom = isOpenBreakoutRoom
        self.h323Setting = h323Setting
        self.isQuotaMeeting = isQuotaMeeting
        self.isPartiChangeNameForbidden = isPartiChangeNameForbidden
        self.isSupportNoHost = isSupportNoHost
        self.autoManageInfo = autoManageInfo
        self.breakoutRoomSettings = breakoutRoomSettings
        self.useImChat = useImChat
        self.bindChatId = bindChatId
        self.panelistPermission = panelistPermission
        self.attendeePermission = attendeePermission
        self.webinarSettings = webinarSettings
        self.isE2EeMeeting = isE2EeMeeting
        self.notePermission = notePermission
        self.intelligentMeetingSetting = intelligentMeetingSetting
    }

    public init() {
        self.init(topic: "",
                  isMicrophoneMuted: false,
                  isCameraMuted: false,
                  subType: .default,
                  maxParticipantNum: 0,
                  maxVideochatDuration: 0,
                  planType: .planFree,
                  shouldEarlyJoin: false,
                  isLocked: false,
                  isMuteOnEntry: false,
                  planTimeLimit: 0,
                  securitySetting: .init(),
                  i18nDefaultTopic: nil,
                  lastSecuritySetting: nil,
                  featureConfig: nil,
                  allowPartiUnmute: false,
                  sipSetting: nil,
                  isOwnerJoinedMeeting: false,
                  onlyHostCanShare: false,
                  manageCapabilities: .init(),
                  onlyHostCanReplaceShare: false,
                  maxSoftRtcNormalMode: 0,
                  rtcProxy: nil,
                  isMeetingOpenInterpretation: false,
                  meetingSupportLanguages: [],
                  isBoxSharing: false,
                  onlyPresenterCanAnnotate: false,
                  countdownDuration: 0,
                  isOpenBreakoutRoom: false,
                  h323Setting: .init(h323AccessList: [],
                                     ercDomainList: [],
                                     isShowCrc: false),
                  isQuotaMeeting: false,
                  isPartiChangeNameForbidden: false,
                  isSupportNoHost: false,
                  autoManageInfo: nil, breakoutRoomSettings: nil,
                  useImChat: false,
                  bindChatId: "",
                  panelistPermission: .init(),
                  attendeePermission: .init(),
                  webinarSettings: nil,
                  isE2EeMeeting: false,
                  notePermission: .init(isOwnerOrganizer: false,
                                        createPermission: .unknown,
                                        editpermission: .unknown),
                  intelligentMeetingSetting: .init(generateMeetingSummaryInMinutes: .featureStatusUnknown,
                                                   generateMeetingSummaryInDocs: .featureStatusUnknown,
                                                   chatWithAiInMeeting: .featureStatusUnknown,
                                                   isAINotDependRecording: false,
                                                   permData: .init()))
    }

    /// 会议主题
    public var topic: String

    /// 会议默认麦克风开/关
    public var isMicrophoneMuted: Bool

    /// 会议默认摄像头开/关
    public var isCameraMuted: Bool

    /// 会议子类型
    public var subType: MeetingSubType

    /// 会议最大人数
    public var maxParticipantNum: Int32

    /// 会议最大时长，单位是分钟
    public var maxVideochatDuration: Int32

    /// 套餐类型
    public var planType: PlanType = .planFree

    /// 当前会话是否支持early join
    public var shouldEarlyJoin: Bool

    /// 会议是否被锁定
    public var isLocked: Bool

    /// 入会时是否静音
    public var isMuteOnEntry: Bool

    /// 套餐最大时长单位分钟
    public var planTimeLimit: Int32

    /// 入会范围设置
    public var securitySetting: SecuritySetting

    public var i18nDefaultTopic: I18nDefaultTopic?

    /// 上一次会议安全设置 （调用HostManage的时候，只有将SecurityLevel改为ONLY_HOST的时候，才会更新last_security_settings这个字段）
    public var lastSecuritySetting: SecuritySetting?

    public var featureConfig: FeatureConfig?

    public var allowPartiUnmute: Bool

    public var sipSetting: SIPSetting?

    /// 会议组织者是否加入过会议
    /// - 创建会议的时候1v1是false
    /// - 非1v1场景，只有会议（没有owner或者owner的user ID=0）并且 会议是面试会议的时候 为false
    /// - 1v1升级的时候 或者 面试会议owner存在了 就会变成true
    public var isOwnerJoinedMeeting: Bool

    public var onlyHostCanShare: Bool

    public var manageCapabilities: ManageCapabilities

    public var onlyHostCanReplaceShare: Bool

    public var maxSoftRtcNormalMode: Int32

    /// RTC代理设置
    public var rtcProxy: RTCProxy?

    public var isMeetingOpenInterpretation: Bool

    /// 当前会议支持的会议频道
    public var meetingSupportLanguages: [InterpreterSetting.LanguageType]

    /// 是否是盒子投屏会议
    public var isBoxSharing: Bool

    /// 只有共享人能标注
    public var onlyPresenterCanAnnotate: Bool

    /// 需要进行倒计时展示时填入，单位是分钟，倒计时在start_time+countdown_duration时归零
    public var countdownDuration: Int32?

    /// 是否开启了讨论组
    public var isOpenBreakoutRoom: Bool

    /// Videoconference_V1_VideoChatH323Setting, https://bytedance.feishu.cn/docs/doccnb8uI64b7gG6y0xoHUZ5Xze
    public var h323Setting: H323Setting?

    /// 是否使用证书开的会议，对于证书会议，主持人和联席主持人需要展示特殊标签
    public var isQuotaMeeting: Bool

    /// 是否允许会中改名
    public var isPartiChangeNameForbidden: Bool

    /// 会议支持无主持人状态
    public var isSupportNoHost: Bool

    /// 大方数会议自动管理状态 （5.27+废弃）
    public var autoManageInfo: AutoManageInfo?

    /// 分组会议设置
    public var breakoutRoomSettings: BreakoutRoomSettings?

    public var useImChat: Bool

    public var bindChatId: String

    /// 嘉宾权限集
    public var panelistPermission: PanelistPermission

    /// 观众权限
    public var attendeePermission: AttendeePermission

    /// 网络研讨会设置
    public var webinarSettings: WebinarSettings?

    /// 是否是端到端加密会议
    public var isE2EeMeeting: Bool

    /// 纪要权限
    public var notePermission: NotesPermission

    /// 智能纪要&AI权限
    public var intelligentMeetingSetting: IntelligentMeetingSetting

    public enum PlanType: Int, Hashable {
        case unknown // = 0
        case planFree // = 1
        case planBasic // = 2
        case planBusiness // = 3
        case planEnterprise // = 4

        /// 标准版E3(未认证)
        case planNewStandard // = 5

        /// 标准版E3(已认证)
        case planNewCertStandard // = 6

        /// 企业版E4
        case planNewBusiness // = 7

        /// 旗舰版E5
        case planNewEnterprise // = 8
    }

    /// 新增VCManageCapabilities，标示当前会中的能力, Videoconference_V1_VCManageCapabilities
    public struct ManageCapabilities: Equatable {

        /// 等候室
        public var vcLobby: Bool

        /// 强制静音
        public var forceMuteMicrophone: Bool

        /// 共享权限
        public var sharePermission: Bool

        /// 抢共享权限
        public var forceGetSharePermission: Bool

        /// 只有主持人共享人能标注
        public var onlyPresenterCanAnnotate: Bool

        public init(vcLobby: Bool, forceMuteMicrophone: Bool, sharePermission: Bool, forceGetSharePermission: Bool, onlyPresenterCanAnnotate: Bool) {
            self.vcLobby = vcLobby
            self.forceMuteMicrophone = forceMuteMicrophone
            self.sharePermission = sharePermission
            self.forceGetSharePermission = forceGetSharePermission
            self.onlyPresenterCanAnnotate = onlyPresenterCanAnnotate
        }

        public init() {
            self.init(vcLobby: false, forceMuteMicrophone: false, sharePermission: false, forceGetSharePermission: false,
                      onlyPresenterCanAnnotate: false)
        }
    }

    public struct SIPSetting: Equatable {

        public var domain: String
        public var ercDomainList: [String]
        public var isShowCrc: Bool

        public init(domain: String, ercDomainList: [String], isShowCrc: Bool) {
            self.domain = domain
            self.ercDomainList = ercDomainList
            self.isShowCrc = isShowCrc
        }
    }


    public struct SecuritySetting: Equatable {
        public init(securityLevel: SecurityLevel, groupIds: [String], userIds: [String], roomIds: [String],
                    isOpenLobby: Bool, specialGroupType: [SpecialGroupType]) {
            self.securityLevel = securityLevel
            self.groupIds = groupIds
            self.userIds = userIds
            self.roomIds = roomIds
            self.isOpenLobby = isOpenLobby
            self.specialGroupType = specialGroupType
        }

        public init() {
            self.init(securityLevel: .unknown, groupIds: [], userIds: [], roomIds: [], isOpenLobby: false, specialGroupType: [])
        }

        public var securityLevel: SecurityLevel

        /// CONTACTS_AND_GROUP时需要关心
        public var groupIds: [String]

        /// CONTACTS_AND_GROUP时需要关心
        public var userIds: [String]

        /// CONTACTS_AND_GROUP时需要关心
        public var roomIds: [String]

        /// 是否开启会议等候室，默认关闭
        public var isOpenLobby: Bool

        public var specialGroupType: [SpecialGroupType]

        public enum SpecialGroupType: Int, Hashable {
            case unknown // = 0
            case calendarGuestList // = 1
        }

        public enum SecurityLevel: Int, Hashable, CaseIterable {
            case unknown // = 0
            case `public` // = 1
            case tenant // = 2
            case contactsAndGroup // = 3
            case onlyHost // = 4
        }

        public var isLocked: Bool {
            return securityLevel == .onlyHost
        }
    }

    public struct AutoManageInfo: Equatable {
        public enum Status: Int, Hashable, CaseIterable{
            case unknown // = 0
            /// 手动设置，符合预期
            case manualExpected // = 1
            /// 手动设置，不符合预期
            case manualUnexpected // = 2
            /// 自动设置，一定符合预期
            case automatic // = 3
        }

        public enum Item {
            case allowParticipantUnmute
            case onlyHostCanShare
            case onlyPresenterCanAnnotate
        }

        public var enabled: Bool
        public var items: [Item: Status]

        public static let `default` = AutoManageInfo(enabled: false, items: [:])
    }

    public struct BreakoutRoomSettings: Equatable {
        public var allowReturnToMainRoom: Bool
        public var autoFinishEnabled: Bool
        public var autoFinishTime: TimeInterval
        public var notifyHostBeforeFinish: Bool
        public var countdownEnabled: Bool
        public var countdownDuration: TimeInterval
    }

    /// Basic_V1_VideoChatI18nDefaultTopic
    public struct I18nDefaultTopic: Equatable, Codable {
        public var i18NKey: String
    }
}

public struct NotesPermission: Equatable {

    public enum PermissionLevel: Int {
        case unknown
        case all
        case onlyHost
    }

    public var isOwnerOrganizer: Bool
    public var createPermission: PermissionLevel
    public var editpermission: PermissionLevel
}

extension VideoChatSettings: CustomStringConvertible {

    public var description: String {
        String(
            indent: "VideoChatSettings",
            "stype=\(subType)",
            "mic=\(isMicrophoneMuted.toInt)",
            "cam=\(isCameraMuted.toInt)",
            "lock=\(isLocked.toInt)",
            "owner=\(isOwnerJoinedMeeting.toInt)",
            "break=\(isOpenBreakoutRoom.toInt)",
            "box=\(isBoxSharing.toInt)",
            "interpret=\(isMeetingOpenInterpretation.toInt)",
            "muteOnEntry=\(isMuteOnEntry.toInt)",
            "allowUnmute=\(allowPartiUnmute.toInt)",
            "ohcShare=\(onlyHostCanShare.toInt)",
            "ohcRepShare=\(onlyHostCanReplaceShare.toInt)",
            "pNum=\(maxParticipantNum)",
            "vDur=\(maxVideochatDuration)",
            "cdDur=\(countdownDuration)",
            "plan=\(planType)(\(planTimeLimit))",
            "early=\(shouldEarlyJoin.toInt)",
            "quota=\(isQuotaMeeting.toInt)",
            "security=\(securitySetting)",
            "lastSecurity=\(lastSecuritySetting)",
            "\(featureConfig)",
            "\(manageCapabilities)",
            "langs=\(meetingSupportLanguages)",
            "isSupportNoHost=\(isSupportNoHost)",
            "panelistPermission=\(panelistPermission)",
            "attendeePermission=\(attendeePermission)",
            "webinarSettings=\(webinarSettings)",
            "maxSoftRtcNormalMode=\(maxSoftRtcNormalMode)",
            "isE2EeMeeting=\(isE2EeMeeting)",
            "notes=\(notePermission)"
        )
    }
}

extension VideoChatSettings.ManageCapabilities: CustomStringConvertible {
    public var description: String {
        String(
            indent: "Capabilities",
            "lobby=\(vcLobby.toInt)",
            "forceMute=\(forceMuteMicrophone.toInt)",
            "share=\(sharePermission.toInt)",
            "getShare=\(forceGetSharePermission.toInt)",
            "opcAnn=\(onlyPresenterCanAnnotate.toInt)"
        )
    }
}

extension VideoChatSettings.SecuritySetting: CustomStringConvertible {
    public var description: String {
        String(indent: "Security",
               "level=\(securityLevel)",
               "lobby=\(isOpenLobby.toInt)",
               "user=\(userIds)",
               "group=\(groupIds)",
               "room=\(roomIds)",
               "special=\(specialGroupType)"
        )
    }
}

extension VideoChatSettings.AutoManageInfo: CustomStringConvertible {
    public var description: String {
        let itemsString = self.items
            .map { k, v in "\(k) : \(v)"}
            .joined(separator: ", ")
        return String(
            indent: "AutoManageInfo",
            "enabled=\(enabled)",
            "items=[\(itemsString)]"
        )
    }
}

extension VideoChatSettings.PlanType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .planFree:
            return "planFree"
        case .planBasic:
            return "planBasic"
        case .planBusiness:
            return "planBusiness"
        case .planEnterprise:
            return "planEnterprise"
        case .planNewStandard:
            return "planNewStandard"
        case .planNewCertStandard:
            return "planNewCertStandard"
        case .planNewBusiness:
            return "planNewBusiness"
        case .planNewEnterprise:
            return "planNewEnterprise"
        }
    }
}
