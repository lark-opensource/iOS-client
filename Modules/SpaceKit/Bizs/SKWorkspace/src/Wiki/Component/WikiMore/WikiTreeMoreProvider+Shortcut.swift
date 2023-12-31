//
//  WikiTreeMoreProvider+Shortcut.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/8/8.
//

import RxSwift
import SKCommon
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignToast
import UniverseDesignDialog
import UIKit
import SpaceInterface
import SKInfra
import SKWorkspace

// 创建shortcut操作
extension WikiMainTreeMoreProvider {

    private typealias Context = WikiInteractionHandler.Context

    func didClickShortcut(meta: WikiTreeNodeMeta, originName: String?, inClipSection: Bool) {
        WikiStatistic.shortcutTo(wikiToken: meta.wikiToken,
                                 docsType: meta.objType.name,
                                 refType: meta.isShortcut ? .shortcut : .original)
        WikiStatistic.clickWikiTreeMore(click: .shortcutTo,
                                        isFavorites: inClipSection,
                                        target: DocsTracker.EventType.wikiFileLocationSelectView.rawValue,
                                        meta: meta)
        let context = Context(meta: meta, originName: originName)
        let entrances: [WorkspacePickerEntrance] = SettingConfig.singleContainerEnable ? .wikiAndSpace : .wikiOnly
        // space 2.0 下，允许 shortcut 到 space
        let picker = interactionHelper.makeShortcutPicker(context: context,
                                                          triggerLocation: .wikiTree,
                                                          entrances: entrances) { [weak self] picker, location in
            self?.shortcutDuplicateCheck(location: location,
                                         objToken: meta.objToken,
                                         objType: meta.objType,
                                         callBack: { showHUD in
                self?.confirmShortcutTo(meta: meta, context: context, location: location, picker: picker, showHUD: showHUD)
            })
        }
        actionInput.accept(.present(provider: { _ in
            picker
        }))
    }

    private func confirmShortcutTo(meta: WikiTreeNodeMeta,
                                   context: Context,
                                   location: WorkspacePickerLocation,
                                   picker: UIViewController,
                                   showHUD: Bool = true) {
        if showHUD {
            // 防止检查重复快捷方式loading与创建loading冲突
            actionInput.accept(.showHUD(.customLoading(BundleI18n.SKResource.CreationMobile_Wiki_CreateCopy_Creating_Toast)))
        }
        interactionHelper.confirmShortcutTo(location: location, context: context)
            .subscribe { [weak self] response in
                guard let self = self else { return }
                switch response.node {
                case let .wiki(newNode, _):
                     // wiki 需要特殊处理下协同逻辑
                    self.moreActionInput.accept(.shortcut(newNode: newNode))
                default:
                    break
                }
                self.actionInput.accept(.hideHUD)
                self.showShortcutSuccess(with: response.url)
                self.actionInput.accept(.dismiss(controller: picker))
                WikiStatistic.clickFileLocationSelect(targetSpaceId: location.targetSpaceID,
                                                      fileId: response.statistic.objToken,
                                                      fileType: response.statistic.objType.name,
                                                      filePageToken: response.statistic.pageToken,
                                                      viewTitle: .shortcutTo,
                                                      originSpaceId: meta.spaceID,
                                                      originWikiToken: meta.wikiToken,
                                                      isShortcut: meta.isShortcut,
                                                      triggerLocation: .wikiTree,
                                                      targetModule: location.targetModule,
                                                      targetFolderType: location.targetFolderType)
            } onError: { [weak self] error in
                guard let self = self else { return }
                DocsLogger.error("shortcut error\(error)")
                self.actionInput.accept(.hideHUD)
                self.actionInput.accept(.showHUD(.failure(self.parseShortcutMessage(from: error, location: location))))
                WikiStatistic.wikiDocsMoveResultToastView(success: false, viewTitle: .shortcutTo)
            }
            .disposed(by: disposeBag)
    }

