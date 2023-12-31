//
//  InMeetRenameViewModel.swift
//  ByteView
//
//  Created by fakegourmet on 2021/12/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork

final class InMeetRenameViewModel: InMeetingChangedInfoPushObserver {

    private let meeting: InMeetMeeting
    required init(meeting: InMeetMeeting) {
        self.meeting = meeting
        meeting.push.inMeetingChange.addObserver(self)
    }

    func didReceiveInMeetingChangedInfo(_ data: InMeetingData) {
        if data.meetingID == meeting.meetingId, data.type == .hostChangePartiName {
            Toast.show(I18n.View_G_HostHasChangedName_Toast)
            RenameTracks.showRenameToast()
        }
    }
}
