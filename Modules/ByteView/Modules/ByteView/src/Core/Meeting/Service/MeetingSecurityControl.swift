//
//  MeetingSecurityControl.swift
//  ByteView
//
//  Created by kiri on 2023/6/29.
//

import Foundation

final class MeetingSecurityControl {
    private let security: SecurityStateDependency

    init(security: SecurityStateDependency) {
        self.security = security
    }

    func didSecurityViewAppear() -> Bool {
        security.didSecurityViewAppear()
    }

    // 截屏录屏保护（共享屏幕场景豁免保护）
    func vcScreenCastChange(_ vcCast: Bool) {
        security.vcScreenCastChange(vcCast)
    }

    @discardableResult
    func copy(_ text: String, token: PasteboardToken, shouldImmunity: Bool = false) -> Bool {
        security.setPasteboardText(text, token: token.rawValue, shouldImmunity: shouldImmunity)
    }

    func paste(token: PasteboardToken) -> String? {
        security.getPasteboardText(token: token.rawValue)
    }
}

// === Clipboard ===
enum PasteboardToken: String {
    case meetingDetailCopyMeetingContent = "LARK-PSDA-meeting_detail_page_copy_meeting_content"
    case phoneListCopyNumbers = "LARK-PSDA-phone_list_page_copy_numbers"
    case magicShareCopyDocumentUrl = "LARK-PSDA-magic_share_copy_document_url"
    case liveCopyLink = "LARK-PSDA-live_page_copy_link"
    case participantCopyMeetingContent = "LARK-PSDA-participant_page_copy_meeting_content"
    case subtitlePageCopySubtitle = "LARK-PSDA-subtitle_page_copy_subtitle"
    case subtitlePageCopyDocUrl = "LARK-PSDA-subtitle_page_copy_doc_url"
    case toolbarCopyLiveLink = "LARK-PSDA-toolbar_copy_live_link"
    /// 仅用于测试代码
    case debugToken = "psda_token_avoid_intercept"
}

enum SncToken: String {
    // === DeviceInfo ===
    case proximityMonitor = "LARK-PSDA-byteview_proximity_monitor"
    case rtcCameraOrientation = "LARK-PSDA-byteview_rtc_camera_orientation_monitor"
    case perfMonitorGetWifi = "LARK-PSDA-byteview_perf_monitor_get_wifi"

    // requestAccess
    case requestMicAccess = "LARK-PSDA-byteview_request_microphone_access"
    case requestCamAccess = "LARK-PSDA-byteview_request_camera_access"

    // startAudioCapture
    case joinChannel = "LARK-PSDA-enter_onthecall_rtc_join_channel"
    case changeToSystemAudio = "LARK-PSDA-change_to_system_audio"
    case noaudioEnterPip = "LARK-PSDA-noaudio_enter_pip"
    case disconnectPhonecall = "LARK-PSDA-onthecall_disconnect_phonecall"
    case breakroomTransiton = "LARK-PSDA-breakroom_transiton_recover"

    // startVideoCapture
    case callOut = "LARK-PSDA-byteview_call_out_open_camera"
    case preview = "LARK-PSDA-byteview_preview_open_camera"
    case preLobby = "LARK-PSDA-byteview_prelobby_open_camera"
    case lobby = "LARK-PSDA-byteview_lobby_open_camera"
    case inMeet = "LARK-PSDA-byteview_inmeet_open_camera"
    case previewLab = "LARK-PSDA-byteview_preview_lab_open_camera"
    case preLobbyLab = "LARK-PSDA-byteview_prelobby_lab_open_camera"
    case lobbyLab = "LARK-PSDA-byteview_lobby_lab_open_camera"
    case inMeetLab = "LARK-PSDA-byteview_inmeet_lab_open_camera"
    case stopCapture = "byteview_stop_video_capture" // 停止不受管控，没有在平台申请，校验一定为true

    // shareScreen
    case shareScreen = "LARK-PSDA-byteview_share_screen"
    case shareToRoom = "LARK-PSDA-byteview_share_to_room_or_box"
    case takeOverSameRoom = "LARK-PSDA-byteview_take_over_same_room"
}