    private func showShortcutSuccess(with url: URL) {
        let operation = UDToastOperationConfig(text: BundleI18n.SKResource.CreationMobile_Wiki_ClickToView_Toast,
                                               displayType: .horizontal)
        let config = UDToastConfig(toastType: .success,
                                   text: BundleI18n.SKResource.CreationMobile_Wiki_Shortcuts_CreateSuccessfully_Toast,
                                   operation: operation,
                                   delay: 5)
        actionInput.accept(.showHUD(.custom(config: config,
                                            operationCallback: { [weak self] _ in
            guard let self = self else { return }
            self.actionInput.accept(.pushURL(url))
            WikiStatistic.wikiDocsMoveResultToast(click: .docsView,
                                                  viewTitle: .shortcutTo,
                                                  target: DocsTracker.EventType.docsPageView.rawValue)
        })))
        WikiStatistic.wikiDocsMoveResultToastView(success: true, viewTitle: .shortcutTo)
    }

    private func parseShortcutMessage(from error: Error, location: WorkspacePickerLocation) -> String {
        if let networkError = error as? DocsNetworkError {
            if networkError.code == .forbidden {
                // 特化文案
                switch location {
                case .folder:
                    return BundleI18n.SKResource.LarkCCM_Workspace_FolderPerm_CantShortcut_Tooltip
                case .wikiNode:
                    return BundleI18n.SKResource.LarkCCM_Docs_ActionFailed_NoTargetPermission_Mob
                }
            } else if let message = networkError.code.errorMessage {
                return message
            } else if let wikiErrorCode = WikiErrorCode(rawValue: networkError.code.rawValue) {
                return wikiErrorCode.createShortcutErrorDescription
            } else {
                return BundleI18n.SKResource.CreationMobile_Wiki_Shortcuts_UnableToCreate_Toast
            }
        } else if case let WikiError.serverError(code) = error,
                  let wikiErrorCode = WikiErrorCode(rawValue: code) {
            return wikiErrorCode.createShortcutErrorDescription
        } else if let wikiErrorCode = WikiErrorCode(rawValue: (error as NSError).code) {
            return wikiErrorCode.createShortcutErrorDescription
        } else {
            return BundleI18n.SKResource.CreationMobile_Wiki_Shortcuts_UnableToCreate_Toast
        }
    }
    
    private func shortcutDuplicateCheck(location: WorkspacePickerLocation,
                                        objToken: String,
                                        objType: DocsType,
                                        callBack: @escaping ((_ showHUD: Bool) -> Void)) {
        actionInput.accept(.showHUD(.customLoading(BundleI18n.SKResource.CreationMobile_Wiki_CreateCopy_Creating_Toast)))
        WorkspaceCrossNetworkAPI.addShortcutDuplicateCheck(objToken: objToken,
                                                           objType: objType,
                                                           location: location)
        .subscribe(onSuccess: { [weak self] stages in
            switch stages {
            case .hasEntity, .hasShortcut:
                self?.actionInput.accept(.hideHUD)
                self?.confirmAddShortcutInDuplicateStages(stages: stages, compeltion: {
                    callBack(true)
                    DocsTracker.shortcutDuplicateCheckClick(stages: stages, click: "add", fileId: objToken, fileTypeName: objType.name)
                })
            case .normal:
                callBack(false)
            }
        }, onError: {[weak self] error in
            DocsLogger.error("wiki.tree.more: shortcut duplicate check error: \(error)")
            callBack(false)
        })
        .disposed(by: disposeBag)
    }
    
    private func confirmAddShortcutInDuplicateStages(stages: CreateShortcutStages, compeltion: @escaping (() -> Void)) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Workspace_AddShortcut_Repitition_Title)
        dialog.setContent(text: stages.contentString)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.LarkCCM_Workspace_AddShortcut_Repitition_Cancel_Button, dismissCompletion:  {
            DocsTracker.shortcutDuplicateCheckClick(stages: stages, click: "cancel")
        })
        dialog.addPrimaryButton(text: BundleI18n.SKResource.LarkCCM_Workspace_AddShortcut_Repitition_Add_Button, dismissCompletion:  {
            compeltion()
        })
        DocsTracker.shortcutDuplicateCheckView(stages: stages)
        actionInput.accept(.present(provider: { _ in
            dialog
        }))
    }
}
