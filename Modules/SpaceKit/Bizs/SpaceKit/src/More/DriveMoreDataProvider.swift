//
//  DriveMoreDataProvider.swift
//  SpaceKit
//
//  Created by lizechuang on 2021/3/4.
//
// swiftlint:disable file_length type_body_length

import SKFoundation
import SKCommon
import SKSpace
import SKDrive
import SKUIKit
import RxSwift
import RxRelay
import RxCocoa
import EENavigator
import SKResource
import LarkSuspendable
import UniverseDesignToast
import SpaceInterface
import SKBrowser
import LarkTab
import LarkDocsIcon
import LarkContainer
import LarkSplitViewController
import SKWorkspace

// MARK: - Setting
extension DriveMoreDataProvider {
    private var file: MoreItemsBuilder {
        MoreItemsBuilder {
            MoreSection(type: .horizontal) {
                var defaultItems = feedShortcut - share - suspend - spaceMoveTo - pin - star - offline
                if quickLaunchService.isQuickLauncherEnabled {
                    if hostViewController?.isTemporaryChild == true {
                        defaultItems = feedShortcut - share - quickLaunch - suspend - spaceMoveTo - pin - star - offline
                    } else {
                        defaultItems = feedShortcut - share - openInNewTab - quickLaunch - suspend - spaceMoveTo - pin - star - offline
                    }
                }
                if docsInfo.isSingleContainerNode {
                    defaultItems = defaultItems - addShortCut
                } else {
                    defaultItems = defaultItems - addTo
                }
                return defaultItems
            }
            MoreSection(type: .vertical, outsideControlItems: self.outsideControlItems) {
                openInBrowser
                readingData
                sensitivtyLabel
                publicPermissionSetting
                operationHistory
                rename
                applyEditPermission
                saveToLocal
                importAsDocs
                openWithOtherApp
                historyRecord
                copyFile
                retention
                reportOutdate
                docFreshness
                customerService
                report
                reportV2
            }
            MoreSection(type: .vertical) {
                delete
            }
        }
    }

    private var wikiFile: MoreItemsBuilder {
        let hiddenWikiDelete = docsInfo.wikiInfo?.wikiNodeState.originIsExternal ?? false
        let preferWikiDeleteInSeparateSection = !hiddenWikiDelete
        return MoreItemsBuilder {
            MoreSection(type: .horizontal) {
                var defaultItems = feedShortcut - share - suspend - wikiMoveTo - pin - star - offline - wikiShortcut
                if quickLaunchService.isQuickLauncherEnabled {
                    if hostViewController?.isTemporaryChild == true {
                        defaultItems = feedShortcut - share - quickLaunch - suspend - wikiMoveTo - pin - star - offline - wikiShortcut
                    } else {
                        defaultItems = feedShortcut - share - openInNewTab - quickLaunch - suspend - wikiMoveTo - pin - star - offline - wikiShortcut
                    }
                }
                return defaultItems
            }
            MoreSection(type: .vertical, outsideControlItems: self.outsideControlItems) {
                openInBrowser
                readingData
                sensitivtyLabel
                publicPermissionSetting
                operationHistory
                rename
                applyEditPermission
                saveToLocal
                openWithOtherApp
                historyRecord
                copyWikiFile
                reportOutdate
                docFreshness
                customerService
                report
                reportV2
            }
            MoreSection(type: .vertical) {
                if preferWikiDeleteInSeparateSection {
                    wikiDelete
                }
                delete
            }
        }
    }

    // 按正常流程代码走到这里应该是不对的，除非业务发生改变
    private var other: MoreItemsBuilder {
        MoreItemsBuilder {
            MoreSection(type: .vertical) {
                customerService
            }
        }
    }
}

