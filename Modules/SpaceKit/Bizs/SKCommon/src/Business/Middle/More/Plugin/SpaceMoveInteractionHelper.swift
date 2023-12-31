//
//  SpaceMoveInteractionHelper.swift
//  SKCommon
//
//  Created by ZhangYuanping on 2023/8/1.
//  

import SKFoundation
import SpaceInterface
import SKResource
import SKInfra
import SKUIKit
import EENavigator
import LarkUIKit
import RxSwift
import RxRelay
import UniverseDesignDialog
import UniverseDesignToast

public enum SpaceManagementError: Error {
    case handlerReferenceError
    case userCancelled
}

/// 供Space文档内部More面板使用的"移动到"工具类，逻辑基本与SpaceListSlideDelegateProxyV2+Move类似，后续可考虑使用该工具类复用
public class SpaceMoveInteractionHelper {
    public struct MoveContext {
        public let name: String
        public let nodeToken: String
        public let objToken: String
        /// 被移动文档的父文件夹 NodeToken
        public var parent: String?
        public let isSingleContainerNode: Bool
        public let type: DocsType
        public let isShortCut: Bool
        public let isSameTenantWithOwner: Bool
        public let ownerIsCurrentUser: Bool
        /// 被移动文档是否在未整理列表
        public let isInUnorganizedList: Bool

        /// 移动到 Wiki 成功后新的 WikiToken
        public let didMovedToWiki: ((String) -> Void)?
        public let didMovedToSpace: (() -> Void)?

        public var spaceMeta: SpaceMeta {
            return SpaceMeta(objToken: objToken, objType: type)
        }

        public init(docsInfo: DocsInfo,
                    isInUnorganizedList: Bool = false,
                    parent: String? = nil,
                    didMovedToWiki: ((String) -> Void)? = nil,
                    didMovedToSpace: (() -> Void)? = nil) {
            self.name = docsInfo.name
            self.nodeToken = docsInfo.containerInfo?.nodeToken ?? ""
            self.objToken = docsInfo.objToken
            self.parent = parent
            self.isSingleContainerNode = docsInfo.isSingleContainerNode
            self.type = docsInfo.type
            self.isShortCut = docsInfo.isShortCut
            self.isSameTenantWithOwner = docsInfo.isSameTenantWithOwner
            self.ownerIsCurrentUser = docsInfo.isOwner
            self.isInUnorganizedList = isInUnorganizedList
            self.didMovedToWiki = didMovedToWiki
            self.didMovedToSpace = didMovedToSpace
        }
    }

    let disposeBag = DisposeBag()
    let spaceAPI: SpaceManagementAPI

    public init(spaceAPI: SpaceManagementAPI) {
        self.spaceAPI = spaceAPI
    }

    /// 创建移动 Picker 移动
    public func makeMovePicker(context: MoveContext) -> UIViewController {
        // entrances 可选择的移动到的地方
        var entrances: [WorkspacePickerEntrance]
        if !context.isSingleContainerNode // Space 1.0 禁止移动到 wiki
            || context.type == .folder // 文件夹禁止移动到 wiki
            || context.isShortCut // shortcut 禁止移动到 wiki
            || !context.isSameTenantWithOwner { // 其他租户的文档禁止移动到 wiki
            entrances = .spaceOnly
        } else {
            entrances = .wikiAndSpace
        }
        if !context.ownerIsCurrentUser || context.type == .folder || context.isInUnorganizedList {
            entrances.removeAll { $0 == .unorganized }
        }

        // Picker
        let tracker = WorkspacePickerTracker(actionType: .moveTo, triggerLocation: .topBar)
        let config = WorkspacePickerConfig(title: BundleI18n.SKResource.LarkCCM_Wiki_MoveTo_Header_Mob,
                                           action: .moveSpace,
                                           entrances: entrances,
                                           ownerTypeChecker: { isSingleFolder in
            // 检查 space 版本是否匹配
            guard context.isSingleContainerNode != isSingleFolder else { return nil }
            if isSingleFolder {
                // 1.0 文件 + 2.0 文件夹
                return BundleI18n.SKResource.CreationMobile_ECM_UnableMoveToast
            } else {
                // 2.0 文件 + 1.0 文件夹
                return BundleI18n.SKResource.CreationMobile_ECM_UnableMoveDocToast
            }
        },
                                           usingLegacyRecentAPI: !context.isSingleContainerNode,
                                           tracker: tracker,
                                           completion: { [weak self] location, picker in
            self?.confirmMoveTo(context: context, location: location, picker: picker)
        })
        let picker = WorkspacePickerFactory.createWorkspacePicker(config: config)

        return picker
    }

