//
//  InMeetLeaveAction.swift
//  ByteView
//
//  Created by kiri on 2021/5/17.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewTracker
import ByteViewUI

struct InMeetLeaveAction {
    static func hangUp(sourceView: UIView, meeting: InMeetMeeting, context: InMeetViewContext, breakoutRoom: BreakoutRoomManager?) {
        // 1v1或者会议中只有一个人直接结束会议
        if meeting.myself.meetingRole != .webinarAttendee,
           meeting.type == .call || meeting.participant.global.nonRingingCount < 2 {
            MeetingTracksV2.trackMeetingClickOperation(
                action: .clickLeave, isSharingContent: meeting.shareData.isSharingContent)
            if shouldShowShareAlert(meeting: meeting) {
                confirmHangUpForShare(meeting: meeting)
                return
            }
            doHangUp(meeting: meeting)
            return
        }
        // 弹二次确认框
        showPopoverView(sourceView: sourceView, meeting: meeting, context: context, breakoutRoom: breakoutRoom)
    }

    static func confirmHangUpForAll(meeting: InMeetMeeting) {
        let title: String
        let rightTitle: String
        if meeting.setting.isWhiteboardSaveEnabled {
            if meeting.shareData.isSharingWhiteboard, !meeting.shareData.isWhiteBoardSaved {
                title = I18n.View_G_EndMeetingWhiteBoardNoSave_Desc
            } else if meeting.shareData.isSharingScreen, !meeting.shareData.isSketchSaved {
                title = I18n.View_G_EndMeetingAnnoNoSave_Desc
            } else {
                title = I18n.View_M_EndMeetingInfo
            }
            rightTitle = I18n.View_G_EndButton
        } else {
            title = meeting.shareData.hasSharedWhiteboard ? I18n.View_G_EndMeetDismissNoSave : I18n.View_M_EndMeetingInfo
            rightTitle = I18n.View_G_ConfirmButton
        }
        ByteViewDialog.Builder()
            .colorTheme(.redLight)
            .title(title)
            .message(nil)
            .leftTitle(I18n.View_G_CancelButton)
            .rightTitle(rightTitle)
            .rightHandler({ [weak meeting] _ in
                doEndMeeting(meeting: meeting)
            })
            .show()
    }

    private static func shouldShowShareAlert(meeting: InMeetMeeting) -> Bool {
        if meeting.setting.isWhiteboardSaveEnabled {
            if meeting.shareData.isSharingWhiteboard, !meeting.shareData.isWhiteBoardSaved {
                return true
            } else if meeting.shareData.isSharingScreen, !meeting.shareData.isSketchSaved {
                return true
            } else {
                return false
            }
        } else {
            return meeting.shareData.hasSharedWhiteboard
        }
    }

    static func confirmHangUpForShare(meeting: InMeetMeeting) {
        let title: String
        let rightTitle: String
        if meeting.setting.isWhiteboardSaveEnabled {
            if meeting.shareData.isSharingWhiteboard, !meeting.shareData.isWhiteBoardSaved {
                title = meeting.type == .call ? I18n.View_G_WhiteboardNotSavedBeforeEndCall_Desc : I18n.View_G_WhiteboardNotSavedBeforeExit_Desc
            } else if meeting.shareData.isSharingScreen, !meeting.shareData.isSketchSaved {
                title = meeting.type == .call ? I18n.View_G_AnnotationNotSavedBeforeEndCall_Desc : I18n.View_G_AnnotationNotSavedBeforeExit_Desc
            } else {
                title = meeting.type == .call ? I18n.View_G_EndCallNoSaveBoard : I18n.View_G_EndMeetNoSaveBoard
            }
            rightTitle = I18n.View_G_EndButton
        } else {
            title = meeting.type == .call ? I18n.View_G_EndCallNoSaveBoard : I18n.View_G_EndMeetNoSaveBoard
            rightTitle = meeting.type == .call ? I18n.View_G_EndButton : I18n.View_G_ConfirmButton
        }
        ByteViewDialog.Builder()
            .colorTheme(.redLight)
            .title(title)
            .message(nil)
            .leftTitle(I18n.View_G_CancelButton)
            .rightTitle(rightTitle)
            .rightHandler({ [weak meeting] _ in
                doHangUp(meeting: meeting)
            })
            .needAutoDismiss(true)
            .show()
    }

    static func confirmHangUpWebinarRehearsalForAll(meeting: InMeetMeeting) {
        ByteViewDialog.Builder()
            .colorTheme(.redLight)
            .title(I18n.View_G_EndRehearsalConfirm_Pop)
            .message(nil)
            .leftTitle(I18n.View_G_CancelButton)
            .rightTitle(I18n.View_G_ConfirmButton)
            .rightHandler({ [weak meeting] _ in
                InMeetWebinarTracks.endRehearsalForAll()
                doEndMeeting(meeting: meeting)
            })
            .show()
    }

