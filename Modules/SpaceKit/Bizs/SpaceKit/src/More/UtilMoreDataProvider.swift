//
//  UtilMoreDataProvider.swift
//  SpaceKit
//
//  Created by lizechuang on 2021/3/2.
//
//swiftlint:disable file_length
//swiftlint:disable type_body_length

import SKFoundation
import SKCommon
import SKUIKit
import SKSpace
import EENavigator
import SKResource
import RxSwift
import RxRelay
import RxCocoa
import SKBrowser
import LarkAlertController
import UniverseDesignToast
import SwiftyJSON
import SKWikiV2
import LarkUIKit
import LarkSuspendable
import UIKit
import UniverseDesignDialog
import UniverseDesignColor
import SpaceInterface
import SKInfra
import LarkContainer
import SKWorkspace

// MARK: - Setting
extension UtilMoreDataProvider {

    private var preferWikiDeleteInSeparateSection: Bool {
        let hiddenWikiDelete = docsInfo.wikiInfo?.wikiNodeState.originIsExternal ?? false
        return !hiddenWikiDelete
    }

    private var standardHorizontalItems: [MoreItem] {
        var items = unassociateDoc - feedShortcut - share - suspend - spaceMoveTo - pin - star - offline
        if quickLaunchService.isQuickLauncherEnabled {
            if hostViewController?.isTemporaryChild == true {
                items =  feedShortcut - share - unassociateDoc - quickLaunch - suspend - spaceMoveTo - pin - star - offline
            } else {
                items =  feedShortcut - share - unassociateDoc - openInNewTab - quickLaunch - suspend - spaceMoveTo - pin - star - offline
            }
        }
        if docsInfo.isSingleContainerNode {
            items = items - addShortCut
        } else {
            items = items - addTo
        }
        return items
    }

    private var wikiHorizontalItems: [MoreItem] {
        if quickLaunchService.isQuickLauncherEnabled {
            if hostViewController?.isTemporaryChild == true {
                return feedShortcut - share - unassociateDoc - quickLaunch - suspend - wikiMoveTo - pin - star - offline - wikiShortcut
            }
            return  feedShortcut - share - unassociateDoc - openInNewTab - quickLaunch - suspend - wikiMoveTo - pin - star - offline - wikiShortcut
        } else {
            return feedShortcut - share - unassociateDoc - suspend - wikiMoveTo - pin - star - offline - wikiShortcut
        }
    }

    private var versionDocsHorizontalItems: [MoreItem] {
        var items = shareVersion - sourceDocs - suspend
        if quickLaunchService.isQuickLauncherEnabled {
            if hostViewController?.isTemporaryChild == true {
                items = shareVersion - sourceDocs - quickLaunch - suspend
            } else {
                items = shareVersion - sourceDocs - openInNewTab - quickLaunch - suspend
            }
        }
        return items
    }

    private var docs: MoreItemsBuilder {
        MoreItemsBuilder {
            MoreSection(type: .horizontal, items: standardHorizontalItems)
            MoreSection(type: .vertical, outsideControlItems: self.outsideControlItems) {
                openInBrowser
                readingData
                sensitivtyLabel
                subscribe
                commentSubscribe
                publicPermissionSetting
                operationHistory
                widescreenModeSwitch
                translate
                searchReplace
                applyEditPermission
                historyRecord
                catalog
                copyFile
                saveAsTemplateV1
                saveAsTemplateV2
                changeTemplateTag
                exportDocument
                retention
                customerService
                report
                reportV2
            }
            MoreSection(type: .vertical) {
                delete
            }
        }
    }

