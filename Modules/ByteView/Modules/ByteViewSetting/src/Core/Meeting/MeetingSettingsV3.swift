//
//  MeetingSettingsV3.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/14.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

final class MeetingSettingsV3 {
    private let service: UserSettingManager
    private let logger: Logger

    init(_ setting: UserSettingManager, logger: Logger) {
        self.service = setting
        self.logger = logger
    }

    private func settings<T: Decodable>(for key: SettingsV3Key, defaultValue: T) -> T {
        service.settings(for: key, defaultValue: defaultValue, logger: logger)
    }

    lazy var activeSpeakerConfig: ActiveSpeakerConfig = settings(for: .vc_active_speaker_config_v2, defaultValue: .default)
    lazy var mutePromptConfig: MutePromptConfig = settings(for: .vc_mute_prompt_config, defaultValue: .default)
    lazy var messageRequestConfig: MessageRequestConfig = settings(for: .vc_retry_interval, defaultValue: .default)
    lazy var howlingConfig: HowlingConfig = settings(for: .vc_howling_warn, defaultValue: .default)
    lazy var countDownConfig: CountDownConfig = settings(for: .vc_countdown_config, defaultValue: .default)
    lazy var participantsConfig: ParticipantsConfig = settings(for: .vc_ios_participants_config, defaultValue: .default)
    lazy var suggestionConfig: SuggestionConfig = settings(for: .vc_suggestion_setting, defaultValue: .default)
    lazy var keyboardMuteConfig: KeyboardMuteConfig = settings(for: .vc_keyboard_mute, defaultValue: .default)
    lazy var miniwindowShareConfig: MiniwindowShareConfig = settings(for: .vc_miniwindow_share, defaultValue: .default)

    lazy var micVolumeConfig: MicVolumeConfig = {
        if let config = service.settings(for: .vc_mic_volume_levels, type: MicVolumeConfig.self) {
            if config.isValid {
                return config
            } else {
                Logger.setting.warn("MicVolumeConfig is invalid. The default configuration will be used instead.")
                return .default
            }
        } else {
            Logger.setting.info("get settings vc_mic_volume_levels failed, use defaultValue")
            return .default
        }
    }()

    lazy var animationConfig: AnimationConfig = settings(for: .vc_animation_config, defaultValue: .default)
    lazy var videoSortConfig: VideoSortConfig = settings(for: .vc_video_sort_config, defaultValue: .default)
    lazy var billingLinkConfig: BillingLinkConfig = settings(for: .vc_billing_link_config, defaultValue: .default)
    lazy var whiteboardConfig: WhiteboardConfig = settings(for: .vc_whiteboard_config, defaultValue: .default)

    ///  共享推流事件上报频率
    lazy var sendShareScreenPublishInfoConfig: SendShareScreenPublishInfoConfig = settings(for: .vc_send_share_screen_config, defaultValue: .default)
    lazy var featurePerformanceConfig: FeaturePerformanceConfig = settings(for: .vc_feature_performance_config, defaultValue: .default)
    lazy var larkDowngradeConfig: LarkDowngradeConfig = settings(for: .lark_ios_universal_downgrade_config, defaultValue: .default)
    lazy var virtualBackgroundImages: [VirtualBgImage] = settings(for: .vc_virtual_background_images, defaultValue: [])
    lazy var enterpriseLimitLinkConfig: EnterpriseLimitLinkConfig = settings(for: .vc_enterprise_control_link, defaultValue: .default)
    lazy var labPlatformApplinkConfig: LabPlatformApplinkConfig = settings(for: .vc_platform_config, defaultValue: .default)
    /// 共享音频配置
    lazy var shareAudioConfig: MeetingShareAudioConfig = settings(for: .vc_audioshare_config, defaultValue: .default)
    lazy var networkTipConfig: NetworkTipsConfig = settings(for: .vc_network_tips_config, defaultValue: .default)
    lazy var microphoneCameraToastConfig: MicrophoneCameraToastConfig = settings(for: .vc_show_mic_camera_mute_toast_config, defaultValue: .default)

    private lazy var _multiResolutionConfig: MultiResolutionConfig = settings(for: .vc_multi_resolution_config, defaultValue: .default)
    var multiResolutionConfig: MultiResolutionConfig {
        if let debugConfig = DebugSettings.multiResolutionConfig {
            return debugConfig
        } else {
            return _multiResolutionConfig
        }
    }