class DriveMoreDataProvider: InsideMoreDataProvider, DriveMoreDataProviderType {
    // output
    lazy var shareClick: Driver<()> = {
        _shareClick.asDriver(onErrorJustReturn: ())
    }()
    lazy var back: Driver<()> = {
        _back.asDriver(onErrorJustReturn: ())
    }()
    lazy var showReadingPanel: Driver<()> = {
        _showReadingPanel.asDriver(onErrorJustReturn: ())
    }()
    lazy var showPublicPermissionPanel: Driver<()> = {
        _showPublicPermissionPanel.asDriver(onErrorJustReturn: ())
    }()
    lazy var showApplyEditPermission: Signal<ApplyEditScene> = {
        _showApplyEditPermission.asSignal()
    }()
    lazy var historyRecordAction: Driver<()> = {
        _historyRecordAction.asDriver(onErrorJustReturn: ())
    }()
    lazy var showRenamePanel: Driver<()> = {
        _showRenamePanel.asDriver(onErrorJustReturn: ())
    }()
    lazy var importAsDocsAction: Driver<()> = {
        _importAsDocsAction.asDriver(onErrorJustReturn: ())
    }()
    lazy var openInOtherAppAction: Driver<()> = {
        _openInOtherAppAction.asDriver(onErrorJustReturn: ())
    }()
    lazy var didSuspendAction: Driver<Bool> = {
        _suspendAction.asDriver(onErrorJustReturn: false)
    }()
    lazy var showSaveToLocal: Driver<()> = {
        _showSaveToLocal.asDriver(onErrorJustReturn: ())
    }()
    lazy var showOperationHistoryPanel: Signal<()> = {
        _showOperationHistoryPanel.asSignal()
    }()
    lazy var showSensitivtyLabelSetting: Driver<SecretLevel?> = {
        _showSensitivtyLabelSetting.asDriver(onErrorJustReturn: nil)
    }()
    lazy var showForcibleWarning: Signal<()> = {
        _showForcibleWarning.asSignal()
    }()
    lazy var redirectToWiki: Driver<String> = {
        _redirectToWiki.asDriver(onErrorJustReturn: "")
    }()

    // input
    private let networkFlowHelper = NetworkFlowHelper()
    private let _shareClick = PublishSubject<()>()
    private let _back = PublishSubject<()>()
    private let _showReadingPanel = PublishSubject<()>()
    private let _showPublicPermissionPanel = PublishSubject<()>()
    private let _showApplyEditPermission = PublishRelay<ApplyEditScene>()
    private let _historyRecordAction = PublishSubject<()>()
    private let _showRenamePanel = PublishSubject<()>()
    private let _importAsDocsAction = PublishSubject<()>()
    private let _openInOtherAppAction = PublishSubject<()>()
    private let _suspendAction = PublishSubject<Bool>()
    private let _showSaveToLocal = PublishSubject<()>()
    private let _showOperationHistoryPanel = PublishRelay<Void>()
    private let _showSensitivtyLabelSetting = PublishSubject<SecretLevel?>()
    private let _showForcibleWarning = PublishRelay<Void>()
    private let _redirectToWiki = PublishSubject<String>()

    var feedId: String?
    var fileType: String?
    var isFromWiki: Bool

    private let wikiActionHandler: WikiMoreActionHandler

    override var builder: MoreItemsBuilder {
        if isFromWiki {
            return wikiFile
        } else {
            return file
        }
    }

