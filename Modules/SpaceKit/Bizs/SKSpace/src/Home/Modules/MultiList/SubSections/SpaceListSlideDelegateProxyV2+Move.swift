//
//  SpaceListSlideDelegateProxyV2+Move.swift
//  SKSpace
//
//  Created by Weston Wu on 2022/10/19.
// swiftlint:disable file_length

import Foundation
import RxSwift
import SKCommon
import SKUIKit
import SKFoundation
import SKResource
import UniverseDesignDialog
import LarkUIKit
import EENavigator
import SpaceInterface
import SKInfra
import SKWorkspace
import LarkContainer

// 移动流程参考 https://bytedance.feishu.cn/wiki/wikcnVRKVBxF6D5AoBEQ4kzZsOg
// MARK: - Move Event
extension SpaceListSlideDelegateProxyV2 {
    func moveTo(for entry: SpaceEntry) {
        if entry.isOffline {
            showFailure(with: BundleI18n.SKResource.Doc_List_FailedToDragOfflineDoc)
            return
        }
        if !SettingConfig.singleContainerEnable {
            let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
            let myFolder = SKDataManager.shared.getMyFolder()
            if entry.parent?.isEmpty == true, let myFolderToken = myFolder?.objToken {
                entry.updateParent(myFolderToken)
            }
        }
        moveWithPicker(entry: entry)
    }

    func moveTo(for wikiEntry: WikiEntry, nodePermission: WikiTreeNodePermission) {
        guard let wikiInfo = wikiEntry.wikiInfo else { return }
        helper?.slideActionInput.accept(.showHUD(.loading))
        WikiNetworkManager.shared.getNodeMetaInfo(wikiToken: wikiInfo.wikiToken)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] wikiServerNode in
                guard let self = self, let helper = self.helper else { return }
                helper.slideActionInput.accept(.hideHUD)
                let subContext = WikiInteractionHandler.Context(meta: wikiServerNode.meta,
                                                                parentToken: wikiServerNode.parent)
                let moveContext = WikiInteractionHandler.MoveContext(subContext: subContext,
                                                                     canMove: nodePermission.canMove,
                                                                     permissionLocked: nodePermission.isLocked,
                                                                     hasChild: wikiServerNode.meta.hasChild,
                                                                     didMovedToWiki: { _, _ in
                    helper.refreshForMoreAction()
                    DocsLogger.info("Wiki didMoveToWiki")
                }, didMovedToSpace: { _ in
                    helper.refreshForMoreAction()
                    DocsLogger.info("Wiki didMovedToSpace")
                })

                let entrances = self.wikiInteractionHelper.entrancesForMove(moveContext: moveContext)

