//
//  LobbyTracks.swift
//  ByteView
//
//  Created by chentao on 2020/7/16.
//

import Foundation
import LarkMedia
import ByteViewTracker

final class LobbyTracks {

    private static let onTheCallPage = TrackEventName.vc_meeting_page_onthecall
    static let waitingRoomPopupPage = TrackEventName.vc_waiting_rooms_popup
    static let waitingRoomPage = TrackEventName.vc_meeting_page_waiting_rooms
    static let userListPage = TrackEventName.vc_meeting_page_userlist

    static func trackAttentionAppearOfLobby(_ meeting: InMeetMeeting) {
        trackAttentionOfLobby(action: "view_lobby", meeting: meeting)
    }

    static func trackAttentionAdmitOfLobby(userID: String, deviceID: String, meeting: InMeetMeeting) {
        trackAttentionOfLobby(action: "admit", userID: userID, deviceID: deviceID, meeting: meeting)
    }

    static func trackAttentionClosedOfLobby(_ meeting: InMeetMeeting) {
        trackAttentionOfLobby(action: "close", meeting: meeting)
    }

    static func trackAttentionProfileOfLobby(userID: String, deviceID: String, meeting: InMeetMeeting) {
        trackAttentionOfLobby(action: "user_profile", userID: userID, deviceID: deviceID, meeting: meeting)
    }

    private static func trackAttentionOfLobby(action: String, userID: String? = nil, deviceID: String? = nil, meeting: InMeetMeeting) {
        let breakoutRoomStart = BreakoutRoomTracks.isStart(meeting)
        var params: TrackParams = [.action_name: action, BreakoutRoomTracks.Start.key: breakoutRoomStart]
        params[BreakoutRoomTracks.Location.key] = BreakoutRoomTracks.selfLocation(meeting)
        var extends: [String: Any] = [:]
        if let userId = userID {
            extends["attendee_uuid"] = EncryptoIdKit.encryptoId(userId)
        }
        if let deviceId = deviceID {
            extends["attendee_device_id"] = deviceId
        }
        if !extends.isEmpty {
            params[.extend_value] = extends
        }
        VCTracker.post(name: waitingRoomPopupPage, params: params)
    }

    static func trackAdmiteAllWaitingParticipantsOfLobby(_ meeting: InMeetMeeting) {
        let breakoutRoomStart = BreakoutRoomTracks.isStart(meeting)
        var params: TrackParams = [.action_name: "admit_all", BreakoutRoomTracks.Start.key: breakoutRoomStart]
        params[BreakoutRoomTracks.Location.key] = BreakoutRoomTracks.selfLocation(meeting)
        VCTracker.post(name: userListPage, params: params)
    }

