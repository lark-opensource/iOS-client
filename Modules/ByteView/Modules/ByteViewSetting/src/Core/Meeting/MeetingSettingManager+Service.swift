//
//  MeetingSettingManager+Service.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/14.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import LarkLocalizations

public extension MeetingSettingManager {
    var meetingSubType: MeetingSubType { videoChatSettings.subType }
    var meetingRole: Participant.MeetingRole? { myself?.meetingRole }

    var isCalendarMeeting: Bool { videoChatInfo.meetingSource == .vcFromCalendar }
    var isInterviewMeeting: Bool { videoChatInfo.meetingSource == .vcFromInterview }

    var isWebinarMeeting: Bool { videoChatSettings.subType == .webinar }
    var isWebinarAttendee: Bool { controlOptions.contains(.webinarAttendee) }

    // MARK: - 主持人权限相关

    /// 是否可使用主持人权限
    var hasHostAuthority: Bool { controlOptions.contains(.host) }
    /// 是否可使用联席主持人权限（主持人此项也为true）
    var hasCohostAuthority: Bool { controlOptions.contains(.cohost) }

    /// Meeting Owner 是否入会：1v1 或 (面试会议 且 Owner 未入会）时为false
    /// - 影响`canBecomeHost(participant:)`和`hasOwnerAuthority`
    var isHostEnabled: Bool { videoChatSettings.isOwnerJoinedMeeting }
    /// 是否可使用owner权限
    var hasOwnerAuthority: Bool { myself?.isMeetingOwner == true && isHostEnabled }

    /// 会议支持无主持人状态
    var isSupportNoHost: Bool { videoChatSettings.isSupportNoHost }
    var isHostControlEnabled: Bool { featureConfig.hostControlEnable }

    // MARK: - 分组会议相关
    var isInBreakoutRoom: Bool { controlOptions.contains(.breakoutRoom) }
    var isOpenBreakoutRoom: Bool { videoChatSettings.isOpenBreakoutRoom }
    var breakoutRoomId: String? { isInBreakoutRoom ? myself?.breakoutRoomId : nil }

    /// 分组会议管控入口
    var showsBreakoutRoomHostControl: Bool { videoChatSettings.isOpenBreakoutRoom && hasCohostAuthority }

    /// 讨论组内用户是否可以返回主会场
    ///
    /// 以下情况允许返回：
    /// 1. 当前用户为主持人或联席主持人
    /// 2. 当前用户非主持人或联席主持人，主持人设置了允许讨论组成员自行返回主会场
    var canReturnToMainRoom: Bool { hasCohostAuthority || (videoChatSettings.breakoutRoomSettings?.allowReturnToMainRoom ?? false) }

    // MARK: - toolbar入口

    /// 麦克风入口
    /// - 仅在 webinar 会议，自己是观众，且麦克风未开时，隐藏
    var showsMicrophone: Bool { !participantSettings.isMicrophoneMuted || !isWebinarAttendee }
    /// 摄像头入口
    var showsCamera: Bool { !isWebinarAttendee }
    /// 扬声器入口
    var showsSpeaker: Bool { participantSettings.audioMode == .internet }

    /// 请求主持人帮助
    var showsAskHostForHelp: Bool { isInBreakoutRoom && !hasCohostAuthority }
    /// 主持人操作面板
    var showsHostControl: Bool { meetingType == .meet && hasCohostAuthority }

    /// 多端协同FG
    var isJoinRoomTogetherEnabled: Bool { fg.isJoinRoomTogetherEnabled }
    /// 多端协同入口
    var showsJoinRoom: Bool { isJoinRoomTogetherEnabled && !isInterviewMeeting && !isWebinarMeeting && !isInBreakoutRoom && !isE2EeMeeting }
    /// 多端协同绑定的room
    var targetToJoinTogether: ByteviewUser? { participantSettings.targetToJoinTogether }

    /// 切换音频入口
    var showsSwitchAudio: Bool {
        if isWebinarAttendee { return false }
        // 端到端加密需要显示无音频
        return (Display.pad && participantSettings.targetToJoinTogether == nil) || isCallMeEnabled || isE2EeMeeting
    }
    /// 切换音频入口
    var showsSwitchAudioInLandscape: Bool { participantSettings.audioMode == .noConnect && isCallMeEnabled }

    /// 倒计时入口
    var showsCountdown: Bool { !isWebinarAttendee }
    var isCountdownEnabled: Bool { !isInBreakoutRoom }
    /// 倒计时设置
    var counddownSetting: CountdownSetting {
        CountdownSetting(isWebinarAttendee: isWebinarAttendee, hasCohostAuthority: hasCohostAuthority, permissionThreshold: videoChatConfig.inMeetingCountdownPermissionThreshold)
    }

    // MARK: - participant

    /// 参会人列表入口
    var showsParticipant: Bool { !isWebinarAttendee }
    /// 别名展示设置
    var isShowAnotherNameEnabled: Bool { fg.isShowAnotherNameEnabled }
    /// 是否展示关联标签
    var isRelationTagEnabled: Bool { fg.isRelationTagEnabled }

    // MARK: - lobby
    /// 是否可以操作等候室参会人（准入、拒绝）
    var canOperateLobbyParticipant: Bool { hasCohostAuthority }
    /// 是否可移动参会人到等候室
    var canMoveToLobby: Bool { !isWebinarMeeting && hasCohostAuthority && suiteQuota.waitingRoom && !isInBreakoutRoom }

    // MARK: - interpret

    /// 传译入口
    var showsInterpret: Bool {
        meetingType == .meet && (videoChatSettings.isMeetingOpenInterpretation || featureConfig.interpretationEnable) && !isInBreakoutRoom
    }
    /// 传译入口isEnabled
    var isInterpretEnabled: Bool { videoChatSettings.isMeetingOpenInterpretation || suiteQuota.interpretation }
    /// 管理传译
    var canEditInterpreter: Bool { hasCohostAuthority && featureConfig.interpretationEnable && suiteQuota.interpretation }
    /// 是否开启了传译
    var isMeetingOpenInterpretation: Bool { videoChatSettings.isMeetingOpenInterpretation }
    /// 当前会议支持的会议频道
    var meetingSupportLanguages: [InterpreterSetting.LanguageType] { videoChatSettings.meetingSupportLanguages }
    /// 会议可选择配置的传译语言
    var meetingSupportInterpretationLanguage: [InterpreterSetting.LanguageType] { videoChatConfig.meetingSupportInterpretationLanguage }

    // MARK: - live

    /// 直播入口
    /// - 1v1 任何人支持发起或结束直播, 会议中只有主持人并且在会中时才能发起或结束直播
    var showsLive: Bool { isLiveEnabled && (meetingType == .call || hasHostAuthority || videoChatSettings.isOwnerJoinedMeeting) }
    /// 直播是否可用
    var isLiveEnabled: Bool { featureConfig.liveEnable && fg.isLiveEnabled && !isInBreakoutRoom && !isWebinarAttendee }
    /// 是否可发起直播/请求发起直播
    /// - admin 配置关闭直播功能，fg打开的时候有企业直播功能，关闭的时候没有企业直播功能，默认关闭
    var canOperateLive: Bool { adminSettings.enableLive || fg.isEnterpriseLiveEnabled }
    /// fg打开的时候有企业直播功能，关闭的时候没有企业直播功能，默认关闭
    var isEnterpriseLiveEnabled: Bool { fg.isEnterpriseLiveEnabled }

