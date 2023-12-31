//
//  BreakoutRoomTrackesV2.swift
//  ByteView
//
//  Created by wulv on 2021/7/18.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

final class BreakoutRoomTracksV2 {

    enum Event {
        static let BKPopupClick = TrackEventName.vc_meeting_breakoutrooms_popup_click
        static let BKPopupView = TrackEventName.vc_meeting_breakoutrooms_popup_view
        static let MTPopupView = TrackEventName.vc_meeting_popup_view
        static let MTPopupClick = TrackEventName.vc_meeting_popup_click
        static let OTCClick = TrackEventName.vc_meeting_onthecall_click
    }

    enum Key {
        static let isBreakoutRoomStart: TrackParamKey = "is_breakoutroom_start"
        static let userLocation: TrackParamKey = "user_location"
    }

    enum Value {
        static let askForHelp = "ask_for_help"
        static let broadcast = "breakoutrooms_receive_broadcast"
        static let countDown = "leave_countdown"
        static let transfer = "join_room_transfer"
        static let mainRoom = "mainroom"
        static let inRooms = "inrooms"
        static let lobbyAttention = "waiting_room_remind"
        static let admitALl = "admit_all"
        static let remove = "remove"
        static let admit = "admit"
        static let leave = "leave"
        static let leaveRooms = "leave_rooms"
        static let leaveMeeting = "leave_meeting"
        static let mobileLeave = "mobile_leaveroom"
        static let request = "sendrequest"
        static let cancel = "cancel"
        static let profile = "user_profile"
        static let viewLobby = "view_lobby"
        static let lobbyRemind = "waiting_room_remind"
        static let known = "known"
        static let leaveNow = "leaveroom_now"
        static let unmute = "self_unmute"
        static let muteAll = "mute_all"
        static let unmuteAll = "unmute_all"
    }
}

extension BreakoutRoomTracksV2 {

    private static func trackEvent(_ event: TrackEventName, specificParams: TrackParams, meeting: InMeetMeeting) {
        var params: TrackParams = ["is_breakoutroom_start": meeting.data.isOpenBreakoutRoom]
        params[Key.userLocation] = selfLocation(meeting)
        params.updateParams(specificParams.rawValue)
        VCTracker.post(name: event, params: params)
    }

    // MARK: - 通参

    static func selfLocation(_ meeting: InMeetMeeting) -> String {
        return meeting.myself.isInMainBreakoutRoom ? Value.mainRoom : Value.inRooms
    }

    static func selfLocation(_ isInBreakoutRoom: Bool) -> String {
        isInBreakoutRoom ? Value.inRooms : Value.mainRoom
    }

    // MARK: - 主持人在讨论组中，选择“离开讨论组
    static func leaveRoomPopupLeave(_ meeting: InMeetMeeting) {
        trackEvent(Event.BKPopupClick, specificParams: [.click: Value.leave,
                                                        .content: Value.leaveRooms,
                                                        .option: Value.mobileLeave], meeting: meeting)
    }

    // MARK: - 讨论组内的参会人请求主持人帮助
    static func askForHelpShow(meeting: InMeetMeeting) {
        trackEvent(Event.BKPopupView, specificParams: [.content: Value.askForHelp], meeting: meeting)
    }

    static func askForHelpRequest(source: BreakoutRoomTracks.Source, meeting: InMeetMeeting) {
        trackEvent(Event.BKPopupClick, specificParams: [.click: Value.request,
                                                        .content: Value.askForHelp,
                                                        .option: source.rawValue], meeting: meeting)
    }

    static func askForHelpCancel(source: BreakoutRoomTracks.Source, meeting: InMeetMeeting) {
        trackEvent(Event.BKPopupClick, specificParams: [.click: Value.cancel,
                                                        .content: Value.askForHelp,
                                                        .option: source.rawValue], meeting: meeting)
    }

    // MARK: - 参会人收到广播
    static func broadcastShow(_ meeting: InMeetMeeting) {
        trackEvent(Event.BKPopupView, specificParams: [.content: Value.broadcast], meeting: meeting)
    }

    // MARK: - 小组内成员收到离开分组的提示
    static func willStopPopupShow(_ meeting: InMeetMeeting) {
        trackEvent(Event.BKPopupView, specificParams: [.content: Value.countDown], meeting: meeting)
    }

