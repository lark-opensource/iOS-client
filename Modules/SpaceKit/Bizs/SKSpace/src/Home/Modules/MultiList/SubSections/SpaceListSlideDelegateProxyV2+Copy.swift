//
//  SpaceListSlideDelegateProxyV2+Copy.swift
//  SKSpace
//
//  Created by Weston Wu on 2022/10/25.
//

import Foundation
import SKFoundation
import SKResource
import SKCommon
import RxSwift
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignColor
import SpaceInterface

extension SpaceListSlideDelegateProxyV2 {
    func copyFile(for entry: SpaceEntry, fileSize: Int64? = nil, originName: String? = nil) {
        copyFileWithPicker(entry: entry, fileSize: fileSize, originName: originName)
    }

    private func copyToCurrentFolderEnable(entry: SpaceEntry) -> Bool {
        // Space 1.0 文档禁用
        guard entry.isSingleContainerNode else { return false }
        // 仅我的空间或文件夹列表
        guard let module = helper?.slideTracker.bizParameter.module else { return false }
        // 在space列表的wiki文档禁用
        if entry.type == .wiki { return false }
        switch module {
        case .personalSubFolder, .sharedSubFolder, .newDrive:
            break
        case let .personal(subModule):
            guard subModule == .none else {
                return false
            }
        default:
            return false
        }

        return true
    }