    /// 采集编码帧率联动
    lazy var encodeLinkageConfig: CameraEncodeLinkageConfig = settings(for: .camera_capture_encode_linkage_config, defaultValue: .default)
    lazy var renderConfig: RenderConfig = settings(for: .vc_ios_render_config, defaultValue: .default)
    lazy var clientDynamicLink: ClientDynamicLink = settings(for: .client_dynamic_link, defaultValue: .default)
    lazy var pstnInviteConfig: PSTNInviteConfig = settings(for: .vc_phone_call_config, defaultValue: .default)

    /// 音频模式设置
    lazy var voiceModeConfig: VoiceModeConfig = settings(for: .vc_voice_mode_config, defaultValue: .default)
    /// 带宽管控等级配置
    lazy var rtcBandwidthConfig: [String: Any]? = {
        if let dic = service.settings(for: .sdk_bandwidth_throttle_config)["vc_rtc_config"] as? [String: Any],
           let obj = dic["bw_threshold"] as? [String: Any] {
            return obj
        } else {
            Logger.setting.error("rtcBW is nil")
            return nil
        }
    }()

    lazy var networkBaselineConfig: [String: Any]? = service.settings(for: .vc_network_tips_config)["meeting_network_quality_strategy"] as? [String: Any]

    /// 自动隐藏状态栏相关配置
    lazy var autoHideToolbarConfig: AutoHideToolbarConfig = settings(for: .vc_auto_hide_toolbar_config, defaultValue: .default)
    /// 异常恢复策略
    lazy var clearRtcCacheVersion: String? = {
        let config = service.settings(for: .custom_exception_config)
        if let runtime = config["safe_mode_runtime"] as? [String: Any],
           let strategy = runtime["lk_safe_mode_strategy"] as? [String: Any],
           let version = strategy["vc"] as? String {
            return version
        }
        return nil
    }()

    lazy var perfSampleConfig: InMeetPerfSampleConfig = settings(for: .vc_in_meet_perf_sample_config, defaultValue: .default)
    lazy var hideNonVideoConfig: HideNonVideoConfig = settings(for: .vc_hide_non_video_config, defaultValue: .default)
    lazy var nfdScanConfig: String = settings(for: .nfd_scan_config, defaultValue: "")
    lazy var rtcAppConfig: RtcAppConfig = settings(for: .vc_rtc_app_config, defaultValue: .default)
    lazy var rtcBillingHeartbeatConfig: RtcBillingHeartbeatConfig = settings(for: .vc_rtc_billing_heartbeat_interval, defaultValue: .default)
    lazy var uploadShareStatusConfig: UploadShareStatusConfig = settings(for: .vc_upload_share_status, defaultValue: .default)
    lazy var landscapeButtonConfig: LandscapeButtonConfig = settings(for: .vc_landscape_button_config, defaultValue: .default)
    lazy var slaTimeoutConfig: SLATimeoutConfig = settings(for: .vc_sla_timeout_config, defaultValue: .default)

    lazy var myAIToolIdConfig: MyAIToolIdConfig = {
        let defaultIds: [String] = service.packageIsLark ? ["Meeting"] : []
        return settings(for: .vc_tool_config, defaultValue: MyAIToolIdConfig(meetingToolIds: defaultIds))
    }()

    lazy var canOrientationManually: Bool = {
        if #available(iOS 16.0, *) {
            let iosVersion = settings(for: .vc_landscape_button_config, defaultValue: LandscapeButtonConfig.default).iosVersion
            let currentVersion = UIDevice.current.systemVersion
            switch currentVersion.compare(iosVersion, options: .numeric) {
                //如果当前系统版本号>=下发的版本号，则显示转屏按钮
            case .orderedSame, .orderedDescending:
                return true
            case .orderedAscending:
                return false
            }
        } else {
            return true
        }
    }()

    lazy var mediaServiceToastConfig: MediaServiceToastConfig = settings(for: .vc_media_service_toast, defaultValue: .default)
    lazy var notesTemplateConfig: NotesTemplateConfig = settings(for: .notes_template_category_id_config, defaultValue: .default)
    lazy var notesAIConfig: NotesAIConfig = settings(for: .notes_ai_config, defaultValue: .default)
    lazy var vcMeetingNotesConfig: VCMeetingNotesConfig = settings(for: .vc_meeting_notes_config, defaultValue: .default)
    lazy var muteAudioConfig: MuteAudioConfig = settings(for: .vc_mute_audio_unit, defaultValue: .default)
    lazy var floatReactionConfig: FloatReactionConfig = settings(for: .vc_float_reaction_config, defaultValue: .default)

    // 妙享降级参数配置
    lazy var magicShareDowngradeConfig: MagicShareDowngradeConfig = settings(for: .vc_magic_share_config, defaultValue: .default)
}
