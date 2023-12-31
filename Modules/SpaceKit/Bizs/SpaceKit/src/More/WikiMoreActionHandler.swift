//
//  WikiMoreActionHandler.swift
//  SpaceKit
//
//  Created by bupozhuang on 2021/8/5.
//

import Foundation
import SKCommon
import SKWikiV2
import RxSwift
import SKFoundation
import SwiftyJSON
import UniverseDesignToast
import SKResource
import LarkUIKit
import EENavigator
import UniverseDesignDialog
import UniverseDesignColor
import SKBrowser
import SKUIKit
import SpaceInterface
import SKInfra
import SKSpace
import SKWorkspace
import LarkContainer


class WikiMoreActionHandler {
    private typealias Context = WikiInteractionHandler.Context
    private typealias CopyLocation = WikiInteractionHandler.CopyPickerLocation

    weak var hostViewController: UIViewController?
    private var docsInfo: DocsInfo
    let bag = DisposeBag()
    private let interactionHandler: WikiInteractionHandler
    
    init(docsInfo: DocsInfo, hostViewController: UIViewController, synergyUUID: String?) {
        self.docsInfo = docsInfo
        self.hostViewController = hostViewController
        self.interactionHandler = WikiInteractionHandler(synergyUUID: synergyUUID)
    }

}

