//
//  ToolbarRoomControlItem.swift
//  ByteView
//
//  Created by wulv on 2023/10/17.
//

import Foundation
import ByteViewSetting
import ByteViewNetwork
import ByteViewTracker

/// 会议室控制
final class ToolbarRoomControlItem: ToolBarItem {
    override var itemType: ToolBarItemType { .roomControl }

    override var title: String { I18n.View_G_MeetingRoomControl_Button }

    override var filledIcon: ToolBarIconType {
        .icon(key: .roomControlFilled)
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        hasJoinedRoom ? .toolbar : .none
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        hasJoinedRoom ? .inCombined : .none
    }

    private var hasJoinedRoom: Bool

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.hasJoinedRoom = meeting.myself.binder?.type == .room
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        Logger.ui.info("init ToolbarRoomControlItem, hasJoinedRoom = \(self.hasJoinedRoom)")
    }

    override func initialize() {
        super.initialize()
        meeting.participant.addListener(self, fireImmediately: false)
    }

    override func clickAction() {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "room_control"])
        shrinkToolBar { [weak self] in
            guard let self = self else { return }
            if let roomId = self.meeting.myself.binder?.user.id {
                self.manageAction(roomId)
            }
        }
    }

    private func manageAction(_ roomId: String) {
        Logger.ui.info("press manage room button!, roomId: \(roomId)")
        if let vc = meeting.router.topMost {
            meeting.larkRouter.gotoRVCPage(roomId: roomId, meetingId: meeting.meetingId, from: vc)
        } else {
            Logger.ui.error("did not found topVC, cannot present lrvc page")
        }
    }
}

extension ToolbarRoomControlItem: InMeetParticipantListener {
    func didChangeMyselfBinder(_ participant: Participant?, oldValue: Participant?) {
        if participant?.user.type == .room || oldValue?.user.type == .room {
            let hasJoinedRoom = meeting.myself.binder?.type == .room
            if hasJoinedRoom != self.hasJoinedRoom {
                self.hasJoinedRoom = hasJoinedRoom
                notifyListeners()
            }
        }
    }
}
