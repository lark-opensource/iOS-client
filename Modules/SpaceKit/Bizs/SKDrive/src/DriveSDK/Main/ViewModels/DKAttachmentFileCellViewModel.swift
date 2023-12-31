//
//  DKAttachmentFileCellViewModel.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/6/16.
//
//
//swiftlint:disable file_length

import Foundation
import SKFoundation
import SKInfra
import SpaceInterface
import RxSwift
import RxRelay
import RxCocoa
import SKCommon
import SKResource
import SKUIKit
import SwiftyJSON
import UniverseDesignEmpty
import LarkDocsIcon
import EENavigator

extension DriveSDKAttachmentFile {
    var fileMeta: DriveFileMeta {
        let fileName = name ?? ""
        return DriveFileMeta(size: 0,
                             name: fileName,
                             type: fileType ?? SKFilePath.getFileExtension(from: fileName) ?? "",
                             fileToken: fileToken,
                             mountNodeToken: mountNodePoint ?? "",
                             mountPoint: mountPoint,
                             version: version,
                             dataVersion: dataVersion,
                             source: .other,
                             tenantID: nil,
                             authExtra: authExtra)
    }
}

protocol DKAttachmentFileDependency {
    var appID: String { get }
    var file: DriveSDKAttachmentFile { get }
    // 提供缓存服务的能力
    var cacheService: DKCacheServiceProtocol { get }
    // 权限服务(第三方附件和Docs附件权限实现不同)
    var permissionHelper: DrivePermissionHelperProtocol { get }
    // 更多菜单的配置
    var moreConfiguration: DriveSDKMoreDependency { get }
    // 终止预览的信号
    var actionProvider: DriveSDKActionDependency { get }
    // statistics
    var statistics: DKStatisticsService { get }
    // 性能埋点
    var performanceRecorder: DrivePerformanceRecorder { get }
    // vcFollow中
    var isInVCFollow: Bool { get }
    // 是否支持转为在线文档
    var canImportAsOnlineFile: Bool { get }
}

//swiftlint:disable type_body_length
class DKAttachmentFileCellViewModel: NSObject, DKFileCellViewModelType, DKHostModuleType {
    
    var pdfInlineAIAction: PublishRelay<DKPDFInlineAIAction>? = .init()
    var pdfAIBridge: RxRelay.BehaviorRelay<Int>? = BehaviorRelay<Int>.init(value: 0)
    
    typealias Dependency = DKAttachmentFileDependency
    // 流量弹窗需要一个fromVC
    private weak var hostContainer: UIViewController?
    
    private let processQueue: DispatchQueue = DispatchQueue(label: "DKAttachmentFileCellViewModel.filePreview")
    private let appID: String
    private let file: DriveSDKAttachmentFile
    let cacheService: DKCacheServiceProtocol
    private let permissionHelper: DrivePermissionHelperProtocol
    var permissionService: UserPermissionService { permissionHelper.permissionService }
    var netManager: DrivePreviewNetManagerProtocol
    private let fileInfoProcessorProvider: FileInfoProcessorProvider
    private var fileInfoProcessor: FileInfoProcessor?
    private var fileInfoLoader: DKFileInfoLoader<DriveFileInfo, DriveFileInfoProvider>?
    private let canImportAsOnlineFile: Bool
    private let moreConfiguration: DriveSDKMoreDependency
    private let docsInfo: DocsInfo
    private let previewFrom: DrivePreviewFrom
    private let rustNetStatus = DocsContainer.shared.resolve(DocsRustNetStatusService.self)!
    private let blockByAdminSignal = PublishRelay<Void>()
    private var request: DocsRequest<JSON>?
    
    private var ifBlockedByCAC: Bool = false

    let isInVCFollow: Bool
    var title: String {
        return fileInfo.name
    }
    
    var previewFromScene: DrivePreviewFrom {
        return previewFrom
    }
    
    var objToken: String {
        return fileInfo.fileToken
    }
    var hostModule: DKHostModuleType? {
        return self
    }
    // 区分预览场景，云空间和附件
    let scene: DKPreviewScene
    private var isAttachment: Bool { scene == .attach }
    var urlForSuspendable: String? {
        return file.urlForSuspendable
    }
    
    var hostToken: String? {
        return commonContext.hostToken
    }
    var windowSizeDependency: WindowSizeProtocol? {
        return hostContainer as? WindowSizeProtocol
    }
    