                let picker = self.wikiInteractionHelper.makeMovePicker(context: moveContext,
                                                                  triggerLocation: .topBar,
                                                                  entrances: entrances) {
                    [weak self] picker, location in
                    guard let self else { return }
                    self.wikiInteractionHelper.confirmMoveTo(location: location,
                                                             context: moveContext,
                                                             picker: picker)
                }
                helper.slideActionInput.accept(.present(viewController: picker))
            } onError: { [weak self] error in
                let message = BundleI18n.SKResource.Doc_List_FolderSelectMove + BundleI18n.SKResource.Doc_AppUpdate_FailRetry
                self?.showFailure(with: message)
                DocsLogger.error("Wiki Move fail getNodeMetaInfo fail: \(error.localizedDescription)")
            }.disposed(by: disposeBag)
    }

    // 接入新 Picker
    private func moveWithPicker(entry: SpaceEntry) {
        var entrances: [WorkspacePickerEntrance]
        // 默认同租户，避免初始拉不到对应文档的ownerTenantID导致问题
        var isSameTenantWithOwner = true
        if entry.ownerTenantID != nil, User.current.info?.tenantID != nil {
            isSameTenantWithOwner = (entry.ownerTenantID == User.current.info?.tenantID)
        }
        if !entry.isSingleContainerNode // Space 1.0 禁止移动到 wiki
            || entry.type == .folder // 文件夹禁止移动到 wiki
            || entry.isShortCut // shortcut 禁止移动到 wiki
            || !isSameTenantWithOwner { // 其他租户的文档禁止移动到 wiki
            entrances = .spaceOnly
        } else {
            entrances = .wikiAndSpace
        }
        
        var isUnorganizedList: Bool = false
        if case let .specialList(folderKey) = helper?.listType, folderKey == .personalFileV3 {
            isUnorganizedList = true
        }
        
        if !entry.ownerIsCurrentUser || entry.type == .folder || isUnorganizedList {
            entrances.removeAll { $0 == .unorganized }
        }
        
        let tracker = WorkspacePickerTracker(actionType: .moveTo, triggerLocation: .topBar)
        let config = WorkspacePickerConfig(title: BundleI18n.SKResource.LarkCCM_Wiki_MoveTo_Header_Mob,
                                           action: .moveSpace,
                                           entrances: entrances,
                                           ownerTypeChecker: { isSingleFolder in
            // 检查 space 版本是否匹配
            guard entry.isSingleContainerNode != isSingleFolder else { return nil }
            if isSingleFolder {
                // 1.0 文件 + 2.0 文件夹
                return BundleI18n.SKResource.CreationMobile_ECM_UnableMoveToast
            } else {
                // 2.0 文件 + 1.0 文件夹
                return BundleI18n.SKResource.CreationMobile_ECM_UnableMoveDocToast
            }
        },
                                           usingLegacyRecentAPI: !entry.isSingleContainerNode,
                                           tracker: tracker) { [weak self] location, picker in
            guard let self = self else { return }
            switch location {
            case let .folder(location):
                self.verifyMoveToSpace(entry: entry, location: location, picker: picker)
            case let .wikiNode(location):
                self.verifyMoveToWiki(entry: entry, location: location, picker: picker)
            }
        }
        let picker = WorkspacePickerFactory.createWorkspacePicker(config: config)
        helper?.slideActionInput.accept(.present(viewController: picker))
    }

    // nolint: magic number
    private static func getReviewerFailedTips(code: Int, userInfo: AuthorizedUserInfo) -> String {
        switch code {
        case DocsNetworkError.Code.executivesBlock.rawValue, 920_004_107:
            return BundleI18n.SKResource.LarkCCM_Wiki_Move_ReqPermission_Blocked(userInfo.getDisplayName())
        case 4203, 920_003_005:
            return BundleI18n.SKResource.LarkCCM_Wiki_Move_ReqPermission_Left
        case DocsNetworkError.Code.workspaceExceedLimited.rawValue, 920_004_106:
            return BundleI18n.SKResource.LarkCCM_Wiki_Move_ReqPermission_TooMany
        case 920_004_105:
            return BundleI18n.SKResource.LarkCCM_Wiki_Move_ReqPermission_SentFailed_NoPerm
        case 4204:
            return BundleI18n.SKResource.LarkCCM_Wiki_Move_Failed_GetManagePerm
        default:
            return BundleI18n.SKResource.LarkCCM_Wiki_Move_ReqPermission_SentFailed
        }
    }
    // enable-lint: magic number
}

// Move To Space
extension SpaceListSlideDelegateProxyV2 {
    // 步骤1：前置校验目标文件夹权限，移动到外部、共享文件夹间移动场景，弹窗二次确认
    private func verifyMoveToSpace(entry: SpaceEntry, location: SpaceFolderPickerLocation, picker: UIViewController) {
        guard location.canCreateSubNode else {
            showFailure(with: BundleI18n.SKResource.LarkCCM_Workspace_FolderPerm_CantMove_Tooltip)
            return
        }
        let alertConfirmation: Completable
        // 老逻辑里，最多只展示一个弹窗
        if shouldShowCrossTenantAlert(entry: entry, location: location) {
            alertConfirmation = showCrossTenantAlert(entry: entry, picker: picker)
        } else if shouldShowTransferAlert(entry: entry, location: location) {
            alertConfirmation = showTransferAlert(entry: entry, picker: picker)
        } else if shouldShowLegacyCrossTenantAlert(entry: entry, location: location) {
            alertConfirmation = showCrossTenantAlert(entry: entry, picker: picker)
        } else {
            // 没有弹窗需要展示
            alertConfirmation = .empty()
        }
        alertConfirmation.subscribe { [weak self] in
            guard let self = self else { return }
            self.confirmMoveToSpace(entry: entry, location: location, picker: picker)
        } onError: { error in
            DocsLogger.info("move to space alert return error", error: error)
        }
        .disposed(by: disposeBag)

    }

