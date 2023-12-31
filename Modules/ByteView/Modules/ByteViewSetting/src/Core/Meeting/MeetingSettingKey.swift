//
//  MeetingSettingKey.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/14.
//

import Foundation

public enum MeetingSettingKey: String, CaseIterable, CustomStringConvertible {
    /// 请求主持人帮助
    case showsAskHostForHelp
    /// 分组会议管控
    case showsBreakoutRoomHostControl
    /// 麦克风
    case showsMicrophone
    /// 摄像头
    case showsCamera
    /// 扬声器入口
    case showsSpeaker
    /// 参会人列表入口
    case showsParticipant
    /// 多端协同入口
    case showsJoinRoom
    /// 切换音频入口
    case showsSwitchAudio
    /// 切换音频横屏入口
    case showsSwitchAudioInLandscape
    /// 主持人操作面板
    case showsHostControl

    /// 特效
    case showsEffects
    case isVirtualBgEnabled
    case isAnimojiEnabled
    case isBackgroundBlur

    /// 传译入口
    case showsInterpret
    /// 传译入口isEnabled
    case isInterpretEnabled
    /// 管理传译
    case canEditInterpreter
    /// 同传是否开启
    case isMeetingOpenInterpretation

    /// 直播入口
    case showsLive
    /// 直播是否可用
    case isLiveEnabled
    /// 是否可发起直播/请求发起直播
    case canOperateLive

    /// 共享入口
    case showsShareContent
    /// 发起共享
    case canShareContent
    /// 抢共享
    case canReplaceShareContent
    /// 标注按钮是否展示
    case showsSketch

    /// 录制入口
    case showsRecord
    /// 是否可以录制
    case canStartRecord
    /// 允许申请录制
    case allowRequestRecord
    /// 转录入口
    case showsTranscribe
    /// 字幕入口
    case showsSubtitle
    /// 字幕入口isEnabled
    case isSubtitleEnabled
    /// 是否可以打开字幕
    case canOpenSubtitle

    /// 投票入口
    case showsVote
    case showsVoteInMain
    /// 投票入口isEnabled
    case isVoteEnabled
    /// 是否可以投票
    case canVote

    /// 邀请
    case canInvite
    /// 取消邀请
    case canCancelInvite
    /// 锁定时邀请
    case canInviteWhenLocked

    /// 电话邀请入口
    case showsPstn
    /// 用户是否可以电话邀请人，若为false则显示引导页面
    case canInvitePstn
    /// SIP入口
    case showsSip

    /// 状态表情入口
    case showsStatusReaction

    /// 倒计时入口
    case showsCountdown
    case isCountdownEnabled

    // MARK: - feature

    /// 影响`canBecomeHost(participant:)`和`hasOwnerAuthority`
    case isHostEnabled
    /// 是否可以操作等候室参会人（准入、拒绝）
    case canOperateLobbyParticipant

    /// 允许发送消息
    case allowSendMessage
    /// 允许发送表情
    case allowSendReaction

    case hasHostAuthority

    case hasCohostAuthority

    case isCallMeEnabled

    case isHostControlEnabled

    /// 讨论组内用户是否可以返回主会场
    /// 以下情况允许返回：
    /// 1. 当前用户为主持人或联席主持人
    /// 2. 当前用户非主持人或联席主持人，主持人设置了允许讨论组成员自行返回主会场
    case canReturnToMainRoom

    // MARK: - user settings

    case isVideoMirrored
    case isMicSpeakerDisabled
    case displayFPS
    case displayCodec
    case isHDModeEnabled
    case isPiPEnabled

    case useCellularImproveAudioQuality
    case autoHideToolStatusBar
    case isUltrawaveEnabled
    case needAdjustAnnotate

    case isEcoModeOn
    case isVoiceModeOn

    case isFrontCameraEnabled
    case isMicrophoneMuted
    case isCameraMuted
    case isCameraEffectOn

    case isSharingDocument
    /// my ai 是否可用
    case isMyAIEnabled

    case enableSelfAsActiveSpeaker

    public var description: String { rawValue }
}

public enum MeetingComplexSettingKey: String, CaseIterable, CustomStringConvertible {
    case countdownSetting
    case billingSetting
    case translateLanguageSetting
    case handsUpEmojiKey
    case subtitlePhraseStatus
    case cameraHandsStatus
    case micHandsStatus
    case virtualBackground
    case advancedBeauty

    public var description: String { rawValue }
}

