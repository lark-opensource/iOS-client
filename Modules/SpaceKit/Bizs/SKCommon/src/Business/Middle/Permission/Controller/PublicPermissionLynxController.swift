//
//  PublicPermissionLynxController.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/3/31.
// swiftlint:disable line_length

import SKFoundation
import SKResource
import SKUIKit
import BDXServiceCenter
import LarkUIKit
import RxSwift
import EENavigator
import UniverseDesignToast
import SwiftyJSON
import UniverseDesignColor
import SpaceInterface
import SKInfra

public final class PublicPermissionLynxController: LynxBaseViewController {

    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    
    // 仅做透传用，不做实际逻辑
    private let fileModel: PublicPermissionFileModel
    private var permStatistics: PermissionStatistics?
    private var updateSecretLevelCompletion: ((Bool) -> Void)?
    private let disposeBag = DisposeBag()
    weak var followAPIDelegate: BrowserVCFollowDelegate?

    public init(token: String,
                type: ShareDocsType,
                isSpaceV2: Bool,
                isWikiV2: Bool,
                needCloseButton: Bool,
                fileModel: PublicPermissionFileModel,
                permStatistics: PermissionStatistics?,
                dlpDialogUrl: String? = nil,
                followAPIDelegate: BrowserVCFollowDelegate? = nil) {
        self.fileModel = fileModel
        self.permStatistics = permStatistics
        self.followAPIDelegate = followAPIDelegate
        super.init(nibName: nil, bundle: nil)
        let config = SettingConfig.leaderPermConfig
        var leaderPermUrl: String? = nil
        //后续不会再增加类型，不会通过AppSetting下发的方式
        if DocsSDK.currentLanguage == .zh_CN {
            leaderPermUrl = config?.cnUrl
        } else if DocsSDK.currentLanguage == .en_US {
            leaderPermUrl = config?.enUrl
        } else if DocsSDK.currentLanguage == .ja_JP {
            leaderPermUrl = config?.jpUrl
        }
        initialProperties = [
            "token": token,
            "objType": type.rawValue,
            "isSpaceV2": isSpaceV2,
            "isWikiV2": isWikiV2,
            "closeInsteadOfBack": needCloseButton,
            "isUserToC": User.current.info?.isToNewC == true,
            "adminCanShareExternal": AdminPermissionManager.adminCanExternalShare(),
            "statisticParams": permStatistics?.commonParameters, // 埋点公参
            "dlpDialogUrl": dlpDialogUrl ?? "",
            "leaderPermUrl": leaderPermUrl ?? "",
            "tenantID": User.current.info?.tenantID ?? "",
            "ownerTenantID": fileModel.tenantID
        ]
        templateRelativePath = "pages/public-permission-panel/template.js"
        view.backgroundColor = UDColor.bgBase
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        lynxView?.triggerLayout()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }

    public override func registerBizHandlers(for lynxView: BDXLynxViewProtocol) {
        super.registerBizHandlers(for: lynxView)
        let eventHandlers: [BridgeHandler] = [
            UpdateSecretLevelBridgeHandler(hostController: self),
            ScopePickerBridgeHandler(hostController: self),
            PublicSubPermissionBridgeHandler(hostController: self),
            NotifyPublicPermissionUpdatedBridgeHandler()
        ]
        eventHandlers.forEach { (handler) in
            lynxView.registerHandler(handler.handler, forMethod: handler.methodName)
        }
    }
}

