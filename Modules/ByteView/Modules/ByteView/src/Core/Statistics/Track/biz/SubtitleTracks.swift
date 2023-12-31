//
//  SubtitleTracks.swift
//  ByteView
//
//  Created by kiri on 2020/10/21.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker
import ByteViewMeeting
import ByteViewCommon

final class SubtitleTracks {

    private static let subtitlePage = TrackEventName.vc_meeting_subtitle_page
    private static let subtitleSettingPage = TrackEventName.vc_meeting_subtitle_setting_page
    private static let meetingPopupPage = TrackEventName.vc_meeting_popup
    private static let subtitlePopup = TrackEventName.vc_meeting_subtitle_popup
    private static let inaccurateSubtitlePopup = TrackEventName.vc_inaccurate_subtitle_popup
    private static let japaneseSubtitlePopup = TrackEventName.vc_japanese_subtitle_popup
    private static let subtitleSegReceive = TrackEventName.vc_new_seg_subtitle_receive_dev

    /// 收到字幕
    static func trackReceiveSubtitle(segId: Int64) {
        VCTracker.post(name: .monitor_vc_client_subtitle_delay, params: ["segid": "\(segId)"])
    }

    /// 点击字幕详情入口
    static func trackClickAllSubtitles() {
        guard let trackName = MeetingManager.shared.currentSession?.meetType.trackName else {
            return
        }
        VCTracker.post(name: trackName, params: [.action_name: "all_subtitles"])
    }

    /// 字幕页面回到底部
    static func trackScrollToBottom() {
        VCTracker.post(name: subtitlePage, params: [.action_name: "to_bottom"])
    }

    /// 点击字幕设置入口
    static func trackClickSettings() {
        VCTracker.post(name: .vc_meeting_subtitle_setting, params: [.action_name: "display", .from_source: "vc_main_settings"])
    }

    static func trackSubtitleSettings(from: String) {
        VCTracker.post(name: .vc_meeting_subtitle_setting_page, params: [.action_name: "display", .from_source: from])
    }

    static func trackChangeSpokenLanguage(from: String?, to: String) {
        VCTracker.post(name: subtitleSettingPage,
                       params: [.action_name: "spoken_language",
                                .extend_value: ["from_language": from ?? "", "action_language": to]])
    }

    static func trackChangeSubtitleLanguage(from: String?, to: String) {
        VCTracker.post(name: subtitleSettingPage,
                       params: [.action_name: "subtitle_language",
                                .extend_value: ["from_language": from ?? "", "action_language": to]])
    }

    /// 开启字幕时允许录制音频
    static func trackEnableAudioRecord(_ enabled: Bool) {
        VCTracker.post(name: subtitlePopup,
                       params: [.action_name: enabled ? "allow" : "deny"])
    }

    static func trackSpokenLanguagePrompt() {
        VCTracker.post(name: meetingPopupPage,
                       params: [.from_source: "substitle_first_spoken_language",
                                .action_name: "display"])
    }

    static func trackConfirmSpokenLanguage(_ lang: String) {
        VCTracker.post(name: meetingPopupPage,
                       params: [.from_source: "substitle_first_spoken_language",
                                .action_name: "confirm",
                                "spoken_language": lang])
    }

    static func trackCancelSpokenLanguage() {
        VCTracker.post(name: meetingPopupPage,
                       params: [.from_source: "substitle_first_spoken_language",
                                .action_name: "cancel"])
    }

    static func trackMismatchLanguageTip() {
        VCTracker.post(name: meetingPopupPage,
                       params: [.from_source: "mismatch_language_tip",
                                .action_name: "display"])
    }

    static func trackLangDetectMismatchAlert() {
        VCTracker.post(name: inaccurateSubtitlePopup, params: [.action_name: "display"])
    }

    static func trackLangDetectNonsupportAlert() {
        VCTracker.post(name: japaneseSubtitlePopup, params: [.action_name: "display"])
    }

    static func trackLangDetectMismatchAction(_ isConfirmed: Bool) {
        let action = isConfirmed ? "confirm" : "sub_setting"
        VCTracker.post(name: inaccurateSubtitlePopup, params: [.action_name: action])
    }

    static func trackLangDetectNonsupportAction(_ isConfirmed: Bool) {
        let action = isConfirmed ? "confirm" : "sub_setting"
        VCTracker.post(name: japaneseSubtitlePopup, params: [.action_name: action])
    }

    static func trackSubtitleSegReceive(isOrdered: Bool) {
        let order = isOrdered ? "true" : "false"
        VCTracker.post(name: subtitleSegReceive, params: ["is_seg_id_ordered": order])
    }
}

// 记录字幕耗时
private enum SubtitleTracksTimeInterval {
    static var startTrackSubtileStartTime: CFTimeInterval?
    static var startTrackListenToSubtitle: CFTimeInterval?
    static var startTrackSilenceToSubtitle: CFTimeInterval?
}

