//
//  DKIMFileCellViewModel.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/6/14.
//
// swiftlint:disable file_length

import Foundation
import SKFoundation
import SpaceInterface
import RxSwift
import RxRelay
import RxCocoa
import SKCommon
import SKResource
import SKUIKit
import UniverseDesignToast
import UniverseDesignEmpty
import LarkSecurityComplianceInterface
import SKInfra
import LarkDocsIcon

protocol DKIMFileDependency {
    var appID: String { get }
    var onlineFile: DriveSDKIMFile { get }
    // 提供加载 FileInfo 的能力
    var fileInfoProvider: DKDefaultFileInfoProvider { get }
    // 提供缓存服务的能力
    var cacheService: DKCacheServiceProtocol { get }
    // 提供保存到云空间的能力
    var saveService: DKSaveToSpaceService { get }
    // 更多菜单的配置
    var moreConfiguration: DriveSDKMoreDependency { get }
    // 终止预览的信号
    var actionProvider: DriveSDKActionDependency { get }
    // statistics
    var statistics: DKStatisticsService { get }
    // 性能埋点
    var performanceRecorder: DrivePerformanceRecorder { get }
}
// swiftlint:disable type_body_length
class DKIMFileCellViewModel: NSObject, DKFileCellViewModelType {
    
    var previewFromScene: DrivePreviewFrom {
        return statisticsService.previewFrom
    }
    
    var title: String {
        return onlineFile.fileName
    }
    var objToken: String {
        return onlineFile.fileID
    }
    var isInVCFollow: Bool = false
    
