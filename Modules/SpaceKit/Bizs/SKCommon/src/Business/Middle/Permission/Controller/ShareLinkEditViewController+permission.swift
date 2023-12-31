//
//  ShareLinkEditViewController+Request.swift
//  SpaceKit
//
//  Created by liweiye on 2020/6/11.
//

import Foundation
import SwiftyJSON
import SKFoundation
import SKResource
import SKUIKit
import LarkUIKit
import EENavigator
import UIKit

extension ShareLinkEditViewController {
    func showPermissonScopeSelectView(showLockTip: Bool) {
        // wiki 文件夹节点，默认选中分享 container 权限
        let defaultSelectContainer = shareEntity.type == .wikiCatalog
        let item1 = ScopeSelectItem(title: BundleI18n.SKResource.CreationMobile_Wiki_Page_Current_tab,
                                    subTitle: nil, selected: !defaultSelectContainer, scopeType: .singlePage)
        var item2SubTitle: String? 
        if showLockTip {
            item2SubTitle = BundleI18n.SKResource.CreationMobile_Wiki_Perm_ExternalShare_Current_notice
        }
        let item2 = ScopeSelectItem(title: BundleI18n.SKResource.CreationMobile_Wiki_Page_CurrentNSub_tab,
                                    subTitle: item2SubTitle,
                                    selected: defaultSelectContainer, scopeType: .container)
        let models: [ScopeSelectItem] = [item1, item2]

        let confirmCompletion: (UIViewController, PermissionScopeType) -> Void = { [weak self] controller, type in
            self?.didClickConfirm(controller, with: type, showLockState: showLockTip)
        }
        let cancelCompletion: (UIViewController, PermissionScopeType) -> Void = { [weak self] controller, type in
            self?.didClickCancel(controller, with: type, showLockState: showLockTip)
        }
        if SKDisplay.pad, isMyWindowRegularSize() {
            let viewController = IpadScopeSelectViewController(items: models)
            viewController.confirmCompletion = confirmCompletion
            viewController.cancelCompletion = cancelCompletion
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .formSheet
            Navigator.shared.present(nav, from: self)
        } else {
            let viewController = ScopeSelectViewController(items: models)
            viewController.confirmCompletion = confirmCompletion
            viewController.cancelCompletion = cancelCompletion
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .overFullScreen
            nav.transitioningDelegate = viewController.panelTransitioningDelegate
            Navigator.shared.present(nav, from: self)
        }
        permStatistics?.reportPermissionScopeChangeView()
    }

    func didClickConfirm(_ view: UIViewController, with type: PermissionScopeType, showLockState: Bool) {
        self.updateDocsPublicPermission(linkShareEntityValue: self.currentChoice,
                                        permType: (type == .container) ? .container : .singlePage)
        permStatistics?.reportPermissionScopeChangeClick(click: .confirm, triggerLocation: .linkShare, scopeOption: type == .container ? .container : .singlePage, isLock: showLockState)
    }

    func didClickCancel(_ view: UIViewController, with type: PermissionScopeType, showLockState: Bool) {
        permStatistics?.reportPermissionScopeChangeClick(click: .cancel, triggerLocation: .linkShare, scopeOption: type == .container ? .container : .singlePage, isLock: showLockState)
        ///对外分享switch开关打开了，重新刷一下
        self.tableView.reloadData()
        self.tableView.layoutIfNeeded()
    }
}



// 公共权限
extension ShareLinkEditViewController {

    /// 更新表单的公共权限
    func updateFormPublicPermission(linkShareEntityValue: ShareLinkChoice) {
        guard let meta = shareEntity.formShareFormMeta else {
            spaceAssertionFailure("meta must not nil")
            return
        }
        let shareToken = meta.shareToken
        updatePermissionRequest?.cancel()
        let params: [String: Any] = ["shareToken": shareToken,
                                     "linkShareEntity": linkShareEntityValue.rawValue]

        updatePermissionRequest = PermissionManager.updateFormPublicPermission(params: params, complete: { [weak self] (response, error) in
            guard let self = self else { return }
            guard (error as? URLError)?.errorCode != NSURLErrorCancelled, error == nil else {
                self.stopLoading()
                self.showToast(text: BundleI18n.SKResource.Doc_Facade_SetFailed, type: .failure)
                return
            }
            guard let response = response else {
                self.stopLoading()
                self.showToast(text: BundleI18n.SKResource.Doc_Facade_SetFailed, type: .failure)
                return
            }
            guard let code = response["code"].int else {
                DocsLogger.error("updatePermission failed!")
                self.stopLoading()
                self.showToast(text: BundleI18n.SKResource.Doc_Facade_SetFailed, type: .failure)
                return
            }
            guard code == 0 else {
                DocsLogger.error("updatePermission failed, error code is \(code)")
                self.stopLoading()
                self.showToast(text: BundleI18n.SKResource.Doc_Facade_SetFailed, type: .failure)
                return
            }

            self.updateSelectedState()
            self.fetchFormPublicPermission(needReloadUI: true)
        })
    }
    
