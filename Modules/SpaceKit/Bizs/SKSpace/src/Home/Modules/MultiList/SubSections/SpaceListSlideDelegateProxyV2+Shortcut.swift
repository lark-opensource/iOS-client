//
//  SpaceListSlideDelegateProxyV2+Shortcut.swift
//  SKSpace
//
//  Created by Weston Wu on 2022/10/27.
//

import Foundation
import SKFoundation
import SKResource
import SKCommon
import RxSwift
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignDialog
import SpaceInterface
import SKInfra

extension SpaceListSlideDelegateProxyV2 {

    func addShortCut(for entry: SpaceEntry, originName: String?) {
        if entry.isOffline {
            self.showFailure(with: BundleI18n.SKResource.Doc_List_FailedToDragOfflineDoc)
            return
        }
        shortcutFileWithPicker(entry: entry, originName: originName)
    }

    private func shortcutFileWithPicker(entry: SpaceEntry, originName: String?) {
        let tracker = WorkspacePickerTracker(actionType: .shortcutTo,
                                             triggerLocation: .catalogListItem)
        let config = WorkspacePickerConfig(title: BundleI18n.SKResource.LarkCCM_Wiki_AddShortcutTo_Header_Mob,
                                           action: .createSpaceShortcut,
                                           entrances: .wikiAndSpace,
                                           ownerTypeChecker: { isV2Folder in
            if isV2Folder {
                return nil
            } else {
                return BundleI18n.SKResource.CreationMobile_ECM_UnableShortToast
            }
        },
                                           tracker: tracker) { [weak self] location, picker in
            guard let self else { return }
            switch location {
            case let .wikiNode(location):
                self.shortcutDuplicateCheck(location: .wikiNode(location: location),
                                            objToken: entry.objToken,
                                            objType: entry.docsType,
                                            picker: picker) { showLoading in
                    self.confirmShortcutToWiki(entry: entry,
                                               originName: originName,
                                               location: location,
                                               picker: picker,
                                               showLoading: showLoading)
                }
            case let .folder(location):
                self.shortcutDuplicateCheck(location: .folder(location: location),
                                            objToken: entry.objToken,
                                            objType: entry.docsType,
                                            picker: picker) { showLoading in
                    self.confirmShortcutToSpace(entry: entry, location: location, picker: picker, showLoading: showLoading)
                }
            }
        }
        let picker = WorkspacePickerFactory.createWorkspacePicker(config: config)
        helper?.slideActionInput.accept(.present(viewController: picker))
    }

    private func confirmShortcutToSpace(entry: SpaceEntry,
                                        location: SpaceFolderPickerLocation,
                                        picker: UIViewController,
                                        showLoading: Bool) {
        guard location.canCreateSubNode else {
            showFailure(with: BundleI18n.SKResource.LarkCCM_Workspace_FolderPerm_CantShortcut_Tooltip)
            return
        }
        guard let helper else { return }
        if showLoading {
            helper.slideActionInput.accept(.showHUD(.loading))
        }
        shortcutToSpace(entry: entry, folderToken: location.folderToken)
            .subscribe { [weak self] _ in
                guard let self = self else { return }
                let url: URL
                if location.folderToken.isEmpty {
                    url = UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? DocsUrlUtil.cloudDriveMyFolderURL : DocsUrlUtil.mySpaceURL
                } else {
                    url = DocsUrlUtil.url(type: .folder, token: location.folderToken)
                }
                self.showShortcutSuccess(with: url)
                picker.dismiss(animated: true)
            } onError: { [weak self] error in
                guard let self = self else { return }
                let message: String
                if let docsError = error as? DocsNetworkError,
                   let errorMessage = docsError.code.errorMessage {
                    message = errorMessage
                } else {
                    message = BundleI18n.SKResource.Doc_List_FolderSelectAdd + BundleI18n.SKResource.Doc_AppUpdate_FailRetry
                }
                self.showFailure(with: message)
            }
            .disposed(by: disposeBag)
    }

