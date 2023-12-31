//
//  RenameRequestor.swift
//  ByteView
//
//  Created by fakegourmet on 2021/12/14.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignInput
import RxSwift
import ByteViewNetwork
import ByteViewUI

final class RenameRequestor {

    static func rename(meeting: InMeetMeeting, name: String, participant: Participant, isSelf: Bool) {
        let httpClient = meeting.httpClient
        let meetingId = meeting.meetingId
        let breakoutRoomId = meeting.setting.breakoutRoomId
        let titleTextField = RenameTextField()
        titleTextField.input.text = name
        ByteViewDialog.Builder()
            .id(.rename)
            .title(I18n.View_G_Window_ChangeName)
            .titlePosition(.left)
            .contentView(titleTextField)
            .contentHeight(48.0)
            .adaptsLandscapeLayout(true)
            .leftTitle(I18n.View_G_Window_Cancel_Button)
            .leftHandler({ vc in
                RenameTracks.clickRenamePopup(isConfirmed: false, isSelf: isSelf)
                vc.dismiss()
            })
            .rightTitle(I18n.View_G_Window_Confirm_Button)
            .rightHandler({ [weak meeting] vc in
                guard let name = titleTextField.text else { return }
                RenameTracks.clickRenamePopup(isConfirmed: true, isSelf: isSelf)
                let hud = meeting?.larkRouter.showLoading(with: I18n.View_VM_Loading, disableUserInteraction: true)
                titleTextField.setStatus(.normal)
                let completion: ((Result<Void, Error>) -> Void) = { result in
                    Util.runInMainThread {
                        hud?.remove()
                        switch result {
                        case .success:
                            vc.dismiss()
                        case let .failure(error):
                            // noPermission
                            if error.toVCError() == .noPermission {
                                titleTextField.config.errorMessege = I18n.View_G_NoChangeNamePermission_Toast
                            } else {
                                titleTextField.config.errorMessege = I18n.View_G_FailedToChange_InRed
                            }
                            titleTextField.setStatus(.error)
                        }
                    }
                }
                if isSelf {
                    var request = ParticipantChangeSettingsRequest(meetingId: meetingId, breakoutRoomId: breakoutRoomId,
                                                                   role: participant.meetingRole)
                    request.participantSettings.inMeetingName = name
                    httpClient.send(request, completion: completion)
                } else {
                    let action: HostManageAction = participant.meetingRole == .webinarAttendee ? .webinarChangeAttendeeInMeetingName : .changeInMeetingName
                    var request = HostManageRequest(action: action, meetingId: meetingId)
                    request.participantId = participant.user
                    request.inMeetingName = name
                    httpClient.send(request, completion: completion)
                }
            })
            .rightType(.enableIf({ updator in
                if let text = titleTextField.text {
                    updator?(!text.isEmpty)
                } else {
                    updator?(false)
                }
                titleTextField.enableUpdator = updator
            }))
            .manualDismiss(true)
            .needAutoDismiss(true)
            .show { vc in
                vc.view.window?.addGestureRecognizer(titleTextField.endEditingTapGestureRecognizer)
            }
    }
}
