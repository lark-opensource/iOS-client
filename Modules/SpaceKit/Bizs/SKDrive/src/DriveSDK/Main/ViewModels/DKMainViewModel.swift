//
//  DKMainViewModel.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/6/14.
//
//  swiftlint:disable file_length

import Foundation
import SKFoundation
import SpaceInterface
import RxSwift
import RxRelay
import RxCocoa
import SKCommon
import SKResource
import SKUIKit
import CoreImage
import SwiftyJSON
import SKInfra
import UniverseDesignToast
import LarkContainer
import LarkQuickLaunchInterface
import LarkTab
import LarkDocsIcon


class DKMainViewModel: NSObject, DriveShadowFileViewModelProtocol, DKMainViewModelType {
    var objToken: String {
        return curModel.fileID
    }
    
    var title: String {
        return curModel.title
    }
    
    var fileType: DriveFileType {
        return curModel.fileType
    }
    
    var previewFrom: DrivePreviewFrom {
        return performanceRecorder.previewFrom
    }
    let bulletinManager: DocsBulletinManager?
    var currentNotice: BulletinInfo?
    var previewUIStateManager: DriveUIStateManager

    private var bag = DisposeBag()
    let naviBarViewModelRelay = BehaviorRelay<DKNaviBarViewModel>(value: DKNaviBarViewModel.emptyBarViewModel)

    private let previewActionSubject = PublishSubject<DKPreviewAction>()
    private var viewModels: [DKFileCellViewModelType] // 支持多文件预览的文件列表，目前只有图片文件支持多文件，其他文件只支持单文件预览
    private var originViewModels: [DKFileCellViewModelType] // 外部传入的文件列表
    private var curModel: DKFileCellViewModelType
    private var openType: DriveOpenType = .unknown
    //公告drive识别码
    static let bulletinIdentifier: String = "file"
    // 自动化测试
    private let _readyToStart = PublishSubject<()>()
    lazy var readyToStart: Driver<()> = {
        return _readyToStart.asObservable().asDriver(onErrorJustReturn: ())
    }()
    private var request: DocsRequest<JSON>?

    
    /// 仅用于绑定外部事件，如退出预览、停止预览
    private var actionBag = DisposeBag()
    
    var performanceRecorder: DrivePerformanceRecorder
    
    var statisticsService: DKStatisticsService
    var fileDeleted: Bool = false
    
    var hostModule: DKHostModuleType?
    var shouldShowCommentBar: Bool {
        DocsLogger.driveInfo("uiState: shouldShowCommentBar: \(hostModule?.commentManager != nil)")
        return hostModule?.commentManager != nil
    }
    
    var isSpaceFile: Bool {
        guard let host = hostModule else { return false }
        return (host.scene == .space)
    }
    var additionalStatisticParameters: [String: String] {
        get {
            return statisticsService.additionalParameters
        }
        set {
            statisticsService.additionalParameters = newValue
        }
    }
    
    private let _fileListChanged = PublishSubject<()>()
    lazy var reloadData: Driver<Int> = {
        return _fileListChanged.flatMap({[weak self] _ -> Observable<Int> in
            guard let self = self else { return Observable.empty() }
            return Observable.just(self.curIndex)
        }).asDriver(onErrorJustReturn: 0)
    }()

    private weak var dlpTimer: Timer?
    
    private var collaboratorsCountRelay: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    
    init(files: [DKFileCellViewModelType], initialIndex: Int, supportLandscape: Bool) {
        self.originViewModels = files
        self.viewModels = files
        self.curIndex = initialIndex
        self.supportLandscape = supportLandscape
        self.curModel = self.viewModels[initialIndex]
        self.performanceRecorder = self.viewModels[initialIndex].performanceRecorder
        self.hostModule = self.viewModels[initialIndex].hostModule
        self.statisticsService = self.viewModels[initialIndex].statisticsService
        self.bulletinManager = DocsContainer.shared.resolve(DocsBulletinManager.self)
        self.previewUIStateManager = DriveUIStateManager(scene: hostModule?.scene ?? .space,
                                                         dependency: DriveUIStateManagerDependencyImpl())
        super.init()
        // 判断是否支持多文件预览，并过滤文件
        (viewModels, curIndex) = self.filterFiles()
        bulletinManager?.addObserver(self)
    }
    
