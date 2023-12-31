//
//  EventEditCoordinator+Attendee.swift
//  Calendar
//
//  Created by 张威 on 2020/4/13.
//

import Foundation
import LarkUIKit
import EENavigator
import UniverseDesignToast

/// 编辑日程参与人

extension EventEditCoordinator: EventEditAttendeeDelegate,
    EventEmailAttendeeViewControllerDelegate,
    EventAttendeeListViewControllerDelegate {
    // MARK: EventEditAttendeeDelegate

    func addAttendee(from fromVC: EventEditViewController) {
        guard let eventModel = fromVC.viewModel.eventModel?.rxModel?.value,
              let calendar = eventModel.calendar,
              let attendeeModel = fromVC.viewModel.attendeeModel else {
            assertionFailure()
            return
        }
        switch calendar.source {
        case .lark:
            let searchContext = fromVC.viewModel.contextForSearchingAttendee(visibleAttendees: attendeeModel.rxAttendeeData.value.visibleAttendees)
            calendarDependency?
                .jumpToAttendeeSelectorController(
                    from: fromVC,
                    selectedUserIDs: searchContext.chatterIds,
                    selectedGroupIDs: searchContext.chatIds,
                    selectedMailContactIDs: searchContext.emailAddresses,
                    enableSearchingOuterTenant: searchContext.enableSearchingOuterTenant,
                    canCrossTenant: true,
                    enableEmailContact: true,
                    isForCalendarAttendee: false,
                    checkInvitePermission: true,
                    chatterPickerTitle: BundleI18n.Calendar.Calendar_Edit_AddGuest,
                    blockTip: BundleI18n.Calendar.Calendar_NewContacts_CantInviteToEventsDueToBlockOthers,
                    beBlockedTip: BundleI18n.Calendar.Calendar_G_CreateEvent_AddUser_CantInvite_Hover,
                    alertTitle: BundleI18n.Calendar.Calendar_NewContacts_NeedToAddToContactstDialgTitle,
                    alertContent: BundleI18n.Calendar.Calendar_NewContacts_NeedToAddToContactstAddGuestsDialogContent,
                    alertContentWithUser: BundleI18n.Calendar.Calendar_NewContacts_NeedToAddToContactstAddOneGuestDialogContent,
                    searchPlaceholder: nil,
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
                            $0.mergeEventCommonParams(commonParam: CommonParamData(event: eventModel.getPBModel(), startTime: Int64(eventModel.startDate.timeIntervalSince1970) ))

                        }
                        UDToast.showLoading(with: I18n.Calendar_Common_LoadAndWait, on: picker.view)
                        editVC.viewModel.addAttendees(
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

        case .exchange, .google, .local:
            // 添加邮箱参与人
            let emailAttendees: [EventEditEmailAttendee] = eventModel.attendees
                .compactMap {
                    guard case .email(let emailAttendee) = $0 else { return nil }
                    return emailAttendee
                }
            let emailOriginalAttendees: [EventEditEmailAttendee] = fromVC.viewModel.originalIndividualAttendees
                .compactMap { attendee in
                    guard attendee.category == .thirdPartyUser else { return nil }
                    return attendee
                }.map { EventEditEmailAttendee(simpleAttendee: $0, type: .normalMail) }
            let viewModel = EventEmailAttendeeViewModel(
                attendees: emailAttendees,
                originalAttendees: emailOriginalAttendees,
                attendeeThatNeedsAutoInsert: fromVC.viewModel.emailAttendeeThatNeedsAutoInsert()
            )
            let tovc = EventEmailAttendeeViewController(viewModel: viewModel)
            tovc.delegate = self
            enter(from: fromVC, to: tovc, present: true)
        }
    }

    func listAttendee(from viewController: EventEditViewController) {
        guard let eventViewModel = eventViewController?.viewModel,
              let eventModel = eventViewModel.eventModel?.rxModel?.value else {
            assertionFailure()
            return
        }
        let eventTuple: (String, String, Int64)?
        switch eventViewModel.input {
        case .editFrom(pbEvent: let event, pbInstance: _):
            eventTuple = (event.calendarID, event.key, event.originalTime)
        default:
            eventTuple = nil
        }

        let pageContext: EventAttendeeListViewModel.PaginationContext

        let simpleAttendeeCount = eventViewModel.individualSimpleAttendees.count + eventViewModel.groupSimpleAttendees.count
        if simpleAttendeeCount > eventModel.attendees.count {
            pageContext = .needPaginationWithPageOffset
        } else {
            pageContext = .noMore
        }

        let currentUser = dependency.currentUser
        let originalGroupAttendee = eventViewModel.originalGroupAttendee
        let viewModel = EventAttendeeListViewModel(
            userResolver: self.userResolver,
            attendees: eventModel.attendees,
            originalGroupAttendee: originalGroupAttendee,
            originalIndividualAttendees: eventViewModel.originalIndividualAttendees,
            newSimpleAttendees: eventViewModel.newSimpleAttendees,
            groupSimpleMemberMap: eventViewModel.groupSimpleMembers,
            groupEncryptedMemberMap: eventViewModel.groupCryptedMembers,
            attendeesPermission: eventViewModel.permissionModel?.rxPermissions.value.attendees ?? .readable,
            isLarkEvent: eventModel.calendar != nil && eventModel.calendar!.source == .lark,
            currentTenantId: currentUser?.tenantId ?? "",
            currentUserCalendarId: dependency.calendarManager?.primaryCalendarID ?? "",
            organizerCalendarId: eventModel.organizerCalendarId,
            creatorCalendarId: eventModel.creatorCalendarId,
            rustAllAttendeeCount: Int(eventModel.eventAttendeeStatistics?.totalNo ?? 0),
            eventTuple: eventTuple,
            eventID: eventModel.eventID,
            startTime: Int64(eventModel.startDate.timeIntervalSince1970),
            rrule: eventModel.getPBModel().rrule,
            pageContext: pageContext,
            aiGenerateAttendeeList: eventModel.aiStyleInfo.attendee
        )
        let vc = EventAttendeeListViewController(viewModel: viewModel, userResolver: self.userResolver)
        vc.showNonFullEditPermissonTip = eventViewModel.shouldShowNonFullEditPermissonTip(attendees: eventModel.attendees)
        vc.delegate = self
        viewController.navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: EventEmailAttendeeViewControllerDelegate

    func didCancelEdit(from viewController: EventEmailAttendeeViewController) {
        exit(from: viewController, fromPresent: true)
    }

    func didFinishEdit(from viewController: EventEmailAttendeeViewController, attendeeType: AttendeeType = .normal) {
        defer {
            exit(from: viewController, fromPresent: true)
        }
        let emailAttendees = viewController.viewModel.attendees
        guard let eventViewModel = eventViewController?.viewModel else {
            assertionFailure()
            return
        }
        // exchange/google/local 日程没有精简参与人
        eventViewModel.updateAttendees(attendees: emailAttendees.map { .email($0) }, simpleAttendees: [], attendeeType: attendeeType)
    }

    // MARK: EventAttendeeListViewControllerDelegate

    func didCancelEdit(from viewController: EventAttendeeListViewController) {
        viewController.navigationController?.popViewController(animated: true)
    }

    func didFinishEdit(from viewController: EventAttendeeListViewController, attendeeType: AttendeeType = .normal) {
        defer {
            viewController.navigationController?.popViewController(animated: true)
        }
        let attendees = viewController.viewModel.attendees
        let simpleAttendees = viewController.viewModel.newSimpleAttendees
        guard let eventViewModel = eventViewController?.viewModel else {
            assertionFailure()
            return
        }
        eventViewModel.updateAttendees(attendees: attendees, simpleAttendees: simpleAttendees, attendeeType: attendeeType)
    }

}