    var isLiveLegalEnabled: Bool { !isFeishuBrand && fg.isLiveLegalEnabled }

    // MARK: - share content

    /// 共享入口
    var showsShareContent: Bool {
        if isWebinarAttendee { return false }
        return !Util.isiOSAppOnMacSystem || featureConfig.magicShare.startCcmEnable || featureConfig.whiteboardConfig.startWhiteboardEnable
    }
    /// 当前用户是否可以发起共享
    var canShareContent: Bool { hasCohostAuthority || !videoChatSettings.onlyHostCanShare }
    /// 抢共享
    var canReplaceShareContent: Bool { hasCohostAuthority || (!videoChatSettings.onlyHostCanShare && !videoChatSettings.onlyHostCanReplaceShare) }
    /// 标注按钮是否展示
    var showsSketch: Bool { !isWebinarAttendee }
    /// 发起ccm共享
    var isShareCcmEnabled: Bool { featureConfig.magicShare.startCcmEnable }
    /// 新建 ccm文档
    var isNewCcmEnabled: Bool { featureConfig.magicShare.newCcmEnable }
    /// 发起白板共享
    var isShareWhiteboardEnabled: Bool {
        return isWebinarMeeting ? featureConfig.whiteboardConfig.startWhiteboardEnable : !isInBreakoutRoom
    }
    /// 大方数会议谨慎共享提示人数阈值
    var largeMeetingShareNoticeThreshold: Int32 { videoChatConfig.largeMeetingShareNoticeThreshold }
    /// 是否在 MagicShare 页面开启自动隐藏工具栏
    var isMSHideToolbarEnabled: Bool { fg.isMSHideToolbarEnabled }

    var onlyHostCanShare: Bool { videoChatSettings.onlyHostCanShare }
    var onlyHostCanReplaceShare: Bool { videoChatSettings.onlyHostCanReplaceShare }
    /// 只有共享人能标注
    var onlyPresenterCanAnnotate: Bool { videoChatSettings.onlyPresenterCanAnnotate }

    var whiteboardConfig: WhiteboardConfig { settingsV3.whiteboardConfig }
    var floatReactionConfig: FloatReactionConfig { settingsV3.floatReactionConfig }

    var isSharingDocument: Bool { extraData.isSharingDocument }
    var isSharingScreen: Bool { extraData.isSharingScreen }
    var isSharingWhiteboard: Bool { extraData.isSharingWhiteboard }

    var isMagicShareNewDocsEnabled: Bool { fg.isMagicShareNewDocsEnabled }
    var isMagicShareNewBitableEnabled: Bool { fg.isMagicShareNewBitableEnabled }

    /// 在会中妙享场景是否使用唯一的WebView
    var isMagicShareWebViewReuseEnabled: Bool { fg.isMagicShareWebViewReuseEnabled }
    /// 会中妙享v7.9新增的降级策略开关
    var isMagicShareDowngradeEnabled: Bool { fg.isMagicShareDowngradeEnabled }

    /// MagicShare中DocX的灰度
    /// 灰度内，灰度范围内能发起 DocX 的共享和看共享
    /// 灰度外，支持在共享面板上搜索到 DocX 文档，但是不支持发起，同时隐藏新建 DocX 的入口
    var isMSDocXEnabled: Bool { fg.isMSDocXEnabled }
    /// MagicShare中新建DocX选项后是否显示beta标签
    var isMSCreateNewDocXBetaShow: Bool { fg.isMSCreateNewDocXBetaShow }
    /// 妙享中ccmDocX和ccmWikiDocX类型是否支持横屏
    var isMSDocXHorizontalEnabled: Bool { fg.isMSDocXHorizontalEnabled }
    /// 妙享中ccmMindnote和ccmWikiMindnote类型是否支持横屏
    var isMSMindnoteHorizontalEnabled: Bool { fg.isMSMindnoteHorizontalEnabled }
    /// MS回到上次位置优化（使用CCM的位置应用能力，VC控制位置的记录与应用）
    var isMSBackToLastLocationEnabled: Bool { fg.isMSBackToLastLocationEnabled }
    var isDecorateEnabled: Bool { fg.isDecorateEnabled }
    /// 妙享场景CPU上报（供CCM降级）
    var isMagicShareCpuUpdateEnabled: Bool { fg.isMagicShareCpuUpdateEnabled }
    /// 会议纪要开关
    var isMeetingNotesEnabled: Bool { fg.isMeetingNotesEnabled }
    /// My AI 总 FG
    var isMyAIAllEnabled: Bool { fg.isMyAIAllEnabled }
    /// Notes 文档增加 My AI 引导的 FG
    var isNotesMyAIGuideEnabled: Bool { fg.isNotesMyAIGuideEnabled }
    /// 投屏是否需要二次确认
    var shareScreenConfirm: GetAdminSettingsResponse.ShareScreenConfirm { adminSettings.shareScreenConfirm }
    /// 共享标注/白板保存开关
    var isWhiteboardSaveEnabled: Bool { fg.isWhiteboardSaveEnabled }
    // MARK: - record

    /// 录制入口
    var showsRecord: Bool {
        if isWebinarAttendee { return false }
        // 会议维度后台录制 FG 是否可用，当因为 admin 关闭录制时，虽然 recordEnable == false，但依然要显示录制按钮；
        // 其他原因导致的 recordEnable == false 一律隐藏
        guard fg.isMeetingRecordEnabled, featureConfig.recordEnable || featureConfig.recordCloseReason == .admin else { return false }
        // 支持会中无主持人状态时，联席主持人也可以开启录制
        if videoChatSettings.isSupportNoHost {
            return true
        } else if meetingType == .call {
            return true
        } else {
            return videoChatSettings.isOwnerJoinedMeeting
        }
    }

    /// 转录入口
    var showsTranscribe: Bool {
        if isWebinarAttendee { return false }
        if isInBreakoutRoom { return false }

        guard isTranscribeEnabled || featureConfig.recordCloseReason == .admin else { return false }
        // 支持会中无主持人状态时，联席主持人也可以开启录制
        if videoChatSettings.isSupportNoHost {
            return true
        } else if meetingType == .call {
            return true
        } else {
            return videoChatSettings.isOwnerJoinedMeeting
        }
    }

    /// 是否可以录制
    /// - 支持会中无主持人状态时，联席主持人也可以开启录制
    var canStartRecord: Bool { videoChatSettings.isSupportNoHost ? hasCohostAuthority : hasHostAuthority }
    /// 是否可以转录
    var canStartTranscribe: Bool { canStartRecord }

