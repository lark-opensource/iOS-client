//
//  BreakoutRoomTracks.swift
//  ByteView
//
//  Created by wulv on 2021/3/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker

final class BreakoutRoomTracks {

    static let Popup = TrackEventName.vc_meeting_breakoutrooms_popup

    enum Action {
        static let display = "display"
        static let click = "click"
        static let leave = "leave"
        static let request = "sendrequest"
        static let cancel = "cancel"
        static let known = "known"
        static let leaveNow = "leaveroom_now"
        static let showLeave = "display_leaveButton"
        static let leaveMeeting = "leave_meeting"
    }

    enum Source: String {
        case toolBar = "toolbar_askforhelp"
        case listTop = "listtop_askforhelp"
        case receive = "breakoutrooms_receive_broadcast"
        case mobile = "mobile_leaveroom"
        case leave = "leaveroom_soon"
        case handsup = "breakoutrooms_applytospeak"
    }

    enum Amount {
        static let key: TrackParamKey = "apply_amount"
    }

    enum Start {
        static let key: TrackParamKey = "is_breakoutroom_start"
        static let `false` = 0
        static let `true` = 1
    }

    enum Location {
        static let key: TrackParamKey = "user_location"
        static let main = "mainroom"
        static let room = "inrooms"
    }
}

extension BreakoutRoomTracks {

    private static func trackPopup(action: String, source: Source, meeting: InMeetMeeting) {
        var params: TrackParams = [.action_name: action, .from_source: source.rawValue, Start.key: isStart(meeting)]
        params[Location.key] = selfLocation(meeting)
        VCTracker.post(name: Popup, params: params)
    }

    // MARK: - 通参
    static func isStart(_ meeting: InMeetMeeting) -> Int {
        return meeting.data.isOpenBreakoutRoom ?
        BreakoutRoomTracks.Start.true :
        BreakoutRoomTracks.Start.false
    }

    static func isStart(_ isOpenBreakoutRoom: Bool) -> Int {
        return isOpenBreakoutRoom ? BreakoutRoomTracks.Start.true : BreakoutRoomTracks.Start.false
    }

    static func selfLocation(_ meeting: InMeetMeeting) -> String {
        return meeting.myself.isInMainBreakoutRoom ? BreakoutRoomTracks.Location.main : BreakoutRoomTracks.Location.room
    }

    static func selfLocation(_ isInBreakoutRoom: Bool) -> String {
        return isInBreakoutRoom ? BreakoutRoomTracks.Location.room : BreakoutRoomTracks.Location.main
    }

    // MARK: - 主持人在讨论组中，选择“离开讨论组
    static func leaveRoomPopupShow(_ meeting: InMeetMeeting) {
        trackPopup(action: Action.display, source: .mobile, meeting: meeting)
    }

    static func leaveRoomPopupLeave(_ meeting: InMeetMeeting) {
        trackPopup(action: Action.leave, source: .mobile, meeting: meeting)
    }

    // MARK: - 讨论组内的参会人请求主持人帮助
    static func askForHelpClick(source: Source, meeting: InMeetMeeting) {
        trackPopup(action: Action.click, source: source, meeting: meeting)
    }

    static func askForHelpShow(source: Source, meeting: InMeetMeeting) {
        trackPopup(action: Action.display, source: source, meeting: meeting)
    }

    static func askForHelpRequest(source: Source, meeting: InMeetMeeting) {
        trackPopup(action: Action.request, source: source, meeting: meeting)
    }

    static func askForHelpCancel(source: Source, meeting: InMeetMeeting) {
        trackPopup(action: Action.cancel, source: source, meeting: meeting)
    }

    // MARK: - 参会人收到广播
    static func broadcastShow(_ meeting: InMeetMeeting) {
        var params: TrackParams = [.action_name: Action.display, .from_source: Source.receive.rawValue, Start.key: isStart(meeting)]
        params[Location.key] = selfLocation(meeting)
        VCTracker.post(name: Popup, params: params)
    }

    // MARK: - 小组内成员收到离开分组的提示
    static func willStopPopupShow(_ meeting: InMeetMeeting) {
        trackPopup(action: Action.display, source: .leave, meeting: meeting)
    }

    static func willStopPopupKnow(_ meeting: InMeetMeeting) {
        trackPopup(action: Action.known, source: .leave, meeting: meeting)
    }

    static func willStopPopupLeave(_ meeting: InMeetMeeting) {
        trackPopup(action: Action.leaveNow, source: .leave, meeting: meeting)
    }

    // MARK: - 转场页超时离会
    static func transitionShowLeaveButton() {
        VCTracker.post(name: Popup, params: [.action_name: Action.showLeave])
    }

    static func transitionLeaveMeeting() {
        VCTracker.post(name: Popup, params: [.action_name: Action.leaveMeeting])
    }
}
