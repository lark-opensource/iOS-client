//
//  ShareLinkEditViewController+password.swift
//  SpaceKit
//
//  Created by liweiye on 2020/6/11.
//

import Foundation
import SKInfra
import SKFoundation
import SKResource
import SKUIKit
import SwiftyJSON
import UniverseDesignToast

// 链接共享密码
extension ShareLinkEditViewController {
    
    func startLoading() {
        UDToast.docs.showMessage(BundleI18n.SKResource.Doc_Facade_Loading, on: self.view, msgType: .loading)
    }

    func stopLoading() {
        UDToast.removeToast(on: self.view)
    }

    private func handleError(json: JSON?, inputText: String) {
        guard let json = json else {
            self.showToast(text: inputText, type: .failure)
            return
        }
        let code = json["code"].intValue
        if let errorCode = ExplorerErrorCode(rawValue: code) {
            let errorEntity = ErrorEntity(code: errorCode, folderName: "")
            self.showToast(text: errorEntity.wording, type: .failure)
        } else {
            self.showToast(text: inputText, type: .failure)
        }
    }
    
    /// 设置密码
    func setupPassword() {
        if shareEntity.spaceSingleContainer && shareEntity.isFolder {
            createPasswordForShareFolder()
        } else {
            startLoading()
            permissionObserver.setupPassword { [weak self] (result, json) in
                guard let self = self else { return }
                defer {
                    self.stopLoading()
                }
                switch result {
                case .success(let password):
                    guard !password.isEmpty else {
                        DocsLogger.error("setupPassword: password is empty!")
                        return
                    }
                    self.updateDataIfPassswordChanged(newHasPassword: true,
                                                      newPassword: password,
                                                      needReloadUI: true)
                    /// 刷新权限
                    self.handlePasswordChanged()
                case .failure(let error):
                    self.tableView.reloadData()
                    self.stopLoading()
                    self.handleError(json: json, inputText: BundleI18n.SKResource.Doc_Facade_OperateFailed)
                    DocsLogger.error("setupPassword failed", extraInfo: nil, error: error, component: nil)
                }
            }
        }
    }


    
    /// 删除密码
    func deletePassword() {
        if shareEntity.spaceSingleContainer && shareEntity.isFolder {
            deletePasswordForShareFolder()
        } else {
            startLoading()
            permissionObserver.deletePassword { [weak self] result, json in
                guard let self = self else { return }
                defer {
                    self.stopLoading()
                }
                switch result {
                case .success:
                    self.updateDataIfPassswordChanged(newHasPassword: false,
                                                      newPassword: "",
                                                      needReloadUI: true)
                    /// 刷新权限
                    self.handlePasswordChanged()
                    DocsLogger.info("delete password success!")
                case .failure(let error):
                    self.tableView.reloadData()
                    self.stopLoading()
                    self.handleError(json: json, inputText: BundleI18n.SKResource.Doc_Facade_OperateFailed)
                    DocsLogger.error("delete password failed!", extraInfo: nil, error: error, component: nil)
                }
            }
        }
    }
    
    /// 刷新密码
    func refreshPassword() {
        if shareEntity.spaceSingleContainer && shareEntity.isFolder {
            refreshPasswordForShareFolder()
        } else {
            startLoading()
            permissionObserver.refreshPassword { [weak self] (result, json) in
                guard let self = self else { return }
                self.stopLoading()
                switch result {
                case .success(let password):
                    guard !password.isEmpty else {
                        DocsLogger.error("setupPassword: password is empty!")
                        return
                    }
                    self.updateDataIfPassswordChanged(newHasPassword: true,
                                                      newPassword: password,
                                                      needReloadUI: true)
                    /// 刷新权限
                    self.handlePasswordChanged {
                        self.showToast(text: BundleI18n.SKResource.Doc_Share_ChangePasswordSuccess, type: .success)
                    }
                case .failure(let error):
                    self.handleError(json: json, inputText: BundleI18n.SKResource.Doc_Facade_OperateFailed)
                    DocsLogger.error("refreshPassword failed", extraInfo: nil, error: error, component: nil)
                }
            }
        }
    }
    
