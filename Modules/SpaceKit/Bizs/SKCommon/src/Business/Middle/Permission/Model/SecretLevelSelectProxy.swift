//
//  SecretLevelSelectProxy.swift
//  SKCommon
//
//  Created by peilongfei on 2022/9/28.
//  


import Foundation
import SKFoundation
import UniverseDesignToast
import EENavigator
import LarkUIKit
import SKResource
import RxSwift
import SKUIKit
import SKInfra

public final class SecretLevelSelectProxy: SecretLevelSelectDelegate, SecretModifyOriginalViewDelegate {
    
    let docsInfo: DocsInfo
    
    let userPermission: UserPermissionAbility?
    
    weak var topVC: UIViewController?
    
    var updateSecLabelDisposeBag = DisposeBag()
    
    public init(docsInfo: DocsInfo, userPermission: UserPermissionAbility?, topVC: UIViewController?) {
        self.docsInfo = docsInfo
        self.userPermission = userPermission
        self.topVC = topVC
    }
    
    public func toSetSecretVC() {
        guard let level = docsInfo.secLabel else {
            DocsLogger.error("level is nil", component: LogComponents.comment)
            return
        }
        guard let topVC = topVC else {
            DocsLogger.error("topVC is nil", component: LogComponents.comment)
            return
        }
        
        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
        let publicPermissionMeta = permissionManager.getPublicPermissionMeta(token: docsInfo.objToken)
        let ccmCommonParameters = CcmCommonParameters(fileId: docsInfo.encryptedObjToken,
                                                      fileType: docsInfo.type.name,
                                                      appForm: (docsInfo.isInVideoConference == true) ? "vc" : "none",
                                                      subFileType: docsInfo.fileType,
                                                      module: docsInfo.type.name,
                                                      userPermRole: userPermission?.permRoleValue,
                                                      userPermissionRawValue: userPermission?.rawValue,
                                                      publicPermission: publicPermissionMeta?.rawValue)
        let permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)
        
