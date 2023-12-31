//
//  DKLocalFileCellViewModel.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/6/15.
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
import LarkSecurityComplianceInterface
import LarkDocsIcon

protocol DKLocalFileDependency {
    var appID: String { get }
    var thirdPartyAppID: String? { get }
    var localFile: DriveSDKLocalFileV2 { get }
    // 更多菜单的配置
    var moreConfiguration: DriveSDKMoreDependency { get }
    // 终止预览的信号
    var actionProvider: DriveSDKActionDependency { get }
    // statistics
    var statistics: DKStatisticsService { get }
    // 性能埋点
    var performanceRecorder: DrivePerformanceRecorder { get }
}

extension DriveSDKLocalFileV2 {
    var driveFileType: DriveFileType {
        if let type = fileType {
            return DriveFileType(fileExtension: type)
        } else {
            let type = fileURL.pathExtension
            return DriveFileType(fileExtension: type)
        }
    }
    var fileToken: String {
        return fileURL.absoluteString.md5()
    }
}

class DKLocalFileCellViewModel: DKFileCellViewModelType {
    
    var title: String {
        return titleRelay.value
    }
    // fake
    var objToken: String {
        return localFile.fileID
    }
    var fileType: DriveFileType {
        return DriveFileType(fileExtension: localFile.fileType)
    }
    
    var previewFromScene: DrivePreviewFrom {
        return statisticsService.previewFrom
    }
    
    var fileID: String {
        return localFile.fileID
    }

    let permissionService: UserPermissionService
    private var cacManager: CACManagerBridge.Type
    
