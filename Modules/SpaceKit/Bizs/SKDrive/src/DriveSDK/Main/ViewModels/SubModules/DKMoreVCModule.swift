//
//  DKMoreVCModule.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/19.
//

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import RxRelay
import RxCocoa
import SKUIKit
import EENavigator
import LarkUIKit
import LarkSuspendable
import UniverseDesignToast
import SKResource
import SpaceInterface
import SKInfra
import LarkDocsIcon

public protocol DriveMoreDataProviderType: MoreDataProvider {
    var shareClick: Driver<()> { get }
    var back: Driver<()> { get }
    var showReadingPanel: Driver<()> { get }
    var showPublicPermissionPanel: Driver<()> { get }
    var showApplyEditPermission: Signal<InsideMoreDataProvider.ApplyEditScene> { get }
    var historyRecordAction: Driver<()> { get }
    var showRenamePanel: Driver<()> { get }
    var importAsDocsAction: Driver<()> { get }
    var openInOtherAppAction: Driver<()> { get }
    var didSuspendAction: Driver<Bool> { get }
    var showSaveToLocal: Driver<()> { get }
    var showOperationHistoryPanel: Signal<()> { get }
    var showSensitivtyLabelSetting: Driver<SecretLevel?> { get }
    var showForcibleWarning: Signal<()> { get }
    var redirectToWiki: Driver<String> { get }
}

class DKMoreVCModule: DKBaseSubModule {
    private var provider: DriveMoreDataProviderType?
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
        DocsLogger.driveInfo("DKMoreVCModule -- deinit")
    }

    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        guard let host = hostModule else { return self }
        host.subModuleActionsCenter.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] action in
            guard let self = self else {
                return
            }
            if !UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                guard self.permissionInfo.userPermissions != nil else {
                    DocsLogger.driveInfo("no user permissions")
                    return
                }
            }
            if case .showMoreVC = action {
                self.showMoreVC(self.docsInfo, self.permissionInfo.userPermissions)
            }
        }).disposed(by: bag)
        return self
    }
    
    func showMoreVC(_ docsInfo: DocsInfo,
                    _ userPermissions: UserPermissionAbility?) {
        guard let host = hostModule,
              let hostVC = host.hostController else { return }
        guard let hostVCDependencyImpl = windowSizeDependency else { return }
        hostVC.view.endEditing(true)
        // 更新是否在 vc follow 状态
        docsInfo.isInVideoConference = host.commonContext.isInVCFollow
        var moreViewController: UIViewController!
        DocsLogger.driveInfo("show new MoreViewController \(docsInfo.type)")
        let provider = self.initializeMoreDataProviderWith(docsInfo: docsInfo,
                                                           fileInfo: fileInfo,
                                                           hostVC: hostVC,
                                                           userPermissions: userPermissions,
                                                           permissionService: host.permissionService)
        let moreViewModel = MoreViewModel(dataProvider: provider, docsInfo: docsInfo)
        let moreVC = MoreViewControllerV2(viewModel: moreViewModel)
        moreVC.needAddWatermark = docsInfo.shouldShowWatermark
        moreVC.supportOrientations = hostVC.supportedInterfaceOrientations
        moreViewController = moreVC
        self.provider = provider

        let completion: (() -> Void) = { [weak self] in
            guard let self = self else { return }
            if self.importToOnlneFileEnabled() && DriveConvertFileConfig.needShowRedGuide() {
                // 为了让More上面的红点消掉
                DriveConvertFileConfig.recordHadClickRedGuide()
                // 通知navigationBar重置rightItems
                self.hostModule?.subModuleActionsCenter.accept(.refreshNaviBarItemsDots)
            }
        }

        if dependency.pad && hostVCDependencyImpl.isMyWindowRegularSize() {
            hostVC.showPopover(to: moreViewController, at: -1, completion: completion)
        } else {
            // VC 场景下，需要让 moreVC 展示在最上层，遮挡住其他控件，故使用 overFullScreen
            if host.commonContext.isInVCFollow {
                moreViewController.modalPresentationStyle = .overFullScreen
            }
            navigator.present(vc: moreViewController, from: hostVC, animated: true, completion: completion)
        }
        // 点击更多按钮事件
        DriveStatistic.reportClickEvent(DocsTracker.EventType.navigationBarClick,
                                        clickEventType: DriveStatistic.DriveTopBarClickEventType.more,
                                        fileId: fileInfo.fileToken,
                                        fileType: fileInfo.fileType)
        // 云空间文件，展示更多面板事件
        DriveStatistic.reportEvent(DocsTracker.EventType.spaceDocsMoreMenuView,
                                   fileId: fileInfo.fileToken,
                                   fileType: fileInfo.fileType.rawValue)
    }
    
    func importToOnlneFileEnabled() -> Bool {
        // 类型是否支持
        let type = DriveFileType(fileExtension: fileInfo.type)
        let typeEnabled = type.canImportAsDocs || type.canImportAsSheet || type.canImportAsMindnote
        // 是否开启fg
        let fgEnabled = DriveConvertFileConfig.isFeatureGatingEnabled()
        // 是否可以导出
        let canExport: Bool
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            // 这里只有无用户权限才返回 false, more 面板内另外有 enable 的判断
            // 考虑补一个豁免 case 来实现
            if let response = hostModule?.permissionService.validate(operation: .importToOnlineDocument) {
                switch response.result {
                case .allow:
                    canExport = true
                case let .forbidden(denyType, _):
                    if case .blockByUserPermission = denyType {
                        canExport = false
                    } else {
                        canExport = true
                    }
                }
            } else {
                canExport = false
            }
        } else {
            canExport = permissionInfo.canExport
        }

        return fgEnabled && canExport && typeEnabled
    }
}