extension WikiMoreActionHandler {
    // wiki创建副本
    // fileSize只针对wiki2.0中Drive文件创建副本时逻辑判断使用，其他场景可不传
    func showWikiCopyFilePanel(fileSize: Int64? = nil) {
        guard let wikiInfo = docsInfo.wikiInfo,
              let currentTopMost = self.hostViewController else {
            return
        }
        let context = Self.convert(wikiInfo: wikiInfo, docsInfo: docsInfo)
        let picker = interactionHandler.makeCopyPicker(context: context,
                                                       triggerLocation: .topBar,
                                                       allowCopyToSpace: SettingConfig.singleContainerEnable) { [weak self] picker, location in
            let request = CopyRequest(context: context, location: location, fileSize: fileSize, wikiInfo: wikiInfo)
            self?.confirmCopy(request: request, hostController: currentTopMost, picker: picker)
        }
        LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) {
            Navigator.shared.present(picker, from: currentTopMost)
        }
        WikiStatistic.copy(wikiToken: wikiInfo.wikiToken,
                           fileType: wikiInfo.docsType.name)
    }

    private struct CopyRequest {
        let context: Context
        let location: CopyLocation
        let fileSize: Int64?
        let wikiInfo: WikiInfo
    }

    private func confirmCopy(request: CopyRequest,
                             hostController: UIViewController,
                             picker: UIViewController) {
        let context = request.context
        let location = request.location
        let fileSize = request.fileSize
        let wikiInfo = request.wikiInfo
        UDToast.showLoading(with: BundleI18n.SKResource.CreationMobile_Wiki_CreateCopy_Creating_Toast,
                               on: hostController.view.window ?? hostController.view,
                               disableUserInteraction: true)
        interactionHandler.confirmCopyTo(location: location, context: context, picker: picker)
            .observeOn(MainScheduler.instance)
            .subscribe { response in
                picker.dismiss(animated: true) {
                    UDToast.removeToast(on: hostController.view.window ?? hostController.view)
                    UDToast.showSuccess(with: BundleI18n.SKResource.CreationMobile_Wiki_CreateCopy_CreateSuccessfully_Toast,
                                           on: hostController.view.window ?? hostController.view)
                    let browser = EditorManager.shared.currentEditor
                    if browser?.vcFollowDelegate == nil {
                        Navigator.shared.docs.showDetailOrPush(response.url, from: hostController)
                    } else {
                        guard let browser = browser else { return }
                        _ = EditorManager.shared.requiresOpen(browser, url: response.url)
                    }
                    WikiStatistic.confirmCopy(wikiToken: context.wikiToken,
                                              fileType: context.objType.name,
                                              status: .success)
                    WikiStatistic.clickFileLocationSelect(targetSpaceId: response.location.targetSpaceID,
                                                          fileId: response.statistic.objToken,
                                                          fileType: response.statistic.objType.name,
                                                          filePageToken: response.statistic.pageToken,
                                                          viewTitle: .makeCopyTo,
                                                          originSpaceId: wikiInfo.spaceId,
                                                          originWikiToken: wikiInfo.wikiToken,
                                                          isShortcut: wikiInfo.wikiNodeState.isShortcut,
                                                          triggerLocation: .topBar,
                                                          targetModule: location.targetModule,
                                                          targetFolderType: location.targetFolderType)
                }
            } onError: { error in
                DocsLogger.error("wiki copy fail \(error)")
                UDToast.removeToast(on: hostController.view.window ?? hostController.view)
                if let networkError = error as? DocsNetworkError,
                   networkError.code == .spaceFileSizeLimited,
                   let size = fileSize {
                    QuotaAlertPresentor.shared.showUserUploadAlert(mountNodeToken: nil, mountPoint: nil, from: hostController, fileSize: size, quotaType: .bigFileToCopy)
                } else {
                    let toastMessage = Self.parseCopyMessage(from: error, location: location)
                    QuotaAlertPresentor.shared.showQuotaAlertIfNeed(type: .makeCopy,
                                                                    defaultToast: toastMessage,
                                                                    error: error,
                                                                    from: hostController,
                                                                    token: self.docsInfo.token)
                }
                WikiStatistic.confirmCopy(wikiToken: context.wikiToken,
                                          fileType: context.objType.name,
                                          status: .fail)
            }
            .disposed(by: bag)
    }

    private static func convert(wikiInfo: WikiInfo, docsInfo: DocsInfo) -> Context {
        let sourceLocation: Context.SourceLocation
        if wikiInfo.wikiNodeState.isShortcut {
            if wikiInfo.wikiNodeState.originIsExternal {
                sourceLocation = .external
            } else {
                let sourceWikiToken = wikiInfo.wikiNodeState.shortcutWikiToken ?? wikiInfo.wikiToken
                let sourceSpaceID = wikiInfo.wikiNodeState.shortcutSpaceID ?? wikiInfo.spaceId
                sourceLocation = .inWiki(wikiToken: sourceWikiToken, spaceID: sourceSpaceID)
            }
        } else {
            let sourceWikiToken = wikiInfo.wikiNodeState.shortcutWikiToken ?? wikiInfo.wikiToken
            let sourceSpaceID = wikiInfo.wikiNodeState.shortcutSpaceID ?? wikiInfo.spaceId
            sourceLocation = .inWiki(wikiToken: sourceWikiToken, spaceID: sourceSpaceID)
        }
        return Context(wikiToken: wikiInfo.wikiToken,
                       spaceID: wikiInfo.spaceId,
                       sourceLocation: sourceLocation,
                       objToken: wikiInfo.objToken,
                       objType: wikiInfo.docsType,
                       name: docsInfo.title,
                       isShortcut: wikiInfo.wikiNodeState.isShortcut,
                       isOwner: docsInfo.isOwner,
                       parentWikiToken: wikiInfo.wikiNodeState.parentWikiToken)
    }

    private static func parseCopyMessage(from error: Error, location: CopyLocation) -> String {
        if let networkError = error as? DocsNetworkError {
            if networkError.code == .forbidden {
                // 特化文案
                switch location {
                case .currentLocation:
                    return BundleI18n.SKResource.LarkCCM_Docs_ActionFailed_NoTargetPermission_Mob
                case let .pick(location):
                    switch location {
                    case .wikiNode:
                        return BundleI18n.SKResource.LarkCCM_Docs_ActionFailed_NoTargetPermission_Mob
                    case .folder:
                        return BundleI18n.SKResource.LarkCCM_Workspace_FolderPerm_CantCopy_Tooltip
                    }
                }
            } else if let message = networkError.code.errorMessage {
                return message
            } else if let wikiErrorCode = WikiErrorCode(rawValue: networkError.code.rawValue) {
                return wikiErrorCode.makeCopyErrorDescription
            } else {
                return BundleI18n.SKResource.CreationMobile_Wiki_CreateCopy_UnableToCreate_Toast
            }
        } else if case let WikiError.serverError(code) = error,
                  let wikiErrorCode = WikiErrorCode(rawValue: code) {
            return wikiErrorCode.makeCopyErrorDescription
        } else if let wikiErrorCode = WikiErrorCode(rawValue: (error as NSError).code) {
            return wikiErrorCode.makeCopyErrorDescription
        } else {
            return BundleI18n.SKResource.CreationMobile_Wiki_CreateCopy_UnableToCreate_Toast
        }
    }


    private func copyTitle(docsInfo: DocsInfo, wikiInfo: WikiInfo) -> String {
        let name: String
        if let title = self.docsInfo.title {
            name = title.isEmpty ? wikiInfo.docsType.untitledString : title
        } else {
            name = wikiInfo.docsType.untitledString
        }
        if docsInfo.type == .file, name.contains(".") == true {
            let arraySubstrings: [Substring]? = name.split(separator: ".")
            let lastName = arraySubstrings?.last ?? ""
            let suffix = "." + lastName
            let tmp = name
            let replaceC = " " + BundleI18n.SKResource.Doc_Facade_CopyDocSuffix + "." + lastName
            let newTitle = tmp.replacingOccurrences(of: suffix, with: replaceC)
            return newTitle
        } else {
            return name + " " + BundleI18n.SKResource.Doc_Facade_CopyDocSuffix
        }
    }
}