    func confirmMoveTo(context: MoveContext, location: WorkspacePickerLocation, picker: InteractionUIHandler) {
        switch location {
        case let .folder(location):
            verifyMoveToSpace(context: context, location: location, picker: picker)
        case let .wikiNode(location):
            verifyMoveToWiki(context: context, location: location, picker: picker)
        @unknown default:
            break
        }
    }

    // nolint: magic number
    private func getReviewerFailedTips(code: Int, userInfo: AuthorizedUserInfo) -> String {
        switch code {
        case DocsNetworkError.Code.executivesBlock.rawValue, DocsNetworkError.Code.requestMoveToBanForSeniorExecutive.rawValue:
            return BundleI18n.SKResource.LarkCCM_Wiki_Move_ReqPermission_Blocked(userInfo.getDisplayName())
        case DocsNetworkError.Code.userResign.rawValue, DocsNetworkError.Code.requestMoveToOwnerResign.rawValue:
            return BundleI18n.SKResource.LarkCCM_Wiki_Move_ReqPermission_Left
        case DocsNetworkError.Code.workspaceExceedLimited.rawValue, DocsNetworkError.Code.requestMoveToOutOfLimit.rawValue:
            return BundleI18n.SKResource.LarkCCM_Wiki_Move_ReqPermission_TooMany
        case DocsNetworkError.Code.requestMoveToNoPermission.rawValue:
            return BundleI18n.SKResource.LarkCCM_Wiki_Move_ReqPermission_SentFailed_NoPerm
        case DocsNetworkError.Code.noProperReviewer.rawValue:
            return BundleI18n.SKResource.LarkCCM_Wiki_Move_Failed_GetManagePerm
        default:
            return BundleI18n.SKResource.LarkCCM_Wiki_Move_ReqPermission_SentFailed
        }
    }
    // enable-lint: magic number
}

// MARK: - 移动前置 Alert 提醒
extension SpaceMoveInteractionHelper {
    // 移动到 space 2.0 外部文件夹，需要弹窗提醒
    private func shouldShowCrossTenantAlert(context: SpaceMoveInteractionHelper.MoveContext,
                                                   location: SpaceFolderPickerLocation) -> Bool {
        guard context.isSingleContainerNode,
              location.isSingleContainerNode,
              location.isExternal else {
            // 非 Space 2.0 外部文件夹，跳过
            return false
        }
        return true
    }

    private func shouldShowTransferAlert(context: SpaceMoveInteractionHelper.MoveContext,
                                                location: SpaceFolderPickerLocation) -> Bool {
        if location.isSingleContainerNode, location.folderType.isShareFolder {
            // 目标位置是 space 2.0 共享文件夹，需要提示
            return true
        }

        if context.isSingleContainerNode,
           let parentToken = context.parent,
           self.spaceAPI.isParentFolderShareFolder(token: parentToken, nodeType: 1) {
            // 原父文件夹是 space 2.0 共享文件夹，需要提示
            return true
        }
        // 其他情况默认不提示
        return false
    }