    deinit {
        DocsLogger.driveInfo("DKMainViewModel -- deinit")
        bulletinManager?.removeObserver(self)
        dlpTimer?.invalidate()
        dlpTimer = nil
    }
    
    var supportLandscape: Bool
    var shouldShowWatermark: Bool {
        guard curIndex < viewModels.count, curIndex >= 0 else { return false }
        let curVM = viewModels[curIndex]
        return curVM.shouldShowWatermark
    }
    
    @InjectedSafeLazy private var temporaryTabService: TemporaryTabService
    
    func numberOfFiles() -> Int {
        return viewModels.count
    }
    
    func didChangeMode(_ mode: DrivePreviewMode) {
         curModel.didChangeMode(mode)
    }
    
    func willChangeMode(_ mode: DrivePreviewMode) {
         curModel.willChangeMode(mode)
    }
    
    func changingMode(_ mode: DrivePreviewMode) {
         curModel.changingMode(mode)
    }
    
    // 开始加载index对应的cell的文件预览信息
    func cellViewModel(at index: Int) -> DKFileCellViewModelType {
        guard index >= 0 && index < viewModels.count else {
            spaceAssertionFailure("DKIMMainViewModel: invalid index")
            curIndex = 0
            return viewModels[0]
        }
        curIndex = index
        let vm = viewModels[curIndex]
        setupCellViewModel(vm: vm)
        return vm
    }
    
    func title(of index: Int) -> String {
        guard index >= 0, index < viewModels.count else {
            DocsLogger.driveInfo("DKIMMainViewModel: invalid index")
            return ""
        }
        let cellVM = viewModels[index]
        return cellVM.title
    }
    var curIndex: Int = 0
    
    var naviBarViewModel: Driver<DKNaviBarViewModel> {
        return naviBarViewModelRelay.asDriver()
    }
    
    var previewAction: Observable<DKPreviewAction> {
        return previewActionSubject.asObservable()
    }
    
    var subTitle: String?

    func setupCellViewModel(vm: DKFileCellViewModelType, mockFG: Bool? = nil) {
        actionBag = DisposeBag()
        curModel = vm
        if viewModels.count > 1 {
            subTitle = "\(curIndex + 1)/\(viewModels.count)"
        } else {
            // 历史版本
            if let editTime = vm.hostModule?.commonContext.hitoryEditTimeStamp {
                subTitle = editTime
            } else {
                subTitle = nil
            }
        }
        self.performanceRecorder = vm.performanceRecorder
        let additionalParams = statisticsService.additionalParameters
        self.statisticsService = vm.statisticsService
        self.additionalStatisticParameters = additionalParams
        self.hostModule = vm.hostModule
        vm.previewAction.debug("previewAction").bind(to: previewActionSubject).disposed(by: actionBag)
        vm.previewAction.subscribe(onNext: {[weak self] action in
            guard let self = self else { return }
            self.disableMultiFileIfNeed(action: action)
        }).disposed(by: actionBag)
        vm.naviBarViewModel.debug("naviViewModel").bind(to: naviBarViewModelRelay).disposed(by: actionBag)
        monitorFileInfo()
        monitorDocsInfo()
        monitorDocsInfoUpdate()
        monitorCollaborators()
        monitorSerectInfo(sensitivtyLabelEnable: mockFG ?? LKFeatureGating.sensitivtyLabelEnable)
        self._readyToStart.onNext(())
    }
    private func disableMultiFileIfNeed(action: DKPreviewAction) {
        guard case let DKPreviewAction.openSuccess(openType: openType) = action else {
            return
        }
        // 使用quicklook打开
        self.openType = openType
        guard openType == .quicklook else {
            return
        }
        let oldList = self.viewModels
        (self.viewModels, self.curIndex) = disableMultiFile()
        if oldList.count != self.viewModels.count {
            self._fileListChanged.onNext(())
        }
    }
    
