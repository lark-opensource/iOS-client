//
//  SingleVideoViewModel.swift
//  ByteView
//
//  Created by LUNNER on 2020/4/1.
//

import Foundation
import RxRelay

final class SingleVideoViewModel {
    let rtcUid: RtcUID
    let gridCellViewModel: InMeetGridCellViewModel

    init(meeting: InMeetMeeting, context: InMeetViewContext, gridVM: InMeetGridCellViewModel) {
        self.rtcUid = gridVM.rtcUid
        self.gridCellViewModel = gridVM
        meeting.participant.addListener(self)
        context.addListener(self, for: .hideSelf)
    }
}

extension SingleVideoViewModel: InMeetParticipantListener, InMeetViewChangeListener {

    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        guard self.gridCellViewModel.meeting.myself.meetingRole != .webinarAttendee else {
            return
        }
        if !gridCellViewModel.meeting.participant.contains(user: gridCellViewModel.pid) {
            gridCellViewModel.isRemoved.accept(true)
        }
    }

    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if change == .hideSelf, let hideSelf = userInfo as? Bool {
            if hideSelf && gridCellViewModel.isMe {
                gridCellViewModel.isRemoved.accept(true)
            }
        }
    }
}