    /// 更新 Bitable 分享权限
    func updateBitablePublicPermission(linkShareEntityValue: ShareLinkChoice) {
        guard let meta = shareEntity.bitableShareEntity?.meta else {
            spaceAssertionFailure("bitable meta missing")
            return
        }
        updatePermissionRequest?.cancel()
        updatePermissionRequest = PermissionManager.updateBitablePublicPermission(
            shareToken: meta.shareToken,
            linkShareEntity: linkShareEntityValue
        ) { [weak self] error in
            guard let self = self else {
                return
            }
            // stop directly?
            self.stopLoading()
            if let error = error {
                self.showToast(text: BundleI18n.SKResource.Doc_Facade_SetFailed, type: .failure)
                return
            }
            self.updateSelectedState()
            self.fetchBitablePublicPermission(needReloadUI: true)
        }
    }

    //查询表单公共权限
    func fetchFormPublicPermission(needReloadUI: Bool) {
        guard let meta = shareEntity.formShareFormMeta, !meta.shareToken.isEmpty else {
            DocsLogger.warning("meta shareToken must not nil")
            spaceAssertionFailure()
            return
        }
        permissionManager.fetchFormPublicPermissions(baseToken: shareEntity.objToken, shareToken: meta.shareToken) { [weak self] meta, err in
                guard let self = self else { return }
                defer {
                    self.stopLoading()
                }
                if let error = err {
                    DocsLogger.error("fetchAllPermission failed!", extraInfo: nil, error: error, component: nil)
                    return
                }
                guard let publicPermissionMeta = meta else {
                    DocsLogger.info("get public permission failed!")
                    return
                }
                self.publicPermissionMeta = publicPermissionMeta
                self.updateDataIfPassswordChanged(newHasPassword: publicPermissionMeta.hasLinkPassword,
                                                  newPassword: publicPermissionMeta.linkPassword,
                                                  needReloadUI: needReloadUI)
                DocsLogger.info("更新文档公共权限成功, publicPermissionMeta: \(publicPermissionMeta)")
        }
    }
    
    /// 查询 Bitable 分享范围
    func fetchBitablePublicPermission(needReloadUI: Bool) {
        guard let param = shareEntity.bitableShareEntity?.param, let meta = shareEntity.bitableShareEntity?.meta else {
            DocsLogger.error("bitable share info missing")
            spaceAssertionFailure()
            return
        }
        DocsLogger.info("fetch bitable share permission start")
        permissionManager.fetchBitablePublicPermissions(
            baseToken: param.baseToken,
            shareToken: meta.shareToken
        ) { [weak self] (result, error) in
            guard let self = self else {
                return
            }
            // stop directly?
            self.stopLoading()
            guard let result = result else {
                let error = error ?? DocsNetworkError.invalidData
                DocsLogger.error("fetch bitable share permission failed", error: error, component: nil)
                return
            }
            DocsLogger.info("fetch bitable share permission success!")
            self.publicPermissionMeta = result
            self.updateDataIfPassswordChanged(
                newHasPassword: result.hasLinkPassword,
                newPassword: result.linkPassword,
                needReloadUI: needReloadUI
            )
        }
    }


    /// 更新文档的公共权限
    func updateDocsPublicPermission(linkShareEntityValue: ShareLinkChoice, permType: PermTypeValue.PermType) {
        let type = shareEntity.type.rawValue
        let token = shareEntity.objToken
        updatePermissionRequest?.cancel()
        let entityValue = ShareFeatureGating.newPermissionSettingEnable(type: type) ? linkShareEntityValue.rawValue + 1 : linkShareEntityValue.rawValue
        var params: [String: Any] = ["type": type,
                                     "token": token,
                                     "link_share_entity": entityValue]
        params.merge(other: ["perm_type": ["link_share_entity": permType.rawValue]])

        updatePermissionRequest = PermissionManager.updateBizsPublicPermission(type: type, params: params, complete: { [weak self] (response, error) in
            guard let self = self else { return }
            guard (error as? URLError)?.errorCode != NSURLErrorCancelled, error == nil else {
                self.stopLoading()
                self.showToast(text: BundleI18n.SKResource.Doc_Facade_SetFailed, type: .failure)
                return
            }
            guard let response = response else {
                self.stopLoading()
                self.showToast(text: BundleI18n.SKResource.Doc_Facade_SetFailed, type: .failure)
                return
            }
            guard let code = response["code"].int else {
                DocsLogger.error("updatePermission failed!")
                self.stopLoading()
                self.showToast(text: BundleI18n.SKResource.Doc_Facade_SetFailed, type: .failure)
                return
            }
            guard code == 0 else {
                DocsLogger.error("updatePermission failed, error code is \(code)")
                self.stopLoading()
                self.handleError(json: response, inputText: BundleI18n.SKResource.Doc_Facade_SetFailed)
                return
            }

            self.updateSelectedState()
            self.fetchDocsPermission(needReloadUI: true)
        })
    }
    