    private var wikiDocs: MoreItemsBuilder {
        MoreItemsBuilder {
            MoreSection(type: .horizontal, items: wikiHorizontalItems)
            MoreSection(type: .vertical, outsideControlItems: self.outsideControlItems) {
                openInBrowser
                readingData
                sensitivtyLabel
                subscribe
                commentSubscribe
                publicPermissionSetting
                operationHistory
                widescreenModeSwitch
                translate
                searchReplace
                applyEditPermission
                historyRecord
                catalog
                copyWikiFile
                saveAsTemplateV1
                saveAsTemplateV2
                changeTemplateTag
                exportDocument
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
    
    private var sheet: MoreItemsBuilder {
        return MoreItemsBuilder {
            MoreSection(type: .horizontal) {
                if docsInfo.isVersion {
                    return versionDocsHorizontalItems
                } else  {
                    return standardHorizontalItems
                }    
            }
            MoreSection(type: .vertical, outsideControlItems: self.outsideControlItems) {
                if docsInfo.isVersion {
                    searchReplace
                    copyFile
                    translate
                    exportDocument
                    renameVersion
                } else {
                    openInBrowser
                    readingData
                    sensitivtyLabel
                    subscribe
                    publicPermissionSetting
                    operationHistory
                    searchReplace
                    applyEditPermission
                    rename
                    savedVersionList
                    copyFile
                    saveAsTemplateV1
                    saveAsTemplateV2
                    changeTemplateTag
                    exportDocument
                    retention
                    reportOutdate
                    docFreshness
                    customerService
                    report
                    reportV2
                }
            }
            MoreSection(type: .vertical) {
                docsInfo.isVersion ? deleteVersion : delete
            }
        }
    }
    
    private var wikiSheet: MoreItemsBuilder {
        return MoreItemsBuilder {
            MoreSection(type: .horizontal) {
                if docsInfo.isVersion {
                    return versionDocsHorizontalItems
                }
                return wikiHorizontalItems
            }
            MoreSection(type: .vertical, outsideControlItems: self.outsideControlItems) {
                if docsInfo.isVersion {
                    searchReplace
                    copyFile
                    translate
                    exportDocument
                    renameVersion
                } else {
                    openInBrowser
                    readingData
                    sensitivtyLabel
                    subscribe
                    publicPermissionSetting
                    operationHistory
                    searchReplace
                    applyEditPermission
                    rename
                    savedVersionList
                    copyWikiFile
                    saveAsTemplateV1
                    saveAsTemplateV2
                    changeTemplateTag
                    exportDocument
                    reportOutdate
                    docFreshness
                    customerService
                    report
                    reportV2
                }
            }
            MoreSection(type: .vertical) {
                if docsInfo.isVersion {
                    deleteVersion
                } else {
                    if preferWikiDeleteInSeparateSection {
                        wikiDelete
                    }
                    delete
                }
            }
        }
    }
    
    private var slides: MoreItemsBuilder {
        MoreItemsBuilder {
            MoreSection(type: .horizontal, items: standardHorizontalItems)
            MoreSection(type: .vertical, outsideControlItems: self.outsideControlItems) {
                openInBrowser
                readingData
                sensitivtyLabel
                commentSubscribe
                publicPermissionSetting
                rename
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
    
    private var wikiSlides: MoreItemsBuilder {
        MoreItemsBuilder {
            MoreSection(type: .horizontal, items: wikiHorizontalItems)
            MoreSection(type: .vertical, outsideControlItems: self.outsideControlItems) {
                openInBrowser
                readingData
                sensitivtyLabel
                commentSubscribe
                publicPermissionSetting
                rename
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
    
    private var mindnote: MoreItemsBuilder {
        MoreItemsBuilder {
            MoreSection(type: .horizontal, items: standardHorizontalItems)
            MoreSection(type: .vertical, outsideControlItems: self.outsideControlItems) {
                openInBrowser
                readingData
                sensitivtyLabel
                applyEditPermission
                publicPermissionSetting
                operationHistory
                copyFile
                saveAsTemplateV1
                saveAsTemplateV2
                changeTemplateTag
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
    
    private var wikiMindnote: MoreItemsBuilder {
        MoreItemsBuilder {
            MoreSection(type: .horizontal, items: wikiHorizontalItems)
            MoreSection(type: .vertical, outsideControlItems: self.outsideControlItems) {
                openInBrowser
                readingData
                sensitivtyLabel
                applyEditPermission
                publicPermissionSetting
                operationHistory
                copyWikiFile
                saveAsTemplateV1
                saveAsTemplateV2
                changeTemplateTag
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

    private var docX: MoreItemsBuilder {
        MoreItemsBuilder {
            MoreSection(type: .horizontal) {
                if docsInfo.isVersion {
                    return versionDocsHorizontalItems
                } else  {
                    return standardHorizontalItems
                }
            }
            MoreSection(type: .vertical, outsideControlItems: self.outsideControlItems) {
                if docsInfo.isVersion {
                    searchReplace
                    catalog
                    copyFile
                    translate
                    exportDocument
                    renameVersion
                } else {
                    openInBrowser
                    readingData
                    sensitivtyLabel
                    subscribe
                    commentSubscribe
                    publicPermissionSetting
                    operationHistory
                    translate
                    searchReplace
                    applyEditPermission
                    widescreenModeSwitch
                    historyRecord
                    savedVersionList
                    catalog
                    copyFile
                    saveAsTemplateV1
                    saveAsTemplateV2
                    changeTemplateTag
                    exportDocument
                    retention
                    reportOutdate
                    docFreshness
                    customerService
                    report
                    reportV2
                }
            }
            MoreSection(type: .vertical) {
                docsInfo.isVersion ? deleteVersion : delete
            }
        }
    }

    private var wikiDocX: MoreItemsBuilder {
        MoreItemsBuilder {
            MoreSection(type: .horizontal) {
                if docsInfo.isVersion {
                    return versionDocsHorizontalItems
                }
                return wikiHorizontalItems
            }
            MoreSection(type: .vertical, outsideControlItems: self.outsideControlItems) {
                if docsInfo.isVersion {
                    searchReplace
                    catalog
                    copyFile
                    translate
                    exportDocument
                    renameVersion
                } else {
                    openInBrowser
                    readingData
                    sensitivtyLabel
                    subscribe
                    commentSubscribe
                    publicPermissionSetting
                    operationHistory
                    translate
                    searchReplace
                    applyEditPermission
                    widescreenModeSwitch
                    historyRecord
                    savedVersionList
                    catalog
                    copyWikiFile
                    saveAsTemplateV1
                    saveAsTemplateV2
                    changeTemplateTag
                    exportDocument
                    reportOutdate
                    docFreshness
                    customerService
                    report
                    reportV2
                }
            }
            MoreSection(type: .vertical) {
                if docsInfo.isVersion {
                    deleteVersion
                } else {
                    if preferWikiDeleteInSeparateSection {
                        wikiDelete
                    }
                    delete
                }
            }
        }
    }

    private var bitableHorizontalItems: [MoreItem] {
        var items = feedShortcut - share - suspend - spaceMoveTo - workbench - pin - star - offline
        if quickLaunchService.isQuickLauncherEnabled {
            if hostViewController?.isTemporaryChild == true {
                items = feedShortcut - share - quickLaunch - suspend - spaceMoveTo - workbench - pin - star - offline
            } else {
                items = feedShortcut - share - openInNewTab - quickLaunch - suspend - spaceMoveTo - workbench - pin - star - offline
            }
        }
        if docsInfo.isSingleContainerNode {
            items = items - addShortCut
        } else {
            items = items - addTo
        }
        return items
    }

    private var wikiBitableHorizontalItems: [MoreItem] {
        var items = feedShortcut - share - suspend - wikiMoveTo - workbench - pin - star - offline - wikiShortcut
        if quickLaunchService.isQuickLauncherEnabled {
            if hostViewController?.isTemporaryChild == true {
                items = feedShortcut - share - quickLaunch - suspend - wikiMoveTo - workbench - pin - star - offline - wikiShortcut
            } else {
                items = feedShortcut - share - openInNewTab - quickLaunch - suspend - wikiMoveTo - workbench - pin - star - offline - wikiShortcut
            }
        }
        return items
    }

    private var bitable: MoreItemsBuilder {
        MoreItemsBuilder {
            MoreSection(type: .horizontal, items: bitableHorizontalItems)
            MoreSection(type: .vertical, outsideControlItems: self.outsideControlItems) {
                openInBrowser
                readingData
                sensitivtyLabel
                bitableAdvancedPermissions
                publicPermissionSetting
                operationHistory
                applyEditPermission
                searchReplace
                rename
                copyFile
                saveAsTemplateV1
                saveAsTemplateV2
                changeTemplateTag
                timeZone
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

    private var wikiBitable: MoreItemsBuilder {
        MoreItemsBuilder {
            MoreSection(type: .horizontal, items: wikiBitableHorizontalItems)
            MoreSection(type: .vertical, outsideControlItems: self.outsideControlItems) {
                openInBrowser
                readingData
                sensitivtyLabel
                bitableAdvancedPermissions
                publicPermissionSetting
                operationHistory
                applyEditPermission
                searchReplace
                rename
                copyWikiFile
                saveAsTemplateV1
                saveAsTemplateV2
                changeTemplateTag
                timeZone
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

class UtilMoreDataProvider: InsideMoreDataProvider {
    // output
    lazy var deleteFile: Driver<()> = {
        _deleteFile.asDriver(onErrorJustReturn: ())
    }()
    lazy var showReadingPanel: Driver<()> = {
        _showReadingPanel.asDriver(onErrorJustReturn: ())
    }()
    lazy var showSensitivtyLabelSetting: Driver<SecretLevel?> = {
        _showSensitivtyLabelSetting.asDriver(onErrorJustReturn: nil)
    }()
    lazy var showBitableAdvancedPermissionsSetting: Driver<BitableBridgeData> = {
        _showBitableAdvancedPermissionsSetting.asDriver(onErrorJustReturn: BitableBridgeData(isPro: false, tables: []))
    }()
    lazy var showPublicPermissionPanel: Driver<()> = {
        _showPublicPermissionPanel.asDriver(onErrorJustReturn: ())
    }()
    lazy var showSearchPanel: Driver<()> = {
        _showSearchPanel.asDriver(onErrorJustReturn: ())
    }()
    lazy var showApplyEditPermission: Signal<ApplyEditScene> = {
        _showApplyEditPermission.asSignal()
    }()
    lazy var historyRecordAction: Driver<()> = {
        _historyRecordAction.asDriver(onErrorJustReturn: ())
    }()
    lazy var versionListAction: Driver<()> = {
        _versionListAction.asDriver(onErrorJustReturn: ())
    }()
    
    lazy var catalogAction: Driver<()> = {
        _catalogAction.asDriver(onErrorJustReturn: ())
    }()
    // isEditor, adminBlocked
    lazy var showExportPanel: Driver<(Bool, Bool)> = {
        _showExportPanel.asDriver(onErrorJustReturn: (false, false))
    }()
    lazy var showRenamePanel: Driver<()> = {
        _showRenamePanel.asDriver(onErrorJustReturn: ())
    }()
    lazy var showCopyWikiFilePanel: Driver<()> = {
        _showCopyWikiFilePanel.asDriver(onErrorJustReturn: ())
    }()
    lazy var didWikiShortcut: Driver<()> = {
        _wikiShortcut.asDriver(onErrorJustReturn: ())
    }()
    lazy var didWikiMove: Signal<Void> = {
        _wikiMove.asSignal()
    }()
    lazy var didWikiDelete: Driver<()> = {
        _wikiDelete.asDriver(onErrorJustReturn: ())
    }()
    lazy var didSuspendAction: Driver<Bool> = {
        _suspendAction.asDriver(onErrorJustReturn: false)
    }()

    lazy var showOperationHistoryPanel: Signal<()> = {
        _showOperationHistoryPanel.asSignal()
    }()
    
    lazy var showTimeZoneSetting: Signal<()> = {
        _showTimeZoneSetting.asSignal()
    }()
    
    lazy var deleteVersions: Driver<()> = {
        _deleteVersion.asDriver(onErrorJustReturn: ())
    }()
    
    lazy var showForcibleWarning: Signal<()> = {
        _showForcibleWarning.asSignal()
    }()
    
    lazy var didWorkbenchAction: Driver<Bool> = {
        _workbenchAction.asDriver(onErrorJustReturn: false)
    }()
    
    // input
    private let _deleteFile = PublishSubject<()>()
    private let _deleteVersion = PublishSubject<()>()
    private let _showReadingPanel = PublishSubject<()>()
    private let _showBitableAdvancedPermissionsSetting = PublishSubject<BitableBridgeData>()
    private let _showSensitivtyLabelSetting = PublishSubject<SecretLevel?>()
    private let _showPublicPermissionPanel = PublishSubject<()>()
    private let _showSearchPanel = PublishSubject<()>()
    private let _showApplyEditPermission = PublishRelay<ApplyEditScene>()
    private let _historyRecordAction = PublishSubject<()>()
    private let _catalogAction = PublishSubject<()>()
    private let _showExportPanel = PublishSubject<(Bool, Bool)>()
    private let _showRenamePanel = PublishSubject<()>()
    private let _showCopyWikiFilePanel = PublishSubject<()>()
    private let _wikiShortcut = PublishSubject<()>()
    private let _wikiMove = PublishRelay<Void>()
    private let _wikiDelete = PublishSubject<()>()
    private let _suspendAction = PublishSubject<Bool>()
    private let _showOperationHistoryPanel = PublishRelay<Void>()
    private let _showTimeZoneSetting = PublishRelay<Void>()
    private let _versionListAction = PublishSubject<()>()
    private let _showForcibleWarning = PublishRelay<Void>()
    private let _workbenchAction = PublishSubject<Bool>()

    /// 需要异步获取状态的 item 的标识符。进行统一管理
    struct ItemAsyncGetStatusFlags {
        var isWorkbenchAdded: Bool = false
    }
    
    weak var model: BrowserModelConfig?
    var outsideControlBadges: [String]?
    var itemAsyncGetStatusFlags = ItemAsyncGetStatusFlags()
    private(set) var bitableBridgeData: BitableBridgeData?
    private let bag = DisposeBag()

    override var builder: MoreItemsBuilder {
        let usingWiki = docsInfo.isFromWiki
        if usingWiki {
            switch self.docsInfo.inherentType {
            case .doc:
                return wikiDocs
            case .sheet:
                return wikiSheet
            case .mindnote:
                return wikiMindnote
            case .bitable:
                return wikiBitable
            case .docX:
                return wikiDocX
            case .slides:
                return wikiSlides
            default:
                spaceAssertionFailure("UtilMoreDataProvider should not contain type: \(docsInfo.type.rawValue)")
                return other
            }
        }
        // 如果是wiki，会取到wiki的真正类型
        switch self.docsInfo.inherentType {
        case .doc:
            return docs
        case .sheet:
            return sheet
        case .bitable:
            return bitable
        case .mindnote:
            return mindnote
        case .slides:
            return slides
        case .docX:
            return docX
        default:
            spaceAssertionFailure("UtilMoreDataProvider should not contain type: \(docsInfo.type.rawValue)")
            return other
        }
    }

    init(docsInfo: DocsInfo,
         model: BrowserModelConfig?,
         hostViewController: UIViewController,
         userPermissions: UserPermissionAbility? = nil,
         permissionService: UserPermissionService?,
         publicPermissionMeta: PublicPermissionMeta? = nil,
         outsideControlItems: MoreDataOutsideControlItems? = nil,
         outsideControlBadges: [String]? = nil,
         bitableBridgeData: BitableBridgeData? = nil,
         followAPIDelegate: SpaceFollowAPIDelegate?,
         docComponentHostDelegate: DocComponentHostDelegate?,
         trackerParams: [String: Any]? = nil) {
        super.init(docsInfo: docsInfo,
                   fileEntry: docsInfo.fileEntry,
                   hostViewController: hostViewController,
                   userPermissions: userPermissions,
                   permissionService: permissionService,
                   publicPermissionMeta: publicPermissionMeta,
                   outsideControlItems: outsideControlItems,
                   followAPIDelegate: followAPIDelegate,
                   docComponentHostDelegate: docComponentHostDelegate)
        self.model = model
        self.outsideControlBadges = outsideControlBadges
        self.bitableBridgeData = bitableBridgeData
    }
    
    override func createMoreActionHandler() -> InsideMoreActionHandler {
        return UtilMoreActionHandler(hostVC: hostViewController, spaceAPI: dataModel, from: .more)
    }

    // MARK: - Items
    override var feedShortcut: MoreItem? {
        if let need = model?.feedInfo.needShowFeedCardShortcut(channel: 3), need,
           let isShortCut = model?.feedInfo.isFeedCardShortcut() {
            return MoreItem(type: isShortCut ? .unFeedShortcut : .feedShortcut) { [weak self] (_, _) in
                guard let self = self else { return }
                guard let isShortCut = self.model?.feedInfo.isFeedCardShortcut() else {
                    DocsLogger.info("[FeedShortcut] model 为空")
                    spaceAssertionFailure("model 为空")
                    return
                }
                let status = !isShortCut
                self.model?.feedInfo.markFeedCardShortcut(isAdd: !isShortCut, success: { (_) in
                    self.reportForFeedShortcut(status)
                    let tips = status ? BundleI18n.SKResource.Doc_More_AddQuickSwitcherSuccess
                        : BundleI18n.SKResource.Doc_More_RemoveQuickSwitcherSuccess
                    self.showSuccess(with: tips)
                }, failure: { (error) in
                    DocsLogger.info("==SKFeedShortcut== Mark Shortcut failed. Error: \(error)")
                    self.reportForFeedShortcut(status)
                    let tips = status ? BundleI18n.SKResource.Doc_More_AddQuickSwitcherFail : BundleI18n.SKResource.Doc_More_RemoveQuickSwitcherFail
                    self.showFailure(with: tips)
                })
            }
        }
        return nil
    }

    override var share: MoreItem? {
        MoreItem(type: .share,
                 newTagInfo: (true, docsInfo.type, docsInfo.isOwner, nil)
        ) { () -> Bool in
            true
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(.share)
                return
            }
            self.callFunction(DocsJSCallBack.sheetClickShare, params: nil, completion: nil)
        }
    }
    
    override var shareVersion: MoreItem? {
        MoreItem(type: .shareVersion,
                 newTagInfo: (true, docsInfo.type, docsInfo.isOwner, nil)
        ) { () -> Bool in
            true
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(.share)
                return
            }
            self.callFunction(DocsJSCallBack.sheetClickShare, params: nil, completion: nil)
        }
    }

    override var suspend: MoreItem? {
        var token = docsInfo.wikiInfo?.wikiToken ?? docsInfo.objToken
        if docsInfo.isVersion {
            token = docsInfo.objToken + docsInfo.versionInfo!.version
        }
        let alreadySuspend = SuspendManager.shared.contains(suspendID: token)
        return MoreItem(type: alreadySuspend ? .cancelSuspend : .addToSuspend, newTagInfo: (true, docsInfo.type, false, self.outsideControlBadges)) { () -> Bool in
            return !SKDisplay.pad && !isVC && !isDocComponent
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            self._suspendAction.onNext(item.type == .addToSuspend)
        }
    }

    override var offline: MoreItem? {
        MoreItem(type: docsInfo.checkIsSetManualOffline() ? .cancelManualOffline : .manualOffline) {
            docsInfo.canShowManuOfflineAction && ManualOfflineConfig.enableFileType(docsInfo.inherentType)
        } handler: { [weak self] (_, _) in
            guard let self = self, DocsNetStateMonitor.shared.isReachable else {
                return
            }

            let isSetManualOffline = self.docsInfo.checkIsSetManualOffline()
            // Todo SlideActionManager 删除
            let fileEntry = self.docsInfo.actualFileEntry
            ManualOfflineHelper.handleManualOfflineFromDetailPage(entry: fileEntry, wikiInfo: self.docsInfo.wikiInfo, isAdd: !isSetManualOffline)
            SpaceStatistic.reportManuOfflineAction(for: fileEntry, module: (FileListStatistics.module ?? .home).rawValue, isAdd: !isSetManualOffline)
            // toast
            if isSetManualOffline {
                self.showSuccess(with: BundleI18n.SKResource.Doc_Facade_RemoveSuccessfully)
            } else {
                self.showSuccess(with: BundleI18n.SKResource.Doc_Facade_EnableManualCache)
            }
        }
    }

    override var addTo: MoreItem? {
        MoreItem(type: .addTo) {
            docsInfo.canShowAddToAction && DocsConfigManager.isShowFolder
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self, let hostVC = self.hostViewController else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(.addTo)
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
            Navigator.shared.present(nav, from: UIViewController.docs.topLast(of: hostVC) ?? hostVC)
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
            self._wikiShortcut.onNext(())
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
            self._wikiMove.accept(())
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
            self._wikiDelete.onNext(())
        }
    }

    public var copyWikiFile: MoreItem? {
        guard let wikiInfo = self.docsInfo.wikiInfo else {
            spaceAssertionFailure("cannot get wikiInfo")
            return nil
        }
        let blockForDocxEdition: Bool
        if docsInfo.isVersion {
            // 对版本创建副本功能需要额外 FG 判断
            blockForDocxEdition = !UserScopeNoChangeFG.WWJ.copyEditionEnable
        } else {
            blockForDocxEdition = false
        }
        let canCopy: Bool
        let copyEnable: Bool
        let permissionCompletion: () -> Bool
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            let request = PermissionRequest(entity: .ccm(token: docsInfo.token, type: docsInfo.inherentType),
                                            operation: .createCopy,
                                            bizDomain: .ccm)
            let response = permissionSDK.validate(request: request)
            canCopy = response.allow && DocsNetStateMonitor.shared.isReachable
            copyEnable = !response.result.needDisabled && DocsNetStateMonitor.shared.isReachable
            permissionCompletion = { [weak self] in
                guard let self, let hostController = self.hostViewController else { return false }
                response.didTriggerOperation(controller: hostController)
                guard canCopy else { return false }
                if !DocsNetStateMonitor.shared.isReachable {
                    self.handleDisableEvent(.copyFile)
                }
                return false
            }
        } else {
            canCopy = validateResult(type: .copyFile).allow && DocsNetStateMonitor.shared.isReachable
            copyEnable = canCopy
            permissionCompletion = { true }
        }
        return MoreItem(type: .copyFile, preventDismissal: copyEnable && !canCopy) {
            wikiInfo.wikiNodeState.canCopy && !blockForDocxEdition
        } prepareEnable: { () -> Bool in
            copyEnable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            let allowDisableEvent = permissionCompletion()
            guard canCopy else {
                guard allowDisableEvent else { return }
                self.handleDisableEvent(.copyFile)
                return
            }
            self._showCopyWikiFilePanel.onNext(())
        }
    }

    override func deleteCurrentFile() {
        self._deleteFile.onNext(())
    }
    
    override func deleteCurrentVersion() {
        self._deleteVersion.onNext(())
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
            if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
                isHaveChangePerm = permissionService.validate(operation: .modifySecretLabel).allow
            } else {
                isHaveChangePerm = userPermissions?.canModifySecretLevel() == true
            }
            guard UserScopeNoChangeFG.TYP.permissionSecretDetail else {
                return isHaveChangePerm
            }
            return true
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (_, _) in
            guard let self = self else { return }
            self._showSensitivtyLabelSetting.onNext(level)
        }
    }

    override var bitableAdvancedPermissions: MoreItem? {
        guard let data = bitableBridgeData else { return nil }
        return MoreItem(type: .bitableAdvancedPermissions, style: data.moreItemStyle) { () -> Bool in
            if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
                return PermissionManager.getUseradPermVisibility(permissionService: permissionService,
                                                                 isTemplate: docsInfo.templateType?.isTemplate == true,
                                                                 isPro: data.isPro)
            } else {
                return PermissionManager.getUserAdPermVisibility(
                    for: docsInfo,
                    isPro: data.isPro,
                    userPermissions: userPermissions
                )
            }
        } prepareEnable: { () -> Bool in
            return true
        } handler: { [weak self] (_, _) in
            guard let self = self else { return }
            self._showBitableAdvancedPermissionsSetting.onNext(data)
        }
    }

    override var publicPermissionSetting: MoreItem? {
        MoreItem(type: .publicPermissionSetting) { () -> Bool in
            if isCurFileOwner { return true }
            if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
                return permissionService.validate(operation: .isFullAccess).allow
            } else {
                var isFullAccess = self.userPermissions?.canManageMeta() ?? false
                //wiki2.0 单页面fg开，考虑单页面fa权限
                if self.docsInfo.isFromWiki {
                    isFullAccess = isFullAccess || (self.userPermissions?.canSinglePageManageMeta() ?? false)
                }
                return isFullAccess
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

    override var widescreenModeSwitch: MoreItem? {
        MoreItem(type: .widescreenModeSwitch,
                 style: .mSwitch(isOn: self.isFullWidth, needLoading: false),
                 newTagInfo: (true, docsInfo.type, docsInfo.isOwner, nil)) { () -> Bool in
            SKDisplay.pad
        } handler: { [weak self] (_, isSwitchOn) in
            guard let self = self else { return }
            let mode: WidescreenMode = isSwitchOn ? .fullwidth : .standardwidth
            CCMKeyValue.globalUserDefault.set(mode.rawValue, forKey: UserDefaultKeys.widescreenModeLastSelected)
            self.callFunction(.widescreenModeSwitch, params: ["mode": mode.rawValue], completion: nil)
        }
    }

    override var translate: MoreItem? {
        let title = self.getTranslateLanguage()
        let titleKey = self.getTranslateLanguageKey()
        let translateFG = UserScopeNoChangeFG.TYP.translateBottom && UserScopeNoChangeFG.TYP.translateMS
        // 由两个 FG 控制是否走新样式翻译
        // doc1.0 没有新样式，走老样式
        if (translateFG || (self.isVC && UserScopeNoChangeFG.TYP.translateMS)) && self.docsInfo.inherentType == .docX {
            return MoreItem(type: .translated(title),
                            style: .mButton(title: BundleI18n.SKResource.LarkCCM_Docs_MagicShare_TranslateSwitch_Button),
                            newTagInfo: (true, docsInfo.type, docsInfo.isOwner, nil)) { () -> Bool in
                self.canShowNewTranslate()
            } prepareEnable: { () -> Bool in
                self.canClickTranslate()
            } handler: { [weak self] (item, _, style) in
                guard let self = self else { return }
                guard item.state.isEnable else {
                    self.handleDisableEvent(.translated(title))
                    return
                }
                if let style = style {
                    switch style {
                    case .left:
                        self.callFunction(DocsJSCallBack.translateClickAction,
                                     params: ["target_key": titleKey], completion: nil)
                    case .right:
                        self.callFunction(DocsJSCallBack.translateClickAction,
                                     params: ["target_key": ""], completion: nil)
                    }
                } else {
                    self.callFunction(DocsJSCallBack.translateClickAction,
                                 params: ["target_key": ""], completion: nil)
                }
                CCMKeyValue.globalUserDefault.set(true, forKey: UserDefaultKeys.hasClickMoreViewTranslateBtn)
            }
        } else {
            return MoreItem(type: .translate,
                            newTagInfo: (true, docsInfo.type, docsInfo.isOwner, nil)) { () -> Bool in
                    guard docsInfo.isEnableTranslate ?? false else {
                        return false
                    }
                    guard !isVC else {
                        return false
                    }
                    if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
                        guard case let .success(container) = permissionService.containerResponse else {
                            return false
                        }
                        return !container.previewBlockByAdmin
                    } else {
                        return userPermissions?.adminBlocked() == false
                    }
                } prepareEnable: { () -> Bool in
                    DocsNetStateMonitor.shared.isReachable
                } handler: { [weak self] (item, _) in
                    guard let self = self else { return }
                    guard item.state.isEnable else {
                        self.handleDisableEvent(.addTo)
                        return
                    }
                    CCMKeyValue.globalUserDefault.set(true, forKey: UserDefaultKeys.hasClickMoreViewTranslateBtn)
                    self.callFunction(DocsJSCallBack.translateClickAction,
                                 params: nil, completion: nil)
                }
        }

    }

    override var searchReplace: MoreItem? {
        // 旧逻辑中只有sheet有红点
        return MoreItem(type: .searchReplace,
                        newTagInfo: (self.docsInfo.type == .sheet, docsInfo.type, docsInfo.isOwner, nil)) {
            if self.docsInfo.type == .docX, !LKFeatureGating.docxSearchEnable {
                return false
            }
            if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
                guard case let .success(container) = permissionService.containerResponse else {
                    return false
                }
                return !container.previewBlockByAdmin
            } else {
                return userPermissions?.adminBlocked() == false
            }
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            guard item.state.isEnable else {
                let disableByWeb = self.outsideControlItems?[.disable]?.contains(.searchReplace) ?? false
                DocsLogger.info("search item is disable, by Web:\(disableByWeb)")
                return
            }
            self._showSearchPanel.onNext(())
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
            if self.docsInfo.type == .docX, !LKFeatureGating.docxHistoryEnable {
                return false
            }
            if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
                guard case let .success(container) = permissionService.containerResponse else {
                    return false
                }
                return !container.previewBlockByAdmin
            } else {
                return userPermissions?.adminBlocked() == false
            }
        } prepareEnable: { [self] () -> Bool in
            if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
                guard DocsNetStateMonitor.shared.isReachable else { return false }
                guard permissionService.validate(operation: .edit).allow else { return false }
                guard case let .success(container) = permissionService.containerResponse else {
                    return false
                }
                return !container.previewBlockByAdmin
            } else {
                return self.hasEditPermission()
                && (self.userPermissions?.adminBlocked() == false)
                && DocsNetStateMonitor.shared.isReachable
            }
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            
            self.reportClickHistory()
            guard item.state.isEnable else {
                self.showTips(with: BundleI18n.SKResource.Doc_Facade_MoreHistoryTips)
                return
            }
            self._historyRecordAction.onNext(())
        }
    }
    
    // 已存版本列表
    override var savedVersionList: MoreItem? {
        MoreItem(type: .savedVersionList, newTagInfo: (true, docsInfo.type, docsInfo.isOwner, nil), hasSubPage: true) { () -> Bool in
            guard !self.isVC else {
                return false
            }
            guard docsInfo.inherentType.supportVersionInfo else {
                return false
            }
            return DocsVersionManager.shared.docsHasVersionData(token: self.docsInfo.token, type: self.docsInfo.inherentType)
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (_, _) in
            guard let self = self else { return }
            self._versionListAction.onNext(())
        }
    }

    override var catalog: MoreItem? {
        MoreItem(type: .catalog) { () -> Bool in
            let browserVC = hostViewController as? BrowserViewController
            return (!SKDisplay.pad || (browserVC?.needHidenCatalogInVesion() ?? false))
        } handler: { [weak self] (_, _) in
            self?._catalogAction.onNext(())
        }
    }

    var operationHistory: MoreItem? {
        // 只支持 wiki 2.0 或 space 2.0
        guard docsInfo.isFromWiki || docsInfo.isSingleContainerNode else { return nil }
        // 是支持新版文档信息的类型，且新文档信息面板 FG 开，不在 more 面板展示入口
        let newReadingPanelType = DocDetailInfoViewController.supportDocTypes
        if newReadingPanelType.contains(docsInfo.inherentType) {
            return nil
        }
        return MoreItem(type: .documentActivity,
                        handler: { [weak self] _, _ in
            self?._showOperationHistoryPanel.accept(())
        })
    }

    override func openCopyFileWith(_ fileUrl: URL, from: UIViewController) {
        let browser = EditorManager.shared.currentEditor
        if browser?.vcFollowDelegate == nil {
            Navigator.shared.push(fileUrl, from: from)
        } else {
            guard let browser = browser else { return }
            _ = EditorManager.shared.requiresOpen(browser, url: fileUrl)
        }
    }
    
    override var sourceDocs: MoreItem? {
        MoreItem(type: .openSourceDocs) { () -> Bool in
            true
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (_, _) in
            guard let self = self, let hostVC = self.hostViewController else { return }
            // 跳到原文档
            guard let shareUrl = self.docsInfo.shareUrl, !shareUrl.isEmpty else {
                DocsLogger.error("openSourceDocs url is nil")
                return
            }
            if var components = URLComponents(string: shareUrl) {
                components.query = nil // 移除所有参数
                let finalUrl = components.string
                if finalUrl != nil, let sourceURL = URL(string: finalUrl!) {
                    var browser = EditorManager.shared.currentEditor
                    if let broserVC = hostVC as? BrowserViewController {
                        browser = broserVC.editor
                    }
                    guard let browser = browser else { return }
                    _ = EditorManager.shared.requiresOpen(browser, url: sourceURL)
                }
            }
        }
    }

    override var saveAsTemplateV1: MoreItem? {
        let allowSaveAsTemplate: Bool
        let saveTemplateEnable: Bool
        let saveCompletion: () -> Void
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            let needDisabled: Bool
            (allowSaveAsTemplate, needDisabled, saveCompletion) = checkSaveAsTemplateEnable(failedTips: BundleI18n.SKResource.Doc_List_SaveCustomTemplFailed)
            saveTemplateEnable = !needDisabled
        } else {
            saveCompletion = {}
            allowSaveAsTemplate = saveAsTemplateEnable
            saveTemplateEnable = saveAsTemplateEnable
        }
        let needNewTag = allowSaveAsTemplate
        return MoreItem(type: .saveAsTemplate,
                        preventDismissal: saveTemplateEnable && !allowSaveAsTemplate,
                        newTagInfo: (needNewTag, docsInfo.type, docsInfo.isOwner, nil)) { () -> Bool in
            if docsInfo.isFromPhoenix {
                return false
            }
            if enableSaveAsCustomTemplateV1() {
                return !OpenAPI.enableTemplateTag(docsInfo: docsInfo)
            }
            return false
        } prepareEnable: { () -> Bool in
            saveTemplateEnable && DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            saveCompletion()
            if allowSaveAsTemplate {
                self.showInputNameAlertForTemplate()
                return
            }
            if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation { return }
            if !DocsNetStateMonitor.shared.isReachable || !self.validateResult(type: .saveAsTemplate).allow {
                self.handleDisableEvent(.saveAsTemplate)
                return
            }
            if self.outsideControlItems?[.disable]?.contains(.saveAsTemplate) == true { // 说明是前端控制置灰的，目前只有 bitable 前端会控制这个置灰
                self.showTips(with: BundleI18n.SKResource.Bitable_AdvancedPermission_UnableToSaveAsTemplate)
            } else {
                self.showTips(with: BundleI18n.SKResource.Doc_List_SaveCustomTemplFailed)
            }
        }
    }

    func reload() {
        if let updater = self.updater {
            updater(self.builder)
        }
    }
    
    override var changeTemplateTag: MoreItem? {
        let allowSaveAsTemplate: Bool
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            (allowSaveAsTemplate, _, _) = checkSaveAsTemplateEnable(failedTips: BundleI18n.SKResource.Doc_List_SaveCustomTemplFailed)
        } else {
            allowSaveAsTemplate = saveAsTemplateEnable
        }
        let needNewTag = allowSaveAsTemplate
        let isUgcTemplate = self.docsInfo.templateType == .ugcTemplate
        return MoreItem(type: .switchToTemplate, style: .mSwitch(isOn: isUgcTemplate, needLoading: true), newTagInfo: (needNewTag, docsInfo.type, docsInfo.isOwner, nil)) { [weak self] () -> Bool in
            guard let self = self, self.docsInfo.templateType != nil else { return false }
            if self.docsInfo.isFromPhoenix {
                return false
            }
            if self.enableSaveAsCustomTemplateV1() && self.docsInfo.inherentType.isSupportSaveAsTemplate {
                let hasPermission: Bool
                if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
                    hasPermission = permissionService.validate(operation: .manageContainerPermissionMeta).allow
                } else {
                    hasPermission = self.userPermissions?.canManageMeta() ?? false
                }
                return OpenAPI.enableTemplateTag(docsInfo: self.docsInfo) && hasPermission
            }
            return false
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (_, _) in
            guard let self = self else { return }
            guard DocsNetStateMonitor.shared.isReachable else {
                self.reload()
                return
            }
            guard let hostVC = self.hostViewController else { return }
            if self.docsInfo.templateType == .ugcTemplate {
                self.handleDeleteTemplateTag(docsInfo: self.docsInfo, hostVC: hostVC)
            } else {
                self.handleAddTemplateTag(name: self.docsInfo.title ?? "", hostVC: hostVC, docsInfo: self.docsInfo)
            }
            
        }
    }
    
    override public var saveAsTemplateV2: MoreItem? {
        let allowSaveAsTemplate: Bool
        let itemEnable: Bool
        let saveCompletion: () -> Void
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            let needDisabled: Bool
            (allowSaveAsTemplate, needDisabled, saveCompletion) = checkSaveAsTemplateEnable(failedTips: BundleI18n.SKResource.LarkCCM_Perms_SaveTemplateFail_NoCopyPerm_Toast)
            itemEnable = !needDisabled
        } else {
            saveCompletion = {}
            allowSaveAsTemplate = saveAsTemplateEnable
            itemEnable = allowSaveAsTemplate
        }
        let needNewTag = allowSaveAsTemplate
        return MoreItem(type: .saveAsTemplate,
                        preventDismissal: itemEnable && !allowSaveAsTemplate,
                        newTagInfo: (needNewTag, docsInfo.type, docsInfo.isOwner, nil)) { () -> Bool in
            if docsInfo.isFromPhoenix {
                return false
            }
            if enableSaveAsCustomTemplateV1() {
                let hasPermission: Bool
                if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
                    hasPermission = permissionService.validate(operation: .manageContainerPermissionMeta).allow
                } else {
                    hasPermission = self.userPermissions?.canManageMeta() ?? false
                }
                return OpenAPI.enableTemplateTag(docsInfo: docsInfo) && !hasPermission
            }
            return false
        } prepareEnable: { () -> Bool in
            itemEnable && DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            saveCompletion()
            if allowSaveAsTemplate {
                self.handleSaveMyTemplate()
                return
            }
            if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation { return }
            if !DocsNetStateMonitor.shared.isReachable || !self.validateResult(type: .saveAsTemplate).allow {
                self.handleDisableEvent(.saveAsTemplate)
                return
            }

            if self.outsideControlItems?[.disable]?.contains(.saveAsTemplate) == true { // 说明是前端控制置灰的，目前只有 bitable 前端会控制这个置灰
                self.showTips(with: BundleI18n.SKResource.Bitable_AdvancedPermission_UnableToSaveAsTemplate)
            } else {
                self.showTips(with: BundleI18n.SKResource.LarkCCM_Perms_SaveTemplateFail_NoCopyPerm_Toast)
            }
        }
    }

    private func canExportDocument() -> Bool {
        //判断是否要添加导出Word/PDF action
        var canExportDocument = self.userPermissions?.canExport() ?? false
        if self.docsInfo.inherentType.isSupportExport == false {
            canExportDocument = false
        }
        return canExportDocument
    }

    override var exportDocument: MoreItem? {
        let exportSupported = docsInfo.inherentType.isSupportExport

        let allowExport: Bool
        let exportVisable: Bool
        let itemEnable: Bool
        let exportCompletion: () -> Void
        let canEdit: Bool
        let adminBlocked: Bool
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            let response = permissionService.validate(operation: .export)
            allowExport = response.allow
            exportVisable = !response.result.needHidden
            itemEnable = !response.result.needDisabled
            let message: String
            if let disableItems = outsideControlItems?[State.disable],
               disableItems.contains(.exportDocument) {
                message = BundleI18n.SKResource.Doc_Export_CantExport_Empty
            } else {
                message = BundleI18n.SKResource.Doc_Document_ExportNoPermission
            }
            exportCompletion = { [weak self] in
                guard let self, let hostController = self.hostViewController else { return }
                response.didTriggerOperation(controller: hostController,
                                             message)
                if response.allow, !DocsNetStateMonitor.shared.isReachable {
                    self.handleDisableEvent(.exportDocument)
                }
            }
            canEdit = permissionService.validate(operation: .edit).allow
            adminBlocked = permissionService.containerResponse?.container?.previewBlockByAdmin ?? false
        } else {
            exportVisable = true
            (canEdit, adminBlocked) = self.canEdit(docsInfo.objToken)
            exportCompletion = {}
            let validateResult = validateResult(type: .exportDocument)
            allowExport = canExportDocument() && validateResult.allow
            itemEnable = allowExport
        }

        return MoreItem(type: .exportDocument,
                        preventDismissal: itemEnable && !allowExport,
                        newTagInfo: (true, docsInfo.type, docsInfo.isOwner, self.outsideControlBadges)) { () -> Bool in
            if docsInfo.type == .docX, !LKFeatureGating.docxExportEnabled {
                return false
            }
            return exportSupported && exportVisable
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable && itemEnable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            exportCompletion()
            if allowExport {
                if self.docsInfo.inherentType == .sheet {
                    self.callFunction(DocsJSCallBack.sheetClickExport, params: ["id": "exportPanel"], completion: nil)
                }
                self._showExportPanel.onNext((canEdit, adminBlocked))
                return
            }

            if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                return
            }

            if !DocsNetStateMonitor.shared.isReachable || !allowExport {
                self.handleDisableEvent(.exportDocument)
                return
            }

            if let disableItems = self.outsideControlItems?[State.disable],
               disableItems.contains(.exportDocument) {
                self.showTips(with: BundleI18n.SKResource.Doc_Export_CantExport_Empty)
                return
            }
        }
    }

    override var rename: MoreItem? {
        let canEdit: Bool
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            canEdit = permissionService.validate(operation: .edit).allow
        } else {
            canEdit = hasEditPermission()
        }
        return MoreItem(type: .rename) { () -> Bool in
            true
        } prepareEnable: { () -> Bool in
            canEdit && DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            guard DocsNetStateMonitor.shared.isReachable else {
                self.handleDisableEvent(.rename)
                return
            }
            guard item.state.isEnable else {
                // TODO: 切换到 permissionSDK callback
                var fileType = ""
                switch self.docsInfo.inherentType {
                case .sheet:
                    fileType = BundleI18n.SKResource.Doc_Facade_MoreRenameTypeSheet
                case .bitable:
                    fileType = BundleI18n.SKResource.Doc_Facade_MoreRenameTypeBitable
                case .slides:
                    fileType = BundleI18n.SKResource.LarkCCM_Slides_ProductName
                default:
                    fileType = ""
                }
                let tip = BundleI18n.SKResource.Doc_Facade_MoreRenameTips(fileType)
                self.showTips(with: tip)
                return
            }
            self._showRenamePanel.onNext(())
        }
    }

    private func hasRenameVersionPermission() -> Bool {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            guard let versionPermissionService else {
                return false
            }
            return versionPermissionService.validate(operation: .manageVersion).allow
        } else {
            guard let permissionsLo = versionPermissions else {
                return false
            }
            return permissionsLo.canRenameVersion()
        }
    }
    
    override var renameVersion: MoreItem? {
        MoreItem(type: .renameVersion) { () -> Bool in
            self.hasRenameVersionPermission()
        } prepareEnable: { [weak self] () -> Bool in
            guard let self = self else { return false }
            // 密级强制打标需求，当FA用户被admin设置强制打标时，不可重命名版本
            let isForcibleSL = SecretBannerCreater.checkForcibleSL(canManageMeta: self.userPermissions?.isFA ?? false,
                                                                   level: self.docsInfo.secLabel)
            return DocsNetStateMonitor.shared.isReachable && !isForcibleSL
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            guard DocsNetStateMonitor.shared.isReachable else {
                self.handleDisableEvent(.rename)
                return
            }
            guard item.state.isEnable else {
                let isForcibleSL = SecretBannerCreater.checkForcibleSL(canManageMeta: self.userPermissions?.isFA ?? false, level: self.docsInfo.secLabel)
                if isForcibleSL {
                    self._showForcibleWarning.accept(())
                } else {
                    var fileType = ""
                    switch self.docsInfo.inherentType {
                    case .sheet:
                        fileType = BundleI18n.SKResource.Doc_Facade_MoreRenameTypeSheet
                    case .bitable:
                        fileType = BundleI18n.SKResource.Doc_Facade_MoreRenameTypeBitable
                    default:
                        fileType = ""
                    }
                    let tip = BundleI18n.SKResource.Doc_Facade_MoreRenameTips(fileType)
                    self.showTips(with: tip)
                }
                return
            }
            self._showRenamePanel.onNext(())
        }
    }

    private func hasDeleteVersionPermission() -> Bool {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            guard let versionPermissionService else {
                return false
            }
            return versionPermissionService.validate(operation: .deleteVersion).allow
        } else {
            guard let permissionsLo = versionPermissions else {
                return false
            }
            return permissionsLo.canDeleteVersion()
        }
    }
    // 删除版本
    override var deleteVersion: MoreItem? {
        MoreItem(type: .deleteVersion) {
            self.hasDeleteVersionPermission()
        } prepareEnable: { [weak self] () -> Bool in
            guard let self = self else { return false }
            // 密级强制打标需求，当FA用户被admin设置强制打标时，不可删除版本
            let isForcibleSL = SecretBannerCreater.checkForcibleSL(canManageMeta: self.userPermissions?.isFA ?? false,
                                                                   level: self.docsInfo.secLabel)
            return DocsNetStateMonitor.shared.isReachable && !isForcibleSL
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            guard item.state.isEnable else {
                let isForcibleSL = SecretBannerCreater.checkForcibleSL(canManageMeta: self.userPermissions?.isFA ?? false, level: self.docsInfo.secLabel)
                if isForcibleSL {
                    self._showForcibleWarning.accept(())
                } else {
                    self.handleDisableEvent(.delete)
                }
                return
            }
            let name = self.docsInfo.versionInfo?.name ?? ""
            self.reportClickDeleteFile()
            let (title, content) = (BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_DeleteV_Confirm(name),
                                                 BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_DeleteV_Note)
            let dialog = UDDialog()
            dialog.setTitle(text: title, checkButton: false)
            dialog.setContent(text: content, checkButton: false)
            dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCheck: { () -> Bool in
                self.reportClickDeleteVersion(type: "cancel")
                return true
            })
            dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_Facade_Delete, dismissCheck: {
                self.reportClickDeleteVersion(type: "delete")
                self.deleteCurrentVersion()
                return true
            })
            guard let hostVC = self.hostViewController else { return }
            Navigator.shared.present(dialog, from: hostVC, animated: true)
            self.reportDeleteVersion()
        }
    }
    
    override var timeZone: MoreItem? {
        MoreItem(type: .timeZone) { () -> Bool in
            if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
                guard permissionService.validate(operation: .updateTimeZone).allow else { return false }
                return true
            } else {
                guard userPermissions?.canPreview() == true else { return false }
                let isFullAccess = userPermissions?.canManageMeta() ?? false
                return isFullAccess
            }
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (_, _) in
            guard let self = self else { return }
            guard DocsNetStateMonitor.shared.isReachable else {
                self.handleDisableEvent(.timeZone)
                return
            }
            self._showTimeZoneSetting.accept(())
        }
    }
    
    public override var workbench: MoreItem? {
        let itemType: MoreItemType = itemAsyncGetStatusFlags.isWorkbenchAdded ? .workbenchAdded : .workbenchNormal
        return MoreItem(type: itemType) {
            UserScopeNoChangeFG.ZSY.workbench
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(itemType)
                return
            }
            self._workbenchAction.onNext(item.type == .workbenchNormal)
        }
    }
    
