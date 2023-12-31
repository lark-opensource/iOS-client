//
//  UtilMoreService+Provider.swift
//  SpaceKit
//
//  Created by lizechuang on 2021/3/9.
//
// swiftlint:disable cyclomatic_complexity
// swiftlint:disable function_body_length

import SKFoundation
import SKCommon
import UniverseDesignToast
import SKResource
import SKBrowser
import SKSpace
import SpaceInterface

// 重构代码暂时写在这里，不与原先逻辑冗杂
extension UtilMoreService {
    func handleMoreViewModel(_ viewModel: MoreViewModel) {
        viewModel.showOnboardingEnd.drive(onNext: { [weak self] (action: String, success: Bool) in
            guard let self = self else { return }
            if success {
                self.model?.jsEngine.callFunction(DocsJSCallBack.notifyGuideFinish, params: ["action": action, "status": "failed"], completion: nil)
            } else {
                self.model?.jsEngine.callFunction(DocsJSCallBack.notifyGuideFinish, params: ["action": action, "status": "success"], completion: nil)
            }
        }).disposed(by: bag)
    }

    func initializeMoreDataProviderWith(docsInfo: DocsInfo,
                                        hostViewController: UIViewController,
                                        userPermissions: UserPermissionAbility?,
                                        permissionService: UserPermissionService,
                                        params: [String: Any],
                                        trackerParams: [String: Any]?) -> UtilMoreDataProvider {
        let followAPIDelegate = (self.navigator?.currentBrowserVC as? BrowserViewController)?.spaceFollowAPIDelegate
        let docComponentDelegate = (self.navigator?.currentBrowserVC as? BrowserViewController)?.editor.docComponentDelegate
        let bitableBridgeData = BitableBridgeData(params: params)
        let publicPermissionMeta = permissionManager.getPublicPermissionMeta(token: docsInfo.objToken)
        let provider = UtilMoreDataProvider(docsInfo: docsInfo,
                                            model: model,
                                            hostViewController: hostViewController,
                                            userPermissions: userPermissions,
                                            permissionService: permissionService,
                                            publicPermissionMeta: publicPermissionMeta,
                                            outsideControlItems: obtainOutsideControlItemsWith(params: params),
                                            outsideControlBadges: self.badges,
                                            bitableBridgeData: bitableBridgeData,
                                            followAPIDelegate: followAPIDelegate,
                                            docComponentHostDelegate: docComponentDelegate,
                                            trackerParams: trackerParams)
        workbenchManager.clearAllRequest()
        asyncUpdateItemBuilder(of: provider)
        bindActionsWith(provider: provider)
        return provider
    }
    
    func bindActionsWith(provider: UtilMoreDataProvider) {
        provider.deleteFile.drive(onNext: { [weak self] () in
            guard let self else { return }
            self.ui?.loadingAgent.stopLoadingAnimation()
            self.navigator?.popViewController(canEmpty: true)
        }).disposed(by: bag)
        
        provider.deleteVersions.drive(onNext: { [weak self] () in
            guard let self = self, let docsInfo = self.hostDocsInfo, let hostView = self.ui?.hostView.window ?? self.ui?.hostView else { return }
            let completion: (Error?) -> Void = { [weak self] (error) in
                guard let self = self else { return }
                if error != nil {
                    if let docsError = error as? DocsNetworkError, docsError.code == .cacDeleteBlocked {
                        DocsLogger.error("cac blocked")
                    } else if let docsError = error as? DocsNetworkError, let message = docsError.code.errorMessage {
                        UDToast.showFailure(with: message, on: hostView)
                    } else {
                        UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_DeleteFailed_Toast, on: hostView)
                    }
                    self.ui?.loadingAgent.stopLoadingAnimation()
                } else {
                    self.ui?.displayConfig.canShowDeleteVersionEmptyView(false)
                    UDToast.showSuccess(with: BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_VDeleted_Toast, on: hostView)
                    self.ui?.loadingAgent.stopLoadingAnimation()
                    self.navigator?.popViewController(canEmpty: false)
                }
            }
            if docsInfo.isVersion, let versionInfo = docsInfo.versionInfo {
                DocsVersionManager.shared.deleteVersion(token: versionInfo.objToken, type: docsInfo.inherentType, versionToken: versionInfo.versionToken) { vToken, success in
                    guard vToken == versionInfo.versionToken else {
                        return
                    }
                    if success {
                        completion(nil)
                    } else {
                        completion(NSError())
                    }
                }
            }
        }).disposed(by: bag)

        provider.showReadingPanel.drive(onNext: { [weak self] () in
            guard let self = self else { return }
            self.requestOpenReadingDataPanel()
        }).disposed(by: bag)

        provider.showSensitivtyLabelSetting.drive(onNext: { [weak self] level in
            guard let self = self else { return }
            self.showSensitivtyLabelSetting(level, fromToolBar: false)
        }).disposed(by: bag)

        provider.showBitableAdvancedPermissionsSetting.drive(onNext: { [weak self] bridgeData in
            guard let self = self else { return }
            self.ui?.displayConfig.showBitableAdvancedPermissionsSettingVC(data: bridgeData, listener: nil)
        }).disposed(by: bag)

