//
//  WikiTreeMoreProvider+Delete.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/8/8.
//

import Foundation
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignDialog
import RxSwift
import SKFoundation
import SKCommon
import SKResource
import SKUIKit
import EENavigator
import LarkUIKit

extension WikiMainTreeMoreProvider {
    
    func didClickDelete(meta: WikiTreeNodeMeta, permission: WikiTreeNodePermission?, inClipSection: Bool, sourceView: UIView) {
        WikiStatistic.clickTreeNodeDelete(wikiToken: meta.wikiToken,
                                          fileType: meta.objType.name)
        WikiStatistic.clickWikiTreeMore(click: .delete,
                                        isFavorites: inClipSection,
                                        target: DocsTracker.EventType.wikiDeleteConfirmView.rawValue,
                                        meta: meta)
        WikiStatistic.deleteConfirmView(meta: meta)
        if !meta.hasChild || meta.isShortcut {
            // 叶子节点和快捷方式 默认使用「全部删除」逻辑处理
            verifyDelete(meta: meta, inClipSection: inClipSection)
        } else {
            showDeleteScopeSelectVC(meta: meta, permission: permission, inClipSection: inClipSection, sourceView: sourceView)
        }
    }
    
    private func showDeleteScopeSelectVC(meta: WikiTreeNodeMeta, permission: WikiTreeNodePermission?, inClipSection: Bool, sourceView: UIView) {
        let canSingleDelete: Bool
        if let permission {
            canSingleDelete = permission.showSingleDelete
        } else {
            canSingleDelete = nodePermissionStorage[meta.wikiToken]?.showSingleDelete ?? false
        }
        let singleDeleteItems = WikiDeleteScopeSelectItem(title: BundleI18n.SKResource.LarkCCM_Workspace_DeletePage_CurrentOnly_Radio,
                                                          subTitle: BundleI18n.SKResource.LarkCCM_Workspace_DeletePage_WithSub_Descrip,
                                                          selected: false,
                                                          scopeType: .single,
                                                          disableReason: canSingleDelete ? nil : BundleI18n.SKResource.LarkCCM_CM_RemoveOrDeleteSubpageFirst_Tooltip)
        let allDeleteItems = WikiDeleteScopeSelectItem(title: BundleI18n.SKResource.LarkCCM_Workspace_DeletePage_WithSub_Radio,
                                                       subTitle: BundleI18n.SKResource.CreationMobile_Common_DeleteOthersPage,
                                                       selected: false,
                                                       scopeType: .all)
        let nodeDeleteScopeVC = WikiDeleteScopeSelectViewController(items: [singleDeleteItems, allDeleteItems])
        
        var direction: UIPopoverArrowDirection = []
        if let center = sourceView.superview?.convert(sourceView.frame, to: sourceView.window),
           let windowCenter = sourceView.window?.center {
            if center.origin.y > windowCenter.y {
                // cell位于屏幕中央偏下方
                direction = [.left, .down]
                DocsLogger.info("wiki more: delete scope vc from cell‘s centerY is \(center.origin.y) in top")
            } else {
                // cell位于屏幕中央上方
                direction = [.left, .up]
                DocsLogger.info("wiki more: delete scope vc from cell‘s centerY is \(center.origin.y) in under")
            }
        } else {
            direction = [.any]
            spaceAssertionFailureWithoutLog("can not get view's window in wiki tree more delete")
        }
        nodeDeleteScopeVC.setupPopover(sourceView: sourceView, direction: direction)
        nodeDeleteScopeVC.confirmCompletion = { [weak self] delteType in
            guard let self = self else { return }
            switch delteType {
            case .all:
                self.confirmDelete(meta: meta, inClipSection: inClipSection)
            case .single:
                self.deleteSingleNode(meta: meta, inClipSection: inClipSection)
            default:
                spaceAssertionFailure("if none, confirm button should disabled, can not go here!")
                return
            }
        }
        actionInput.accept(.present(provider: { _ in
            nodeDeleteScopeVC
        }))
    }
    
