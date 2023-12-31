//
//  EventEditCoordinator+WebinarAttendee.swift
//  Calendar
//
//  Created by ByteDance on 2023/1/30.
//

import Foundation
import LarkUIKit
import EENavigator
import UniverseDesignToast

/// 编辑日程参与人
// MARK: EventEditWebinarAttendeeDelegate
extension EventEditCoordinator: EventEditWebinarAttendeeDelegate {
    func addWebinarAttendee(from fromVC: EventEditViewController, type: WebinarAttendeeType) {
        guard let eventModel = fromVC.viewModel.eventModel?.rxModel?.value,
              let calendar = eventModel.calendar,
              let attendeeContext = fromVC.viewModel.webinarAttendeeModel?.getAttendeeContext(with: type) else {
            assertionFailure()
            return
        }
        switch calendar.source {
        case .lark:
            let searchContext = fromVC.viewModel.contextForSearchingAttendee(visibleAttendees: attendeeContext.rxAttendeeData.value.visibleAttendees)
            calendarDependency?
                .jumpToAttendeeSelectorController(
                    from: fromVC,
                    selectedUserIDs: searchContext.chatterIds,
                    selectedGroupIDs: searchContext.chatIds,
                    selectedMailContactIDs: searchContext.emailAddresses,
                    enableSearchingOuterTenant: searchContext.enableSearchingOuterTenant,
                    canCrossTenant: true,
                    enableEmailContact: type != .speaker,
                    isForCalendarAttendee: false,
                    checkInvitePermission: true,
                    chatterPickerTitle: type == .speaker ? BundleI18n.Calendar.Calendar_Edit_AddPanelists : BundleI18n.Calendar.Calendar_Edit_AddAttendees,
                    blockTip: BundleI18n.Calendar.Calendar_NewContacts_CantInviteToEventsDueToBlockOthers,
                    beBlockedTip: BundleI18n.Calendar.Calendar_G_CreateEvent_AddUser_CantInvite_Hover,
                    alertTitle: BundleI18n.Calendar.Calendar_NewContacts_NeedToAddToContactstDialgTitle,
                    alertContent: BundleI18n.Calendar.Calendar_NewContacts_NeedToAddToContactstAddGuestsDialogContent,
                    alertContentWithUser: BundleI18n.Calendar.Calendar_NewContacts_NeedToAddToContactstAddOneGuestDialogContent,
                    searchPlaceholder: type == .speaker ? BundleI18n.Calendar.Calendar_Edit_SearchContactPlaceholder : nil,
                    callBack: { [weak fromVC] (picker, result, showApplyContactAlert) in
                        guard let editVC = fromVC,
                              let picker = picker,
                              !result.attendees.isEmpty || !result.departments.isEmpty else {
                            picker?.dismiss(animated: true) {
                                showApplyContactAlert?()
                            }
                            return
                        }
                        let has_group_attendee = result.attendees.contains { attendee in
                            if case .group = attendee {
                                return true
                            }
                            return false
                        }
                        let has_architecture_attendee = !result.departments.isEmpty
                        CalendarTracerV2.EventFullCreate.traceClick {
                            $0.has_group_attendee = has_group_attendee.description
                            $0.has_architecture_attendee = has_architecture_attendee.description
                            $0.click("add_attendee_result").target("none")
                            $0.is_new_create = self.editInput.isFromCreating ? "true" : "false"
                            $0.mergeEventCommonParams(commonParam: CommonParamData(event: eventModel.getPBModel(),
                                                                                   startTime: Int64(eventModel.startDate.timeIntervalSince1970) ))

                        }
                        UDToast.showLoading(with: I18n.Calendar_Common_LoadAndWait, on: picker.view)
                        editVC.viewModel.addAttendees(
                            type: type,
                            seeds: result.attendees,
                            departments: result.departments,
                            messageReceiver: { [weak editVC] message in
                                guard let editVC = editVC else { return }
                                switch message {
                                case .showAlert(let alert):
                                    editVC.handleAlert(alert)
                                case .attendeeCountLimit(let limitReason, let continueAction):
                                    UDToast.removeToast(on: picker.view)
                                    guard let limitReason = limitReason else {
                                        picker.dismiss(animated: true)
                                        return
                                    }
                                    editVC.handleAttendeeLimitReason(limitReason: limitReason, controller: picker)
                                case .applyContactAlert:
                                    showApplyContactAlert?()
                                case .errorToast(let msg):
                                    UDToast.showFailure(with: msg, on: picker.view)
                                case .warningToast(let msg):
                                    UDToast.showWarning(with: msg, on: editVC.view)
                                case .tipsToast(let msg):
                                    UDToast.showTips(with: msg, on: editVC.view)
                                }
                            }
                        )
                    })
        default:
            return
        }
    }