extension DKMoreVCModule {
    func initializeMoreDataProviderWith(docsInfo: DocsInfo,
                                        fileInfo: DriveFileInfo,
                                        hostVC: UIViewController,
                                        userPermissions: UserPermissionAbility?,
                                        permissionService: UserPermissionService) -> DriveMoreDataProviderType {
        let isFromWiki = (hostModule?.commonContext.previewFrom == .wiki)
        let context = DriveMoreDataProviderContext(docsInfo: docsInfo,
                                                   feedId: hostModule?.commonContext.feedId,
                                                   fileType: fileInfo.type,
                                                   fileSize: Int64(fileInfo.size),
                                                   isFromWiki: isFromWiki,
                                                   hostViewController: hostVC,
                                                   permissionSerivce: permissionService,
                                                   userPermissions: userPermissions,
                                                   publicPermissionMeta: nil,
                                                   outsideControlItems: obtainOutsideControlItems(),
                                                   followAPIDelegate: hostModule?.commonContext.followAPIDelegate)
        let provider = DocsContainer.shared.resolve(SKDriveDependency.self)!
            .createMoreDataProvider(context: context)
        bindActionsWith(provider: provider)
        return provider
    }

    func bindActionsWith(provider: DriveMoreDataProviderType) {
        provider.shareClick.drive(onNext: { [weak self] in
            guard let self = self else { return }
            self.hostModule?.subModuleActionsCenter.accept(.showShareVC)
        }).disposed(by: bag)

        provider.back.drive(onNext: { [weak self] () in
            guard let self = self, let hostVC = self.hostModule?.hostController else { return }
            hostVC.back(canEmpty: true)
        }).disposed(by: bag)

        provider.showReadingPanel.drive(onNext: { [weak self] () in
            guard let self = self, let hostVC = self.hostModule?.hostController else { return }
            self.hostModule?.subModuleActionsCenter.accept(.openReadingData)

        }).disposed(by: bag)

        provider.showPublicPermissionPanel.drive(onNext: { [weak self] () in
            guard let self = self else { return }
            self.hostModule?.subModuleActionsCenter.accept(.publicPermissionSetting)
        }).disposed(by: bag)

        provider.showApplyEditPermission.emit(onNext: { [weak self] scene in
            guard let self = self else { return }
            self.hostModule?.subModuleActionsCenter.accept(.applyEditPermission(scene: scene))
        }).disposed(by: bag)

        provider.historyRecordAction.drive(onNext: { [weak self] () in
            guard let self = self else { return }
            self.hostModule?.subModuleActionsCenter.accept(.openHistory)
        }).disposed(by: bag)

        provider.showRenamePanel.drive(onNext: { [weak self] () in
            guard let self = self else { return }
            self.hostModule?.subModuleActionsCenter.accept(.rename)
        }).disposed(by: bag)

        provider.importAsDocsAction.drive(onNext: { [weak self] () in
            guard let self = self else { return }
            self.pushConvertFileVC(actionSource: .attachmentMore, previewFrom: .docsList)
        }).disposed(by: bag)

        provider.openInOtherAppAction.drive(onNext: { [weak self] () in
            guard let self = self else { return }
            self.hostModule?.subModuleActionsCenter.accept(.spaceOpenWithOtherApp)
        }).disposed(by: bag)

        provider.didSuspendAction.drive(onNext: { [weak self] (addToSuspend) in
            guard let self = self else { return }
            self.handleSuspendActionWith(addToSuspend: addToSuspend)
        }).disposed(by: bag)
        
        provider.showSaveToLocal.drive(onNext: { [weak self] () in
            guard let self = self else { return }
            self.saveFileToLocal(actionSource: .fileDetail)
        }).disposed(by: bag)

        provider.showOperationHistoryPanel.emit(onNext: { [weak self] in
            guard let self = self else { return }
            self.showOperationHistoryPanel()
        }).disposed(by: bag)
        
        provider.showSensitivtyLabelSetting.drive(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.hostModule?.subModuleActionsCenter.accept(.showSecretVC)
        }).disposed(by: bag)
        