extension MeetingSettingKey {
    /// waiting for _forEachFieldWithKeyPath or KeyPathIterable
    /// - https://github.com/apple/swift/blob/2cf7d63a5e0a47765d6ff1129a729fcf2bda29e1/stdlib/public/core/ReflectionMirror.swift#L314
    /// - https://www.tensorflow.org/swift/api_docs/Protocols/KeyPathIterable
    var keyPath: KeyPath<MeetingSettingManager, Bool> {
        switch self {
        case .showsAskHostForHelp:
            return \.showsAskHostForHelp
        case .showsBreakoutRoomHostControl:
            return \.showsBreakoutRoomHostControl
        case .showsMicrophone:
            return \.showsMicrophone
        case .showsCamera:
            return \.showsCamera
        case .showsSpeaker:
            return \.showsSpeaker
        case .showsParticipant:
            return \.showsParticipant
        case .showsJoinRoom:
            return \.showsJoinRoom
        case .showsSwitchAudio:
            return \.showsSwitchAudio
        case .showsSwitchAudioInLandscape:
            return \.showsSwitchAudioInLandscape
        case .showsHostControl:
            return \.showsHostControl
        case .showsEffects:
            return \.showsEffects
        case .isVirtualBgEnabled:
            return \.isVirtualBgEnabled
        case .isAnimojiEnabled:
            return \.isAnimojiEnabled
        case .isBackgroundBlur:
            return \.isBackgroundBlur
        case .showsInterpret:
            return \.showsInterpret
        case .isInterpretEnabled:
            return \.isInterpretEnabled
        case .canEditInterpreter:
            return \.canEditInterpreter
        case .isMeetingOpenInterpretation:
            return \.isMeetingOpenInterpretation
        case .showsLive:
            return \.showsLive
        case .isLiveEnabled:
            return \.isLiveEnabled
        case .canOperateLive:
            return \.canOperateLive
        case .showsShareContent:
            return \.showsShareContent
        case .canShareContent:
            return \.canShareContent
        case .canReplaceShareContent:
            return \.canReplaceShareContent
        case .showsSketch:
            return \.showsSketch
        case .showsRecord:
            return \.showsRecord
        case .canStartRecord:
            return \.canStartRecord
        case .allowRequestRecord:
            return \.allowRequestRecord
        case .showsTranscribe:
            return \.showsTranscribe
        case .showsSubtitle:
            return \.showsSubtitle
        case .isSubtitleEnabled:
            return \.isSubtitleEnabled
        case .canOpenSubtitle:
            return \.canOpenSubtitle
        case .showsVote:
            return \.showsVote
        case .isVoteEnabled:
            return \.isVoteEnabled
        case .canVote:
            return \.canVote
        case .showsVoteInMain:
            return \.showsVoteInMain
        case .canInvite:
            return \.canInvite
        case .canCancelInvite:
            return \.canCancelInvite
        case .canInviteWhenLocked:
            return \.canInviteWhenLocked
        case .showsPstn:
            return \.showsPstn
        case .canInvitePstn:
            return \.canInvitePstn
        case .showsSip:
            return \.showsSip
        case .showsStatusReaction:
            return \.showsStatusReaction
        case .showsCountdown:
            return \.showsCountdown
        case .isCountdownEnabled:
            return \.isCountdownEnabled
        case .isHostEnabled:
            return \.isHostEnabled
        case .canOperateLobbyParticipant:
            return \.canOperateLobbyParticipant
        case .allowSendMessage:
            return \.allowSendMessage
        case .allowSendReaction:
            return \.allowSendReaction
        case .hasHostAuthority:
            return \.hasHostAuthority
        case .hasCohostAuthority:
            return \.hasCohostAuthority
        case .isCallMeEnabled:
            return \.isCallMeEnabled
        case .isHostControlEnabled:
            return \.isHostControlEnabled
        case .canReturnToMainRoom:
            return \.canReturnToMainRoom
        case .isVideoMirrored:
            return \.isVideoMirrored
        case .isMicSpeakerDisabled:
            return \.isMicSpeakerDisabled
        case .displayFPS:
            return \.displayFPS
        case .displayCodec:
            return \.displayCodec
        case .isHDModeEnabled:
            return \.isHDModeEnabled
        case .isPiPEnabled:
            return \.isPiPEnabled
        case .useCellularImproveAudioQuality:
            return \.useCellularImproveAudioQuality
        case .autoHideToolStatusBar:
            return \.autoHideToolStatusBar
        case .isUltrawaveEnabled:
            return \.isUltrawaveEnabled
        case .needAdjustAnnotate:
            return \.needAdjustAnnotate
        case .isEcoModeOn:
            return \.isEcoModeOn
        case .isVoiceModeOn:
            return \.isVoiceModeOn
        case .isFrontCameraEnabled:
            return \.isFrontCameraEnabled
        case .isMicrophoneMuted:
            return \.isMicrophoneMuted
        case .isCameraMuted:
            return \.isCameraMuted
        case .isCameraEffectOn:
            return \.isCameraEffectOn
        case .isSharingDocument:
            return \.isSharingDocument
        case .isMyAIEnabled:
            return \.isMyAIEnabled
        case .enableSelfAsActiveSpeaker:
            return \.enableSelfAsActiveSpeaker
        }
    }
}