extension WikiMoreActionHandler {
    func wikiShortcut() {
        guard let wikiInfo = docsInfo.wikiInfo,
              let currentTopMost = self.hostViewController else {
            return
        }
        let context = Self.convert(wikiInfo: wikiInfo, docsInfo: docsInfo)
        let entrances: [WorkspacePickerEntrance]
        if wikiInfo.wikiNodeState.originIsExternal {
            entrances = .wikiAndSpace
        } else {
            entrances = SettingConfig.singleContainerEnable ? .wikiAndSpace : .wikiOnly
        }
        let picker = interactionHandler.makeShortcutPicker(context: context,
                                                           triggerLocation: .topBar,
                                                           entrances: entrances) { [weak self] picker, location in
            self?.shortcutDuplicateCheck(objToken: wikiInfo.objToken,
                                         objType: wikiInfo.docsType,
                                         location: location,
                                         picker: picker, callBack: { showLoading in
                self?.confirmShortcut(context: context,
                                      wikiInfo: wikiInfo,
                                      location: location,
                                      hostController: currentTopMost,
                                      picker: picker,
                                      showLoading: showLoading)
            })
        }
        Navigator.shared.present(picker, from: currentTopMost)
    }

    private func confirmShortcut(context: Context,
                                 wikiInfo: WikiInfo,
                                 location: WorkspacePickerLocation,
                                 hostController: UIViewController,
                                 picker: UIViewController,
                                 showLoading: Bool = true) {
        if showLoading {
            UDToast.showLoading(with: BundleI18n.SKResource.CreationMobile_Wiki_CreateCopy_Creating_Toast,
                                   on: hostController.view.window ?? hostController.view,
                                   disableUserInteraction: true)
        }
        interactionHandler.confirmShortcutTo(location: location, context: context)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] response in
                picker.dismiss(animated: true) {
                    UDToast.removeToast(on: hostController.view.window ?? hostController.view)
                    self?.showShortcutSuccess(with: response.url, hostController: hostController)
                    WikiStatistic.clickFileLocationSelect(targetSpaceId: location.targetSpaceID,
                                                          fileId: response.statistic.objToken,
                                                          fileType: response.statistic.objType.name,
                                                          filePageToken: response.statistic.pageToken,
                                                          viewTitle: .shortcutTo,
                                                          originSpaceId: wikiInfo.spaceId,
                                                          originWikiToken: wikiInfo.wikiToken,
                                                          isShortcut: wikiInfo.wikiNodeState.isShortcut,
                                                          triggerLocation: .topBar,
                                                          targetModule: location.targetModule,
                                                          targetFolderType: location.targetFolderType)
                }
            } onError: { error in
                DocsLogger.error("wiki shortcut fail \(error)")
                let toastMessage = Self.parseShortcutMessage(from: error, location: location)
                UDToast.showFailure(with: toastMessage, on: hostController.view.window ?? hostController.view)
                WikiStatistic.wikiDocsMoveResultToastView(success: false, viewTitle: .shortcutTo)
            }
            .disposed(by: bag)
    }

    private func showShortcutSuccess(with url: URL, hostController: UIViewController) {
        let operation = UDToastOperationConfig(text: BundleI18n.SKResource.CreationMobile_Wiki_ClickToView_Toast,
                                               displayType: .horizontal)
        let config = UDToastConfig(toastType: .success,
                                   text: BundleI18n.SKResource.CreationMobile_Wiki_Shortcuts_CreateSuccessfully_Toast,
                                   operation: operation,
                                   delay: 5)
        UDToast.showToast(with: config,
                          on: hostController.view.window ?? hostController.view,
                          operationCallBack: { [weak self] _ in
            guard self != nil else {
                return
            }
            let browser = EditorManager.shared.currentEditor
            if browser?.vcFollowDelegate == nil {
                Navigator.shared.push(url, from: hostController)
            } else {
                guard let browser = browser else { return }
                _ = EditorManager.shared.requiresOpen(browser, url: url)
            }
            WikiStatistic.wikiDocsMoveResultToast(click: .docsView,
                                                  viewTitle: .shortcutTo,
                                                  target: DocsTracker.EventType.docsPageView.rawValue)
        })
        WikiStatistic.wikiDocsMoveResultToastView(success: true, viewTitle: .shortcutTo)
    }

    private static func parseShortcutMessage(from error: Error, location: WorkspacePickerLocation) -> String {
        if let networkError = error as? DocsNetworkError {
            if networkError.code == .forbidden {
                // 特化文案
                switch location {
                case .wikiNode:
                    return BundleI18n.SKResource.LarkCCM_Docs_ActionFailed_NoTargetPermission_Mob
                case .folder:
                    return BundleI18n.SKResource.LarkCCM_Workspace_FolderPerm_CantShortcut_Tooltip
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
    
    private func shortcutDuplicateCheck(objToken: String,
                                        objType: DocsType,
                                        location: WorkspacePickerLocation,
                                        picker: UIViewController,
                                        callBack: @escaping ((_ showLoading: Bool) -> Void)) {
        let toastView: UIView = picker.view.window ?? picker.view
        UDToast.showLoading(with: BundleI18n.SKResource.CreationMobile_Wiki_CreateCopy_Creating_Toast,
                            on: toastView,
                            disableUserInteraction: true)
        WorkspaceCrossNetworkAPI.addShortcutDuplicateCheck(objToken: objToken,
                                                           objType: objType,
                                                           location: location)
        .subscribe(onSuccess: { [weak self] stages in
            switch stages {
            case .hasEntity, .hasShortcut:
                UDToast.removeToast(on: toastView)
                self?.confirmAddShortcutInDuplicateStages(stages: stages, picker: picker, compeltion: {
                    callBack(true)
                    DocsTracker.shortcutDuplicateCheckClick(stages: stages, click: "add", fileId: objToken, fileTypeName: objType.name)
                })
            case .normal:
                callBack(false)
            }
        }, onError: {[weak self] error in
            DocsLogger.error("space.file.more: shortcut duplicate check error: \(error)")
            callBack(false)
        })
        .disposed(by: bag)
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
}

extension WikiMoreActionHandler {
    // wiki删除
    func wikiDelete() {
        guard let currentTopMost = hostViewController,
              let wikiInfo = docsInfo.wikiInfo else {
            DocsLogger.error("can not get the wiki info")
            return
        }
        if wikiInfo.wikiNodeState.isShortcut || !wikiInfo.wikiNodeState.hasChild {
            wikiAllDelete()
        } else {
            showWikiDeleteScopeSelectVC(wikiInfo: wikiInfo, sourceView: currentTopMost)
        }
    }
    
    func showWikiDeleteScopeSelectVC(wikiInfo: WikiInfo, sourceView: UIViewController) {
        let canSingleDelete = wikiInfo.wikiNodeState.showSingleDelete
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
        nodeDeleteScopeVC.modalPresentationStyle = .overFullScreen
        nodeDeleteScopeVC.confirmCompletion = { [weak self] type in
            switch type {
            case .all:
                self?.wikiAllDeleteHandler(wikiInfo: wikiInfo, sourceView: sourceView)
            case .single:
                self?.wikiSingleDelete(wikiInfo: wikiInfo, sourceView: sourceView)
            default:
                spaceAssertionFailure("if none, confirm button status is disabled, can not go here!")
                return
            }
        }
        if SKDisplay.pad, let browserVC = sourceView as? BaseViewController {
            browserVC.showPopover(panel: nodeDeleteScopeVC, at: -1)
        } else {
            Navigator.shared.present(nodeDeleteScopeVC, from: sourceView)
        }
    }

    func wikiSingleDelete(wikiInfo: WikiInfo, sourceView: UIViewController) {
        UDToast.showLoading(with: BundleI18n.SKResource.LarkCCM_Workspace_DeletePageIng_Toast,
                            on: sourceView.view.window ?? sourceView.view)
        WikiMoreAPI.deleteSingleNode(wikiToken: wikiInfo.wikiToken, spaceID: wikiInfo.spaceId)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] reviewerInfo in
                UDToast.removeToast(on: sourceView.view.window ?? sourceView.view)
                self?.applyDelete(meta: wikiInfo.wikiMeta,
                                  isSingleDelete: true,
                                  reviewerInfo: reviewerInfo,
                                  hostController: sourceView)
            } onError: { [weak self] error in
                DocsLogger.error("delete wiki failed \(error)")
                if let rxError = error as? RxError, case .timeout = rxError {
                    UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_Workspace_DeletePage_OT_Toast,
                                        on: sourceView.view.window ?? sourceView.view)
                } else {
                    let error = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
                    self?.showDeleteFailedDialog(error: error, sourceView: sourceView)
                }
            } onCompleted: { [weak self] in
                UDToast.removeToast(on: sourceView.view.window ?? sourceView.view)
                UDToast.showSuccess(with: BundleI18n.SKResource.LarkCCM_Workspace_DeletePage_Deleted_Toast,
                                    on: sourceView.view.window ?? sourceView.view)
                // 同步space列表页文档删除移除列表
                let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
                SKDataManager.shared.deleteFileByToken(token: TokenStruct(token: wikiInfo.wikiToken))
                // 同步新首页置顶列表文档移除列表
                NotificationCenter.default.post(name: .Docs.deleteDocInNewHome, object: wikiInfo.wikiToken)
                self?.popViewController(canEmpty: true)
            }
            .disposed(by: bag)
    }
    
    func wikiAllDelete() {
        guard let wikiInfo = docsInfo.wikiInfo,
              let currentTopMost = hostViewController else {
            return
        }
        WikiStatistic.clickTreeNodeDelete(wikiToken: wikiInfo.wikiToken,
                                          fileType: wikiInfo.docsType.name)
        // 弹窗
        let title = wikiInfo.wikiNodeState.isShortcut ?
            BundleI18n.SKResource.CreationMobile_Wiki_Shortcuts_DeleteShortcuts_Tooltip :
            BundleI18n.SKResource.CreationMobile_Wiki_RemoveThePage_Title
        let originContent = BundleI18n.SKResource.LarkCCM_Workspace_Trash_DeleteIn30D_Popover_Text
        let shorcutContent = BundleI18n.SKResource.LarkCCM_Workspace_Trash_DeleteShortcut_Descrip
        let content = wikiInfo.wikiNodeState.isShortcut ? shorcutContent : originContent
        let caption: String? = {
            if wikiInfo.wikiNodeState.isShortcut { return nil }
            return BundleI18n.SKResource.CreationMobile_Common_DeleteOthersPage
        }()
        let dialog = UDDialog()
        dialog.setTitle(text: title)
        if let caption = caption {
            dialog.setContent(text: content, caption: caption)
        } else {
            dialog.setContent(text: content)
        }
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
        dialog.addDestructiveButton(text: BundleI18n.SKResource.CreationMobile_Wiki_Permission_Remove_Toast,
                                    dismissCompletion: { [weak self] in
            guard let self else { return }
            self.wikiAllDeleteHandler(wikiInfo: wikiInfo, sourceView: currentTopMost)
        })
        Navigator.shared.present(dialog, from: currentTopMost, animated: true)
    }
    
    private func wikiAllDeleteHandler(wikiInfo: WikiInfo, sourceView: UIViewController) {
        UDToast.showLoading(with: BundleI18n.SKResource.LarkCCM_Workspace_DeletePageIng_Toast,
                            on: sourceView.view.window ?? sourceView.view)
        WikiNetworkManager.shared.deleteNode(wikiInfo.wikiToken,
                                             spaceId: wikiInfo.spaceId,
                                             canApply: UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled)
        .observeOn(MainScheduler.instance)
        .subscribe { [weak self] reviewerInfo in
            UDToast.removeToast(on: sourceView.view.window ?? sourceView.view)
            self?.applyDelete(meta: wikiInfo.wikiMeta,
                              isSingleDelete: false,
                              reviewerInfo: reviewerInfo,
                              hostController: sourceView)
        } onError: { [weak self] error in
            DocsLogger.error("delete wiki failed \(error)")
            let error = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
            self?.showDeleteFailedDialog(error: error, sourceView: sourceView)
            WikiStatistic.confirmTreeNodeDelete(wikiToken: wikiInfo.wikiToken,
                                                fileType: wikiInfo.docsType.name,
                                                status: .fail)
        } onCompleted: { [weak self] in
            UDToast.removeToast(on: sourceView.view.window ?? sourceView.view)
            UDToast.showSuccess(with: BundleI18n.SKResource.CreationMobile_Wiki_RemoveSuccessfully_Toast,
                                on: sourceView.view.window ?? sourceView.view)
            self?.popViewController(canEmpty: true)
            // 同步space列表页文档删除移除列表
            let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
            SKDataManager.shared.deleteFileByToken(token: TokenStruct(token: wikiInfo.wikiToken))
            // 同步新首页置顶列表文档移除列表
            NotificationCenter.default.post(name: .Docs.deleteDocInNewHome, object: wikiInfo.wikiToken)
            WikiStatistic.confirmTreeNodeDelete(wikiToken: wikiInfo.wikiToken,
                                                fileType: wikiInfo.docsType.name,
                                                status: .success)
        }
        .disposed(by: bag)
    }
    
    // canEmpty: iPad 模式下是否可以pop到兜底页
    public func popViewController(canEmpty: Bool) {
        if let vc = hostViewController as? BaseViewController {
            vc.back(canEmpty: canEmpty)
        } else {
            spaceAssertionFailure("currentBrowserVC is not BaseViewController")
            hostViewController?.navigationController?.popViewController(animated: true)
        }
    }
    
    private func showDeleteFailedDialog(error: WikiErrorCode, sourceView: UIViewController) {
        UDToast.removeToast(on: sourceView.view.window ?? sourceView.view)
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
            Navigator.shared.present(dialog, from: sourceView)
        case .nodesCountLimitExceed:
            //上移子节点超过了当前目录树节点上限
            let description = BundleI18n.SKResource.LarkCCM_Workspace_DeletePageFail_OverLimit
            dialog.setContent(text: description)
            Navigator.shared.present(dialog, from: sourceView)
        case .cacDeleteBlcked:
            DocsLogger.info("cac delete blocked, no need show tips or dialog")
        default:
            UDToast.showFailure(with: error.deleteErrorDescription,
                                   on: sourceView.view.window ?? sourceView.view)
        }
    }

    // 申请删除流程，提示用户并填写申请理由
    private func applyDelete(meta: WikiMeta,
                             isSingleDelete: Bool,
                             reviewerInfo: WikiAuthorizedUserInfo,
                             hostController: UIViewController) {
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
                DocsLogger.error("failed to generate helper center URL when apply delete in wiki from detail more panel", error: error)
            }
        }
        let controller = SKApplyPanelController.createController(config: config)
        Navigator.shared.present(controller, from: hostController)
    }

    // 确认申请删除，发起请求
    private func confirmApplyDelete(meta: WikiMeta,
                                    isSingleDelete: Bool,
                                    reviewerInfo: WikiAuthorizedUserInfo,
                                    reason: String?,
                                    controller: UIViewController) {
        UDToast.showLoading(with: BundleI18n.SKResource.CreationMobile_Comment_Add_Sending_Toast, on: controller.view.window ?? controller.view)
        WikiNetworkManager.shared.applyDelete(wikiMeta: meta,
                                              isSingleDelete: isSingleDelete,
                                              reason: reason,
                                              reviewerID: reviewerInfo.userID)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak controller, weak self] in
                guard let controller, let self else { return }
                UDToast.removeToast(on: controller.view.window ?? controller.view)
                controller.dismiss(animated: true)
                guard let hostController = self.hostViewController else { return }
                UDToast.showSuccess(with: BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AskOwner_SentToast, on: hostController.view.window ?? hostController.view)
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
            .disposed(by: bag)
    }
}

