//
//  WorkSpacePickerAPI.swift
//  SKCommon
//
//  Created by liujinwei on 2023/2/9.
//


import Foundation
import UniverseDesignToast
import SKResource
import SKFoundation
import RxSwift
import SKUIKit
import EENavigator
import SpaceInterface
import LarkUIKit

open class InsideMoreActionHandler {
    
    public enum SourceType {
        case more   //more面板里的操作
        case other
    }

    let disposeBag = DisposeBag()
    let spaceAPI: SpaceManagementAPI
    let spaceMoveHelper: SpaceMoveInteractionHelper

    weak var hostVC: UIViewController?
    
    private let source: SourceType

    public init(hostVC: UIViewController?, spaceAPI: SpaceManagementAPI, from source: SourceType) {
        self.hostVC = hostVC
        self.spaceAPI = spaceAPI
        self.source = source
        self.spaceMoveHelper = SpaceMoveInteractionHelper(spaceAPI: spaceAPI)
    }

    public func copyFileWithPicker(docsInfo: DocsInfo, fileSize: Int64?) {
        guard let hostVC = self.hostVC else { return }
        let tracker = WorkspacePickerTracker(actionType: .makeCopyTo,
                                             triggerLocation: .topBar)
        let entrances: [WorkspacePickerEntrance]
        if docsInfo.isSingleContainerNode {
            entrances = .wikiAndSpace
        } else {
            entrances = .spaceOnly
        }
        let config = WorkspacePickerConfig(title: BundleI18n.SKResource.LarkCCM_Wiki_MoveACopyTo_Header_Mob,
                                           action: .copySpace,
                                           extraEntranceConfig: nil,
                                           entrances: entrances,
                                           ownerTypeChecker: { isSingleFolder in
            // 检查 space 版本是否匹配
            guard docsInfo.isSingleContainerNode != isSingleFolder else { return nil }
            if isSingleFolder {
                // 1.0 文件 + 2.0 文件夹
                return BundleI18n.SKResource.CreationMobile_ECM_UnableAddFolderToast
            } else {
                // 2.0 文件 + 1.0 文件夹
                return BundleI18n.SKResource.CreationMobile_ECM_UnableDuplicateDocToast
            }
        },
                                           disabledWikiToken: nil,
                                           usingLegacyRecentAPI: !docsInfo.isSingleContainerNode,
                                           tracker: tracker) { [weak self] location, picker in
            guard let self else { return }
            switch location {
            case let .wikiNode(location):
                self.confirmCopyToWiki(docsInfo: docsInfo, location: location, fileSize: fileSize, picker: picker)
            case let .folder(location):
                guard location.canCreateSubNode else {
                    UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_Workspace_FolderPerm_CantCopy_Tooltip,
                                        on: picker.view.window ?? picker.view)
                    return
                }
                self.confirmCopyToSpace(docsInfo: docsInfo, folderToken: location.folderToken, fileSize: fileSize, picker: picker)
            }
        }
        let picker = WorkspacePickerFactory.createWorkspacePicker(config: config)
        LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) {
            Navigator.shared.present(picker, from: hostVC, animated: true)
        }
    }

    private func confirmCopyToSpace(docsInfo: DocsInfo, folderToken: String, fileSize: Int64?, picker: UIViewController) {
        let fileType = docsInfo.type
        var originTitle = docsInfo.title ?? ""
        if originTitle.isEmpty {
            originTitle = fileType.untitledString
        }
        let objToken = docsInfo.isVersion ? docsInfo.versionInfo!.versionToken : docsInfo.objToken
        let ownerType = docsInfo.ownerType ?? defaultOwnerType
        let parentToken = folderToken
        let trackParams = DocsCreateDirectorV2.TrackParameters(source: .larkCreate,
                                                               module: .home(.recent),
                                                               ccmOpenSource: .copy)
        UDToast.showDefaultLoading(on: picker.view.window ?? picker.view)
        let request = WorkspaceManagementAPI.Space.CopyToSpaceRequest(
            sourceMeta: SpaceMeta(objToken: objToken, objType: fileType),
            ownerType: ownerType,
            folderToken: parentToken,
            originName: originTitle,
            fileSize: fileSize,
            trackParams: trackParams
        )
        WorkspaceManagementAPI.Space.copyToSpace(request: request,
                                                 router: picker as? DocsCreateViewControllerRouter).subscribe { [weak self] fileURL in
            guard let self = self else { return }
            UDToast.removeToast(on: picker.view.window ?? picker.view)
            FileListStatistics.reportClientContentManagement(statusName: "", action: "make_a_copy")
            var tips = BundleI18n.SKResource.Doc_Facade_MakeCopySucceed
            if fileType == .sheet {
                tips = BundleI18n.SKResource.CreationMobile_Sheets_MakeCopying_Toast
            }
            let operation = UDToastOperationConfig(text: BundleI18n.SKResource.CreationMobile_Doc_Facade_MakeCopySucceed_open_btn)
            let config = UDToastConfig(toastType: .success, text: tips, operation: operation, delay: 4)
            let callback: (String?) -> Void = { [weak self] _ in
                guard let self = self else { return }
                guard let rootVC = self.hostVC?.view.window?.rootViewController,
                      let from = UIViewController.docs.topMost(of: rootVC) else { return }
                let url: URL
                if UserScopeNoChangeFG.XM.ccmBitableRecordsGantt {
                    url = fileURL.docs.addOrChangeEncodeQuery(parameters: ["from": "create_suite_template"])
                } else {
                    url = fileURL
                }
                self.openCopyFileWith(url, from: from)
                self.reportClientCopyAction(url.absoluteString, fileType: fileType, error: "")
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
                } else if DocsNetworkError.isDlpError(docsError) {
                    DlpManager.updateCurrentToken(token: objToken)
                    let text = DocsNetworkError.dlpErrorMsg(docsError)
                    UDToast.showFailure(with: text, on: picker.view)
                }
            }
        }
        .disposed(by: disposeBag)
    }

    private func confirmCopyToWiki(docsInfo: DocsInfo, location: WikiPickerLocation, fileSize: Int64?, picker: UIViewController) {
        UDToast.showDefaultLoading(on: picker.view.window ?? picker.view)
        let newTitle = DocsRequestCenter.getCopyTitle(objType: docsInfo.type, name: docsInfo.name)
        let needAsync = docsInfo.type == .sheet
        let objToken = docsInfo.isVersion ? docsInfo.versionInfo!.versionToken : docsInfo.objToken
        let a = WorkspaceManagementAPI.Space.copyToWiki(objToken: objToken, objType: docsInfo.type, location: location, title: newTitle, needAsync: needAsync).map { $1 }

            a.observeOn(MainScheduler.instance)
            .subscribe { [weak self] wikiToken in
                UDToast.removeToast(on: picker.view.window ?? picker.view)
                guard let self = self else { return }
                let url = DocsUrlUtil.url(type: .wiki, token: wikiToken)
                let tips = needAsync
                ? BundleI18n.SKResource.CreationMobile_Sheets_MakeCopying_Toast
                : BundleI18n.SKResource.Doc_Facade_MakeCopySucceed
                UDToast.showTips(with: tips,
                                 operationText: BundleI18n.SKResource.CreationMobile_Doc_Facade_MakeCopySucceed_open_btn,
                                 on: picker.view.window ?? picker.view,
                                 delay: 4,
                                 operationCallBack: { [weak self] _ in
                    guard let self = self else { return }
                    guard let rootVC = self.hostVC?.view.window?.rootViewController,
                          let from = UIViewController.docs.topMost(of: rootVC) else { return }
                    let openUrl: URL
                    if UserScopeNoChangeFG.XM.ccmBitableRecordsGantt, docsInfo.type == .bitable {
                        openUrl = url.docs.addOrChangeEncodeQuery(parameters: ["from": "create_suite_template"])
                    } else {
                        openUrl = url
                    }
                    self.openCopyFileWith(openUrl, from: from)
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
                    } else if DocsNetworkError.isDlpError(networkError) {
                        DlpManager.updateCurrentToken(token: objToken)
                        message = DocsNetworkError.dlpErrorMsg(networkError)
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
            .disposed(by: self.disposeBag)
    }

    open func openCopyFileWith(_ fileUrl: URL, from: UIViewController) {
        Navigator.shared.push(fileUrl, from: from)
    }

    // Space移动到功能
    public func moveWithPicker(context: SpaceMoveInteractionHelper.MoveContext) {
        guard let hostVC = self.hostVC else { return }
        let movePicker = spaceMoveHelper.makeMovePicker(context: context)
        LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) {
            Navigator.shared.present(movePicker, from: hostVC, animated: true)
        }
    }
}

///埋点
extension InsideMoreActionHandler {
    
    private func reportClientCopyAction(_ url: String, fileType: DocsType, error: String) {
        //more面板里才报埋点
        guard self.source == .more else { return }
        let array = url.split(separator: "/")
        let token = String(array.last ?? "")
        let params = ["status_name": error,
            "file_type": fileType.name,
            "file_id": DocsTracker.encrypt(id: token)] as [String: Any]
        DocsTracker.log(enumEvent: .clickMakeCopy, parameters: params)
    }
    
}

// 删除逻辑
extension InsideMoreActionHandler {
    // 删除当前文档，回调返回删除是否成功, 方便业务自定义退出逻辑
    public func deleteFile(docsInfo: DocsInfo, completion: @escaping (Bool) -> Void) {
        if docsInfo.isSingleContainerNode {
            deleteV2File(docsInfo: docsInfo, completion: completion)
        } else {
            deleteV1File(docsInfo: docsInfo, completion: completion)
        }
    }

    private func deleteV2File(docsInfo: DocsInfo, completion: @escaping (Bool) -> Void) {
        spaceAPI.deleteInDoc(objToken: docsInfo.objToken,
                             docType: docsInfo.type,
                             canApply: UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled)
        .subscribe { [weak self] reviewerInfo in
            completion(false)
            guard let self, let hostController = self.hostVC else {
                return
            }
            self.applyDelete(docsInfo: docsInfo, reviewerInfo: reviewerInfo, hostController: hostController)
        } onError: { [weak self] error in
            guard let self, let hostController = self.hostVC else {
                completion(false)
                return
            }
            let hostView: UIView = hostController.view.window ?? hostController.view
            if let docsError = error as? DocsNetworkError, docsError.code == .cacDeleteBlocked {
                DocsLogger.error("cac blocked")
            } else if let docsError = error as? DocsNetworkError, let message = docsError.code.errorMessage {
                UDToast.showFailure(with: message, on: hostView)
            } else {
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_Delete + BundleI18n.SKResource.Doc_Normal_Fail, on: hostView)
            }
            completion(false)
        } onCompleted: { [weak self] in
            guard let self, let hostController = self.hostVC else {
                completion(false)
                return
            }
            let hostView: UIView = hostController.view.window ?? hostController.view
            UDToast.showSuccess(with: BundleI18n.SKResource.Doc_List_DeleteSuccessfully, on: hostView)
            completion(true)
        }
        .disposed(by: disposeBag)
    }

    private func applyDelete(docsInfo: DocsInfo, reviewerInfo: AuthorizedUserInfo, hostController: UIViewController) {
        var config = SKApplyPanelConfig(userInfo: reviewerInfo,
                                        title: BundleI18n.SKResource.LarkCCM_CM_RequestToDeleteDoc_Title,
                                        placeHolder: BundleI18n.SKResource.LarkCCM_Wiki_Move_ReqPermission_Context,
                                        actionName: BundleI18n.SKResource.CreationMobile_Wiki_MoveToSpace_AskOwner_Btn,
                                        contentProvider: { BundleI18n.SKResource.LarkCCM_CM_NoPermToDeletePageWithParentPageSettings_Description($0) })
        config.actionHandler = { [weak self] controller, reason in
            DocsLogger.info("user confirm to apply delete space entry")
            self?.confirmApplyDelete(docsInfo: docsInfo,
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
                DocsLogger.error("failed to generate helper center URL when apply delete in space from detail more panel", error: error)
            }
        }
        let controller = SKApplyPanelController.createController(config: config)
        Navigator.shared.present(controller, from: hostController)
    }


    // 确认申请删除，发起请求
    private func confirmApplyDelete(docsInfo: DocsInfo,
                                    reviewerInfo: AuthorizedUserInfo,
                                    reason: String?,
                                    controller: UIViewController) {
        UDToast.showLoading(with: BundleI18n.SKResource.CreationMobile_Comment_Add_Sending_Toast, on: controller.view.window ?? controller.view)
        spaceAPI.applyDelete(meta: SpaceMeta(objToken: docsInfo.token, objType: docsInfo.inherentType),
                             reviewerID: reviewerInfo.userID,
                             reason: reason)
            .subscribe { [weak controller, weak self] in
                guard let controller, let self else { return }
                UDToast.removeToast(on: controller.view.window ?? controller.view)
                controller.dismiss(animated: true)
                guard let hostController = self.hostVC else { return }
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
            .disposed(by: disposeBag)
    }

    private func deleteV1File(docsInfo: DocsInfo, completion: @escaping (Bool) -> Void) {
        spaceAPI.delete(objToken: docsInfo.objToken, docType: docsInfo.type) { [weak self] error in
            guard let self, let hostController = self.hostVC else {
                completion(false)
                return
            }
            let hostView: UIView = hostController.view.window ?? hostController.view
            if let error {
                if let docsError = error as? DocsNetworkError, let message = docsError.code.errorMessage {
                    UDToast.showFailure(with: message, on: hostView)
                } else {
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_Delete + BundleI18n.SKResource.Doc_Normal_Fail, on: hostView)
                }
                completion(false)
                return
            }
            UDToast.showSuccess(with: BundleI18n.SKResource.Doc_List_DeleteSuccessfully, on: hostView)
            // 删除成功需要退出 controller
            completion(true)
        }
    }
}