    var canReadAndCanCopy: Observable<(Bool, Bool)>? {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let canCopy = permissionService.validate(operation: .copyContent).allow
            let canRead = permissionService.validate(operation: .view).allow
            return .just((canRead, canCopy))
        } else {
            return Observable<(Bool, Bool)>.just((true, true))
        }
    }
    
    typealias Dependency = DKLocalFileDependency
    private let appID: String
    private let thirdPartyAppID: String?
    private let localFile: DriveSDKLocalFileV2
    
    private let previewActionSubject = ReplaySubject<DKPreviewAction>.create(bufferSize: 1)
    var previewAction: Observable<DKPreviewAction> {
        previewActionSubject.debug("previewActionSubject").asObservable()
    }
    var isInVCFollow: Bool = false
    
    // 业务埋点
    let statisticsService: DKStatisticsService
    // 性能埋点
    let performanceRecorder: DrivePerformanceRecorder
    // 是否需要展示水印
    var shouldShowWatermark: Bool {
        return false
    }
    var urlForSuspendable: String? {
        return nil
    }
    var hostModule: DKHostModuleType? {
        return nil
    }
    /// 业务方配置的导航栏按钮，如“更多”
    private let naviBarItemsRelay: BehaviorRelay<[DKNaviBarItem]>
    /// 预览业务配置的额外的导航栏按钮，如“PPT 演示模式”
    private let additionRightNaviBarItemsRelay = BehaviorRelay<[DKNaviBarItem]>(value: [])
    private let additionLeftNaviBarItemsRelay = BehaviorRelay<[DKNaviBarItem]>(value: [])
    /// 文件标题
    private let titleRelay: BehaviorRelay<String>
    /// 预览状态更新
    private let previewStateRelay = ReplaySubject<DKFilePreviewState>.create(bufferSize: 1)
    var previewStateUpdated: Driver<DKFilePreviewState> {
        previewStateRelay.asDriver(onErrorJustReturn: .setupFailed(data: DKPreviewFailedViewData.defaultData()))
    }
    
    
    /// 拷贝的临时预览文件路径
    private var tempFileURL: SKFilePath?

    private var fileNotFounded: Bool {
        return !localFile.absFilePath.exists
    }
    
    private var fileIsEmpty: Bool {
        return (localFile.absFilePath.fileSize ?? 0) == 0
    }
    
    private var localCacheKey: String {
        return "local_\(appID)_\(localFile.fileToken)"
    }

    
    /// 仅用于绑定外部事件，如退出预览、停止预览
    private let actionBag = DisposeBag()
    private var canOpenWithOtherApp: Bool {
        let canOpen: Bool
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            canOpen = permissionService.validate(operation: .openWithOtherApp).allow
        } else {
            canOpen = cacManager.syncValidate(entityOperate: .ccmFileDownload, fileBizDomain: .ccm,
                                              docType: .file, token: localFile.fileToken).allow
        }
        let canExport = localFile.dependency.moreDependency.actions.contains { (action) -> Bool in
            switch action {
            case .openWithOtherApp, .customOpenWithOtherApp:
                return true
            case .forward, .saveToSpace, .saveAlbum, .saveToFile, .saveToLocal, .IMSaveToLocal, .convertToOnlineFile, .customUserDefine:
                return false
            }
        }
        return canOpen && canExport
    }
    init(dependency: Dependency,
         permissionService: UserPermissionService,
         cacManager: CACManagerBridge.Type = CACManager.self) {
        self.appID = dependency.appID
        self.thirdPartyAppID = dependency.thirdPartyAppID
        self.localFile = dependency.localFile
        self.statisticsService = dependency.statistics
        self.performanceRecorder = dependency.performanceRecorder
        self.cacManager = cacManager
        self.permissionService = permissionService
        naviBarItemsRelay = BehaviorRelay<[DKNaviBarItem]>(value: [])
        titleRelay = BehaviorRelay<String>(value: localFile.fileName)
        let rightBarItemsChanged = Observable<[DKNaviBarItem]>.combineLatest(naviBarItemsRelay, additionRightNaviBarItemsRelay, resultSelector: +)
        let emptyNaviBarItemsRelay = BehaviorRelay<[DKNaviBarItem]>(value: [])
        let leftBarItemsChanged = Observable<[DKNaviBarItem]>.combineLatest(emptyNaviBarItemsRelay, additionLeftNaviBarItemsRelay, resultSelector: +)
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
        DocsLogger.driveInfo("DKLocalFileCellViewModel - deinit")
    }

    func startPreview(hostContainer: UIViewController) {
        performanceRecorder.openStart(isInVC: isInVCFollow, contextVC: hostContainer)
        statisticsService.enterPreview()
        if fileNotFounded {
            performanceRecorder.openFinish(result: .nativeFail, code: .localFileNotFound, openType: .unknown)
            handleBizPreviewFailed(canRetry: false)
            return
        }
        if fileIsEmpty {
            performanceRecorder.openFinish(result: .nativeFail, code: .previewFileIsEmpty, openType: .unknown)
            handleBizPreviewFailed(canRetry: false)
            return
        }
        
        if localFile.driveFileType.isSupport {
            previewStateRelay.onNext(.loading)
            performanceRecorder.stageBegin(stage: .fileIsOpen)
            prepareFileIfNeeded { [weak self] (url) in
                guard let self = self else { return }
                let fileURL = url ?? self.localFile.absFilePath
                DispatchQueue.main.async {
                    self.previewStateRelay.onNext(.endLoading)
                    self.previewStateRelay.onNext(self.setupPreviewState(filePath: fileURL))
                }
            }
        } else {
            let codec = self.localFile.absFilePath.getVideoCodecType()
            DocsLogger.driveInfo("video codec: \(codec)")
            performanceRecorder.openFinish(result: .nativeFail, code: .localUnsupportFileType, openType: .unknown)
            handleBizPreviewUnsupport(type: .typeUnsupport)
        }
    }
    func willChangeMode(_ mode: DrivePreviewMode) {
        DocsLogger.driveInfo("local file does not support card Mode")
    }
    func changingMode(_ mode: DrivePreviewMode) {
        DocsLogger.driveInfo("local file does not support card Mode")
    }
    func didChangeMode(_ mode: DrivePreviewMode) {
        DocsLogger.driveInfo("local file does not support card Mode")
        
    }
    func reset() {
        DocsLogger.driveInfo("reset do nothing")
    }
    
    let naviBarViewModel = ReplaySubject<DKNaviBarViewModel>.create(bufferSize: 1)

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
        additionLeftNaviBarItemsRelay.accept(leftNaviBarItems)
        additionRightNaviBarItemsRelay.accept(rightNaviBarItems)
    }
    
    func handle(previewAction: DKPreviewAction) {
        previewActionSubject.onNext(previewAction)
    }
    
    func handleOpenFileSuccessType(openType: DriveOpenType) {}
    
    func handleBizPreviewFailed(canRetry: Bool) {
        let failedData = DKPreviewFailedViewData(showRetryButton: canRetry,
                                                 retryEnable: BehaviorRelay<Bool>(value: canRetry),
                                                 retryHandler: {},
                                                 showOpenWithOtherApp: BehaviorRelay<Bool>(value: canOpenWithOtherApp),
                                                 openWithOtherEnable: BehaviorRelay<Bool>(value: canOpenWithOtherApp)) { [weak self] (sourceView, sourceRect) in
            guard let self = self else { return }
            let (action, callback) = self.customOpenOtherAppAction()
            self.handleOpenWithOtherApp(customAction: action, sourceView: sourceView, sourceRect: sourceRect, callback: { [weak self] shareType, success in
                guard let self = self else { return }
                let info = self.attachmentInfo()
                callback?(info, shareType, success)
            })
        }
        previewStateRelay.onNext(.setupFailed(data: failedData))
    }
    
    func handleBizPreviewDowngrade() { }
    
    func handleBizPreviewUnsupport(type: DriveUnsupportPreviewType) {
        previewStateRelay.onNext(unsupportState(type: type))
    }

    func didResumeVCFullWindow() {}
}