    static func leaveWithRoom(meeting: InMeetMeeting) {
        VCTracker.post(name: .vc_meeting_popup_view, params: [.content: "leave_with_room"])
        ByteViewDialog.Builder()
            .colorTheme(.followSystem)
            .id(.leaveWithRoom)
            .title(I18n.View_G_ConfirmRoomLeaveToo_Desc)
            .message(nil)
            .leftTitle(I18n.View_G_CancelButton)
            .rightTitle(I18n.View_G_ConfirmButton)
            .rightHandler({ [weak meeting] _ in
                VCTracker.post(name: .vc_meeting_popup_click, params: [.click: "leave_with_room"])
                doHangUp(meeting: meeting, withRoom: true)
            })
            .needAutoDismiss(true)
            .show()
    }

    static func leaveMeeting(meeting: InMeetMeeting, holdPSTN: Bool = false) {
        // 离会的时候检查一下是否有绑定rooms，如有则弹窗提醒
        if meeting.myself.settings.isBindScreenCastRoom == true {
            ByteViewDialog.Builder()
                .colorTheme(.redLight)
                .id(.bindScreenCastRoom)
                .title(I18n.View_G_RoomCastLeaveConfirm)
                .message(nil)
                .leftTitle(I18n.View_G_CancelButton)
                .rightTitle(I18n.View_G_ConfirmButton)
                .rightHandler({ [weak meeting] _ in
                    doHangUp(meeting: meeting)
                })
                .needAutoDismiss(true)
                .show()
            return
        }
        doHangUp(meeting: meeting, isHoldPstn: holdPSTN)
    }

    static func endMeeting(meeting: InMeetMeeting) {
        doEndMeeting(meeting: meeting)
    }

    private static func doHangUp(meeting: InMeetMeeting?, isHoldPstn: Bool = false, withRoom: Bool = false) {
        guard let meeting = meeting else { return }
        if isHoldPstn {
            meeting.camera.muteMyself(true, source: .callmeLeaveWithoutPstn, showToastOnSuccess: false, completion: nil)
        }
        var roomId: String = ""
        var roomInteractiveId: String = ""
        if withRoom, let id = meeting.myself.binder?.user.id, let interactiveId = meeting.myself.binder?.interactiveId {
            roomId = id
            roomInteractiveId = interactiveId
        }
        meeting.leave(.userLeave(isHoldPstn: isHoldPstn, roomId: roomId, roomInteractiveID: roomInteractiveId))
        if meeting.type == .meet {
            trackUserEnd(isLeave: true)
        }
        if VCScene.isPhoneLandscape {
            MeetingTracksV2.trackChangeOrientation(toLandscape: false, reason: .leave)
        }
        if meeting.shareData.isSharingWhiteboard {
            InMeetWhiteboardViewModel.trackStopWhiteboard(meeting: meeting, isEndMeeting: true)
        }
    }

    private static func doEndMeeting(meeting: InMeetMeeting?) {
        guard let meeting = meeting else { return }
        meeting.leave(.userEnd)
        if meeting.type == .meet {
            trackUserEnd(isLeave: false)
        }
        if VCScene.isPhoneLandscape {
            MeetingTracksV2.trackChangeOrientation(toLandscape: false, reason: .leave)
        }
        if meeting.shareData.isSharingWhiteboard {
            InMeetWhiteboardViewModel.trackStopWhiteboard(meeting: meeting, isEndMeeting: true)
        }
    }

    private static func trackUserEnd(isLeave: Bool) {
        VCTracker.post(name: .vc_meeting_page_onthecall,
                       params: [.action_name: "hangup", .from_source: "control_bar",
                                .extend_value: ["hangup_type": isLeave ? "leave" : "exit"]])
    }

    static func showPopoverView(sourceView: UIView, meeting: InMeetMeeting, context: InMeetViewContext, breakoutRoom: BreakoutRoomManager?) {
        let vm = InMeetLeaveActionPopoverViewModel(meeting, breakoutRoom)
        let vc = InMeetLeaveActionPopoverViewController(viewModel: vm)
        // iPhone上挂断按钮在导航栏，弹窗往下展开，iPad上挂断按钮在toolbar，弹窗往上展开
        let arrowDirection: AlignPopoverAnchor.ArrowDirection = Display.phone ? .up : .down
        let contentSize = vc.contentSize
        let anchor = AlignPopoverAnchor(
            sourceView: sourceView,
            alignmentType: Display.phone ? .right : .center,
            arrowDirection: arrowDirection,
            contentWidth: .fixed(contentSize.width),
            contentHeight: contentSize.height,
            positionOffset: Display.phone ? CGPoint(x: 0, y: 4) : CGPoint(x: 0, y: -4),
            minPadding: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
            cornerRadius: 8,
            containerColor: UIColor.ud.bgFloat
        )
        let popover = AlignPopoverManager.shared.present(viewController: vc, anchor: anchor)
        popover.fullScreenDetector = context.fullScreenDetector
    }
}
