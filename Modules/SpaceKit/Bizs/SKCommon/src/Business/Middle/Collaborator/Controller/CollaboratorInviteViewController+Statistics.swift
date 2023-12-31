//
//  CollaboratorInviteViewController+Statistics.swift
//  SKCommon
//
//  Created by liweiye on 2020/9/7.
//
//  swiftlint:disable operator_usage_whitespace

import Foundation
import UIKit
import SwiftyJSON
import LarkLocalizations
import SKFoundation

/// 文档权限点位
public enum FileUserPermission: Int, CaseIterable {
    case read    = 1
    case comment = 2
    case edit    = 4
    case share   = 8
    case copy    = 16
    case export  = 32
    case print   = 64
    case fullAccess   = 1024
}

extension UserPermissionAbility {
    /// Use this array to get access to transformations such as `map` and `reduce`.
    public var array: [FileUserPermission] {
        var arr = [FileUserPermission]()
        if canView() { arr.append(.read) }
        if canComment() { arr.append(.comment) }
        if canEdit() { arr.append(.edit) }
        if canManageCollaborator() { arr.append(.share) }
        if canCopy() { arr.append(.copy) }
        if canExport() { arr.append(.export) }
        if canPrint() { arr.append(.print) }
        return arr
    }
}

extension CollaboratorInviteViewController {

    func clickSendInviteBtnStatistics(statusCode: Int, statusName: String) {
        var details = CollaboratorStatistics.InviteDetail()
        details.userCont = self.items.filter { $0.type == .user }.count
        details.charCount = self.items.filter { $0.type == .group }.count
        details.organizationCount = self.items.filter { $0.type == .organization }.count
        details.larkInform = self.collaboratorBottomView.isSelect
        details.statusCode = statusCode
        details.statusName = statusName
        details.tenantParams = self.getTenantParams()
        details.collaboratorParams = self.getParamsForSelectItems()
        details.collaborateId = self.items.map { $0.userID }.joined(separator: ",")
        details.collaborateType = self.items.map { "\($0.rawValue)" }.joined(separator: ",")
        details.collaborateTenantId = self.items.map { "\($0.tenantID ?? "")" }.joined(separator: ",")
        details.permSetAfter = self.items.map { "\($0.userPermissions.array.reduce(0) { $0 + $1.rawValue })" }.joined(separator: ",")
        details.touserAccountType = self.items.map { "\($0.accountType?.rawValue ?? "0" )" }.joined(separator: ",")
        details.shareMethodType = self.items.map { getShareMethodType(collaborator: $0) }.joined(separator: ",")
        details.relationType = self.items.map { "\(String($0.isFriend ?? false))" }.joined(separator: ",")
        self.inviteVM.statistics?.clickSendInviteBtn(info: details)
    }

    private func getShareMethodType(collaborator: Collaborator) -> String {
        return "Lark"
    }

    func reportOpenPageStatis() {
        let mode = inviteVM.modeConfig.mode
        switch mode {
        case .sendLink:
            openSendLinkPageStatis()
        case .askOwner:
            openAskOwnerPageStatistics()
        default:
            break
        }
    }

    func openSendLinkPageStatis() {
        inviteVM.statistics?.openSendLinkPageStatis(
            source: "add_cooperator",
            module: FileListStatistics.module?.rawValue ?? FileListStatistics.Module.quickaccess.rawValue,
            fileType: fileModel.docsType.name,
            fileId: fileModel.objToken)
    }
    func sendLinkForInviteCollaboratorStatistics() {
        inviteVM.statistics?.sendLinkForInviteCollaboratorStatistics(
            source: "add_cooperator",
            module: FileListStatistics.module?.rawValue ?? FileListStatistics.Module.quickaccess.rawValue,
            fileType: fileModel.docsType.name,
            fileId: fileModel.objToken)
    }

    func openAskOwnerPageStatistics() {
        inviteVM.statistics?.openAskOwnerPageStatistics(
            source: inviteVM.modeConfig.isFromSendLink ? "show_send_link" : "add_cooperator",
            module: FileListStatistics.module?.rawValue ?? FileListStatistics.Module.quickaccess.rawValue,
            fileType: fileModel.docsType.name,
            fileId: fileModel.objToken)
    }

    func askOwnerForInviteCollaboratorStatistics() {
        inviteVM.statistics?.askOwnerForInviteCollaboratorStatistics(
            source: inviteVM.modeConfig.isFromSendLink ? "show_send_link" : "add_cooperator",
            module: FileListStatistics.module?.rawValue ?? FileListStatistics.Module.quickaccess.rawValue,
            fileType: fileModel.docsType.name,
            fileId: fileModel.objToken)
    }
    
