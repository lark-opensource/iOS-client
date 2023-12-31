//
//  BreakoutRoomAction.swift
//  ByteView
//
//  Created by kiri on 2021/5/11.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewUI

class BreakoutRoomAction {
    static func askHostForHelp(source: BreakoutRoomTracks.Source, meeting: InMeetMeeting) {
        BreakoutRoomTracks.askForHelpClick(source: source, meeting: meeting)
        if meeting.participant.hasHostOrCohost {
            Toast.show(I18n.View_G_HostCoInRoomAlready)
            return
        }

        let title = I18n.View_G_AskHostForHelpQuestion
        let cancel = I18n.View_G_CancelButton
        let send = I18n.View_M_SendRequest
        BreakoutRoomTracks.askForHelpShow(source: source, meeting: meeting)
        BreakoutRoomTracksV2.askForHelpShow(meeting: meeting)
        ByteViewDialog.Builder()
            .id(.confirmBeforeAskHostForHelp)
            .message(nil)
            .needAutoDismiss(true)
            .title(title)
            .leftTitle(cancel)
            .leftHandler({ [weak meeting] _ in
                guard let meeting = meeting else { return }
                BreakoutRoomTracks.askForHelpCancel(source: source, meeting: meeting)
                BreakoutRoomTracksV2.askForHelpCancel(source: source, meeting: meeting)
            })
            .rightTitle(send)
            .rightHandler({ [weak meeting] _ in
                doAskHostForHelp(meeting: meeting, source: source)
            })
            .show()
    }

    static func doAskHostForHelp(meeting: InMeetMeeting?, source: BreakoutRoomTracks.Source) {
        guard let meeting = meeting else { return }
        BreakoutRoomTracks.askForHelpRequest(source: source, meeting: meeting)
        BreakoutRoomTracksV2.askForHelpRequest(source: source, meeting: meeting)
        let myRoomID = meeting.myself.breakoutRoomId
        if meeting.participant.hasHostOrCohost {
            Toast.show(I18n.View_G_HostCoInRoomAlready)
            return
        }
        let request = VCManageApplyRequest(meetingId: meeting.meetingId, breakoutRoomId: myRoomID, applyType: .applyForHelpFromBreakoutRoom)
        meeting.httpClient.getResponse(request) { (result) in
            if let code = result.value?.result, code != .success {
                switch code {
                case .hostBusy:
                    Toast.show(I18n.View_G_HostBusy)
                case .fail:
                    Logger.ui.debug("Ask for help response fail")
                default:
                    Logger.ui.debug("Ask for help response unknown default")
                }
            }
        }
    }
}