extension PublicPermissionLynxController: UpdateSecretLevelHandler {
    public func updateSecretLevel(token: String, type: ShareDocsType, meta: ShareBizMeta, completion: @escaping (Bool) -> Void) {
        guard let level = meta.secretLevel else {
            DocsLogger.error("unable to get secret level info from meta")
            completion(false)
            return
        }
        let viewModel = SecretLevelViewModel(level: level, wikiToken: fileModel.wikiToken, token: token, type: type.rawValue, permStatistic: permStatistics, viewFrom: .permSetting)
        updateSecretLevelCompletion = completion
        let isIPad = SKDisplay.pad && isMyWindowRegularSize()
        if isIPad {
            let viewController = IpadSecretLevelViewController(viewModel: viewModel)
            viewController.delegate = self
            viewController.followAPIDelegate = followAPIDelegate
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .formSheet
            Navigator.shared.present(nav, from: self)
        } else {
            let viewController = SecretLevelViewController(viewModel: viewModel)
            viewController.delegate = self
            viewController.followAPIDelegate = followAPIDelegate
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .overFullScreen
            nav.transitioningDelegate = viewController.panelTransitioningDelegate
            Navigator.shared.present(nav, from: self)
        }
        permStatistics?.reportPermissionSetPermissionSecurityButtonClick()
    }
}

extension PublicPermissionLynxController: SecretLevelSelectDelegate {
    private func showSecretModifyOriginalViewController(viewModel: SecretLevelViewModel) {
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
                                                                     permStatistic: viewModel.permStatistic,
                                                                     followAPIDelegate: followAPIDelegate)
        let isIPad = SKDisplay.pad && isMyWindowRegularSize()
        if isIPad {
            let viewController = IpadSecretModifyOriginalViewController(viewModel: viewModel)
            viewController.delegate = self
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .formSheet
            Navigator.shared.present(nav, from: self)
        } else {
            let viewController = SecretModifyOriginalViewController(viewModel: viewModel)
            viewController.delegate = self
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .overFullScreen
            nav.transitioningDelegate = viewController.panelTransitioningDelegate
            Navigator.shared.present(nav, from: self)
        }
    }

    public func didClickConfirm(_ view: UIViewController, viewModel: SecretLevelViewModel,
                         didUpdate: Bool, showOriginalView: Bool) {
        guard didUpdate else {
            updateSecretLevelCompletion?(false)
            updateSecretLevelCompletion = nil
            DocsLogger.error("did update is not true")
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
        updateSecretLevelCompletion?(false)
        updateSecretLevelCompletion = nil
    }

    public func didSelectRow(_ view: UIViewController, viewModel: SecretLevelViewModel) {}
}