    func reportBackClick() {
        switch self.inviteVM.modeConfig.mode {
        case .manage:
            let context = ReportPermissionSelectContactClick(shareType: fileModel.docsType, click: .back, target: .noneTargetView, isAddNotes: nil, isSendNotice: nil, isAllowChildAccess: false, userList: nil)
            inviteVM.permStatistics?.reportPermissionSelectContactClick(context: context)
        case .sendLink:
            inviteVM.permStatistics?.reportPermissionSendLinkClick(click: .back, target: .noneTargetView)
        case .askOwner:
            inviteVM.permStatistics?.reportPermissionShareAskOwnerClick(click: .back, target: .noneTargetView)
        }
    }
    
    func reportPermissionInviteCollaboratorView(candidates: Set<Collaborator>) {
        let userList: [[String: Any]] = Array(candidates).map {
            return ["object_uid": DocsTracker.encrypt(id: $0.userID),
                    "collaborate_type": $0.rawValue,
                    "list_type": getPermissionSelectOption(userPermissions: $0.userPermissions).rawValue]
        }
        switch self.inviteVM.modeConfig.mode {
        case .manage:
            inviteVM.permStatistics?.reportPermissionSelectContactView(shareType: fileModel.docsType, userList: userList)
        case .sendLink:
            inviteVM.permStatistics?.reportPermissionSendLinkView(userList: userList)
        case .askOwner:
            inviteVM.permStatistics?.reportPermissionShareAskOwnerView(userList: userList)
        }
    }
    
    func reportPermissionShareAskOwnerTypeView(collaborateType: Int, objectUid: String) {
        switch self.inviteVM.modeConfig.mode {
        case .askOwner:
            inviteVM.permStatistics?.reportPermissionShareAskOwnerTypeView(collaborateType: collaborateType, objectUid: objectUid)
        default:
            break
        }
    }
    
    func reportPermissionChangeClick(click: PermissionSelectOption, collaborateType: Int, objectUid: String) {
        switch self.inviteVM.modeConfig.mode {
        case .askOwner:
            inviteVM.permStatistics?.reportPermissionShareAskOwnerTypeClick(click: click,
                                                                            target: .noneTargetView,
                                                                            collaborateType: collaborateType,
                                                                            objectUid: objectUid)
        default:
            break
        }
    }
    
    func reportInviteClick(candidates: Set<Collaborator>) {
        let isAddNotes = self.collaboratorBottomView.textView.text.count > 0
        let isSendNotice = self.collaboratorBottomView.isSelect
        let userList: [[String: Any]] = Array(candidates).map {
            return ["object_uid": DocsTracker.encrypt(id: $0.userID),
                    "collaborate_type": $0.rawValue,
                    "list_type": getPermissionSelectOption(userPermissions: $0.userPermissions).rawValue]
        }
        switch self.inviteVM.modeConfig.mode {
        case .manage:
            let context = ReportPermissionSelectContactClick(shareType: fileModel.docsType, click: .invite, target: .noneTargetView, isAddNotes: isAddNotes, isSendNotice: isSendNotice, isAllowChildAccess: collaboratorBottomView.singlePageSelected, userList: userList)
            inviteVM.permStatistics?.reportPermissionSelectContactClick(context: context)
        case .sendLink:
            inviteVM.permStatistics?.reportPermissionSendLinkClick(click: .sendLink,
                                                                   target: .noneTargetView,
                                                                   isAddNotes: isAddNotes,
                                                                   userList: userList)
        case .askOwner:
            inviteVM.permStatistics?.reportPermissionShareAskOwnerClick(click: .sendRequest,
                                                                        target: .noneTargetView,
                                                                        isAddNotes: isAddNotes,
                                                                        userList: userList)
        }
    }

    func reportPermissionOrganizationAuthorizeSendNoticeClick(isCancel: Bool, candidates: Set<Collaborator>) {
        if isCancel {
            inviteVM.permStatistics?.reportPermissionOrganizationAuthorizeSendNoticeClick(click: .cancel, target: .noneTargetView)
        } else {
            let isAddNotes = self.collaboratorBottomView.textView.text.count > 0
            let userList: [[String: Any]] = Array(candidates).map {
                return ["object_uid": DocsTracker.encrypt(id: $0.userID),
                        "collaborate_type": $0.rawValue,
                        "list_type": getPermissionSelectOption(userPermissions: $0.userPermissions).rawValue]
            }
            inviteVM.permStatistics?.reportPermissionOrganizationAuthorizeSendNoticeClick(click: .send,
                                                                                          target: .noneTargetView,
                                                                                          isAddNotes: isAddNotes,
                                                                                          userList: userList)
        }
    }

    func getPermissionSelectOption(userPermissions: UserPermissionAbility) -> PermissionSelectOption {
        var perm: PermissionSelectOption = .noAccess
        if userPermissions.canManageMeta() {
            perm = .fullAccess
        } else if userPermissions.canEdit() {
            perm = .edit
        } else if userPermissions.canView() {
            perm = .read
        } else {
            perm = .noAccess
        }
        return perm
    }
}
