//
//  CollaboratorInviteViewController+Biz.swift
//  SKCommon
//
//  Created by liweiye on 2020/9/6.
//

import Foundation
import UIKit
import SwiftyJSON
import LarkLocalizations
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignToast
import UniverseDesignDialog
import UniverseDesignColor

extension CollaboratorInviteViewController {

    public func fetchUserPermissions() {
        if fileModel.isFormV1 {
            fetchFormUserPermissions(completion: nil)
        } else if fileModel.isBitableSubShare {
            asyncUpdateBitableUserPermissions()
        } else if fileModel.isFolder {
            fetchShareFolderUserPermissions(completion: nil)
        } else {
            fetchFileUserPermissions(completion: nil)
        }
    }

    // 表单-获取用户权限
    private func fetchFormUserPermissions(completion: ((Bool, Error?) -> Void)?) {
        guard let formMeta = fileModel.formMeta else {
            spaceAssertionFailure()
            DocsLogger.warning("InviteViewController form meta is nil")
            return
        }
        let token = fileModel.objToken
        let tableId = formMeta.tableId
        let viewId = formMeta.viewId
        permissionManager.fetchFormUserPermissions(token: token, tableID: tableId, viewId: viewId) { [weak self] mask, error in
            guard let self = self else { return }
            guard let mask = mask else {
                DocsLogger.error("InviteViewController form fetch form user permission failed", error: error, component: LogComponents.permission)
                completion?(false, error)
                return
            }
            DocsLogger.info("InviteViewController form fetch form user permission success", component: LogComponents.permission)
            self.userPermissions = mask
            completion?(true, nil)
        }
    }
    
    private func asyncUpdateBitableUserPermissions() {
        guard let bitableEntity = fileModel.bitableShareEntity else {
            spaceAssertionFailure()
            DocsLogger.error("InviteViewController bitable info is nil")
            return
        }
        permissionManager.fetchBibtaleUserPermissions(
            token: fileModel.objToken,
            tableID: bitableEntity.param.tableId,
            viewId: bitableEntity.param.viewId,
            shareType: bitableEntity.param.shareType
        ) { [weak self] permissionMask, error in
            guard let self = self else {
                return
            }
            guard let permissionMask = permissionMask else {
                DocsLogger.error("update user permission failed", error: error, component: LogComponents.permission)
                return
            }
            DocsLogger.info("update user permission success", component: LogComponents.permission)
            self.userPermissions = permissionMask
        }
    }

    // 文档-获取用户权限
    private func fetchFileUserPermissions(completion: ((Bool, Error?) -> Void)?) {
        let token = fileModel.objToken
        let type = fileModel.docsType.rawValue
        permissionManager.fetchUserPermissions(token: token, type: type) { [weak self] info, error in
            guard let self = self else { return }
            guard let info = info, let mask = info.mask else {
                completion?(false, error)
                DocsLogger.error("InviteViewController file fetch user permission failed", error: error, component: LogComponents.permission)
                return
            }
            DocsLogger.info("InviteViewController file fetch user permission success", component: LogComponents.permission)
            self.userPermissions = mask
            completion?(true, nil)
        }
    }

    // 共享文件夹-获取用户权限
    private func fetchShareFolderUserPermissions(completion: ((Bool, Error?) -> Void)?) {
        if fileModel.isV2Folder {
            let token = fileModel.objToken
            permissionManager.requestShareFolderUserPermission(token: token, actions: []) { [weak self] (permissions, error) in
                guard let self = self else { return }
                guard let permissions = permissions, error == nil else {
                    DocsLogger.error("InviteViewController fetch v2 folder user permission failed (sc)", error: error, component: LogComponents.permission)
                    completion?(false, error)
                    return
                }
                DocsLogger.info("InviteViewController fetch v2 folder user permission success (sc)", component: LogComponents.permission)
                self.userPermissions = permissions
                completion?(true, nil)
            }
        } else {
            if fileModel.isCommonFolder {
                DocsLogger.info("InviteViewController file is isCommonFolder, use mock permisson", component: LogComponents.permission)
                self.userPermissions = UserPermissionMask.mockPermisson()
                completion?(true, nil)
            } else {
                let spaceID = fileModel.spaceID
                permissionManager.getShareFolderUserPermissionRequest(spaceID: spaceID, token: fileModel.objToken) { [weak self] (permissions, error) in
                    guard let self = self else { return }
                    guard let permissions = permissions, error == nil else {
                        completion?(false, error)
                        DocsLogger.error("InviteViewController fetch share folder user permission failed", error: error, component: LogComponents.permission)
                        return
                    }
                    DocsLogger.info("InviteViewController fetch share folder user permission success", component: LogComponents.permission)
                    self.userPermissions = permissions
                    completion?(true, nil)
                }
            }
        }
    }
}