    /// 允许申请录制
    var allowRequestRecord: Bool { hasCohostAuthority || videoChatSettings.panelistPermission.allowRequestRecord }
    /// 允许申请转录
    var allowRequestTranscribe: Bool { allowRequestRecord }

    var isRecordEnabled: Bool { featureConfig.recordEnable }
    var isTranscribeEnabled: Bool {  featureConfig.transcriptConfig.transcriptEnable }
    var isLocalRecordEnabled: Bool { featureConfig.localRecordEnable }

    var recordCloseReason: FeatureConfig.RecordCloseReason { featureConfig.recordCloseReason }

    // MARK: - subtitle

    /// 字幕入口
    var showsSubtitle: Bool { fg.isSubtitleEnabled && !isE2EeMeeting }
    /// 字幕入口isEnabled
    var isSubtitleEnabled: Bool { suiteQuota.subtitle }
    /// 是否可以打开字幕
    var canOpenSubtitle: Bool { fg.isSubtitleEnabled && adminSettings.enableSubtitle && !isE2EeMeeting }
    /// 默认入会开启字幕
    var turnOnSubtitleWhenJoin: Bool { viewUserSetting.meetingAdvanced.subtitle.turnOnSubtitleWhenJoin }
    /// 付费套餐是否允许开启字幕
    var hasSubtitleQuota: Bool { suiteQuota.subtitle }
    /// 会议首位开启字幕的用户为其他参会人设置的默认口说语言列表
    var selectableSpokenLanguages: [PullVideoChatConfigResponse.SubtitleLanguage] { videoChatConfig.selectableSpokenLanguages }

    /// 开启后，字幕去掉“说话语言”的相关设置及弹窗
    var subtitleDeleteSpokenLanguage: Bool { fg.subtitleDeleteSpokenLanguage }
    var isSubtitleIconOut: Bool { fg.isSubtitleIconOut }
    /// FG开启 首位开启字幕有弹窗；FG关闭 首位开启字幕者无弹窗，所有参会人的说话语言不会被修改
    var isSpokenLanguageSettingsEnabled: Bool { fg.isSpokenLanguageSettingsEnabled }
    var isSubtitleTranslationEnabled: Bool { fg.isSubtitleTranslationEnabled }
    var isAudioRecordEnabledForSubtitle: Bool { fg.isAudioRecordEnabledForSubtitle }
    /// 参会者口说语言
    var spokenLanguage: String { participantSettings.spokenLanguage }
    /// 字幕显示语言
    var subtitleLanguage: String { participantSettings.subtitleLanguage }
    ///  转录语言
    var transcriptLanguage: String { participantSettings.transcriptLanguage }

    // MARK: - vote

    /// 投票入口
    var showsVote: Bool { canVote && (!isWebinarAttendee || extraData.hasVote) }
    var showsVoteInMain: Bool { showsVote && extraData.hasVote }
    /// 投票入口isEnabled
    var isVoteEnabled: Bool { featureConfig.voteConfig.quotaIsOn }
    /// 是否可以投票
    var canVote: Bool { meetingType == .meet && !isInterviewMeeting && !isInBreakoutRoom && featureConfig.voteConfig.allowVote }

    // MARK: - invite/pstn/sip/callme

    /// 邀请
    var canInvite: Bool { featureConfig.shareMeeting.inviteEnable }
    /// 取消邀请
    var canCancelInvite: Bool { hasCohostAuthority }
    /// 锁定时邀请
    var canInviteWhenLocked: Bool { hasCohostAuthority }

    /// 电话邀请入口
    var showsPstn: Bool {
        // 飞书品牌下如果FG未开，不展示入口
        if isFeishuBrand, !fg.isPhoneServiceEnable {
            return false
        }
        // 用户可以电话邀请人
        if canInvitePstn {
            return true
        }
        // 是否可以展示引导页
        if isFeishuBrand && featureConfig.pstn.outGoingCallEnable && !sponsorAdminSettings.pstnEnableOutgoingCall && !isInBreakoutRoom {
            return true
        }
        return false
    }
    /// 用户是否可以电话邀请人，若为false则显示引导页面
    var canInvitePstn: Bool {
        featureConfig.pstn.outGoingCallEnable && sponsorAdminSettings.pstnEnableOutgoingCall && sponsorAdminSettings.enablePSTNCalloutScopeAny && !isInBreakoutRoom
    }

    var pstnInviteConfig: PSTNInviteConfig { settingsV3.pstnInviteConfig }
    /// pstn呼入
    var isPstnIncomingEnabled: Bool { featureConfig.pstn.incomingCallEnable && sponsorAdminSettings.pstnEnableIncomingCall }
    /// 快捷电话邀请（一键邀请电话入会）
    var isPstnQuickCallEnabled: Bool {
        featureConfig.pstn.outGoingCallEnable && sponsorAdminSettings.pstnEnableOutgoingCall && fg.isPstnQuickCallEnable && !isInBreakoutRoom
    }
    /// 电话服务是否精细化管理
    var isRefinementManagement: Bool { fg.isRefinementManagement }
    /// pstn呼叫剩余
    var hasPstnQuota: Bool { suiteQuota.pstnCall }
    /// 是否有pstn精细化余额
    var hasPstnRefinedQuota: Bool { suiteQuota.pstnRefinedQuota }
    /// PSTN 呼入默认国家
    var pstnIncomingCallCountryDefault: [MobileCode] { pstnMobileCodes.pstnIncomingCallCountryDefault }
    /// PSTN 呼入号码列表
    var pstnIncomingCallPhoneList: [PSTNPhone] { pstnMobileCodes.pstnIncomingCallPhoneList }
    /// PSTN 呼出默认国家
    var pstnOutgoingCallCountryDefault: [MobileCode] { pstnMobileCodes.pstnOutgoingCallCountryDefault }
    /// PSTN 呼出国家列表
    var pstnOutgoingCallCountryList: [MobileCode] { pstnMobileCodes.pstnOutgoingCallCountryList }

    /// SIP入口
    var showsSip: Bool { featureConfig.sip.outGoingCallEnable && fg.isSipInviteEnabled && !isInBreakoutRoom }
    var isDialpadEnabled: Bool { fg.isDialpadEnabled }

    var isCallMeEnabled: Bool { fg.isCallMeEnabled && adminOrgSettings.allowUserChangePstnAudioType }
    var callmePhoneNumber: String { callmePhone?.displayPhoneNumber ?? "" }

    // MARK: - chat

    /// 是否使用新版聊天
    var isUseImChat: Bool {
        guard videoChatSettings.useImChat && !isInBreakoutRoom else { return false }
        return isCalendarMeeting ? fg.isCalUseImChatEnabled : fg.isUseImChatEnabled
    }
    var bindChatId: String { videoChatSettings.bindChatId }
    var isChatHistoryEnabled: Bool { featureConfig.chatHistoryEnabled }