    private func copyFileWithPicker(entry: SpaceEntry, fileSize: Int64? = nil, originName: String? = nil) {
        let tracker = WorkspacePickerTracker(actionType: .makeCopyTo,
                                             triggerLocation: .catalogListItem)
        let entrances: [WorkspacePickerEntrance]
        if entry.isSingleContainerNode {
            entrances = .wikiAndSpace
        } else {
            entrances = .spaceOnly
        }
        let entranceConfig = PickerEntranceConfig(icon: UDIcon.copyFilled.ud.withTintColor(UDColor.primaryContentDefault),
                                                  title: BundleI18n.SKResource.LarkCCM_NewCM_MakeCopies_Option) { [weak self] picker in
            self?.confirmCopyToCurrentFolder(entry: entry, fileSize: fileSize, originName: originName, picker: picker)
        }
        let config = WorkspacePickerConfig(title: BundleI18n.SKResource.LarkCCM_Wiki_MoveACopyTo_Header_Mob,
                                           action: .copySpace,
                                           extraEntranceConfig: copyToCurrentFolderEnable(entry: entry) ? entranceConfig : nil,
                                           entrances: entrances,
                                           ownerTypeChecker: { isSingleFolder in
            // 检查 space 版本是否匹配
            guard entry.isSingleContainerNode != isSingleFolder else { return nil }
            if isSingleFolder {
                // 1.0 文件 + 2.0 文件夹
                return BundleI18n.SKResource.CreationMobile_ECM_UnableAddFolderToast
            } else {
                // 2.0 文件 + 1.0 文件夹
                return BundleI18n.SKResource.CreationMobile_ECM_UnableDuplicateDocToast
            }
        },
                                           disabledWikiToken: nil,
                                           usingLegacyRecentAPI: !entry.isSingleContainerNode,
                                           tracker: tracker) { [weak self] location, picker in
            guard let self else { return }
            switch location {
            case let .wikiNode(location):
                self.confirmCopyToWiki(entry: entry, location: location, fileSize: fileSize, originName: originName, picker: picker)
            case let .folder(location):
                guard location.canCreateSubNode else {
                    UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_Workspace_FolderPerm_CantCopy_Tooltip,
                                        on: picker.view.window ?? picker.view)
                    return
                }
                self.confirmCopyToSpace(entry: entry, folderToken: location.folderToken, fileSize: fileSize, originName: originName, picker: picker)
            }
        }
        let picker = WorkspacePickerFactory.createWorkspacePicker(config: config)
        helper?.slideActionInput.accept(.present(viewController: picker))
    }

    private func confirmCopyToCurrentFolder(entry: SpaceEntry, fileSize: Int64?, originName: String?, picker: UIViewController) {
        if let parentToken = entry.parent {
            confirmCopyToSpace(entry: entry, folderToken: parentToken, fileSize: fileSize, originName: originName, picker: picker)
            return
        }
        guard let helper else {
            return
        }
        var spaceItem = entry.spaceItem
        if entry.isShortCut {
            spaceItem = SpaceMeta(objToken: entry.nodeToken, objType: .spaceShortcut)
        }
        
        helper.interactionHelper.getParentFolderToken(item: spaceItem)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] parentToken in
                entry.updateParent(parentToken)
                self?.confirmCopyToSpace(entry: entry, folderToken: parentToken, fileSize: fileSize, originName: originName, picker: picker)
            } onError: { error in
                let errorMessage: String
                if let docsError = error as? DocsNetworkError,
                   docsError.code == .forbidden {
                    errorMessage = BundleI18n.SKResource.LarkCCM_Wiki_NoPerms_CopyTo_Tooltip
                } else {
                    errorMessage = BundleI18n.SKResource.Doc_Facade_CreateFailed
                }
                UDToast.showFailure(with: errorMessage, on: picker.view.window ?? picker.view)
            }
            .disposed(by: disposeBag)
    }

    private func confirmCopyToSpace(entry: SpaceEntry, folderToken: String, fileSize: Int64?, originName: String?, picker: UIViewController) {
        UDToast.showLoading(with: BundleI18n.SKResource.CreationMobile_Wiki_CreateCopy_Creating_Toast, on: picker.view.window ?? picker.view)
        // 如果 entry 是 shortcut，需要尝试获取本体的名字
        let name: String
        if let originName = originName {
            name = SpaceEntry.displayName(title: originName, type: entry.type)
        } else {
            name = entry.name
        }
        var objType = entry.type
        if let wikiEntry = entry as? WikiEntry, let wikiInfo = wikiEntry.wikiInfo {
            objType = wikiInfo.docsType
        }
        
        copyToSpace(entry: entry, name: name, folderToken: folderToken, fileSize: fileSize, picker: picker)
        .observeOn(MainScheduler.instance)
        .subscribe { [weak self] fileURL in
            guard let self = self else { return }
            FileListStatistics.reportClientContentManagement(statusName: "", action: "make_a_copy")
            var tips = BundleI18n.SKResource.Doc_Facade_MakeCopySucceed
            if objType == .sheet {
                tips = BundleI18n.SKResource.CreationMobile_Sheets_MakeCopying_Toast
            }
            if entry.type == .wiki {
                // wiki文档直接打开副本
                UDToast.removeToast(on: picker.view.window ?? picker.view)
                self.helper?.slideActionInput.accept(.openURL(url: fileURL, context: nil))
                self.helper?.slideActionInput.accept(.showHUD(.success(tips)))
                picker.dismiss(animated: true)
                return
            }
            
            let operaiton = UDToastOperationConfig(text: BundleI18n.SKResource.CreationMobile_Doc_Facade_MakeCopySucceed_open_btn)
            let config = UDToastConfig(toastType: .success, text: tips, operation: operaiton, delay: 4)
            let callback: (String?) -> Void = { [weak self] _ in
                guard let self = self else { return }
                self.helper?.slideActionInput.accept(.openURL(url: fileURL, context: nil))
                self.reportClientCopyAction(fileURL.absoluteString, fileType: objType, error: "")
            }
            UDToast.showToast(with: config, on: picker.view.window ?? picker.view, operationCallBack: callback)
            picker.dismiss(animated: true)
        } onError: { error in
            UDToast.removeToast(on: picker.view.window ?? picker.view)
            DocsLogger.error("Create By Copy error: \(error)")
            // copyToSpace 内部也会弹 toast，这里只针对几种特殊场景单独覆盖 toast
            if let docsError = error as? DocsNetworkError {
                FileListStatistics.reportClientContentManagement(statusName: docsError.errorMsg, action: "make_a_copy")
                if DocsNetworkError.error(docsError, equalTo: .auditError) {
                    UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_Workspace_FolderPerm_CantCopy_Tooltip, on: picker.view)
                } else if DocsNetworkError.error(docsError, equalTo: .forbidden) {
                    UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_Workspace_FolderPerm_CantCopy_Tooltip, on: picker.view)
                }
            }
        }
        .disposed(by: disposeBag)
    }

    private func confirmCopyToWiki(entry: SpaceEntry, location: WikiPickerLocation, fileSize: Int64?, originName: String?, picker: UIViewController) {
        UDToast.showLoading(with: BundleI18n.SKResource.CreationMobile_Wiki_CreateCopy_Creating_Toast, on: picker.view.window ?? picker.view)
        var needAsync = entry.type == .sheet
        if let wikiEntry = entry as? WikiEntry, let wikiInfo = wikiEntry.wikiInfo {
            needAsync = wikiInfo.docsType == .sheet
        }
        // 如果 entry 是 shortcut，需要尝试获取本体的名字
        let name: String
        if let originName {
            name = SpaceEntry.displayName(title: originName, type: entry.type)
        } else {
            name = entry.name
        }
        
        copyToWiki(entry: entry, location: location, name: name)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] wikiToken in
                UDToast.removeToast(on: picker.view.window ?? picker.view)
                guard let self = self else { return }
                let tips = needAsync
                ? BundleI18n.SKResource.CreationMobile_Sheets_MakeCopying_Toast
                : BundleI18n.SKResource.Doc_Facade_MakeCopySucceed
                let url = DocsUrlUtil.url(type: .wiki, token: wikiToken)
                if entry.type == .wiki {
                    // wiki文档创建副本后直接打开副本
                    self.helper?.slideActionInput.accept(.openURL(url: url, context: nil))
                    self.helper?.slideActionInput.accept(.showHUD(.success(tips)))
                    picker.dismiss(animated: true)
                    return
                }
                
                UDToast.showTips(with: tips,
                                 operationText: BundleI18n.SKResource.CreationMobile_Doc_Facade_MakeCopySucceed_open_btn,
                                 on: picker.view.window ?? picker.view,
                                 delay: 4,
                                 operationCallBack: { [weak self] _ in
                    guard let self = self else { return }
                    self.helper?.slideActionInput.accept(.openURL(url: url, context: nil))
                })
                picker.dismiss(animated: true)
            } onError: { error in
                DocsLogger.error("space copy to wiki failed", error: error)
                UDToast.removeToast(on: picker.view.window ?? picker.view)
                let message: String
                if let networkError = error as? DocsNetworkError {
                    if let wikiErrorCode = WikiErrorCode(rawValue: networkError.code.rawValue) {
                        message = wikiErrorCode.makeCopyErrorDescription
                    } else if let errorMessage = networkError.code.errorMessage {
                        message = errorMessage
                    } else {
                        message = BundleI18n.SKResource.Doc_Facade_CreateFailed
                    }
                } else if case let WikiError.serverError(code) = error,
                          let wikiErrorCode = WikiErrorCode(rawValue: code) {
                    message = wikiErrorCode.makeCopyErrorDescription
                } else if let wikiErrorCode = WikiErrorCode(rawValue: (error as NSError).code) {
                    message = wikiErrorCode.makeCopyErrorDescription
                } else {
                    message = BundleI18n.SKResource.Doc_Facade_CreateFailed
                }
                UDToast.showFailure(with: message, on: picker.view.window ?? picker.view)
            }
            .disposed(by: disposeBag)
    }

    private func reportClientCopyAction(_ url: String, fileType: DocsType, error: String) {
        let array = url.split(separator: "/")
        let token = String(array.last ?? "")
        let params = ["status_name": error,
                      "file_type": fileType.name,
                      "file_id": DocsTracker.encrypt(id: token)] as [String: Any]
        DocsTracker.log(enumEvent: .clickMakeCopy, parameters: params)
    }
    
    
    //MARK: 6.4版本兼容Wiki创建副本
    private func copyToSpace(entry: SpaceEntry, name: String, folderToken: String, fileSize: Int64?, picker: UIViewController) -> Single<URL> {
        guard let helper else {
            return .error(DocsNetworkError.invalidData)
        }
        
        if entry.type == .wiki, let wikiEntry = entry as? WikiEntry, let wikiInfo = wikiEntry.wikiInfo {
            let needAsync = wikiInfo.docsType == .sheet
            let newTitle = DocsRequestCenter.getCopyTitle(objType: wikiInfo.docsType, name: name)
            return helper.interactionHelper.copyToSpace(sourceWikiToken: entry.objToken,
                                                        spaceId: wikiInfo.spaceId,
                                                        folderToken: folderToken,
                                                        title: newTitle,
                                                        needAsync: needAsync)
        } else {
            let trackParams = DocsCreateDirectorV2.TrackParameters(source: .larkCreate,
                                                                   module: helper.slideTracker.module,
                                                                   ccmOpenSource: .copy)
            let request = WorkspaceManagementAPI.Space.CopyToSpaceRequest(
                sourceMeta: SpaceMeta(objToken: entry.objToken, objType: entry.type),
                ownerType: entry.ownerType,
                folderToken: folderToken,
                originName: name,
                fileSize: fileSize,
                trackParams: trackParams
            )
            return helper.interactionHelper.copyToSpace(request: request, picker: picker)
        }
    }
    
    private func copyToWiki(entry: SpaceEntry, location: WikiPickerLocation, name: String) -> Single<String> {
        guard let helper else {
            return .error(DocsNetworkError.invalidData)
        }
        
        if entry.type == .wiki, let wikiEntry = entry as? WikiEntry, let wikiInfo = wikiEntry.wikiInfo {
            let sourceMeta = WikiMeta(wikiToken: entry.objToken, spaceID: wikiInfo.spaceId)
            let targetMeta = WikiMeta(location: location)
            let newTitle = DocsRequestCenter.getCopyTitle(objType: wikiInfo.docsType, name: name)
            let needAsync = wikiInfo.docsType == .sheet
            return helper.interactionHelper.copyToWiki(sourceMeta: sourceMeta, targetMeta: targetMeta, title: newTitle, needAsync: needAsync)
        } else {
            let newTitle = DocsRequestCenter.getCopyTitle(objType: entry.docsType, name: name)
            let needAsync = entry.docsType == .sheet
            return helper.interactionHelper.copyToWiki(objToken: entry.objToken,
                                                       objType: entry.type,
                                                       location: location,
                                                       title: newTitle,
                                                       needAsync: needAsync)
        }
    }
}