extension CollaboratorInviteViewController {

    // 无分享权限、链接分享on 发送链接
    func sendLinkForInviteCollaborator(larkIMText: String? = nil) {
        self.loading()
        self.fileInviteRequest = permissionManager.sendLinkForInviteCollaborator(
            type: self.fileModel.docsType.rawValue,
            token: self.fileModel.objToken,
            candidates: Set(self.items),
            larkIMText: larkIMText,
            complete: { [weak self] (json, err) in
                guard let self = self else { return }
                self.hideLoadingView()
                if let error = err {
                    DocsLogger.info(error.localizedDescription)
                    if let netError = (error as? DocsNetworkError) {
                        self.showToast(text: netError.errorMsg, type: .failure)
                    } else {
                        self.showToast(text: BundleI18n.SKResource.Doc_Permission_SendFailed, type: .failure)
                    }
                    return
                }
                guard let json = json else {
                    self.showToast(text: BundleI18n.SKResource.Doc_Permission_SendFailed, type: .failure)
                    DocsLogger.info("response is nil")
                    return
                }
                guard let code = json["code"].int else {
                    DocsLogger.info("parseSendlink code is not exist")
                    self.showToast(text: BundleI18n.SKResource.Doc_Permission_SendFailed, type: .failure)
                    return
                }
                if code == 0 {
                    self.showSuccessTips(text: BundleI18n.SKResource.Doc_Permission_SendSuccess)
                } else {
                    let utils = CollaboratorBlockStatusManager(requestType: .sendLink, fromView: UIViewController.docs.topMost(of: self)?.view, statistics: self.inviteVM.statistics)
                    utils.showSendLinkFailedToast(json, isFolder: self.fileModel.isFolder)
                    guard self.navigationBar.leadingBarButtonItem != nil else { return }
                    self.backBarButtonItemAction()
                }
            })
        sendLinkForInviteCollaboratorStatistics()
    }

    // 无分享权限、链接分享off 请求所有者共享
    func askOwnerForInviteCollaborator(larkIMText: String? = nil, dispalyName: String) {
        self.askOwnerRequest = permissionManager.askOwnerForInviteCollaborator(
            type: self.fileModel.docsType.rawValue,
            token: self.fileModel.objToken,
            candidates: Set(self.items),
            larkIMText: larkIMText,
            complete: { [weak self] (json, response, err) in
                guard let self = self else { return }
                self.hideLoadingView()

                if let response = response as? HTTPURLResponse, response.statusCode == 429 {
                    //请求频控，超过最大申请次数
                    self.showToast(text: BundleI18n.SKResource.Doc_Permission_SendRequestMaxCount, type: .failure)
                    return
                }
                
                if let error = err {
                    DocsLogger.info(error.localizedDescription)
                    if let netError = (error as? DocsNetworkError) {
                        self.showToast(text: netError.errorMsg, type: .failure)
                    } else {
                        self.showToast(text: BundleI18n.SKResource.Doc_Permission_SendApplyFailed, type: .failure)
                    }
                    return
                }
                guard let json = json else {
                    self.showToast(text: BundleI18n.SKResource.Doc_Permission_SendApplyFailed, type: .failure)
                    DocsLogger.info("response is nil")
                    return
                }
                guard let code = json["code"].int else {
                    DocsLogger.info("parse ask owner code is not exist")
                    self.showToast(text: BundleI18n.SKResource.Doc_Permission_SendApplyFailed, type: .failure)
                    return
                }
                if code == 0 {
                    self.showSuccessTips(text: BundleI18n.SKResource.Doc_Permission_SendApplySuccess)
                } else {
                    //迁移过程中，禁止写入
                    if code == ExplorerErrorCode.dataUpgradeLocked.rawValue {
                        self.showToast(text: BundleI18n.SKResource.CreationMobile_DataUpgrade_Locked_toast, type: .failure)
                        return
                    }
                    /// 判断是否有owner不在的群
                    if let dict = json.dictionaryObject,
                       let data = dict["data"] as? [String: Any] {
                        let ownerNotInGroupStr = self.parseOwnerNotInGroupName(data: data)
                        if !ownerNotInGroupStr.isEmpty {
                            let typeString: String = (self.fileModel.docsType == .minutes) ? BundleI18n.SKResource.CreationMobile_Minutes_name : BundleI18n.SKResource.Doc_Facade_Document
                            self.showToast(text: BundleI18n.SKResource.CreatinoMobile_Minutes_request_unable(typeString, ownerNotInGroupStr), type: .failure)
                            return
                        }
                    }
                    
                    let utils = CollaboratorBlockStatusManager(requestType: .askOwner,
                                                               fromView: UIViewController.docs.topMost(of: self)?.view,
                                                               statistics: self.inviteVM.statistics)
                    utils.showAskOwnerFailedToast(json, ownerName: dispalyName, isFolder: self.fileModel.isFolder)
                    // 失败是否需要退出邀请页面
                }
            })
        askOwnerForInviteCollaboratorStatistics()
    }
    