    /// 允许发送消息
    var allowSendMessage: Bool {
        if isWebinarAttendee {
            return videoChatSettings.attendeePermission.allowSendMessage
        } else {
            return hasCohostAuthority || videoChatSettings.panelistPermission.allowSendMessage
        }
    }
    /// 允许发送表情
    var allowSendReaction: Bool {
        if isWebinarAttendee {
            return videoChatSettings.attendeePermission.allowSendReaction
        } else {
            return hasCohostAuthority || videoChatSettings.panelistPermission.allowSendReaction
        }
    }
    /// 状态表情入口
    var showsStatusReaction: Bool {  !isWebinarAttendee }
    /// 举手表情皮肤
    var handsUpEmojiKey: String { viewUserSetting.emojiSetting.handsUpEmojiKey }
    /// 翻译设置
    var translateLanguageSetting: TranslateLanguageSetting { service.translateLanguageSetting }
    ///  myAI入口
    var isMyAIEnabled: Bool { fg.isMyAIChatEnabled && featureConfig.myAIConfig.myAiEnable && !isE2EeMeeting && !isInBreakoutRoom && !isWebinarAttendee }
    /// “会中与AI对话”权限，v7.8新增
    var isChatWithAIOffOrInvalid: Bool { videoChatSettings.intelligentMeetingSetting.chatWithAiInMeeting.isOffOrInvalid }
    // 兼容老版本，默认值true表示会中AI依赖录制
    var isMyAIDependRecording: Bool { !videoChatSettings.intelligentMeetingSetting.isAINotDependRecording }

    var intelligentMeetingSetting: IntelligentMeetingSetting { videoChatSettings.intelligentMeetingSetting }

    /// 会中专属表情开关
    var isExclusiveReactionEnabled: Bool { fg.isExclusiveReactionEnabled }

    // MARK: - 3rdParty
    /// 分享会议链接
    var isCopyLinkEnabled: Bool { featureConfig.shareMeeting.copyMeetingLinkEnable }
    /// 分享会议卡片
    var isShareCardEnabled: Bool { featureConfig.shareMeeting.shareCardEnable }
    /// 创建群和进入群操作，当前主要是用来控制 日历想起中群按钮的显示
    var isEnterGroupEnabled: Bool { featureConfig.relationChain.enterGroupEnable }
    /// 查看user_profile
    var isBrowseUserProfileEnabled: Bool { featureConfig.relationChain.browseUserProfileEnable }

    // MARK: - 会中改名
    /// 是否允许会中改名自己
    var canRenameSelf: Bool { meetingType != .call && (hasCohostAuthority || !videoChatSettings.isPartiChangeNameForbidden) }
    /// 是否允许会中改名其他人
    var canRenameOther: Bool { meetingType != .call && hasCohostAuthority }

    // MARK: - 安全
    /// 是否已锁定
    var isMeetingLocked: Bool { videoChatSettings.securitySetting.isLocked }
    /// 入会时是否静音
    var isMuteOnEntry: Bool {  videoChatSettings.isMuteOnEntry }
    /// 是否允许参会人打开麦克风
    var allowPartiUnmute: Bool { videoChatSettings.allowPartiUnmute }

    // MARK: - audio & video
    var micCameraSetting: MicCameraSetting {
        get { service.micCameraSetting }
        set { service.micCameraSetting = newValue }
    }

    // 预览页替代入会功能是否可用
    var isReplaceJoinedDeviceEnabled: Bool { fg.isSwitchDeviceInMeetingEnabled }
    // 预览页替代入会开关设备维度存储
    var replaceJoinedDevice: Bool {
        get { service.replaceJoinedDevice }
        set { service.replaceJoinedDevice = newValue }
    }

    /// 表情气泡样式
    var reactionDisplayMode: ReactionDisplayMode {
        get {
            if service.floatReactionConfig.isEnabled {
                return service.reactionDisplayMode
            } else {
                return .bubble
            }
        }
        set { service.reactionDisplayMode = newValue }
    }

    /// 强制静音
    var forceMuteMicrophone: Bool { manageCapabilities.forceMuteMicrophone }

    var supportsKeyboardMute: Bool { fg.isKeyboardMuteEnabled && Display.pad && showsMicrophone }
    var isKeyboardMuteEnabled: Bool { fg.isKeyboardMuteEnabled && service.isKeyboardMuteEnabled }
    /// 音频模式
    var audioMode: ParticipantSettings.AudioMode { participantSettings.audioMode }
    /// 系统电话状态
    var isSystemPhoneCalling: Bool { extraData.isSystemPhoneCalling }
    /// 是否关闭麦克风
    var isMicrophoneMuted: Bool {
        isOnTheCall ? extraData.isInMeetMicrophoneMuted : participantSettings.isMicrophoneMutedOrUnavailable
    }
    /// 是否关闭摄像头（指主场景，不含特效选择页等次要场景）
    var isCameraMuted: Bool {
        isOnTheCall ? extraData.isInMeetCameraMuted : participantSettings.isCameraMutedOrUnavailable
    }
    var isFrontCameraEnabled: Bool { extraData.isFrontCameraEnabled }