    private func confirmShortcutToWiki(entry: SpaceEntry,
                                       originName: String?,
                                       location: WikiPickerLocation,
                                       picker: UIViewController,
                                       showLoading: Bool) {
        guard let helper else { return }
        if showLoading {
            helper.slideActionInput.accept(.showHUD(.loading))
        }
        shortcutToWiki(entry: entry, location: location, title: originName ?? entry.name)
        .subscribe { [weak self] wikiToken in
            guard let self else { return }
            let url = DocsUrlUtil.url(type: .wiki, token: wikiToken)
            self.showShortcutSuccess(with: url)
            picker.dismiss(animated: true)
        } onError: { [weak self] error in
            guard let self else { return }
            let message: String
            let code = (error as NSError).code
            if let wikiError = WikiErrorCode(rawValue: code) {
                message = wikiError.createShortcutErrorDescription
            } else if let docsError = error as? DocsNetworkError,
                      let errorMessage = docsError.code.errorMessage {
                message = errorMessage
            } else {
                message = BundleI18n.SKResource.Doc_List_FolderSelectAdd + BundleI18n.SKResource.Doc_AppUpdate_FailRetry
            }
            self.showFailure(with: message)
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
        helper?.slideActionInput.accept(.showHUD(.custom(config: config, operationCallback: { [weak self] _ in
            guard let self = self else { return }
            self.helper?.slideActionInput.accept(.openURL(url: url, context: nil))
        })))
    }
    
    private func shortcutDuplicateCheck(location: WorkspacePickerLocation,
                                        objToken: String,
                                        objType: DocsType,
                                        picker: UIViewController,
                                        callBack: @escaping ((_ showLoading: Bool) -> Void)) {
        helper?.slideActionInput.accept(.showHUD(.loading))
        WorkspaceCrossNetworkAPI.addShortcutDuplicateCheck(objToken: objToken,
                                                           objType: objType,
                                                           location: location)
        .subscribe(onSuccess: { [weak self] stages in
            switch stages {
            case .hasEntity, .hasShortcut:
                self?.helper?.slideActionInput.accept(.hideHUD)
                self?.confirmAddShortcutInDuplicateStages(stages: stages, picker: picker, compeltion: {
                    callBack(true)
                    DocsTracker.shortcutDuplicateCheckClick(stages: stages, click: "add", fileId: objToken, fileTypeName: objType.name)
                })
            case .normal:
                callBack(false)
            }
        }, onError: { error in
            DocsLogger.error("space.file.more: shortcut duplicate check error: \(error)")
            callBack(false)
        })
        .disposed(by: disposeBag)
    }
    
    private func confirmAddShortcutInDuplicateStages(stages: CreateShortcutStages, picker: UIViewController, compeltion: @escaping (() -> Void)) {
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
        picker.present(dialog, animated: true)
    }
    
    // MARK: 6.4版本Wiki兼容添加快捷方式
    private func shortcutToSpace(entry: SpaceEntry, folderToken: String) -> Single<String> {
        guard let helper else {
            return .error(DocsNetworkError.invalidData)
        }
        
        if entry.type == .wiki, let wikiEntry = entry as? WikiEntry, let wikiInfo = wikiEntry.wikiInfo {
            let item = SpaceItem(objToken: wikiInfo.objToken, objType: wikiInfo.docsType)
            return helper.interactionHelper.shortcutToSpace(item: item, folderToken: folderToken)
        } else {
            let item = SpaceItem(objToken: entry.objToken, objType: entry.docsType)
            return helper.interactionHelper.createShortCut(for: item, in: folderToken)
        }
    }
    
    private func shortcutToWiki(entry: SpaceEntry, location: WikiPickerLocation, title: String) -> Single<String> {
        guard let helper else {
            return .error(DocsNetworkError.invalidData)
        }
        if entry.type == .wiki, let wikiEntry = entry as? WikiEntry, let wikiInfo = wikiEntry.wikiInfo {
            let sourceWikiMeta = WikiMeta(wikiToken: wikiInfo.wikiToken, spaceID: wikiInfo.spaceId)
            let targetWikiMeta = WikiMeta(location: location)
            return helper.interactionHelper.shortcutToWiki(sourceWikiMeta: sourceWikiMeta, targetWikiMeta: targetWikiMeta, title: title)
        } else {
            return helper.interactionHelper.shortcutToWiki(objToken: entry.objToken, objType: entry.docsType, title: title, location: location)
        }
    }
}
