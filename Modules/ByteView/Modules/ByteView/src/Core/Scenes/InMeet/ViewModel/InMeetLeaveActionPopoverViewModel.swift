//
// Created by maozhixiang.lip on 2022/9/1.
//

import Foundation
import RxSwift
import RxCocoa
import ByteViewTracker

class InMeetLeaveActionPopoverViewModel {
    typealias ActionHandler = () -> Void
    private let meetingContext: InMeetMeeting
    private let breakoutRoomManager: BreakoutRoomManager?

    private var isWebinarRehearsing: Bool {
        meetingContext.isWebinarRehearsing
    }

    init(_ meetingContext: InMeetMeeting,
         _ breakoutRoomManager: BreakoutRoomManager?) {
        self.meetingContext = meetingContext
        self.breakoutRoomManager = breakoutRoomManager
    }

    enum ActionType {
        case leaveMeeting
        case endMeeting
        case leaveBreakoutRoom
        case leaveMeetingFromBreakoutRoom
        case webinarRehearsalLeaveMeeting
        case webinarRehearsalEndMeeting
        case leaveWithRoom
    }

    var holdPSTN: Bool = false

    var showPSTNView: Bool {
        self.meetingContext.audioModeManager.isInCallMe
    }

    var actions: [(ActionType, ActionHandler)] {
        self.actionTypes.map { ($0, self.createActionHandler($0)) }
    }

    // PRD: https://bytedance.feishu.cn/docx/doxcn3rDSsWWj3U5n6ViS0BX4Mg
    private var actionTypes: [ActionType] {
        if self.isInBreakoutRoom {
            if meetingContext.setting.canReturnToMainRoom {
                return meetingContext.setting.hasCohostAuthority
                    ? [.leaveBreakoutRoom]
                    : [.leaveMeetingFromBreakoutRoom, .leaveBreakoutRoom]
            } else {
                return [.leaveMeeting]
            }
        } else if self.isWebinarRehearsing {
            if meetingContext.setting.hasHostAuthority {
                return [.webinarRehearsalEndMeeting, .webinarRehearsalLeaveMeeting]
            } else {
                return [.webinarRehearsalLeaveMeeting]
            }
        } else {
            if meetingContext.setting.hasHostAuthority {
                if meetingContext.myself.binder?.type == .room {
                    return [.endMeeting, .leaveMeeting, .leaveWithRoom]
                }
                return [.endMeeting, .leaveMeeting]
            } else {
                if meetingContext.myself.binder?.type == .room {
                    return [.leaveMeeting, .leaveWithRoom]
                }
                return [.leaveMeeting]
            }
        }
    }


    private var isInBreakoutRoom: Bool {
        guard let roomID = self.meetingContext.data.breakoutRoomId else { return false }
        return !BreakoutRoomUtil.isMainRoom(roomID)
    }

    private func createActionHandler(_ actionType: ActionType) -> ActionHandler {
        switch actionType {
        case .webinarRehearsalEndMeeting:
            return { [weak self] in
                guard let self = self else { return }
                InMeetLeaveAction.confirmHangUpWebinarRehearsalForAll(meeting: self.meetingContext)
            }
        case .leaveBreakoutRoom:
            return { [weak self] in
                guard let self = self else { return }
                guard let breakoutRoom = self.breakoutRoomManager else { return }
                BreakoutRoomTracks.leaveRoomPopupLeave(self.meetingContext)
                BreakoutRoomTracksV2.leaveRoomPopupLeave(self.meetingContext)
                breakoutRoom.leave()
            }
        case .endMeeting:
            return { [weak self] in
                guard let self = self else { return }
                MeetingTracksV2.trackMeetingClickOperation(
                    action: .clickEndMeeting,
                    isSharingContent: self.meetingContext.shareData.isSharingContent)
                InMeetLeaveAction.confirmHangUpForAll(meeting: self.meetingContext)
            }
        case .leaveMeeting, .leaveMeetingFromBreakoutRoom, .webinarRehearsalLeaveMeeting:
            return { [weak self] in
                guard let self = self else { return }
                MeetingTracksV2.trackLeaveMeeting(self.meetingContext, holdPSTN: self.holdPSTN)
                InMeetLeaveAction.leaveMeeting(meeting: self.meetingContext, holdPSTN: self.holdPSTN)
            }
        case .leaveWithRoom:
            return { [weak self] in
                guard let self = self else { return }
                VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "leave_with_room"])
                InMeetLeaveAction.leaveWithRoom(meeting: self.meetingContext)
            }
        }
    }
}