    /// 判断邀请的协作者中哪些是有owner不在的群，并返回群名称
    private func parseOwnerNotInGroupName(data: [String: Any]) -> String {
        // 根据后台fail_members字段中错误码"10027"，判断邀请的协作者中哪些是有owner不在的群
        let ownerNotInGroupCode = String(CollaboratorBlockStatusManager.ResponseCode.ownerNotInGroup.rawValue)
        if let failMembersDict = data["fail_members"] as? [String: Any],
           let failMembers = failMembersDict[ownerNotInGroupCode] as? [[String: Any]],
           !failMembers.isEmpty {
            var ownerNotInGroupStr = ""
            failMembers.forEach { (member) in
                if let userId = member["owner_id"] as? String,
                   let name = self.getCollaboratorName(with: userId) {
                    ownerNotInGroupStr += ownerNotInGroupStr.isEmpty ? "\(name)" : ",\(name)"
                }
            }
            return ownerNotInGroupStr
        }
        return ""
    }
    
    func getCollaboratorName(with userId: String) -> String? {
        let collaborator = items.first { $0.userID == userId }
        return collaborator?.name
    }
    
    // suite 添加协作者请求
    func inviteForBiz(collaboratorSource: CollaboratorSource, larkIMText: String? = nil) {
        let notify = hasEmailCollaborator ? true : self.collaboratorBottomView.isSelect

        self.loading()
        let requestContext = CollaboratorsRequest(type: self.fileModel.docsType.rawValue, token: self.fileModel.objToken, candidates: Set(self.items), notify: notify, larkIMText: larkIMText, collaboratorSource: collaboratorSource)
        self.fileInviteRequest = PermissionManager.inviteCollaboratorsRequest(
            context: requestContext,
            notifyType: (self.inviteVM.source == .diyTemplate) ? .bot : .im) { [weak self] (result: JSON?, error: Error?) in
                let error = error as NSError?
                let statusCode = error?.code ?? 0
                let statusName = error?.localizedDescription ?? "success"
                
                guard let self = self else { return }
                self.clickSendInviteBtnStatistics(statusCode: statusCode, statusName: statusName)
                self.checkIfNeedReportForTemplateShare()
                self.hideLoadingView()
                guard let json = result else {
                    self.showToast(text: BundleI18n.SKResource.Doc_Share_CollaboratorInvite + BundleI18n.SKResource.Doc_AppUpdate_FailRetry, type: .failure)
                    DocsLogger.info(error?.localizedDescription ?? "")
                    return
                }
                defer {
                    let refreshCollaboratorsNotification = Notification(name: Notification.Name.Docs.refreshCollaborators)
                    NotificationCenter.default.post(refreshCollaboratorsNotification)
                }
                let data = json["data"]
                let notNotiCollaborators = data["not_notify_users"].arrayValue
                let code = json["code"].intValue

                guard code == 0 else {
                    self.handleInviteCollaboratorsError(json: json)
                    return
                }
                self.checkIfNeedBlockNotifyCollaborator(json: json)
                
                /// cac管控: 这里是部分失败，全部失败会走上面code != 0 的逻辑
                let result = CollaboratorBlockStatusManager.getInviteResultsByCacBlocked(json: json)
                if result != .noFail {
                    DocsLogger.info("inviteForBiz blocked by cac")
                    self.showCacBlockedTips(result: result)
                    return
                }
                
                if let names = self.getAllNotNotiCollaboratorNames(users: notNotiCollaborators) {
                    self.showNotNotifyUserTips(names: names)
                    return
                }
                if let names = CollaboratorBlockStatusManager.getAllNotPartnerTenantCollaboratorNames(json: json) {
                    self.showPartialSuccessTips(names: names)
                    return
                }
                self.showSuccessTips()
        }
    }