    // MARK: - DKHostModuleType
    var subModuleManager = DriveSubModuleManager()
    var hostController: DKSubModleHostVC? {
        return hostContainer as? DKSubModleHostVC
    }
    var cacManager: CACManagerBridge.Type = CACManager.self
    let fileInfoRelay: BehaviorRelay<DriveFileInfo>
    private let fileInfoError = PublishRelay<DriveError?>()
    var fileInfoErrorOb: Observable<DriveError?> {
        return fileInfoError.catchErrorJustReturn(nil)
    }
    let docsInfoRelay: BehaviorRelay<DocsInfo>
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    let permissionRelay: BehaviorRelay<DrivePermissionInfo>
    var canReadAndCanCopy: Observable<(Bool, Bool)>? {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let isAttachment = self.isAttachment
            return Observable.merge(
                permissionService.onPermissionUpdated,
                permissionService.offlinePermission
            ).map { [weak permissionService] _ in
                guard let permissionService else {
                    return (false, false)
                }
                let canRead = permissionService.validate(operation: .view).allow
                let canCopy = permissionService.validate(operation: .copyContent).allow
                return (canRead, canCopy)
            }
        } else {
            // 跳过初始值
            return permissionRelay.skip(1)
                .asObservable().map { ($0.isReadable, $0.canCopy) }
        }
    }
    // admin设置预览管控时，用于重置previewBag的信号
    private let resetPreviewBagAction = PublishSubject<Void>()
    weak var commentManager: DriveCommentManager?
    var commonContext: DKSpacePreviewContext
    var moreDependency: DriveSDKMoreDependency {
        return moreConfiguration
    }
    var openFileSuccessType: DriveOpenType?
    // 额外的上报参数
    var additionalStatisticParameters: [String: String] {
        return statisticsService.additionalParameters
    }
    // 子模块之间通过actionsCenter传递事件
    let subModuleActionsCenter = PublishRelay<DKSubModuleAction>()
    // 文件类型，用于判断是否支持多文件预览
    var fileType: DriveFileType {
        return fileInfo.fileType
    }
    
    var fileID: String {
        return file.fileToken
    }

    var fileInfo: DriveFileInfo {
        didSet {
            updatePerfomanceRecorder(fileInfo: fileInfo)
            fileInfoRelay.accept(fileInfo)
        }
    }
    
    private var stage: DKFileStage = .initial {
        didSet {
            DocsLogger.driveInfo("DKAttachmentFileCellViewModel --- stage changed", extraInfo: ["from": oldValue, "to": stage])
        }
    }

    /// 仅用于绑定外部事件，如退出预览、停止预览
    private let actionBag = DisposeBag()
    /// 用于内部事件的绑定，当收到外部停止预览事件时，会被重置
    private var disposeBag = DisposeBag() {
        didSet {
            // 连带重置一下
            previewBag = DisposeBag()
        }
    }
    /// 与预览流程相关的事件绑定，如 FileInfoLoader、PreviewVM，当收到 admin 禁止预览事件时，会被重置
    private var previewBag = DisposeBag()
    // 权限信息
    private var permissionInfo: DrivePermissionInfo = DrivePermissionInfo(isReadable: true,
                                                                          isEditable: false,
                                                                          canComment: false,
                                                                          canExport: false,
                                                                          canCopy: false,
                                                                          canShowCollaboratorInfo: false,
                                                                          isCACBlock: false,
                                                                          permissionStatusCode: nil,
                                                                          userPermissions: nil)
    private var permissionStatusCode = UserPermissionResponse.StatusCode.normal
    /// 缓存当前是否是可预览状态，仅用于权限变化时判断是否需要重新加载，其他场景请直接通过 permissionService 现查
    private var permissionCanView = true

    let naviBarViewModel = ReplaySubject<DKNaviBarViewModel>.create(bufferSize: 1)
    // 业务埋点
    let statisticsService: DKStatisticsService
    // 性能埋点
    let performanceRecorder: DrivePerformanceRecorder
    // 是否需要展示水印
    var shouldShowWatermark: Bool {
        return docsInfo.shouldShowWatermark
    }
    // 触发动作
    // 上一个action,用于多文件切换时，重新绑定，判断是否需要emit上一次的action
    // 如果之前emit了exitPreview,在绑定时需要重放。
    var preAction: DKPreviewAction?
    let previewActionSubject = ReplaySubject<DKPreviewAction>.create(bufferSize: 0)
    var previewAction: Observable<DKPreviewAction> {
        previewActionSubject.asObservable().do(onNext: {[weak self] (action) in
            self?.preAction = action
            self?.reportPreviewFailed(action: action)
        }, onSubscribed: { [weak self] in
            if case .exitPreview = self?.preAction {
                DocsLogger.driveInfo("DKAttachmentFileCellViewModel -- relay preAction when subscribe")
                self?.previewActionSubject.onNext(.exitPreview)
            }
        })
    }

    /// 预览状态更新
    private let previewStateRelay = ReplaySubject<DKFilePreviewState>.create(bufferSize: 0)
    var previewStateUpdated: Driver<DKFilePreviewState> {
        previewStateRelay.asDriver(onErrorJustReturn: .setupFailed(data: DKPreviewFailedViewData.defaultData())).do(onNext: {[weak self] state in
            guard let self = self else { return }
            switch state {
            case .setupFailed, .setupUnsupport, .noPermission:
                self.previewActionSubject.onNext(.openFailed)
            default:
                break
            }
        })
    }
    var currentDisplayMode: DrivePreviewMode {
        return displayMode
    }
    var isFromCardMode: Bool = false
    private var displayMode: DrivePreviewMode = .normal {
        didSet {
            if displayMode == .card {
                isFromCardMode = true
            }
        }
    }
    
    private var canOpenWithOtherApp = BehaviorRelay<Bool>(value: false)

    /// 网络状态
    private let reachabilityRelay: BehaviorRelay<Bool>
    var reachabilityChanged: Observable<Bool> {
        return reachabilityRelay.asObservable()
    }
    var isReachable: Bool {
        return reachabilityRelay.value
    }
    
    private var shouldShowDeleteFailedView: Bool = true
    
    deinit {
        statisticsService.exitPreview()
        DocsLogger.driveInfo("DKAttachmentFileCellViewModel -- deinit")
    }

    init(dependency: Dependency, previewFrom: DrivePreviewFrom, commonContext: DKSpacePreviewContext, scene: DKPreviewScene) {
        self.scene = scene
        appID = dependency.appID
        file = dependency.file
        cacheService = dependency.cacheService
        permissionHelper = dependency.permissionHelper
        statisticsService = dependency.statistics
        performanceRecorder = dependency.performanceRecorder
        isInVCFollow = dependency.isInVCFollow
        canImportAsOnlineFile = dependency.canImportAsOnlineFile
        reachabilityRelay = BehaviorRelay<Bool>(value: DocsNetStateMonitor.shared.isReachable)
        fileInfoProcessorProvider = DefaultFileInfoProcessorProvider(cacheService: cacheService, performanceLogger: performanceRecorder)
        // 创建fileInfo基本信息，同时从缓存更新缓存的fileInfo信息
        self.fileInfo = DriveFileInfo(fileMeta: file.fileMeta)
        self.fileInfo.updateFromCacheIfExist()
        self.fileInfoRelay = BehaviorRelay<DriveFileInfo>(value: fileInfo)
        netManager = DrivePreviewNetManager(performanceRecorder, fileInfo: fileInfo)
        self.moreConfiguration = dependency.moreConfiguration
        self.docsInfo = DocsInfo(type: .file, objToken: file.fileToken)
        self.docsInfoRelay = BehaviorRelay<DocsInfo>(value: docsInfo)
        self.permissionRelay = BehaviorRelay<DrivePermissionInfo>(value: permissionInfo)
        self.previewFrom = previewFrom
        self.commonContext = commonContext
        super.init()
        setupExternalAction(actionProvider: dependency.actionProvider)
    }
    
    private func setupSubModuleMonitor() {
        subModuleActionsCenter.subscribe(onNext: {[weak self] event in
            switch event {
            case let .updateNaviBar(vm):
                self?.naviBarViewModel.onNext(vm)
            case let .didSetupCommentManager(manager):
                self?.commentManager = manager
            case .stopDownload:
                self?.fileInfoLoader?.stopDownload()
            case let .refreshVersion(version):
                // 刷新版本前清空额外增加的航栏按钮，避免新版本类型不一致有残留按钮(比如演示模式按钮)
                self?.update(additionLeftBarItems: [], additionRightBarItems: [])
                self?.refreshVersion(version)
            case .fileDidDeleted:
                // 文件被删除清空按钮
                self?.update(additionLeftBarItems: [], additionRightBarItems: [])
                self?.handleFileDeletedRouter()
            case let .wikiNodeDeletedStatus(isDelete):
                if isDelete {
                    self?.update(additionLeftBarItems: [], additionRightBarItems: [])
                    self?.handleFileDeletedRouter()
                }
            default:
                break
            }
        }).disposed(by: disposeBag)
    }

    private func setupFileInfoLoader(hostContainer: UIViewController) {
        let preferPreview = DriveFileInfoProcessorConfig.preferPreview(fileType: fileInfo.fileType, previewFrom: previewFrom, isInVCFollow: isInVCFollow)
        let cacheSource: DriveCacheService.Source = (previewFrom == .history) ? .history : .standard
        let config = DriveFileInfoProcessorConfig(isIMFile: false,
                                                  isIMFileEncrypted: false,
                                                  preferPreview: preferPreview,
                                                  authExtra: file.authExtra,
                                                  cacheSource: cacheSource,
                                                  previewFrom: previewFrom,
                                                  isInVCFollow: isInVCFollow,
                                                  appID: appID, scene: scene)
        netManager = DrivePreviewNetManager(performanceRecorder, fileInfo: fileInfo)
        let showInRecent = (scene == .space)
        let fileInfoProvider = DriveFileInfoProvider(netManager: netManager, showInfRecent: showInRecent)
        let loader = DKFileInfoLoader(fileInfo: fileInfo,
                                     isLatest: true,
                                     isInVCFollow: isInVCFollow,
                                     skipCellularCheck: isInVCFollow || isFromCardMode,
                                     fileInfoProvider: fileInfoProvider,
                                     fileInfoProcessorProvider: fileInfoProcessorProvider,
                                     processorConfig: config,
                                     cacheService: cacheService,
                                     statisticsService: statisticsService,
                                     performanceRecorder: performanceRecorder,
                                     hostContainer: hostContainer)
        self.fileInfoLoader = loader
        loader.state.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] state in
            self?.handleState(state)
        }).disposed(by: previewBag)
        loader.action.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] previewAction in
            self?.handle(previewAction: previewAction)
        }).disposed(by: previewBag)
    }
    
    func refreshVersion(_ version: String?) {
        if let ver = version {
            fileInfo.version = ver
        }
        fileInfoLoader?.fetchFileInfo(version: version)
    }
    
    // 开始加载文件
    func startPreview(hostContainer: UIViewController) {
        self.hostContainer = hostContainer
        guard case .initial = stage else {
            DocsLogger.driveError("drive.sdk.context.main --- mainVM not in initial stage : \(stage)")
            return
        }
        processQueue.async { [weak self] in
            guard let self = self else { return }
            self.statisticsService.enterPreview()
            self.disposeBag = DisposeBag()
            self.setupFileInfoLoader(hostContainer: hostContainer)
            self.fileInfoLoader?.start()
            self.setupPermissionMonitor()
            self.setupNetworkMonitor()
            if let listener = hostContainer as? WatermarkUpdateListener {
                self.docsInfo.requestWatermarkInfo()
                WatermarkManager.shared.addListener(listener)
            }
            self.setupSubModuleMonitor()
            self.subModuleManager.registerSubModules(secne: self.scene, hostModule: self)
        }
    }
    
    func willChangeMode(_ mode: DrivePreviewMode) {
        previewStateRelay.onNext(.willChangeMode(mode: mode))
    }
    
    func changingMode(_ mode: DrivePreviewMode) {
        previewStateRelay.onNext(.changingMode(mode: mode))
    }
    
    // 改变预览状态
    func didChangeMode(_ mode: DrivePreviewMode) {
        displayMode = mode
        previewStateRelay.onNext(.didChangeMode(mode: mode))
    }
    
    func update(additionLeftBarItems: [DriveNavBarItemData], additionRightBarItems: [DriveNavBarItemData]) {
        let leftNaviBarItems = additionLeftBarItems.compactMap { (barItemData) -> DKNaviBarItem? in
            guard let icon = barItemData.type.image, let action = barItemData.action else { return nil }
            let barItem = DKStandardNaviBarItem(naviBarButtonID: barItemData.type.skNaviBarButtonID, itemIcon: icon, isHighLighted: barItemData.isHighLighted) { () -> DKNaviBarItem.Action in
                barItemData.target?.perform(action)
                return .none
            }
            return barItem
        }
        let rightNaviBarItems = additionRightBarItems.compactMap { (barItemData) -> DKNaviBarItem? in
            guard let icon = barItemData.type.image, let action = barItemData.action else { return nil }
            let barItem = DKStandardNaviBarItem(naviBarButtonID: barItemData.type.skNaviBarButtonID, itemIcon: icon, isHighLighted: barItemData.isHighLighted) { () -> DKNaviBarItem.Action in
                barItemData.target?.perform(action)
                return .none
            }
            return barItem
        }
        subModuleActionsCenter.accept(.updateAdditionNavibarItem(leftItems: leftNaviBarItems, rightItems: rightNaviBarItems))
    }

    func handle(previewAction: DKPreviewAction) {
        previewActionSubject.onNext(previewAction)
    }
    
    func handleState(_ state: FileInfoState<DriveFileInfo>) {
        switch state {
        case let .startFetch(isAsycn):
            stage = isAsycn ? .asyncFetchingFileInfo : .fetchingFileInfo
            if !isAsycn {
                previewStateRelay.onNext(.loading)
            } else { // 异步请求，更新fileInfo
                previewActionSubject.onNext(.didFetchFileInfo(fileInfo: fileInfo))
            }
        case .storing:
            break
        case let .fetchFailed(error, isPreviewing):
            handleFileInfoFailed(error: error, isAsync: isPreviewing)
        case let .fetchSucc(info, isPreviewing):
            if isPreviewing {
                handleAsync(fileInfo: info)
            } else {
                updateFileInfo(info)
            }
            previewActionSubject.onNext(.didFetchFileInfo(fileInfo: info))
            fileInfoError.accept(nil)
        case .failedWithNoNet:
            handleNoNet()
        case let .startFetchPreview(info):
            startPreview(fileInfo: info)
        case let .showDownloading(fileType):
            previewStateRelay.onNext(.showDownloading(fileType: fileType))
        case let .downloading(progress):
            previewStateRelay.onNext(.downloading(progress: progress))
        case let .downloadFailed(msg, handler):
            let data = failedData(retryHandler: handler)
            previewStateRelay.onNext(.setupFailed(data: data))
            openFailed(type: .downloadFail(errorMessage: msg))
        case .downloadCompleted:
            previewStateRelay.onNext(.downloadCompleted)
        case let .preview(type, info):
            previewStateRelay.onNext(.setupPreview(type: type, info: info))
        case .downloadNoPermission:
            let data = failedData(retryHandler: {})
            previewStateRelay.onNext(.setupFailed(data: data))
        case let .unsupport(fileInfo, type):
            let unsupport = unsupportState(fileInfo: fileInfo, type: type)
            previewStateRelay.onNext(unsupport)
        case let .cacDenied(info):
            previewStateRelay.onNext(.noPermission(docsInfo: DocsInfo(type: .file, objToken: info.fileID), canRequestPermission: false, isFromPermissionAPI: true, isAdminBlocked: false, isShareControlByCAC: false, isPreviewControlByCAC: true, isViewBlockByAudit: false))
        }
    }
    
    func handleNoNet() {
        stage = .fetchFailed
        openFailed(type: .noNetwork)
        let failedData = DKPreviewFailedViewData(showRetryButton: true, retryEnable: reachabilityRelay, retryHandler: { [weak self] in
            guard let self = self else { return }
            self.stage = .fetchingFileInfo
            self.fileInfoLoader?.fetchFileInfo()
        }, showOpenWithOtherApp: canOpenWithOtherApp, openWithOtherEnable: reachabilityRelay, openWithOtherAppHandler: { [weak self] (sourceView, sourceRect) in
            self?.handleOpenWithOtherApp(sourceView: sourceView, sourceRect: sourceRect)
        })
        previewStateRelay.onNext(.setupFailed(data: failedData))
    }
    
    func updateFileInfo(_ fileInfo: DriveFileInfo) {
        self.fileInfo = fileInfo
        statisticsService.updateFileType(fileInfo.fileType)
    }
    
    // 用于兼容 drive 现有的预览异常处理
    func handleBizPreviewUnsupport(type: DriveUnsupportPreviewType) {
        previewStateRelay.onNext(unsupportState(fileInfo: fileInfo, type: type))
    }

    // 用于兼容 drive 现有的预览失败处理
    func handleBizPreviewFailed(canRetry: Bool) {
        let failedData: DKPreviewFailedViewData
        if canRetry, case let DKFileStage.onlinePreviewing(previewVM) = stage {
            failedData = DKPreviewFailedViewData(showRetryButton: true,
                                                 retryEnable: reachabilityRelay,
                                                 retryHandler: { [weak previewVM] in
                                                    previewVM?.input.fetchPreview.onNext(.normal)
                                                 },
                                                 showOpenWithOtherApp: canOpenWithOtherApp,
                                                 openWithOtherEnable: reachabilityRelay,
                                                 openWithOtherAppHandler: { [weak self] (sourceView, sourceRect) in
                                                    self?.handleOpenWithOtherApp(sourceView: sourceView, sourceRect: sourceRect)
                                                 })
        } else {
            failedData = DKPreviewFailedViewData(showRetryButton: false,
                                                 retryEnable: reachabilityRelay,
                                                 retryHandler: {},
                                                 showOpenWithOtherApp: canOpenWithOtherApp,
                                                 openWithOtherEnable: reachabilityRelay,
                                                 openWithOtherAppHandler: { [weak self] (sourceView, sourceRect) in
                                                    self?.handleOpenWithOtherApp(sourceView: sourceView, sourceRect: sourceRect)
            })
        }
        previewStateRelay.onNext(.setupFailed(data: failedData))
    }
    
    func handleBizPreviewDowngrade() {
        // 判断当前状态是否支持降级预览，避免无权限、被删除等场景时仍走入预览降级流程
        guard stage.canDowngradeStage else { return }
        if case let DKFileStage.onlinePreviewing(previewVM) = stage {
            previewVM.input.fetchPreview.onNext(.downgrade)
        } else {
            // 目前仅有 WPS 会进入降级在线转码预览
            startPreview(fileInfo: fileInfo)
        }
    }
    
    func handleOpenFileSuccessType(openType: DriveOpenType) {
        previewActionSubject.onNext(.openSuccess(openType: openType))
        self.openFileSuccessType = openType
        hostModule?.subModuleActionsCenter.accept(.openSuccess(openType: openType))
    }
    
    func reset() {
        stage = .initial
        disposeBag = DisposeBag()
        subModuleManager.unRegist()
        permissionHelper.unRegister()
        fileInfoLoader?.stopDownload()
    }

    /// 处理异步请求 FileInfo 的结果
    private func handleAsync(fileInfo: DriveFileInfo) {
        DocsLogger.driveInfo("drive.sdk.context.main --- handling async fileInfo")
        stage = .previewingCache
        updateFileInfo(fileInfo)
    }

    private func handleCommonError(_ error: Error, isAsync: Bool) {
        if isAsync {
            if displayMode != .card {
                DocsLogger.driveInfo("DKAttachmentFileCellViewModel -- file has cache and is in card mode do not show toast")
            } else {
                previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.Drive_Drive_GetFileInformationFail, type: .failure))
            }
        } else {
            let failedType: FailedType
            if let driveError = error as? DriveError, case let .serverError(code) = driveError {
                DocsLogger.driveInfo("DKAttachmentFileCellViewModel -- fetch fileinfo failed Server Error Code: \(code)")
                failedType = .fetchFileInfoFail(errorMessage: "Server Error Code: \(code)")
            } else {
                DocsLogger.driveInfo("DKAttachmentFileCellViewModel -- fetch fileinfo failed : \(error.localizedDescription)")
                failedType = .fetchFileInfoFail(errorMessage: error.localizedDescription)
            }
            openFailed(type: failedType)
            let failedData = DKPreviewFailedViewData(mainText: BundleI18n.SKResource.Drive_Drive_LoadingFail,
                                                     showRetryButton: true,
                                                     retryEnable: reachabilityRelay,
                                                     retryHandler: { [weak self] in
                                                        guard let self = self else { return }
                                                        self.stage = .fetchingFileInfo
                                                        self.fileInfoLoader?.fetchFileInfo()
                                                     },
                                                     showOpenWithOtherApp: canOpenWithOtherApp,
                                                     openWithOtherEnable: reachabilityRelay,
                                                     openWithOtherAppHandler: { [weak self] (sourceView, sourceRect) in
                                                        self?.handleOpenWithOtherApp(sourceView: sourceView, sourceRect: sourceRect)
                                                     })
            previewStateRelay.onNext(.setupFailed(data: failedData))
        }
    }
    /// 处理异步请求 FileInfo 的错误
    private func handleFileInfoFailed(error: Error, isAsync: Bool) {
        DocsLogger.error("drive.sdk.context.main --- fileInfo provider failed with error when async fetching")
        stage = isAsync ? .previewingCache : .fetchFailed
        guard let driveError = error as? DriveError else {
            handleCommonError(error, isAsync: isAsync)
            return
        }
        DocsLogger.error("drive.sdk.context.main --- async handle drive error", error: driveError)
        fileInfoError.accept(driveError)
        switch driveError {
        case let .blockByTNS(redirectURL):
            DocsLogger.error("drive.sdk.context.main --- redirect to tns H5 within drive from file info error")
            // 兜底按无权限处理
            let info = TNSRedirectInfo(meta: SpaceMeta(objToken: objToken, objType: .file),
                                       redirectURL: redirectURL,
                                       module: "file",
                                       appForm: isInVCFollow ? .inVideoConference : .standard)
            stage = .blockByTNS(info: info)
            openFailed(type: .noPermission)
            previewStateRelay.onNext(noPermissionState(isFromPermissionApi: false, userPermissions: nil))
            cacheService.deleteFile(dataVersion: fileInfo.dataVersion)
            performTNSRedirect(info: info)
        case let .serverError(code):
            // 处理审核结果
            let driveErrorCode = DriveFileInfoErrorCode(rawValue: code)
            switch code {
            case DriveFileInfoErrorCode.fileDeletedOnServerError.rawValue:
                stage = .fetchFailed
                openFailed(type: .fileDeletedOnServer)
                handleDeleteFileRestore()
                cacheService.deleteFile(dataVersion: fileInfo.dataVersion)
            case DriveFileInfoErrorCode.fileNotFound.rawValue:
                stage = .fetchFailed
                openFailed(type: .fileNotFound)
                let failedData = fileNotFoundFailedData(reason: BundleI18n.SKResource.Drive_Drive_FileIsNotExist,
                                                        image: UDEmptyType.loadingFailure.defaultImage())
                previewStateRelay.onNext(.setupFailed(data: failedData))
                cacheService.deleteFile(dataVersion: fileInfo.dataVersion)
            case DriveFileInfoErrorCode.noPermission.rawValue:
                stage = .fetchFailed
                openFailed(type: .noPermission)
                previewStateRelay.onNext(noPermissionState(isFromPermissionApi: false, userPermissions: nil))
                cacheService.deleteFile(dataVersion: fileInfo.dataVersion)
            case DriveFileInfoErrorCode.fileCopying.rawValue:
                stage = .fetchFailed
                openFailed(type: .fileCopyTimeout)
                let failData = simpleFaileData(reason: BundleI18n.SKResource.CreationMobile_ECM_CreateLaterToast)
                previewStateRelay.onNext(.setupFailed(data: failData))
            case DriveFileInfoErrorCode.fileDamage.rawValue:
                stage = .fetchFailed
                openFailed(type: .fileCopyFailed)
                let failData = simpleFaileData(reason: BundleI18n.SKResource.CreationMobile_ECM_CreateLaterToast)
                previewStateRelay.onNext(.setupFailed(data: failData))
                cacheService.deleteFile(dataVersion: fileInfo.dataVersion)
            case DriveFileInfoErrorCode.machineAuditFailureError.rawValue,
                 DriveFileInfoErrorCode.humanAuditFailureError.rawValue:
                stage = .fetchFailed
                openFailed(type: .auditFailure)
                let failData = simpleFaileData(reason: BundleI18n.SKResource.Drive_Drive_DisableAccessByPolicyTitle)
                previewStateRelay.onNext(.setupFailed(data: failData))
                cacheService.deleteFile(dataVersion: fileInfo.dataVersion)
            case DriveFileInfoErrorCode.fileKeyDeleted.rawValue:
                stage = .fetchFailed
                let failData = fileNotFoundFailedData(reason: BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidCanNotPreview,
                                                      image: UDEmptyType.ccmDocumentKeyUnavailable.defaultImage())
                previewStateRelay.onNext(.setupFailed(data: failData))
                cacheService.deleteFile(dataVersion: fileInfo.dataVersion)
            default:
                handleCommonError(error, isAsync: isAsync)
            }
        default:
            handleCommonError(error, isAsync: isAsync)
        }
    }

    func didResumeVCFullWindow() {
        if case let .blockByTNS(info) = stage {
            DocsLogger.error("drive.sdk.context.main --- redirect to tns H5 within drive after resume VC full window")
            performTNSRedirect(info: info)
        }
    }

    private func performTNSRedirect(info: TNSRedirectInfo) {
        guard let hostController else {
            spaceAssertionFailure("failed to get hostVC when redirect to TNS page")
            return
        }
        var rootController: UIViewController = hostController
        // 找到最接近 navigationController 的 Controller
        while let parent = rootController.parent, !parent.isKind(of: UINavigationController.self) {
            rootController = parent
        }
        if hostController.hasAppearred {
            Navigator.shared.push(info.finalURL, from: rootController, forcePush: true, animated: false) { _, _ in
                rootController.navigationController?.viewControllers.removeAll { $0 == rootController }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) {
                Navigator.shared.push(info.finalURL, from: rootController, forcePush: true, animated: false) { _, _ in
                    rootController.navigationController?.viewControllers.removeAll { $0 == rootController }
                }
            }
        }
    }
    
    // 文件被删除或者文件不存在错误
    private func fileNotFoundFailedData(reason: String, image: UIImage) -> DKPreviewFailedViewData {
        let data = DKPreviewFailedViewData(mainText: reason,
                                           image: image,
                                           showRetryButton: false,
                                           retryEnable: reachabilityRelay,
                                           retryHandler: {},
                                           showOpenWithOtherApp: BehaviorRelay<Bool>(value: false),
                                           openWithOtherEnable: reachabilityRelay,
                                           openWithOtherAppHandler: { _, _ in })
        return data
    }
    
    private func simpleFaileData(reason: String) -> DKPreviewFailedViewData {
        let data = DKPreviewFailedViewData(mainText: reason,
                                           showRetryButton: false,
                                           retryEnable: reachabilityRelay,
                                           retryHandler: {},
                                           showOpenWithOtherApp: BehaviorRelay<Bool>(value: false),
                                           openWithOtherEnable: reachabilityRelay,
                                           openWithOtherAppHandler: { _, _ in })
        return data
    }
    
    private func failedData(retryHandler: @escaping () -> Void) -> DKPreviewFailedViewData {
        let failedData = DKPreviewFailedViewData(showRetryButton: true,
                                                 retryEnable: reachabilityRelay,
                                                 retryHandler: retryHandler,
                                                 showOpenWithOtherApp: canOpenWithOtherApp,
                                                 openWithOtherEnable: reachabilityRelay) { [weak self] (sourceView, sourceRect) in
                                                    self?.handleOpenWithOtherApp(sourceView: sourceView, sourceRect: sourceRect)
            spaceAssertionFailure()
        }
        return failedData
    }
    
    func handleOpenWithOtherApp(sourceView: UIView?, sourceRect: CGRect?) {
        let callback: ((DKAttachmentInfo, String, Bool) -> Void)? = getCustomOpenWithOtherAppCallback()
        DocsLogger.driveInfo("drive.sdk.context.main --- did click open with other app")
        let action = DKPreviewAction.downloadAndOpenWithOtherApp(meta: fileInfo.getFileMeta(),
                                                                 previewFrom: self.previewFrom,
                                                                 sourceView: sourceView,
                                                                 sourceRect: sourceRect,
                                                                 callback: {[weak self] shareType, success in
            guard let self = self else { return }
            let info = self.fileInfo.attachmentInfo()
            callback?(info, shareType, success)
        })
        self.previewActionSubject.onNext(action)
    }
    
    private func handleDeleteFileRestore() {
        var restoreType = RestoreType.space(objToken: fileInfo.fileToken, objType: .file)
        if let wikiToken = commonContext.wikiToken {
            restoreType = RestoreType.wiki(wikiToken: wikiToken)
        }
        previewStateRelay.onNext(.deleteFileRestore(type: restoreType, completion: { [weak self] in
            if self?.previewFrom == .wiki {
                self?.hostModule?.subModuleActionsCenter.accept(.resotreSuccess)
            }
            if let hostController = self?.hostController {
                self?.stage = .initial
                self?.startPreview(hostContainer: hostController)
            }
            self?.shouldShowDeleteFailedView = true
        }))
        cacheService.deleteFile(dataVersion: fileInfo.dataVersion)
        
        let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
        dataCenterAPI?.deleteSpaceEntry(token: TokenStruct(token: fileInfo.fileToken))
    }
    
    func handleFileDeletedRouter() {
        guard shouldShowDeleteFailedView else { return }
        previewBag = DisposeBag()
        self.shouldShowDeleteFailedView = false
        handleDeleteFileRestore()
    }
    
    private func getCustomOpenWithOtherAppCallback() -> ((DKAttachmentInfo, String, Bool) -> Void)? {
        if case let .customOpenWithOtherApp(_, actionCallback) = self.moreDependency.actions.first(where: { action in
            if case .customOpenWithOtherApp(_, _) = action {
                return true
            } else {
                return false
            }
        }) {
            return actionCallback
        }
        return nil
    }
}
// MARK: - 终止预览信号处理
extension DKAttachmentFileCellViewModel {
    private func setupExternalAction(actionProvider: DriveSDKActionDependency) {
        actionProvider.closePreviewSignal
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.previewActionSubject.onNext(.exitPreview)
                self.cacheService.deleteFile(dataVersion: nil)
            }).disposed(by: actionBag)

        actionProvider.stopPreviewSignal
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] reason in
                guard let self = self else { return }
                // 收到外部的停止预览信号，需要中断内部的订阅，避免继续加载数据
                self.subModuleActionsCenter.accept(.clearNaviBarItems)
                self.stopPreview(deleteFile: true)
                self.previewStateRelay.onNext(.forbidden(reason: reason.reason, image: reason.image))
            })
            .disposed(by: actionBag)
        
        actionProvider.uiActionSignal
            .observeOn(MainScheduler.instance).subscribe(onNext: {[weak self] action in
                guard let self = self else { return }
                self.handleAction(action)
            }).disposed(by: actionBag)
    }
    
    private func handleAction(_ action: DriveSDKUIAction) {
        switch action {
        case let .showBanner(banner, bannerID):
            self.previewActionSubject.onNext(.showCustomBanner(banner: banner, bannerID: bannerID))
        case let .hideBanner(bannerID):
            self.previewActionSubject.onNext(.hideCustomBanner(bannerID: bannerID))
        @unknown default:
            spaceAssertionFailure("unknown action")
        }
    }

    private func stopPreview(deleteFile: Bool) {
        self.disposeBag = DisposeBag()
        self.stage = .forbidden
        if deleteFile {
            self.cacheService.deleteFile(dataVersion: nil)
        }
    }
}