    private func deleteSingleNode(meta: WikiTreeNodeMeta, inClipSection: Bool) {
        actionInput.accept(.showHUD(.customLoading(BundleI18n.SKResource.Doc_Wiki_RemoveDialog)))
        confirmDeleteSingleNode(meta: meta)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] reviewerInfo in
                guard let self else { return }
                self.actionInput.accept(.hideHUD)
                self.applyDelete(meta: meta, isSingleDelete: true, reviewerInfo: reviewerInfo)
            } onError: { [weak self] error in
                DocsLogger.error("delete single node to space failed", error: error)
                guard let self = self else { return }
                self.actionInput.accept(.hideHUD)
                if let rxError = error as? RxError, case .timeout = rxError {
                    self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.LarkCCM_Workspace_DeletePage_OT_Toast)))
                } else if let error = WikiErrorCode(rawValue: (error as NSError).code) {
                    // 特定case 弹窗处理
                    self.showDeleteFailedDialog(error: error)
                } else {
                    self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.LarkCCM_Workspace_DeletePage_Failed_Title)))
                }
                WikiStatistic.clickDeleteConfirm(isFavorites: inClipSection,
                                                 isSuccess: false,
                                                 includeChildren: false,
                                                 deleteScope: .single,
                                                 meta: meta)
            } onCompleted: { [weak self] in
                self?.actionInput.accept(.showHUD(.success(BundleI18n.SKResource.LarkCCM_Workspace_DeletePage_Deleted_Toast)))
                WikiStatistic.clickDeleteConfirm(isFavorites: inClipSection,
                                                 isSuccess: true,
                                                 includeChildren: false,
                                                 deleteScope: .single,
                                                 meta: meta)
            }
            .disposed(by: disposeBag)
    }
    // 确认并执行 moveToSpace 操作，并在成功后更新目录树，但需要业务方自行处理 UI 逻辑（toast 等）
    private func confirmDeleteSingleNode(meta: WikiTreeNodeMeta) -> Maybe<WikiAuthorizedUserInfo> {
        // 发起 + 轮询
        let requestUUID = requestUUID
        return .create { observer in
            WikiMoreAPI.deleteSingleNode(wikiToken: meta.wikiToken,
                                         spaceID: meta.spaceID,
                                         synergyUUID: requestUUID)
            .subscribe { reviewerInfo in
                observer(.success(reviewerInfo))
            } onError: { error in
                observer(.error(error))
            } onCompleted: { [weak self] in
                // 操作生效后，抛出事件让目录树更新
                self?.moreActionInput.accept(.delete(meta: meta, isSingleDelete: true))
                observer(.completed)
            }
        }
    }

    private func verifyDelete(meta: WikiTreeNodeMeta, inClipSection: Bool) {
        let title = meta.isShortcut ?
            BundleI18n.SKResource.CreationMobile_Wiki_Shortcuts_DeleteShortcuts_Tooltip :
            BundleI18n.SKResource.CreationMobile_Wiki_RemoveThePage_Title
        let originContent = BundleI18n.SKResource.LarkCCM_Workspace_Trash_DeleteIn30D_Popover_Text
        let shorcutContent = BundleI18n.SKResource.LarkCCM_Workspace_Trash_DeleteShortcut_Descrip
        let content = meta.isShortcut ? shorcutContent : originContent
        let caption: String? = {
            if meta.isShortcut { return nil }
            return BundleI18n.SKResource.CreationMobile_Common_DeleteOthersPage
        }()
        let dialog = UDDialog()
        dialog.setTitle(text: title)
        if let caption = caption {
            dialog.setContent(text: content, caption: caption)
        } else {
            dialog.setContent(text: content)
        }
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion: {
            WikiStatistic.clickDeleteCancel(isFavorites: inClipSection, meta: meta)
        })
        dialog.addDestructiveButton(text: BundleI18n.SKResource.LarkCCM_Workspace_DeletePage_Delete_Button, dismissCompletion: { [weak self] in
            // 确认删除
            self?.confirmDelete(meta: meta, inClipSection: inClipSection)
        })
        actionInput.accept(.present(provider: { _ in
            dialog
        }))
    }

    private func confirmDelete(meta: WikiTreeNodeMeta, inClipSection: Bool) {
        actionInput.accept(.showHUD(.customLoading(BundleI18n.SKResource.Doc_Wiki_RemoveDialog)))
        networkAPI.deleteNode(meta.wikiToken,
                              spaceId: meta.spaceID,
                              canApply: UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled,
                              synergyUUID: requestUUID)
        .observeOn(MainScheduler.instance)
        .subscribe { [weak self] reviewerInfo in
            guard let self = self else { return }
            self.actionInput.accept(.hideHUD)
            self.applyDelete(meta: meta, isSingleDelete: false, reviewerInfo: reviewerInfo)
        } onError: { [weak self] error in
            guard let self = self else { return }
            self.actionInput.accept(.hideHUD)
            let error = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
            self.showDeleteFailedDialog(error: error)
            WikiStatistic.confirmTreeNodeDelete(wikiToken: meta.wikiToken,
                                                fileType: meta.objType.name,
                                                status: .fail)
            WikiStatistic.clickDeleteConfirm(isFavorites: inClipSection,
                                             isSuccess: false,
                                             includeChildren: meta.hasChild,
                                             deleteScope: .all,
                                             meta: meta)
        } onCompleted: { [weak self] in
            guard let self = self else { return }
            self.moreActionInput.accept(.delete(meta: meta, isSingleDelete: false))
            self.actionInput.accept(.showHUD(.success(BundleI18n.SKResource.LarkCCM_Workspace_DeletePage_Deleted_Toast)))
            WikiStatistic.clickDeleteConfirm(isFavorites: inClipSection,
                                             isSuccess: true,
                                             includeChildren: meta.hasChild,
                                             deleteScope: .all,
                                             meta: meta)
            WikiStatistic.confirmTreeNodeDelete(wikiToken: meta.wikiToken,
                                                fileType: meta.objType.name,
                                                status: .success)
        }
        .disposed(by: disposeBag)
    }

    // 申请删除流程，提示用户并填写申请理由
    private func applyDelete(meta: WikiTreeNodeMeta, isSingleDelete: Bool, reviewerInfo: WikiAuthorizedUserInfo) {
        var config = SKApplyPanelConfig(userInfo: reviewerInfo,
                                        title: BundleI18n.SKResource.LarkCCM_CM_RequestToDeleteDoc_Title,
                                        placeHolder: BundleI18n.SKResource.LarkCCM_Wiki_Move_ReqPermission_Context,
                                        actionName: BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AskOwner_Btn,
                                        contentProvider: { BundleI18n.SKResource.LarkCCM_CM_NoPermToDeletePageWithWikiSettings_Description($0) })
        config.actionHandler = { [weak self] controller, reason in
            self?.confirmApplyDelete(meta: meta,
                                     isSingleDelete: isSingleDelete,
                                     reviewerInfo: reviewerInfo,
                                     reason: reason,
                                     controller: controller)
        }
        if UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled {
            do {
                let url = try HelpCenterURLGenerator.generateURL(article: .cmApplyDelete,
                                                                 query: ["from": "ccm_permission_delete"])
                config.accessoryHandler = { controller in
                    Navigator.shared.present(url,
                                             context: ["showTemporary": false],
                                             wrap: LkNavigationController.self,
                                             from: controller)
                }
            } catch {
                DocsLogger.error("failed to generate helper center URL when apply delete in wiki from wiki tree", error: error)
            }
        }
        let controller = SKApplyPanelController.createController(config: config)
        actionInput.accept(.present(provider: { _ in controller }))
    }

    // 确认申请删除，发起请求
    private func confirmApplyDelete(meta: WikiTreeNodeMeta,
                                    isSingleDelete: Bool,
                                    reviewerInfo: WikiAuthorizedUserInfo,
                                    reason: String?,
                                    controller: UIViewController) {
        UDToast.showLoading(with: BundleI18n.SKResource.CreationMobile_Comment_Add_Sending_Toast, on: controller.view.window ?? controller.view)
        networkAPI.applyDelete(wikiMeta: meta.wikiMeta, isSingleDelete: isSingleDelete, reason: reason, reviewerID: reviewerInfo.userID)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak controller, weak self] in
                guard let controller, let self else { return }
                UDToast.removeToast(on: controller.view.window ?? controller.view)
                controller.dismiss(animated: true)
                self.actionInput.accept(.showHUD(.success(BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AskOwner_SentToast)))
            } onError: { [weak controller] error in
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
                        errorMessage = error.deleteErrorDescription
                    }
                }
                UDToast.showFailure(with: errorMessage, on: controller.view.window ?? controller.view)
            }
            .disposed(by: disposeBag)
    }
    
    private func showDeleteFailedDialog(error: WikiErrorCode) {
        let dialog = UDDialog()
        let title = BundleI18n.SKResource.LarkCCM_Workspace_DeletePage_Failed_Title
        let confirmTitle = BundleI18n.SKResource.LarkCCM_Workspace_DeletePage_GotIt_Button
        dialog.setTitle(text: title)
        dialog.addPrimaryButton(text: confirmTitle, dismissCompletion: nil)
        switch error {
        case .operateSubNodeNoPerm:
            //无上移子节点权限
            let description = BundleI18n.SKResource.LarkCCM_Workspace_DeletePageFail_NoPerm
            dialog.setContent(text: description)
            actionInput.accept(.present(provider: { _ in
                dialog
            }))
        case .nodesCountLimitExceed:
            //上移子节点超过了当前目录树节点上限
            let description = BundleI18n.SKResource.LarkCCM_Workspace_DeletePageFail_OverLimit
            dialog.setContent(text: description)
            actionInput.accept(.present(provider: { _ in
                dialog
            }))
        case .cacDeleteBlcked:
            DocsLogger.info("cac delete blocked, no need show tips or dialog")
        default:
            actionInput.accept(.showHUD(.failure(error.deleteErrorDescription)))
        }
    }
}