    init(docsInfo: DocsInfo,
         feedId: String?,
         fileType: String?,
         fileSize: Int64,
         isFromWiki: Bool = false,
         hostViewController: UIViewController,
         userPermissions: UserPermissionAbility? = nil,
         permissionService: UserPermissionService?,
         publicPermissionMeta: PublicPermissionMeta? = nil,
         outsideControlItems: MoreDataOutsideControlItems? = nil,
         followAPIDelegate: SpaceFollowAPIDelegate?) {
        self.isFromWiki = isFromWiki
        let proxy = hostViewController as? WikiContextProxy
        let synergyUUID = proxy?.wikiContextProvider?.synergyUUID
        self.wikiActionHandler = WikiMoreActionHandler(docsInfo: docsInfo, hostViewController: hostViewController, synergyUUID: synergyUUID)
        super.init(docsInfo: docsInfo,
                   fileEntry: docsInfo.fileEntry,
                   fileSize: fileSize,
                   hostViewController: hostViewController,
                   userPermissions: userPermissions,
                   permissionService: permissionService,
                   publicPermissionMeta: publicPermissionMeta,
                   outsideControlItems: outsideControlItems,
                   followAPIDelegate: followAPIDelegate,
                   docComponentHostDelegate: nil,
                   trackerParams: DocsParametersUtil.createCommonParams(by: docsInfo))
        self.feedId = feedId
        self.fileType = fileType
    }

    // MARK: - Items
    override var feedShortcut: MoreItem? {
        if !DocsSDK.isInLarkDocsApp, self.feedId != nil {
            let isShortCut = feedShortcutStatus()
            return MoreItem(type: isShortCut ? .unFeedShortcut : .feedShortcut) { [weak self] (_, _) in
                guard let self = self else { return }
                let status = !isShortCut
                if let feedId = self.feedId {
                    let setService = FeedShortcutService(feedId, .set)
                        .setMark(as: !isShortCut).setSuccessBlock({ (_) in
                            self.reportForFeedShortcut(status)
                            let tips = status ? BundleI18n.SKResource.Doc_More_AddQuickSwitcherSuccess
                                : BundleI18n.SKResource.Doc_More_RemoveQuickSwitcherSuccess
                            self.showSuccess(with: tips)
                        }).setFailureBlock { (error) in
                            DocsLogger.info("==SKFeedShortcut== Mark Shortcut failed. Error: \(error)")
                            self.reportForFeedShortcut(status)
                            let tips = status ? BundleI18n.SKResource.Doc_More_AddQuickSwitcherFail : BundleI18n.SKResource.Doc_More_RemoveQuickSwitcherFail
                            self.showFailure(with: tips)
                        }
                    HostAppBridge.shared.call(setService)
                }
            }

        }
        return nil
    }