// MARK: - Syncing FileInfo Handling
extension DKAttachmentFileCellViewModel {
    private func unsupportState(fileInfo: DKFileProtocol?, type: DriveUnsupportPreviewType) -> DKFilePreviewState {
        let fileName = fileInfo?.name ?? ""
        let fileSize: UInt64 = fileInfo?.size ?? performanceRecorder.fileSize ?? 0
        let fileType: String = fileInfo?.type ?? SKFilePath.getFileExtension(from: fileName) ?? ""
        let canOpen = canOpenWithOtherApp.asObservable()
        let info = DKUnSupportViewInfo(type: type,
                                       fileName: fileName,
                                       fileSize: fileSize,
                                       fileType: fileType,
                                       buttonVisable: canOpen,
                                       buttonEnable: reachabilityRelay.asObservable(), showDocTips: showUnsupportTips())
        return .setupUnsupport(info: info, handler: { [weak self] (sourceView, sourceRect) in
            self?.handleOpenWithOtherApp(sourceView: sourceView, sourceRect: sourceRect)
        })
    }
    
    private func showUnsupportTips() -> Bool {
        if performanceRecorder.previewFrom == .docsAttach || performanceRecorder.previewFrom == .sheetAttach {
            return true
        }
        return false
    }
    
    private func transcodingState(type: String, handler: (() -> Void)?) -> DKFilePreviewState {
        return .transcoding(
            fileType: type,
            handler: { [weak self] (sourceView, sourceRect) in
                self?.handleOpenWithOtherApp(sourceView: sourceView, sourceRect: sourceRect)
            },
            downloadForPreviewHandler: handler
        )
    }