// MARK: - 终止预览信号处理
extension DKLocalFileCellViewModel {
    private func setupExternalAction(actionProvider: DriveSDKActionDependency) {
        actionProvider.closePreviewSignal.debug("xxxxxxxxxx2")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.previewActionSubject.onNext(.exitPreview)
                self.clearTempFile()
                // 删除缓存数据
            }).disposed(by: actionBag)

        actionProvider.stopPreviewSignal.debug("xxxxxxxxxx2")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] reason in
                guard let self = self else { return }
                // 收到外部的停止预览信号，需要中断内部的订阅，避免继续加载数据
                self.clearTempFile()
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
}

// MARK: - 配置导航栏
extension DKLocalFileCellViewModel {
    private func setupNaviBarItems(moreDependency: DriveSDKMoreDependency) {
        let moreNaviBarItem = setupMoreBarItems(moreDependency: moreDependency)
        let naviBarItems: [DKNaviBarItem] = [moreNaviBarItem]
        DocsLogger.driveInfo("DKLocalFileMainViewModel --- setting up naviBar items", extraInfo: ["naviBarItemsCount": naviBarItems.count])
        naviBarItemsRelay.accept(naviBarItems)
    }

    private func setupMoreBarItems(moreDependency: DriveSDKMoreDependency) -> DKNaviBarItem {
        let moreDependencyImpl = DKMoreDependencyImpl(moreVisable: moreDependency.moreMenuVisable,
                                                      moreEnable: moreDependency.moreMenuEnable,
                                                      isReachable: Observable<Bool>.just(true),
                                                      saveToSpaceState: Observable.just(.unable))

        var moreItems = moreDependency.actions.compactMap { (moreAction) -> DKMoreItem? in
            switch moreAction {
            case let .customOpenWithOtherApp(action, callback):
                let state: DKMoreItemState
                var response: PermissionResponse?
                if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                    let permissionResponse = permissionService.validate(operation: .openWithOtherApp)
                    response = permissionResponse
                    state = permissionResponse.allow ? .normal : .forbidden
                } else {
                    state = self.check(entityOperate: .ccmFileDownload, fileBizDomain: self.previewFromScene.transfromBizDomainDownloadPoint, docType: .file, token: self.objToken)
                }
                return DKMoreItem(type: .openWithOtherApp, itemState: state) { [weak self] sourceView, sourceRect in
                    guard let self = self else { return }
                    if let response {
                        self.previewActionSubject.onNext(.customAction(action: { controller in
                            response.didTriggerOperation(controller: controller)
                        }))
                    }
                    switch state {
                    case .normal:
                        self.handleOpenWithOtherApp(customAction: action, sourceView: sourceView, sourceRect: sourceRect, callback: { shareType, success in
                            let info = self.attachmentInfo()
                            callback?(info, shareType, success)
                        })
                    case .forbidden:
                        DocsLogger.error("drive.sdk.context.main --- open with other app forbidden",
                                         traceId: response?.traceID)
                    case .deny:
                        DocsLogger.error("DKLocalFileMainViewModel --- admin deny")
                        self.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, type: .failure))
                    case .fileDeny:
                        DocsLogger.error("drive.sdk.context.main --- Strategies decision deny")
                        self.previewActionSubject.onNext(.dialog(entityOperate: .ccmFileDownload, fileBizDomain: self.previewFromScene.transfromBizDomainDownloadPoint, docType: .file, token: self.objToken))
                    }
                    self.statisticsService.reportClickEvent(DocsTracker.EventType.driveFileMenuClick, clickEventType: DriveStatistic.DriveFileMenuClickEvent.openInOtherApp, params: [:])
                }
            case let .saveToLocal(handler):
                let state: DKMoreItemState
                var response: PermissionResponse?
                if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                    let permissionResponse = permissionService.validate(operation: .saveFileToLocal)
                    response = permissionResponse
                    state = permissionResponse.allow ? .normal : .forbidden
                } else {
                   state = self.check(entityOperate: .ccmFileDownload, fileBizDomain: self.previewFromScene.transfromBizDomainDownloadPoint, docType: .file, token: self.objToken)
                }
                return DKMoreItem(type: .saveToLocal, itemState: state) { [weak self] _, _ in
                    guard let self = self else { return }
                    if let response {
                        self.previewActionSubject.onNext(.customAction(action: { controller in
                            response.didTriggerOperation(controller: controller)
                        }))
                    }
                    switch state {
                    case .normal:
                        self.handleSaveToLocal(info: self.localFile, handler: handler)
                    case .forbidden:
                        DocsLogger.error("drive.sdk.context.main --- save file to local forbidden",
                                         traceId: response?.traceID)
                    case .deny:
                        DocsLogger.error("DKLocalFileMainViewModel --- admin deny")
                        self.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, type: .failure))
                    case .fileDeny:
                        DocsLogger.error("drive.sdk.context.main --- Strategies decision deny")
                        self.previewActionSubject.onNext(.dialog(entityOperate: .ccmFileDownload, fileBizDomain: self.previewFromScene.transfromBizDomainDownloadPoint, docType: .file, token: self.objToken))
                    }

                    self.statisticsService.reportClickEvent(DocsTracker.EventType.driveFileMenuClick, clickEventType: DriveStatistic.DriveFileMenuClickEvent.saveToLocal, params: [:])
                }
            case let .customUserDefine(provider):
                var customParams: [String: Any] = [:]
                customParams["click"] = provider.actionId
                customParams["target"] = "none"
                return DKMoreItem(type: .customUserDefine, text: provider.text, handler: { [weak self] (_, _) in
                    guard let self = self else { return }
                    self.handlerCustomUserDefine(handler: provider.handler)
                    self.statisticsService.reportEvent(DocsTracker.EventType.driveFileMenuClick, params: customParams)
                })
            case .saveToSpace, .forward, .saveAlbum, .saveToFile, .openWithOtherApp, .IMSaveToLocal, .convertToOnlineFile:
                spaceAssertionFailure("DKLocalFileMainViewModel --- local file not support action: \(moreAction)")
                return nil
            }
        }
        
        let cancelItem = DKMoreItem(type: .cancel) { [weak self] (_, _) in
            self?.statisticsService.reportClickEvent(DocsTracker.EventType.driveFileMenuClick, clickEventType: DriveStatistic.DriveFileMenuClickEvent.cancel, params: [:])
        }
        moreItems.append(cancelItem)
        DocsLogger.driveInfo("DKLocalFileMainViewModel --- setting up more items", extraInfo: ["moreItemCount": moreItems.count])
        let moreViewModel = DKMoreViewModel(dependency: moreDependencyImpl, moreType: .attach(items: moreItems))
        moreViewModel.itemDidClickAction = { [weak self] in
            // 上报点击"更多"事件，以及更多页面展示的事件
            self?.statisticsService.reportClickEvent(DocsTracker.EventType.driveFileOpenClick, clickEventType: DriveStatistic.DriveFileOpenClickEventType.more, params: [:])
            self?.statisticsService.reportEvent(DocsTracker.EventType.driveFileMenuView, params: [:])
        }
        return moreViewModel
    }
    
    private func attachmentInfo() -> DKAttachmentInfo {
        let fileSize: UInt64 = localFile.absFilePath.fileSize ?? 0
        return DKAttachmentInfo(fileID: self.fileID.md5(),
                                    name: self.localFile.fileName,
                                    type: self.fileType.rawValue,
                                size: fileSize,
                                localPath: self.localFile.fileURL)
    }

    // MARK: 更多菜单事件处理
    private func handleOpenWithOtherApp(customAction: ((UIViewController) -> Void)?,
                                        sourceView: UIView?,
                                        sourceRect: CGRect?,
                                        callback: ((String, Bool) -> Void)?) {
        SecurityReviewManager.reportDriveSDKLocalAction(appID: appID, fileID: localFile.fileID,
                                                        operation: .operationsOpenWith3rdApp,
                                                        driveType: localFile.driveFileType,
                                                        thirdPartyID: thirdPartyAppID)
        DocsLogger.driveInfo("DKLocalFileMainViewModel --- did click open with other app")
        guard !fileNotFounded else {
            spaceAssertionFailure("DKLocalFileMainViewModel --- local file not found")
            return
        }

        if let action = customAction {
            previewActionSubject.onNext(.customAction(action: action))
        } else {
            previewActionSubject.onNext(.openWithOtherApp(url: localFile.fileURL,
                                                          sourceView: sourceView,
                                                          sourceRect: sourceRect,
                                                          callback: callback))
        }
    }
    
    private func handleSaveToLocal(info: DriveSDKLocalFileV2, handler: ((UIViewController, DKAttachmentInfo) -> Void)?) {
        SecurityReviewManager.reportDriveSDKLocalAction(appID: appID, fileID: localFile.fileID,
                                                        operation: .operationsDownload,
                                                        driveType: localFile.driveFileType,
                                                        thirdPartyID: thirdPartyAppID)
        DocsLogger.driveInfo("DKLocalFileMainViewModel --- did click save to local")
        guard !fileNotFounded else {
            spaceAssertionFailure("DKLocalFileMainViewModel --- local file not found")
            return
        }
        let path = info.fileURL
        let attachInfo = attachmentInfo()
        previewActionSubject.onNext(.completeDownloadToSave(fileType: info.driveFileType, url: path, handler: { vc in
            handler?(vc, attachInfo)
        }))
    }
    
    private func handlerCustomUserDefine(handler: @escaping (UIViewController, DKAttachmentInfo) -> Void) {
        let fileType = localFile.fileType
        let size = localFile.absFilePath.fileSize ?? 0
        let info = DKAttachmentInfo(fileID: localFile.fileID, name: localFile.fileName, type: fileType ?? "", size: size, localPath: localFile.fileURL)
        previewActionSubject.onNext(.customUserDefine(handler: handler, info: info))
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func check(entityOperate: EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: DocsType, token: String?) -> DKMoreItemState {
        var state: DKMoreItemState = .normal
        let result = cacManager.syncValidate(entityOperate: entityOperate, fileBizDomain: fileBizDomain,
                                                           docType: docType, token: token)
        if !result.allow && result.validateSource == .fileStrategy {
            state = .fileDeny
        } else if !result.allow && result.validateSource == .securityAudit {
            state = .deny
        } else if result.allow {
            state = .normal
        }
        return state
    }
}

