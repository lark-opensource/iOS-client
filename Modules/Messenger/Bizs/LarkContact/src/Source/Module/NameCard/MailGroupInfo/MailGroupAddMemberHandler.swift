//
//  MailGroupAddMemberHandler.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/11/9.
//

import Foundation
import RxCocoa
import RxSwift
import LarkSDKInterface
import RustPB
import LarkContainer
import ServerPB
import LarkMessengerInterface

typealias MailGroupPcikerCallback = (_ error: Error?,
                                     _ reachLimit: [GroupInfoMemberItem]?,
                                     _ noDepartmentPerm: Bool) -> Void

protocol MailGroupPickerAddHandler {
    func handleContactPickResult(_ result: ContactPickerResult, complete: @escaping MailGroupPcikerCallback)
}

/// 添加邮件组成员
final class MailGroupPickerMemberHandler: MailGroupPickerAddHandler {
    let nameCardAPI: NamecardAPI
    let groupId: Int
    let accountId: String
    let disposeBag = DisposeBag()

    init(groupId: Int, accountId: String, nameCardAPI: NamecardAPI) {
        self.groupId = groupId
        self.accountId = accountId
        self.nameCardAPI = nameCardAPI
    }

    var roleType: MailGroupRole {
        return .member
    }

    func handleContactPickResult(_ result: ContactPickerResult, complete: @escaping MailGroupPcikerCallback) {
        createMemberPB(pickerResult: result).flatMap { [weak self] members -> Observable<MailGroupUpdateResponse> in
            guard let self = self else { return .empty() }
            return self.nameCardAPI.updateMailGroupInfo(self.groupId,
                                                        accountID: self.accountId,
                                                        permission: nil,
                                                        addMember: members,
                                                        deletedMember: nil,
                                                        addManager: nil,
                                                        deletedManager: nil,
                                                        addPermissionMember: nil,
                                                        deletePermissionMember: nil)
        }.subscribe(onNext: { resp in
            if resp.code == .success {
                complete(nil, nil, false)
            } else if resp.code == .canNotUseDepartmentAsMember {
                complete(nil, nil, true)
            } else {
                complete(nil, resp.reachLimitManagers, false)
            }
        }) { error in
            complete(error, nil, false)
        }.disposed(by: disposeBag)
    }

    private func createMemberPB(pickerResult: ContactPickerResult) -> Observable<[Email_Client_V1_MailGroupMember]> {
        var memberItem: [Email_Client_V1_MailGroupMember] = []
        for item in pickerResult.chatterInfos {
            var temp = Email_Client_V1_MailGroupMember()
            temp.memberID = Int64(item.ID) ?? 0
            if !item.email.isEmpty {
                temp.mailAddress = item.email
            }
            temp.memberType = .groupUser
            memberItem.append(temp)
        }
        for item in pickerResult.departments {
            var temp = Email_Client_V1_MailGroupMember()
            temp.memberID = Int64(item.id) ?? 0
            temp.memberType = .department
            memberItem.append(temp)
        }
        for item in pickerResult.mailContacts where item.type == .sharedMailbox {
            var temp = Email_Client_V1_MailGroupMember()
            temp.memberID = Int64(item.entityId) ?? 0
            temp.memberType = .sharedAccount
            if !item.email.isEmpty {
                temp.mailAddress = item.email
            }
            memberItem.append(temp)
        }
        if pickerResult.mails.isEmpty {
            return .just(memberItem)
        } else {
            return nameCardAPI.getEmailsMembersInfo(groupId: groupId, email: pickerResult.mails).map { list -> [Email_Client_V1_MailGroupMember] in
                let mails = list.map { temp -> Email_Client_V1_MailGroupMember in
                    var item = Email_Client_V1_MailGroupMember()
                    item.memberID = temp.memberID
                    item.memberType = temp.memberType.clientPB
                    item.mailAddress = temp.mailAddress
                    item.name = temp.name
                    item.memberBizID = temp.memberBizID
                    return item
                }
                memberItem.append(contentsOf: mails)
                return memberItem
            }
        }
    }
}

/// 添加邮件组管理员
final class MailGroupPickerManagerHandler: MailGroupPickerAddHandler {
    let nameCardAPI: NamecardAPI
    let groupId: Int
    let accountId: String
    let disposeBag = DisposeBag()

    init(groupId: Int, accountId: String, nameCardAPI: NamecardAPI) {
        self.groupId = groupId
        self.accountId = accountId
        self.nameCardAPI = nameCardAPI
    }

    var roleType: MailGroupRole {
        return .manager
    }

