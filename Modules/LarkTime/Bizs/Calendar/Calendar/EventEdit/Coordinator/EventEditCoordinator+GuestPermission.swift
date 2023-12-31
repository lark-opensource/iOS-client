//
//  EventEditCoordinator+GuestPermission.swift
//  Calendar
//
//  Created by huoyunjie on 2023/2/28.
//

import Foundation

extension EventEditCoordinator: EventEditGuestPermissionViewControllerDelegate {
    func selectGuestPermission(from fromVC: EventEditViewController) {
        guard let event = fromVC.viewModel.eventModel?.rxModel?.value else {
            EventEdit.logger.error("eventModel is not initialized")
            return
        }

        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click("attendee_auth_setting")
            $0.is_new_create = fromVC.viewModel.input.isFromCreating.description
            switch fromVC.viewModel.input {
            case .editFrom(let pbEvent, let pbInstance):
                $0.mergeEventCommonParams(commonParam: CommonParamData(instance: pbInstance, event: pbEvent))
            default:
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: event.getPBModel()))
            }
        }

        let permission: GuestPermission
        if event.guestCanModify {
            permission = .guestCanModify
        } else if event.guestCanInvite {
            permission = .guestCanInvite
        } else if event.guestCanSeeOtherGuests {
            permission = .guestCanSeeOtherGuests
        } else {
            permission = .none
        }

        let minPermission: GuestPermission = event.getPBModel().type == .meeting ? .guestCanSeeOtherGuests : .none
        let createNotesPermission = event.meetingNotesConfig.createNotesPermissionRealValue()
        let vc = EventEditGuestPermissionViewController(viewData: .init(guestPermission: permission,
                                                                        createNotesPermission: createNotesPermission),
                                                        minPermission: minPermission)
        vc.inMeetingNotesFG = fromVC.viewModel.meetingNotesModel?.inMeetingNotesFG ?? false
        vc.delegate = self
        enter(from: fromVC, to: vc, present: true)
    }

    func didFinishEdit(from viewController: EventEditGuestPermissionViewController) {
        EventEdit.logger.info("GuestPermission: \(viewController.viewData.guestPermission.rawValue)")
        let permission = viewController.viewData.guestPermission
        eventViewController?.viewModel.updateGuestPermission(permission)
        let createNotesPermission = viewController.viewData.createNotesPermission
        eventViewController?.viewModel.updateCreateNotesPermission(createNotesPermission)
        exit(from: viewController, fromPresent: true)
    }

    func didCancelEdit(from viewController: EventEditGuestPermissionViewController) {
        exit(from: viewController, fromPresent: true)
    }
}