    var canReadAndCanCopy: Observable<(Bool, Bool)>? {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let canCopy = permissionService.validate(operation: .copyContent).allow
            let canRead = permissionService.validate(operation: .view).allow
            return .just((canRead, canCopy))
        } else {
            return Observable<(Bool, Bool)>.just((true, true))
        }
    }
    
    // 流量弹窗需要一个fromVC
    private weak var hostContainer: UIViewController?

    typealias Dependency = DKIMFileDependency

    let naviBarViewModel = ReplaySubject<DKNaviBarViewModel>.create(bufferSize: 1)

    private let appID: String
    private let onlineFile: DriveSDKIMFile
    private var downloadViewModel: DKDownloadViewModel? // 源文件下载进度条VM
    private let rustNetStatus = DocsContainer.shared.resolve(DocsRustNetStatusService.self)!
    private let previewActionSubject = ReplaySubject<DKPreviewAction>.create(bufferSize: 1)
    var previewAction: Observable<DKPreviewAction> {
        previewActionSubject.debug("previewActionSubject").asObservable().do(onNext: {[weak self] (action) in
            self?.reportPreviewFailed(action: action)
        })
    }

    private var fileEditTypeService: DKFileEditTypeService?
    private var fileInfoLoader: DKFileInfoLoader<DKFileInfo, DKDefaultFileInfoProvider>?
    private let cacheService: DKCacheServiceProtocol

    private let saveService: DKSaveToSpaceService

    let permissionService: UserPermissionService
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private var cacManager: CACManagerBridge.Type
    
    // 业务埋点
    let statisticsService: DKStatisticsService
    // 性能埋点
    let performanceRecorder: DrivePerformanceRecorder
    // 是否需要展示水印
    var shouldShowWatermark: Bool {
        return false
    }
    // 文件类型，用于判断是否支持多文件预览
    var fileType: DriveFileType {
        let fileExt = SKFilePath.getFileExtension(from: onlineFile.fileName)
        let type = DriveFileType(fileExtension: fileExt)
        return fileInfo?.fileType ?? type
    }
    
    var fileID: String {
        return onlineFile.fileID
    }
    var urlForSuspendable: String? {
        return nil
    }
    var hostModule: DKHostModuleType? {
        return nil
    }
    private let fileInfoProcessorProvider: FileInfoProcessorProvider
    private let fileInfoProvider: DKDefaultFileInfoProvider
    private var fileInfo: DKFileInfo? {
        didSet {
            if let info = fileInfo {
                updatePerfomanceRecorder(fileInfo: info)
            }
        }
    }

    /// 控制"用其他应用打开"按钮的可见性
    private var canOpenWithOtherApp: Bool {
        let canOpen: Bool
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            canOpen = permissionService.validate(operation: .openWithOtherApp).allow
        } else {
            canOpen = cacManager.syncValidate(entityOperate: .ccmFileDownload, fileBizDomain: .ccm,
                                              docType: .file, token: objToken).allow
        }
        return originFileProvider != nil && canOpen
    }
    /// 获取原始文件
    private var originFileProvider: DriveSDKFileProvider?

    /// 网络状态
    private let reachabilityRelay: BehaviorRelay<Bool>
    var reachabilityChanged: Observable<Bool> {
        return reachabilityRelay.asObservable()
    }
    var isReachable: Bool {
        return reachabilityRelay.value
    }

    /// 保存到云空间的状态
    private let saveToSpaceStateRelay = BehaviorRelay<DKSaveToSpaceState>(value: .unsave)
    var saveToSpaceStateChanged: Observable<DKSaveToSpaceState> {
        return saveToSpaceStateRelay.asObservable()
    }
    var saveToSpaceState: DKSaveToSpaceState {
        return saveToSpaceStateRelay.value
    }

    /// 业务方配置的导航栏按钮，如“更多”
    private let naviBarItemsRelay: BehaviorRelay<[DKNaviBarItem]>
    /// 预览业务配置的额外的导航栏按钮，如“PPT 演示模式”
    private let additionLeftNaviBarItemsRelay = BehaviorRelay<[DKNaviBarItem]>(value: [])
    private let additionRightNaviBarItemsRelay = BehaviorRelay<[DKNaviBarItem]>(value: [])

    /// 预览状态更新
    private let previewStateRelay = ReplaySubject<DKFilePreviewState>.create(bufferSize: 1)
    var previewStateUpdated: Driver<DKFilePreviewState> {
        previewStateRelay.asDriver(onErrorJustReturn: .setupFailed(data: DKPreviewFailedViewData.defaultData()))
    }

    /// 文件标题
    private let titleRelay: BehaviorRelay<String>

    private var stage: DKFileStage = .initial {
        didSet {
            DocsLogger.driveInfo("drive.sdk.context.main --- stage changed", extraInfo: ["from": oldValue, "to": stage])
        }
    }
    
    init(dependency: Dependency, permissionService: UserPermissionService, cacManager: CACManagerBridge.Type = CACManager.self) {
        appID = dependency.appID
        onlineFile = dependency.onlineFile
        cacheService = dependency.cacheService
        saveService = dependency.saveService
        fileInfoProvider = dependency.fileInfoProvider
        statisticsService = dependency.statistics
        performanceRecorder = dependency.performanceRecorder
        self.cacManager = cacManager
        self.permissionService = permissionService
        reachabilityRelay = BehaviorRelay<Bool>(value: DocsNetStateMonitor.shared.isReachable)
        naviBarItemsRelay = BehaviorRelay<[DKNaviBarItem]>(value: [])
        titleRelay = BehaviorRelay<String>(value: onlineFile.fileName)
        fileInfoProcessorProvider = DKFileInfoProcessorProvider(cacheService: cacheService)

        super.init()
        let leftBarItemsChanged = Observable<[DKNaviBarItem]>.combineLatest(BehaviorRelay<[DKNaviBarItem]>(value: []), additionLeftNaviBarItemsRelay, resultSelector: +)
        let rightBarItemsChanged = Observable<[DKNaviBarItem]>.combineLatest(naviBarItemsRelay, additionRightNaviBarItemsRelay, resultSelector: +)
        
        let naviBarDependencyImpl = DKNaviBarDependencyImpl(titleRelay: titleRelay,
                                                            fileDeleted: BehaviorRelay<Bool>(value: false),
                                                            leftBarItems: leftBarItemsChanged,
                                                            rightBarItems: rightBarItemsChanged)
        naviBarViewModel.onNext(DKNaviBarViewModel(dependency: naviBarDependencyImpl))
        setupNaviBarItems(moreDependency: dependency.moreConfiguration)
        setupExternalAction(actionProvider: dependency.actionProvider)
    }
    
    deinit {
        statisticsService.exitPreview()
        DocsLogger.driveInfo("DKIMFileCellViewModel -- deinit")
    }

    /// 仅用于绑定外部事件，如退出预览、停止预览
    private let actionBag = DisposeBag()
    /// 用于内部事件的绑定，当收到外部停止预览事件时，会被重置
    private var disposeBag = DisposeBag()
    
    private func setupFileInfoLoader(hostContainer: UIViewController) {
        let initailFileInfo = getFileInfoFromCache()
        let config = DriveFileInfoProcessorConfig(isIMFile: true,
                                                  isIMFileEncrypted: onlineFile.isEncrypted,
                                                  preferPreview: true,
                                                  authExtra: nil,
                                                  cacheSource: .standard,
                                                  previewFrom: .im,
                                                  isInVCFollow: isInVCFollow,
                                                  appID: appID,
                                                  scene: .im)
        let loader = DKFileInfoLoader(fileInfo: initailFileInfo,
                                     isLatest: true,
                                     isInVCFollow: isInVCFollow,
                                     skipCellularCheck: isInVCFollow,
                                     fileInfoProvider: fileInfoProvider,
                                     fileInfoProcessorProvider: fileInfoProcessorProvider,
                                     processorConfig: config,
                                     cacheService: cacheService,
                                     statisticsService: statisticsService,
                                     performanceRecorder: performanceRecorder,
                                     hostContainer: hostContainer)        
        loader.state.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] state in
            self?.handleState(state)
        }).disposed(by: disposeBag)
        loader.action.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] previewAction in
            self?.handle(previewAction: previewAction)
        }).disposed(by: disposeBag)

        self.fileInfoLoader = loader
    }
    // 开始加载文件
    func startPreview(hostContainer: UIViewController) {
        self.hostContainer = hostContainer
        guard case .initial = stage else {
            DocsLogger.error("drive.sdk.context.main --- mainVM not in initial stage")
            return
        }
        statisticsService.enterPreview()
        disposeBag = DisposeBag()
        setupFileInfoLoader(hostContainer: hostContainer)
        fileInfoLoader?.start()
        setupNetworkMonitor()
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
        additionLeftNaviBarItemsRelay.accept(leftNaviBarItems)
        let rightNaviBarItems = additionRightBarItems.compactMap { (barItemData) -> DKNaviBarItem? in
            guard let icon = barItemData.type.image, let action = barItemData.action else { return nil }
            let barItem = DKStandardNaviBarItem(naviBarButtonID: barItemData.type.skNaviBarButtonID, itemIcon: icon, isHighLighted: barItemData.isHighLighted) { () -> DKNaviBarItem.Action in
                barItemData.target?.perform(action)
                return .none
            }
            return barItem
        }
        additionRightNaviBarItemsRelay.accept(rightNaviBarItems)
    }
    func willChangeMode(_ mode: DrivePreviewMode) {
        DocsLogger.driveInfo("im not support changeMode")
    }
    
    func changingMode(_ mode: DrivePreviewMode) {
        DocsLogger.driveInfo("im not support changeMode")
    }

    func didChangeMode(_ mode: DrivePreviewMode) {
        DocsLogger.driveInfo("im not support changeMode")
    }
    func handle(previewAction: DKPreviewAction) {
        previewActionSubject.onNext(previewAction)
    }
    
    func handleOpenFileSuccessType(openType: DriveOpenType) {
        if fileType.isExcel && openType == .wps {
            // 上报 IM Excel 支持编辑打开的埋点
            statisticsService.reportExcelContentPageView(editMethod: .wps)
        }
    }
    
    // swiftlint:disable cyclomatic_complexity
    func handleState(_ state: FileInfoState<DKFileInfo>) {
        DocsLogger.driveInfo("drive.sdk.context.main --- handleState: \(state)")
        switch state {
        case let .startFetch(isAsycn):
            stage = isAsycn ? .asyncFetchingFileInfo : .fetchingFileInfo
            if !isAsycn {
                previewStateRelay.onNext(.loading)
            }
        case .storing:
            break
        case let .fetchFailed(error, isPreviewing):
            if isPreviewing {
                handleAsyncFileInfoFailed(error: error)
            } else {
                handleFileInfoFailed(error: error)
            }
        case let .fetchSucc(info, isPreviewing):
            if isPreviewing {
                handleAsync(fileInfo: info)
            } else {
                updateFileInfo(info)
            }
        case .failedWithNoNet:
            handleNoNet()
        case let .startFetchPreview(info):
            startPreview(fileInfo: info)
        case let .showDownloading(fileType):
            previewStateRelay.onNext(.showDownloading(fileType: fileType))
        case let .downloading(progress):
            previewStateRelay.onNext(.downloading(progress: progress))
        case let .downloadFailed(errorMessage, handler):
            let data = failedData(retryHandler: handler)
            previewStateRelay.onNext(.setupFailed(data: data))
            openFailed(type: .downloadFail(errorMessage: errorMessage))
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
        DocsLogger.driveInfo("drive.sdk.context.main --- handleNoNet")
        stage = .fetchFailed
        openFailed(type: .noNetwork)
        let canOpen = BehaviorRelay<Bool>(value: canOpenWithOtherApp)
        let failedData = DKPreviewFailedViewData(showRetryButton: true, retryEnable: reachabilityRelay, retryHandler: { [weak self] in
            guard let self = self else { return }
            self.stage = .fetchingFileInfo
            self.fileInfoLoader?.fetchFileInfo()
        }, showOpenWithOtherApp: canOpen, openWithOtherEnable: reachabilityRelay, openWithOtherAppHandler: { [weak self] (sourceView, sourceRect) in
            guard let fileProvider = self?.originFileProvider else { return }
            self?.handleOpenWithOtherApp(fileProvider: fileProvider, sourceView: sourceView, sourceRect: sourceRect)
        })
        previewStateRelay.onNext(.setupFailed(data: failedData))
    }
    
    func updateFileInfo(_ fileInfo: DKFileInfo) {
        self.fileInfo = fileInfo
        titleRelay.accept(fileInfo.name)
        saveToSpaceStateRelay.accept(fileInfo.saveState)
    }
    // 用于兼容 drive 现有的预览异常处理
    func handleBizPreviewUnsupport(type: DriveUnsupportPreviewType) {
        DocsLogger.driveInfo("drive.sdk.context.main --- handleBizPreviewUnsupport: \(type)")
        previewStateRelay.onNext(unsupportState(fileInfo: fileInfo, type: type))
    }

    // 用于兼容 drive 现有的预览失败处理
    func handleBizPreviewFailed(canRetry: Bool) {
        DocsLogger.driveInfo("drive.sdk.context.main --- handleBizPreviewFailed: \(canRetry)")
        guard fileInfo?.isRealFileType == true else {
            // 文件不是真实类型的，显示不支持页面
            previewStateRelay.onNext(unsupportState(fileInfo: fileInfo, type: .notRealType))
            return
        }
        let failedData: DKPreviewFailedViewData
        let canOpen = BehaviorRelay<Bool>(value: canOpenWithOtherApp)
        if canRetry, case let DKFileStage.onlinePreviewing(previewVM) = stage {
            failedData = DKPreviewFailedViewData(showRetryButton: true, retryEnable: reachabilityRelay, retryHandler: { [weak previewVM] in
                previewVM?.input.fetchPreview.onNext(.normal)
            }, showOpenWithOtherApp: canOpen, openWithOtherEnable: reachabilityRelay, openWithOtherAppHandler: { [weak self] (sourceView, sourceRect) in
                guard let fileProvider = self?.originFileProvider else { return }
                self?.handleOpenWithOtherApp(fileProvider: fileProvider, sourceView: sourceView, sourceRect: sourceRect)
            })
        } else {
            failedData = DKPreviewFailedViewData(showRetryButton: false,
                                                 retryEnable: reachabilityRelay,
                                                 retryHandler: {},
                                                 showOpenWithOtherApp: canOpen,
                                                 openWithOtherEnable: reachabilityRelay,
                                                 openWithOtherAppHandler: { [weak self] (sourceView, sourceRect) in
                                                    guard let fileProvider = self?.originFileProvider else { return }
                                                    self?.handleOpenWithOtherApp(fileProvider: fileProvider, sourceView: sourceView, sourceRect: sourceRect)
            })
        }
        previewStateRelay.onNext(.setupFailed(data: failedData))
    }
    
    func handleBizPreviewDowngrade() {
        DocsLogger.driveInfo("drive.sdk.context.main --- handleBizPreviewDowngrade")
        if case let DKFileStage.onlinePreviewing(previewVM) = stage {
            DocsLogger.driveInfo("drive.sdk.context.main --- fetchPreview downgrade")
            previewVM.input.fetchPreview.onNext(.downgrade)
        } else if let fileInfo = self.fileInfo {
            // 目前仅有 WPS 会进入降级在线转码预览
            startPreview(fileInfo: fileInfo)
        } else {
            let canOpen = BehaviorRelay<Bool>(value: canOpenWithOtherApp)
            let failedData = DKPreviewFailedViewData(showRetryButton: false,
                                                     retryEnable: reachabilityRelay,
                                                     retryHandler: {},
                                                     showOpenWithOtherApp: canOpen,
                                                     openWithOtherEnable: reachabilityRelay,
                                                     openWithOtherAppHandler: { [weak self] (sourceView, sourceRect) in
                                                        guard let fileProvider = self?.originFileProvider else { return }
                                                        self?.handleOpenWithOtherApp(fileProvider: fileProvider, sourceView: sourceView, sourceRect: sourceRect)
            })
            previewStateRelay.onNext(.setupFailed(data: failedData))
        }
    }
    
    func reset() {
        DocsLogger.driveInfo("drive.sdk.context.main --- reset")
        stage = .initial
    }

    /// 处理异步请求 FileInfo 的结果
    private func handleAsync(fileInfo: DKFileInfo) {
        // DriveSDK 中的文件还没有版本更新、重命名改变后缀的场景，暂时不需要处理
        DocsLogger.driveInfo("drive.sdk.context.main --- handling async fileInfo")
        stage = .previewingCache
        updateFileInfo(fileInfo)
    }

    /// 处理异步请求 FileInfo 的错误
    private func handleAsyncFileInfoFailed(error: Error) {
        DocsLogger.error("drive.sdk.context.main --- fileInfo provider failed with error when async fetching")
        stage = .previewingCache
        guard let driveError = error as? DriveError else {
            DocsLogger.error("drive.sdk.context.main --- async handle unknown error", error: error)
            previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.Drive_Drive_GetFileInformationFail, type: .failure))
            return
        }
        DocsLogger.error("drive.sdk.context.main --- async handle drive error", error: driveError)
        updateNaviBarMoreItem(with: driveError)
        switch driveError {
        case let .serverError(code):
            switch code {
            case DriveFileInfoErrorCode.fileDeletedOnServerError.rawValue:
                stage = .fetchFailed
                openFailed(type: .fileDeletedOnServer)
                let failedData = fileNotFoundFailedData(reason: BundleI18n.SKResource.Drive_Drive_FileDeleted)
                previewStateRelay.onNext(.setupFailed(data: failedData))
                cacheService.deleteFile(dataVersion: nil)
            case DriveFileInfoErrorCode.fileNotFound.rawValue:
                stage = .fetchFailed
                openFailed(type: .fileNotFound)
                let failedData = fileNotFoundFailedData(reason: BundleI18n.SKResource.Drive_Drive_FileIsNotExist)
                previewStateRelay.onNext(.setupFailed(data: failedData))
                cacheService.deleteFile(dataVersion: nil)
            case DriveFileInfoErrorCode.noPermission.rawValue:
                stage = .fetchFailed
                openFailed(type: .noPermission)
                let data = failedData { [weak self] in
                    guard let self = self else { return }
                    self.stage = .fetchingFileInfo
                    self.fileInfoLoader?.fetchFileInfo()
                }
                previewStateRelay.onNext(.setupFailed(data: data))
                cacheService.deleteFile(dataVersion: nil)
            case DriveFileInfoErrorCode.resourceFrozenByAdmin.rawValue:
                stage = .fetchFailed
                openFailed(type: .fileDeletedOnServer)
                let failedData = fileNotFoundFailedData(reason: BundleI18n.SKResource.Drive_Drive_FileDeleted)
                previewStateRelay.onNext(.setupFailed(data: failedData))
                let alertContent = fileDeletedByAdminAlert(recoverable: true)
                previewActionSubject.onNext(.alert(content: alertContent))
                cacheService.deleteFile(dataVersion: nil)
            case DriveFileInfoErrorCode.resourceShreddedByAdmin.rawValue:
                stage = .fetchFailed
                openFailed(type: .fileDeletedOnServer)
                let failedData = fileNotFoundFailedData(reason: BundleI18n.SKResource.Drive_Drive_FileDeleted)
                previewStateRelay.onNext(.setupFailed(data: failedData))
                let alertContent = fileDeletedByAdminAlert(recoverable: false)
                previewActionSubject.onNext(.alert(content: alertContent))
                cacheService.deleteFile(dataVersion: nil)
            case DriveFileInfoErrorCode.fileKeyDeleted.rawValue:
                stage = .fetchFailed
                let failedData = fileKeyDeletedFailedData()
                previewStateRelay.onNext(.setupFailed(data: failedData))
                cacheService.deleteFile(dataVersion: nil)
            case DriveFileInfoErrorCode.dlpDetectingFailed.rawValue:
                stage = .fetchFailed
                openFailed(type: .dlpDetectingFailed)
                let failedData = fileNotFoundFailedData(reason: BundleI18n.SKResource.LarkCCM_IM_DLP_UnableToViewFileSensitiveInfoNew_Text)
                previewStateRelay.onNext(.setupFailed(data: failedData))
                cacheService.deleteFile(dataVersion: nil)
            default:
                previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.Drive_Drive_GetFileInformationFail, type: .failure))
            }
        default:
            previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.Drive_Drive_GetFileInformationFail, type: .failure))
        }
    }
    
    // 文件被删除或者文件不存在错误
    private func fileNotFoundFailedData(reason: String) -> DKPreviewFailedViewData {
        let canOpen = BehaviorRelay<Bool>(value: false)
        let data = DKPreviewFailedViewData(mainText: reason,
                                           showRetryButton: false,
                                           retryEnable: reachabilityRelay,
                                           retryHandler: {},
                                           showOpenWithOtherApp: canOpen,
                                           openWithOtherEnable: reachabilityRelay,
                                           openWithOtherAppHandler: { _, _ in })
        return data
    }
    
    // 文件密钥被删除场景
    private func fileKeyDeletedFailedData() -> DKPreviewFailedViewData {
        let data = DKPreviewFailedViewData(mainText: BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidCanNotPreview,
                                           image: UDEmptyType.ccmDocumentKeyUnavailable.defaultImage(),
                                           showRetryButton: false,
                                           retryEnable: BehaviorRelay<Bool>(value: false),
                                           retryHandler: {},
                                           showOpenWithOtherApp: BehaviorRelay<Bool>(value: false),
                                           openWithOtherEnable: BehaviorRelay<Bool>(value: false),
                                           openWithOtherAppHandler: { _, _ in })
        return data
    }
    
    private func failedData(retryHandler: @escaping () -> Void) -> DKPreviewFailedViewData {
        let canOpen = BehaviorRelay<Bool>(value: canOpenWithOtherApp)
        let failedData = DKPreviewFailedViewData(showRetryButton: true,
                                                 retryEnable: reachabilityRelay,
                                                 retryHandler: retryHandler,
                                                 showOpenWithOtherApp: canOpen,
                                                 openWithOtherEnable: reachabilityRelay) { [weak self] (sourceView, sourceRect) in
                                                    guard let fileProvider = self?.originFileProvider else { return }
                                                    self?.handleOpenWithOtherApp(fileProvider: fileProvider, sourceView: sourceView, sourceRect: sourceRect)
        }
        return failedData
    }

    private func fileDeletedByAdminAlert(recoverable: Bool) -> DKAlertContent {
        let message = recoverable ? BundleI18n.SKResource.Drive_Sdk_FileNotFoundDialogResourceFrozen : BundleI18n.SKResource.Drive_Sdk_FileNotFoundDialogResourceShredded
        let dismissAction = DKAlertContent.Action(style: .default, title: BundleI18n.SKResource.Drive_Sdk_FileNotFoundDialogIKnow) { [weak self] in
            self?.previewActionSubject.onNext(.exitPreview)
        }
        return DKAlertContent(title: BundleI18n.SKResource.Drive_Sdk_FileNotFoundDialogTitle,
                              message: message,
                              actions: [dismissAction])
    }
    
    func getFileInfoFromCache() -> DKFileInfo {
        let node = try? cacheService.getFile(type: .preview, fileExtension: nil, dataVersion: nil).get()
        let fileName = node?.fileName ?? onlineFile.fileName
        let fileSize = node?.fileSize ?? 0
        var fileInfo = DKFileInfo(appId: appID,
                        fileId: onlineFile.fileID,
                        name: fileName,
                        size: fileSize,
                        fileToken: onlineFile.fileID,
                        authExtra: onlineFile.extraAuthInfo)
        fileInfo.type = fileType.rawValue
        return fileInfo

    }

    func didResumeVCFullWindow() {}
}

