//
//  SettingsV3Key.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/10/17.
//

import Foundation

public enum SettingsV3Key: String, CustomStringConvertible {
    case vc_feedback_issue_type_config
    case vc_active_speaker_config_v2
    case vc_mute_prompt_config
    case vc_retry_interval
    case vc_howling_warn
    case vc_countdown_config
    case vc_ios_participants_config
    case vc_suggestion_setting
    case vc_keyboard_mute
    case vc_mic_volume_levels
    case vc_animation_config
    case vc_video_sort_config
    case vc_billing_link_config
    case vc_whiteboard_config
    case vc_send_share_screen_config
    case vc_feature_performance_config
    case vc_virtual_background_images
    case vc_enterprise_control_link
    case vc_platform_config
    case vc_audioshare_config
    case vc_network_tips_config
    case vc_show_mic_camera_mute_toast_config
    case vc_multi_resolution_config
    case camera_capture_encode_linkage_config
    case vc_ios_render_config
    case client_dynamic_link
    case vc_phone_call_config
    case vc_voice_mode_config
    case sdk_bandwidth_throttle_config
    case vc_auto_hide_toolbar_config
    case custom_exception_config
    case vc_in_meet_perf_sample_config
    case vc_hide_non_video_config
    case vc_rtc_app_config
    case vc_rtc_billing_heartbeat_interval
    case vc_upload_share_status
    case vc_landscape_button_config
    case vc_sla_timeout_config
    case vc_tool_config
    case vc_media_service_toast
    case notes_template_category_id_config
    case notes_ai_config
    case vc_meeting_notes_config
    case vc_mute_audio_unit
    case vc_float_reaction_config

    case vc_miniwindow_share

    case nfd_scan_config
    case myai_onboarding_config
    case my_ai_brand_name

    case lark_ios_universal_downgrade_config
    /// 忽略过期的 callkit 推送配置
    case vc_ios_ignore_expired_voip_config
    /// 妙享降级配置
    case vc_magic_share_config

    /// 精细化平台配置
    /// https://bytedance.larkoffice.com/wiki/wikcnu2QtiSOkq64Tps3fABOOrd
    case fine_scheduling

    public var description: String { rawValue }
}