    func handleContactPickResult(_ result: ContactPickerResult, complete: @escaping MailGroupPcikerCallback) {
        createMemberPB(pickerResult: result).flatMap { [weak self] members -> Observable<MailGroupUpdateResponse> in
            guard let self = self else { return .empty() }
            return self.nameCardAPI.updateMailGroupInfo(self.groupId,
                                                        accountID: self.accountId,
                                                        permission: nil,
                                                        addMember: nil,
                                                        deletedMember: nil,
                                                        addManager: members,
                                                        deletedManager: nil,
                                                        addPermissionMember: nil,
                                                        deletePermissionMember: nil)
        }.subscribe(onNext: { resp in
                if resp.code == .success {
                    complete(nil, nil, false)
                } else if resp.code == .canNotUseDepartmentAsMember {
                    complete(nil, nil, true)
                } else {
                    complete(nil, resp.reachLimitManagers, false)
                }
            }) { error in
                complete(error, nil, false)
        }.disposed(by: disposeBag)
    }

    private func createMemberPB(pickerResult: ContactPickerResult) -> Observable<[Email_Client_V1_MailGroupManager]> {
        var memberItem: [Email_Client_V1_MailGroupManager] = []
        for item in pickerResult.chatterInfos {
            var temp = Email_Client_V1_MailGroupManager()
            temp.userID = Int64(item.ID) ?? 0
            memberItem.append(temp)
        }
        for item in pickerResult.departments {
            var temp = Email_Client_V1_MailGroupManager()
            temp.userID = Int64(item.id) ?? 0
            memberItem.append(temp)
        }
        for item in pickerResult.mailContacts where item.type == .sharedMailbox {
            var temp = Email_Client_V1_MailGroupManager()
            temp.userID = Int64(item.entityId) ?? 0
            memberItem.append(temp)
        }
        return .just(memberItem)
    }
}

/// 添加邮件组权限成员
final class MailGroupPickerPermissionHandler: MailGroupPickerAddHandler {
    let nameCardAPI: NamecardAPI
    let groupId: Int
    let accountId: String
    let disposeBag = DisposeBag()

    init(groupId: Int, accountId: String, nameCardAPI: NamecardAPI) {
        self.groupId = groupId
        self.accountId = accountId
        self.nameCardAPI = nameCardAPI
    }

    var roleType: MailGroupRole {
        return .permission
    }

    func handleContactPickResult(_ result: ContactPickerResult, complete: @escaping MailGroupPcikerCallback) {
        createMemberPB(pickerResult: result).flatMap { [weak self] members -> Observable<MailGroupUpdateResponse> in
            guard let self = self else { return .empty() }
            return self.nameCardAPI.updateMailGroupInfo(self.groupId,
                                                        accountID: self.accountId,
                                                        permission: .custom,
                                                        addMember: nil,
                                                        deletedMember: nil,
                                                        addManager: nil,
                                                        deletedManager: nil,
                                                        addPermissionMember: members,
                                                        deletePermissionMember: nil)
        }.subscribe(onNext: { resp in
                if resp.code == .success {
                    complete(nil, nil, false)
                } else if resp.code == .canNotUseDepartmentAsMember {
                    complete(nil, nil, true)
                } else {
                    complete(nil, resp.reachLimitManagers, false)
                }
            }) { error in
                complete(error, nil, false)
        }.disposed(by: disposeBag)
    }

    private func createMemberPB(pickerResult: ContactPickerResult) -> Observable<[Email_Client_V1_MailGroupPermissionMember]> {
        var memberItem: [Email_Client_V1_MailGroupPermissionMember] = []
        for item in pickerResult.chatterInfos {
            var temp = Email_Client_V1_MailGroupPermissionMember()
            temp.memberID = Int64(item.ID) ?? 0
            temp.memberType = .groupUser
            memberItem.append(temp)
        }
        for item in pickerResult.departments {
            var temp = Email_Client_V1_MailGroupPermissionMember()
            temp.memberID = Int64(item.id) ?? 0
            temp.memberType = .department
            memberItem.append(temp)
        }
        for item in pickerResult.mailContacts where item.type == .sharedMailbox {
            var temp = Email_Client_V1_MailGroupPermissionMember()
            temp.memberID = Int64(item.entityId) ?? 0
            temp.memberType = .sharedAccount
            memberItem.append(temp)
        }
        return .just(memberItem)
    }
}

extension ServerPB_Mail_entities_MemberType {
    var clientPB: Email_Client_V1_GroupMemberType {
        switch self {
        case .lakrGroup:
            return .larkGroup
        case .larkCalendar:
            return .larkCalendar
        case .contact:
            return .contact
        case .user:
            return .groupUser
        case .mailingList:
            return .mailingList
        case .department:
            return .department
        case .externalContact:
            return .externalContact
        case .company:
            return .company
        case .sharedAccount:
            return .sharedAccount
        case .userGroup:
            return .userGroup
        case .dynamicUserGroup:
            return .dynamicUserGroup
        case .unknownMemberType:
            return .unknownMemberType
        @unknown default:
            // TODO: @liutefeng
            return .unknownMemberType
        }
    }
}