        var wikiToken: String?
        var token = docsInfo.objToken
        if let wikiInfo = docsInfo.wikiInfo {
            wikiToken = wikiInfo.wikiToken
            token = wikiInfo.objToken
        }
        let type = docsInfo.type.rawValue
        let viewModel = SecretLevelViewModel(level: level, wikiToken: wikiToken, token: token, type: type, permStatistic: permStatistics, viewFrom: .banner)
        let isIPad = SKDisplay.pad && topVC.isMyWindowRegularSize()
        if isIPad {
            let viewController = IpadSecretLevelViewController(viewModel: viewModel)
            viewController.delegate = self
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .formSheet
            Navigator.shared.present(nav, from: topVC)
        } else {
            let viewController = SecretLevelViewController(viewModel: viewModel)
            viewController.delegate = self
            viewController.supportOrientations = topVC.supportedInterfaceOrientations
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .overFullScreen
            nav.transitioningDelegate = viewController.panelTransitioningDelegate
            Navigator.shared.present(nav, from: topVC)
        }
    }
    
    public func didClickConfirm(_ view: UIViewController, viewModel: SecretLevelViewModel, didUpdate: Bool, showOriginalView: Bool) {
        guard didUpdate else {
            DocsLogger.info("didupdate is no true")
            return
        }
        if showOriginalView {
            showSecretModifyOriginalViewController(viewModel: viewModel)
        } else {
            if viewModel.shouldShowUpgradeAlert {
                showUpgradeAlert(viewModel: viewModel)
            } else {
                upgradeSecret(viewModel: viewModel)
            }
        }
    }
    
    public func didClickCancel(_ view: UIViewController, viewModel: SecretLevelViewModel) {
    }
    
    public func didSelectRow(_ view: UIViewController, viewModel: SecretLevelViewModel) {
    }
    
    public func shouldApprovalAlert(_ view: UIViewController, viewModel: SecretLevelViewModel) {
        guard let levelLabel = viewModel.selectedLevelLabel else {
            DocsLogger.info("select level label is nil")
            return
        }
        guard let topVC = topVC else {
            DocsLogger.error("topVC is nil", component: LogComponents.comment)
            return
        }
        viewModel.reportCcmPermissionSecurityDemotionResubmitView()
        switch viewModel.approvalType {
        case .SelfRepeatedApproval:
            let dialog = SecretApprovalDialog.selfRepeatedApprovalDialog {
                viewModel.reportCcmPermissionSecurityDemotionResubmitClick(click: "cancel")
            } define: { [weak self] in
                guard let self = self else { return }
                self.showSecretModifyOriginalViewController(viewModel: viewModel)
                viewModel.reportCcmPermissionSecurityDemotionResubmitClick(click: "confirm")
            }
            topVC.present(dialog, animated: true, completion: nil)
        case .OtherRepeatedApproval:
            let dialog = SecretApprovalDialog.otherRepeatedApprovalDialog(num: viewModel.otherRepeatedApprovalCount, name: levelLabel.name) { [weak self] in
                guard let self = self else { return }
                self.showApprovalList(viewModel: viewModel)
                viewModel.reportCcmPermissionSecurityDemotionResubmitClick(click: "member_hover")
            } cancel: {
                viewModel.reportCcmPermissionSecurityDemotionResubmitClick(click: "cancel")
            } define: { [weak self] in
                guard let self = self else { return }
                self.showSecretModifyOriginalViewController(viewModel: viewModel)
                viewModel.reportCcmPermissionSecurityDemotionResubmitClick(click: "confirm")
            }
            topVC.present(dialog, animated: true, completion: nil)
        default: break
        }
    }
    
    public func didUpdateLevel(_ view: UIViewController, viewModel: SecretModifyViewModel) {
        let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
        dataCenterAPI?.updateSecurity(objToken: viewModel.wikiToken ?? viewModel.token, newSecurityName: viewModel.label.name)
    }
    
    public func didClickCancel(_ view: UIViewController, viewModel: SecretModifyViewModel) {
    }
    
    public func didSubmitApproval(_ view: UIViewController, viewModel: SecretModifyViewModel) {
        guard let topVC = topVC else {
            DocsLogger.error("topVC is nil", component: LogComponents.comment)
            return
        }
        viewModel.reportCcmPermissionSecurityDemotionResultView(success: true)
        let dialog = SecretApprovalDialog.sendApprovaSuccessDialog { [weak self] in
            guard let self = self else { return }
            self.showApprovalCenter(viewModel: viewModel)
            viewModel.reportCcmPermissionSecurityDemotionResultClick(click: "view_checking")
        } define: {
            viewModel.reportCcmPermissionSecurityDemotionResultClick(click: "known")
        }
        topVC.present(dialog, animated: true, completion: nil)
    }
}

extension SecretLevelSelectProxy {
    
    private func upgradeSecret(viewModel: SecretLevelViewModel) {
        guard let levelLabel = viewModel.selectedLevelLabel else {
            DocsLogger.error("leve label is nil")
            return
        }
        updateSecLabelDisposeBag = DisposeBag()
        SecretLevel.updateSecLabel(token: viewModel.token, type: viewModel.type, id: levelLabel.id, reason: "")
            .subscribe { [self] in
                DocsLogger.info("update secret level success")
                let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
                dataCenterAPI?.updateSecurity(objToken: viewModel.wikiToken ?? viewModel.token, newSecurityName: levelLabel.name)
                showToast(text: BundleI18n.SKResource.LarkCCM_Docs_SecurityLevel_SetasDefault_Toast, success: true)
            } onError: { [self] error in
                DocsLogger.error("update secret level fail", error: error)
                showToast(text: BundleI18n.SKResource.CreationMobile_SecureLabel_Change_Failed, success: false)
            }
            .disposed(by: updateSecLabelDisposeBag)
    }
    