// MARK: - Syncing FileInfo Handling
extension DKIMFileCellViewModel {
    private func unsupportState(fileInfo: DKFileProtocol?, type: DriveUnsupportPreviewType) -> DKFilePreviewState {
        let fileName = onlineFile.fileName
        let fileSize: UInt64 = fileInfo?.size ?? performanceRecorder.fileSize ?? 0
        let fileType: String = fileInfo?.type ?? SKFilePath.getFileExtension(from: fileName) ?? ""
        let info = DKUnSupportViewInfo(type: type,
                                       fileName: fileName,
                                       fileSize: fileSize,
                                       fileType: fileType,
                                       buttonVisable: .just(canOpenWithOtherApp),
                                       buttonEnable: reachabilityRelay.asObservable(),
                                       showDocTips: false)
        return .setupUnsupport(info: info, handler: { [weak self] (sourceView, sourceRect) in
            guard let fileProvider = self?.originFileProvider else {
                DocsLogger.error("open with other app need fileProvider")
                return
            }
            self?.handleOpenWithOtherApp(fileProvider: fileProvider, sourceView: sourceView, sourceRect: sourceRect)
        })
    }
    
    private func transcodingState(type: String, handler: (() -> Void)?) -> DKFilePreviewState {
        return .transcoding(
            fileType: type,
            handler: { [weak self] (sourceView, sourceRect) in
                guard let fileProvider = self?.originFileProvider else {
                    DocsLogger.error("open with other app need fileProvider")
                    return
                }
                self?.handleOpenWithOtherApp(fileProvider: fileProvider, sourceView: sourceView, sourceRect: sourceRect)
            },
            downloadForPreviewHandler: handler
        )
    }