    // 移动到 space 2.0 外部文件夹，需要弹窗提醒
    private func shouldShowCrossTenantAlert(entry: SpaceEntry, location: SpaceFolderPickerLocation) -> Bool {
        guard entry.isSingleContainerNode,
              location.isSingleContainerNode,
              location.isExternal else {
            // 非 Space 2.0 外部文件夹，跳过
            return false
        }
        return true
    }

    private func shouldShowTransferAlert(entry: SpaceEntry, location: SpaceFolderPickerLocation) -> Bool {

        if location.isSingleContainerNode, location.folderType.isShareFolder {
            // 目标位置是 space 2.0 共享文件夹，需要提示
            return true
        }
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        if entry.isSingleContainerNode,
           let parentToken = entry.parent,
           let parentEntry = SKDataManager.shared.spaceEntry(token: TokenStruct(token: parentToken, nodeType: 1)),
           let parentFolder = parentEntry as? FolderEntry,
           parentFolder.isShareFolder {
            // 原父文件夹是 space 2.0 共享文件夹，需要提示
            return true
        }
        // 其他情况默认不提示
        return false
    }

    private func shouldShowLegacyCrossTenantAlert(entry: SpaceEntry, location: SpaceFolderPickerLocation) -> Bool {
        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
        if let entryPermission = permissionManager.getPublicPermissionMeta(token: entry.objToken),
           !entryPermission.externalAccessEnable {
            // 如果文档没有开启「允许文档被分享到组织外」，不需要弹窗
            return false
        }

        if User.current.info?.isToNewC == true {
            // 小B不弹窗
            return false
        }
        // 最终由目标位置是否是外部文件夹决定弹窗
        return location.isExternal
    }