    static func willStopPopupKnow(_ meeting: InMeetMeeting) {
        trackEvent(Event.BKPopupClick, specificParams: [.click: Value.known, .content: Value.countDown], meeting: meeting)
    }

    static func willStopPopupLeave(_ meeting: InMeetMeeting) {
        trackEvent(Event.BKPopupClick, specificParams: [.click: Value.leaveNow,
                                                        .content: Value.countDown], meeting: meeting)
    }

    // MARK: - 转场页超时离会
    static func transitionLeaveMeeting(_ meeting: InMeetMeeting) {
        trackEvent(Event.BKPopupClick, specificParams: [.click: Value.leaveMeeting,
                                                        .content: Value.transfer], meeting: meeting)
    }

    // MARK: - 转场
    static func beginTransition(_ meeting: InMeetMeeting) {
        trackEvent(Event.BKPopupView, specificParams: [.content: Value.transfer], meeting: meeting)
    }

    // MARK: - 等候室
    static func lobbyAttention(_ meeting: InMeetMeeting) {
        trackEvent(Event.MTPopupView,
                   specificParams: [.content: Value.lobbyAttention],
                   meeting: meeting)
    }

    static func lobbyAttentionProfile(_ meeting: InMeetMeeting) {
        trackEvent(Event.MTPopupClick, specificParams: [.click: Value.profile,
                                                        .content: Value.lobbyRemind], meeting: meeting)
    }

    static func lobbyAttentionDetail(_ meeting: InMeetMeeting) {
        trackEvent(Event.MTPopupClick, specificParams: [.click: Value.viewLobby,
                                                        .content: Value.lobbyRemind], meeting: meeting)
    }

    static func lobbyAttentionAdmit(_ meeting: InMeetMeeting) {
        trackEvent(Event.MTPopupClick, specificParams: [.click: Value.admit,
                                                        .content: Value.lobbyRemind], meeting: meeting)
    }

    static func lobbyAttentionClose(_ meeting: InMeetMeeting) {
        trackEvent(Event.MTPopupClick, specificParams: [.click: "close",
                                                        .content: Value.lobbyRemind], meeting: meeting)
    }

    static func admitAllLobby(_ meeting: InMeetMeeting) {
        trackEvent(Event.OTCClick,
                   specificParams: [.click: Value.admitALl],
                   meeting: meeting)
    }

    static func removeLobby(_ meeting: InMeetMeeting) {
        trackEvent(Event.OTCClick,
                   specificParams: [.click: Value.remove],
                   meeting: meeting)
    }

    static func admitLobby(_ meeting: InMeetMeeting) {
        trackEvent(Event.OTCClick,
                   specificParams: [.click: Value.admit],
                   meeting: meeting)
    }

    // MARK: - 全员静音
    static func muteAll(_ meeting: InMeetMeeting, isMute: Bool) {
        trackEvent(Event.OTCClick, specificParams: [.click: isMute ? Value.muteAll : Value.unmuteAll], meeting: meeting)
    }

    enum AttentionButton: String {
        case viewDetail = "detail"
        case joinRoom = "joinroom"
        case dismiss = "dismiss"
    }

    static func trackAttentionClick(_ meeting: InMeetMeeting, _ button: AttentionButton) {
        let params: TrackParams = [
            .click: button.rawValue,
            .content: "breakoutrooms_receive_help"
        ]
        trackEvent(Event.OTCClick, specificParams: params, meeting: meeting)
    }

    enum HostControlButton: String {
        case joinRoom = "joinroom"
        case leaveRoom = "leaveRoom"
    }

    static func trackHostControlClick(_ meeting: InMeetMeeting, _ button: HostControlButton) {
        let params: TrackParams = [.click: button.rawValue]
        trackEvent(TrackEventName.vc_meeting_breakoutrooms_setting_click, specificParams: params, meeting: meeting)
    }
    enum AutoFinishConfirmButton: String {
        case continue_ = "continue_discuss"
        case end = "end_discuss_now"
    }

    static func trackAutoFinishConfirmClick(_ meeting: InMeetMeeting, _ button: AutoFinishConfirmButton) {
        let params: TrackParams = [.click: button.rawValue, .content: "end_discuss_confirm"]
        trackEvent(TrackEventName.vc_meeting_breakoutrooms_popup_click, specificParams: params, meeting: meeting)
    }
}