    /// 复制链接和密码
    func copyLinkAndPassword(with password: String) {
        guard !password.isEmpty else {
            self.showToast(text: BundleI18n.SKResource.Doc_Doc_CopyFailed, type: .failure)
            return
        }
        let shareURL = shareEntity.shareUrl
        guard !shareURL.isEmpty else {
            self.showToast(text: BundleI18n.SKResource.Doc_Doc_CopyFailed, type: .failure)
            DocsLogger.error("shareURL is nil!")
            return
        }
        let isSuccess = SKPasteboard.setString(BundleI18n.SKResource.Doc_Facade_LinkAndPasswordText(shareURL, password),
                               psdaToken: PSDATokens.Pasteboard.docs_share_link_do_copy,
                          shouldImmunity: true)
        if isSuccess {
            self.showToast(text: BundleI18n.SKResource.Doc_Facade_CopyLinkAndPasswordSuccess, type: .success)
        }
        
    }
    
    func handlePasswordChanged(completation: (() -> Void)? = nil) {
        /// 更新本地的权限信息
        updatePermissionsIfPasswordChanged(completation: completation)
        ///通知外部更新权限
        NotificationCenter.default.post(name: Notification.Name.Docs.publicPermissonUpdate, object: nil)
    }
    
    func updatePermissionsIfPasswordChanged(completation: (() -> Void)? = nil) {
        if isFolder {
            requestFolderPublicPermission(needReloadUI: false, completation: completation)
        } else {
            fetchDocsPermission(needReloadUI: false, completation: completation)
        }
    }
    
    func updateDataIfPassswordChanged(newHasPassword: Bool, newPassword: String, needReloadUI: Bool) {
        self.hasLinkPassword = newHasPassword
        self.linkPassword = newPassword
        self.loadData()
        if needReloadUI {
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
        }
//        self.updateLinkConstraintBannerView()
    }
}

// 单容器文件夹密码新的一套协议
extension ShareLinkEditViewController {
    func createPasswordForShareFolder() {
        let token = shareEntity.objToken
        let type = shareEntity.type.rawValue
        startLoading()
        createPasswordForShareFolderRequest = PermissionManager.createPasswordForShareFolder(token: token, type: type) { [weak self] success, password, _ in
            guard let self = self else { return }
            self.stopLoading()
            if success {
                guard let password = password, !password.isEmpty else {
                    return
                }
                self.updateDataIfPassswordChanged(newHasPassword: true, newPassword: password, needReloadUI: true)
                self.handlePasswordChanged()
            } else {
                self.showToast(text: BundleI18n.SKResource.Doc_Facade_OperateFailed, type: .failure)
            }
        }
    }
    
    func refreshPasswordForShareFolder() {
        let token = shareEntity.objToken
        let type = shareEntity.type.rawValue
        startLoading()
        refreshPasswordForShareFolderRequest = PermissionManager.refreshPasswordForShareFolder(token: token, type: type) { [weak self] success, password, _ in
            guard let self = self else { return }
            self.stopLoading()
            if success {
                guard let password = password, !password.isEmpty else {
                    return
                }
                self.updateDataIfPassswordChanged(newHasPassword: true, newPassword: password, needReloadUI: false)
                let indexPath = IndexPath(item: 1, section: 1)
                guard self.tableView.cellForRow(at: indexPath) != nil else { return }
                self.tableView.reloadRows(at: [indexPath], with: .none)
                self.showToast(text: BundleI18n.SKResource.Doc_Share_ChangePasswordSuccess, type: .tips)
                self.handlePasswordChanged()
            } else {
                self.showToast(text: BundleI18n.SKResource.Doc_Facade_OperateFailed, type: .failure)
            }
        }
    }
    
    func deletePasswordForShareFolder() {
        let token = shareEntity.objToken
        let type = shareEntity.type.rawValue
        startLoading()
        deletePasswordForShareFolderRequest = PermissionManager.deletePasswordForShareFolder(token: token, type: type) { [weak self] success, _ in
            guard let self = self else { return }
            self.stopLoading()
            if success {
                self.updateDataIfPassswordChanged(newHasPassword: false, newPassword: "", needReloadUI: true)
                self.handlePasswordChanged()
            } else {
                self.tableView.reloadData()
                self.showToast(text: BundleI18n.SKResource.Doc_Facade_OperateFailed, type: .failure)
            }
        }
    }
}