    // MARK: - effect
    var isVirtualBgEnabled: Bool { adminSettings.enableMeetingBackground }
    var isAnimojiEnabled: Bool { fg.isAnimojiEnabled && adminSettings.enableVirtualAvatar }
    var isRetuschierenEnabled: Bool { fg.isRetuschierenEnabled }
    var isFilterEnabled: Bool { fg.isFilterEnabled }
    var showsEffects: Bool { !isWebinarAttendee && (isFilterEnabled || isRetuschierenEnabled || isVirtualBgEnabled || isAnimojiEnabled) }
    var isVirtualBgCoremlEnabled: Bool {  //  虚拟背景是否可以用coreml
        if #available(iOS 14.0, *), fg.isVirtualBgCoremlEnabled {
            // A12芯片以上
            if Display.phone {
                // nolint-next-line: magic number
                return DeviceUtil.modelNumber >= DeviceModelNumber(major: 11, minor: 2)
            } else if Display.pad {
                return DeviceUtil.modelNumber >= DeviceModelNumber(major: 8, minor: 1)
            }
        }
        return false
    }
    var isVirtualBgCvpixelbufferEnabled: Bool { fg.isVirtualBgCvpixelbufferEnabled && isVirtualBgCoremlEnabled }
    var virtualBackgroundImages: [VirtualBgImage] { settingsV3.virtualBackgroundImages }
    /// 只在会中并且开摄像头的时候有效
    var isCameraEffectOn: Bool {
        isOnTheCall ? extraData.isInMeetCameraEffectOn : false
    }
    var virtualBgSettingImages: [VirtualBgImage] { settingsV3.virtualBackgroundImages }
    var virtualBgAdminImages: [GetAdminSettingsResponse.MeetingBackground] { adminSettings.meetingBackgroundList }
    var labPlatformApplinkConfig: LabPlatformApplinkConfig { settingsV3.labPlatformApplinkConfig }
    var canPersonalInstall: Bool { adminSettings.canPersonalInstall }
    var enableCustomMeetingBackground: Bool { adminSettings.enableCustomMeetingBackground } //自定义虚拟背景
    // 特效记忆
    var isBackgroundBlur: Bool { viewDeviceSetting.video.backgroundBlur }
    var virtualBackground: String { viewDeviceSetting.video.virtualBackground }
    var advancedBeauty: String { viewDeviceSetting.video.advancedBeauty }

    // MARK: - rtc
    var rtcMode: ParticipantSettings.RtcMode { participantSettings.rtcMode }
    var cameraHandsStatus: ParticipantHandsStatus { participantSettings.cameraHandsStatus }
    var micHandsStatus: ParticipantHandsStatus { participantSettings.handsStatus }
    /// 是否在设置页面中显示高级调试功能
    var isAdvancedDebugOptionsEnabled: Bool { fg.isAdvancedDebugOptionsEnabled }
    var displayFPS: Bool { service.displayFPS }
    var displayCodec: Bool { service.displayCodec }
    var isHDModeEnabled: Bool { fg.isHDModeEnabled && multiResolutionConfig.isHighEndDevice && service.isHDModeEnabled }
    /// 弱网提示
    var isWeakNetworkEnabled: Bool { fg.isWeakNetworkEnabled && networkTipConfig.isABTestEnabled(deviceId: deviceId) }
    /// 远端ICE提示根据Network unknown进行判断
    var isRemoteNetworkUnknown: Bool { fg.isRemoteNetworkUnknown }
    /// 是否接入主端提供的个人状态控件
    var isNewStatusEnabled: Bool { fg.isNewStatusEnabled }
    /// 是否开启RTC证书注入
    var isRtcSslEnabled: Bool { fg.isRtcSslEnabled }
    /// 是否限制RTC带宽
    var isLimitRTCBandwidth: Bool { fg.isLimitRTCBandwidth }
    /// 是否开启带宽管控
    var isNetTrafficControlEnabled: Bool { fg.isNetTrafficControlEnabled }
    var maxSoftRtcNormalMode: Int32 { videoChatSettings.maxSoftRtcNormalMode }
    /// 音频模式
    var isVoiceModeOn: Bool { extraData.dataMode == .voiceMode }
    /// 是否支持节能模式
    var isEcoModeEnabled: Bool { fg.isEcoModeEnabled }
    var isNewPrefAdjustEnbaled: Bool { fg.isEcoModeEnabled }
    /// 是否支持温度降级
    var isThermalAdjustEnabled: Bool { fg.isEcoModeEnabled && fg.isThermalDegradeEnabled }
    /// 是否开启RTC证书注入
    /// 节能模式是否开启
    var isEcoModeOn: Bool { extraData.dataMode == .ecoMode }
    /// 数据模式
    var dataMode: DataMode { extraData.dataMode }
    /// 音频模式设置
    var voiceModeConfig: VoiceModeConfig { settingsV3.voiceModeConfig }
    /// 带宽管控等级配置
    var rtcBandwidthConfig: [String: Any]? { settingsV3.rtcBandwidthConfig }
    var networkBaselineConfig: [String: Any]? { settingsV3.networkBaselineConfig }
    var multiResolutionConfig: MultiResolutionConfig { settingsV3.multiResolutionConfig }
    var renderConfig: RenderConfig { settingsV3.renderConfig }
    var rtcAppConfig: RtcAppConfig { settingsV3.rtcAppConfig }
    var rtcBillingHeartbeatConfig: RtcBillingHeartbeatConfig { settingsV3.rtcBillingHeartbeatConfig }
    var networkTipConfig: NetworkTipsConfig { settingsV3.networkTipConfig }
    var featurePerformanceConfig: FeaturePerformanceConfig { settingsV3.featurePerformanceConfig }
    var larkDowngradeConfig: LarkDowngradeConfig { settingsV3.larkDowngradeConfig }

    var isVideoMirrored: Bool { viewDeviceSetting.video.mirror }
    var useCellularImproveAudioQuality: Bool { service.useCellularImproveAudioQuality }

    /// 是否展示清晰度标签
    var canShowRtcDefinition: Bool { fg.canShowRtcDefinition }
    // 是否需要自动修正（默认需要）
    var needAdjustAnnotate: Bool { service.needAdjustAnnotate }

    // MARK: - 会议纪要
    var notesTemplateConfig: NotesTemplateConfig { settingsV3.notesTemplateConfig }
    /// AI补全纪要内容
    var notesAIConfig: NotesAIConfig { settingsV3.notesAIConfig }
    /// 纪要按钮请求头像数据
    var vcMeetingNotesConfig: VCMeetingNotesConfig { settingsV3.vcMeetingNotesConfig }
    /// 能否创建纪要
    var canCreateNotes: Bool { [.all, .unknown].contains(videoChatSettings.notePermission.createPermission) || (videoChatSettings.notePermission.createPermission == .onlyHost && (hasCohostAuthority || (hasOwnerAuthority && videoChatSettings.notePermission.isOwnerOrganizer))) }

    /// 直播协议
    var policyURL: PolicyURL {
        var vcPrivacyPolicyUrl = ""
        if !service.domain(for: .vcPrivacyPolicyUrl).isEmpty, let urlStr = service.domain(for: .vcPrivacyPolicyUrl).first {
            vcPrivacyPolicyUrl = urlStr
        }

        var vcTermsServiceUrl = ""
        if !service.domain(for: .vcTermsServiceUrl).isEmpty, let urlStr = service.domain(for: .vcTermsServiceUrl).first {
            vcTermsServiceUrl = urlStr
        }

        var vcLivePolicyUrl = ""
        if !service.domain(for: .vcLivePolicyUrl).isEmpty, let urlStr = service.domain(for: .vcLivePolicyUrl).first {
            vcLivePolicyUrl = urlStr
        }

        return PolicyURL(vcPrivacyPolicyUrl: vcPrivacyPolicyUrl,
                         vcTermsServiceUrl: vcTermsServiceUrl,
                         vcLivePolicyUrl: vcLivePolicyUrl)
    }

    var rtcSetting: RtcSetting {
        let dependency = service.rtcDependency
        // extra参数设置，初始化RTC时需要通过parameters参数传入

        let hostConfig = RtcSetting.RtcHostConfig(frontier: service.domain(for: .rtcFrontier),
                                                  decision: service.domain(for: .rtcDecision),
                                                  defaultIps: service.domain(for: .rtcDefaultips),
                                                  kaChannel: dependency.kaChannel)
        let dispatchConfig = RtcSetting.RtcDispatchConfig(feishuRtc: service.domain(for: .feishuRtc),
                                                    feishuPreRtc: service.domain(for: .feishuPreRtc),
                                                    feishuTestRtc: service.domain(for: .feishuTestRtc),
                                                    feishuTestPreRtc: service.domain(for: .feishuTestPreRtc),
                                                    feishuTestGaussRtc: service.domain(for: .feishuTestGaussRtc),
                                                    larkRtc: service.domain(for: .larkRtc),
                                                    larkPreRtc: service.domain(for: .larkPreRtc),
                                                    larkTestRtc: service.domain(for: .larkTestRtc),
                                                    larkTestPreRtc: service.domain(for: .larkTestPreRtc),
                                                    larkTestGaussRtc: service.domain(for: .larkTestGaussRtc))

        let isMediaOversea = !isFeishuBrand && !adminSettings.speedupNodes.contains("china")
        let isDataOversea = !service.account.isChinaMainlandGeo

        var extraDict: [String: Any] = [:]
        if let qualityStrategy = self.networkBaselineConfig {
            extraDict["meeting_network_quality_strategy"] = qualityStrategy
        }
        if let rtcBandwidthConfig = self.rtcBandwidthConfig {
            extraDict["bw_threshold"] = rtcBandwidthConfig
        }
        extraDict["rtc.aid"] = dependency.appId
        extraDict["rtc.device_id"] = deviceId

        if hostConfig.kaChannel != "saas",
           let defaultIp = hostConfig.defaultIps.first{
            // log sdk 上传地址
            extraDict["rtc.log_sdk_websocket_url"] = "wss://" + defaultIp + "/report"
        }
        // kaChannel 为旧方案中 setHostName 传的参数中的 kaChannel
        extraDict["rtc.ka_configure"] = ["kaChannel": hostConfig.kaChannel]
        // 传kRoomProfileTypeMeeting（16）或者kRoomProfileTypeMeetingRoom（17），分别代表vc和rooms场景
        // nolint-next-line: magic number
        extraDict["rtc.channel_profile"] = 16
        // isMediaOversea和isDataOversea 分别为旧方案中setDefaultVendorType 传入的对应参数
        extraDict["rtc.is_oversea"] = ["isMediaOversea": isMediaOversea,
                                       "isDataOversea": isDataOversea]

//        TODO: @zhangji: RTC注入证书，后续PM评估是否需要
//        extraDict["byteview.callmeeting.client.rtc.enable_ssl_pinning"] = fg.isRtcSslEnabled
//        if fg.isRtcSslEnabled {
//            extraDict["rtc.ca_root_cert"] = dependency.serverCertificate
//        }


        return RtcSetting(rtcAppId: videoChatInfo.rtcInfo?.rtcAppId ?? rtcAppConfig.rtcAppid,
                          appGroupId: appGroupId,
                          isMediaOversea: isMediaOversea,
                          isDataOversea: isDataOversea,
                          isHDModeEnabled: isHDModeEnabled,
                          isVirtualBgCoremlEnabled: isVirtualBgCoremlEnabled,
                          isVirtualBgCvpixelbufferEnabled: isVirtualBgCvpixelbufferEnabled,
                          hostConfig: hostConfig,
                          dispatchConfig: dispatchConfig,
                          multiResolutionConfig: multiResolutionConfig,
                          renderConfig: settingsV3.renderConfig,
                          activeSpeakerConfig: activeSpeakerConfig,
                          mutePromptConfig: settingsV3.mutePromptConfig,
                          perfSampleConfig: settingsV3.perfSampleConfig,
                          extra: extraDict,
                          bandwidth: isLimitRTCBandwidth ? adminSettings.bandwidth : nil,
                          fgConfig: rtcFeatureGating?.fgJsonString,
                          adminMediaServerSettings: adminMediaServerSettings?.enablePrivateMedia,
                          clearRtcCacheVersion: settingsV3.clearRtcCacheVersion,
                          encodeLinkageConfig: fg.isEncodeLinkageEnabled && settingsV3.encodeLinkageConfig.fpsLinkageEnable ? settingsV3.encodeLinkageConfig : nil,
                          logPath: service.logPath)
    }

    // MARK: - 超声波
    var isUltrawaveEnabled: Bool { service.isUltrawaveEnabled }
    /// 若附近Room（超声波检测）已在会中，是否入会自动静音自己
    var isAutoMuteWhenRoomInMeetingEnabled: Bool { fg.isAutoMuteWhenRoomInMeetingEnabled }

    // MARK: - others

    /// 是否是盒子投屏会议
    var isBoxSharing: Bool { videoChatSettings.isBoxSharing }

    /// 私有化互通
    var isCrossWithKa: Bool { videoChatInfo.isCrossWithKa }

    /// 通知是否显示详情
    var shouldShowDetails: Bool { service.shouldShowDetails }
    /// 会中通话中是否暂停通知
    var shouldShowMessage: Bool { service.shouldShowMessage }

    var isSuperAdministrator: Bool { adminPermissionInfo.isSuperAdministrator }

    var packageIsLark: Bool { service.packageIsLark }
    var isFeishuBrand: Bool { service.isFeishuBrand }
    var appGroupId: String { service.appGroupId }
    var isCallKitEnabled: Bool {
        #if DEBUG || ALPHA
        if DebugSettings.isCallKitEnabled { return true }
        #endif
        return service.isCallKitEnabled
    }
    var broadcastExtensionId: String { service.broadcastExtensionId }
    var customRingtone: String { service.customRingtone }
    var shouldUpdateLark: Bool { service.shouldUpdateLark }
    var includesCallsInRecents: Bool { service.includesCallsInRecents }
    var callKitIconData: Data? { service.callKitIconData }

    var lastOnTheCallMeetingId: String? {
        get { service.lastOnTheCallMeetingId }
        set { service.lastOnTheCallMeetingId = newValue }
    }

    var userjoinAudioOutputSetting: JoinAudioOutputSettingType {
        service.userjoinAudioOutputSetting
    }

    func saveUserjoinAudioOutputSetting(_ output: Int) {
        service.saveUserjoinAudioOutputSetting(output)
    }

    func lastMeetAudioOutput() -> Int {
        service.lastMeetAudioOutput()
    }

    func saveLastMeetAudioOutput(_ output: Int) {
        service.saveLastMeetAudioOutput(output)
    }

    func lastCallAudioOutput(isVoiceCall: Bool) -> Int {
        service.lastCallAudioOutput(isVoiceCall: isVoiceCall)
    }

    func saveLastCallAudioOutput(_ output: Int, isVoiceCall: Bool) {
        service.saveLastCallAudioOutput(output, isVoiceCall: isVoiceCall)
    }

    /// Passport域名
    var passportDomain: String { service.domain(for: .passport).first ?? "" }

    var applinkDomain: String { service.domain(for: .mpApplink).first ?? "" }

    /// 端到端加密
    var isE2EeMeeting: Bool { videoChatSettings.isE2EeMeeting }

    /// 会议最大人数
    var maxParticipantNum: Int {
        let maxNumber = videoChatSettings.maxParticipantNum
        if maxNumber > 0 {
            return Int(maxNumber)
        } else {
            return Int(appConfig.videochatParticipantLimit)
        }
    }
    var maxAttendeeNum: Int {
        videoChatSettings.subType == .webinar ? Int(videoChatSettings.webinarSettings?.maxAttendeeNum ?? 0) : 0
    }
    /// 会议最大人数
    var maxParticipantNumForDisplay: Int {  Int(videoChatSettings.maxParticipantNum)  }

    /// 是否需要升级套餐
    func shouldUpgradePlan(_ plan: VideoChatSettings.PlanType) -> Bool {
        videoChatConfig.enableUpgradePlanNotice[Int32(plan.rawValue), default: false]
    }
    /// 套餐设置
    var billingSetting: BillingSetting {
        BillingSetting(meetingType: meetingType, countdownDuration: videoChatSettings.countdownDuration, maxVideochatDuration: videoChatSettings.maxVideochatDuration, planType: videoChatSettings.planType, planTimeLimit: videoChatSettings.planTimeLimit)
    }
    /// AI 品牌名称，用来填充文案中的 {aiName} 占位
    var aiBrandName: String {
        if let aiBrandName = service.aiBrandNameConfig?[LanguageManager.currentLanguage.rawValue] {
            return aiBrandName
        }
        if isFeishuBrand {
            return BundleI18n.ByteViewSetting.MyAI_Common_Faye_AiNameFallBack.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return BundleI18n.ByteViewSetting.MyAI_Common_MyAI_AiNameFallBack.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    var isMicSpeakerDisabled: Bool { service.isMicSpeakerDisabled }
    var isPiPEnabled: Bool {
        // Debug 强开
        if DebugSettings.isPiPEnabled { return true }
        // 用户开启
        return service.isPIPPreferred && PIPCapability.isMultiTaskingCameraAccessEnabled && fg.isPiPEnabled
    }
    var isPiPSampleBufferRenderEnabled: Bool {
        // Debug 强开
        if DebugSettings.isPiPSampleBufferRenderEnabled { return true }
        // FG 命中
        return fg.isPiPSampleBufferRenderEnabled
    }
    var autoHideToolStatusBar: Bool { service.autoHideToolStatusBar }

    /// 进出会议时播放声音提醒
    var playEnterExitChimes: Bool { viewUserSetting.meetingGeneral.playEnterExitChimes }

    /// 发言时 AS 是否显示自己
    var enableSelfAsActiveSpeaker: Bool { viewUserSetting.meetingGeneral.enableSelfAsActiveSpeaker }

    var miniWindowShareDisabled: Bool { fg.miniWindowShareDisabled }

    /// 当UI和RTC麦克风/摄像头状态不一致时是否自动mute
    var isAutoMuteWhenConflictEnabled: Bool { fg.isAutoMuteWhenConflictEnabled }
    var isOnewayRelationshipEnabled: Bool { fg.isOnewayRelationshipEnabled }

    var enterpriseLimitLinkConfig: EnterpriseLimitLinkConfig { settingsV3.enterpriseLimitLinkConfig }

    /// 会议是否开启“在纪要文档中生成智能会议纪要”
    var inMeetGenerateMeetingSummaryInDocs: Bool { videoChatSettings.intelligentMeetingSetting.generateMeetingSummaryInDocs.isOn }

    var topic: String {
        let topic = videoChatSettings.topic
        if topic.isEmpty {
            return I18n.View_G_ServerNoTitle
        }
        return isInterviewMeeting ? I18n.View_M_VideoInterviewNameBraces(topic) : topic
    }

    var isWebinarRehearsing: Bool {
        videoChatSettings.webinarSettings?.rehearsalStatus == .on
    }
}

public extension MeetingSettingManager {

    var activeSpeakerConfig: ActiveSpeakerConfig { settingsV3.activeSpeakerConfig }

    var messageRequestConfig: MessageRequestConfig { settingsV3.messageRequestConfig }

    var howlingConfig: HowlingConfig { settingsV3.howlingConfig }

    var countDownConfig: CountDownConfig { settingsV3.countDownConfig }

    var participantsConfig: ParticipantsConfig { settingsV3.participantsConfig }

    var suggestionConfig: SuggestionConfig { settingsV3.suggestionConfig }

    var keyboardMuteConfig: KeyboardMuteConfig { settingsV3.keyboardMuteConfig }

    var micVolumeConfig: MicVolumeConfig { settingsV3.micVolumeConfig }

    var animationConfig: AnimationConfig { settingsV3.animationConfig }

    var videoSortConfig: VideoSortConfig { settingsV3.videoSortConfig }

    var billingLinkConfig: BillingLinkConfig { settingsV3.billingLinkConfig }

    /// 是否能手动横竖屏（指的是否能手动调用系统的横竖屏的方法）
    var canOrientationManually: Bool { settingsV3.canOrientationManually }

    ///  共享推流事件上报频率
    var sendShareScreenPublishInfoConfig: SendShareScreenPublishInfoConfig { settingsV3.sendShareScreenPublishInfoConfig }

    /// 共享音频配置
    var shareAudioConfig: MeetingShareAudioConfig { settingsV3.shareAudioConfig }

    var microphoneCameraToastConfig: MicrophoneCameraToastConfig { settingsV3.microphoneCameraToastConfig }

    var clientDynamicLink: ClientDynamicLink { settingsV3.clientDynamicLink }

    /// 自动隐藏状态栏相关配置
    var autoHideToolbarConfig: AutoHideToolbarConfig { settingsV3.autoHideToolbarConfig }

    /// 会中性能埋点配置：线程 CPU 、各核心 CPU、电池
    var perfSampleConfig: InMeetPerfSampleConfig { settingsV3.perfSampleConfig }

    /// 隐藏非视频参会者优化需求配置
    var hideNonVideoConfig: HideNonVideoConfig { settingsV3.hideNonVideoConfig }

    var nfdScanConfig: String { settingsV3.nfdScanConfig }

    var uploadShareStatusConfig: UploadShareStatusConfig { settingsV3.uploadShareStatusConfig }

    var slaTimeoutConfig: SLATimeoutConfig { settingsV3.slaTimeoutConfig }

    var mediaServiceToastConfig: MediaServiceToastConfig { settingsV3.mediaServiceToastConfig }

    var myAIToolIdConfig: MyAIToolIdConfig { settingsV3.myAIToolIdConfig }
    var miniwindowShareConfig: MiniwindowShareConfig { settingsV3.miniwindowShareConfig }

    /// 主动入会不启用 callkit
    var isCallKitOutgoingDisable: Bool {
        #if DEBUG || ALPHA
        if DebugSettings.isCallKitOutgoingEnabled { return false }
        #endif
        return fg.isCallKitOutgoingDisable
    }

    var isExternalMeeting: Bool {
        if let isExternal = extraData.isExternalMeeting {
            return isExternal
        } else if let myself = self.myself, myself.status == .ringing {
            return videoChatInfo.isExternalMeetingWhenRing
        } else {
            return false
        }
    }

    var muteAudioConfig: MuteAudioConfig { settingsV3.muteAudioConfig }

    /// 妙享降级参数配置
    var magicShareDowngradeConfig: MagicShareDowngradeConfig { settingsV3.magicShareDowngradeConfig }
}

extension MeetingSettingChangeReason {
    var affectKeys: Set<MeetingSettingKey> {
        MeetingSettingChangeReason.keyCache[self, default: []]
    }

    var affectComplexKeys: Set<MeetingComplexSettingKey> {
        MeetingSettingChangeReason.complexCache[self, default: []]
    }

    private static let keyCache: [MeetingSettingChangeReason: Set<MeetingSettingKey>] = {
        var cache: [MeetingSettingChangeReason: Set<MeetingSettingKey>] = [:]
        MeetingSettingKey.allCases.forEach { key in
            key.dependencies.forEach { reason in
                var keys = cache[reason, default: []]
                keys.insert(key)
                cache[reason] = keys
            }
        }
        return cache
    }()

    private static let complexCache: [MeetingSettingChangeReason: Set<MeetingComplexSettingKey>] = {
        var cache: [MeetingSettingChangeReason: Set<MeetingComplexSettingKey>] = [:]
        MeetingComplexSettingKey.allCases.forEach { key in
            key.dependencies.forEach { reason in
                var keys = cache[reason, default: []]
                keys.insert(key)
                cache[reason] = keys
            }
        }
        return cache
    }()
}

private extension MeetingSettingKey {
    var dependencies: Set<MeetingSettingChangeReason> {
        switch self {
        case .showsAskHostForHelp:
            return [.breakoutRoom, .cohost]
        case .showsBreakoutRoomHostControl:
            return [.videoChatSettings, .cohost]
        case .showsMicrophone:
            return [.participantSettings, .webinarAttendee]
        case .showsCamera:
            return [.webinarAttendee]
        case .showsSpeaker:
            return [.participantSettings]
        case .showsParticipant:
            return [.webinarAttendee]
        case .showsJoinRoom:
            return [.videoChatSettings, .breakoutRoom]
        case .showsHostControl:
            return [.meetingType, .cohost]
        case .showsEffects:
            return [.webinarAttendee].union(.isAnimojiEnabled, .isVirtualBgEnabled)
        case .isVirtualBgEnabled:
            return [.adminSettings]
        case .isAnimojiEnabled:
            return [.adminSettings]
        case .showsInterpret:
            return [.meetingType, .videoChatSettings, .featureConfig, .breakoutRoom]
        case .isInterpretEnabled:
            return [.videoChatSettings, .suiteQuota]
        case .canEditInterpreter:
            return [.cohost, .featureConfig, .suiteQuota]
        case .isMeetingOpenInterpretation:
            return [.videoChatSettings]
        case .showsLive:
            return [.meetingType, .host, .videoChatSettings].union(.isLiveEnabled)
        case .isLiveEnabled:
            return [.featureConfig, .breakoutRoom, .webinarAttendee]
        case .canOperateLive:
            return [.adminSettings]
        case .showsShareContent:
            return [.webinarAttendee, .featureConfig]
        case .canShareContent:
            return [.cohost, .videoChatSettings]
        case .canReplaceShareContent:
            return [.cohost, .videoChatSettings]
        case .showsSketch:
            return [.webinarAttendee]
        case .showsRecord:
            return [.videoChatSettings, .featureConfig, .webinarAttendee, .breakoutRoom, .meetingType]
        case .canStartRecord:
            return [.videoChatSettings, .host, .cohost]
        case .allowRequestRecord:
            return [.cohost, .videoChatSettings]
        case .showsTranscribe:
            return [.videoChatSettings, .featureConfig, .webinarAttendee, .breakoutRoom, .meetingType]
        case .showsSubtitle:
            return [.breakoutRoom, .videoChatSettings]
        case .isSubtitleEnabled:
            return [.suiteQuota]
        case .canOpenSubtitle:
            return [.adminSettings, .videoChatSettings]
        case .showsVote, .showsVoteInMain:
            return [.webinarAttendee, .extraData].union(.canVote)
        case .isVoteEnabled:
            return [.featureConfig]
        case .canVote:
            return [.meetingType, .breakoutRoom, .featureConfig]
        case .canInvite:
            return [.featureConfig]
        case .canCancelInvite:
            return [.cohost]
        case .canInviteWhenLocked:
            return [.cohost]
        case .showsPstn:
            return [.featureConfig, .sponsorAdminSettings, .breakoutRoom].union(.canInvitePstn)
        case .canInvitePstn:
            return [.featureConfig, .sponsorAdminSettings, .breakoutRoom]
        case .showsSip:
            return [.featureConfig, .breakoutRoom]
        case .showsSwitchAudio:
            return [.webinarAttendee, .participantSettings].union(.isCallMeEnabled)
        case .showsSwitchAudioInLandscape:
            return [.participantSettings].union(.isCallMeEnabled)
        case .isCallMeEnabled:
            return [.adminOrgSettings]
        case .isHostEnabled:
            return [.videoChatSettings]
        case .canOperateLobbyParticipant:
            return [.cohost]
        case .allowSendMessage, .allowSendReaction:
            return [.cohost, .videoChatSettings, .webinarAttendee]
        case .showsStatusReaction:
            return [.webinarAttendee]
        case .showsCountdown:
            return [.webinarAttendee]
        case .isCountdownEnabled:
            return [.breakoutRoom]
        case .isVideoMirrored:
            return [.viewDeviceSetting]
        case .hasHostAuthority:
            return [.host]
        case .hasCohostAuthority:
            return [.cohost]
        case .isHostControlEnabled:
            return [.featureConfig]
        case .canReturnToMainRoom:
            return [.cohost, .videoChatSettings]
        case .isPiPEnabled:
            return [.debug]
        case .isEcoModeOn, .isVoiceModeOn, .isFrontCameraEnabled, .isCameraEffectOn, .isSharingDocument:
            return [.extraData]
        case .isCameraMuted, .isMicrophoneMuted:
            return [.extraData, .participantSettings]
        case .isMicSpeakerDisabled, .displayFPS, .displayCodec, .isHDModeEnabled, .useCellularImproveAudioQuality,
                .autoHideToolStatusBar, .isUltrawaveEnabled, .needAdjustAnnotate:
            return []
        case .isMyAIEnabled:
            return [.videoChatSettings, .featureConfig, .webinarAttendee, .breakoutRoom]
        case .isBackgroundBlur:
            return [.viewDeviceSetting]
        case .enableSelfAsActiveSpeaker:
            return [.viewUserSetting]
        }
    }
}

private extension Array where Element == MeetingSettingChangeReason {
    func union(_ keys: MeetingSettingKey...) -> Set<MeetingSettingChangeReason> {
        var set = Set(self)
        for key in keys {
            set.formUnion(key.dependencies)
        }
        return set
    }
}

private extension MeetingComplexSettingKey {
    var dependencies: Set<MeetingSettingChangeReason> {
        switch self {
        case .countdownSetting:
            return [.webinarAttendee, .cohost, .videoChatConfig]
        case .billingSetting:
            return [.meetingType, .videoChatSettings]
        case .handsUpEmojiKey:
            return [.viewUserSetting]
        case .cameraHandsStatus, .micHandsStatus:
            return [.participantSettings]
        case .translateLanguageSetting, .subtitlePhraseStatus:
            return []
        case .virtualBackground:
            return [.viewDeviceSetting]
        case .advancedBeauty:
            return [.viewDeviceSetting]
        }
    }
}
