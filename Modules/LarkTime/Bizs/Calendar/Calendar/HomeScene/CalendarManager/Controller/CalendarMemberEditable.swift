//
//  CalendarMemberEditable.swift
//  Calendar
//
//  Created by harry zou on 2019/3/25.
//

import UIKit
import Foundation
import CalendarFoundation
import UniverseDesignToast
import RxSwift
import RustPB

protocol CalendarMemberEditable {
    var api: CalendarRustAPI { get }
    var calendarDependency: CalendarDependency { get }
    var disposeBag: DisposeBag { get }
    func update(withModel model: CalendarManagerModel)
}

extension CalendarMemberEditable where Self: UIViewController {
    func addAttendee(withModel model: CalendarManagerModel) {
        var selectedIds: (user: [String], group: [String]) = ([], [])
        model.calendarMembers.forEach { member in
            if member.status == .removed { return }
            if member.isGroup { selectedIds.group.append(member.chatId) } else { selectedIds.user.append(member.userID) }
        }

        calendarDependency
            .jumpToAttendeeSelectorController(
                from: self,
                selectedUserIDs: selectedIds.user,
                selectedGroupIDs: selectedIds.group,
                selectedMailContactIDs: [],
                enableSearchingOuterTenant: false,
                canCrossTenant: false,
                enableEmailContact: false,
                isForCalendarAttendee: true,
                checkInvitePermission: true,
                chatterPickerTitle: BundleI18n.Calendar.Calendar_Setting_AddSharingMembers,
                blockTip: BundleI18n.Calendar.Calendar_NewContacts_CantInviteToEventsDueToBlockOthers,
                beBlockedTip: BundleI18n.Calendar.Calendar_G_CreateEvent_AddUser_CantInvite_Hover,
                alertTitle: BundleI18n.Calendar.Calendar_NewContacts_NeedToAddToContactstDialgTitle,
                alertContent: BundleI18n.Calendar.Calendar_NewContacts_NeedToAddToContactstAddGuestsDialogContent,
                alertContentWithUser: BundleI18n.Calendar.Calendar_NewContacts_NeedToAddToContactstAddOneGuestDialogContent,
                searchPlaceholder: nil,
                callBack: { [unowned self] (controller, result, _) in
                    let attendees = result.attendees
                    let (userIds, chatterIds) = attendees.reduce(([], []), { (result, attendee) -> ([String], [String]) in

                        switch attendee {
                        case .user(let chatterId):
                            var result = result
                            var chatterIds = result.0
                            chatterIds.append(chatterId)
                            result.0 = chatterIds
                            return result
                        case .group(let chatId):
                            var result = result
                            var chatIds = result.1
                            chatIds.append(chatId)
                            result.1 = chatIds
                            return result
                        default: return result
                        }
                    })
                    self.api.getCalendarMembersWithCheck(calendarId: model.calendar.serverId, userIds: userIds, chatIds: chatterIds)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak model, weak self] (memberPBs, hasMemberInhibited, rejectedUsers) in
                        guard let model = model,
                            let `self` = self else { return }
                            let newMembers: [CalendarMember] = memberPBs.map { .init(pb: $0) }
                            if hasMemberInhibited {
                                model.rejectedUserIDs = rejectedUsers
                                let alertText = (userIds.count > 1 || !chatterIds.isEmpty) ? I18n.Calendar_Share_NoPermitShare_Toast : I18n.Calendar_Share_NoPermitShareThis_Toast
                                UDToast.showWarning(with: alertText, on: self.view)
                            }
                            guard !newMembers.isEmpty else { return }

                            for var newMember in newMembers {
                                if let index = model.calendarMembers.firstIndex(where: { (member) -> Bool in
                                    if member.isGroup && newMember.isGroup && newMember.chatId == member.chatId {
                                        return true
                                    }
                                    if !member.isGroup && !newMember.isGroup && member.userID == newMember.userID {
                                        return true
                                    }
                                    return false
                                }) {
                                    model.calendarMembers[index].status = .default
                                } else {
                                    CalendarTracer.shareInstance.calCalAddMember(memberType: .init(isGroup: newMember.isGroup),
                                                                                 memberPermission: .init(accessRole: newMember.accessRole))
                                    newMember.accessRole = .reader
                                    if model.calendarMembers.isEmpty {
                                        model.calendarMembers.append(newMember)
                                    } else {
                                        model.calendarMembers.insert(newMember, at: 1)
                                    }
                                }
                            }
                        self.update(withModel: model)
                    }, onError: { (_) in

                    }).disposed(by: self.disposeBag)
                    controller?.dismiss(animated: true)
                })

    }

    func editAttendee(withModel model: CalendarManagerModel, index: Int) {
        guard let calendarMember = model.calendarMembers[safeIndex: index] else {
            assertionFailureLog()
            return
        }
        let controller = ShareMemberViewController(member: calendarMember, deleteMember: { [unowned self] in
            model.calendarMembers[index].status = .removed
            self.update(withModel: model)
        }) { [unowned self] (newAccessRole) in
            var newMember = model.calendarMembers[index]
            newMember.accessRole = newAccessRole
            model.calendarMembers[index] = newMember
            CalendarTracer
                .shareInstance
                .calCalEditMemberPermission(memberType: .init(isGroup: newMember.isGroup),
                                            calMemberPermission: .init(accessRole: newAccessRole))
            self.update(withModel: model)
        }
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
