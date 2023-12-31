//
//  DKSecretSettingVCModule.swift
//  SKDrive
//
// swiftlint:disable line_length

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import SKUIKit
import EENavigator
import LarkUIKit
import UniverseDesignColor
import UniverseDesignToast
import SKResource
import UIKit
import SKInfra

class DKSecretSettingVCModule: DKBaseSubModule {
    weak var secretViewController: UIViewController?
    var navigator: DKNavigatorProtocol
    weak var windowSizeDependency: WindowSizeProtocol?
    var dependency: DKShareVCModuleDependency
    init(hostModule: DKHostModuleType,
         windowSizeDependency: WindowSizeProtocol?,
         dependency: DKShareVCModuleDependency = DefaultShareVCModuleDependencyImpl(),
         navigator: DKNavigatorProtocol = Navigator.shared) {
        self.navigator = navigator
        self.windowSizeDependency = windowSizeDependency
        self.dependency = dependency
        super.init(hostModule: hostModule)
    }
    deinit {
        DocsLogger.driveInfo("DKSecretSettingVCModule -- deinit")
    }
    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        guard let host = hostModule else { return self }
        host.subModuleActionsCenter.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] action in
            guard let self = self else {
                return
            }
            switch action {
            case .showSecretVC:
                self.showSecretSettingVC(fileInfo: self.fileInfo, docsInfo: self.docsInfo, viewFrom: .moreMenu)
            case .clickNavSecretEvent:
                self.showSecretSettingVC(fileInfo: self.fileInfo, docsInfo: self.docsInfo, viewFrom: .upperIcon)
            case .clickSecretBanner:
                self.showSecretSettingVC(fileInfo: self.fileInfo, docsInfo: self.docsInfo, viewFrom: .banner)
            case let .updateSecretLabel(name):
                self.upgradeSecretComfirm(fileInfo: self.fileInfo, docsInfo: self.docsInfo, viewFrom: .banner, secLabelName: name)
            default: break
            }

        }).disposed(by: bag)
        return self
    }
    
    // 打开密级面板
    func showSecretSettingVC(fileInfo: DriveFileInfo,
                             docsInfo: DocsInfo,
                             viewFrom: PermissionStatistics.SecuritySettingViewFrom) {
        guard let hostVC = hostModule?.hostController else {
            spaceAssertionFailure("hostVC not found")
            return
        }
        guard let hostVCDependencyImpl = windowSizeDependency else { return }
        guard let level = docsInfo.secLabel else {
            DocsLogger.error("level is nil")
            return
        }
        hostVC.view.endEditing(true)

        let publicPermissionMeta = DocsContainer.shared.resolve(PermissionManager.self)?.getPublicPermissionMeta(token: docsInfo.objToken)
        let userPermissions = DocsContainer.shared.resolve(PermissionManager.self)?.getUserPermissions(for: docsInfo.objToken)
        let ccmCommonParameters = CcmCommonParameters(fileId: docsInfo.encryptedObjToken,
                                                      fileType: docsInfo.type.name,
                                                      appForm: (docsInfo.isInVideoConference == true) ? "vc" : "none",
                                                      subFileType: docsInfo.fileType,
                                                      module: "drive",
                                                      userPermRole: userPermissions?.permRoleValue,
                                                      userPermissionRawValue: userPermissions?.rawValue,
                                                      publicPermission: publicPermissionMeta?.rawValue)
        let permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)

        var wikiToken: String?
        var token = docsInfo.objToken
        if let wikiInfo = docsInfo.wikiInfo {
            wikiToken = wikiInfo.wikiToken
            token = wikiInfo.objToken
        }
        let type = docsInfo.type.rawValue
        let viewModel = SecretLevelViewModel(level: level, wikiToken: wikiToken, token: token, type: type, permStatistic: permStatistics, viewFrom: viewFrom)
        let isIPad = dependency.pad && hostVCDependencyImpl.isMyWindowRegularSize()
        if isIPad {
            let viewController = IpadSecretLevelViewController(viewModel: viewModel)
            viewController.delegate = self
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .formSheet
            navigator.present(vc: nav, from: hostVC, animated: true)
            self.secretViewController = viewController
        } else {
            let viewController = SecretLevelViewController(viewModel: viewModel)
            viewController.delegate = self
            viewController.supportOrientations = hostVC.supportedInterfaceOrientations
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .overFullScreen
            nav.transitioningDelegate = viewController.panelTransitioningDelegate
            navigator.present(vc: nav, from: hostVC, animated: true)
            self.secretViewController = viewController
        }
        
        switch viewFrom {
        case .upperIcon:
            permStatistics.reportNavigationBarPermissionSecurityButtonClick()
        case .moreMenu:
            permStatistics.reportMoreMenuPermissionSecurityButtonClick()
        default: break
        }
    }
}