    private func disableMultiFile() -> (newList: [DKFileCellViewModelType], index: Int) {
        guard !viewModels.isEmpty, viewModels.count > curIndex && curIndex >= 0 else {
            DocsLogger.error("params error curIndex: \(curIndex), fileList count: \(viewModels.count)")
            return (viewModels, 0)
        }
        let curFile = viewModels[curIndex]
        return ([curFile], 0)
    }
    private func monitorFileInfo() {
        hostModule?.fileInfoErrorOb
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] err in
            guard let self = self else { return }
            guard let error = err else {
                self.fileDeleted = false
                return
            }
            switch error {
            case let .serverError(code):
                self.fileDeleted = (code == DriveFileInfoErrorCode.fileDeletedOnServerError.rawValue
                                    || code == DriveFileInfoErrorCode.fileNotFound.rawValue)
            default:
                self.fileDeleted = false
            }
        }).disposed(by: actionBag)
        hostModule?.fileInfoRelay.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            // 判断是否需要更新文件列表，图片变为其他文件，或者其他文件重命名为图片的情况
            let oldList = self.viewModels
            (self.viewModels, self.curIndex) = self.filterFiles()
            if oldList.count != self.viewModels.count {
                self._fileListChanged.onNext(())
            }
        }).disposed(by: actionBag)
    }
    
    private func monitorDocsInfoUpdate() {
        hostModule?.docsInfoRelay
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            guard let vc = self.hostModule?.hostController as? TabContainable else { return }
            guard vc.isTemporaryChild else {
                DocsLogger.driveInfo(" open DKMainViewController is not from Temporary")
                return
            }
            if self.hostModule?.commonContext.previewFrom == .wiki {
                guard let parentVC = vc.parent as? TabContainable else { return }
                self.temporaryTabService.updateTab(parentVC)
            } else {
                self.temporaryTabService.updateTab(vc)
            }
        }).disposed(by: actionBag)
    }
    
    private func monitorDocsInfo() {
        guard LKFeatureGating.docDlpEnable else { return }
        guard let hostModule = hostModule else {
            DocsLogger.error("HostModule does not exsit")
            return
        }
        let docsInfoUpdate: Observable<DocsInfo>
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            docsInfoUpdate = Observable.combineLatest(hostModule.docsInfoRelay, hostModule.permissionService.onPermissionUpdated)
                .observeOn(MainScheduler.instance).do(onNext: { [weak self] docsInfo, _ in
                    guard let permissionContainer = self?.hostModule?.permissionService.containerResponse?.container else {
                        DocsLogger.error("PermissionContainer does not exist")
                        return
                    }
                    self?.previewActionSubject.onNext(.showLeaderPermAlert(token: docsInfo.token,
                                                                           permissionContainer: permissionContainer))
                    guard let permissionManager = DocsContainer.shared.resolve(PermissionManager.self) else  {
                        DocsLogger.error("PermissionManager does not exsit")
                        return
                    }
                    let publicPermissionMeta = permissionManager.getPublicPermissionMeta(token: docsInfo.objToken)
                    PermissionStatistics.shared.updateCcmCommonParameters(docsInfo: docsInfo, userPermission: nil, publicPermission: publicPermissionMeta)
                    let extraInfo = ["encryptedObjToken": docsInfo.encryptedObjToken]
                    DocsLogger.driveInfo("Update PermissionStatistics Parameters", extraInfo: extraInfo)
                }).map { $0.0 } // 取 DocsInfo
        } else {
            docsInfoUpdate = Observable.combineLatest(hostModule.docsInfoRelay, hostModule.permissionRelay)
                .observeOn(MainScheduler.instance).do(onNext: { [weak self] docsInfo, permissionInfo in
                    guard let userPermissions = permissionInfo.userPermissions else {
                        DocsLogger.error("UserPermissions does not exsit")
                        return
                    }
                    self?.previewActionSubject.onNext(.legacyShowLeaderPermAlert(token: docsInfo.objToken, userPermission: userPermissions))
                    guard let permissionManager = DocsContainer.shared.resolve(PermissionManager.self) else  {
                        DocsLogger.error("PermissionManager does not exsit")
                        return
                    }
                    let publicPermissionMeta = permissionManager.getPublicPermissionMeta(token: docsInfo.objToken)
                    PermissionStatistics.shared.updateCcmCommonParameters(docsInfo: docsInfo, userPermission: userPermissions, publicPermission: publicPermissionMeta)
                    let extraInfo = ["encryptedObjToken": docsInfo.encryptedObjToken]
                    DocsLogger.driveInfo("Update PermissionStatistics Parameters", extraInfo: extraInfo)
                }).map { $0.0 }
        }
        docsInfoUpdate.flatMap({ [weak self] docsInfo -> Observable<Bool> in
            return .create { observer in
                guard let self, let permissionService = self.hostModule?.permissionService else {
                    return Disposables.create()
                }

                guard docsInfo.isOwner else {
                    DocsLogger.driveInfo("Not doc owner", extraInfo: ["encryptedObjToken": docsInfo.encryptedObjToken])
                    observer.onNext(false)
                    return Disposables.create()
                }

                let uid = User.current.info?.userID ?? ""
                let closedKey = "ccm.permission.dlp.closed" + docsInfo.encryptedObjToken + uid
                if CacheService.normalCache.containsObject(forKey: closedKey) {
                    DocsLogger.driveInfo("Doc have been closed", extraInfo: ["encryptedObjToken": docsInfo.encryptedObjToken])
                    observer.onNext(false)
                    return Disposables.create()
                }
                DocsLogger.driveInfo("Fetch DLP status", extraInfo: ["encryptedObjToken": docsInfo.encryptedObjToken])
                if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                    permissionService.asyncValidate(exemptScene: .dlpBannerVisable) { [weak self] response in
                        switch response.result {
                        case .allow:
                            observer.onNext(false)
                        case let .forbidden(denyType, _):
                            observer.onNext(denyType == .blockByDLPSensitive)
                        }
                        self?.updateDLPTimerWithPermissionSDK()
                    }
                } else {
                    DlpManager.status(with: docsInfo.token, type: docsInfo.inherentType, action: .OPENEXTERNALACCESS) { [weak self] status in
                        DocsLogger.driveInfo("Return DLP status", extraInfo: [
                            "encryptedObjToken": docsInfo.encryptedObjToken,
                            "dlpStatus": status.rawValue
                        ])
                        observer.onNext(status == .Sensitive)
                        self?.updateDLpTimer(token: docsInfo.token, type: docsInfo.inherentType)
                    }
                }
                return Disposables.create()
            }
        }).distinctUntilChanged().map({ flag -> DKPreviewAction in
            return flag ? .showDLPBanner : .hideDLPBanner
        }).bind(to: previewActionSubject).disposed(by: actionBag)

        docsInfoUpdate.observeOn(MainScheduler.instance).subscribe { [weak self] docsInfo in
            guard let self, let permissionContainer = self.hostModule?.permissionService.containerResponse?.container else {
                DocsLogger.error("PermissionContainer does not exist", extraInfo: ["encryptedObjToken": docsInfo.encryptedObjToken])
                return
            }
            guard docsInfo.isOwner else {
                DocsLogger.driveInfo("Not doc owner", extraInfo: ["encryptedObjToken": docsInfo.encryptedObjToken])
                return
            }
            let statusCode = permissionContainer.statusCode
            guard statusCode == .auditError || statusCode == .reportError else {
                DocsLogger.driveInfo("Doc does not ban", extraInfo: ["encryptedObjToken": docsInfo.encryptedObjToken])
                return
            }
            self.featchComplaintInfo()
        }.disposed(by: actionBag)
    }

    func notifyControllerWillAppear() {
        hostModule?.permissionService.notifyResourceWillAppear()
    }

    func notifyControllerDidDisappear() {
        hostModule?.permissionService.notifyResourceDidDisappear()
    }

    private func updateDLPTimerWithPermissionSDK() {
        hostModule?.permissionService.notifyResourceWillAppear()
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func updateDLpTimer(token: String, type: DocsType) {
        dlpTimer?.invalidate()
        dlpTimer = nil
        let timeout = DlpManager.timerTime(token: token)
        let timer = Timer(timeInterval: timeout, repeats: true) { _ in
            DlpManager.status(with: token, type: type, action: .OPENEXTERNALACCESS) { status in
                DocsLogger.driveInfo("timer update", extraInfo: [
                    "encryptedObjToken": token,
                    "dlpStatus": status.rawValue
                ])
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        dlpTimer = timer
    }
    
    private func monitorSerectInfo(sensitivtyLabelEnable: Bool) {
        guard sensitivtyLabelEnable else {
            DocsLogger.driveInfo("fg close")
            return
        }
        guard let hostModule = hostModule else {
            DocsLogger.error("HostModule does not exsit")
            return
        }

        struct SecretPermission {
            let canModifySecretLevel: Bool
            let canManageMeta: Bool
            let permissionForReport: UserPermissionAbility?
        }

        let secretPermissionUpdated: Observable<SecretPermission>
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            secretPermissionUpdated = hostModule.permissionService.onPermissionUpdated.map { [weak hostModule] _ in
                guard let service = hostModule?.permissionService else {
                    return SecretPermission(canModifySecretLevel: false, canManageMeta: false, permissionForReport: nil)
                }
                let canModifySecretLevel = service.validate(operation: .modifySecretLabel).allow
                let canManageMeta = service.validate(operation: .managePermissionMeta).allow
                return SecretPermission(canModifySecretLevel: canModifySecretLevel,
                                        canManageMeta: canManageMeta,
                                        permissionForReport: nil)
            }
        } else {
            secretPermissionUpdated = hostModule.permissionRelay.map { info in
                SecretPermission(canModifySecretLevel: info.userPermissions?.canModifySecretLevel() ?? false,
                                 canManageMeta: info.userPermissions?.isFA ?? false,
                                 permissionForReport: info.userPermissions)
            }
        }
        
        Observable.combineLatest(hostModule.docsInfoRelay, secretPermissionUpdated, collaboratorsCountRelay)
            .observeOn(MainScheduler.instance)
            .takeUntil(previewActionSubject.skipWhile({ action in
                if case .showSecretSetting = action {
                    return false
                } else {
                    return true
                }
            }))
            .subscribe(onNext: { [weak self] docsInfo, permissionInfo, count in
                guard let self = self else { return }
                guard docsInfo.typeSupportSecurityLevel,
                      let level = docsInfo.secLabel,
                      level.canSetSecLabel == .yes else {
                    DocsLogger.driveInfo("type unSupport, or level nil, or can not set secLabel")
                    self.previewActionSubject.onNext(.hideSecretBanner)
                    return
                }

                guard permissionInfo.canModifySecretLevel else {
                    DocsLogger.driveInfo("hide by permisson")
                    self.previewActionSubject.onNext(.hideSecretBanner)
                    return
                }
                
                var type: SecretBannerView.BannerType = .hide
                if UserScopeNoChangeFG.TYP.permissionSecretAuto {
                    type = SecretBannerCreater.checkForceSecretLableAutoOrRecommend(canManageMeta: permissionInfo.canManageMeta,
                                                                                    level: level, collaboratorsCount: count)
                    switch type {
                    case .recommendMarkBanner, .forceRecommendMarkBanner:
                        self.requestUpdateRecommandBanner(level: level, type: type, docsInfo: docsInfo, userPermisson: permissionInfo.permissionForReport)
                    default:
                        self.handleBannerType(type: type, docsInfo: docsInfo, level: level)
                    }
                } else {
                    if LKFeatureGating.sensitivityLabelForcedEnable {
                        ///强制打标
                        type = SecretBannerCreater.forcibleBannerType(canManageMeta: permissionInfo.canManageMeta, level: level, collaboratorsCount: count)
                    } else {
                        /// 非强制打标
                        type = SecretBannerCreater.unForcibleBannerType(level: level, collaboratorsCount: count)
                    }
                    self.handleBannerType(type: type, docsInfo: docsInfo, level: level)
                }
                DocsLogger.driveInfo("show banner with type \(type)")
                self.reportPermissionSecurityBanner(docsInfo: docsInfo, userPermisson: permissionInfo.permissionForReport, level: level)
            })
            .disposed(by: actionBag)
    }
    
    private func reportPermissionSecurityBanner(docsInfo: DocsInfo, userPermisson: UserPermissionAbility?, level: SecretLevel, type: SecretBannerView.BannerType? = nil) {
        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)
        let publicPermissionMeta = permissionManager?.getPublicPermissionMeta(token: docsInfo.objToken)
        let ccmCommonParameters = CcmCommonParameters(fileId: docsInfo.encryptedObjToken,
                                                      fileType: docsInfo.type.name,
                                                      appForm: (docsInfo.isInVideoConference == true) ? "vc" : "none",
                                                      subFileType: docsInfo.fileType,
                                                      module: docsInfo.type.name,
                                                      userPermRole: userPermisson?.permRoleValue,
                                                      userPermissionRawValue: userPermisson?.rawValue,
                                                      publicPermission: publicPermissionMeta?.rawValue)
        let permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)
        if type == nil {
            permStatistics.reportPermissionSecurityDocsBannerView(hasDefaultSecretLevel: level.bannerType == .defaultSecret)
        } else {
            if let type = type, case .forceRecommendMarkBanner = type {
                permStatistics.reportPermissionRecommendBannerView(isCompulsoryLabeling: true)
            } else {
                permStatistics.reportPermissionRecommendBannerView(isCompulsoryLabeling: false)
            }
        }
    }
    
    private func handleBannerType(type: SecretBannerView.BannerType, docsInfo: DocsInfo, level: SecretLevel) {
        DocsLogger.driveInfo("handleBannerType -- \(type), for: \(docsInfo.encryptedObjToken)")
        switch type {
        case .hide:
            DocsLogger.driveInfo("should hide banner")
            self.previewActionSubject.onNext(.hideSecretBanner)
            return
        case .autoMarkBanner:
            DocsLogger.info("should autoMarkBanner")
            self.requestUpdateAutoBanner(docsInfo: docsInfo, level: level)
        case .unChangetype:
            return
        case .forcibleSecret:
            DocsLogger.driveInfo("should show SecretSetting")
            self.previewActionSubject.onNext(.showSecretSetting)
        default: break
        }
        self.previewActionSubject.onNext(.showSecretBanner(type: type))
    }
    
    private func requestUpdateAutoBanner(docsInfo: DocsInfo, level: SecretLevel) {
        SecretLevel.updateSecLabelBanner(token: docsInfo.objId ?? "0",
                                         type: docsInfo.inherentType.rawValue,
                                         secLabelId: level.label.id,
                                         bannerType: level.secLableTypeBannerType?.rawValue ?? 0,
                                         bannerStatus: level.secLableTypeBannerStatus?.rawValue ?? 0)
            .subscribe {
                DocsLogger.driveInfo("update secret level success")
            } onError: { error in
                DocsLogger.error("update secret level fail", error: error)
            }
            .disposed(by: self.bag)
    }
    
    private func requestUpdateRecommandBanner(level: SecretLevel, type:SecretBannerView.BannerType, docsInfo: DocsInfo, userPermisson: UserPermissionAbility?) {
        SecretLevelLabelList.fetchLabelList()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] list in
                guard !list.labels.isEmpty else { return }
                for label in list.labels {
                    if label.id == level.recommendLabelId {
                        if case .recommendMarkBanner = type {
                            self?.previewActionSubject.onNext(.showSecretBanner(type: .recommendMarkBanner(title: label.name)))
                        } else {
                            self?.previewActionSubject.onNext(.showSecretBanner(type: .forceRecommendMarkBanner(title: label.name)))
                        }
                        self?.reportPermissionSecurityBanner(docsInfo: docsInfo, userPermisson: userPermisson, level: level, type: type)
                    }
                }
            }, onError: {  error in
                DocsLogger.error("fetchLabelList failed!", error: error)
            })
            .disposed(by: self.bag)
    }
        
    
    private func monitorCollaborators() {
        guard let hostModule = hostModule else {
            DocsLogger.error("HostModule does not exsit")
            return
        }
        // 只有云空间文件才需请求，附件等场景无协作者信息，无需请求
        guard hostModule.scene == .space else { return }

        collaboratorsCountRelay = BehaviorRelay<Int>(value: 0)
        guard LKFeatureGating.sensitivityLabelForcedEnable || UserScopeNoChangeFG.GQP.sensitivityLabelsecretopt else {
            DocsLogger.driveInfo("fg close")
            return
        }

        let docsInfo = hostModule.docsInfoRelay.value
        NotificationCenter.default.rx.notification(Notification.Name.Docs.CollaboratorListChanged)
            .subscribe { [weak self] (notification: Notification) in
                guard let self = self else { return }
                let oldCount = self.collaboratorsCountRelay.value
                if let info = notification.userInfo,
                   let token = info["token"] as? String,
                   token == docsInfo.token,
                    let count = info["count"] as? Int,
                   count != oldCount {
                    DocsLogger.driveInfo("get collaborator list changed notification, new count = \(count), old count =\(oldCount)")
                    self.collaboratorsCountRelay.accept(count)
                }
            }
            .disposed(by: actionBag)
        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
        permissionManager.fetchCollaborators(token: docsInfo.token, type: docsInfo.inherentType.rawValue, shouldFetchNextPage: true, collaboratorSource: .defaultType)
    }
    
    // Suspendable多任务关联文件用于恢复，目前只有图片场景需要
    var associatedFiles: [[String: String]] {
        return viewModels.compactMap({ file in
            if let url = file.urlForSuspendable {
                return ["path": url, "type": file.fileType.rawValue]
            } else {
                return nil
            }
        })
    }
    
    func prepareShowBulletin() {
        guard isSpaceFile else { return }
        NotificationCenter.default.post(name: DocsBulletinManager.bulletinRequestShowIfNeeded, object: self)
    }
    
    //用于后续拓展公告栏刷新操作
    func bannerRefresh() {
        NotificationCenter.default.post(name: DocsBulletinManager.bulletinRequestRefresh, object: self)
    }
    
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        guard let hostVC = hostModule?.hostController else { return }
        guard let view = hostVC.view.window ?? hostVC.view else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type)
    }
}