    override var share: MoreItem? {
        MoreItem(type: .share) { () -> Bool in
            true
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(.share)
                return
            }
            self._shareClick.onNext(())
        }
    }
    
    override var openInNewTab: MoreItem? {
        guard DriveFileType(fileExtension: docsInfo.fileType ?? "").isSupportMultiPics, !self.isFromWiki else {
            return super.openInNewTab
        }
        return MoreItem(type: .openInNewTab) { () -> Bool in
            showNewTab
        } prepareEnable: { () -> Bool in
            return true
        } handler: { [weak self] (_, _) in
            guard let self = self else { return }
            let urlString = self.docsInfo.urlForSuspendable()
            if let url = URL(string: urlString),
               let containable = DriveVCFactory.shared.makeDrivePreview(url: url, context: nil) as? TabContainable {
                self.temporaryTabService.showTab(containable)
                (self.hostViewController as? BaseViewController)?.back(canEmpty: true)
            } else {
                DocsLogger.error("pic controller create failure when open in new tab")
            }
            // 点击 在标签页中打开 如果此时把 VC 左拉到全屏，切换回云文档Tab会出现类型白屏的情况（云文档Tab没有展示出来）
            if UserScopeNoChangeFG.TYP.openBlankScreen && self.hostViewController?.isMyWindowRegularSizeInPad == true {
                guard let vc = self.hostViewController?.lkSplitViewController as? SplitViewController else {
                    DocsLogger.error("DriveMoreDataProvider openInNewTab: vc is not SplitViewController")
                    return
                }
                DocsLogger.info("DriveMoreDataProvider openInNewTab: show docs tab")
                vc.updateSplitMode(.oneOverSecondary, animated: false)
            }
        }
    }

    override var suspend: MoreItem? {
        let alreadySuspend: Bool
        if docsInfo.isFromWiki, let wikiToken = docsInfo.wikiInfo?.wikiToken {
            alreadySuspend = SuspendManager.shared.contains(suspendID: wikiToken)
        } else {
            alreadySuspend = SuspendManager.shared.contains(suspendID: docsInfo.objToken)
        }

        return MoreItem(type: alreadySuspend ? .cancelSuspend : .addToSuspend, newTagInfo: (true, docsInfo.type, false, nil)) { () -> Bool in
            !SKDisplay.pad && !isVC
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            self._suspendAction.onNext(item.type == .addToSuspend)
        }
    }

    override var offline: MoreItem? {
        MoreItem(type: docsInfo.checkIsSetManualOffline() ? .cancelManualOffline : .manualOffline) {
            docsInfo.canShowManuOfflineAction
        } handler: { [weak self] (_, _) in
            guard let self = self, DocsNetStateMonitor.shared.isReachable else {
                return
            }

            let isSetManualOffline = self.docsInfo.checkIsSetManualOffline()
            let fileEntry = self.docsInfo.actualFileEntry
            ManualOfflineHelper.handleManualOfflineFromDetailPage(entry: fileEntry, wikiInfo: self.docsInfo.wikiInfo, isAdd: !isSetManualOffline)
            
            let fileSize = fileEntry.fileSize
            let fileName = fileEntry.realName
            SpaceStatistic.reportManuOfflineAction(for: fileEntry, module: "drive", isAdd: !isSetManualOffline)
            // toast
            if isSetManualOffline {
                self.showSuccess(with: BundleI18n.SKResource.Doc_Facade_RemoveSuccessfully)
            } else {
                self.networkFlowHelper.checkIfNeedToastWhenOffline(fileSize: fileSize, fileName: fileName ?? "", objToken: fileEntry.objToken, block: {[weak self] (toastType) in
                    guard let self = self else { return }
                    switch toastType {
                    case .manualOfflineSuccessToast:
                        self.showSuccess(with: BundleI18n.SKResource.Doc_Facade_EnableManualCache)
                    case  let .manualOfflineFlowToast(trueSize):
                        let size = FileSizeHelper.memoryFormat(trueSize)
                        let toastText = BundleI18n.SKResource.CreationMobile_Warning_CellularStreaming_OffLineToast(size)
                        let buttonText = BundleI18n.SKResource.CreationMobile_Warning_CellularStreaming_ButtonClose
                        self.showOfflineToast(text: toastText,
                                              buttonText: buttonText)
                    @unknown default:
                        spaceAssertionFailure()
                    }
                })
            }
        }
    }

    override var addTo: MoreItem? {
        MoreItem(type: .addTo) {
            docsInfo.canShowAddToAction && DocsConfigManager.isShowFolder
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self, let hostViewController = self.hostViewController else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(.share)
                return
            }
            let srcFile = self.docsInfo.fileEntry
            if srcFile.isOffline {
                self.showFailure(with: BundleI18n.SKResource.Doc_List_FailedToDragOfflineDoc)
                return
            }
            let tracker = WorkspacePickerTracker(actionType: .createFile, triggerLocation: .topBar)
            let config = WorkspacePickerConfig(title: BundleI18n.SKResource.Doc_Facade_AddTo,
                                               action: .createSpaceShortcut,
                                               entrances: .spaceOnly,
                                               usingLegacyRecentAPI: true,
                                               tracker: tracker) { _, _ in
                spaceAssertionFailure("add file should not call config callback")
            }
            let context = DirectoryEntranceContext(action: .addTo(srcFile: srcFile), pickerConfig: config)
            
            let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
            let entranceVC = DirectoryEntranceController(userResolver: userResolver, context: context)
            let nav = UINavigationController(rootViewController: entranceVC)
            nav.modalPresentationStyle = .formSheet
            Navigator.shared.present(nav, from: UIViewController.docs.topLast(of: hostViewController) ?? hostViewController)
        }
    }

    override func deleteCurrentFile() {
        _back.onNext(())
    }

    override var readingData: MoreItem {
        MoreItem(type: .readingData(fileEntry.docsType)) { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [self] (item, _) in
            guard item.state.isEnable else {
                handleDisableEvent(.readingData(fileEntry.docsType))
                return
            }
            self._showReadingPanel.onNext(())
        }
    }

    override var publicPermissionSetting: MoreItem? {
        MoreItem(type: .publicPermissionSetting) { () -> Bool in
            if isCurFileOwner { return true }
            if UserScopeNoChangeFG.WWJ.permissionSDKEnableInDrive {
                return permissionService.validate(operation: .managePermissionMeta).allow
            } else {
                return userPermissions?.canManageMeta() == true
            }
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(.publicPermissionSetting)
                return
            }
            self._showPublicPermissionPanel.onNext(())
        }
    }

    override var sensitivtyLabel: MoreItem? {
        guard let level = docsInfo.secLabel else { return nil }

        var title = ""
        let style = level.moreViewItemRightStyle
        switch style {
        case .normal:
            title = level.label.name
        case .fail:
            title = BundleI18n.SKResource.CreationMobile_SecureLabel_GetInfoFailed
        case .notSet:
            title = BundleI18n.SKResource.CreationMobile_SecureLabel_Unspecified
        case .none:
            title = ""
        @unknown default:
            title = ""
        }
        return MoreItem(type: .sensitivtyLabel, style: .rightLabel(title: title)) { () -> Bool in
            guard LKFeatureGating.sensitivtyLabelEnable,
                  docsInfo.isSingleContainerNode == true,
                  level.canSetSecLabel == .yes else {
                return false
            }
            guard docsInfo.typeSupportSecurityLevel else {
                return false
            }
            let isHaveChangePerm: Bool
            if UserScopeNoChangeFG.WWJ.permissionSDKEnableInDrive {
                isHaveChangePerm = permissionService.validate(operation: .modifySecretLabel).allow
            } else {
                isHaveChangePerm = userPermissions?.canModifySecretLevel() == true
            }
            guard UserScopeNoChangeFG.TYP.permissionSecretDetail else {
                return isHaveChangePerm
            }
            return true
        } prepareEnable: { () -> Bool in
            return true
        } handler: { [weak self] (_, _) in
            guard let self = self else { return }
            self._showSensitivtyLabelSetting.onNext(level)
        }
    }

    override var applyEditPermission: MoreItem? {
        guard let scene = canApplyEditPermission() else { return nil }
        return MoreItem(type: .applyEditPermission) { () -> Bool in
            true
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(.addTo)
                return
            }
            self._showApplyEditPermission.accept(scene)
        }
    }

    override var historyRecord: MoreItem? {
        MoreItem(type: .historyRecord) { () -> Bool in
            guard !self.isVC else {
                return false
            }
            if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
                guard case let .success(container) = permissionService.containerResponse else {
                    return false
                }
                let blocked = (container.previewBlockByAdmin || container.shareControlByCAC || container.previewControlByCAC)
                guard !blocked else {
                    return false
                }
                return permissionService.validate(operation: .edit).allow
            } else {
                // 依赖外部注入
                let controlled = userPermissions?.adminBlocked() == true
                    || userPermissions?.shareControlByCAC() == true
                    || userPermissions?.previewControlByCAC() == true
                return hasEditPermission() && !controlled
            }
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            self.reportClickHistory()
            guard item.state.isEnable else {
                self.handleDisableEvent(.historyRecord)
                return
            }
            self._historyRecordAction.onNext(())
        }
    }

    override func openCopyFileWith(_ fileUrl: URL, from: UIViewController) {
        Navigator.shared.push(fileUrl, from: from)
    }

    override var rename: MoreItem? {
        let canEdit: Bool
        // 密级强制打标需求，当FA用户被admin设置强制打标时，不可重命名
        let canManageMeta: Bool
        let completion: (Bool) -> Void
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInDrive {
            let response = permissionService.validate(operation: .edit)
            canEdit = response.allow
            canManageMeta = permissionService.validate(operation: .managePermissionMeta).allow
            let fileType = docsInfo.type.i18Name
            completion = { [weak self] isForcibleSL in
                guard let self, let hostController = self.hostViewController else { return }
                let message = BundleI18n.SKResource.Doc_Facade_MoreRenameTips(fileType)
                response.didTriggerOperation(controller: hostController, message)
                guard canEdit else { return }
                if isForcibleSL {
                    self._showForcibleWarning.accept(())
                } else if !DocsNetStateMonitor.shared.isReachable {
                    self.handleDisableEvent(.rename)
                }
            }
        } else {
            canEdit = hasEditPermission()
            canManageMeta = userPermissions?.isFA ?? false
            completion = { _ in }
        }
        let isForcibleSL = SecretBannerCreater.checkForcibleSL(canManageMeta: canManageMeta, level: docsInfo.secLabel)
        return MoreItem(type: .rename) { () -> Bool in
            // 依赖外部注入
            true
        } prepareEnable: { () -> Bool in
            return canEdit && DocsNetStateMonitor.shared.isReachable && !isForcibleSL
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            completion(isForcibleSL)
            guard item.state.isEnable else {
                if UserScopeNoChangeFG.WWJ.permissionSDKEnableInDrive { return }
                // 密级强制打标需求，当FA用户被admin设置强制打标时，不可重命名
                if isForcibleSL {
                    self._showForcibleWarning.accept(())
                } else {
                    self.handleDisableEvent(.rename)
                }
                return
            }
            self._showRenamePanel.onNext(())
        }
    }

    override var saveToLocal: MoreItem? {
        let saveVisable: Bool
        let allowSave: Bool
        let saveEnable: Bool
        let saveCompletion: () -> Void

        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInDrive {
            let response = permissionService.validate(operation: .saveFileToLocal)
            allowSave = response.allow && DocsNetStateMonitor.shared.isReachable
            saveEnable = (!response.result.needDisabled) && DocsNetStateMonitor.shared.isReachable
            saveVisable = !response.result.needHidden
            saveCompletion = { [weak self] in
                guard let self, let hostController = self.hostViewController else { return }
                response.didTriggerOperation(controller: hostController, BundleI18n.SKResource.Doc_Document_ExportNoPermission)
                if response.allow && !DocsNetStateMonitor.shared.isReachable {
                    self.handleDisableEvent(.saveToLocal)
                }
            }
        } else {
            allowSave = DocsNetStateMonitor.shared.isReachable
            && validateResult(type: .saveToLocal).allow
            && hasPreviewPermission()
            && hasExportPermission()
            saveEnable = allowSave
            saveVisable = true
            saveCompletion = { [weak self] in
                if allowSave { return }
                self?.handleDisableEvent(.saveToLocal)
            }
        }

        return MoreItem(type: .saveToLocal, preventDismissal: saveEnable && !allowSave) {
            saveVisable
        } prepareEnable: {
            saveEnable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            saveCompletion()
            guard allowSave else {
                return
            }
            self._showSaveToLocal.onNext(())
        }
    }

    override var importAsDocs: MoreItem? {
        let fileType = self.docsInfo.fileType
        let importVisable: Bool
        let importEnable: Bool
        let importCompletion: () -> Void

        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInDrive {
            let response = permissionService.validate(operation: .importToOnlineDocument)
            importEnable = response.allow && DocsNetStateMonitor.shared.isReachable
            importVisable = !response.result.needHidden
            importCompletion = { [weak self] in
                guard let self, let hostController = self.hostViewController else { return }
                response.didTriggerOperation(controller: hostController, BundleI18n.SKResource.Doc_Document_ExportNoPermission)
                if response.allow && !DocsNetStateMonitor.shared.isReachable {
                    self.handleDisableEvent(.importAsDocs(fileType))
                }
            }
        } else {
            importVisable = true
            importEnable = DocsNetStateMonitor.shared.isReachable && validateResult(type: .importAsDocs(fileType)).allow
            importCompletion = { [weak self] in
                if importEnable { return }
                self?.handleDisableEvent(.importAsDocs(fileType))
            }
        }
        return MoreItem(type: .importAsDocs(fileType),
                 newTagInfo: (true, docsInfo.type, docsInfo.isOwner, nil)) { () -> Bool in
            importVisable
        } prepareEnable: {
            importEnable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            importCompletion()
            guard item.state.isEnable else {
                return
            }
            self._importAsDocsAction.onNext(())
        }
    }

    override var openWithOtherApp: MoreItem? {

        let allowSave: Bool
        let saveVisable: Bool
        let saveEnable: Bool
        let saveCompletion: () -> Void

        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInDrive {
            let response = permissionService.validate(operation: .openWithOtherApp)
            allowSave = response.allow && DocsNetStateMonitor.shared.isReachable
            saveEnable = (!response.result.needDisabled) && DocsNetStateMonitor.shared.isReachable
            saveVisable = !response.result.needHidden
            saveCompletion = { [weak self] in
                guard let self, let hostController = self.hostViewController else { return }
                response.didTriggerOperation(controller: hostController, BundleI18n.SKResource.Doc_Document_ExportNoPermission)
                if response.allow && !DocsNetStateMonitor.shared.isReachable {
                    self.handleDisableEvent(.openWithOtherApp)
                }
            }
        } else {
            allowSave = DocsNetStateMonitor.shared.isReachable
            && validateResult(type: .openWithOtherApp).allow
            && hasPreviewPermission()
            && hasExportPermission()
            saveEnable = allowSave
            saveVisable = true
            saveCompletion = { [weak self] in
                if allowSave { return }
                self?.handleDisableEvent(.openWithOtherApp)
            }
        }

        return MoreItem(type: .openWithOtherApp, preventDismissal: saveEnable && !allowSave) {
            saveVisable
        } prepareEnable: {
            saveEnable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            saveCompletion()
            guard allowSave else {
                return
            }
            self._openInOtherAppAction.onNext(())
        }
    }

    public var wikiMoveTo: MoreItem? {
        guard let wikiInfo = docsInfo.wikiInfo else {
            return nil
        }
        return MoreItem(type: .moveTo) {
            return !isVC
        } prepareEnable: {
            guard DocsNetStateMonitor.shared.isReachable else { return false }
            guard wikiInfo.wikiNodeState.showMove else { return false }
            return true
        } handler: { [weak self] (item, _) in
            guard let self else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(.moveTo)
                return
            }
            self.wikiActionHandler.moveWiki()
        }
    }

    public var wikiShortcut: MoreItem? {
        guard let wikiInfo = self.docsInfo.wikiInfo else {
            spaceAssertionFailure("cannot get wikiInfo")
            return nil
        }
        return MoreItem(type: .addShortCut) {
            wikiInfo.wikiNodeState.canShortcut
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(.addShortCut)
                return
            }
            self.wikiActionHandler.wikiShortcut()
        }
    }

    public var wikiDelete: MoreItem? {
        guard let wikiInfo = self.docsInfo.wikiInfo else {
            spaceAssertionFailure("cannot get wikiInfo")
            return nil
        }
        let type = wikiInfo.wikiNodeState.isShortcut ? MoreItemType.deleteShortcut : MoreItemType.delete
        let hidden: Bool
        if UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled {
            // 用新点位
            hidden = (!wikiInfo.wikiNodeState.showDelete) || (docsInfo.isInVideoConference == true)
        } else {
            hidden = (!wikiInfo.wikiNodeState.nodeMovePermission) || (docsInfo.isInVideoConference == true)
        }
        // 本体在 space 的 wiki shortcut，需要隐藏 wikiDelete 按钮
        let hiddenForExternalShortcut = wikiInfo.wikiNodeState.isShortcut
        && wikiInfo.wikiNodeState.originIsExternal
        return MoreItem(type: type) {
            !(hidden || hiddenForExternalShortcut)
        } prepareEnable: { () -> Bool in
            if UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled {
                return DocsNetStateMonitor.shared.isReachable
            } else {
                return DocsNetStateMonitor.shared.isReachable && wikiInfo.wikiNodeState.canDelete
            }
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            guard item.state.isEnable else {
                self.handleDisableWikiDeleteEvent(wikiInfo: wikiInfo)
                return
            }
            self.wikiActionHandler.wikiDelete()
        }
    }

    public var copyWikiFile: MoreItem? {
        guard let wikiInfo = self.docsInfo.wikiInfo else {
            spaceAssertionFailure("cannot get wikiInfo")
            return nil
        }

        let canCopy: Bool
        let copyEnable: Bool
        let copyCompletion: () -> Void

        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInDrive {
            let response = permissionSDK.validate(request: PermissionRequest(token: docsInfo.token,
                                                                             type: docsInfo.inherentType,
                                                                             operation: .createCopy,
                                                                             bizDomain: .ccm,
                                                                             tenantID: docsInfo.tenantID))
            canCopy = response.allow && DocsNetStateMonitor.shared.isReachable
            copyEnable = !response.result.needDisabled && DocsNetStateMonitor.shared.isReachable
            copyCompletion = { [weak self] in
                guard let self, let hostController = self.hostViewController else { return }
                response.didTriggerOperation(controller: hostController, BundleI18n.SKResource.Doc_Document_ExportNoPermission)
                if response.allow && !DocsNetStateMonitor.shared.isReachable {
                    self.handleDisableEvent(.copyFile)
                }
            }
        } else {
            canCopy = DocsNetStateMonitor.shared.isReachable
            && validateResult(type: .copyFile).allow
            copyEnable = canCopy
            copyCompletion = { [weak self] in
                if canCopy { return }
                self?.handleDisableEvent(.copyFile)
            }
        }

        return MoreItem(type: .copyFile, preventDismissal: copyEnable && !canCopy) {
            wikiInfo.wikiNodeState.canCopy
        } prepareEnable: {
            copyEnable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            copyCompletion()
            guard canCopy else {
                return
            }
            self.wikiActionHandler.showWikiCopyFilePanel(fileSize: self.fileSize)
        }
    }

    var operationHistory: MoreItem? {
        // 只支持 wiki 2.0 或 space 2.0
        guard docsInfo.isFromWiki || docsInfo.isSingleContainerNode else { return nil }
        // 目前 drive 已支持新的文档信息面板，因此隐藏该MoreItem入口
        return nil
    }

    override var spaceMoveTo: MoreItem? {
        return MoreItem(type: .moveTo) {
            return UserScopeNoChangeFG.ZYP.spaceMoveToEnable && !isVC
        } prepareEnable: { [weak self] in
            guard DocsNetStateMonitor.shared.isReachable else { return false }
            guard self?.docsInfo.containerInfo != nil else { return false }
            return true
        } handler: { [weak self] (item, _) in
            guard let self else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(.moveTo)
                return
            }
            let context = SpaceMoveInteractionHelper.MoveContext(docsInfo: self.docsInfo, parent: nil,
                                                   didMovedToWiki: { [weak self] token in
                self?._redirectToWiki.onNext(token)
            },
                                                   didMovedToSpace: nil)
            self.actionHandler.moveWithPicker(context: context)
        }
    }
}

// MARK: - Actions
extension DriveMoreDataProvider {

    private func feedShortcutStatus() -> Bool {
        if let feedId = self.feedId {
            let getService = FeedShortcutService(feedId, .get)
            let isPined = HostAppBridge.shared.call(getService) as? Bool
            return isPined ?? false
        } else {
            return false
        }
    }

}
