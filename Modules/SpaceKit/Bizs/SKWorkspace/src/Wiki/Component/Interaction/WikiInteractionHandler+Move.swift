//
//  WikiInteractionHandler+Move.swift
//  SKWorkspace
//
//  Created by Weston Wu on 2023/7/11.
//

import Foundation
import SKCommon
import SKResource
import SKInfra
import SKFoundation
import RxSwift
import RxRelay
import SpaceInterface
import UniverseDesignToast
import UniverseDesignDialog
import EENavigator
import LarkUIKit

// 移除场景没有 picker，导致 UI 跳转逻辑有特化，单独抽象一下
public protocol WikiInteractionUIHandler: AnyObject {
    func presentForWikiInteraction(controller: UIViewController)
    func dismissForWikiInteraction(controller: UIViewController?)
    func showToastForWikiInteraction(action: WikiTreeViewAction.HUDAction)
    func removeToastForWikiInteraction()
}

extension WikiInteractionUIHandler {
    func dismissForWikiInteraction() {
        dismissForWikiInteraction(controller: nil)
    }
}

extension UIViewController: WikiInteractionUIHandler {
    public func presentForWikiInteraction(controller: UIViewController) {
        present(controller, animated: true)
    }
    public func dismissForWikiInteraction(controller: UIViewController?) {
        if let presentingVC = presentingViewController {
            presentingVC.dismiss(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    public func showToastForWikiInteraction(action: WikiTreeViewAction.HUDAction) {
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

    public func removeToastForWikiInteraction() {
        UDToast.removeToast(on: view.window ?? view)
    }
}

extension WikiInteractionHandler {
    public struct MoveContext {

        public let subContext: Context
        public let canMove: Bool
        public let permissionLocked: Bool
        public let hasChild: Bool
        /// 移动到 Wiki 成功后新的 SortID 和 parentMeta
        public let didMovedToWiki: (Double, WikiMeta) -> Void
        public let didMovedToSpace: (WikiObjInfo.SpaceInfo) -> Void

        public init(subContext: WikiInteractionHandler.Context,
                    canMove: Bool,
                    permissionLocked: Bool,
                    hasChild: Bool,
                    didMovedToWiki: @escaping (Double, WikiMeta) -> Void,
                    didMovedToSpace: @escaping (WikiObjInfo.SpaceInfo) -> Void) {
            self.subContext = subContext
            self.canMove = canMove
            self.permissionLocked = permissionLocked
            self.hasChild = hasChild
            self.didMovedToWiki = didMovedToWiki
            self.didMovedToSpace = didMovedToSpace
        }
    }

    public typealias MovePickerHandler = ShortcutPickerHandler

    public func entrancesForMove(moveContext: MoveContext) -> [WorkspacePickerEntrance] {
        let context = moveContext.subContext
        if moveToSpaceEnable(context: context) {
            var entrances = [WorkspacePickerEntrance].wikiAndSpace
            if !context.isOwner {
                entrances.removeAll { $0 == .unorganized }
            }
            return entrances
        } else {
            return .wikiOnly
        }
    }

    private func moveToSpaceEnable(context: Context) -> Bool {
        guard SettingConfig.singleContainerEnable else { return false }
        guard !context.isShortcut else { return false }
        return true
    }

    public func makeMovePicker(context: MoveContext,
                               triggerLocation: WorkspacePickerTracker.TriggerLocation,
                               entrances: [WorkspacePickerEntrance],
                               handler: @escaping MovePickerHandler) -> UIViewController {
        let tracker = WorkspacePickerTracker(actionType: .moveTo, triggerLocation: triggerLocation)
        let config = WorkspacePickerConfig(title: BundleI18n.SKResource.LarkCCM_Wiki_MoveTo_Header_Mob,
                                           action: .moveWiki,
                                           entrances: entrances,
                                           ownerTypeChecker: { $0 ? nil : BundleI18n.SKResource.CreationMobile_ECM_UnableMoveDocToast },
                                           disabledWikiToken: context.subContext.wikiToken,
                                           tracker: tracker) { location, picker in
            handler(picker, location)
        }
        return WorkspacePickerFactory.createWorkspacePicker(config: config)
    }

    public func confirmMoveTo(location: WorkspacePickerLocation,
                              context: MoveContext,
                              picker: WikiInteractionUIHandler) {
        switch location {
        case let .wikiNode(wikiLocation):
            verifyMoveToWiki(context: context,
                             targetMeta: WikiMeta(location: wikiLocation),
                             isRootNode: wikiLocation.isMainRoot,
                             picker: picker)
        case let .folder(folderLocation):
            guard folderLocation.canCreateSubNode else {
                picker.showToastForWikiInteraction(action: .failure(BundleI18n.SKResource.LarkCCM_Workspace_FolderPerm_CantMove_Tooltip))
                return
            }
            verifyMoveToSpace(moveContext: context,
                              location: .folder(folderToken: folderLocation.folderToken),
                              targetModule: folderLocation.targetModule,
                              targetFolderType: folderLocation.targetFolderType,
                              picker: picker)
        }
    }

    private func verifyTargetWikiPermission(targetMeta: WikiMeta, isRootNode: Bool) -> Single<Bool> {
        if isRootNode {
            return networkAPI.getSpacePermission(spaceId: targetMeta.spaceID)
                .map(\.canEditFirstLevel)
        } else {
            return networkAPI.getNodePermission(spaceId: targetMeta.spaceID, wikiToken: targetMeta.wikiToken)
                .map(\.canCreate)
        }
    }

    private func verifyMoveToWiki(context: MoveContext,
                                  targetMeta: WikiMeta,
                                  isRootNode: Bool,
                                  picker: WikiInteractionUIHandler) {
        let currentParentToken = context.subContext.parentWikiToken ?? ""
        // 这里需要找个方法取到 oldParentToken
        guard currentParentToken != targetMeta.wikiToken else {
            picker.showToastForWikiInteraction(action: .failure(BundleI18n.SKResource.Doc_Wiki_Move_SelectFather))
            return
        }
        picker.showToastForWikiInteraction(action: .loading)
        verifyTargetWikiPermission(targetMeta: targetMeta, isRootNode: isRootNode)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self, weak picker] canMoveIn in
                guard let self, let picker else { return }
                picker.removeToastForWikiInteraction()
                guard canMoveIn else {
                    picker.showToastForWikiInteraction(action: .failure(BundleI18n.SKResource.LarkCCM_Docs_MoveToWiki_NoMovingPermission_Toast))
                    return
                }
                self.verifyMoveToWikiPermissionChange(moveContext: context,
                                                      targetMeta: targetMeta,
                                                      picker: picker)
            } onError: { [weak self, weak picker] error in
                DocsLogger.error("verify move target permission failed", error: error)
                guard let self, let picker else { return }
                picker.removeToastForWikiInteraction()
                // 与前端对齐，前置鉴权失败放行后续的操作
                self.verifyMoveToWikiPermissionChange(moveContext: context,
                                                      targetMeta: targetMeta,
                                                      picker: picker)
            }
            .disposed(by: disposeBag)
    }

    private func verifyMoveToWikiPermissionChange(moveContext: MoveContext,
                                                  targetMeta: WikiMeta,
                                                  picker: WikiInteractionUIHandler) {
        let context = moveContext.subContext
        WikiStatistic.permissonChangeView(context: context, viewTitle: .moveTo)
        WikiStatistic.clickTreeNodeMove(wikiToken: context.wikiToken,
                                        fileType: context.objType.name)

        // FG 关或者 spaceID 没变，都不需要检查单页面 owner 场景
        guard LKFeatureGating.wikiSinglePageOwner, context.spaceID != targetMeta.spaceID else {
            notifyWikiPermissionChange(moveContext: moveContext,
                                       targetMeta: targetMeta,
                                       picker: picker)
            return
        }
        picker.showToastForWikiInteraction(action: .loading)
        networkAPI.rxGetCoupleSpaceInfo(firstSpaceId: context.spaceID, secondSpaceId: targetMeta.spaceID)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self, weak picker] (space1, space2) in
                guard let self, let picker else { return }
                picker.removeToastForWikiInteraction()
                if space2.ownerPermType == WikiSpace.OwnerPermType.singlePage.rawValue,
                   space1.ownerPermType != WikiSpace.OwnerPermType.singlePage.rawValue {
                    self.notifyWikiOwnerPermTypeChange(moveContext: moveContext, targetMeta: targetMeta, picker: picker)
                } else {
                    self.notifyWikiPermissionChange(moveContext: moveContext,
                                                    targetMeta: targetMeta,
                                                    picker: picker)
                }
            } onError: { [weak self, weak picker] error in
                DocsLogger.error("get space error \(error)")
                guard let self, let picker else { return }
                picker.removeToastForWikiInteraction()
                self.notifyWikiPermissionChange(moveContext: moveContext,
                                                targetMeta: targetMeta,
                                                picker: picker)
            }
            .disposed(by: disposeBag)
    }