extension PublicPermissionLynxController: SecretModifyOriginalViewDelegate {
    public func didUpdateLevel(_ view: UIViewController, viewModel: SecretModifyViewModel) {
        //重新拉取密级
        let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
        dataCenterAPI?.updateSecurity(objToken: viewModel.wikiToken ?? viewModel.token, newSecurityName: viewModel.label.name)
        NotificationCenter.default.post(name: Notification.Name.Docs.publicPermissonUpdate, object: nil)
        updateSecretLevelCompletion?(true)
        updateSecretLevelCompletion = nil
    }
    public func didSubmitApproval(_ view: UIViewController, viewModel: SecretModifyViewModel) {        viewModel.reportCcmPermissionSecurityDemotionResultView(success: true)
        let dialog = SecretApprovalDialog.sendApprovaSuccessDialog { [weak self] in
            guard let self = self else { return }
            self.showApprovalCenter(viewModel: viewModel)
            viewModel.reportCcmPermissionSecurityDemotionResultClick(click: "view_checking")
        } define: {
            viewModel.reportCcmPermissionSecurityDemotionResultClick(click: "known")
        }
        present(dialog, animated: true, completion: nil)
    }
    public func didClickCancel(_ view: UIViewController, viewModel: SecretModifyViewModel) {
        updateSecretLevelCompletion?(false)
        updateSecretLevelCompletion = nil
    }
    private func showApprovalCenter(viewModel: SecretModifyViewModel) {
        guard let from = UIViewController.docs.topMost(of: self) else {
            DocsLogger.error("from is nil")
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
        if let followAPIDelegate = viewModel.followAPIDelegate {
            followAPIDelegate.follow(onOperate: .vcOperation(value: .setFloatingWindow(getFromVCHandler: { from in
                guard let from else { return }
                Navigator.shared.push(url, from: from)
            })))
        } else {
            Navigator.shared.push(url, from: from)
        }
    }
    public func shouldApprovalAlert(_ view: UIViewController, viewModel: SecretLevelViewModel) {
        guard let levelLabel = viewModel.selectedLevelLabel else {
            DocsLogger.info("select level label is nil")
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
            present(dialog, animated: true, completion: nil)
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
            present(dialog, animated: true, completion: nil)
        default: break
        }
    }

    private func showApprovalList(viewModel: SecretLevelViewModel) {
        guard let from = UIViewController.docs.topMost(of: self) else {
            DocsLogger.error("from is nil")
            return
        }
        guard let approvalList = viewModel.approvalList else {
            DocsLogger.error("approval list is nil")
            return
        }
        guard let levelLabel = viewModel.selectedLevelLabel else {
            DocsLogger.error("leve label is nil")
            return
        }
        let viewModel = SecretApprovalListViewModel(label: levelLabel, instances: approvalList.instances(with: levelLabel.id),
                                                    wikiToken: viewModel.wikiToken, token: viewModel.token,
                                                    type: viewModel.type, permStatistic: viewModel.permStatistic, viewFrom: .resubmitView)
        let vc = SecretLevelApprovalListViewController(viewModel: viewModel, needCloseBarItem: true, followAPIDelegate: followAPIDelegate)
        let navVC = LkNavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = from.isMyWindowRegularSizeInPad ? .formSheet :.fullScreen
        Navigator.shared.present(navVC, from: from)
    }

    private func upgradeSecret(viewModel: SecretLevelViewModel) {
        guard let levelLabel = viewModel.selectedLevelLabel else {
            updateSecretLevelCompletion?(false)
            updateSecretLevelCompletion = nil
            DocsLogger.error("leve label is nil")
            return
        }

        SecretLevel.updateSecLabel(token: viewModel.token, type: viewModel.type, id: levelLabel.id, reason: "")
            .subscribe { [weak self] in
                guard let self = self else { return }
                DocsLogger.info("update secret level success")
                UDToast.showSuccess(with: BundleI18n.SKResource.LarkCCM_Docs_SecurityLevel_SetasDefault_Toast, on: self.view.window ?? self.view)
                NotificationCenter.default.post(name: Notification.Name.Docs.publicPermissonUpdate, object: nil)
                let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
                dataCenterAPI?.updateSecurity(objToken: viewModel.wikiToken ?? viewModel.token, newSecurityName: levelLabel.name)
                self.updateSecretLevelCompletion?(true)
                self.updateSecretLevelCompletion = nil
            } onError: { [weak self] error in
                guard let self = self else { return }
                DocsLogger.error("update secret level fail", error: error)
                UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_SecureLabel_Change_Failed, on: self.view.window ?? self.view)
                self.updateSecretLevelCompletion?(false)
                self.updateSecretLevelCompletion = nil
            }
            .disposed(by: disposeBag)

    }

    private func showUpgradeAlert(viewModel: SecretLevelViewModel) {
        let dialog = SecretApprovalDialog.secretLevelUpgradeDialog { [weak self] in
            guard let self = self else { return }
            self.upgradeSecret(viewModel: viewModel)
        }
        present(dialog, animated: true, completion: nil)
    }
}