    /// 处理非异步化 FileInfo 请求的结果
    private func startPreview(fileInfo: DriveFileInfo) {
        guard let hostVC = hostContainer else {
            spaceAssertionFailure("host container is nil")
            return
        }
        if ifBlockedByCAC {
            return
        }
        DocsLogger.driveInfo("drive.sdk.context.main --- handling fileInfo")

        guard let previewType = fileInfo.previewType else {
            previewStateRelay.onNext(unsupportState(fileInfo: fileInfo, type: .typeUnsupport))
            return
        }

        let previewVMDependencyImpl = DKPreviewAttachFileVMDependencyImpl(fileInfo: fileInfo,
                                                                          previewType: previewType,
                                                                          skipCellularCheck: isInVCFollow || isFromCardMode ,
                                                                          netState: reachabilityChanged,
                                                                          hostContainer: hostVC,
                                                                          performanceRecorder: performanceRecorder)
        var config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: true,
                                                 canDownloadOrigin: true,
                                                 previewFrom: performanceRecorder.previewFrom,
                                                 isInVCFollow: isInVCFollow,
                                                 cacheSource: .standard,
                                                 authExtra: file.authExtra)
        if isInVCFollow {
            // VC Follow 场景下，部分文件必须使用服务端预览文件，需要禁用降级策略
            config.allowDowngradeToOrigin = !self.fileInfo.fileType.preferRemotePreviewInVCFollow

        }
        let onlinePreviewVM = DKPreviewViewModel(fileInfo: fileInfo, isLatest: true, processorConfig: config, dependency: previewVMDependencyImpl)
        onlinePreviewVM.additionalStatisticParameters = statisticsService.additionalParameters
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let canCopy = permissionService.validate(operation: .copyContent).allow
            onlinePreviewVM.canCopy.accept(canCopy)
        } else {
            onlinePreviewVM.canCopy.accept(permissionInfo.canCopy)
        }
        onlinePreviewVM.output.previewState.asObservable().do(onNext: {[weak self] (state) in
            self?.reportPreviewFailedIfNeed(state: state)
        }).map {[weak self] (state) -> DKFilePreviewState in
            guard let self = self else {
                return .setupFailed(data: DKPreviewFailedViewData.defaultData())
            }
            return self.transformToPreviewState(state)
        }.bind(to: previewStateRelay).disposed(by: previewBag)
        onlinePreviewVM.output.previewAction.asObservable().bind(to: previewActionSubject).disposed(by: previewBag)
        stage = .onlinePreviewing(previewVM: onlinePreviewVM)
    }
    
    private func transformToPreviewState(_ state: DKPreviewViewModel.State) -> DKFilePreviewState {
        switch state {
        case .loading:
            return .loading
        case .endLoading:
            return .endLoading
        case let .fetchFailed(canRetry, _, handler):
            let failedData = DKPreviewFailedViewData(showRetryButton: canRetry,
                                                     retryEnable: reachabilityRelay,
                                                     retryHandler: handler ?? {},
                                                     showOpenWithOtherApp: canOpenWithOtherApp,
                                                     openWithOtherEnable: reachabilityRelay,
                                                     openWithOtherAppHandler: { [weak self] sourceView, sourceRect in
                                                        self?.handleOpenWithOtherApp(sourceView: sourceView, sourceRect: sourceRect)
            })
            return .setupFailed(data: failedData)
        case let .transcoding(fileType, handler):
            return transcodingState(type: fileType, handler: handler)
        case .endTranscoding:
            return .endTranscoding
        case let .showDownloading(fileType):
            return .showDownloading(fileType: fileType)
        case let .downloading(progress):
            return .downloading(progress: progress)
        case let .downloadFailed(_, handler):
            let data = failedData(retryHandler: handler)
            return .setupFailed(data: data)
        case .downloadNoPermission:
            let data = failedData(retryHandler: {})
            return .setupFailed(data: data)
        case .downloadCompleted:
            return .downloadCompleted
        case let .preview(type, info):
            return .setupPreview(type: type, info: info)
        case let .unsupport(fileInfo, type):
            return unsupportState(fileInfo: fileInfo, type: type)
        case .cacDenied:
            return .cacDenied
        }
    }
}