extension DKMainViewModel {
    func filterFiles() -> (newList: [DKFileCellViewModelType], index: Int) {
        // 如果当前打开方式为quicklook, 只支持单文件预览
        if openType == .quicklook {
            return disableMultiFile()
        }
        guard isSpaceFile else { return (viewModels, curIndex) }
        guard viewModels.count > curIndex && curIndex >= 0 else {
            DocsLogger.error("params error curIndex: \(curIndex), fileList count: \(viewModels.count)")
            return ([], 0)
        }
        var newList: [DKFileCellViewModelType]
        let curFile = viewModels[curIndex]
        if curFile.fileType.isSupportMultiPics || curFile.fileType == .svg {
            newList = originViewModels.filter({ (file) -> Bool in
                return file.fileType.isSupportMultiPics || file.fileType == .svg
            })

        } else {
            newList = [curFile]
        }
        if newList.isEmpty {
            newList = [curFile]
        }
        
        var idx: Int = 0
        for (index, value) in newList.enumerated()
            where value.fileID == curFile.fileID {
            idx = index
        }
        return (newList, idx)
    }
}


// MARK: - BulletinNotice
extension DKMainViewModel: DocsBulletinResponser {
    
    // 只处理首页的公告
    public func canHandle(_ type: [String]) -> Bool { return type.contains(DKMainViewModel.bulletinIdentifier) }
    
