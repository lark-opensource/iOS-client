//
//  RoomAudioSelectViewModel.swift
//  ByteView
//
//  Created by kiri on 2023/3/16.
//

import Foundation
import ByteViewUI
import UniverseDesignIcon
import ByteViewTracker

enum RoomAudioSelectItem {
    case system
    case callMe
//    case noConnect
    case room
}

struct RoomAudioSelectCellModel {
    let item: RoomAudioSelectItem
    var icon: UDIconType?
    let title: String
    var subtitle: String?
    var accessoryText: String?
    var isSelected = false
}

protocol RoomAudioSelectViewModelDelegate: AnyObject {
    func didChangeCallMeItem(_ cellModel: RoomAudioSelectCellModel)
}

final class RoomAudioSelectViewModel: InMeetAudioModeListener {
    let meeting: InMeetMeeting
    let title: String
    private(set) var availableItems: [[RoomAudioSelectCellModel]]
    weak var delegate: RoomAudioSelectViewModelDelegate?
    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        let isPstnCalling = meeting.audioModeManager.isPstnCalling
        var items: [[RoomAudioSelectCellModel]] = [
            [RoomAudioSelectCellModel(item: .system, icon: .systemaudioFilled, title: I18n.View_MV_SelectDeviceAudio)],
            [RoomAudioSelectCellModel(item: .room, title: I18n.View_G_MeetingRoomControl_Button)]
        ]

        let isCallMeEnabled = meeting.setting.isCallMeEnabled && !meeting.isE2EeMeeing
        if isCallMeEnabled {
            items[0].append(RoomAudioSelectCellModel(item: .callMe, icon: .callFilled, title: I18n.View_MV_SelectPhoneAudio,
                                                     subtitle: meeting.setting.callmePhoneNumber,
                                                     accessoryText: isPstnCalling ? I18n.View_G_CallingEllipsis : nil))
        }

        self.title = I18n.View_MV_SwitchAudioTo
        self.availableItems = items
        if isCallMeEnabled {
            meeting.audioModeManager.addListener(self)
        }
    }

    func beginPstnCalling() {
        changeCalling(true)
    }

    func closePstnCalling() {
        changeCalling(false)
    }

    func handleSelectItem(_ item: RoomAudioSelectItem, from: UIViewController) {
        Logger.ui.info("handleSelectItem \(item)")
        switch item {
        case .system:
            VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "room_to_mobile_mic"])
            Self.showAlert(for: item, title: I18n.View_G_ConfirmSwitchSystemAudio, message: I18n.View_G_SwitchMayWhineCautionAnother,
                      rightTitle: I18n.View_MV_SwitchAudio_BarButton, rightHandler: { [weak meeting] in
                meeting?.audioModeManager.changeBizAudioMode(bizMode: .internet)
            })
        case .callMe:
            VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "room_to_mobile_call"])
            Self.showAlert(for: item, title: I18n.View_G_ConfirmSwitchPhoneAudio, message: I18n.View_G_CallPhoneJoinDisconnectRoomAudio, rightTitle: I18n.View_MV_SwitchAudio_BarButton, rightHandler: { [weak meeting] in
                meeting?.audioModeManager.beginPstnCalling()
            })
        case .room:
            VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "room_virtual_control"])
            if let room = meeting.myself.settings.targetToJoinTogether, let vc = from.presentingViewController {
                let meetingId = meeting.meetingId
                let router = meeting.larkRouter
                from.dismiss(animated: true) {
                    router.gotoRVCPage(roomId: room.id, meetingId: meetingId, from: vc)
                }
                return
            }
        }
        from.dismiss(animated: true)
    }

    static func showAlert(for item: RoomAudioSelectItem, title: String, message: String, rightTitle: String, rightHandler: @escaping () -> Void) {
        ByteViewDialog.Builder()
            .id(.switchAudioMode)
            .needAutoDismiss(true)
            .title(title)
            .message(message)
            .leftTitle(I18n.View_MV_CancelButtonTwo)
            .leftHandler({ _ in
                VCTracker.post(name: .vc_meeting_popup_click, params: [.click: "cancel", .content: "room_audio_to_mobile"])
            })
            .rightTitle(rightTitle)
            .rightHandler({ _ in
                VCTracker.post(name: .vc_meeting_popup_click, params: [.click: "confirm", .content: "room_audio_to_mobile"])
                rightHandler()
            })
            .show()
    }

    private func changeCalling(_ isCalling: Bool) {
        if let model = editItem(for: .callMe, updator: {
            $0.accessoryText = isCalling ? I18n.View_G_CallingEllipsis : nil
        }) {
            delegate?.didChangeCallMeItem(model)
        }
    }

    private func editItem(for item: RoomAudioSelectItem, updator: (inout RoomAudioSelectCellModel) -> Void) -> RoomAudioSelectCellModel? {
        for (i, rows) in availableItems.enumerated() {
            for (j, row) in rows.enumerated() {
                if row.item == item {
                    return updateItem(&availableItems[i][j], updator: updator)
                }
            }
        }
        return nil
    }

    private func updateItem(_ obj: inout RoomAudioSelectCellModel, updator: (inout RoomAudioSelectCellModel) -> Void) -> RoomAudioSelectCellModel {
        updator(&obj)
        return obj
    }
}