extension DKSecretSettingVCModule: SecretLevelSelectDelegate, SecretModifyOriginalViewDelegate {
    private func showSecretModifyOriginalViewController(viewModel: SecretLevelViewModel) {
        guard let from = hostModule?.hostController else {
            spaceAssertionFailure("hostVC not found")
            return
        }
        guard let levelLabel = viewModel.selectedLevelLabel else {
            DocsLogger.error("leve label is nil")
            return
        }
        let viewModel: SecretModifyViewModel = SecretModifyViewModel(approvalType: viewModel.approvalType,
                                                                     originalLevel: viewModel.level,
                                                                     label: levelLabel, wikiToken: viewModel.wikiToken, token: viewModel.token,
                                                                     type: viewModel.type, approvalDef: viewModel.approvalDef, approvalList: viewModel.approvalList, permStatistic: viewModel.permStatistic)
        let isIPad = from.isMyWindowRegularSize()
        if isIPad {
            let viewController = IpadSecretModifyOriginalViewController(viewModel: viewModel)
            viewController.delegate = self
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .formSheet
            navigator.present(vc: nav, from: from, animated: true)
        } else {
            let viewController = SecretModifyOriginalViewController(viewModel: viewModel)
            viewController.delegate = self
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .overFullScreen
            nav.transitioningDelegate = viewController.panelTransitioningDelegate
            navigator.present(vc: nav, from: from, animated: true)
        }
    }
    func didClickConfirm(_ view: UIViewController, viewModel: SecretLevelViewModel, didUpdate: Bool, showOriginalView: Bool) {
        guard didUpdate else {
            DocsLogger.driveInfo("did update is false")
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
    func didClickCancel(_ view: UIViewController, viewModel: SecretLevelViewModel) {}
    func didSelectRow(_ view: UIViewController, viewModel: SecretLevelViewModel) {}
    func didUpdateLevel(_ view: UIViewController, viewModel: SecretModifyViewModel) {
        let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
        dataCenterAPI?.updateSecurity(objToken: viewModel.wikiToken ?? viewModel.token, newSecurityName: viewModel.label.name)
    }
    func didSubmitApproval(_ view: UIViewController, viewModel: SecretModifyViewModel) {
        guard let hostVC = hostModule?.hostController else {
            spaceAssertionFailure("hostVC not found")
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
        hostVC.present(dialog, animated: true, completion: nil)
    }
    func didClickCancel(_ view: UIViewController, viewModel: SecretModifyViewModel) {}
    func shouldApprovalAlert(_ view: UIViewController, viewModel: SecretLevelViewModel) {
        guard let hostVC = hostModule?.hostController else {
            spaceAssertionFailure("hostVC not found")
            return
        }
        guard let levelLabel = viewModel.selectedLevelLabel else {
            DocsLogger.driveInfo("select level label is nil")
            return
        }
        viewModel.reportCcmPermissionSecurityDemotionResubmitView()
        switch viewModel.approvalType {
        case .SelfRepeatedApproval:
            let dialog = SecretApprovalDialog.selfRepeatedApprovalDialog {
                viewModel.reportCcmPermissionSecurityDemotionResubmitView()
            } define: { [weak self] in
                guard let self = self else { return }
                self.showSecretModifyOriginalViewController(viewModel: viewModel)
                viewModel.reportCcmPermissionSecurityDemotionResubmitClick(click: "confirm")
            }
            hostVC.present(dialog, animated: true, completion: nil)
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
            hostVC.present(dialog, animated: true, completion: nil)
        default: break
        }
    }
    private func showApprovalCenter(viewModel: SecretModifyViewModel) {
        guard let hostVC = hostModule?.hostController, let from = UIViewController.docs.topMost(of: hostVC) else {
            spaceAssertionFailure("hostVC not found")
            return
        }
        guard let config = SettingConfig.approveRecordProcessUrlConfig else {
            DocsLogger.error("config is nil")
            return
        }
        guard let instanceId = viewModel.instanceCode else {
            DocsLogger.error("instanceId is nil")
            return
        }
        let urlString = config.url + instanceId
        guard let url = URL(string: urlString) else {
            DocsLogger.error("url is nil")
            return
        }
        Navigator.shared.push(url, from: from)
    }
    private func showApprovalList(viewModel: SecretLevelViewModel) {
        guard let hostVC = hostModule?.hostController, let from = UIViewController.docs.topMost(of: hostVC) else {
            spaceAssertionFailure("hostVC not found")
            return
        }
        guard let levelLabel = viewModel.selectedLevelLabel else {
            DocsLogger.error("leve label is nil")
            return
        }
        guard let approvalList = viewModel.approvalList else { return }
        let viewModel = SecretApprovalListViewModel(label: levelLabel, instances: approvalList.instances(with: levelLabel.id),
                                                    wikiToken: viewModel.wikiToken, token: viewModel.token,
                                                    type: viewModel.type, permStatistic: viewModel.permStatistic,
                                                    viewFrom: .resubmitView)
        let vc = SecretLevelApprovalListViewController(viewModel: viewModel, needCloseBarItem: true)
        let navVC = LkNavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = from.isMyWindowRegularSizeInPad ? .formSheet :.fullScreen
        navigator.present(vc: navVC, from: from, animated: true)
    }
    private func upgradeSecret(viewModel: SecretLevelViewModel) {
        guard let levelLabel = viewModel.selectedLevelLabel else {
            DocsLogger.error("leve label is nil")
            return
        }
        SecretLevel.updateSecLabel(token: viewModel.token, type: viewModel.type, id: levelLabel.id, reason: "")
            .subscribe { [self] in
                DocsLogger.driveInfo("update secret level success")
                let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
                dataCenterAPI?.updateSecurity(objToken: viewModel.wikiToken ?? viewModel.token, newSecurityName: levelLabel.name)
                showToast(text: BundleI18n.SKResource.LarkCCM_Docs_SecurityLevel_SetasDefault_Toast, type: .tips)
            } onError: { [self] error in
                DocsLogger.error("update secret level fail", error: error)
                showToast(text: BundleI18n.SKResource.CreationMobile_SecureLabel_Change_Failed, type: .failure)
            }
            .disposed(by: bag)
    }
    
    private func upgradeSecretComfirm(fileInfo: DriveFileInfo,
                                      docsInfo: DocsInfo,
                                      viewFrom: PermissionStatistics.SecuritySettingViewFrom,
                                      secLabelName: String) {
        guard let level = docsInfo.secLabel else {
            DocsLogger.error("level is nil")
            return
        }
        let bannerId: String
        if docsInfo.secLabel?.secLableTypeBannerType == .recommendMark {
            bannerId = docsInfo.secLabel?.recommendLabelId ?? "0"
        } else {
            bannerId = docsInfo.secLabel?.defaultLabelId ?? "0"
        }
        SecretLevel.updateSecLabel(token: docsInfo.token, type: docsInfo.inherentType.rawValue, id: bannerId, reason: "")
            .subscribe { [weak self] in
                DocsLogger.info("update secret level success")
                let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
                dataCenterAPI?.updateSecurity(objToken: docsInfo.token, newSecurityName: secLabelName)
                self?.showToast(text: BundleI18n.SKResource.LarkCCM_Docs_SecurityLevel_SetasDefault_Toast, type: .tips)
            } onError: { [weak self] error in
                DocsLogger.error("update secret level fail", error: error)
                self?.showToast(text: BundleI18n.SKResource.CreationMobile_SecureLabel_Change_Failed, type: .failure)
            }
            .disposed(by: bag)
    }

    private func showUpgradeAlert(viewModel: SecretLevelViewModel) {
        guard let hostVC = hostModule?.hostController else {
            spaceAssertionFailure("hostVC not found")
            return
        }
        let dialog = SecretApprovalDialog.secretLevelUpgradeDialog { [weak self] in
            guard let self = self else { return }
            self.upgradeSecret(viewModel: viewModel)
        }
        hostVC.present(dialog, animated: true, completion: nil)
    }
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        guard let hostVC = hostModule?.hostController else { return }
        guard let view = hostVC.view.window ?? hostVC.view else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type)
    }
}