extension DKAttachmentFileCellViewModel {
    private enum FailedType {
        case noNetwork
        case fetchFileInfoFail(errorMessage: String)
        case fetchPreviewURLFail(errorMessage: String)
        case noPermission
        case fileNotFound
        case userCancel
        case userCancelOnCellularNetwork
        case downloadFail(errorMessage: String)
        case fileDeletedOnServer
        case auditFailure
        case fileCopyFailed
        case fileCopyTimeout
        case sizeTooBig
    }
    private func openFailed(type: FailedType) {
        // 根据失败类型 上报处理相关逻辑
        DocsLogger.error("DKAttachmentFileCellViewModel --- openFail type: \(type)")
        switch type {
        case .noNetwork:
            performanceRecorder.openFinish(result: .nativeFail, code: .noNetwork, openType: .unknown)
        case let .fetchFileInfoFail(errorMessage):
            performanceRecorder.openFinish(result: .nativeFail, code: .fetchFileInfoFail, openType: .unknown, extraInfo: ["error_message": errorMessage])
        case .fileDeletedOnServer:
            performanceRecorder.openFinish(result: .serverFail, code: .fileDeleted, openType: .unknown)
        case .noPermission:
            performanceRecorder.openFinish(result: .nativeFail, code: .noPermission, openType: .unknown)
        case .fileNotFound:
            performanceRecorder.openFinish(result: .nativeFail, code: .fileNotFound, openType: .unknown)
        case .userCancelOnCellularNetwork: // 4G下浏览提醒时取消
            performanceRecorder.openFinish(result: .cancel, code: .cancelledOnCellularNetwork, openType: .unknown)
        case .userCancel:
            performanceRecorder.openFinish(result: .cancel, code: .cancel, openType: .unknown)
        case .fetchPreviewURLFail(let errorMessage):
            performanceRecorder.openFinish(result: .nativeFail, code: .fetchPreviewUrlFail, openType: .unknown, extraInfo: ["error_message": errorMessage])
        case let .downloadFail(errorMessage):
            performanceRecorder.openFinish(result: .rustFail, code: .rustDownloadFail, openType: .unknown, extraInfo: ["error_message": errorMessage])
        case .auditFailure:
            performanceRecorder.openFinish(result: .nativeFail, code: .illegalFile, openType: .unknown)
        case .fileCopyTimeout:
            performanceRecorder.openFinish(result: .serverFail, code: .fileCopyTimeout, openType: .unknown)
        case .fileCopyFailed:
            performanceRecorder.openFinish(result: .serverFail, code: .fileCopyFailed, openType: .unknown)
        case .sizeTooBig:
            performanceRecorder.openFinish(result: .serverFail, code: .previewFileSizeTooBig, openType: .unknown)
        }
    }