    // 解除关联文档
    open var unassociateDoc: MoreItem? {
        MoreItem(type: .unassociateDoc) {
            guard let webBrowser = self.model?.jsEngine as? WebBrowserView,
                  let associateAppUrl = webBrowser.fileConfig?.associateAppUrl,
                  !associateAppUrl.isEmpty else {
                return false
            }
            return true

        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (_, _) in
            guard let self = self else { return }
            guard let hostVC = self.hostViewController else { return }
            guard let docsInfo = self.model?.hostBrowserInfo.docsInfo else {
                return
            }
            
            guard let webBrowser = self.model?.jsEngine as? WebBrowserView else {
                DocsLogger.info("UtilMoreDataProvider, get webBrowser nil", component: LogComponents.associateApp)
                return
            }
            
            DocPluginForWebService.showTipAndDeleteReference(appUrl: webBrowser.fileConfig?.associateAppUrl, 
                                                             urlMetaId: webBrowser.fileConfig?.associateAppUrlMetaId,
                                                             hostVC: hostVC,
                                                             docList: [(docToken: docsInfo.objToken, docType: docsInfo.type)]) { isSuccess, error in
                DocsLogger.info("UtilMoreDataProvider, deleteReference isSuccess:\(isSuccess) , error: \(String(describing: error))", component: LogComponents.associateApp)
            }
        }
    }
}