    static func trackAdmitAllLobby() {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "admit_all", .location: "userlist"])
    }

    static func trackWebinarAdmitAllLobby(paneCount: Int, attendeeCount: Int, fromAttendee: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "admit_all", "waitingroom_panelist_num": paneCount, "waitingroom_attendee_num": attendeeCount, .location: fromAttendee ? "attendee_list" : "panelist_list"])
    }

    static func trackRemovedWaitingParticipantOfLobby(userID: String, deviceID: String, isSearch: Bool, meeting: InMeetMeeting) {
        trackWaitingParticipantOfLobby(action: "remove", userID: userID, deviceID: deviceID, isSearch: isSearch, meeting: meeting)
    }

    static func trackRemoveLobby() {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "remove", .location: "userlist"])
    }

    static func trackWebinarRemoveLobby(paneCount: Int, attendeeCount: Int, fromAttendee: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "remove", "waitingroom_panelist_num": paneCount, "waitingroom_attendee_num": attendeeCount, .location: fromAttendee ? "attendee_list" : "panelist_list"])

    }

    static func trackAdmitedWaitingParticipantOfLobby(userID: String, deviceID: String, isSearch: Bool, meeting: InMeetMeeting) {
        trackWaitingParticipantOfLobby(action: "admit", userID: userID, deviceID: deviceID, isSearch: isSearch, meeting: meeting)
    }

    static func trackAdmitLobby() {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "admit", .location: "userlist"])
    }

    static func trackWebinarAdmitLobby(paneCount: Int, attendeeCount: Int, fromAttendee: Bool) {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "admit", "waitingroom_panelist_num": paneCount, "waitingroom_attendee_num": attendeeCount, .location: fromAttendee ? "attendee_list" : "panelist_list"])
    }

    private static func trackWaitingParticipantOfLobby(action: String, userID: String, deviceID: String, isSearch: Bool, meeting: InMeetMeeting) {
        let breakoutRoomStart = BreakoutRoomTracks.isStart(meeting)
        var params: TrackParams = [.from_source: isSearch ? "search_userlist" : "userlist",
                                   .action_name: action,
                                   .extend_value: ["attendee_uuid": EncryptoIdKit.encryptoId(userID),
                                                   "attendee_device_id": deviceID],
                                   BreakoutRoomTracks.Start.key: breakoutRoomStart]
        params[BreakoutRoomTracks.Location.key] = BreakoutRoomTracks.selfLocation(meeting)
        VCTracker.post(name: userListPage, params: params)
    }

    static func trackDisplayOfLobby(interactiveID: String) {
        VCTracker.post(name: waitingRoomPage, params: [.action_name: "display",
                                                 "interactive_id": interactiveID])
    }

    static func trackCameraStatusOfLobby(muted: Bool, source: LobbySource? = nil) {
        trackControlOfLobby(action: "camera", enabled: muted)
        /// 新埋点
        if let source = source {
            var params: TrackParams = [.click: "camera", .option: muted ? "close" : "open"]
            if source == .preLobby {
                params[.is_starting_auth] = true
            }
            VCTracker.post(name: source.trackName, params: params)
        }
    }

    static func trackMicStatusOfLobby(muted: Bool, source: LobbySource) {
        trackControlOfLobby(action: "mic", enabled: muted)
        /// 新埋点
        var params: TrackParams = [.click: "mic", .option: muted ? "close" : "open"]
        if source == .preLobby {
            params[.is_starting_auth] = true
        }
        VCTracker.post(name: source.trackName, params: params)
    }

    static func trackSpeakerStatusOfLobby(enabled: Bool) {
        trackControlOfLobby(action: "speaker", enabled: enabled)
    }

    static func trackHangupOfLobby(source: LobbySource) {
        trackControlOfLobby(action: "hangup")
        /// 新埋点
        if source == .inLobby {
            VCTracker.post(name: .vc_meeting_waiting_click, params: [.click: "leave"])
        }
    }

    private static func trackControlOfLobby(action: String, enabled: Bool? = nil) {
        var params: TrackParams = [.from_source: "control_bar",
                                   .action_name: action]
        if let enabled = enabled {
            params[.extend_value] = ["action_enabled": enabled ? 1 : 0]
        }
        VCTracker.post(name: waitingRoomPage, params: params)
    }
}

// MARK: New Tracker
final class LobbyTracksV2 {

    /// 切换无入会权限参会人进入等候室
    static func trackSwitchLobbyEntry(on: Bool, fromSource: TrackFromSource, isMeetingLocked: Bool) {
        VCTracker.post(name: .vc_meeting_hostpanel_click,
                       params: [.click: "lobby_entry",
                                "is_meeting_locked": isMeetingLocked,
                                "host_tab": "join_permission",
                                "is_check": on,
                                .from_source: fromSource.rawValue])
    }

    static func trackSpeakerStatusOfLobby(isSheet: Bool, source: LobbySource) {
        let target = isSheet ? TrackEventName.vc_meeting_loudspeaker_view : nil
        var params: TrackParams = [.click: "speaker", .target: target]
        if source == .preLobby {
            params[.is_starting_auth] = true
        }
        VCTracker.post(name: source.trackName, params: params)
    }
}

extension LobbySource {
    var trackName: TrackEventName {
        switch self {
        case .preLobby:
            return .vc_meeting_pre_click
        case .inLobby:
            return .vc_meeting_waiting_click
        }
    }
}