    private func reportPreviewFailedIfNeed(state: DKPreviewViewModel.State) {
        switch state {
        case .fetchFailed(_, let errorMessage, _):
            openFailed(type: .fetchPreviewURLFail(errorMessage: errorMessage))
        case let .downloadFailed(errorMessage, _):
            openFailed(type: .downloadFail(errorMessage: errorMessage))
        case .downloadNoPermission:
            openFailed(type: .noPermission)
        case .unsupport(_, let type):
            if case .sizeTooBig = type {
                openFailed(type: .sizeTooBig)
            } else {
                DocsLogger.driveInfo("other unsupport type will report unsupport \(type)")
            }
        default:
            break
        }
    }

    private func reportPreviewFailed(action: DKPreviewAction) {
        switch action {
        case .cancelDownload:
            openFailed(type: .userCancelOnCellularNetwork)
        default:
            break
        }
    }
    private func setupNetworkMonitor() {
        let reachableOb = RxNetworkMonitor.networkStatus(observerObj: self)
        Observable.combineLatest(reachableOb, self.rustNetStatus.status.asObservable()).map { rechableStatus, rustStatus in
            DocsLogger.driveInfo("DKAttachmentFileCellViewModel -- rustStatus: \(rustStatus), reachable: \(rechableStatus)")
            switch rustStatus {
            case .netUnavailable, .offline, .serviceUnavailable:
                return false
            @unknown default:
                return rechableStatus.isReachable
            }
        }.bind(to: reachabilityRelay).disposed(by: disposeBag)
    }
    private func updatePerfomanceRecorder(fileInfo: DriveFileInfo) {
        performanceRecorder.fileSize = fileInfo.size
        performanceRecorder.fileType = fileInfo.type
        performanceRecorder.mimeType = fileInfo.mimeType
        performanceRecorder.realMimeType = fileInfo.realMimeType
    }
}