extension DKLocalFileCellViewModel {
    /// 针对文件路径的文件类型为空，但是指定了 fileType 的情况，复制一份临时文件并带上文件类型
    func prepareFileIfNeeded(completion: @escaping (SKFilePath?) -> Void) {
        guard localFile.absFilePath.pathURL.pathExtension.isEmpty,
              let fileType = localFile.fileType,
              localFile.driveFileType != .unknown else {
            completion(nil)
            return
        }
        let oldURL = localFile.absFilePath
        // 用 UUID 作为文件名，并带上文件类型后缀
        let newFileName = UUID().uuidString + ".\(fileType)"
        guard let newURL = self.cacheDirectory()?.appendingRelativePath(newFileName) else {
            DocsLogger.error("get new url failed")
            completion(nil)
            return
        }
        DispatchQueue.global().async {
            if oldURL.copyItem(to: newURL) {
                // 设置临时文件 URL，用于退出预览时清理
                self.tempFileURL = newURL
                completion(newURL)
            } else {
                completion(oldURL)
            }
        }
    }
    
    func clearTempFile() {
        guard let tempFileURL = tempFileURL else { return }
        DispatchQueue.global().async {
            try? tempFileURL.removeItem()
        }
    }
    /// 获取临时目录
    private func cacheDirectory() -> SKFilePath? {
        let cacheDirectory = SKFilePath.driveCacheDir.appendingRelativePath("ccm.drive.localpreview.temp")
        if cacheDirectory.createDirectoryIfNeeded() {
            return cacheDirectory
        }
        return nil
    }