    //owner权限类型变化   空间配置所有者是容器权限--> 空间配置所有者是页面权限
    private func notifyWikiOwnerPermTypeChange(moveContext: MoveContext,
                                               targetMeta: WikiMeta,
                                               picker: WikiInteractionUIHandler) {
        let content = BundleI18n.SKResource.CreationMobile_Wiki_SinglePageFA_Moved
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Wiki_MovePage_ConfirmMove_Title)
        dialog.setContent(text: content, checkButton: false)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
        dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: { [weak self, weak picker] in
            guard let self, let picker else { return }
            WikiStatistic.confirmTreeNodeMove(wikiToken: moveContext.subContext.wikiToken,
                                              fileType: moveContext.subContext.objType.name)
            self.confirmMoveToWiki(moveContext: moveContext, targetMeta: targetMeta, picker: picker)
        })
        picker.presentForWikiInteraction(controller: dialog)
    }

    // 移动后，如果当前节点未加锁，需要提示权限将会变化
    private func notifyWikiPermissionChange(moveContext: MoveContext,
                                            targetMeta: WikiMeta,
                                            picker: WikiInteractionUIHandler) {
        let context = moveContext.subContext
        if moveContext.permissionLocked {
            // 节点已经加锁，移动后权限无变化，无需确认直接继续移动
            confirmMoveToWiki(moveContext: moveContext,
                              targetMeta: targetMeta,
                              picker: picker)
            return
        }

        // 节点没加锁，移动后权限会跟随父节点，需要二次确认
        let dialog = UDDialog()
        let content = BundleI18n.SKResource.CreationMobile_Wiki_Permission_OnceRemoved_Placeholder
        let caption = BundleI18n.SKResource.LarkCCM_Workspace_MoveConfirmPage_Wiki_Subtitle_Mob
        var title = BundleI18n.SKResource.LarkCCM_Workspace_MoveConfirm_Title_Mob
        if !context.isShortcut {
            title = BundleI18n.SKResource.LarkCCM_Workspace_MoveConfirm_Title_Mob
            dialog.setContent(text: content, caption: caption)
        } else {
            dialog.setContent(text: content)
        }
        dialog.setTitle(text: title)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
        dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: { [weak self, weak picker] in
            guard let self, let picker else { return }
            WikiStatistic.confirmTreeNodeMove(wikiToken: context.wikiToken,
                                              fileType: context.objType.name)
            self.confirmMoveToWiki(moveContext: moveContext,
                                   targetMeta: targetMeta,
                                   picker: picker)
        })
        picker.presentForWikiInteraction(controller: dialog)
    }

    private func confirmMoveToWiki(moveContext: MoveContext, targetMeta: WikiMeta, picker: WikiInteractionUIHandler) {
        guard moveContext.canMove else {
            applyMoveToWiki(moveContext: moveContext, targetMeta: targetMeta, picker: picker)
            return
        }
        let context = moveContext.subContext
        picker.showToastForWikiInteraction(action: .customLoading(BundleI18n.SKResource.Doc_Wiki_MovePageMoving))
        networkAPI.moveNode(sourceMeta: context.wikiMeta,
                            originParent: context.parentWikiToken ?? "",
                            targetMeta: targetMeta,
                            synergyUUID: synergyUUID)
        .observeOn(MainScheduler.instance)
        .subscribe { [weak picker] newSortID in
            guard let picker else { return }
            picker.showToastForWikiInteraction(action: .success(BundleI18n.SKResource.Doc_Wiki_MoveSuccess))
            picker.dismissForWikiInteraction()
            moveContext.didMovedToWiki(newSortID, targetMeta)
        } onError: { [weak picker] error in
            guard let picker else { return }
            let error = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
            picker.showToastForWikiInteraction(action: .failure(error.moveErrorDescription(pageName: context.name ?? "")))
        }
        .disposed(by: disposeBag)
    }

    private func applyMoveToWiki(moveContext: MoveContext, targetMeta: WikiMeta, picker: WikiInteractionUIHandler) {
        picker.showToastForWikiInteraction(action: .loading)
        prepareApplyForMove(context: moveContext.subContext, viewTitle: .moveTo) { [weak self, weak picker] controller, reason in
            guard let self = self else { return }
            self.confirmApplyForMoveToWiki(context: moveContext.subContext,
                                           targetMeta: targetMeta,
                                           authorizedUserInfo: controller.config.userInfo,
                                           reason: reason,
                                           controller: controller)
            .subscribe(onCompleted: {
                guard let picker else { return }
                picker.showToastForWikiInteraction(action: .success(BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AskOwner_SentToast))
                picker.dismissForWikiInteraction(controller: controller)
            })
            .disposed(by: self.disposeBag)
        }
        .subscribe(onSuccess: { [weak picker] controller in
            guard let picker else { return }
            picker.removeToastForWikiInteraction()
            picker.presentForWikiInteraction(controller: controller)
            WikiStatistic.applyMoveOutView(context: moveContext.subContext, viewTitle: .moveTo)
        }, onError: { [weak picker] error in
            DocsLogger.error("get move node authorized userInfo failed", error: error)
            guard let picker else { return }
            if let docsError = error as? DocsNetworkError,
               let message = docsError.code.errorMessage {
                picker.showToastForWikiInteraction(action: .failure(message))
            } else {
                let error = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
                let message = error.moveErrorDescription(pageName: moveContext.subContext.name ?? "")
                picker.showToastForWikiInteraction(action: .failure(message))
            }
        })
        .disposed(by: disposeBag)
    }

    // 请求申请人信息，并返回一个 controller 供调用方展示
    private func prepareApplyForMove(context: Context,
                                     viewTitle: WikiStatistic.ViewTitle,
                                     actionHandler: ((SKApplyPanelController, String?) -> Void)?) -> Single<UIViewController> {
        // 拉取有权限的人
        return networkAPI.getMoveNodeAuthorizedUserInfo(wikiToken: context.wikiToken,
                                                        spaceID: context.spaceID)
        .observeOn(MainScheduler.instance)
        .map { userInfo in
            var config = SKApplyPanelConfig(userInfo: userInfo,
                                            title: BundleI18n.SKResource.LarkCCM_CM_RequestToMoveDoc_Title,
                                            placeHolder: BundleI18n.SKResource.LarkCCM_Wiki_Move_ReqPermission_Context,
                                            actionName: BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AskOwner_Btn,
                                            contentProvider: { BundleI18n.SKResource.LarkCCM_CM_NoPermToMoveDoc_WithWikiSettings_Description($0) })
            config.cancelHandler = { reason in
                WikiStatistic.applyMoveOutClick(context: context,
                                                clickType: .cancel,
                                                viewTitle: viewTitle,
                                                haveComment: (reason?.isEmpty != false),
                                                target: DocsTracker.EventType.noneTargetView.rawValue)
            }
            config.actionHandler = actionHandler
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
                    DocsLogger.error("failed to generate helper center URL when apply move from wiki tree", error: error)
                }
            }
            let controller = SKApplyPanelController.createController(config: config)
            return controller
        }
    }

    private func confirmApplyForMoveToWiki(context: Context,
                                           targetMeta: WikiMeta,
                                           authorizedUserInfo: WikiAuthorizedUserInfo,
                                           reason: String?,
                                           controller: UIViewController) -> Completable {
        WikiStatistic.applyMoveOutClick(context: context,
                                        clickType: .send,
                                        viewTitle: .moveTo,
                                        haveComment: (reason?.isEmpty == false),
                                        target: DocsTracker.EventType.noneTargetView.rawValue)
        UDToast.showLoading(with: BundleI18n.SKResource.CreationMobile_Comment_Add_Sending_Toast,
                            on: controller.view.window ?? controller.view)
        let parentToken = context.parentWikiToken ?? ""
        return networkAPI.applyMoveToWiki(sourceMeta: context.wikiMeta,
                                          currentParentWikiToken: parentToken,
                                          targetMeta: targetMeta,
                                          reason: reason,
                                          authorizedUserID: authorizedUserInfo.userID)
        .asCompletable()
        .observeOn(MainScheduler.instance)
        .do(onError: { [weak controller] error in
            DocsLogger.error("submit move to space apply failed", error: error)
            guard let controller else { return }
            UDToast.removeToast(on: controller.view.window ?? controller.view)
            let errorMessage: String
            if let docsError = error as? DocsNetworkError,
               let message = docsError.code.errorMessage {
                errorMessage = message
            } else {
                let error = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
                if error == .applyForbiddenByAdmin {
                    errorMessage = BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AdminNotificationOff
                } else {
                    errorMessage = error.moveErrorDescription(pageName: context.name ?? "")
                }
            }
            UDToast.showFailure(with: errorMessage, on: controller.view.window ?? controller.view)
        }, onCompleted: { [weak controller] in
            guard let controller = controller else { return }
            UDToast.removeToast(on: controller.view.window ?? controller.view)
        })
    }
}