extension WikiMoreActionHandler {
    func moveWiki() {
        guard let wikiInfo = docsInfo.wikiInfo,
              let hostViewController else {
            return
        }
        let synergyUUID = interactionHandler.synergyUUID
        let context = Self.convert(wikiInfo: wikiInfo, docsInfo: docsInfo)
        let moveContext = WikiInteractionHandler.MoveContext(subContext: context,
                                                             canMove: wikiInfo.wikiNodeState.canMove,
                                                             permissionLocked: wikiInfo.wikiNodeState.isLocked,
                                                             hasChild: wikiInfo.wikiNodeState.hasChild) { [weak self] sortID, parentMeta in
            // 这里要把移动事件通知给Wiki Container
            let notification = WikiLocalSync.movedFromMore(movedMeta: context.wikiMeta,
                                                           newParentMeta: parentMeta,
                                                           newSortID: sortID,
                                                           oldParentToken: wikiInfo.wikiNodeState.parentWikiToken,
                                                           synergyUUID: synergyUUID)
            NotificationCenter.default.post(notification)
            // 发通知后再更新下 wikiInfo
            guard let self else { return }
            self.docsInfo.wikiInfo?.spaceId = parentMeta.spaceID
            self.docsInfo.wikiInfo?.wikiNodeState.parentWikiToken = parentMeta.wikiToken
        } didMovedToSpace: { [weak hostViewController] _ in
            // 移动到 Space 后直接关闭
            guard let controller = hostViewController as? BaseViewController else { return }
            if controller.presentedViewController != nil {
                controller.dismiss(animated: true) {
                    controller.back(canEmpty: true)
                }
            } else {
                controller.back(canEmpty: true)
            }
        }
        let entrances = interactionHandler.entrancesForMove(moveContext: moveContext)
        let picker = interactionHandler.makeMovePicker(context: moveContext, triggerLocation: .topBar, entrances: entrances) { [weak self] picker, location in
            guard let self else { return }
            self.interactionHandler.confirmMoveTo(location: location, context: moveContext, picker: picker)
        }
        Navigator.shared.present(picker, from: hostViewController)
    }
}