    /// 展示公告，每次只会展示一个公告，所以当前页面如果有未关闭的公告，需要进行覆盖。
    public func bulletinShouldShow(_ info: BulletinInfo) {
        currentNotice = info
        previewActionSubject.onNext(.showNotice(info: info))
        bulletinTrack(event: .view(bulletin: info))
    }

    /// 关闭指定公告，若为nil则关闭任何公告
    public func bulletinShouldClose(_ info: BulletinInfo?) {
        guard info == nil || info?.id == currentNotice?.id else {
            DocsLogger.driveInfo("The closed bulletin is not the one currently displayed")
            return
        }
        previewActionSubject.onNext(.closeBulletin(info: info))
    }
    
    private func bulletinTrack(event: DocsBulletinTrackEvent) {
        let commonParams: [String: Any] = statisticsService.commonTrackParams
        bulletinManager?.track(event, commonParams: commonParams)
    }
}

extension DKMainViewModel: BulletinViewDelegate {
    public func shouldClose(_ bulletinView: BulletinView) {
        guard let info = bulletinView.info else {
            DocsLogger.driveInfo("No closeBulletinInfo")
            return
        }
        bulletinTrack(event: .close(bulletin: info))
        NotificationCenter.default.post(name: DocsBulletinManager.bulletinCloseNotification, object: nil, userInfo: ["id": info.id])
    }
    