    // Bitable 添加协作者请求
    func inviteForBitable(larkIMText: String? = nil) {
        let notify = self.collaboratorBottomView.isSelect
        let shareToken: String
        if fileModel.isFormV1 {
            shareToken = fileModel.formMeta?.shareToken ?? ""
        } else if fileModel.isBitableSubShare {
            shareToken = fileModel.bitableShareEntity?.meta?.shareToken ?? ""
        } else {
            spaceAssertionFailure("non-bitable invite!")
            DocsLogger.error("invite is not for bitable type")
            return
        }

        self.loading()
        self.fileInviteRequest = PermissionManager.inviteBitableCollaboratorsRequest(
            shareToken: shareToken,
            candidates: Set(self.items),
            notify: notify) { [weak self] (result: JSON?, error: Error?) in
                let error = error as NSError?
                let statusCode = error?.code ?? 0
                let statusName = error?.localizedDescription ?? "success"

                guard let self = self else { return }
                self.clickSendInviteBtnStatistics(statusCode: statusCode, statusName: statusName)
                self.checkIfNeedReportForTemplateShare()
                self.hideLoadingView()
                guard let json = result else {
                    self.showToast(text: BundleI18n.SKResource.Doc_Share_CollaboratorInvite + BundleI18n.SKResource.Doc_AppUpdate_FailRetry, type: .failure)
                    DocsLogger.info(error?.localizedDescription ?? "")
                    return
                }
                let data = json["data"]
                let notNotiCollaborators = data["not_notify_users"].arrayValue
                let code = json["code"].intValue

                guard code == 0 else {
                    self.handleInviteCollaboratorsError(json: json)
                    return
                }
                if let names = self.getAllNotNotiCollaboratorNames(users: notNotiCollaborators) {
                    self.showNotNotifyUserTips(names: names)
                    return
                }
                self.showSuccessTips()
                let refreshCollaboratorsNotification = Notification(name: Notification.Name.Docs.refreshCollaborators)
                NotificationCenter.default.post(refreshCollaboratorsNotification)
        }
    }
    
    ///cac 管控提示
    func showCacBlockedTips(result: InviteResultsByCacBlocked) {
        let content = (result == .allFail) ? BundleI18n.SKResource.LarkCCM_Workspace_ConAccess_InviteFail_Tooltip : BundleI18n.SKResource.LarkCCM_Workspace_ConAccess_InviteCtCollabFail_Toast
        
        let config = UDDialogUIConfig()
        config.contentMargin = .zero
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Workspace_ConAccess_ShareFail_Title)
        dialog.setContent(text: content)
//        dialog.addPrimaryButton(text: BundleI18n.SKResource.LarkCCM_Workspace_ConAccess_GotIt_Button, color: UDColor.primaryContentDefault)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.LarkCCM_Workspace_ConAccess_GotIt_Button, dismissCompletion:  { [weak self] in
            guard let self = self else { return }
            self.backBarButtonItemAction()
        })
        present(dialog, animated: true, completion: nil)
    }
    
    // 高管屏蔽通知
    func showNotNotifyUserTips(names: String) {
        let hintTips = BundleI18n.SKResource.Doc_Permission_NotNotifyTip(BundleI18n.SKResource.Doc_Share_AddCollaboratorSuccessfully, BundleI18n.SKResource.Doc_Permission_AdminSetting, names)
        self.showToast(text: hintTips, type: .tips)
        self.backBarButtonItemAction()
        return
    }

    func showPartialSuccessTips(names: String) {
        let hintTips: String
        if fileModel.isFolder {
            hintTips = BundleI18n.SKResource.CreationMobile_ECM_Security_Conflict_Confirm_Scenario9(names)
        } else {
            hintTips = BundleI18n.SKResource.CreationMobile_ECM_Security_Conflict_Confirm_Scenario6(names)
        }
        self.showToast(text: hintTips, type: .tips)
        self.backBarButtonItemAction()
    }

    func showSuccessTips(text: String) {
        self.showToast(text: text, type: .success)
        self.backBarButtonItemAction()
    }

    func showSuccessTips() {
        var text = BundleI18n.SKResource.Doc_Share_CollaboratorInvite + BundleI18n.SKResource.Doc_Normal_Success
        if inviteVM.source == .diyTemplate {
            text = BundleI18n.SKResource.Doc_List_ShareCustomTempSuccess
        }
        self.showToast(text: text, type: .success)
        self.backBarButtonItemAction()
    }
}

extension CollaboratorInviteViewController {
    private func checkIfNeedReportForTemplateShare() {
        guard inviteVM.source == .diyTemplate, let templateMainType = fileModel.templateMainType else { return }
        TemplateCenterTracker.reportManagementTemplateByUser(action: .share, templateMainType: templateMainType)
    }
    
    private func checkIfNeedBlockNotifyCollaborator(json: JSON) {
        guard let blockMap = json["data"]["block_notification_collaborator_map"].dictionaryObject else {
            shouldShowBlockNotifyCollaboratorTips = false
            return
        }
        for code in blockMap.keys where code == "10045" {
            shouldShowBlockNotifyCollaboratorTips = true
            return
        }
        shouldShowBlockNotifyCollaboratorTips = false
    }
}