    private func showToast(text: String, success: Bool = true) {
        guard !text.isEmpty else {
            return
        }
        guard let topVC = topVC, let view = topVC.view.window ?? topVC.view else {
            DocsLogger.error("topVC is nil", component: LogComponents.comment)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) {
            if success {
                UDToast.showSuccess(with: text, on: view)
            } else {
                UDToast.showFailure(with: text, on: view)
            }
        }
    }
    
    private func showApprovalCenter(viewModel: SecretModifyViewModel) {
        guard let config = SettingConfig.approveRecordProcessUrlConfig else {
            DocsLogger.error("config is nil")
            return
        }
        guard let instanceId = viewModel.instanceCode else {
            DocsLogger.error("instanceId is nil")
            return
        }
        guard let topVC = topVC else {
            DocsLogger.error("topVC is nil", component: LogComponents.comment)
            return
        }
        let urlString = config.url + instanceId
        guard let url = URL(string: urlString) else {
            DocsLogger.error("url is nil")
            return
        }
        Navigator.shared.push(url, from: topVC)
    }
    
    private func showApprovalList(viewModel: SecretLevelViewModel) {
        guard let approvalList = viewModel.approvalList else {
            DocsLogger.info("approval list is nil")
            return
        }
        guard let levelLabel = viewModel.selectedLevelLabel else {
            DocsLogger.error("leve label is nil")
            return
        }
        guard let topVC = topVC else {
            DocsLogger.error("topVC is nil", component: LogComponents.comment)
            return
        }
        let viewModel = SecretApprovalListViewModel(label: levelLabel, instances: approvalList.instances(with: levelLabel.id),
                                                    wikiToken: viewModel.wikiToken, token: viewModel.token,
                                                    type: viewModel.type, permStatistic: viewModel.permStatistic, viewFrom: .resubmitView)
        let vc = SecretLevelApprovalListViewController(viewModel: viewModel, needCloseBarItem: true)
        let navVC = LkNavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = topVC.isMyWindowRegularSizeInPad ? .formSheet :.fullScreen
        Navigator.shared.present(navVC, from: topVC)
    }
    
    
    private func showUpgradeAlert(viewModel: SecretLevelViewModel) {
        guard let topVC = topVC else {
            DocsLogger.error("topVC is nil", component: LogComponents.comment)
            return
        }
        let dialog = SecretApprovalDialog.secretLevelUpgradeDialog { [weak self] in
            guard let self = self else { return }
            self.upgradeSecret(viewModel: viewModel)
        }
        topVC.present(dialog, animated: true, completion: nil)
    }
    
    private func showSecretModifyOriginalViewController(viewModel: SecretLevelViewModel) {
        guard let topVC = topVC else {
            DocsLogger.error("topVC is nil", component: LogComponents.comment)
            return
        }
        guard let levelLabel = viewModel.selectedLevelLabel else {
            DocsLogger.error("leve label is nil")
            return
        }
        let viewModel: SecretModifyViewModel = SecretModifyViewModel(approvalType: viewModel.approvalType,
                                                                     originalLevel: viewModel.level,
                                                                     label: levelLabel,
                                                                     wikiToken: viewModel.wikiToken,
                                                                     token: viewModel.token,
                                                                     type: viewModel.type,
                                                                     approvalDef: viewModel.approvalDef,
                                                                     approvalList: viewModel.approvalList,
                                                                     permStatistic: viewModel.permStatistic)
        let isIPad = topVC.isMyWindowRegularSize()
        if isIPad {
            let viewController = IpadSecretModifyOriginalViewController(viewModel: viewModel)
            viewController.delegate = self
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .formSheet
            Navigator.shared.present(nav, from: topVC)
        } else {
            let viewController = SecretModifyOriginalViewController(viewModel: viewModel)
            viewController.delegate = self
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .overFullScreen
            nav.transitioningDelegate = viewController.panelTransitioningDelegate
            Navigator.shared.present(nav, from: topVC)
        }
    }
}