    private func startPreview(fileInfo: DKFileInfo) {
        guard let hostVC = hostContainer else {
            spaceAssertionFailure("host container is nil")
            return
        }
        DocsLogger.driveInfo("drive.sdk.context.main --- handling fileInfo")
        
        guard !onlineFile.isEncrypted else {
            DocsLogger.driveInfo("drive.sdk.context.main --- show im file encrypted tips")
            previewStateRelay.onNext(unsupportState(fileInfo: fileInfo, type: .imfileEncrypted))
            return
        }

        guard let previewType = fileInfo.previewType else {
            previewStateRelay.onNext(unsupportState(fileInfo: fileInfo, type: .typeUnsupport))
            return
        }

        let previewVMDependencyImpl = DKPreviewVMDependencyImpl(fileInfo: fileInfo,
                                                                previewType: previewType,
                                                                skipCellularCheck: false,
                                                                netState: reachabilityChanged,
                                                                hostContainer: hostVC,
                                                                performanceRecorder: performanceRecorder)
        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: true,
                                                 canDownloadOrigin: false,
                                                 previewFrom: .im,
                                                 isInVCFollow: isInVCFollow,
                                                 cacheSource: .standard,
                                                 authExtra: nil)
        let onlinePreviewVM = DKPreviewViewModel(fileInfo: fileInfo, isLatest: true, processorConfig: config, dependency: previewVMDependencyImpl)
        onlinePreviewVM.additionalStatisticParameters = statisticsService.additionalParameters
        onlinePreviewVM.output.previewState.asObservable().do(onNext: {[weak self] (state) in
            self?.reportPreviewFailedIfNeed(state: state)
        }).map {[weak self] (state) -> DKFilePreviewState in
            guard let self = self else {
                return .setupFailed(data: DKPreviewFailedViewData.defaultData())
            }
            return self.transformToPreviewState(state)
        }.bind(to: previewStateRelay).disposed(by: disposeBag)
        onlinePreviewVM.output.previewAction.asObservable().bind(to: previewActionSubject).disposed(by: disposeBag)
        stage = .onlinePreviewing(previewVM: onlinePreviewVM)
    }

    /// 处理非异步化 FileInfo 请求的错误
    private func handleFileInfoFailed(error: Error) {
        DocsLogger.warning("drive.sdk.context.main --- fileInfo provider failed with error", error: error)
        stage = .fetchFailed

        let failedType: FailedType
        let canRetry: Bool
        let shouldShowOpenWithOtherApp: Bool
        let failedDescription: String

        if let driveError = error as? DriveError {
            (failedType, canRetry, shouldShowOpenWithOtherApp, failedDescription) = handleFileInfoFailed(driveError: driveError)
            updateNaviBarMoreItem(with: driveError)
        } else {
            failedType = .fetchFileInfoFail(errorMessage: error.localizedDescription)
            canRetry = true
            shouldShowOpenWithOtherApp = canOpenWithOtherApp
            failedDescription = BundleI18n.SKResource.Drive_Drive_LoadingFail
        }

        openFailed(type: failedType)
        
        if case .fileKeyDeleted = failedType {
            // 文件密钥删除场景特殊处理
            let failedData = fileKeyDeletedFailedData()
            previewStateRelay.onNext(.setupFailed(data: failedData))
            return
        }
        let canOpen = BehaviorRelay<Bool>(value: shouldShowOpenWithOtherApp)
        let failedData = DKPreviewFailedViewData(
                mainText: failedDescription,
                showRetryButton: canRetry,
                retryEnable: reachabilityRelay,
                retryHandler: { [weak self] in
                    guard let self = self else { return }
                    self.stage = .fetchingFileInfo
                    self.fileInfoLoader?.fetchFileInfo()
                },
                showOpenWithOtherApp: canOpen,
                openWithOtherEnable: reachabilityRelay,
                openWithOtherAppHandler: { [weak self] (sourceView, sourceRect) in
                    guard let fileProvider = self?.originFileProvider else { return }
                    self?.handleOpenWithOtherApp(fileProvider: fileProvider, sourceView: sourceView, sourceRect: sourceRect)
                })
        previewStateRelay.onNext(.setupFailed(data: failedData))
    }

    private func handleFileInfoFailed(driveError: DriveError) -> (failedType: FailedType, canRetry: Bool, shouldShowOpenWithOtherApp: Bool, failedDescription: String) {
        DocsLogger.warning("drive.sdk.context.main --- handleFileInfoFailed", error: driveError)
        switch driveError {
        case let .serverError(code):
            switch code {
            case DriveFileInfoErrorCode.fileDeletedOnServerError.rawValue:
                cacheService.deleteFile(dataVersion: nil)
                return (.fileDeletedOnServer, false, false, BundleI18n.SKResource.Drive_Drive_FileDeleted)
            case DriveFileInfoErrorCode.fileNotFound.rawValue:
                cacheService.deleteFile(dataVersion: nil)
                return (.fileNotFound, false, false, BundleI18n.SKResource.Drive_Drive_FileIsNotExist)
            case DriveFileInfoErrorCode.noPermission.rawValue:
                cacheService.deleteFile(dataVersion: nil)
                return (.noPermission, true, canOpenWithOtherApp, BundleI18n.SKResource.Drive_Drive_LoadingFail)
            case DriveFileInfoErrorCode.resourceFrozenByAdmin.rawValue:
                let alertContent = fileDeletedByAdminAlert(recoverable: true)
                previewActionSubject.onNext(.alert(content: alertContent))
                cacheService.deleteFile(dataVersion: nil)
                return (.fileDeletedOnServer, false, false, BundleI18n.SKResource.Drive_Drive_FileDeleted)
            case DriveFileInfoErrorCode.resourceShreddedByAdmin.rawValue:
                let alertContent = fileDeletedByAdminAlert(recoverable: false)
                previewActionSubject.onNext(.alert(content: alertContent))
                cacheService.deleteFile(dataVersion: nil)
                return (.fileDeletedOnServer, false, false, BundleI18n.SKResource.Drive_Drive_FileDeleted)
            case DriveFileInfoErrorCode.fileKeyDeleted.rawValue:
                cacheService.deleteFile(dataVersion: nil)
                return (.fileKeyDeleted, false, false, BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidCanNotPreview)
            case DriveFileInfoErrorCode.dlpDetectingFailed.rawValue:
                cacheService.deleteFile(dataVersion: nil)
                return (.dlpDetectingFailed, false, false, BundleI18n.SKResource.LarkCCM_IM_DLP_UnableToViewFileSensitiveInfoNew_Text)
            default:
                return (.fetchFileInfoFail(errorMessage: "Server Error Code: \(code)"), true, canOpenWithOtherApp, BundleI18n.SKResource.Drive_Drive_LoadingFail)
            }
        default:
            return (.fetchFileInfoFail(errorMessage: driveError.localizedDescription), true, canOpenWithOtherApp, BundleI18n.SKResource.Drive_Drive_LoadingFail)
        }
    }
    
    private func transformToPreviewState(_ state: DKPreviewViewModel.State) -> DKFilePreviewState {
        switch state {
        case .loading:
            return .loading
        case .endLoading:
            return .endLoading
        case let .fetchFailed(canRetry, _, handler):
            let canOpen = BehaviorRelay<Bool>(value: canOpenWithOtherApp)
            let failedData = DKPreviewFailedViewData(showRetryButton: canRetry,
                                                     retryEnable: reachabilityRelay,
                                                     retryHandler: handler ?? {},
                                                     showOpenWithOtherApp: canOpen,
                                                     openWithOtherEnable: reachabilityRelay,
                                                     openWithOtherAppHandler: { [weak self] sourceView, sourceRect in
                                                        guard let fileProvider = self?.originFileProvider else { return }
                                                        self?.handleOpenWithOtherApp(fileProvider: fileProvider, sourceView: sourceView, sourceRect: sourceRect)
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

// MARK: - 终止预览信号处理
extension DKIMFileCellViewModel {
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
                self.stopPreview(deleteFile: true)
                self.naviBarItemsRelay.accept([])
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
        self.downloadViewModel?.cancelDownload()
        self.downloadViewModel = nil
        if deleteFile {
            self.cacheService.deleteFile(dataVersion: nil)
        }
    }
}

// MARK: - 配置导航栏
extension DKIMFileCellViewModel {
    private func setupNaviBarItems(moreDependency: DriveSDKMoreDependency) {
        let moreNaviBarItem = setupMoreBarItems(moreDependency: moreDependency)
        let naviBarItems: [DKNaviBarItem] = [moreNaviBarItem]
        DocsLogger.driveInfo("drive.sdk.context.main --- setting up naviBar items", extraInfo: ["naviBarItemsCount": naviBarItems.count])
        naviBarItemsRelay.accept(naviBarItems)
    }
    
    /// 根据 fileInfo 的错误信息，来更新“更多选项”（需求引入背景：KA 私有化的文件发送给 SaaS 租户，Drive 与私有化并不互通，会报错“文件找不到”，此时需移除“保存到云空间”选项）
    private func updateNaviBarMoreItem(with driveError: DriveError) {
        switch driveError {
        case let .serverError(code):
            switch code {
            case DriveFileInfoErrorCode.fileDeletedOnServerError.rawValue,
                 DriveFileInfoErrorCode.fileNotFound.rawValue,
                 DriveFileInfoErrorCode.noPermission.rawValue,
                 DriveFileInfoErrorCode.resourceFrozenByAdmin.rawValue,
                 DriveFileInfoErrorCode.resourceShreddedByAdmin.rawValue:
                // “保存到云空间”的选项不可用
                saveToSpaceStateRelay.accept(.unable)
            case DriveFileInfoErrorCode.fileKeyDeleted.rawValue:
                naviBarItemsRelay.accept([])
                titleRelay.accept("")
            case DriveFileInfoErrorCode.dlpDetectingFailed.rawValue:
                naviBarItemsRelay.accept([])
            default:
                break
            }
        default:
            break
        }
    }

    private func setupMoreBarItems(moreDependency: DriveSDKMoreDependency) -> DKNaviBarItem {
        let moreDependencyImpl = DKMoreDependencyImpl(moreVisable: moreDependency.moreMenuVisable,
                                                      moreEnable: moreDependency.moreMenuEnable,
                                                      isReachable: reachabilityChanged,
                                                      saveToSpaceState: saveToSpaceStateChanged)

        var moreItems = moreDependency.actions.compactMap { (moreAction) -> DKMoreItem? in
            switch moreAction {
            case let .openWithOtherApp(fileProvider):
                self.originFileProvider = fileProvider
                return DKMoreItem(type: .openWithOtherApp) { [weak self] sourceView, sourceRect in
                    guard let self = self else { return }
                    self.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.Doc_Facade_Loading, type: .loading))
                    self.asyncValidate(downloadAction: .openOtherAppForMoreItem, fileProvider: fileProvider, sourceView: sourceView, sourceRect: sourceRect)
                    self.statisticsService.reportClickEvent(DocsTracker.EventType.driveFileMenuClick, clickEventType: DriveStatistic.DriveFileMenuClickEvent.openInOtherApp, params: [:])
                }
            case let .saveToSpace(handler):
                let state: DKMoreItemState
                var response: PermissionResponse?
                if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                    let permissionResponse = permissionService.validate(operation: .upload, bizDomain: .ccm)
                    response = permissionResponse
                    state = permissionResponse.allow ? .normal : .forbidden
                } else {
                    state = self.check(entityOperate: .ccmFileUpload, fileBizDomain: .ccm, docType: .file, token: self.objToken)
                }
                return DKMoreItem(type: .saveToSpace, itemState: state) { [weak self] _, _ in
                    if self?.saveToSpaceState == .unsave {
                        if let response {
                            self?.hostModule?.previewActionSubject.onNext(.customAction(action: { controller in
                                response.didTriggerOperation(controller: controller)
                            }))
                        }
                        switch state {
                        case .normal:
                            self?.handleSaveToSpace(handler: handler)
                        case .forbidden:
                            DocsLogger.error("drive.sdk.context.main --- save to space forbidden",
                                             traceId: response?.traceID)
                        case .deny:
                            DocsLogger.error("drive.sdk.context.main --- admin deny")
                            self?.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, type: .failure))
                        case .fileDeny:
                            DocsLogger.error("drive.sdk.context.main --- Strategies decision deny")
                            self?.previewActionSubject.onNext(.dialog(entityOperate: .ccmFileUpload, fileBizDomain: .im, docType: .file, token: self?.objToken))
                        }
                    } else {
                        self?.handleSaveToSpace(handler: handler)
                    }
                    self?.statisticsService.reportClickEvent(DocsTracker.EventType.driveFileMenuClick, clickEventType: DriveStatistic.DriveFileMenuClickEvent.saveToDrive, params: [:])
                }
            case let .forward(handler):
                return DKMoreItem(type: .forward) { [weak self] _, _ in
                    self?.handleForward(handler: handler)
                    self?.statisticsService.reportClickEvent(DocsTracker.EventType.driveFileMenuClick, clickEventType: DriveStatistic.DriveFileMenuClickEvent.sendToChat, params: [:])
                }
            case let .IMSaveToLocal(fileProvider):
                self.originFileProvider = fileProvider
                return DKMoreItem(type: .saveToLocal) { [weak self] _, _ in
                    guard let self = self else { return }
                    self.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.Doc_Facade_Loading, type: .loading))
                    self.asyncValidate(downloadAction: .saveToLocal, fileProvider: fileProvider, sourceView: nil, sourceRect: nil)
                    self.statisticsService.reportClickEvent(DocsTracker.EventType.driveFileMenuClick, clickEventType: DriveStatistic.DriveFileMenuClickEvent.saveToLocal, params: [:])
                }
            case .convertToOnlineFile:
                DocsLogger.driveInfo("drive.sdk.context.main --- im config convert to online file")
                if shouldShowImportAsOnlineFile() {
                    let state: DKMoreItemState
                    var response: PermissionResponse?
                    if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                        let permissionResponse = permissionService.validate(operation: .importToOnlineDocument, bizDomain: .ccm)
                        response = permissionResponse
                        state = permissionResponse.allow ? .normal : .forbidden
                    } else {
                        state = self.check(entityOperate: .ccmCreateCopy, fileBizDomain: .ccm, docType: .file, token: self.objToken)
                    }
                    DocsLogger.driveInfo("drive.sdk.context.main --- file type support config convert to online file")
                    return DKMoreItem(type: .importAsOnlineFile(fileType: self.fileType), itemState: state) { [weak self] _, _ in
                        guard let self = self else { return }
                        if let response {
                            self.hostModule?.previewActionSubject.onNext(.customAction(action: { controller in
                                response.didTriggerOperation(controller: controller)
                            }))
                        }
                        switch state {
                        case .normal:
                            self.handleImportAs(msgID: self.onlineFile.msgID, fileType: self.fileType)
                        case .forbidden:
                            DocsLogger.error("drive.sdk.context.main --- convert to online file forbidden",
                                             traceId: response?.traceID)
                        case .deny:
                            DocsLogger.error("drive.sdk.context.main --- admin deny")
                            self.hostModule?.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, type: .failure))
                        case .fileDeny:
                            DocsLogger.error("drive.sdk.context.main --- Strategies decision deny")
                            self.hostModule?.previewActionSubject.onNext(.dialog(entityOperate: .ccmCreateCopy, fileBizDomain: .ccm, docType: .file, token: self.objToken))
                        }
                        self.statisticsService.reportClickEvent(DocsTracker.EventType.driveFileMenuClick, clickEventType: DriveStatistic.DriveFileMenuClickEvent.importAs, params: [:])
                    }
                } else {
                    DocsLogger.driveInfo("drive.sdk.context.main --- file type not support convert to online file")
                    return nil
                }
            case let .customUserDefine(provider):
                var customParams: [String: Any] = [:]
                customParams["click"] = provider.actionId
                customParams["target"] = "none"
                return DKMoreItem(type: .customUserDefine, text: provider.text, handler: { [weak self] (_, _) in
                    self?.handlerCustomUserDefine(handler: provider.handler)
                    self?.statisticsService.reportEvent(DocsTracker.EventType.driveFileMenuClick, params: customParams)
                })
            case .saveAlbum, .saveToFile, .customOpenWithOtherApp, .saveToLocal:
                spaceAssertionFailure("IM file not support action: \(moreAction)")
                return nil
            }
        }
        
        let cancelItem = DKMoreItem(type: .cancel) { [weak self] (_, _) in
            self?.statisticsService.reportClickEvent(DocsTracker.EventType.driveFileMenuClick, clickEventType: DriveStatistic.DriveFileMenuClickEvent.cancel, params: [:])
        }
        moreItems.append(cancelItem)
        DocsLogger.driveInfo("drive.sdk.context.main --- setting up more items", extraInfo: ["moreItemCount": moreItems.count])
        let moreViewModel = DKMoreViewModel(dependency: moreDependencyImpl, moreType: .attach(items: moreItems))
        moreViewModel.itemDidClickAction = { [weak self] in
            // 上报点击"更多"事件，以及更多页面展示的事件
            self?.statisticsService.reportClickEvent(DocsTracker.EventType.driveFileOpenClick, clickEventType: DriveStatistic.DriveFileOpenClickEventType.more, params: [:])
            self?.statisticsService.reportEvent(DocsTracker.EventType.driveFileMenuView, params: [:])
        }
        return moreViewModel
    }
    
    // 判断是否展示转在线文档入口
    private func shouldShowImportAsOnlineFile() -> Bool {
        let typeSupport = self.fileType.canImportAsDocs || self.fileType.canImportAsSheet
        return typeSupport
    }

    // MARK: 更多菜单事件处理
    private func handleOpenWithOtherApp(fileProvider: DriveSDKFileProvider, sourceView: UIView?, sourceRect: CGRect?) {
        SecurityReviewManager.reportDriveSDKAction(appID: appID, fileID: onlineFile.fileID,
                                                   operation: .operationsOpenWith3rdApp,
                                                   driveType: fileInfo?.fileType)
        DocsLogger.driveInfo("drive.sdk.context.main --- did click open with other app")
        self.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.Doc_Facade_Loading, type: .loading))
        asyncValidate(downloadAction: .openOtherApp, fileProvider: fileProvider, sourceView: sourceView, sourceRect: sourceRect)
    }
    
    private func handleSaveToLocal(fileProvider: DriveSDKFileProvider) {
        SecurityReviewManager.reportDriveSDKAction(appID: appID, fileID: onlineFile.fileID,
                                                   operation: .operationsDownload,
                                                   driveType: fileInfo?.fileType)
        DocsLogger.driveInfo("drive.sdk.context.main --- did click save to local")
        guard let info = fileInfo else { return }
        if CacheService.isDiskCryptoEnable() {
            DocsLogger.error("[KACrypto] KA crypto enable cannot download")
            self.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.CreationMobile_ECM_SecuritySettingKAToast, type: .tips))
            return
        }
        if let url = fileProvider.localFileURL {
            self.previewActionSubject.onNext(.completeDownloadToSave(fileType: info.fileType, url: url, handler: nil))
        } else {
            guard downloadViewModel == nil else {
                DocsLogger.driveInfo("is already downloading")
                return
            }
            let vm = DKDownloadViewModel(fileProvider: fileProvider, completion: { [weak self] url in
                guard let self = self else { return }
                if let url = url {
                    self.previewActionSubject.onNext(.completeDownloadToSave(fileType: info.fileType, url: url, handler: nil))
                }
                self.downloadViewModel = nil
            })
            self.downloadViewModel = vm
            self.previewActionSubject.onNext(.downloadOriginFile(viewModel: vm, isOpenWithOtherApp: false))
        }
    }
    
    private func handleSaveToSpace(handler: @escaping (DKSaveToSpaceState) -> Void) {
        DocsLogger.driveInfo("drive.sdk.context.main --- did click save to space")
        // 通知按钮被点击，业务方可以进行数据上报等操作
        handler(saveToSpaceState)
        switch saveToSpaceState {
        case let .saved(fileToken):
            previewActionSubject.onNext(.openDrive(token: fileToken, appID: appID))
        case .unsave:
            saveService.saveToSpace().subscribe(onNext: { [weak self] status in
                guard let self = self else { return }
                self.handle(saveToSpaceStatus: status)
            }, onError: { [weak self] error in
                DocsLogger.error("drive.sdk.context.main --- save to space failed with error", error: error)
                self?.handleError(error)
            }).disposed(by: disposeBag)
            statisticsService.reportSaveToSpace()
        case .unable:
            break
        }
    }

    private func handleOpenOtherApp(fileProvider: DriveSDKFileProvider, sourceView: UIView?, sourceRect: CGRect?) {
        if CacheService.isDiskCryptoEnable() {
            DocsLogger.error("[KACrypto] KA crypto enable cannot download")
            self.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.CreationMobile_ECM_ShareSecuritySettingKAToast, type: .tips))
            return
        }
        if let url = fileProvider.localFileURL, !shouldOpenOtherAppDownloadAgain() {
            previewActionSubject.onNext(.openWithOtherApp(url: url, sourceView: sourceView, sourceRect: sourceRect, callback: nil))
        } else {
            guard downloadViewModel == nil else {
                DocsLogger.driveInfo("is already downloading")
                return
            }
            let vm = DKDownloadViewModel(fileProvider: fileProvider, completion: {[weak self] url in
                guard let self = self else { return }
                if let filePath = url {
                    self.previewActionSubject.onNext(.openWithOtherApp(url: filePath, sourceView: sourceView, sourceRect: sourceRect, callback: nil))
                }
                self.downloadViewModel = nil
            })
            downloadViewModel = vm
            previewActionSubject.onNext(.downloadOriginFile(viewModel: vm, isOpenWithOtherApp: true))
        }
    }
    
    private func handleImportAs(msgID: String, fileType: DriveFileType) {
        DocsLogger.driveInfo("drive.sdk.context.main handle import as \(fileType)")
        guard let info = fileInfo else {
            DocsLogger.error("drive.sdk.context.main fileinfo is nil")
            return
        }
        self.previewActionSubject.onNext(.importAs(convertType: .im(info: info, msgID: msgID),
                                                   actionSource: .attachmentMore,
                                                   previewFrom: .im))
    }
    
    private func handleError(_ error: Error) {
        DocsLogger.driveInfo("drive.sdk.context.main saveToSpace error： \(error)")
        if case let .unknownResultCode(code) = error as? DKSaveToSpaceError,
           code == DocsNetworkError.Code.createLimited.rawValue,
           QuotaAlertPresentor.shared.enableTenantQuota {
            self.previewActionSubject.onNext(.storageQuotaAlert)
        } else if case let .unknownResultCode(code) = error as? DKSaveToSpaceError,
                  code == DocsNetworkError.Code.driveUserStorageLimited.rawValue,
                  QuotaAlertPresentor.shared.enableUserQuota {
            self.previewActionSubject.onNext(.userStorageQuotaAlert(token: onlineFile.fileID))
        } else if case let .unknownResultCode(code) = error as? DKSaveToSpaceError,
                  code == DocsNetworkError.Code.spaceFileSizeLimited.rawValue,
                  SettingConfig.sizeLimitEnable {
            guard let fileInfo = self.fileInfo else { return }
            self.previewActionSubject.onNext(.saveToSpaceQuotaAlert(fileSize: Int64(fileInfo.size)))
        } else if case let .unknownResultCode(code) = error as? DKSaveToSpaceError,
                  let docsError = DocsNetworkError(code),
                  let message = docsError.code.errorMessage {
            // 未知的错误码可以转换为 DocsNetworkError，且配置了对应的国际化文案
            self.previewActionSubject.onNext(.toast(content: message, type: .failure))
        } else if case let .unknownResultCode(code) = error as? DKSaveToSpaceError,
                  code == DocsNetworkError.Code.dlpSameTenatDetcting.rawValue {
            self.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.LarkCCM_IM_DLP_UnableToSaveToMySpace_Toast, type: .failure))
        } else if case let .unknownResultCode(code) = error as? DKSaveToSpaceError,
                  code == DocsNetworkError.Code.dlpSameTenatSensitive.rawValue {
            self.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.LarkCCM_IM_DLP_UnableToViewFileSensitiveInfoNew_Text, type: .failure))
        } else {
            if let docsError = error as? DocsNetworkError,
                let message = docsError.code.errorMessage {
                self.previewActionSubject.onNext(.toast(content: message, type: .failure))
            } else {
                self.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.Drive_Drive_SaveFailed, type: .failure))
            }
        }
    }

    private func handle(saveToSpaceStatus status: DKSaveToSpaceStatus) {
        let action: DKPreviewAction
        switch status {
        case let .saved(token):
            saveToSpaceStateRelay.accept(.saved(fileToken: token))
            action = .toast(content: BundleI18n.SKResource.Drive_Sdk_SaveSuccessfully, type: .success)
        case .saving:
            action = .toast(content: BundleI18n.SKResource.Drive_Sdk_Saving, type: .loading)
        case .deleted:
            action = .toast(content: BundleI18n.SKResource.Drive_Drive_SaveFailed, type: .failure)
        case .crossRegionUnsupport:
            action = .toast(content: BundleI18n.SKResource.Drive_Sdk_SaveFailedCantCrossTenant, type: .failure)
        }
        previewActionSubject.onNext(action)
    }

    private func handleForward(handler: @escaping (UIViewController, DKAttachmentInfo) -> Void) {
        DocsLogger.driveInfo("drive.sdk.context.main --- did click forward")
        let fileType = fileInfo?.type ?? SKFilePath.getFileExtension(from: onlineFile.fileName)
        let size = fileInfo?.size ?? 0
        let info = DKAttachmentInfo(fileID: onlineFile.fileID, name: onlineFile.fileName, type: fileType ?? "", size: size)
        previewActionSubject.onNext(.forward(handler: handler, info: info))
    }
    
    private func handlerCustomUserDefine(handler: @escaping (UIViewController, DKAttachmentInfo) -> Void) {
        let fileType = fileInfo?.type ?? SKFilePath.getFileExtension(from: onlineFile.fileName)
        let size = fileInfo?.size ?? 0
        let info = DKAttachmentInfo(fileID: onlineFile.fileID, name: onlineFile.fileName, type: fileType ?? "", size: size)
        previewActionSubject.onNext(.customUserDefine(handler: handler, info: info))
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func check(entityOperate: EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: DocsType, token: String?) -> DKMoreItemState {
        var state: DKMoreItemState = .normal
        let result = cacManager.syncValidate(entityOperate: entityOperate, fileBizDomain: fileBizDomain,
                                                           docType: docType, token: token)
        if result.allow {
            state = .normal
        } else {
            if result.validateSource == .fileStrategy {
                state = .fileDeny
            }
            if result.validateSource == .securityAudit {
                state = .deny
            }
        }
        return state
    }
}
extension DKIMFileCellViewModel {
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
        case fileKeyDeleted
        case dlpDetectingFailed
        case sizeTooBig
    }
    private func openFailed(type: FailedType) {
        DocsLogger.error("DKIMFileCellViewModel -- openFailed type: \(type)")
        // 根据失败类型 上报处理相关逻辑
        switch type {
        case .noNetwork:
            performanceRecorder.openFinish(result: .nativeFail, code: .noNetwork, openType: .unknown)
        case let .fetchFileInfoFail(errorMessage):
            performanceRecorder.openFinish(result: .nativeFail, code: .fetchFileInfoFail, openType: .unknown, extraInfo: ["error_message": errorMessage])
        case .fileDeletedOnServer, .fileKeyDeleted:
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
        case .dlpDetectingFailed:
            performanceRecorder.openFinish(result: .serverFail, code: .fileDeleted, openType: .unknown)
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
            DocsLogger.driveInfo("DKIMFileCellViewModel -- rustStatus: \(rustStatus), reachable: \(rechableStatus)")
            switch rustStatus {
            case .netUnavailable, .offline, .serviceUnavailable:
                return false
            @unknown default:
                return rechableStatus.isReachable
            }
        }.bind(to: reachabilityRelay).disposed(by: disposeBag)
    }
    private func updatePerfomanceRecorder(fileInfo: DKFileInfo) {
        performanceRecorder.fileSize = fileInfo.size
        performanceRecorder.fileType = fileInfo.type
        performanceRecorder.mimeType = fileInfo.mimeType
        performanceRecorder.realMimeType = fileInfo.realMimeType
    }
}