// MARK: - Action
extension UtilMoreDataProvider {
    func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {
        model?.jsEngine.callFunction(function, params: params, completion: { (_, error) in
            guard error == nil else {
                DocsLogger.error(String(describing: error))
                return
            }
        })
    }
    
    private func canClickTranslate() -> Bool {
        if !DocsNetStateMonitor.shared.isReachable {
            return false
        }
        if self.followAPIDelegate?.followRole == .presenter {
            return false
        }
        return true
    }
    
    //
    private func canShowNewTranslate() -> Bool {
        guard docsInfo.isEnableTranslate ?? false else {
            return false
        }
        guard (!self.isVC || UserScopeNoChangeFG.TYP.translateMS) else {
            return false
        }
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            guard case let .success(container) = permissionService.containerResponse else {
                return false
            }
            return !container.previewBlockByAdmin
        } else {
            return userPermissions?.adminBlocked() == false
        }
    }
    
    private func getTranslateLanguage() -> String {
        // 优先用前端设置的翻译语言文案
        if let languageTitle = docsInfo.translationContext?.targetLanguageTitle {
            return languageTitle
        }
        guard let translateService = try? Container.shared.resolve(assert: CCMTranslateService.self) else { return ""}
        return translateService.targetLanguage ?? ""
    }
    
    private func getTranslateLanguageKey() -> String {
        // 优先用前端设置的翻译语言
        if let languageKey = docsInfo.translationContext?.targetLanguage {
            return languageKey
        }
        guard let translateService = try? Container.shared.resolve(assert: CCMTranslateService.self) else { return ""}
        return translateService.targetLanguageKey ?? ""
    }

    // 全宽高模式判断
    private var isFullWidth: Bool {
        guard let mode = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.widescreenModeLastSelected), mode.count > 0 else {
            return true //默认值为true
        }
        return mode == WidescreenMode.fullwidth.rawValue ? true : false
    }
}

private extension BitableBridgeData {
    var moreItemStyle: MoreStyle {
        guard UserScopeNoChangeFG.ZYS.baseAdPermRoleInheritance else {
            return .normal
        }
        if isPro {
            return .rightLabel(title: BundleI18n.SKResource.Bitable_AdvancedPermissions_Mobile_TurnedOn_Text)
        } else {
            return .normal
        }
    }
}