    // 从 Space 2.0 共享文件夹移动到另一个共享文件夹，需要弹窗提醒
    private func showTransferAlert(entry: SpaceEntry, picker: UIViewController) -> Completable {
        Completable.create { [weak self] observer in
            guard let self = self else {
                observer(.error(SpaceManagementError.handlerReferenceError))
                return Disposables.create()
            }
            let title = BundleI18n.SKResource.LarkCCM_Workspace_MoveConfirm_Title_Mob
            let content = BundleI18n.SKResource.LarkCCM_Workspace_MoveConfirmContent_Subtitle_Mob
            let caption = BundleI18n.SKResource.LarkCCM_Workspace_MoveConfirmNotification_Subtitle_Mob
            let dialog = UDDialog()

            // owner 或 shortcut 不展示非所有者移动提示
            if !entry.ownerIsCurrentUser,
               !entry.isShortCut {
                dialog.setContent(text: content, caption: caption)
            } else {
                dialog.setContent(text: content)
            }

            dialog.setTitle(text: title)
            dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion: {
                observer(.error(SpaceManagementError.userCancelled))
            })
            dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: {
                observer(.completed)
            })
            self.helper?.userResolver.navigator.present(dialog, from: picker)
            return Disposables.create()
        }
    }

    private func showCrossTenantAlert(entry: SpaceEntry, picker: UIViewController) -> Completable {
        Completable.create { [weak self] observer in
            guard let self = self else {
                observer(.error(SpaceManagementError.handlerReferenceError))
                return Disposables.create()
            }
            let typeName = entry.type == .folder ? BundleI18n.SKResource.Doc_Facade_Folder : BundleI18n.SKResource.Doc_Facade_Document
            let content = BundleI18n.SKResource.CreationMobile_ECM_MovedExternalConfirmDesc(typeName)
            let caption = BundleI18n.SKResource.LarkCCM_Workspace_MoveConfirmNotification_Subtitle_Mob
            let dialog = UDDialog()
            // owner 或 shortcut 不展示非所有者移动提示
            if !entry.ownerIsCurrentUser,
               !entry.isShortCut {
                dialog.setContent(text: content, caption: caption)
            } else {
                dialog.setContent(text: content)
            }
            dialog.setTitle(text: BundleI18n.SKResource.CreationMobile_ECM_MovedExternalConfirmTitle)
            dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion: {
                observer(.error(SpaceManagementError.userCancelled))
            })
            dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: {
                observer(.completed)
            })
            self.helper?.userResolver.navigator.present(dialog, from: picker)
            return Disposables.create()
        }
    }

    // 步骤2：用户确认后，拉 reviewer 信息，走申请移动流程或直接移动
    private func confirmMoveToSpace(entry: SpaceEntry, location: SpaceFolderPickerLocation, picker: UIViewController) {
        guard let helper else {
            return
        }

        if entry.isShortCut || !entry.isSingleContainerNode {
            // 移动快捷方式、1.0文档时，跳过申请流程
            DocsLogger.info("apply move shortcut or space 1.0 not supported")
            moveToSpace(entry: entry, location: location, picker: picker)
            return
        }

        if entry.type == .folder, !UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled {
            // FG 关时，文件夹不支持申请移动
            DocsLogger.info("apply move folder disabled by FG")
            moveToSpace(entry: entry, location: location, picker: picker)
            return
        }

        helper.slideActionInput.accept(.showHUD(.loading))
        helper.interactionHelper.getMoveReviewer(nodeToken: entry.nodeToken, item: nil, targetToken: location.folderToken)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] userInfo in
                // 走申请流程
                guard let self = self,
                      let helper = self.helper else { return }
                helper.slideActionInput.accept(.hideHUD)
                self.showApplyMoveToSpacePanel(entry: entry, location: location, userInfo: userInfo, picker: picker)
            } onError: { [weak self] error in
                let message: String
                // nolint-next-line: magic number
                if 4204 == (error as NSError).code {
                    message = BundleI18n.SKResource.LarkCCM_Wiki_Move_Failed_GetManagePerm
                } else {
                    message = BundleI18n.SKResource.Doc_List_FolderSelectMove + BundleI18n.SKResource.Doc_AppUpdate_FailRetry
                }
                // 报错提示
                self?.showFailure(with: message)
            } onCompleted: { [weak self] in
                // 有权限，可以直接移动流程
                self?.moveToSpace(entry: entry, location: location, picker: picker)
            }
            .disposed(by: disposeBag)
    }

    // 申请分支-步骤3：展示申请移动弹窗
    private func showApplyMoveToSpacePanel(entry: SpaceEntry,
                                           location: SpaceFolderPickerLocation,
                                           userInfo: AuthorizedUserInfo,
                                           picker: UIViewController) {
        let title = entry.type == .folder
        ? BundleI18n.SKResource.LarkCCM_CM_RequestToMoveFolder_Title
        : BundleI18n.SKResource.LarkCCM_CM_RequestToMoveDoc_Title
        let subTitle: (String) -> String = entry.type == .folder
        ? { BundleI18n.SKResource.LarkCCM_CM_NoPermToMoveFolder_WithFolderSettings_Description($0) }
        : { BundleI18n.SKResource.LarkCCM_CM_NoPermToMoveDoc_WithFolderSettings_Description($0) }
        var config = SKApplyPanelConfig(userInfo: userInfo,
                                        title: title,
                                        placeHolder: BundleI18n.SKResource.LarkCCM_Wiki_Move_ReqPermission_Context,
                                        actionName: BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AskOwner_Btn,
                                        contentProvider: subTitle)
        config.actionHandler = { [weak self] _, reason in
            self?.applyMoveToSpace(entry: entry,
                                   location: location,
                                   userInfo: userInfo,
                                   reason: reason,
                                   picker: picker)
        }
        if UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled {
            do {
                let url = try HelpCenterURLGenerator.generateURL(article: .cmApplyMove,
                                                                 query: ["from": "ccm_permission_move"])
                config.accessoryHandler = { [weak self] controller in
                    self?.helper?.userResolver.navigator.present(url,
                                                                 context: ["showTemporary": false],
                                                                 wrap: LkNavigationController.self,
                                                                 from: controller)
                }
            } catch {
                DocsLogger.error("failed to generate helper center URL when apply move to space from space list", error: error)
            }
        }
        let controller = SKApplyPanelController.createController(config: config)
        self.helper?.userResolver.navigator.present(controller, from: picker)
    }

    // 申请分支-步骤4：发起申请移动请求，成功后关闭 picker，结束流程，失败时停留在申请页面
    private func applyMoveToSpace(entry: SpaceEntry, location: SpaceFolderPickerLocation, userInfo: AuthorizedUserInfo, reason: String?, picker: UIViewController) {
        guard let helper else { return }
        helper.slideActionInput.accept(.showHUD(.customLoading(BundleI18n.SKResource.CreationMobile_Comment_Add_Sending_Toast)))
        helper.interactionHelper.applyMoveToSpace(nodeToken: entry.nodeToken, targetToken: location.folderToken, reviewerID: userInfo.userID, comment: reason)
            .subscribe { [weak self] in
                // 申请成功
                guard let self = self else { return }
                self.showSuccess(with: BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AskOwner_SentToast)
                picker.presentingViewController?.dismiss(animated: true)
            } onError: { [weak self] error in
                // 申请失败
                guard let self = self else { return }
                let code = (error as NSError).code
                let message = Self.getReviewerFailedTips(code: code, userInfo: userInfo)
                self.showFailure(with: message)
            }
            .disposed(by: disposeBag)
    }

    // 移动分支-步骤3：有权限直接移动，发起移动请求，成功后关闭 picker，结束流程，失败时停留在 picker
    private func moveToSpace(entry: SpaceEntry, location: SpaceFolderPickerLocation, picker: UIViewController) {
        guard let helper else { return }
        let moveEvent: Completable
        if entry.isSingleContainerNode {
            moveEvent = helper.interactionHelper.moveV2(nodeToken: entry.nodeToken, from: entry.parent, to: location.folderToken)
        } else {
            moveEvent = helper.interactionHelper.move(nodeToken: entry.nodeToken, from: entry.parent ?? "", to: location.folderToken)
        }
        helper.slideActionInput.accept(.showHUD(.loading))
        moveEvent.subscribe { [weak self] in
            guard let self else { return }
            self.helper?.refreshForMoreAction()
            self.showSuccess(with: BundleI18n.SKResource.Doc_List_FolderSelectMove + BundleI18n.SKResource.Doc_Normal_Success)
            picker.presentingViewController?.dismiss(animated: true)
            self.refreshCurrentList()
        } onError: { [weak self] error in
            guard let self else { return }
            DocsLogger.error("move to space failed with error", error: error)
            let message: String
            let rawErrorCode = (error as NSError).code
            if let errorCode = ExplorerErrorCode(rawValue: rawErrorCode) {
                if rawErrorCode == ExplorerErrorCode.moveDontHaveSharePermission.rawValue {
                    message = BundleI18n.SKResource.Doc_Permission_MoveToNoPermission(entry.name)
                } else {
                    let errorEntity = ErrorEntity(code: errorCode, folderName: error.localizedDescription)
                    message = errorEntity.wording
                }
            } else if let err = error as? DocsNetworkError,
                      let errorMessage = err.code.errorMessage {
                message = errorMessage
            } else {
                message = BundleI18n.SKResource.Doc_List_FolderSelectAdd + BundleI18n.SKResource.Doc_AppUpdate_FailRetry
            }
            self.showFailure(with: message)
        }
        .disposed(by: disposeBag)
    }
}