// MARK: - 权限逻辑
extension DKAttachmentFileCellViewModel {
    func setupPermissionMonitor() {
        // 当下面的permissionHelper返回结果显示admin设置了预览管控，将会重置previewBag
        // 但如果在fileInfo更新前就重置previewBag的话，会导致新建副本无法获取到标题等文档信息
        // 所以这里就等待resetPreviewBagAction和fileInfoRelay都发出信号后才会去重置previewBag
        Observable.zip(
            resetPreviewBagAction.asObservable(),
            fileInfoError.asObservable()
        ).subscribe(onNext: { [weak self] _ in
            self?.previewBag = DisposeBag()
        }).disposed(by: disposeBag)

        docsInfoRelay.compactMap(\.tenantID).subscribe(onNext: { [weak permissionService] tenantID in
            permissionService?.update(tenantID: tenantID)
        })
        .disposed(by: disposeBag)

        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            permissionService.onPermissionUpdated.subscribe(onNext: { [weak self] response in
                guard let self else { return }
                self.updateSecurityCopyEncryptID()
                let container = self.permissionService.containerResponse?.container
                switch response {
                case .success:
                    guard let container else {
                        spaceAssertionFailure("on permission update success but not container found")
                        return
                    }
                    if container.previewBlockByAdmin || container.shareControlByCAC || container.previewControlByCAC || container.viewBlockByAudit {
                        // 走失败流程
                        self.handlePermissionSerivce(container: container, statusCode: container.statusCode, applyInfo: nil)
                    } else {
                        self.handlePermissionService(container: container)
                    }
                case let .noPermission(statusCode, applyUserInfo):
                    self.handlePermissionSerivce(container: container,
                                                 statusCode: statusCode,
                                                 applyInfo: applyUserInfo)
                }
            }).disposed(by: disposeBag)

            performanceRecorder.stageBegin(stage: .requestPermission)
            permissionService.updateUserPermission().subscribe { [weak self] _ in
                guard let self else { return }
                self.performanceRecorder.stageEnd(stage: .requestPermission)
            } onError: { [weak self] error in
                guard let self else { return }
                self.performanceRecorder.stageBegin(stage: .requestPermission)
                self.handlePermissionService(error: error)
            }.disposed(by: disposeBag)
        } else {
            // 旧权限逻辑
            permissionHelper.startMonitorPermission(startFetch: {[weak self] in
                self?.performanceRecorder.stageBegin(stage: .requestPermission)
                }, permissionChanged: {[weak self] (info) in
                    guard let self = self else { return }
                    self.performanceRecorder.stageEnd(stage: .requestPermission)
                    self.handlePermission(newInfo: info)
                }, failed: {[weak self] (model) in
                    guard let self = self else { return }
                    self.performanceRecorder.stageEnd(stage: .requestPermission)
                    self.handlePermissionError(model: model)
            })
        }
    }

    // permissionService 拉取权限失败
    private func handlePermissionService(error: Error) {
        if (error as NSError).code == Int(DriveResultCode.operationsTooFrequentError.rawValue) {
            DocsLogger.error("DKAttachmentFileCellViewModel --: operation too frequent error")
        } else {
            DocsLogger.error("DKAttachmentFileCellViewModel --: handle get permission failed", error: error)
        }
    }

    private func updateSecurityCopyEncryptID() {
        // 只有 space 预览场景才需要主动写入 encryptID，因为只是为了给评论使用
        guard checkNeedSecurityCopy() else {
            ClipboardManager.shared.updateEncryptId(token: fileInfo.fileToken, encryptId: nil)
            return
        }
        ClipboardManager.shared.updateEncryptId(token: fileInfo.fileToken, encryptId: fileInfo.fileToken)
    }

    private func checkNeedSecurityCopy() -> Bool {
        guard scene == .space else { return false } // 附件场景用宿主token加密，不需要关注
        guard LKFeatureGating.securityCopyEnable else { return false } // FG 关不处理
        let copyResponse = permissionService.validate(operation: .copyContent)
        switch copyResponse.result {
        case .allow:
            // 有复制权限，正常复制
            return false
        case let .forbidden(denyType, _):
            guard case let .blockByUserPermission(reason) = denyType else {
                // 非权限原因管控复制
                return false
            }
            switch reason {
            case .blockByServer, .unknown, .userPermissionNotReady, .blockByAudit:
                // 走编辑权限判断
                return permissionService.validate(operation: .edit).allow
            case .blockByCAC, .cacheNotSupport:
                // 其他非权限原因管控复制
                return false
            }
        }
    }

    // permissionService 更新了权限状态
    private func handlePermissionService(container: UserPermissionContainer) {
        let canView = permissionService.validate(operation: .view).allow
        ifBlockedByCAC = container.previewControlByCAC
        handleBizExtraIfNeed(bizExtra: (container as? DriveThirdPartyAttachmentPermissionContainer)?.userPermission.bizExtraInfo)
        recoverFromNoPermissionIfNeed(container: container, canView: canView)

        permissionStatusCode = container.statusCode
        permissionCanView = canView
        let canCopy = permissionService.validate(operation: .copyContent).allow
        fileInfoLoader?.canCopy.accept(canCopy)
        if !canView {
            if container.previewControlByCAC {
                disposeBag = DisposeBag()
                previewActionSubject.onNext(.cacBlock)
            }
            previewStateRelay.onNext(createNoPermissionState(container: container, applyInfo: nil))
        }
        let openWithOtherAppAllow = permissionService.validate(operation: .openWithOtherApp).allow
        canOpenWithOtherApp.accept(openWithOtherAppAllow)
        if case let .onlinePreviewing(previewVM) = stage {
            let canCopy = permissionService.validate(operation: .copyContent).allow
            previewVM.canCopy.accept(canCopy)
        }
    }
    
    private func handleBizExtraIfNeed(bizExtra: [String: Any]?) {
        // 如果有业务后端返回的perm_v2，回调给业务
        if let bizExtra {
            file.handleBizPermission?(bizExtra)
        } else {
            DocsLogger.driveInfo("no perm_v2")
        }
    }

    // permissionService 回报无权限状态
    private func handlePermissionSerivce(container: UserPermissionContainer?,
                                         statusCode: UserPermissionResponse.StatusCode,
                                         applyInfo: AuthorizedUserInfo?) {
        permissionStatusCode = statusCode
        permissionCanView = false
        switch statusCode {
        case .passwordRequired:
            handlePasswordRequired()
        case .entityDeleted:
            // 被删除走报错流程
            handlePermissionService(error: DocsNetworkError.entityDeleted)
        default:
            if let container,
               container.shareControlByCAC
                || container.previewControlByCAC
                || container.previewBlockByAdmin
                || container.viewBlockByAudit {
                // CAC、admin 管控需要额外设置一些状态
                ifBlockedByCAC = true
                resetPreviewBagAction.onNext(())
            }
            /// 其他无权限错误
            let state = createNoPermissionState(container: container, applyInfo: applyInfo)
            previewStateRelay.onNext(state)
            self.openFailed(type: .noPermission)
            cacheService.deleteFile(dataVersion: fileInfo.dataVersion)
        }
    }
    
    private func handlePasswordRequired() {
        // 需要输入密码相当于无权限情况，如果本地有缓存删除缓存，避免第二次进入后先出现缓存文件预览后变为无权限。
        cacheService.deleteFile(dataVersion: fileInfo.dataVersion)
        // 显示密码输入框页面
        previewStateRelay.onNext(.showPasswordInputView(fileToken: fileInfo.fileToken, restartBlock: { [weak self] in
            guard let self = self else { return }
            if let hostVC = self.hostController {
                self.stage = .initial
                self.startPreview(hostContainer: hostVC)
            }
        }))
    }

    private func createNoPermissionState(container: UserPermissionContainer?,
                                         applyInfo: AuthorizedUserInfo?) -> DKFilePreviewState {
        // 在 Drive 的申请权限页会再拉一次权限判断能否申请，这里暂时先不传递申请信息过去了
        let docsInfo = DocsInfo(type: .file, objToken: file.fileToken)
        docsInfo.isInVideoConference = isInVCFollow
        return .noPermission(docsInfo: docsInfo,
                             canRequestPermission: applyInfo != nil,
                             isFromPermissionAPI: true,
                             isAdminBlocked: container?.previewBlockByAdmin ?? false,
                             isShareControlByCAC: container?.shareControlByCAC ?? false,
                             isPreviewControlByCAC: container?.previewControlByCAC ?? false,
                             isViewBlockByAudit: container?.viewBlockByAudit ?? false)
    }

    @discardableResult
    private func recoverFromNoPermissionIfNeed(container: UserPermissionContainer, canView: Bool) -> Bool {
        guard shouldRecoverFromNoPermission(container: container, canView: canView) else {
            DocsLogger.driveInfo("DKAttachmentFileCellViewModel: no need to recover from no permission",
                                 extraInfo: [
                                    "currentCanView": permissionCanView,
                                    "currentStatusCode": permissionStatusCode
                                 ])
            return false
        }
        guard let hostController else {
            spaceAssertionFailure("hostController is nil when recover from no permission")
            return false
        }
        stage = .initial
        startPreview(hostContainer: hostController)
        return true
    }

    private func shouldRecoverFromNoPermission(container: UserPermissionContainer, canView: Bool) -> Bool {
        let previousCanView = permissionCanView
        /// 无权限 -> 有权限，隐藏无权限页面，重新加载文件
        let recoverFromNoPermission = !previousCanView && canView
        /// 密码 -> 有权限
        let recoverFromPassword = permissionStatusCode == .passwordRequired && canView
        return recoverFromNoPermission || recoverFromPassword
    }
}