extension WikiInteractionHandler {
    func verifyMoveToSpace(moveContext: MoveContext,
                           location: WikiMoveToSpaceLocation,
                           targetModule: WikiStatistic.TargetModule,
                           targetFolderType: WikiStatistic.TargetFolderType,
                           picker: WikiInteractionUIHandler) {
        let dialog = makeConfirmMoveToSpaceDialog(moveContext: moveContext, location: location) { [weak self, weak picker] confirm in
            guard let self, let picker else { return }
            guard confirm else {
                WikiStatistic.permissonChangeClick(context: moveContext.subContext,
                                                   clickType: .cancel,
                                                   viewTitle: .moveToSpace,
                                                   target: DocsTracker.EventType.noneTargetView.rawValue)
                return
            }
            if moveContext.canMove {
                self.startMoveToSpace(moveContext: moveContext,
                                      location: location,
                                      targetModule: targetModule,
                                      targetFolderType: targetFolderType,
                                      picker: picker)
            } else {
                self.startApplyMoveToSpace(moveContext: moveContext,
                                           location: location,
                                           targetModule: targetModule,
                                           targetFolderType: targetFolderType,
                                           picker: picker)
            }
        }
        picker.presentForWikiInteraction(controller: dialog)
    }

    // 弹框二次确认，返回一个 controller 供调用方自行 present，原因是侧滑移除和 picker 中的展示逻辑不一样
    private func makeConfirmMoveToSpaceDialog(moveContext: MoveContext,
                                              location: WikiMoveToSpaceLocation,
                                              completion: @escaping (Bool) -> Void) -> UIViewController {
        let dialog = UDDialog()
        switch location {
        case .ownerSpace:
            let title = BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_MoveTips_Title
            let content = BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_MoveTips_Subtitle
            dialog.setTitle(text: title)
            if moveContext.hasChild {
                dialog.setContent(text: content, caption: BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_MoveTips_NoticeSubpage)
            } else {
                dialog.setContent(text: content)
            }
        case .folder:
            dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Wiki_MovePage_ConfirmMove_Title)
            if moveContext.hasChild {
                dialog.setContent(text: BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_OnceRemoved_Permission,
                                  caption: BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_OnceRemoved_Permission2)
            } else {
                dialog.setContent(text: BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_OnceRemoved_Permission)
            }
        }
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion: {
            DocsLogger.info("move to space cancelled")
            completion(false)
        })
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: {
            DocsLogger.info("move to space confirmed")
            completion(true)
        })
        WikiStatistic.permissonChangeView(context: moveContext.subContext, viewTitle: .moveToSpace)
        return dialog
    }


    private func startMoveToSpace(moveContext: MoveContext,
                                  location: WikiMoveToSpaceLocation,
                                  targetModule: WikiStatistic.TargetModule,
                                  targetFolderType: WikiStatistic.TargetFolderType,
                                  picker: WikiInteractionUIHandler) {
        WikiStatistic.permissonChangeClick(context: moveContext.subContext,
                                           clickType: .confirm,
                                           viewTitle: .moveToSpace,
                                           target: DocsTracker.EventType.noneTargetView.rawValue)
        picker.showToastForWikiInteraction(action: .loading)
        confirmMoveToSpace(wikiToken: moveContext.subContext.wikiToken, location: location)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak picker] info in
                guard let picker else { return }
                picker.removeToastForWikiInteraction()
                switch location {
                case let .folder(folderToken):
                    let context = moveContext.subContext
                    picker.showToastForWikiInteraction(action: .success(BundleI18n.SKResource.Doc_Wiki_MoveSuccess))
                    WikiStatistic.clickFileLocationSelect(targetSpaceId: folderToken,
                                                          fileId: context.objToken,
                                                          fileType: context.objType.name,
                                                          filePageToken: context.objToken,
                                                          viewTitle: .moveTo,
                                                          originSpaceId: context.spaceID,
                                                          originWikiToken: context.wikiToken,
                                                          isShortcut: context.isShortcut,
                                                          triggerLocation: .wikiTree,
                                                          targetModule: targetModule,
                                                          targetFolderType: targetFolderType)
                case .ownerSpace:
                    picker.showToastForWikiInteraction(action: .success(BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_Success))
                }
                picker.dismissForWikiInteraction()
                moveContext.didMovedToSpace(info)
            }, onError: { [weak picker] error in
                DocsLogger.error("move node to space failed", error: error)
                guard let picker else { return }
                picker.removeToastForWikiInteraction()
                let message: String
                if let rxError = error as? RxError, case .timeout = rxError {
                    message = BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_Error_CheckStatusFailedAndRetry
                } else if let docsError = error as? DocsNetworkError,
                          let errorMessage = docsError.code.errorMessage {
                    if docsError.code == .forbidden {
                        // 特化文案
                        message = BundleI18n.SKResource.LarkCCM_Docs_ActionFailed_NoTargetPermission_Mob
                    } else {
                        message = errorMessage
                    }
                } else {
                    let error = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
                    message = error.moveToSpaceErrorDescription(pageName: moveContext.subContext.name ?? "")
                }
                picker.showToastForWikiInteraction(action: .failure(message))
            })
            .disposed(by: disposeBag)
    }


    // 确认并执行 moveToSpace 操作，并在成功后更新目录树，但需要业务方自行处理 UI 逻辑（toast 等）
    private func confirmMoveToSpace(wikiToken: String, location: WikiMoveToSpaceLocation) -> Single<WikiObjInfo.SpaceInfo> {
        // 发起 + 轮询
        return networkAPI.moveToSpace(wikiToken: wikiToken, location: location, synergyUUID: synergyUUID)
    }

    private func startApplyMoveToSpace(moveContext: MoveContext,
                                       location: WikiMoveToSpaceLocation,
                                       targetModule: WikiStatistic.TargetModule,
                                       targetFolderType: WikiStatistic.TargetFolderType,
                                       picker: WikiInteractionUIHandler) {
        WikiStatistic.permissonChangeClick(context: moveContext.subContext,
                                           clickType: .confirm,
                                           viewTitle: .moveToSpace,
                                           target: DocsTracker.EventType.wikiApplyMoveOutView.rawValue)
        picker.showToastForWikiInteraction(action: .loading)
        prepareApplyForMove(context: moveContext.subContext, viewTitle: .moveToSpace) { [weak self] controller, reason in
            guard let self else { return }
            self.confirmApplyForMoveToSpace(context: moveContext.subContext,
                                            location: location,
                                            authorizedUserInfo: controller.config.userInfo,
                                            reason: reason,
                                            controller: controller)
            .subscribe(onCompleted: { [weak picker] in
                guard let picker else { return }
                picker.showToastForWikiInteraction(action: .success(BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AskOwner_SentToast))
                picker.dismissForWikiInteraction(controller: controller)
            })
            .disposed(by: self.disposeBag)
        }
        .subscribe(onSuccess: { [weak picker] controller in
            guard let picker else { return }
            picker.removeToastForWikiInteraction()
            picker.presentForWikiInteraction(controller: controller)
            WikiStatistic.applyMoveOutView(context: moveContext.subContext, viewTitle: .moveToSpace)
        }, onError: { [weak picker] error in
            DocsLogger.error("get move node authorized userInfo failed", error: error)
            guard let picker else { return }
            picker.removeToastForWikiInteraction()
            let message: String
            if let docsError = error as? DocsNetworkError,
               let errorMessage = docsError.code.errorMessage {
                if docsError.code == .forbidden {
                    // 特化文案
                    message = BundleI18n.SKResource.LarkCCM_Docs_ActionFailed_NoTargetPermission_Mob
                } else {
                    message = errorMessage
                }
            } else {
                let error = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
                message = error.moveToSpaceErrorDescription(pageName: moveContext.subContext.name ?? "")
            }
            picker.showToastForWikiInteraction(action: .failure(message))
        })
        .disposed(by: disposeBag)
    }

    // 封装 applyPanel 内的申请逻辑，成功后的 UI 需要业务方自行处理
    private func confirmApplyForMoveToSpace(context: Context,
                                            location: WikiMoveToSpaceLocation,
                                            authorizedUserInfo: WikiAuthorizedUserInfo,
                                            reason: String?,
                                            controller: UIViewController) -> Completable {
        WikiStatistic.applyMoveOutClick(context: context,
                                        clickType: .send,
                                        viewTitle: .moveToSpace,
                                        haveComment: (reason?.isEmpty == false),
                                        target: DocsTracker.EventType.noneTargetView.rawValue)
        UDToast.showLoading(with: BundleI18n.SKResource.CreationMobile_Comment_Add_Sending_Toast, on: controller.view.window ?? controller.view)
        return networkAPI.applyMoveToSpace(wikiToken: context.wikiToken,
                                           location: location,
                                           reason: reason,
                                           authorizedUserID: authorizedUserInfo.userID)
        .asCompletable()
        .observeOn(MainScheduler.instance)
        .do(onError: { [weak controller] error in
            DocsLogger.error("submit move to space apply failed", error: error)
            guard let controller = controller else { return }
            UDToast.removeToast(on: controller.view.window ?? controller.view)
            let errorMessage: String
            if let docsError = error as? DocsNetworkError,
               let message = docsError.code.errorMessage {
                errorMessage = message
            } else {
                let error = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
                if error == .applyForbiddenByAdmin {
                    errorMessage = BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AdminNotificationOff
                } else {
                    errorMessage = error.moveToSpaceErrorDescription(pageName: context.name ?? "")
                }
            }
            UDToast.showFailure(with: errorMessage, on: controller.view.window ?? controller.view)
        }, onCompleted: { [weak controller] in
            guard let controller = controller else { return }
            UDToast.removeToast(on: controller.view.window ?? controller.view)
        })
    }
}