    /// 更新文档的公共权限(可搜索设置)
    func updateDocsPublicPermission(searchSettingInfo: SearchSettingInfo, permType: PermTypeValue.PermType) {
        let type = shareEntity.type.rawValue
        let token = shareEntity.objToken
        updatePermissionRequest?.cancel()
        var params: [String: Any] = ["type": type,
                                     "token": token,
                                     "search_entity": searchSettingInfo.chosenType.rawValue]
        params.merge(other: ["perm_type": ["search_entity": permType.rawValue]])

        updatePermissionRequest = PermissionManager.updateBizsPublicPermission(type: type, params: params, complete: { [weak self] (response, error) in
            guard let self = self else { return }
            guard (error as? URLError)?.errorCode != NSURLErrorCancelled, error == nil else {
                self.stopLoading()
                self.showToast(text: BundleI18n.SKResource.Doc_Facade_SetFailed, type: .failure)
                return
            }
            guard let response = response else {
                self.stopLoading()
                self.showToast(text: BundleI18n.SKResource.Doc_Facade_SetFailed, type: .failure)
                return
            }
            guard let code = response["code"].int else {
                DocsLogger.error("updatePermission failed!")
                self.stopLoading()
                self.showToast(text: BundleI18n.SKResource.Doc_Facade_SetFailed, type: .failure)
                return
            }
            guard code == 0 else {
                DocsLogger.error("updatePermission failed, error code is \(code)")
                self.stopLoading()
                self.handleError(json: response, inputText: BundleI18n.SKResource.Doc_Facade_SetFailed)
                return
            }

            self.updateSearchSettingSelectedState(searchSettingInfo: searchSettingInfo)
            self.fetchDocsPermission(needReloadUI: true)
        })
    }