    public func shouldOpenLink(_ bulletinView: BulletinView, url: URL) {
        guard let info = bulletinView.info else {
            DocsLogger.driveInfo("No openLinkBulletinInfo")
            return
        }
        openBulletinURL(url)
        bulletinTrack(event: .openLink(bulletin: info))
        NotificationCenter.default.post(name: DocsBulletinManager.bulletinOpenLinkNotification, object: ["id": info.id])
    }
    
    private func openBulletinURL(_ url: URL) {
        if let type = DocsType(url: url),
           let objToken = DocsUrlUtil.getFileToken(from: url, with: type) {
            let file = SpaceEntryFactory.createEntry(type: type, nodeToken: "", objToken: objToken)
            file.updateShareURL(url.absoluteString)
            let body = SKEntryBody(file)
            previewActionSubject.onNext(.open(entry: body, context: [:]))
        } else {
            previewActionSubject.onNext(.openURL(url: url))
        }
    }
}

extension DKMainViewModel {
    func shouldOpenVerifyURL(type: ComplaintState) {
        if type == .machineVerify || type == .verifyFailed {
            let provider = DriveAppealInfoProvider(token: objToken)
            let vc = SubmitAppealViewController(token: objToken, objType: .file, provider: provider, fromScene: .driveFile(title: title))
            vc.submitCompletion = { [weak self] in
                self?.featchComplaintInfo()
            }
            previewActionSubject.onNext(.push(viewController: vc))
        } else {
            let mpDomain = DomainConfig.mpAppLinkDomain
            let urlString = "https://\(mpDomain)/TdSgr1y9"
            if let url = URL(string: urlString) {
                previewActionSubject.onNext(.openURL(url: url))
            }
        }
    }