// MARK: New Trackers
final class SubtitleTracksV2 {

    static var trackId: String?

    enum TrackType: String {
        case start_to_listen
        case start_to_silence
        case listen_to_subtitle
        case silence_to_subtitle
    }

    enum TrackStatus: String {
        case success
        case close
        case fail
    }

    enum PageType: String {
        case complete_subtitle
        case realtime_subtitle
    }

    /// 会中字幕页监控事件
    /// 开始计时：开启到下一状态
    static func startTrackSubtitleStartDuration() {
        Queue.tracker.async {
            trackId = UUID().uuidString
            SubtitleTracksTimeInterval.startTrackSubtileStartTime = CACurrentMediaTime()
        }
    }

    /// 会中字幕页监控事件
    /// 开始计时：正在聆听到首句字幕
    static func startTrackListenToSubtitle() {
        Queue.tracker.async {
            SubtitleTracksTimeInterval.startTrackListenToSubtitle = CACurrentMediaTime()
        }
    }

    /// 会中字幕页监控事件
    /// 开始计时：无人发言到首句字幕
    static func startTrackSilenceToSubtitle() {
        Queue.tracker.async {
            SubtitleTracksTimeInterval.startTrackSilenceToSubtitle = CACurrentMediaTime()
        }
    }

    /// 会中字幕页监控事件(开启到聆听/无人发言)
    /// 终止计时并上报
    static func endTrackSubtitleStartDuration(status: TrackStatus, type: TrackType, exists: Int) {
        Queue.tracker.async {
            guard let startTime = SubtitleTracksTimeInterval.startTrackSubtileStartTime,
                  let tId = trackId else { return }
            let duration = CACurrentMediaTime() - startTime
            if status == .success {
                VCTracker.post(name: .vc_meeting_subtitle_dev,
                               params: ["status": status,
                                        "type": type,
                                        .duration: duration * 1000,
                                        "id": tId,
                                        "exists": exists
                                       ])
            } else {
                VCTracker.post(name: .vc_meeting_subtitle_dev,
                               params: ["status": status,
                                        "type": type,
                                        .duration: duration * 1000,
                                        "id": tId
                                       ])
            }
            SubtitleTracksTimeInterval.startTrackSubtileStartTime = nil
            Logger.subtitle.info("start duration: \(Int(duration * 1000)), status: \(status), type: \(type)")
        }
    }

    /// 会中字幕页监控事件(正在聆听到首句字幕)
    /// 终止计时并上报
    static func endTrackListenToSubtitleDuration(status: TrackStatus, type: TrackType) {
        Queue.tracker.async {
            guard let startTime = SubtitleTracksTimeInterval.startTrackListenToSubtitle,
                  let tId = trackId else { return }
            let duration = CACurrentMediaTime() - startTime
            VCTracker.post(name: .vc_meeting_subtitle_dev,
                           params: ["status": status,
                                    "type": type,
                                    .duration: duration * 1000,
                                    "id": tId
                                   ])
            SubtitleTracksTimeInterval.startTrackListenToSubtitle = nil
            trackId = nil
        }
    }

    /// 会中字幕页监控事件(聆听/无人发言到首句字幕)
    /// 终止计时并上报
    static func endTrackSilenceToSubtitleDuration(status: TrackStatus, type: TrackType) {
        Queue.tracker.async {
            guard let startTime = SubtitleTracksTimeInterval.startTrackSilenceToSubtitle,
                  let tId = self.trackId else { return }
            let duration = CACurrentMediaTime() - startTime
            VCTracker.post(name: .vc_meeting_subtitle_dev,
                           params: ["status": status,
                                    "type": type,
                                    .duration: duration * 1000,
                                    "id": tId
                                   ])
            SubtitleTracksTimeInterval.startTrackSilenceToSubtitle = nil
            trackId = nil
        }
    }

    /// 字幕视图曝光
    static func trackSubtitleViewAppear(type: PageType) {
        VCTracker.post(name: .vc_meeting_subtitle_view,
                       params: ["page_type": type.rawValue])
    }