extension DKIMFileCellViewModel {
    
    enum IMDownloadType {
        case openOtherAppForMoreItem
        case saveToLocal
        case openOtherApp
    }

    private func asyncValidate(downloadAction: IMDownloadType, fileProvider: DriveSDKFileProvider, sourceView: UIView?, sourceRect: CGRect?) {
        guard UserScopeNoChangeFG.WWJ.permissionSDKEnable else {
            cacValidate(type: downloadAction, fileProvider: fileProvider, sourceView: sourceView, sourceRect: sourceRect)
            return
        }
        permissionService.asyncValidate(operation: .save,
                                        bizDomain: .customIM(fileBizDomain: .im,
                                                             senderTenantID: onlineFile.senderTenantID)) { [weak self] response in
            guard let self else { return }
            self.previewActionSubject.onNext(.hideLoadingToast)
            self.previewActionSubject.onNext(.customAction(action: { controller in
                response.didTriggerOperation(controller: controller)
            }))
            guard response.allow else { return }
            self.download(type: downloadAction, fileProvider: fileProvider, sourceView: sourceView, sourceRect: sourceRect)
        }
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    func cacValidate(type: IMDownloadType, fileProvider: DriveSDKFileProvider, sourceView: UIView?, sourceRect: CGRect?) {
        self.cacManager.asyncValidate(entityOperate: .imFileDownload,
                                      fileBizDomain: .customIM(fileBizDomain: .im, senderTenantID: onlineFile.senderTenantID),
                                       docType: .imMsgFile,
                                       token: self.objToken) { [weak self] result in
            guard let self = self else { return }
            self.previewActionSubject.onNext(.hideLoadingToast)
            
            guard result.allow else {
                if result.validateSource == .fileStrategy {
                    DocsLogger.error("drive.sdk.context.main --- Strategies decision deny")
                    self.previewActionSubject.onNext(.dialog(entityOperate: .imFileDownload, fileBizDomain: .im, docType: .imMsgFile, token: self.objToken))
                }
                if result.validateSource == .securityAudit {
                    DocsLogger.error("drive.sdk.context.main --- admin deny")
                    self.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, type: .failure))
                }
                return
            }
            self.download(type: type, fileProvider: fileProvider, sourceView: sourceView, sourceRect: sourceRect)
        }
    }

    private func download(type: IMDownloadType, fileProvider: DriveSDKFileProvider, sourceView: UIView?, sourceRect: CGRect?) {
        switch type {
        case .openOtherAppForMoreItem:
            originFileProvider?.canDownload(fromView: sourceView)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] canDownload in
                    guard canDownload else { return }
                    self?.handleOpenWithOtherApp(fileProvider: fileProvider, sourceView: sourceView, sourceRect: sourceRect)
                })
                .disposed(by: disposeBag)
        case .saveToLocal:
            handleSaveToLocal(fileProvider: fileProvider)
        case .openOtherApp:
            handleOpenOtherApp(fileProvider: fileProvider, sourceView: sourceView, sourceRect: sourceRect)
        }
    }

    /// 判断"用其它应用打开"是否需要重新下载
    private func shouldOpenOtherAppDownloadAgain() -> Bool {
        // IM Excel 文件支持编辑情况重新下载，避免编辑回写文件后，用其它应用打开下载的文件不是最新的
        return fileType.isExcel && UserScopeNoChangeFG.ZYP.imWPSEditEnable
    }
}