    public func featchComplaintInfo() {
        var pramas: [String: Any] = [:]
        pramas = ["obj_type": DocsType.file.rawValue, "obj_token": self.objToken]  /// obj_type针对文件夹传0
        if UserScopeNoChangeFG.PLF.appealV2Enable {
            pramas["transit"] = true
        }
        request = DocsRequest<JSON>(path: OpenAPI.APIPath.getComplaintInfo, params: pramas)
            .set(method: .GET)
            .start(result: { [weak self] result, error in
                guard let self = self else { return }
                guard let json = result,
                      let code = DocsNetworkError(json["code"].int)?.code else {
                    DocsLogger.error("request failed data invalide")
                    return
                }
                //后端接口文档链接：https://bytedance.feishu.cn/wiki/wikcnVpgwVGEsedAffmHx4APrHg#nfzCrw, 这里是「查看申诉状态」
                let resultCode = json["data"]["result"].int
                switch code {
                case .success where resultCode == PermissionError.ComplaintResultCode.inProgress.rawValue:
                    /// 申诉中
                    self.previewActionSubject.onNext(.appealResult(state: .verifying))
                case .success where resultCode == PermissionError.ComplaintResultCode.pass.rawValue:
                    /// 审核通过
                    self.previewActionSubject.onNext(.hideAppealBanner)
                case .success where resultCode == PermissionError.ComplaintResultCode.noPass.rawValue:
                    ///不通过
                    self.previewActionSubject.onNext(.appealResult(state: .verifyFailed))
                case .appealEnable:
                    /// 允许申诉
                    self.previewActionSubject.onNext(.appealResult(state: .machineVerify))
                case .appealing:
                    /// 申诉中
                    self.previewActionSubject.onNext(.appealResult(state: .verifying))
                case .appealRejected:
                    /// 申诉被驳回
                    self.previewActionSubject.onNext(.appealResult(state: .verifyFailed))
                case .notFound:
                    /// 未申诉
                    self.previewActionSubject.onNext(.appealResult(state: .machineVerify))
                case .dailyLimit:
                    /// 当日到达上限
                    self.previewActionSubject.onNext(.appealResult(state: .reachVerifyLimitOfDay))
                case .allLimit:
                    /// 申诉到达总上限
                    self.previewActionSubject.onNext(.appealResult(state: .reachVerifyLimitOfAll))
                case .timeShort:
                    self.previewActionSubject.onNext(.appealResult(state: .verifyFailed))
                default:
                    /// 兜底清空所有关于申诉的banner
                    self.previewActionSubject.onNext(.hideAppealBanner)
                }
            })
    }
}
