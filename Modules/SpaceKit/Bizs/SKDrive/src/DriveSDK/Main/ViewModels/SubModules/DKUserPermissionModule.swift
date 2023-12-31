//
//  DKUserPermissionModule.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/22.
//

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import SKUIKit
import EENavigator
import LarkUIKit
import SKResource
import UniverseDesignToast
import SKInfra
import SpaceInterface

class DKUserPermissionModule: DKBaseSubModule {
    var navigator: DKNavigatorProtocol
    private var filePermissionRequest: DocsRequest<[String: Any]>?
    init(hostModule: DKHostModuleType, navigator: DKNavigatorProtocol = Navigator.shared) {
        self.navigator = navigator
        super.init(hostModule: hostModule)
    }
    deinit {
        DocsLogger.driveInfo("DKUserPermissionModule -- deinit")
    }
    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        guard let host = hostModule else { return self }
        host.subModuleActionsCenter.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] action in
            guard let self = self else {
                return
            }
            if case let .applyEditPermission(scene) = action {
                self.handleApplyEditPermission(scene: scene)
            }
        }).disposed(by: bag)
        return self
    }
    
    func handleApplyEditPermission(scene: InsideMoreDataProvider.ApplyEditScene) {
        switch scene {
        case .userPermission:
            applyEditUserPermission()
        case .auditExempt:
            applyEditAuditExempt()
        }
    }

    private func applyEditAuditExempt() {
        guard let hostController = hostModule?.hostController else {
            DocsLogger.error("failed to get host controller when apply edit permission")
            spaceAssertionFailure()
            return
        }
        var userName = ""
        var tenantName = ""
        if let currentUserInfo = User.current.info {
            userName = currentUserInfo.nameForDisplay()
            tenantName = (currentUserInfo.isToNewC ? BundleI18n.SKResource.Doc_Permission_PersonalAccount : currentUserInfo.tenantName) ?? ""
            if userName.isEmpty {
                let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
                if let userInfo = dataCenterAPI?.userInfo(for: currentUserInfo.userID) {
                    userName = userInfo.nameForDisplay()
                    tenantName = (userInfo.isToNewC ? BundleI18n.SKResource.Doc_Permission_PersonalAccount : userInfo.tenantName) ?? ""
                }
            }
        }

        var currentUserName = ""
        if !userName.isEmpty {
            currentUserName = "\(tenantName)-\(userName)"
        }
        var config = SKApplyPanelConfig(userInfo: .empty,
                                        title: BundleI18n.SKResource.Doc_Resource_ApplyEditPerm,
                                        placeHolder: BundleI18n.SKResource.Doc_Facade_AddRemarks,
                                        actionName: BundleI18n.SKResource.Doc_Facade_ApplyFor) { _ in
            BundleI18n.SKResource.LarkCCM_CM_Sharing_AskForFurtherEditPerm_Desc(currentUserName)
        }
        config.actionHandler = { [weak self] controller, reason in
            self?.confirmApplyEditExempt(controller: controller, reason: reason)
        }
        let controller = SKApplyPanelController.createController(config: config)
        navigator.present(vc: controller, from: hostController, animated: true)
    }

    private func confirmApplyEditExempt(controller: UIViewController, reason: String?) {
        let toastView: UIView = controller.view.window ?? controller.view
        UDToast.showLoading(with: BundleI18n.SKResource.LarkCCM_Perm_PermissionRequesting_Mobile,
                            on: toastView)
        AuditExemptAPI.requestExempt(objToken: docsInfo.objToken,
                                     objType: docsInfo.type,
                                     exemptType: .edit,
                                     reason: reason)
        .subscribe { [weak controller, weak toastView] in
            guard let controller, let toastView else { return }
            UDToast.removeToast(on: toastView)
            UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Permission_SendRequestSuccessfully, on: toastView)
            controller.dismiss(animated: true)
        } onError: { [weak toastView] error in
            DocsLogger.driveError("apply edit exempt failed", error: error)
            guard let toastView else { return }
            UDToast.removeToast(on: toastView)
            let exemptError = AuditExemptAPI.parse(error: error)
            switch exemptError {
            case .tooFrequent:
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Permission_SendRequestMaxCount, on: toastView)
            case .other:
                UDToast.showFailure(with: BundleI18n.SKResource.Drive_Drive_SendRequestFail, on: toastView)
            }
        }
        .disposed(by: bag)
    }

    private func applyEditUserPermission() {
        guard let hostController = hostModule?.hostController else {
            DocsLogger.error("failed to get host controller when apply edit permission")
            assertionFailure()
            return
        }
        let publicPermissionMeta = DocsContainer.shared.resolve(PermissionManager.self)?.getPublicPermissionMeta(token: docsInfo.objToken)
        let userPermissions = DocsContainer.shared.resolve(PermissionManager.self)?.getUserPermissions(for: docsInfo.objToken)
        let ccmCommonParameters = CcmCommonParameters(fileId: docsInfo.encryptedObjToken,
                                                      fileType: docsInfo.type.name,
                                                      appForm: (docsInfo.isInVideoConference == true) ? "vc" : "none",
                                                      subFileType: fileInfo.type,
                                                      module: "drive",
                                                      userPermRole: userPermissions?.permRoleValue,
                                                      userPermissionRawValue: userPermissions?.rawValue,
                                                      publicPermission: publicPermissionMeta?.rawValue)
        let permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)
        var ownerName = docsInfo.displayName
        if ownerName.count <= 0 {
            ownerName = docsInfo.ownerName ?? ""
        }
        let vc = AskOwnerForInviteCollaboratorViewController(ownerName: ownerName,
                                                             ownerID: docsInfo.ownerID ?? "",
                                                             permStatistics: permStatistics) { [weak self] message in
            guard let self = self else { return }
            self.requestFilePermission(message: message)
            permStatistics.reportPermissionReadWithoutEditClick(click: .apply,
                                                                target: .noneTargetView,
                                                                isAddNotes: message.count > 0)
        }
        vc.supportOrientations = hostController.supportedInterfaceOrientations
        let nav = LkNavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .overCurrentContext
        nav.update(style: .clear)
        navigator.present(vc: nav, from: hostController, animated: false)
    }

    private func requestFilePermission(message: String?) {
        let docsInfo = self.docsInfo
        var params = ["token": docsInfo.objToken,
                      "obj_type": docsInfo.type.rawValue,
                      "permission": 4] as [String: Any]
        if message?.isEmpty == false {
            params.updateValue(message ?? "", forKey: "message")
        }
        
        filePermissionRequest = DocsRequest(path: OpenAPI.APIPath.requestFilePermissionUrl, params: params)
        filePermissionRequest?.start(rawResult: { [weak self] (data, response, _) in
            guard let self = self else { return }
            // nolint-next-line: magic number
            if let response = response as? HTTPURLResponse, response.statusCode == 429 {
                self.showFailure(content: BundleI18n.SKResource.Doc_Permission_SendRequestMaxCount)
                self.reportClickSendApplyEditPermission(docsInfo: docsInfo, status: 0, message: message)
                return
            }
            guard let jsonData = data,
                  let json = jsonData.json else {
                self.showFailure(content: BundleI18n.SKResource.Drive_Drive_SendRequestFail)
                self.reportClickSendApplyEditPermission(docsInfo: docsInfo, status: 0, message: message)
                return
            }
            guard let code = json["code"].int else {
                self.showFailure(content: BundleI18n.SKResource.Drive_Drive_SendRequestFail)
                self.reportClickSendApplyEditPermission(docsInfo: docsInfo, status: 0, message: message)
                return
            }
            guard code == 0 else {
                let statistics = CollaboratorStatistics(docInfo: CollaboratorAnalyticsFileInfo(fileType: docsInfo.type.name,
                                                                         fileId: docsInfo.objToken),
                                                        module: docsInfo.type.name)
                let fromView = self.hostModule?.hostController?.view
                let manager = CollaboratorBlockStatusManager(requestType: .requestPermissionForBiz, fromView: fromView, statistics: statistics)
                manager.showRequestPermissionForBizFaliedToast(json, ownerName: docsInfo.displayName)
                self.reportClickSendApplyEditPermission(docsInfo: docsInfo, status: 0, message: message)
                return
            }
            if let resultData = json["data"].dictionary,
               let result = resultData["ret"]?.bool, Bool(result) {
                self.showSuccess(content: BundleI18n.SKResource.Doc_Permission_SendRequestSuccessfully)
                self.reportClickSendApplyEditPermission(docsInfo: docsInfo, status: 1, message: message)
                return
            } else {
                self.showFailure(content: BundleI18n.SKResource.Drive_Drive_SendRequestFail)
                self.reportClickSendApplyEditPermission(docsInfo: docsInfo, status: 0, message: message)
            }
        })
    }
    
    private func showSuccess(content: String) {
        guard let window = hostModule?.hostController?.view.window else { return }
        UDToast.showSuccess(with: content, on: window)
    }

    private func showFailure(content: String) {
        guard let window = hostModule?.hostController?.view.window  else { return }
        UDToast.showFailure(with: content, on: window)
    }
    
    func reportClickSendApplyEditPermission(docsInfo: DocsInfo, status: Int, message: String?) {
        let note = (message?.isEmpty ?? true) ? "0" : "1"
        let params: [String: Any] = ["file_type": docsInfo.type.name,
                                     "file_id": docsInfo.encryptedObjToken,
                                      "action": "send",
                                      "permission": "edit",
                                      "note": note,
                                      "status": String(status)]
        DocsTracker.log(enumEvent: .clickSendApplyEditPermission, parameters: params)
    }
}