        provider.showForcibleWarning.emit(onNext: { [weak self] in
            guard let self = self else { return }
            self.showForcibleWarning()
        }).disposed(by: bag)

        provider.redirectToWiki.drive(onNext: { [weak self] token in
            guard let self = self else { return }
            self.hostModule?.subModuleActionsCenter.accept(.redirectToWiki(token: token))
        }).disposed(by: bag)
    }

    // Drive控制置灰Items
    func obtainOutsideControlItems() -> MoreDataOutsideControlItems? {
        var items = MoreDataOutsideControlItems()
        var hiddenItems: [MoreItemType] = [MoreItemType]()
        if !importToOnlneFileEnabled() {
            hiddenItems.append(.importAsDocs(fileInfo.type))
        }
        if hiddenItems.count > 0 {
            items[State.hidden] = hiddenItems
        }
        if items.count > 0 {
            return items
        }
        return nil
    }
    
    // 浮窗操作
    func handleSuspendActionWith(addToSuspend: Bool) {
        var hostVC: UIViewController? = hostModule?.hostController
        if self.docsInfo.isFromWiki {
            hostVC = hostVC?.parent
        }
        guard let hostVC = hostVC as? ViewControllerSuspendable else { return }
        if addToSuspend {
            SuspendManager.shared.addSuspend(viewController: hostVC, shouldClose: true)
        } else {
            SuspendManager.shared.removeSuspend(byId: hostVC.suspendID)
        }
    }
    
    // 转码
    func pushConvertFileVC(actionSource: DriveStatisticActionSource, previewFrom: DrivePreviewFrom) {
        guard let hostVC = hostModule?.hostController else { return }
        let performanceLogger = DrivePerformanceRecorder(fileToken: fileInfo.fileToken,
                                                         fileType: fileInfo.fileType.rawValue,
                                                         sourceType: .preview,
                                                         additionalStatisticParameters: nil)
        let viewModel = DriveConvertFileViewModel(fileInfo: fileInfo, performanceLogger: performanceLogger)
        let vc = DriveConvertFileViewController(viewModel: viewModel,
                                                loadingView: DocsContainer.shared.resolve(DocsLoadingViewProtocol.self),
                                                actionSource: actionSource,
                                                previewFrom: previewFrom)
        navigator.push(vc: vc, from: hostVC, animated: true)
    }
    
    // 保存到本地
    func saveFileToLocal(actionSource: DriveStatisticActionSource) {
        guard let hostVC = hostModule?.hostController else {
            spaceAssertionFailure("hostVC not found")
            return
        }
        DriveStatistic.reportClickEvent(DocsTracker.EventType.spaceDocsMoreMenuClick,
                                        clickEventType: DriveStatistic.DriveFileMenuClickEvent.saveToLocal,
                                        fileId: fileInfo.fileID,
                                        fileType: fileInfo.fileType)
        DriveRouter.saveToLocal(fileInfo: fileInfo, from: hostVC, appealAlertFrom: .driveDetailMoreDownload)
    }

    func showOperationHistoryPanel() {
        guard let hostVC = hostModule?.hostController else {
            spaceAssertionFailure()
            return
        }
        // TODO: 考虑 wiki
        let token = fileInfo.fileID
        let type = DocsType.file
        DocumentActivityAPI.open(objToken: token, objType: type, from: hostVC).disposed(by: bag)
    }
    
    func showForcibleWarning() {
        guard let hostVC = hostModule?.hostController, let secLabel = docsInfo.secLabel else { return }
        UDToast.showWarning(with: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_Requird_Toast,
                            operationText: BundleI18n.SKResource.LarkCCM_Workspace_Security_Button_Set,
                            on: hostVC.view.window ?? hostVC.view) { [weak self] _ in
            self?.hostModule?.hostController?.dismiss(animated: true) {
                self?.hostModule?.subModuleActionsCenter.accept(.showSecretVC)
            }
        }
    }
}