    /// 更新文件夹的公共权限
    func updateFolderPublicPermission() {
        if shareEntity.spaceSingleContainer {
            updateShareFolderPublicPermissions()
        } else {
            var count = currentChoice.rawValue
            /// 文件夹的「所有人可阅读」权限的值为4
            if count == 3 {
                count += 1
            }
            let spaceID = shareEntity.spaceID
            guard !spaceID.isEmpty else {
                self.stopLoading()
                DocsLogger.error("can not get space id!")
                return
            }
            let params: [String: Any] = ["space_id": spaceID,
                                         "allow_cross_tenant": publicPermissionMeta.externalAccessEnable,
                                         "link_perm": count,
                                         "external_access": publicPermissionMeta.externalAccessEnable,
                                         "remind_anyone_link": publicPermissionMeta.remindAnyoneLink]
            updatePermissionRequest?.cancel()
            updatePermissionRequest = PermissionManager.updateOldShareFolderPublicPermissionRequest(params: params) { [weak self] (response, error) in
                guard let self = self else { return }
                guard (error as? URLError)?.errorCode != NSURLErrorCancelled, error == nil else {
                    self.stopLoading()
                    self.showToast(text: BundleI18n.SKResource.Doc_Facade_SetFailed, type: .failure)
                    return
                }
                guard let response = response, let code = response["code"].int else {
                    self.stopLoading()
                    self.showToast(text: BundleI18n.SKResource.Doc_Facade_SetFailed, type: .failure)
                    return
                }
                guard code == 0 else {
                    self.stopLoading()
                    self.handleError(json: response, inputText: BundleI18n.SKResource.Doc_Facade_SetFailed)
                    DocsLogger.error("error code: \(code)")
                    return
                }
                self.updateSelectedState()
                self.requestFolderPublicPermission(needReloadUI: true)
            }
        }
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

    func fetchDocsPermission(needReloadUI: Bool, completation: (() -> Void)? = nil) {
        permissionObserver.fetchAllPermission { [weak self] (response) in
            guard let self = self else { return }
            defer {
                self.stopLoading()
                completation?()
            }
            if let error = response.error {
                DocsLogger.error("fetchAllPermission failed!", extraInfo: nil, error: error, component: nil)
                return
            }
            guard let publicPermissionMeta = response.publicPermissionMeta else {
                DocsLogger.info("get public permission failed!")
                return
            }
            self.publicPermissionMeta = publicPermissionMeta
            self.updateDataIfPassswordChanged(newHasPassword: publicPermissionMeta.hasLinkPassword,
                                              newPassword: publicPermissionMeta.linkPassword,
                                              needReloadUI: needReloadUI)
            DocsLogger.info("更新文档公共权限成功, publicPermissionMeta: \(publicPermissionMeta)")
        }
    }
    
    func requestFolderPublicPermission(needReloadUI: Bool, completation: (() -> Void)? = nil) {
        if shareEntity.spaceSingleContainer {
            let token = shareEntity.objToken
            permissionManager.requestV2FolderPublicPermissions(token: token, type: shareEntity.type.rawValue) { [weak self] (publicPermissionMeta, error) in
                guard let self = self else { return }
                defer {
                    self.stopLoading()
                    completation?()
                }
                guard error == nil else {
                    DocsLogger.error("SKShareViewModel fetch share folder public permission failed (sc)", error: error, component: LogComponents.permission)
                    return
                }
                guard let publicPermissionMeta = publicPermissionMeta else { return }
                self.publicPermissionMeta = publicPermissionMeta
                self.updateDataIfPassswordChanged(newHasPassword: publicPermissionMeta.hasLinkPassword,
                                                  newPassword: publicPermissionMeta.linkPassword,
                                                  needReloadUI: needReloadUI)
                DocsLogger.info("查询文件夹公共权限成功, shareFolderPermissionMeta: \(self.publicPermissionMeta)")
            }
        } else {
            let spaceID = shareEntity.spaceID
//            folderPermissionRequest?.cancel()
            permissionManager.getOldShareFolderPublicPermissionsRequest(spaceID: spaceID, token: shareEntity.objToken) { [weak self] (newPermissionMeta, error) in
                guard let self = self else { return }
                defer {
                    self.stopLoading()
                }
                if let error = error {
                    DocsLogger.error("shareFolderPermissions failed!", extraInfo: nil, error: error, component: nil)
                    return
                }
                guard let newPermissionMeta = newPermissionMeta else {
                    DocsLogger.info("shareFolderPermissionMeta is nil!")
                    return
                }
                self.publicPermissionMeta = newPermissionMeta
                self.updateDataIfPassswordChanged(newHasPassword: newPermissionMeta.hasLinkPassword,
                                                  newPassword: newPermissionMeta.linkPassword,
                                                  needReloadUI: needReloadUI)
                DocsLogger.info("查询文件夹公共权限成功, shareFolderPermissionMeta: \(self.publicPermissionMeta)")
            }
        }
    }
    
    // MARK: 修改公共权限判断是否触发加锁
    func checkLockByUpdatePublicPermission(linkShareEntityValue: ShareLinkChoice?, searchEntityValue: SearchEntity?, completion: ((_ success: Bool, _ needLock: Bool) -> Void)?) {
        if shareEntity.wikiV2SingleContainer || shareEntity.spaceSingleContainer {
            let token = shareEntity.objToken
            let type = shareEntity.type.rawValue
            if shareEntity.isFolder {
                checkLockPermission = PermissionManager.checkLockByUpdateShareFolderPublicPermission(
                    token: token,
                    linkShareEntity: linkShareEntityValue?.rawValue) { (success, needLock, _) in
                    completion?(success, needLock)
                }
            } else {
                checkLockPermission = PermissionManager.checkLockByUpdateFilePublicPermission(
                    token: token,
                    type: type,
                    linkShareEntity: linkShareEntityValue?.rawValue,
                    searchEntity: searchEntityValue?.rawValue) { (success, needLock, _) in
                    completion?(success, needLock)
                }
            }
        } else {
            completion?(true, false)
        }
    }
}

extension ShareLinkEditViewController {
    func updateShareFolderPublicPermissions() {
        let token = shareEntity.objToken
        let linkShareEntity = currentChoice.rawValue + 1
        updatePermissionRequest = PermissionManager.updateV2FolderPublicPermissions(
            token: token,
            type: shareEntity.type.rawValue,
            params: ["link_share_entity": linkShareEntity]) { [weak self] (success, _, json) in
            guard let self = self else { return }
            if let success = success, success == true {
                self.updateSelectedState()
                self.requestFolderPublicPermission(needReloadUI: true)
            } else {
                self.stopLoading()
                self.handleError(json: json, inputText: BundleI18n.SKResource.Doc_Facade_SetFailed)
            }
        }
    }
}