    private func shouldShowLegacyCrossTenantAlert(context: SpaceMoveInteractionHelper.MoveContext,
                                                         location: SpaceFolderPickerLocation) -> Bool {
        guard let permissionManager = DocsContainer.shared.resolve(PermissionManager.self) else {
            DocsLogger.error("shouldShowLegacyCrossTenantAlert, no permissionManager")
            return false
        }
        if let entryPermission = permissionManager.getPublicPermissionMeta(token: context.objToken),
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
    private func showTransferAlert(context: MoveContext, picker: InteractionUIHandler) -> Completable {
        Completable.create { observer in
            let title = BundleI18n.SKResource.LarkCCM_Workspace_MoveConfirm_Title_Mob
            let content = BundleI18n.SKResource.LarkCCM_Workspace_MoveConfirmContent_Subtitle_Mob
            let caption = BundleI18n.SKResource.LarkCCM_Workspace_MoveConfirmNotification_Subtitle_Mob
            let dialog = UDDialog()

            // owner 或 shortcut 不展示非所有者移动提示
            if !context.ownerIsCurrentUser,
               !context.isShortCut {
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
            picker.presentForInteraction(controller: dialog)
            return Disposables.create()
        }
    }

    private func showCrossTenantAlert(context: MoveContext, picker: InteractionUIHandler) -> Completable {
        Completable.create { observer in
            let typeName = context.type == .folder ? BundleI18n.SKResource.Doc_Facade_Folder : BundleI18n.SKResource.Doc_Facade_Document
            let content = BundleI18n.SKResource.CreationMobile_ECM_MovedExternalConfirmDesc(typeName)
            let caption = BundleI18n.SKResource.LarkCCM_Workspace_MoveConfirmNotification_Subtitle_Mob
            let dialog = UDDialog()
            // owner 或 shortcut 不展示非所有者移动提示
            if !context.ownerIsCurrentUser,
               !context.isShortCut {
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
            picker.presentForInteraction(controller: dialog)
            return Disposables.create()
        }
    }

}

// MARK: - Move To Space
extension SpaceMoveInteractionHelper {
    // 步骤1：前置校验目标文件夹权限，移动到外部、共享文件夹间移动场景，弹窗二次确认
    private func verifyMoveToSpace(context: SpaceMoveInteractionHelper.MoveContext,
                                          location: SpaceFolderPickerLocation,
                                          picker: InteractionUIHandler) {
        guard location.canCreateSubNode else {
            picker.showToastForInteraction(action: .failure(BundleI18n.SKResource.LarkCCM_Workspace_FolderPerm_CantMove_Tooltip))
            return
        }
        let alertConfirmation: Completable
        // 老逻辑里，最多只展示一个弹窗
        if shouldShowCrossTenantAlert(context: context, location: location) {
            alertConfirmation = showCrossTenantAlert(context: context, picker: picker)
        } else if shouldShowTransferAlert(context: context, location: location) {
            alertConfirmation = showTransferAlert(context: context, picker: picker)
        } else if shouldShowLegacyCrossTenantAlert(context: context, location: location) {
            alertConfirmation = showCrossTenantAlert(context: context, picker: picker)
        } else {
            // 没有弹窗需要展示
            alertConfirmation = .empty()
        }
        alertConfirmation.subscribe { [weak self] in
            guard let self = self else { return }
            self.confirmMoveToSpace(context: context, location: location, picker: picker)
        } onError: { error in
            DocsLogger.error("move to space alert return error", error: error)
        }
        .disposed(by: disposeBag)
    }

    // 步骤2：用户确认后，拉 reviewer 信息，走申请移动流程或直接移动
    private func confirmMoveToSpace(context: SpaceMoveInteractionHelper.MoveContext,
                                           location: SpaceFolderPickerLocation,
                                           picker: InteractionUIHandler) {
        if context.isShortCut || !context.isSingleContainerNode {
            // 移动快捷方式、1.0文档时，跳过申请流程
            DocsLogger.info("apply move shortcut or space 1.0 not supported")
            moveToSpace(context: context, location: location, picker: picker)
            return
        }

        if context.type == .folder, !UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled {
            // FG 关时，文件夹不支持申请移动
            DocsLogger.info("apply move folder disabled by FG")
            moveToSpace(context: context, location: location, picker: picker)
            return
        }

        picker.showToastForInteraction(action: .loading)
        WorkspaceManagementAPI.Space.getMoveReviewer(nodeToken: context.nodeToken,
                                                     item: nil,
                                                     targetToken: location.folderToken)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] userInfo in
                // 走申请流程
                guard let self = self else { return }
                picker.removeToastForInteraction()
                self.showApplyMoveToSpacePanel(context: context, location: location, userInfo: userInfo, picker: picker)
            } onError: { error in
                let message: String
                if DocsNetworkError.Code.noProperReviewer.rawValue == (error as NSError).code {
                    message = BundleI18n.SKResource.LarkCCM_Wiki_Move_Failed_GetManagePerm
                } else {
                    message = BundleI18n.SKResource.Doc_List_FolderSelectMove + BundleI18n.SKResource.Doc_AppUpdate_FailRetry
                }
                // 报错提示
                picker.showToastForInteraction(action: .failure(message))
            } onCompleted: { [weak self] in
                // 有权限，可以直接移动流程
                self?.moveToSpace(context: context, location: location, picker: picker)
            }
            .disposed(by: disposeBag)
    }

    // 申请分支-步骤3：展示申请移动弹窗
    private func showApplyMoveToSpacePanel(context: SpaceMoveInteractionHelper.MoveContext,
                                                  location: SpaceFolderPickerLocation,
                                                  userInfo: AuthorizedUserInfo,
                                                  picker: InteractionUIHandler) {
        let title = context.type == .folder
        ? BundleI18n.SKResource.LarkCCM_CM_RequestToMoveFolder_Title
        : BundleI18n.SKResource.LarkCCM_CM_RequestToMoveDoc_Title
        let subTitle: (String) -> String = context.type == .folder
        ? { BundleI18n.SKResource.LarkCCM_CM_NoPermToMoveFolder_WithFolderSettings_Description($0) }
        : { BundleI18n.SKResource.LarkCCM_CM_NoPermToMoveDoc_WithFolderSettings_Description($0) }
        var config = SKApplyPanelConfig(userInfo: userInfo,
                                        title: title,
                                        placeHolder: BundleI18n.SKResource.LarkCCM_Wiki_Move_ReqPermission_Context,
                                        actionName: BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AskOwner_Btn,
                                        contentProvider: subTitle)
        config.actionHandler = { [weak self] _, reason in
            self?.applyMoveToSpace(context: context,
                                   location: location,
                                   userInfo: userInfo,
                                   reason: reason,
                                   picker: picker)
        }
        if UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled {
            do {
                let url = try HelpCenterURLGenerator.generateURL(article: .cmApplyMove,
                                                                 query: ["from": "ccm_permission_move"])
                config.accessoryHandler = { controller in
                    Navigator.shared.present(url,
                                             context: ["showTemporary": false],
                                             wrap: LkNavigationController.self,
                                             from: controller)
                }
            } catch {
                DocsLogger.error("failed to generate helper center URL when apply move to space from space list", error: error)
            }
        }
        let controller = SKApplyPanelController.createController(config: config)
        picker.presentForInteraction(controller: controller)
    }

    // 申请分支-步骤4：发起申请移动请求，成功后关闭 picker，结束流程，失败时停留在申请页面
    private func applyMoveToSpace(context: SpaceMoveInteractionHelper.MoveContext,
                                         location: SpaceFolderPickerLocation,
                                         userInfo: AuthorizedUserInfo,
                                         reason: String?,
                                         picker: InteractionUIHandler) {
        picker.showToastForInteraction(action: .customLoading(BundleI18n.SKResource.CreationMobile_Comment_Add_Sending_Toast))
        WorkspaceManagementAPI.Space.applyMoveToSpace(nodeToken: context.nodeToken, targetToken: location.folderToken, reviewerID: userInfo.userID, comment: reason)
            .subscribe {
                // 申请成功
                picker.showToastForInteraction(action: .success(BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AskOwner_SentToast))
                picker.dismissForInteraction(completion: nil)
            } onError: { [weak self] error in
                // 申请失败
                guard let self = self else { return }
                let code = (error as NSError).code
                let message = self.getReviewerFailedTips(code: code, userInfo: userInfo)
                picker.showToastForInteraction(action: .failure(message))
            }
            .disposed(by: disposeBag)
    }

    // 移动分支-步骤3：有权限直接移动，发起移动请求，成功后关闭 picker，结束流程，失败时停留在 picker
    private func moveToSpace(context: SpaceMoveInteractionHelper.MoveContext,
                                    location: SpaceFolderPickerLocation,
                                    picker: InteractionUIHandler) {
        let moveEvent: Completable
        if context.isSingleContainerNode {
            moveEvent = self.spaceAPI.moveV2(nodeToken: context.nodeToken, from: context.parent, to: location.folderToken)
        } else {
            moveEvent = self.spaceAPI.move(nodeToken: context.nodeToken, from: context.parent ?? "", to: location.folderToken)
        }
        picker.showToastForInteraction(action: .loading)
        moveEvent.subscribe {
            picker.showToastForInteraction(action: .success(BundleI18n.SKResource.Doc_List_FolderSelectMove + BundleI18n.SKResource.Doc_Normal_Success))
            picker.dismissForInteraction {
                context.didMovedToSpace?()
            }
        } onError: { error in
            DocsLogger.error("move to space failed with error", error: error)
            let message: String
            let rawErrorCode = (error as NSError).code
            if let errorCode = ExplorerErrorCode(rawValue: rawErrorCode) {
                if rawErrorCode == ExplorerErrorCode.moveDontHaveSharePermission.rawValue {
                    message = BundleI18n.SKResource.Doc_Permission_MoveToNoPermission(context.name)
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
            picker.showToastForInteraction(action: .failure(message))
        }
        .disposed(by: disposeBag)
    }
}


// MARK: - Move To Wiki
extension SpaceMoveInteractionHelper {
    // 步骤1：前置校验目标 wiki 位置的权限
    private func verifyMoveToWiki(context: SpaceMoveInteractionHelper.MoveContext,
                                         location: WikiPickerLocation,
                                         picker: InteractionUIHandler) {
        guard context.isSingleContainerNode else {
            picker.showToastForInteraction(action: .failure(BundleI18n.SKResource.CreationMobile_ECM_UnableMoveToast))
            return
        }
        picker.showToastForInteraction(action: .loading)
        WorkspaceCrossNetworkAPI.checkWikiCreatePermission(location: location)
            .subscribe { [weak self] canCreate in
                guard let self else { return }
                guard canCreate else {
                    picker.showToastForInteraction(action: .failure(BundleI18n.SKResource.LarkCCM_Docs_MoveToWiki_NoMovingPermission_Toast))
                    return
                }
                picker.removeToastForInteraction()
                self.notifyWikiPermissionChange(location: location, picker: picker)
                    .subscribe { [weak self] in
                        // 开始获取 reviewer
                        self?.confirmMoveToWiki(context: context, location: location, picker: picker)
                    } onError: { error in
                        DocsLogger.info("move to wiki alert return error", error: error)
                    }
                    .disposed(by: self.disposeBag)
            } onError: { error in
                DocsLogger.error("check wiki permission failed when move to wiki", error: error)
                picker.showToastForInteraction(action: .failure(BundleI18n.SKResource.LarkCCM_Docs_MoveToWiki_Fail_Toast))
            }
            .disposed(by: disposeBag)
    }

    // 步骤2：弹窗二次确认权限变化
    private func notifyWikiPermissionChange(location: WikiPickerLocation,
                                                   picker: InteractionUIHandler) -> Completable {
        Completable.create { observer in
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
            picker.presentForInteraction(controller: dialog)
            return Disposables.create()
        }
    }

    // 步骤3：获取 reviewer，走申请或直接移动
    private func confirmMoveToWiki(context: SpaceMoveInteractionHelper.MoveContext,
                                          location: WikiPickerLocation,
                                          picker: InteractionUIHandler) {
        picker.showToastForInteraction(action: .loading)
        WorkspaceManagementAPI.Space.getMoveReviewer(nodeToken: context.nodeToken, item: nil, targetToken: location.wikiToken)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] userInfo in
                // 走申请流程
                guard let self = self else { return }
                picker.removeToastForInteraction()
                self.showApplyMoveToWikiPanel(context: context, location: location, userInfo: userInfo, picker: picker)
            } onError: { error in
                let message: String
                if DocsNetworkError.Code.noProperReviewer.rawValue == (error as NSError).code {
                    message = BundleI18n.SKResource.LarkCCM_Wiki_Move_Failed_GetManagePerm
                } else {
                    message = BundleI18n.SKResource.LarkCCM_Docs_MoveToWiki_Fail_Toast
                }
                // 报错提示
                picker.showToastForInteraction(action: .failure(message))
            } onCompleted: { [weak self] in
                // 有权限，可以直接移动流程
                self?.moveToWiki(context: context, location: location, picker: picker)
            }
            .disposed(by: disposeBag)
    }

    // 申请分支-步骤3：展示申请移动弹窗
    private func showApplyMoveToWikiPanel(context: SpaceMoveInteractionHelper.MoveContext,
                                                 location: WikiPickerLocation,
                                                 userInfo: AuthorizedUserInfo,
                                                 picker: InteractionUIHandler) {
        var config = SKApplyPanelConfig(userInfo: userInfo,
                                        title: BundleI18n.SKResource.LarkCCM_CM_RequestToMoveDoc_Title,
                                        placeHolder: BundleI18n.SKResource.LarkCCM_Wiki_Move_ReqPermission_Context,
                                        actionName: BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AskOwner_Btn,
                                        contentProvider: { BundleI18n.SKResource.LarkCCM_CM_NoPermToMoveDoc_WithFolderSettings_Description($0) })
        config.actionHandler = { [weak self] _, reason in
            self?.applyMoveToWiki(context: context,
                                  location: location,
                                  userInfo: userInfo,
                                  reason: reason,
                                  picker: picker)
        }
        if UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled {
            do {
                let url = try HelpCenterURLGenerator.generateURL(article: .cmApplyMove,
                                                                 query: ["from": "ccm_permission_move"])
                config.accessoryHandler = { controller in
                    Navigator.shared.present(url,
                                             context: ["showTemporary": false],
                                             wrap: LkNavigationController.self,
                                             from: controller)
                }
            } catch {
                DocsLogger.error("failed to generate helper center URL when apply move to wiki from space list", error: error)
            }
        }
        let controller = SKApplyPanelController.createController(config: config)
        picker.presentForInteraction(controller: controller)
    }

    // 申请分支-步骤4：发起申请移动请求，成功后关闭 picker，结束流程，失败时停留在申请页面
    private func applyMoveToWiki(context: SpaceMoveInteractionHelper.MoveContext,
                                        location: WikiPickerLocation,
                                        userInfo: AuthorizedUserInfo,
                                        reason: String?,
                                        picker: InteractionUIHandler) {
        picker.showToastForInteraction(action: .customLoading(BundleI18n.SKResource.CreationMobile_Comment_Add_Sending_Toast))
        WorkspaceManagementAPI.Space.applyMoveToWiki(item: context.spaceMeta, location: location, reviewerID: userInfo.userID, comment: reason)
            .subscribe {
                // 申请成功
                picker.showToastForInteraction(action: .success(BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AskOwner_SentToast))
                picker.dismissForInteraction(completion: nil)
            } onError: { [weak self] error in
                // 申请失败
                let code = (error as NSError).code
                let message = self?.getReviewerFailedTips(code: code, userInfo: userInfo) ?? ""
                picker.showToastForInteraction(action: .failure(message))
            }
            .disposed(by: disposeBag)
    }

    // 移动分支-步骤3：有权限直接移动，发起移动请求，成功后关闭 picker，结束流程，失败时停留在 picker
    private func moveToWiki(context: SpaceMoveInteractionHelper.MoveContext,
                            location: WikiPickerLocation,
                            picker: InteractionUIHandler) {
        picker.showToastForInteraction(action: .loading)
        self.spaceAPI.moveToWiki(item: context.spaceMeta,
                                 nodeToken: context.nodeToken,
                                 parentToken: context.parent,
                                 location: location)
            .subscribe { [weak self] status in
                switch status {
                case .moving:
                    spaceAssertionFailure("moving status should not be return")
                    let message = BundleI18n.SKResource.Doc_List_FolderSelectMove + BundleI18n.SKResource.Doc_AppUpdate_FailRetry
                    picker.showToastForInteraction(action: .failure(message))
                case .succeed(let wikiToken):
                    picker.showToastForInteraction(action: .success(BundleI18n.SKResource.Doc_Wiki_MoveSuccess))
                    picker.dismissForInteraction {
                        context.didMovedToWiki?(wikiToken)
                    }
                case let .failed(code):
                    let message = self?.getMoveToWikiFailedTips(code: code) ?? ""
                    picker.showToastForInteraction(action: .failure(message))
                }
            } onError: { error in
                DocsLogger.error("move to space failed with error", error: error)
                let message: String
                let rawErrorCode = (error as NSError).code
                if let errorCode = ExplorerErrorCode(rawValue: rawErrorCode) {
                    if rawErrorCode == ExplorerErrorCode.moveDontHaveSharePermission.rawValue {
                        message = BundleI18n.SKResource.Doc_Permission_MoveToNoPermission(context.name)
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
                picker.showToastForInteraction(action: .failure(message))
            }
            .disposed(by: disposeBag)
    }

    private func getMoveToWikiFailedTips(code: Int) -> String {
        switch code {
        case MoveToWikiFailErrorCode.exceedMaxLevel.rawValue:
            return BundleI18n.SKResource.LarkCCM_Wiki_Menu_ImportToWiki_Import_failed_MaxLevel
        case MoveToWikiFailErrorCode.noPermission.rawValue:
            return BundleI18n.SKResource.LarkCCM_Docs_MoveToWiki_NoMovingPermission_Toast
        case MoveToWikiFailErrorCode.alreadyExist.rawValue:
            return BundleI18n.SKResource.LarkCCM_Wiki_ImportToWiki_Exist
        case MoveToWikiFailErrorCode.retentionRestricted.rawValue:
            return BundleI18n.SKResource.LarkCCM_Docs_Retention_Settings_Restricted
        default:
            return BundleI18n.SKResource.LarkCCM_Docs_MoveToWiki_Fail_Toast
        }
    }

    enum MoveToWikiFailErrorCode: Int {
        /// 已达子页面层级数上限
        case exceedMaxLevel = 3
        /// 无权限
        case noPermission = 4
        /// 已经存在
        case alreadyExist = 6
        /// 已设定保留标签，不支持移动
        case retentionRestricted = 9
    }
}

// MARK: - 界面上的 Toast/Loading 的交互
public protocol InteractionUIHandler: AnyObject {
    func presentForInteraction(controller: UIViewController)
    func dismissForInteraction(completion: (() -> Void)?)
    func showToastForInteraction(action: HUDAction)
    func removeToastForInteraction()
}

public enum HUDAction {
    case customLoading(_ content: String)
    case failure(_ content: String)
    case success(_ content: String)
    case tips(_ content: String)
    case custom(config: UDToastConfig, operationCallback: ((String?) -> Void)?)
    public static let loading: HUDAction = .customLoading(BundleI18n.SKResource.Doc_Facade_Loading)
}

extension UIViewController: InteractionUIHandler {
    public func presentForInteraction(controller: UIViewController) {
        present(controller, animated: true)
    }
    public func dismissForInteraction(completion: (() -> Void)?) {
        if let presentingVC = presentingViewController {
            presentingVC.dismiss(animated: true, completion: completion)
        } else {
            dismiss(animated: true, completion: completion)
        }
    }
    public func showToastForInteraction(action: HUDAction) {
        let targetView: UIView = view.window ?? view
        switch action {
        case let .customLoading(message):
            UDToast.showLoading(with: message, on: targetView)
        case let .failure(message):
            UDToast.showFailure(with: message, on: targetView)
        case let .success(message):
            UDToast.showSuccess(with: message, on: targetView)
        case let .tips(message):
            UDToast.showTips(with: message, on: targetView)
        case let .custom(config, operationCallback):
            UDToast.showToast(with: config, on: targetView, operationCallBack: operationCallback)
        }
    }

    public func removeToastForInteraction() {
        UDToast.removeToast(on: view.window ?? view)
    }
}