    /// 开启字幕，isAutoOpen 是否为入会后自动开启
    static func trackOpenSubtitles(isAutoOpen: Bool) {
        let action: MeetingTracksClickAction = .clickSubtitle
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: [.click: action.trackStr,
                                .target: action.trackTarget,
                                "is_auto": isAutoOpen])
    }

    /// 关闭字幕页面
    static func trackClickSubtitleClose(fromSource: String) {
        VCTracker.post(name: .vc_meeting_subtitle_click,
                       params: [.click: "close",
                                .target: TrackEventName.vc_meeting_onthecall_view,
                                "page_type": fromSource])
    }
    /// 弹窗点击转到完整字幕
    static func trackSubtitleActionSheetClickCompleteSubtitle() {
        VCTracker.post(name: .vc_subtitle_popup_click,
                       params: [.click: "complete_subtitle",
                                .target: TrackEventName.vc_meeting_subtitle_view])
    }
    /// 弹窗点击关闭字幕
    static func trackSubtitleActionSheetClickClose() {
        VCTracker.post(name: .vc_subtitle_popup_click,
                       params: [.click: "close",
                                .target: TrackEventName.vc_meeting_onthecall_view])
    }
    /// 弹窗点击取消
    static func trackSubtitleActionSheetClickCancel() {
        VCTracker.post(name: .vc_subtitle_popup_click,
                       params: [.click: "cancel",
                                .target: TrackEventName.vc_meeting_onthecall_view])
    }

    /// 点击实时字幕面板
    static func trackClickSubtitlePanel() {
        VCTracker.post(name: .vc_meeting_subtitle_click,
                       params: [.click: "complete_subtitle",
                                .target: TrackEventName.vc_meeting_subtitle_view,
                                "page_type": PageType.realtime_subtitle])
    }

    /// 点击字幕设置
    static func trackClickSubtitleSetting() {
        VCTracker.post(name: .vc_meeting_subtitle_click,
                       params: [.click: "subtitle_setting",
                                .target: TrackEventName.vc_meeting_subtitle_setting_view,
                                "page_type": PageType.complete_subtitle])
    }

    /// 拷贝字幕
    static func trackCopySubtitle() {
        VCTracker.post(name: .vc_meeting_subtitle_click,
                       params: [.click: "copy_subtitle",
                                .target: "none",
                                "page_type": PageType.complete_subtitle])
    }

    /// 关闭历史字幕设置
    static func trackClickHistorySubtitleClose() {
        VCTracker.post(name: .vc_meeting_subtitle_click,
                       params: [.click: "close_history",
                                .target: "none"])
    }

    /// 点击字幕历史
    static func trackClickShowHistory() {
        VCTracker.post(name: .vc_meeting_subtitle_click,
                       params: [.click: "show_history"])
    }

    /// 点击筛选
    static func trackClickFilter() {
        VCTracker.post(name: .vc_meeting_subtitle_click,
                       params: [.click: "filter",
                                "page_type": PageType.complete_subtitle])
    }

    /// 完整字幕筛选器点击某个参会人触发筛选
    static func trackSelectParticipant() {
        VCTracker.post(name: .vc_meeting_subtitle_status,
                       params: ["status": "filter",
                                "page_type": PageType.complete_subtitle])
    }

    /// 点击字幕搜索框
    static func trackClickSearch() {
        VCTracker.post(name: .vc_meeting_subtitle_click,
                       params: [.click: "search",
                                "page_type": PageType.complete_subtitle])
    }

    /// 完整字幕搜索框输入内容
    static func trackEditingDidBegin() {
        VCTracker.post(name: .vc_meeting_subtitle_status,
                       params: ["status": "search",
                                "page_type": PageType.complete_subtitle])
    }

    /// 点击返回底部
    static func trackClickBackToBottom() {
        VCTracker.post(name: .vc_meeting_subtitle_click,
                       params: [.click: "back_to_bottom"])
    }

    /// 滑动字幕 current 当前段落， total整体段落
    static func trackClickScrollProgress(current: Int, total: Int) {
        VCTracker.post(name: .vc_meeting_subtitle_click,
                       params: [.click: "subtitle_progress_bar",
                                "page_type": PageType.complete_subtitle,
                                "paragraph_now": String(current),
                                "paragraph_total": String(total)])
    }
    /// 完整字幕点击会议小窗
    static func trackClickFloatWindow() {
        VCTracker.post(name: .vc_meeting_subtitle_click,
                       params: [.click: "small_window"])
    }

    /// 完整字幕点击返回按钮
    static func trackClickBackButton() {
        VCTracker.post(name: .vc_meeting_subtitle_click,
                       params: [.click: "back",
                                .target: "vc_meeting_subtitle_view",
                                "page_type": PageType.complete_subtitle])
    }
}

/// 【字幕】效果端到端评测
/// 埋点方案 https://bytedance.sg.feishu.cn/sheets/shtlgplBXYuspJBymZPwbDYdqed
final class SubtitleTracksV3 {
    /// 端上在决策字幕是否要上屏时的端上埋点
    static func trackShouldShowSubtitle(seg_id: String, slice_id: String, display_time: String, decision: Int) {
        VCTracker.post(name: .vc_subtitle_exp_dev,
                       params: ["type": "SUB_DISPLAYED",
                               "seg_id": seg_id,
                               "slice_id": slice_id,
                               "display_time": display_time,
                               "decision": decision])
    }
}