extension PublicPermissionLynxController: ScopePickerBridgeDelegate {
    func showScopePicker(needLockTips: Bool, defaultScopeType: PermissionScopeType, completion: @escaping (PermissionScopeType?) -> Void) {
        let singlePageItem = ScopeSelectItem(title: BundleI18n.SKResource.CreationMobile_Wiki_Page_Current_tab,
                                             subTitle: nil,
                                             selected: defaultScopeType == .singlePage,
                                             scopeType: .singlePage)
        var item2SubTitle: String?
        if needLockTips {
            item2SubTitle = BundleI18n.SKResource.CreationMobile_Wiki_Perm_ExternalShare_Current_notice
        }
        let containerItem = ScopeSelectItem(title: BundleI18n.SKResource.CreationMobile_Wiki_Page_CurrentNSub_tab,
                                            subTitle: item2SubTitle,
                                            selected: defaultScopeType == .container,
                                            scopeType: .container)
        let models: [ScopeSelectItem] = [singlePageItem, containerItem]

        let confirmCompletion: (UIViewController, PermissionScopeType) -> Void = { _, type in
            completion(type)
        }
        let cancelCompletion: (UIViewController, PermissionScopeType) -> Void = { _, _ in
            completion(nil)
        }
        if SKDisplay.pad, isMyWindowRegularSize() {
            let viewController = IpadScopeSelectViewController(items: models)
            viewController.confirmCompletion = confirmCompletion
            viewController.cancelCompletion = cancelCompletion
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .formSheet
            Navigator.shared.present(nav, from: self)
        } else {
            let viewController = ScopeSelectViewController(items: models)
            viewController.confirmCompletion = confirmCompletion
            viewController.cancelCompletion = cancelCompletion
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .overFullScreen
            nav.transitioningDelegate = viewController.panelTransitioningDelegate
            Navigator.shared.present(nav, from: self)
        }
        permStatistics?.reportPermissionScopeChangeView()
        permStatistics?.reportPermissionSetClick(click: .isShareOutside, target: .permissionScopeChangeView)
    }
}

extension PublicPermissionLynxController: PublicSubPermissionUpdateHandler {
    func updatePublicSubPermission(publicPermissionMeta: PublicPermissionMeta, subPermission: PublicSubPermissionType) {
        let cellType: PublicPermissionCellModelType
        let sectionTitle: String
        switch subPermission {
        case .manageCollaboratorEntity:
            cellType = .manageCollaborator
            sectionTitle = BundleI18n.SKResource.CreationMobile_ECM_Permission_AddCollaborator_title
        case .securityEntity:
            cellType = .security
            switch fileModel.type {
            case .folder:
                sectionTitle = BundleI18n.SKResource.CreationMobile_Docs_Folder_WhoCan
            case .minutes:
                sectionTitle = BundleI18n.SKResource.CreationMobile_Minutes_permissions_settings_question
            default:
                sectionTitle = BundleI18n.SKResource.LarkCCM_Perms_Settings_WhoCanCopyPrintDwld_Descrip
            }
        case .commentEntity:
            cellType = .comment
            sectionTitle = fileModel.isFolder ? BundleI18n.SKResource.CreationMobile_Docs_Folder_WhoCanComment
            : BundleI18n.SKResource.CreationMobile_Minutes_permissions_settings_comment
        case .showCollaboratorInfoEntity:
            cellType = .showCollaboratorInfo
            sectionTitle = BundleI18n.SKResource.LarkCCM_Perm_WhoCanViewProfilePicture_Tooltip
        case .copyEntity:
            cellType = .copy
            sectionTitle = BundleI18n.SKResource.LarkCCM_Perms_RecordCopy_Settings_WhoCanCopy
        }

        let publicPermissionUpdated: (PublicPermissionMeta) -> Void = { [weak self] meta in
            guard let self = self else { return }
            let metaJSON = meta.rawValue.toDictionary() ?? [:]
            let event = GlobalEventEmiter.Event(
                name: "ccm-public-permission-change",
                params: metaJSON
            )
            self.globalEventEmiter.send(event: event, needCache: true)
        }
        let vc = PublicPermissionSettingViewController(fileModel: fileModel,
                                                       publicPermissionMeta: publicPermissionMeta,
                                                       publicPermissionSettingType: cellType,
                                                       publicPermissonUpdated: publicPermissionUpdated,
                                                       permStatistics: permStatistics,
                                                       navTitle: sectionTitle)
        vc.supportOrientations = self.supportedInterfaceOrientations
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