@available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
extension DKAttachmentFileCellViewModel {

    private func handlePermissionError(model: PermissionResponseModel) {
        guard let error = model.error else {
            DocsLogger.error("DKAttachmentFileCellViewModel --: error is nil!")
            return
        }
        DocsLogger.warning("DKAttachmentFileCellViewModel --: handlePermissionError", error: error)
        if let permissionStatusCode = model.permissionStatusCode, permissionStatusCode == .passwordRequired {
            self.handlePasswordRequired()
            let newPermission = permission(model: model)
            self.permissionInfo = newPermission
            self.permissionRelay.accept(newPermission)
        } else if (error as NSError).code == Int(DriveResultCode.operationsTooFrequentError.rawValue) {
            DocsLogger.error("DKAttachmentFileCellViewModel --: 频繁请求")
        } else if model.userPermissions?.shareControlByCAC() == true
                    || model.userPermissions?.previewControlByCAC() == true
                    || model.userPermissions?.adminBlocked() == true {
            ifBlockedByCAC = true
            resetPreviewBagAction.onNext(())
            /// admin管控导致的无权限
            previewStateRelay.onNext(noPermissionState(isFromPermissionApi: true, userPermissions: model.userPermissions))
            self.openFailed(type: .noPermission)
            cacheService.deleteFile(dataVersion: fileInfo.dataVersion)
        } else if (error as? DocsNetworkError)?.code == DocsNetworkError.Code.forbidden {
            /// 无权限错误
            previewStateRelay.onNext(noPermissionState(isFromPermissionApi: true, userPermissions: model.userPermissions))
            self.openFailed(type: .noPermission)
            cacheService.deleteFile(dataVersion: fileInfo.dataVersion)
        } else {
            DocsLogger.error("DKAttachmentFileCellViewModel --: 权限请求失败")
        }
    }

    private func permission(model: PermissionResponseModel) -> DrivePermissionInfo {
        guard let userPermission = model.userPermissions else {
            var permission = DrivePermissionInfo.noPermissionInfo
            permission.permissionStatusCode = model.permissionStatusCode
            return permission
        }
        let permission = DrivePermissionInfo(isReadable: userPermission.canView(),
                                             isEditable: userPermission.canEdit(),
                                             canComment: userPermission.canComment(),
                                             canExport: userPermission.canExport(),
                                             canCopy: userPermission.canComment(),
                                             canShowCollaboratorInfo: userPermission.canShowCollaboratorInfo(),
                                             isCACBlock: userPermission.previewControlByCAC(),
                                             permissionStatusCode: model.permissionStatusCode)
        return permission
    }

    private func handlePermission(newInfo: DrivePermissionInfo) {
        if !newInfo.isCACBlock {
            ifBlockedByCAC = false
        }
        handleBizExtraIfNeed(bizExtra: newInfo.bizExtra)
        handlePermissionRecovered(originInfo: self.permissionInfo, newInfo: newInfo)
        handlePasswordRequired(originInfo: self.permissionInfo, newInfo: newInfo)
        self.permissionInfo = newInfo
        self.permissionRelay.accept(newInfo)
        self.fileInfoLoader?.canCopy.accept(newInfo.canCopy)
        if !newInfo.isReadable {
            if newInfo.isCACBlock {
                ifBlockedByCAC = true
                disposeBag = DisposeBag()
                self.previewActionSubject.onNext(.cacBlock)
                previewStateRelay.onNext(.noPermission(docsInfo: DocsInfo(type: .file, objToken: fileInfo.fileToken), canRequestPermission: false, isFromPermissionAPI: true, isAdminBlocked: false, isShareControlByCAC: false, isPreviewControlByCAC: true, isViewBlockByAudit: false))
            } else {
                previewStateRelay.onNext(noPermissionState(isFromPermissionApi: true, userPermissions: nil))
            }
            self.openFailed(type: .noPermission)
            cacheService.deleteFile(dataVersion: fileInfo.dataVersion)
        }
        canOpenWithOtherApp.accept(newInfo.canExport)
        if case let .onlinePreviewing(previewVM) = stage {
            previewVM.canCopy.accept(newInfo.canCopy)
        }
    }

    private func handlePermissionRecovered(originInfo: DrivePermissionInfo, newInfo: DrivePermissionInfo) {
        /// 无权限 -> 有权限，隐藏无权限页面，重新加载文件
        /// 密码 -> 有权限
        if needRecover(originInfo: originInfo, newInfo: newInfo) {
            if let hostVC = hostController {
                stage = .initial
                startPreview(hostContainer: hostVC)
            }
        } else {
            DocsLogger.driveInfo("DKAttachmentFileCellViewModel: handlePermissionRecovered, originInfo: \(originInfo), newInfo: \(newInfo)")
        }
    }

    private func needRecover(originInfo: DrivePermissionInfo, newInfo: DrivePermissionInfo) -> Bool {
        /// 无权限 -> 有权限，隐藏无权限页面，重新加载文件
        let recoverFromForbid = (!originInfo.isReadable && newInfo.isReadable)
        /// 密码 -> 有权限
        let recoverFromPassword =  (originInfo.permissionStatusCode == .passwordRequired && newInfo.isReadable && newInfo.permissionStatusCode != .passwordRequired)
        return  (recoverFromForbid || recoverFromPassword)

    }

    private func handlePasswordRequired(originInfo: DrivePermissionInfo, newInfo: DrivePermissionInfo) {
        DocsLogger.driveInfo("DKAttachmentFileCellViewModel: handle password required successed, originInfo: \(originInfo), newInfo: \(newInfo)")
        guard let code = newInfo.permissionStatusCode, code == PermissionStatusCode.passwordRequired else { return }
        handlePasswordRequired()
    }

    private func noPermissionState(isFromPermissionApi: Bool, userPermissions: UserPermissionAbility?, isFromCACPermissionApi: Bool = false) -> DKFilePreviewState {
        let docsInfo = DocsInfo(type: .file, objToken: file.fileToken)
        docsInfo.isInVideoConference = isInVCFollow
        let canRequest = (scene == .space)
        var permissionInfo: DrivePermissionInfo
        if isFromPermissionApi {
            permissionInfo = DrivePermissionInfo(isReadable: userPermissions?.canView() ?? false,
                                                 isEditable: userPermissions?.canEdit() ?? false,
                                                 canComment: userPermissions?.canComment() ?? false,
                                                 canExport: userPermissions?.canExport() ?? false,
                                                 canCopy: userPermissions?.canCopy() ?? false,
                                                 canShowCollaboratorInfo: true,
                                                 isCACBlock: false,
                                                 permissionStatusCode: nil,
                                                 userPermissions: userPermissions)
        } else {
            permissionInfo = DrivePermissionInfo.noPermissionInfo
        }
        permissionInfo.userPermissions = userPermissions
        self.permissionInfo = permissionInfo
        permissionRelay.accept(permissionInfo)
        return .noPermission(docsInfo: docsInfo,
                             canRequestPermission: userPermissions?.canApply() ?? canRequest,
                             isFromPermissionAPI: isFromPermissionApi,
                             isAdminBlocked: userPermissions?.adminBlocked() == true,
                             isShareControlByCAC: userPermissions?.shareControlByCAC() == true,
                             isPreviewControlByCAC: userPermissions?.previewControlByCAC() == true || isFromCACPermissionApi,
                             isViewBlockByAudit: false)
    }
}
