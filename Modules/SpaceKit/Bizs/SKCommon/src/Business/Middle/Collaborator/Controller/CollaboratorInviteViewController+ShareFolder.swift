//
//  CollaboratorInviteViewController+ShareFolder.swift
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
import SKInfra

extension CollaboratorInviteViewController {
    // 文件夹邀请协作者
    func inviteForFolder(shouldContainPermssion: Bool = false, larkIMText: String? = nil) {
        if fileModel.spaceSingleContainer {
            inviteCollaboratorForFolderV2(shouldContainPermssion: shouldContainPermssion, larkIMText: larkIMText)
        } else {
            let larkInform = self.collaboratorBottomView.isSelect
            let larkIMText = self.collaboratorBottomView.textView.text
            self.loading()
            self.folderInviteRequest = PermissionManager.addFolderCollaboratorsRequest(
                spaceID: self.fileModel.spaceID,
                token: self.fileModel.objToken,
                candidates: Set(self.items),
                containPermssion: shouldContainPermssion,
                sendLarkIm: larkInform,
                larkIMText: larkIMText) { [weak self] (data, error) in
                guard let self = self else { return }
                self.hideLoadingView()
                self.handleInviteCollaboratorForFolderResopnse(data: data, error: error)
            }
        }
    }
    
    // 单容器文件夹邀请协作者
    func inviteCollaboratorForFolderV2(shouldContainPermssion: Bool = false, larkIMText: String? = nil) {
        let botNotify = self.collaboratorBottomView.isSelect
        let note = self.collaboratorBottomView.textView.text
        let objToken = self.fileModel.objToken
        self.loading()
        
        self.folderInviteRequest = PermissionManager.inviteCollaboratorForFolder(
            token: objToken,
            candidates: Set(self.items),
            botNotify: botNotify,
            note: note,
            complete: { [weak self](data, error) in
                guard let self = self else { return }
                self.hideLoadingView()
                self.handleInviteCollaboratorForFolderResopnse(data: data, error: error)
            })
    }
    
    private func handleInviteCollaboratorForFolderResopnse(data: (Bool, JSON?)?, error: Error?) {
        let error = error as NSError?
        let statusCode = error?.code ?? 0
        let statusName = error?.localizedDescription ?? "success"
        let folderName = error?.domain ?? ""
        
        /// 不支持邀请外部协作者
        if statusCode == ExplorerErrorCode.notSupportInviteExternal.rawValue {
            if User.current.info?.isToC == true {
                self.showToast(text: BundleI18n.SKResource.Doc_Share_NotSupportEnterpriseUser, type: .failure)
            } else {
                self.showToast(text: BundleI18n.SKResource.Doc_Share_NotSupportExternalUser, type: .failure)
            }
            return
        }
        self.clickSendInviteBtnStatistics(statusCode: statusCode, statusName: statusName)

        /// error code判断
        if let errorCode = ExplorerErrorCode(rawValue: statusCode) {
            let errorEntity = ErrorEntity(code: errorCode, folderName: folderName)
            self.showToast(text: errorEntity.wording, type: .failure)
            return
        }
        
        ///code != 0
        guard let newData = data, newData.0 == true else {
            guard let json = data?.1 else { return }
            let manager = CollaboratorBlockStatusManager(requestType: .inviteCollaboratorsForFolder, fromVC: self,
                                                         fromView: UIViewController.docs.topMost(of: self)?.view, statistics: self.inviteVM.statistics)
            manager.delegate = self
            manager.showInviteCollaboratorsForFolderFailedToast(json)
            return
        }
        
        /// code == 0
        guard let json = newData.1 else { return }
        
        
        ///通知外部更新
        let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
        let refreshPersonFileNotification = Notification(name: Notification.Name.Docs.RefreshPersonFile)
        let refreshCollaboratorsNotification = Notification(name: Notification.Name.Docs.refreshCollaborators)
        NotificationCenter.default.post(refreshCollaboratorsNotification)
        NotificationCenter.default.post(refreshPersonFileNotification)
        dataCenterAPI?.refreshListData(of: .sharedFolders, completion: nil)
        
        /// cac管控  提示：部分成功的提示,全部失败的场景走上面code!=0的逻辑
        if let names = CollaboratorBlockStatusManager.getAllCacBlockedCollaboratorNames(json: json) {
            self.showCacBlockedTips(result: .partFail)
            return
        }

        /// 提示： 不发送通知的用户名单
        if let names = self.getAllNotNotiCollaboratorNames(users: json["data"]["not_notify_users"]) {
            self.showNotNotifyUserTips(names: names)
            return
        }
        /// 提示：部分成功的提示 （非关联组织的外部用户邀请失败）
        if let names = CollaboratorBlockStatusManager.getAllNotPartnerTenantFolderCollaboratorNames(json: json) {
            self.showPartialSuccessTips(names: names)
            return
        }
        
        self.backBarButtonItemAction()
        self.showToast(text: BundleI18n.SKResource.Doc_Share_CollaboratorInvite + BundleI18n.SKResource.Doc_Normal_Success, type: .success)
    }
}

extension CollaboratorInviteViewController: CollaboratorBlockStatusManagerDelegate {
    func showInviteFolderCollaboratorCacDialog(animated: Bool, completion: (() -> Void)?) {
        self.showCacBlockedTips(result: .allFail)
    }
}