        provider.showPublicPermissionPanel.drive(onNext: { [weak self] () in
            guard let self = self else { return }
            self.showPublicPermissionSettingVC()
        }).disposed(by: bag)

        provider.showSearchPanel.drive(onNext: { [weak self] () in
            guard let self = self else { return }
            self.displaySearchPanel()
        }).disposed(by: bag)

        provider.showApplyEditPermission.emit(onNext: { [weak self] scene in
            guard let self = self else { return }
            self.handleApplyEditPermission(scene: scene)
        }).disposed(by: bag)

        provider.historyRecordAction.drive(onNext: { [weak self] () in
            guard let self = self else { return }
            guard let callbackFunc = self.callbackFunc else { return }
            self.ui?.displayConfig.isHistoryPanelShow = true
            self.callFunction(callbackFunc, params: nil, completion: nil)
        }).disposed(by: bag)
        
        provider.versionListAction.drive(onNext: { [weak self] () in
            guard let self = self else { return }
            self.showVersionListPanel()
        }).disposed(by: bag)

        provider.catalogAction.drive(onNext: { [weak self] () in
            guard let self = self else { return }
            self.handleCatalogDetails()
        }).disposed(by: bag)

        provider.showExportPanel.drive(onNext: { [weak self] (canEdit, adminBlocked) in
            guard let self = self else { return }
            self.moreViewShowExportDocumentVC(editorEnable: canEdit, shouldHideLongPic: adminBlocked)
        }).disposed(by: bag)

        provider.showRenamePanel.drive(onNext: { [weak self] () in
            guard let self = self else { return }
            self.handleRename()
        }).disposed(by: bag)
        
        provider.showCopyWikiFilePanel.drive(onNext: { [weak self] in
            guard let self = self else { return }
            self.showWikiCopyFilePanel()
        }).disposed(by: bag)

        provider.didWikiShortcut.drive(onNext: { [weak self] in
            guard let self = self else { return }
            self.wikiShortcut()
        }).disposed(by: bag)

        provider.didWikiMove.emit(onNext: { [weak self] in
            guard let self = self else { return }
            self.wikiMove()
        }).disposed(by: bag)

        provider.didWikiDelete.drive(onNext: { [weak self] in
            guard let self = self else { return }
            self.wikiDelete()
        }).disposed(by: bag)

        provider.didSuspendAction.drive(onNext: { [weak self] (addToSuspend) in
            guard let self = self else { return }
            self.handleSuspendActionWith(addToSuspend: addToSuspend)
        }).disposed(by: bag)

        provider.showOperationHistoryPanel.emit(onNext: { [weak self] in
            guard let self = self else { return }
            self.showOperationHistoryPanel()
        }).disposed(by: bag)
        
        provider.showTimeZoneSetting.emit(onNext: { [weak self] in
            guard let self = self else { return }
            self.showTimeZoneSetting()
        }).disposed(by: bag)
        
        provider.showForcibleWarning.emit(onNext: { [weak self] in
            guard let self = self else { return }
            self.showForcibleWarning()
        }).disposed(by: bag)
        
        provider.didWorkbenchAction.drive(onNext: { [weak self] (addToWorkbench) in
            guard let self = self else { return }
            self.handleWorkbenchActionWith(addToWorkbench: addToWorkbench)
        }).disposed(by: bag)
        
    }
    
    // 外部(前端)控制Items状态
    func obtainOutsideControlItemsWith(params: [String: Any]) -> MoreDataOutsideControlItems? {
        guard let disables = params["disables"] as? [String] else {
            return nil
        }
        var items = MoreDataOutsideControlItems()
        // 目前只有控制置灰
        items[State.disable] = disables.compactMap { MoreItemType.itemTypeControlledByFrontend(id: $0) }
        if let hiddens = params["invisibles"] as? [String] {
            items[State.hidden] = hiddens.compactMap { MoreItemType.itemTypeControlledByFrontend(id: $0) }
        }
        return items
    }
}

// MARK: - async Update builder
extension UtilMoreService {
    
    /// 异步更新 item 生成器
    func asyncUpdateItemBuilder(of provider: UtilMoreDataProvider) {
        asyncUpdateWorkbenchItem(with: provider)
    }
    
    /// 异步更新工作台
    private func asyncUpdateWorkbenchItem(with provider: UtilMoreDataProvider) {
        guard UserScopeNoChangeFG.ZSY.workbench, hostDocsInfo?.inherentType == .bitable else { return }

        let objToken = hostDocsInfo?.token
        let userId = model?.userResolver.docs.user?.basicInfo?.userID ?? User.current.basicInfo?.userID
        
        guard let token = objToken, let uid = userId else {
            DocsLogger.error("workbench asyncUpdateWorkbenchItem get params error token is nil: \(objToken == nil), uid is nil: \(userId == nil)")
            return
        }
        
        workbenchManager.requestWorkbenchStatus(token: token, userId: uid) { [weak provider] result in
            guard let provider = provider else { return }
            switch result {
            case .success(let isAdded):
                provider.itemAsyncGetStatusFlags.isWorkbenchAdded = isAdded
                provider.updater?(provider.builder)
            case .failure:
                break
            }
        }
    }
}
