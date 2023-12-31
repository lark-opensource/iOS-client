//
//  MeetSettingTracks.swift
//  ByteView
//
//  Created by kiri on 2020/10/21.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkMedia
import ByteViewTracker
import ByteViewMeeting

extension VideoChatSecuritySetting.SecurityLevel {
    var trackName: String {
        switch self {
        case .public:
            return "anyone"
        case .onlyHost:
            return "host_invited"
        case .contactsAndGroup:
            return "selected"
        case .tenant:
            return "organizer_company"
        default:
            return ""
        }
    }
}

final class MeetSettingTracks {

    /// 设备权限检查
    static func trackDeviceStatus(name: TrackEventName, isMicOn: Bool?, isCameraOn: Bool?, audioOutput: AudioOutput) {
        var params: TrackParams = [:]
        params[.action_name] = "hardware_status"
        if let isMicOn = isMicOn, !Privacy.audioDenied {
            params["mic"] = isMicOn ? "unmute" : "mute"
        } else {
            params["mic"] = "unavailable"
        }
        if let isCameraOn = isCameraOn, !Privacy.videoDenied {
            params["camera"] = isCameraOn ? "unmute" : "mute"
        } else {
            params["camera"] = "unavailable"
        }
        params["audio_output"] = audioOutput.trackText
        VCTracker.post(name: name, params: params)
    }

    static func trackStartRecording() {
        VCTracker.post(name: .vc_meeting_page_onthecall, params: [.action_name: "record_start"])
    }

    static func trackStartRecordingReConfrim(canceled: Bool) {
        VCTracker.post(name: .vc_meeting_popup, params: [.from_source: "record_reconfirm",
                                                         .action_name: canceled ? "cancel" : "confirm"])
    }

    static func trackStopRecording() {
        VCTracker.post(name: .vc_meeting_page_onthecall, params: [.action_name: "record_stop"])
    }

    static func trackConfirmRequstRecording(_ confirm: Bool) {
        VCTracker.post(name: .vc_meeting_popup,
                       params: [.from_source: "record_request_reconfirm",
                                .action_name: confirm ? "confirm" : "cancel"])
    }

    static func trackConfirmStopRecording(_ confirm: Bool, isOwner: Bool) {
        VCTracker.post(name: .vc_meeting_page_onthecall,
                       params: [.from_source: "record_finish_hint",
                                .action_name: confirm ? "confirm" : "cancel",
                                "is_owner": isOwner ? 1 : 0])
    }

    /// 接受、拒绝会议录制邀请
    static func trackConfirmRecordInviteHint(_ confirm: Bool, isMeet: Bool) {
        VCTracker.post(name: .vc_meeting_page_onthecall,
                       params: [.from_source: "record_invite_hint",
                                .action_name: confirm ? "confirm" : "refuse"])
        if !isMeet {
            VCTracker.post(name: .vc_call_page_onthecall,
                           params: [.action_name: confirm ? "click_agree" : "click_refuse"])
        }
    }

    static func trackConfirmRecordPopup(_ confirm: Bool) {
        VCTracker.post(name: .vc_meeting_page_onthecall,
                       params: [.from_source: "record_popup",
                                .action_name: confirm ? "stay_meeting" : "leave_meeting"])
    }

    /// 3.47【录制icon优化】添加，点击录制/录制中icon时埋点
    /// https://bytedance.feishu.cn/sheets/shtcnBfaNZPnMBLmpnvigakIaad
    /// - Parameter isRecording: 点击时是否正处于录制中的状态
    static func trackTapRecording(onRecordingStatus isRecording: Bool) {
        VCTracker.post(name: .vc_meeting_page_onthecall,
                       params: [.action_name: "click_record",
                                "recording_status": isRecording ? 1 : 0])
    }

    static func trackStartTranscribing() {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "transcribe"])
    }

    static func trackStopTranscribing() {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "stop_transcribe"])
    }

    static func trackHideTranscriptPanel(location: String) {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "hide_transcript_panel", "location": location])
    }

    static func trackConfirmRequstLiving(_ confirm: Bool) {
        VCTracker.post(name: .vc_meeting_popup,
                       params: [.from_source: "live_request_reconfirm",
                                .action_name: confirm ? "confirm" : "cancel"])
    }

    static func trackTapLive(isLiving: Bool, liveId: Int64?) {
        let params: TrackParams = [.action_name: "ask_host_to_livestream",
                                   "is_live": isLiving ? 1 : 0,
                                   "live_id": liveId ?? 0]
        VCTracker.post(name: .vc_meeting_page_onthecall, params: params)
    }

    static func trackTapLiveSettings(isLiving: Bool, liveId: Int64?) {
        let params: TrackParams = [.action_name: "live",
                                   "is_live": isLiving ? 1 : 0,
                                   "live_id": liveId ?? 0]
        VCTracker.post(name: .vc_meeting_page_onthecall, params: params)
    }

    static func trackTapLab() {
        VCTracker.post(name: .vc_meeting_page_onthecall,
                       params: [.action_name: "vc_labs",
                                .from_source: "addition"])
    }

    static func trackTapVideoMirrorSetting(on: Bool, settingTab: String = "setting") {
        VCTracker.post(name: .vc_meeting_setting_click,
                       params: [.click: "is_mirror",
                                "is_check": on,
                                "setting_tab": settingTab])
    }

    static func trackTapCenterStageSetting(on: Bool) {
        VCTracker.post(name: .vc_meeting_setting_click,
                       params: [.click: "center_stage",
                                "is_check": on])
    }

    static func trackTapKeyboardMuteSetting(on: Bool) {
        VCTracker.post(name: .vc_meeting_setting_click,
                       params: [.click: "space_open_mic",
                                "is_check": on,
                                "setting_tab": "voice"])
    }

    static func trackTapCellularImproveVoice(isChecked: Bool, isFromToast: Bool) {
        VCTracker.post(name: .vc_meeting_setting_click,
                       params: [.click: "cellular_improve_voice",
                                "is_check": isChecked,
                                "from_source": isFromToast ? "toast" : "normal_setting" ])
    }

    static func trackHideNoVideoUser(isOn: Bool) {
        VCTracker.post(name: .vc_meeting_setting_click,
                       params: [.click: "hide_non_video_users",
                                "is_check": isOn])
    }
}

// MARK: New Tracker
final class MeetSettingTracksV2 {

    /// 字幕设置页面选中某种语言
    /// - Parameter isTranslateLanguage: true->翻译语言；false->口说语言
    static func trackClickSubtitleLanguage(_ selectedLanguage: String, isTranslateLanguage: Bool) {
        VCTracker.post(name: .vc_meeting_setting_click,
                       params: [.click: isTranslateLanguage ? "translate_language" : "speak_language",
                                "setting_tab": "subtitle",
                                "language": selectedLanguage])
    }

    /// 字幕设置页开关智能注释
    static func trackClickSubtitleSettingSwitch(_ isChecked: Bool) {
        VCTracker.post(name: .vc_meeting_setting_click,
                       params: [.click: "subtitle_annotation",
                                "is_checked": isChecked ? "true" : "false"])
    }

}