    private func unsupportState(type: DriveUnsupportPreviewType) -> DKFilePreviewState {
        let fileName = localFile.fileName
        let fileSize: UInt64 = localFile.absFilePath.fileSize ?? 0
        let fileType: String = localFile.fileType ?? localFile.fileURL.pathExtension
        let info = DKUnSupportViewInfo(type: type,
                                       fileName: fileName,
                                       fileSize: fileSize,
                                       fileType: fileType,
                                       buttonVisable: .just(canOpenWithOtherApp),
                                       buttonEnable: .just(canOpenWithOtherApp),
                                       showDocTips: false)
        return .setupUnsupport(info: info, handler: { [weak self] (sourceView, sourceRect) in
            guard let self = self else { return }
            let (action, callback) = self.customOpenOtherAppAction()
            self.handleOpenWithOtherApp(customAction: action, sourceView: sourceView, sourceRect: sourceRect, callback: { [weak self] shareType, success in
                guard let self = self else { return }
                let info = self.attachmentInfo()
                callback?(info, shareType, success)
            })
        })
    }
    
    private func setupPreviewState(filePath: SKFilePath) -> DKFilePreviewState {
        let codec = filePath.getVideoCodecType()
        DocsLogger.driveInfo("video codec: \(codec)")
        if localFile.driveFileType.isMedia && localFile.driveFileType.isVideoPlayerSupport {
            let fileSize: UInt64 = localFile.absFilePath.fileSize ?? 0
            let videoInfo = DriveVideo(type: .local(url: filePath), info: nil, title: localFile.fileName, size: fileSize, cacheKey: localCacheKey, authExtra: nil)
            let previewInfo = DKFilePreviewInfo.localMedia(url: filePath, video: videoInfo)
            return DKFilePreviewState.setupPreview(type: localFile.driveFileType, info: previewInfo)
        } else {
            let localData = DKFilePreviewInfo.LocalPreviewData(url: filePath,
                                                               originFileType: localFile.driveFileType,
                                                               fileName: localFile.fileName,
                                                               previewFrom: statisticsService.previewFrom,
                                                               additionalStatisticParameters: statisticsService.additionalParameters)
            let previewInfo = DKFilePreviewInfo.local(data: localData)
            return DKFilePreviewState.setupPreview(type: localFile.driveFileType, info: previewInfo)
        }
    }
    
    private func customOpenOtherAppAction() -> (((UIViewController) -> Void)?, ((DKAttachmentInfo, String, Bool) -> Void)?) {
        // 判断业务是否配置了自定义使用其他应用打开
        var customOpenOtherAppAction: ((UIViewController) -> Void)?
        var actionCallbak: ((DKAttachmentInfo, String, Bool) -> Void)?
        for action in self.localFile.dependency.moreDependency.actions {
            if case let .customOpenWithOtherApp(action, callback) = action {
                customOpenOtherAppAction = action
                actionCallbak = callback
            }
        }
        return (customOpenOtherAppAction, actionCallbak)
    }
}