// Move To Wiki
extension SpaceListSlideDelegateProxyV2 {
    // 步骤1：前置校验目标 wiki 位置的权限
    private func verifyMoveToWiki(entry: SpaceEntry, location: WikiPickerLocation, picker: UIViewController) {
        guard entry.isSingleContainerNode else {
            showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_UnableMoveToast)
            return
        }
        guard let helper else { return }
        helper.slideActionInput.accept(.showHUD(.loading))
        helper.interactionHelper.checkWikiCreatePermission(location: location)
            .subscribe { [weak self] canCreate in
                guard let self else { return }
                guard canCreate else {
                    self.showFailure(with: BundleI18n.SKResource.LarkCCM_Docs_MoveToWiki_NoMovingPermission_Toast)
                    return
                }
                self.helper?.slideActionInput.accept(.hideHUD)
                self.notifyWikiPermissionChange(location: location, picker: picker)
                    .subscribe { [weak self] in
                        // 开始获取 reviewer
                        self?.confirmMoveToWiki(entry: entry, location: location, picker: picker)
                    } onError: { error in
                        DocsLogger.info("move to wiki alert return error", error: error)
                    }
                    .disposed(by: self.disposeBag)
            } onError: { [weak self] error in
                DocsLogger.error("check wiki permission failed when move to wiki", error: error)
                self?.showFailure(with: BundleI18n.SKResource.LarkCCM_Docs_MoveToWiki_Fail_Toast)
            }
            .disposed(by: disposeBag)
    }

    // 步骤2：弹窗二次确认权限变化
    private func notifyWikiPermissionChange(location: WikiPickerLocation, picker: UIViewController) -> Completable {
        Completable.create { [weak self] observer in
            guard let self = self else {
                observer(.error(SpaceManagementError.handlerReferenceError))
                return Disposables.create()
            }
            let title = BundleI18n.SKResource.LarkCCM_Workspace_MoveConfirm_Title_Mob
            let locationName = location.isMainRoot ? location.spaceName : location.nodeName
            let content = BundleI18n.SKResource.LarkCCM_Docs_MoveToWiki_SingleAuthorityChange_DescriptionNew(locationName)
            let caption = BundleI18n.SKResource.LarkCCM_Wiki_MoveDocs_AlertOthers_Tooltip_web
            let dialog = UDDialog()
            dialog.setTitle(text: title)
            dialog.setContent(text: content, caption: caption)
            dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion: {
                observer(.error(SpaceManagementError.userCancelled))
            })
            dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: {
                observer(.completed)
            })
            self.helper?.userResolver.navigator.present(dialog, from: picker)
            return Disposables.create()
        }
    }

    // 步骤3：获取 reviewer，走申请或直接移动
    private func confirmMoveToWiki(entry: SpaceEntry, location: WikiPickerLocation, picker: UIViewController) {
        guard let helper else {
            return
        }
        helper.slideActionInput.accept(.showHUD(.loading))
        helper.interactionHelper.getMoveReviewer(nodeToken: entry.nodeToken, item: nil, targetToken: location.wikiToken)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] userInfo in
                // 走申请流程
                guard let self = self,
                      let helper = self.helper else { return }
                helper.slideActionInput.accept(.hideHUD)
                self.showApplyMoveToWikiPanel(entry: entry, location: location, userInfo: userInfo, picker: picker)
            } onError: { [weak self] error in
                let message: String
                if 4204 == (error as NSError).code {
                    message = BundleI18n.SKResource.LarkCCM_Wiki_Move_Failed_GetManagePerm
                } else {
                    message = BundleI18n.SKResource.LarkCCM_Docs_MoveToWiki_Fail_Toast
                }
                // 报错提示
                self?.showFailure(with: message)
            } onCompleted: { [weak self] in
                // 有权限，可以直接移动流程
                self?.moveToWiki(entry: entry, location: location, picker: picker)
            }
            .disposed(by: disposeBag)
    }

    // 申请分支-步骤3：展示申请移动弹窗
    private func showApplyMoveToWikiPanel(entry: SpaceEntry,
                                          location: WikiPickerLocation,
                                          userInfo: AuthorizedUserInfo,
                                          picker: UIViewController) {
        var config = SKApplyPanelConfig(userInfo: userInfo,
                                        title: BundleI18n.SKResource.LarkCCM_CM_RequestToMoveDoc_Title,
                                        placeHolder: BundleI18n.SKResource.LarkCCM_Wiki_Move_ReqPermission_Context,
                                        actionName: BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AskOwner_Btn,
                                        contentProvider: { BundleI18n.SKResource.LarkCCM_CM_NoPermToMoveDoc_WithFolderSettings_Description($0) })
        config.actionHandler = { [weak self] _, reason in
            self?.applyMoveToWiki(entry: entry,
                                  location: location,
                                  userInfo: userInfo,
                                  reason: reason,
                                  picker: picker)
        }
        if UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled {
            do {
                let url = try HelpCenterURLGenerator.generateURL(article: .cmApplyMove,
                                                                 query: ["from": "ccm_permission_move"])
                config.accessoryHandler = { [weak self] controller in
                    self?.helper?.userResolver.navigator.present(url,
                                                                 context: ["showTemporary": false],
                                                                 wrap: LkNavigationController.self,
                                                                 from: controller)
                }
            } catch {
                DocsLogger.error("failed to generate helper center URL when apply move to wiki from space list", error: error)
            }
        }
        let controller = SKApplyPanelController.createController(config: config)
        self.helper?.userResolver.navigator.present(controller, from: picker)
    }

    // 申请分支-步骤4：发起申请移动请求，成功后关闭 picker，结束流程，失败时停留在申请页面
    private func applyMoveToWiki(entry: SpaceEntry, location: WikiPickerLocation, userInfo: AuthorizedUserInfo, reason: String?, picker: UIViewController) {
        guard let helper else { return }
        helper.slideActionInput.accept(.showHUD(.customLoading(BundleI18n.SKResource.CreationMobile_Comment_Add_Sending_Toast)))
        helper.interactionHelper.applyMoveToWiki(item: entry.spaceItem, location: location, reviewerID: userInfo.userID, comment: reason)
            .subscribe { [weak self] in
                // 申请成功
                guard let self = self else { return }
                self.showSuccess(with: BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AskOwner_SentToast)
                picker.presentingViewController?.dismiss(animated: true)
            } onError: { [weak self] error in
                // 申请失败
                guard let self = self else { return }
                let code = (error as NSError).code
                let message = Self.getReviewerFailedTips(code: code, userInfo: userInfo)
                self.showFailure(with: message)
            }
            .disposed(by: disposeBag)
    }

    // 移动分支-步骤3：有权限直接移动，发起移动请求，成功后关闭 picker，结束流程，失败时停留在 picker
    private func moveToWiki(entry: SpaceEntry, location: WikiPickerLocation, picker: UIViewController) {
        guard let helper else { return }
        helper.slideActionInput.accept(.showHUD(.loading))
        helper.interactionHelper.moveToWiki(item: entry.spaceItem,
                                            nodeToken: entry.nodeToken,
                                            parentToken: entry.parent,
                                            location: location)
            .subscribe { [weak self] status in
                guard let self else { return }
                switch status {
                case .moving:
                    spaceAssertionFailure("moving status should not be return")
                    let message = BundleI18n.SKResource.Doc_List_FolderSelectMove + BundleI18n.SKResource.Doc_AppUpdate_FailRetry
                    self.showFailure(with: message)
                case .succeed:
                    self.helper?.refreshForMoreAction()
                    self.showSuccess(with: BundleI18n.SKResource.Doc_Wiki_MoveSuccess)
                    picker.presentingViewController?.dismiss(animated: true)
                    self.refreshCurrentList()
                case let .failed(code):
                    let message = Self.getMoveToWikiFailedTips(code: code)
                    self.showFailure(with: message)
                }
            } onError: { [weak self] error in
                guard let self else { return }
                DocsLogger.error("move to space failed with error", error: error)
                let message: String
                let rawErrorCode = (error as NSError).code
                if let errorCode = ExplorerErrorCode(rawValue: rawErrorCode) {
                    if rawErrorCode == ExplorerErrorCode.moveDontHaveSharePermission.rawValue {
                        message = BundleI18n.SKResource.Doc_Permission_MoveToNoPermission(entry.name)
                    } else {
                        let errorEntity = ErrorEntity(code: errorCode, folderName: error.localizedDescription)
                        message = errorEntity.wording
                    }
                } else if let err = error as? DocsNetworkError,
                          let errorMessage = err.code.errorMessage {
                    message = errorMessage
                } else {
                    message = BundleI18n.SKResource.Doc_List_FolderSelectMove + BundleI18n.SKResource.Doc_AppUpdate_FailRetry
                }
                self.showFailure(with: message)
            }
            .disposed(by: disposeBag)
    }

    private static func getMoveToWikiFailedTips(code: Int) -> String {
        switch code {
        case 3:
            return BundleI18n.SKResource.LarkCCM_Wiki_Menu_ImportToWiki_Import_failed_MaxLevel
        case 4:
            return BundleI18n.SKResource.LarkCCM_Docs_MoveToWiki_NoMovingPermission_Toast
        case 6:
            return BundleI18n.SKResource.LarkCCM_Wiki_ImportToWiki_Exist
        case 9:
            return BundleI18n.SKResource.LarkCCM_Docs_Retention_Settings_Restricted
        default:
            return BundleI18n.SKResource.LarkCCM_Docs_MoveToWiki_Fail_Toast
        }
    }
    
    // 移动成功后刷新当前所在列表
    func refreshCurrentList() {
        NotificationCenter.default.post(name: .Docs.refreshRecentFilesList, object: nil)
        NotificationCenter.default.post(name: .Docs.quickAccessUpdate, object: nil)
        NotificationCenter.default.post(name: .Docs.refreshShareSpaceFolderList, object: nil)
        NotificationCenter.default.post(name: .Docs.RefreshPersonFile, object: nil)
        NotificationCenter.default.post(name: FavoritesDataModel.favoritesNeedUpdate, object: nil)
    }
}