    func listWebinarAttendee(from viewController: EventEditViewController, type: WebinarAttendeeType) {
        guard let eventViewModel = eventViewController?.viewModel,
              let eventModel = eventViewModel.eventModel?.rxModel?.value,
              let webinarAttendeeModel = eventViewModel.webinarAttendeeModel,
              let attendeeContext = webinarAttendeeModel.getAttendeeContext(with: type) else {
            assertionFailure()
            return
        }

        let currentUser = dependency.currentUser
        let attendeesPermission: PermissionOption = eventViewModel.permissionModel?.rxPermissions.value.attendees ?? .readable
        let isLarkEvent: Bool = eventModel.calendar != nil && eventModel.calendar!.source == .lark
        let currentTenantId: String = currentUser?.tenantId ?? ""
        let currentUserCalendarId: String = dependency.calendarManager?.primaryCalendarID ?? ""
        let organizerCalendarId: String = eventModel.organizerCalendarId
        let creatorCalendarId: String = eventModel.creatorCalendarId
        let eventID: String = eventModel.eventID
        let startTime: Int64 = Int64(eventModel.startDate.timeIntervalSince1970)
        let rrule: String = eventModel.getPBModel().rrule
        let simpleAttendeeCount: Int = attendeeContext.individualSimpleAttendees.count + attendeeContext.groupSimpleAttendees.count

        let eventTuple: (String, String, Int64)?
        let pageContext: EventAttendeeListViewModel.PaginationContext
        var originalGroupAttendee: [EventEditAttendee] = eventViewModel.originalGroupAttendee
        let attendees: [EventEditAttendee] = type == .speaker ? eventModel.speakers : eventModel.audiences
        let originalIndividualAttendees: [Rust.IndividualSimpleAttendee] = attendeeContext.rxOriginalIndividualimpleAttendees.value
        let newSimpleAttendees: [Rust.IndividualSimpleAttendee] = attendeeContext.rxNewSimpleAttendees.value
        let attendeeInfo = type == .speaker ? eventModel.eventSpeakerStatistics : eventModel.eventAudienceStatistics
        let rustAllAttendeeCount: Int = Int(attendeeInfo?.totalNo ?? 0)
        let groupSimpleMemberMap: [String: [Rust.IndividualSimpleAttendee]] = webinarAttendeeModel.groupSimpleMembers
        let groupEncryptedMemberMap: [String: [Rust.EncryptedSimpleAttendee]] = webinarAttendeeModel.groupEncryptedMembers

        switch eventViewModel.input {
        case .editWebinar(pbEvent: let event, pbInstance: _):
            eventTuple = (event.calendarID, event.key, event.originalTime)
        default:
            eventTuple = nil
        }

        if simpleAttendeeCount > attendees.count {
            pageContext = .needPaginationWithPageOffset
        } else {
            pageContext = .noMore
        }

        let viewModel = EventAttendeeListViewModel(
            userResolver: self.userResolver,
            attendees: attendees,
            originalGroupAttendee: originalGroupAttendee,
            originalIndividualAttendees: originalIndividualAttendees,
            newSimpleAttendees: newSimpleAttendees,
            groupSimpleMemberMap: groupSimpleMemberMap,
            groupEncryptedMemberMap: groupEncryptedMemberMap,
            attendeesPermission: attendeesPermission,
            isLarkEvent: isLarkEvent,
            currentTenantId: currentTenantId,
            currentUserCalendarId: currentUserCalendarId,
            organizerCalendarId: organizerCalendarId,
            creatorCalendarId: creatorCalendarId,
            rustAllAttendeeCount: rustAllAttendeeCount,
            eventTuple: eventTuple,
            eventID: eventID,
            startTime: startTime,
            rrule: rrule,
            pageContext: pageContext,
            attendeeType: .webinar(type)
        )
        let vc = EventAttendeeListViewController(viewModel: viewModel, userResolver: self.userResolver)
        vc.showNonFullEditPermissonTip = eventViewModel.shouldShowNonFullEditPermissonTip(attendees: attendees)
        vc.delegate = self
        viewController.navigationController?.pushViewController(vc, animated: true)
    }
}
