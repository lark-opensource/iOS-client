//
//  DKFileCell.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/6/12.
//
//  swiftlint:disable file_length type_body_length

import UIKit
import SnapKit
import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import LarkSecurityComplianceInterface
import SKInfra
import LarkFoundation
import LarkDocsIcon
import SpaceInterface

protocol DKFileCellContainerVC: BaseViewController {
    var topView: UIView? { get }
    var bottomView: UIView? { get }
}

class DKFileCell: UICollectionViewCell {
    let fileView = DKFileView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        DocsLogger.driveInfo("DKFileCell -- init")
        contentView.addSubview(fileView)
        fileView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        fileView.reset()
    }
}

class DKFileView: UIView {
    weak var lastChildVC: UIViewController?
    private var displayMode: DrivePreviewMode = .normal {
        didSet {
            switch displayMode {
            case .card:
                // 在无复制权限时截图场景下，是文档中内嵌的Drive Block时，toast不要显示在该Block上
                // 因为文档相关视图会负责toast
                viewCapturePreventer.notifyContainer = []
                DocsLogger.driveInfo("DKFileView(card) set notifyContainer => none")
            case .normal:
                viewCapturePreventer.notifyContainer = [.controller]
                DocsLogger.driveInfo("DKFileView(card) set notifyContainer => all")
            @unknown default:
                break
            }
        }
    }
    weak var mainViewController: DKFileCellContainerVC? {
        didSet {
            updateContainerConstraint()
        }
    }
    weak var screenModeDelegate: DrivePreviewScreenModeDelegate?
    var viewModel: DKFileCellViewModelType?
    /// 屏幕旋转或者分屏时，禁止reset。
    /// 原因是reset之后childVC会被移除，此时没有请求数据的逻辑
    var shouldReset = true
    private var bag = DisposeBag()

    var lastBlockType: SKApplyPermissionBlockType?

    private func getVCFactory(permissionService: UserPermissionService) -> DKPreviewVCFactory {
        // vcFactory 不会被强持有，内部的权限监听需要用外部传入的 DisposeBag
        let context = DKPreviewVCFactoryContext(mainVC: mainViewController,
                                                hostModule: viewModel?.hostModule,
                                                delegate: self,
                                                areaCommentDelegate: mainViewController as? DriveAreaCommentDelegate,
                                                screenModeDelegate: screenModeDelegate,
                                                isiOSAppOnMacSystem: Utils.isiOSAppOnMacSystem,
                                                previewFromScene: viewModel?.previewFromScene,
                                                permissionService: permissionService,
                                                disposeBag: bag)
        return DKPreviewVCFactory(context: context)
    }

    private lazy var viewCapturePreventer: ViewCapturePreventable = {
        let preventer = ViewCapturePreventer()
        preventer.notifyContainer = [.superView, .windowOrVC, .thisView]
        preventer.setAnalyticsFileInfoGetter(block: { [weak self] () -> (String?, String?) in
            let fileId = DocsTracker.encrypt(id: self?.viewModel?.fileID ?? "")
            let fileType = self?.viewModel?.fileType.rawValue ?? ""
            DocsLogger.driveInfo("ViewCapture Event: DKFileView fileId: \(fileId), fileType: \(fileType)")
            return (fileId, fileType)
        })
        preventer.contentView.backgroundColor = .clear
        return preventer
    }()
    
    var containerView: UIView { viewCapturePreventer.contentView }
    
    // 提示界面
    private lazy var hintView: DKPreviewHintView = {
        let view = DKPreviewHintView(mode: displayMode)
        // 卡片模式下点击触发事件
        view.tapEnterFull = { [weak self] in
            self?.enterNormalMode()
        }
        
        // 卡片模式下展示hitview后，hintview自己处理点击进全屏态事件，需要disable掉mainVC的点击事件
        view.didShowHintView = { [weak self] show in
            guard let mainVC = self?.mainViewController as? DKMainViewController else { return }
            mainVC.enableCardModeTapAction(!show)
        }
        return view
    }()
    // 性能上报
    private var performanceLogger: DrivePerformanceRecorder? {
        return viewModel?.performanceRecorder
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        DocsLogger.driveInfo("DKFileCell -- init")
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func notifyWillDisplay() {
        viewModel?.permissionService.notifyResourceWillAppear()
    }

    func notifyDidEndDisplay() {
        viewModel?.permissionService.notifyResourceDidDisappear()
    }
    
    func reset() {
        guard shouldReset else { return }
        bag = DisposeBag()
        hintView.hide()
        removeChildVC()
        if viewModel != nil {
            viewModel?.reset()
            showLoading()
        }
        viewModel = nil
    }
    
    func showLoading() {
        if isInFullScreenMode() {
            hintView.showCircleLoading()
        } else {
            hintView.showLoading()
        }
    }
    
    func hideLoading() {
        if isInFullScreenMode() {
            hintView.hideCircleLoading()
        } else {
            hintView.hideLoading()
        }
    }
    
    /// 开始加载文件
    func startLoadFile() {
        guard let logger = performanceLogger else { return }
        // 打开埋点
        logger.openStart(isInVC: viewModel?.isInVCFollow ?? false, contextVC: mainViewController)
        setupViewModel()
    }
    
    private func setupViewModel() {
        guard let vm = viewModel else {
            spaceAssertionFailure("DriveSDK.FileCell: no DKFileCellViewModel")
            return
        }
        
        guard let hostVC = mainViewController else {
            spaceAssertionFailure("DriveSDK.FileCell: no hostViewController")
            return
        }
        vm.previewStateUpdated.drive(onNext: {[weak self] (state) in
            guard let self = self else { return }
            DocsLogger.driveInfo("DriveSDK.FileCell: previewState: \(state)")
            self.handle(previewState: state)
        }).disposed(by: bag)
        vm.canReadAndCanCopy?
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (canRead, canCopy) in
            guard let self = self else {
                DocsLogger.driveInfo("DriveSDK.FileCell: not self")
                return
            }
            if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                // 上层已经判断了 Admin 权限了
                let allowCapture = canCopy || !canRead
                let desc = "canCopy: \(canCopy), canRead: \(canRead)"
                DocsLogger.driveInfo("DriveSDK.DKFileView: `allowCapture` permission changed from permissionSDK: \(desc)")
                self.viewCapturePreventer.isCaptureAllowed = allowCapture
            } else {
                let isAdminCanCopy: Bool
                if vm.previewFromScene == .im {
                    isAdminCanCopy = CCMSecurityPolicyService.syncValidate(entityOperate: .imFileCopy, fileBizDomain: vm.previewFromScene.transfromBizDomain, docType: .imMsgFile, token: nil).allow
                } else {
                    isAdminCanCopy = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmCopy, fileBizDomain: vm.previewFromScene.transfromBizDomain, docType: .file, token: nil).allow
                }
                var isAllowed = canCopy
                isAllowed = (isAllowed && isAdminCanCopy) || canRead == false // 特殊处理: 不能阅读时(显示申请权限视图)允许正常截图
                let desc = "canCopy: \(canCopy), isAdminCanCopy: \(isAdminCanCopy), canRead:\(canRead)"
                DocsLogger.driveInfo("DriveSDK.DKFileView: `canCopy` permission changed: \(desc)")
                self.viewCapturePreventer.isCaptureAllowed = isAllowed
            }
        }).disposed(by: bag)
        
        vm.startPreview(hostContainer: hostVC)
    }
    
    //  swiftlint:disable cyclomatic_complexity
    private func handle(previewState: DKFilePreviewState) {
        DocsLogger.driveInfo("DriveSDK.DKFileView: previewState \(previewState)")
        switch previewState {
        case .loading:
            showLoading()
        case .endLoading:
            hideLoading()
        case let .transcoding(fileType, handler, downloadForPreviewHandler):
            hintView.showTranscoding(fileType: fileType, handler: handler, downloadForPreviewHandler: downloadForPreviewHandler)
        case .endTranscoding:
            hintView.hideTranscoding()
        case let .showDownloading(fileType):
            // 展示下载页面需要移除子VC，WPS场景下 会继续监听回调导致弹出不符的Toast
            removeChildVC()
            hintView.showDownloadingView(status: .prepare(fileType: fileType), isFullScreen: isInFullScreenMode())
        case let .downloading(progress):
            /// 判断是否需要刷新兜底页
            guard needUpdateNoPermissionUI(isFromPermissionAPI: false, blockType: nil) else {
                DocsLogger.driveInfo("DKFileCell:No Permission Controller is exist!")
                return
            }
            hintView.updateDownloadingView(status: .loading(progress: progress), isFullScreen: isInFullScreenMode())
        case .downloadCompleted:
            hintView.hideDownloadingView()
        case let .setupPreview(type, info):
            performanceLogger?.stageBegin(stage: .fileIsOpen)
            hintView.hide()
            setupChildVC(type: type, info: info)
        case let .setupUnsupport(info, handler):
            hintView.showUnSupportView(info: info, handler: handler)
            performanceLogger?.openFinish(result: .success, code: .unsupportPreviewFileType, openType: .unknown)
        case let .forbidden(reason, image):
            hintView.showForbiddenView(reason: reason, image: image)
            if let presentedVC = mainViewController?.presentedViewController {
                presentedVC.dismiss(animated: true, completion: nil)
            }
            removeChildVC()
        case let .setupFailed(data):
            removeChildVC()
            showFetchFailed(data: data)
        case let .noPermission(docsInfo, canRequestPermission, isFromPermissionAPI, isAdminBlocked, isShareControlByCAC, isPreviewControlByCAC, isViewBlockByAudit):
            hintView.hide()
            showUpNoPermissionPage(docsInfo: docsInfo,
                                   canRequestPermission: canRequestPermission,
                                   isFromPermissionAPI: isFromPermissionAPI,
                                   isAdminBlocked: isAdminBlocked,
                                   isShareControlByCAC: isShareControlByCAC,
                                   isPreviewControlByCAC: isPreviewControlByCAC,
                                   isViewBlockByAudit: isViewBlockByAudit)
        case let .showPasswordInputView(fileToken, restartBlock):
            hintView.hide()
            showPasswordInputView(fileToken: fileToken, restartBlock: restartBlock)
        case let .willChangeMode(mode):
            willChangeMode(mode)
        case let .changingMode(mode):
            changingMode(mode)
        case let .didChangeMode(mode):
            didChangeMode(mode)
        case let .deleteFileRestore(restoreType, handler):
            removeChildVC()
            hintView.showDeleteRestore(type: restoreType, completion: handler)
        case .cacDenied: break
            
        }
    }
    
    private func setupUI() {
        UIView.performWithoutAnimation {
            addSubview(containerView)
            containerView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            containerView.addSubview(hintView)
            hintView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            self.layoutIfNeeded()
        }
        hintView.isHidden = true
        hintView.didClickRetryButtonAction = { [weak self] in
            self?.performanceLogger?.loadFrom = .retry
        }
    }
    
    private func willChangeMode(_ mode: DrivePreviewMode) {
        guard let vc = lastChildVC as? DriveBizeControllerProtocol else {
            return
        }
        vc.willUpdateDisplayMode(mode)
    }
    
    private func changingMode(_ mode: DrivePreviewMode) {
        if hintView.isDisplaying {
            hintView.changeMode(mode, animate: true)
        }
        if let vc = lastChildVC as? DKViewModeChangable {
            vc.changeMode(mode, animate: true)
        }
        guard let vc = lastChildVC as? DriveBizeControllerProtocol else {
            return
        }
        vc.changingDisplayMode(mode)
    }

    private func didChangeMode(_ mode: DrivePreviewMode) {
        let oldValue = self.displayMode
        self.displayMode = mode
        if oldValue != .normal, mode == .normal {
            // 从非normal模式进入normal时, 触发一下防截图toast(若有)
            let currentValue = viewCapturePreventer.isCaptureAllowed
            viewCapturePreventer.isCaptureAllowed = currentValue
        }
        hintView.changeMode(mode, animate: false)
        guard let vc = lastChildVC as? DriveBizeControllerProtocol else {
            return
        }
        vc.updateDisplayMode(mode)
    }

    private func updateContainerConstraint() {
        guard let vc = mainViewController else {
            assertionFailure("DriveMainViewController can not be nil")
            return
        }
        containerView.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            if let bottomView = vc.bottomView {
                make.bottom.equalTo(bottomView.snp.top)
            } else {
                make.bottom.equalToSuperview()
            }
            if let topView = vc.topView {
                make.top.equalTo(topView.snp.bottom)
            } else {
                make.top.equalToSuperview()
            }
        }
    }

    private func setupChildVC(type: DriveFileType, info: DKFilePreviewInfo, layout: ((UIView) -> Void)? = nil) {
        guard let parentVC = mainViewController else {
            spaceAssertionFailure("DriveSDK.FileCell: no parentVC")
            return
        }
        guard let vm = viewModel else {
            DocsLogger.driveInfo("DriveSDK.DKFileCell::cell is reset makes vm is nil")
            return
        }
        lastBlockType = nil
        let isInVCFollow = viewModel?.isInVCFollow ?? false
        let vcFactory = getVCFactory(permissionService: vm.permissionService)
        guard let vc = vcFactory.previewVC(previewInfo: info, previewFileType: type, isInVCFollow: isInVCFollow) else {
            DocsLogger.error("DriveSDK.DKFileCell: vcFactory不支持该类型")
            if let info = unsupportInfo(vm: vm), let attachVM = vm as? DKAttachmentFileCellViewModel {
                hintView.showUnSupportView(info: info) {[weak attachVM] view, rect in
                    attachVM?.handleOpenWithOtherApp(sourceView: view, sourceRect: rect)
                }
            } else {
                // 兜底展示失败界面
                hintView.showFetchFailed(data: DKPreviewFailedViewData.defaultData())
            }
            
            return
        }
        removeChildVC()
        setupForVCFollowIfNeed(childVC: vc, parentVC: parentVC)
        parentVC.addChild(vc)
        UIView.performWithoutAnimation {
            containerView.insertSubview(vc.view, belowSubview: hintView)
            vc.didMove(toParent: parentVC)
            if let layout = layout {
                layout(vc.view)
            } else {
                makeConstraints(for: vc.view)
            }
            self.layoutIfNeeded()
        }
        lastChildVC = vc
        let openType: DriveOpenType = (vc as? DriveBizeControllerProtocol)?.openType ?? .unknown
        vm.handle(previewAction: .setupChildPreviewVC(openType: openType))
    }
    
    func removeChildVC() {
        if let childVC = lastChildVC {
            childVC.willMove(toParent: nil)
            childVC.view.removeFromSuperview()
            childVC.removeFromParent()
        }
    }
    
    func makeConstraints(for view: UIView) {
        updateContainerConstraint()
        view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func showFetchFailed(data: DKPreviewFailedViewData) {
        /// 如果已经展示了权限申请、密码页面，就不展示失败页面
        if (lastChildVC is DriveRequestPermissionController) || (lastChildVC is PasswordInputViewController) {
            DocsLogger.driveInfo("DKFileCell:cancel show fetch failed view")
            return
        }
        hintView.showFetchFailed(data: data)
    }
    
    private func showUpNoPermissionPage(docsInfo: DocsInfo,
                                        canRequestPermission: Bool,
                                        isFromPermissionAPI: Bool,
                                        isAdminBlocked: Bool,
                                        isShareControlByCAC: Bool,
                                        isPreviewControlByCAC: Bool,
                                        isViewBlockByAudit: Bool) {
        guard let parentVC = mainViewController else {
            DocsLogger.driveInfo("DKFileCell: mainViewController Controller is Not exist!")
            return
        }

        var defaultBlockType: SKApplyPermissionBlockType = .userPermissonBlock
        if isShareControlByCAC {
            defaultBlockType = .shareControlByCAC
        } else if isPreviewControlByCAC {
            defaultBlockType = .previewControlByCAC
        } else if isViewBlockByAudit && UserScopeNoChangeFG.WWJ.auditPermissionControlEnable {
            defaultBlockType = .viewBlockByAudit
        } else if isAdminBlocked {
            defaultBlockType = .adminBlock
        } else {
            defaultBlockType = .userPermissonBlock
        }
        DocsLogger.driveInfo("DKFileCell: defaultBlockType: \(defaultBlockType)")

        /// 判断是否需要刷新兜底页
        guard needUpdateNoPermissionUI(isFromPermissionAPI: isFromPermissionAPI, blockType: defaultBlockType) else {
            DocsLogger.driveInfo("DKFileCell:No Permission Controller is exist!")
            return
        }
        removeChildVC()
        DocsLogger.driveInfo("DKFileCell:setup permission VC")

        let vc = DriveRequestPermissionController(docsInfo,
                                                  canRequestPermission: canRequestPermission,
                                                  defaultBlockType: defaultBlockType)
        vc.displayMode = displayMode
        vc.screenModeDelegate = screenModeDelegate
        parentVC.addChild(vc)
        containerView.insertSubview(vc.view, belowSubview: hintView)
        vc.didMove(toParent: parentVC)
        makeConstraints(for: vc.view)
        lastChildVC = vc
    }
    
    private func needUpdateNoPermissionUI(isFromPermissionAPI: Bool, blockType: SKApplyPermissionBlockType?) -> Bool {
        if isFromPermissionAPI {// permission api 返回的无权限结果，如果当前没有展示无权限界面就需要刷新
            // 如果blockType没发生改变，就不必刷新，不然刷新动作中的removeChildVC可能会把上层的所有视图都移除掉
            if lastBlockType != blockType {
                lastBlockType = blockType
                return true
            }
            return false
        } else { // fileInfo返回的无权限结果，如果当前没有展示无权限或者密码界面，才需要更新，因为permission接口的权限信息优先级更高
            return !(lastChildVC is DriveRequestPermissionController) && !(lastChildVC is PasswordInputViewController)
        }
    }
    
    func showPasswordInputView(fileToken: String, restartBlock: @escaping () -> Void) {
        guard let parentVC = mainViewController else { return }
        guard !(lastChildVC is PasswordInputViewController) else {
            DocsLogger.driveInfo("Password Controller is exist!")
            return
        }
        removeChildVC()
        let vc = PasswordInputViewController(token: fileToken,
                                             type: .file)
        vc.unlockStateRelay.subscribe(onNext: { (result) in
            if result {
                restartBlock()
            } else {
                DocsLogger.driveInfo("unlock failed!")
            }
        }).disposed(by: bag)
        parentVC.addChild(vc)
        containerView.insertSubview(vc.view, belowSubview: hintView)
        vc.didMove(toParent: parentVC)
        makeConstraints(for: vc.view)
        lastChildVC = vc
    }
    
    private func isInFullScreenMode() -> Bool {
        guard let screenModeDelegate = mainViewController as? DrivePreviewScreenModeDelegate else {
            return false
        }
        return screenModeDelegate.isInFullScreenMode()
    }
    
    // 这里桥接了 FollowContainer 和 FollowContentProvider
    func setupForVCFollowIfNeed(childVC: UIViewController, parentVC: UIViewController) {
        guard let followContainer = parentVC as? DriveFollowContainer else {
            DocsLogger.driveInfo("drive.preview.follow --- parentVC is not a followContainer")
            return
        }
        guard followContainer.isInVCFollow else {
            DocsLogger.driveInfo("drive.preview.follow --- followContainer is not in vc follow context")
            return
        }
        guard let contentProvider = childVC as? DriveFollowContentProvider else {
            DocsLogger.error("drive.preview.follow --- childVC is not a followProvider")
            followContainer.handleContentUnavailableForFollow()
            return
        }
        guard contentProvider.vcFollowAvailable else {
            DocsLogger.driveInfo("drive.preview.follow --- followProvider unavailable for vc follow")
            followContainer.handleContentUnavailableForFollow()
            return
        }
        DocsLogger.driveInfo("drive.preview.follow --- setting up followContainer and followProvider")
        followContainer.setupFollowConfig(contentProvider: contentProvider)
    }
    
    private func unsupportInfo(vm: DKFileCellViewModelType) -> DKUnSupportViewInfo? {
        guard let host = vm.hostModule else { return nil }
        let fileName = host.fileInfoRelay.value.name
        let fileSize = host.fileInfoRelay.value.size
        let type = host.fileInfoRelay.value.type
        let canExport: Observable<Bool>
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let isAttachment = vm.previewFromScene.isAttachment
            canExport = host.permissionService.onPermissionUpdated.map { [weak host] _ in
                let operation: PermissionRequest.Operation = isAttachment ? .downloadAttachment : .download
                return host?.permissionService.validate(operation: operation).allow ?? false
            }
        } else {
            canExport = host.permissionRelay.map { $0.canExport }
        }
        let enable = host.reachabilityChanged.asObservable()
        let info = DKUnSupportViewInfo(type: .typeUnsupport,
                                       fileName: fileName,
                                       fileSize: fileSize,
                                       fileType: type,
                                       buttonVisable: canExport,
                                       buttonEnable: enable,
                                       showDocTips: false) // 卡片模式不展示不支持其他应用打开tips

        return info
    }
}

// MARK: - DriveBizViewControllerDelegate
extension DKFileView: DriveBizViewControllerDelegate {
    private func enterNormalMode() {
        if let mainVC = mainViewController as? DKMainViewController {
            mainVC.enterFullAction(gesture: nil)
        }
    }
    
    private func showCardModeNavibar(_ show: Bool) {
        if let mainVC = mainViewController as? DKMainViewController {
            mainVC.showCardModeNavibar(show, animate: true)
        }
    }
    
    func openSuccess(type: DriveOpenType) {
        reportFileOpenStageFinishedIfNeed(result: .success, openType: type)
        // 可降级的预览方式成功，上报成功事件
        if type.isDowngradable {
            performanceLogger?.openDowngradable(success: true, openType: type)
        }
    }
    
    func exitPreview(result: DriveBizViewControllerOpenResult, type: DriveOpenType) {
        viewModel?.handle(previewAction: .exitPreview)
        reportFileOpenStageFinishedIfNeed(result: result, openType: type)
    }
    
    func unSupport(_ bizViewController: UIViewController, reason: DriveUnsupportPreviewType, type: DriveOpenType) {
        viewModel?.handleBizPreviewUnsupport(type: reason)
        reportFileOpenStageFinishedIfNeed(result: .unsupport, openType: type)
    }

    var context: [String: Any]? {
        get {
            return viewModel?.hostModule?.commonContext.extraInfo
        }
        set {
            guard let newContext = newValue else {
                viewModel?.hostModule?.commonContext.extraInfo = [:]
                return
            }
            viewModel?.hostModule?.commonContext.extraInfo = newContext
        }
    }
    
    var fileID: String? {
        return viewModel?.fileID
    }
    
    var pageNumber: Int? {
        return viewModel?.hostModule?.commonContext.pdfPageNumber
    }
    
    func previewFailed(_ bizViewController: UIViewController, needRetry: Bool, type: DriveOpenType, extraInfo: [String: Any]?) {
        viewModel?.handleBizPreviewFailed(canRetry: needRetry)
        reportFileOpenStageFinishedIfNeed(result: .failed, openType: type, extraInfo: extraInfo)
    }
    
    func previewFailedWithAutoRetry(_ bizViewController: UIViewController, type: DriveOpenType, extraInfo: [String: Any]) {
        viewModel?.handleBizPreviewDowngrade()
        // 可降级的预览方式失败，上报失败事件
        if type.isDowngradable {
            reportFileOpenStageFinishedIfNeed(result: .failed, openType: type, extraInfo: extraInfo)
            performanceLogger?.openDowngradable(success: false, openType: type, extraInfo: extraInfo)
        }
    }
    
    func statistic(action: DriveStatisticAction, source: DriveStatisticActionSource) {
        switch action {
        case .secLink:
            secLinkStatistic()
        case .clickDisplay:
            var screenMode = "default"
            if screenModeDelegate?.isInFullScreenMode() ?? false { screenMode = "full" }
            viewModel?.statisticsService.clientClickDisplay(screenMode: screenMode)
        default:
            viewModel?.statisticsService.toggleAttribute(action: action, source: source)
        }
    }
    
    func statistic(event: DocsTrackerEventType, params: [String: Any]) {
        viewModel?.statisticsService.reportEvent(event, params: params)
    }
    
    func clickEvent(_ event: DocsTrackerEventType, clickEventType: ClickEventType, params: [String: Any]) {
        viewModel?.statisticsService.reportClickEvent(event, clickEventType: clickEventType, params: params)
    }
    
    func append(leftBarButtonItems: [DriveNavBarItemData], rightBarButtonItems: [DriveNavBarItemData]) {
        viewModel?.update(additionLeftBarItems: leftBarButtonItems, additionRightBarItems: rightBarButtonItems)
    }
    
    func stageBegin(stage: DrivePerformanceRecorder.Stage) {
        performanceLogger?.stageBegin(stage: stage)
    }
    
    func stageEnd(stage: DrivePerformanceRecorder.Stage) {
        performanceLogger?.stageEnd(stage: stage)
    }
    
    func reportStage(stage: DrivePerformanceRecorder.Stage, costTime: Double) {
        performanceLogger?.reportStageCostTime(stage: stage, costTime: costTime)
    }
    
    func invokeDriveBizAction(_ action: DriveBizViewControllerAction) {
        switch action {
        case .dismissCommentVC:
            guard let mainVC = mainViewController as? DKMainViewController else { return }
            mainVC.dismissCommentVCIfNeeded()
        case .enterNormalMode:
            enterNormalMode()
        case .showCardModeNavibar(let show):
            showCardModeNavibar(show)
        }
    }
    
    /// 参考文档: https://bytedance.feishu.cn/docs/doccnzzp51OvlcXraWINo8rXw3d
    private func secLinkStatistic() {
        guard let vm = viewModel else { return }
        var scene: SecLinkStatistics.SecLinkScene = .ccm
        var location: SecLinkStatistics.SecLinkLocation = .ccmDrive
        /// Docs附件用ccm
        if vm.statisticsService.previewFrom == .docsAttach {
            scene = .ccm
            location = .driveSdkCreation
        } else if vm.statisticsService.previewFrom == .mail || vm.statisticsService.previewFrom == .calendar {
            let fromValue = vm.statisticsService.previewFrom.rawValue
            guard let thirdPartyType = DriveThirdPartyType(rawValue: fromValue) else {
                SecLinkStatistics.recordClickLinkStatistics(scene: scene, location: location)
                return
            }
            scene = thirdPartyType.seclinkReportData.0
            location = thirdPartyType.seclinkReportData.1
        }
        /// 兜底就是文件预览
        SecLinkStatistics.recordClickLinkStatistics(scene: scene, location: location)
    }
}

// MARK: 性能埋点
extension DKFileView {
    private func reportFileOpenStageFinishedIfNeed(result: DriveBizViewControllerOpenResult, openType: DriveOpenType, extraInfo: [String: Any]? = nil) {
        performanceLogger?.stageEnd(stage: .fileIsOpen)
        switch result {
        case .cancel:
            performanceLogger?.openFinish(result: .cancel, code: .cancel, openType: openType, extraInfo: extraInfo)
        case .cancelOnCellularNetwork:
            performanceLogger?.openFinish(result: .cancel, code: .cancelledOnCellularNetwork, openType: openType, extraInfo: extraInfo)
        case .success:
            performanceLogger?.openFinish(result: .success, code: .success, openType: openType, extraInfo: extraInfo)
            if openType == .videoCover {
                // No need to run next steps
                return
            }
            if let fileId = viewModel?.fileID, let fileType = viewModel?.fileType {
                viewModel?.statisticsService.reportFileOpen(fileId: fileId, fileType: fileType, isSupport: true)
            }
            /// 获取预览成功的文件类型
            viewModel?.handleOpenFileSuccessType(openType: openType)
        case .unsupport:
            performanceLogger?.openFinish(result: .nativeFail, code: .localUnsupportFileType, openType: openType, extraInfo: extraInfo)
            viewModel?.statisticsService.reportDrivePageView(isSupport: false, displayMode: displayMode)
        case .failed:
            performanceLogger?.openFinish(result: .nativeFail, code: .localFileRenderFailed, openType: openType, extraInfo: extraInfo)
        }
    }
}


enum DriveThirdPartyType: String {
    case mail
    case calendar

    var seclinkReportData: (scene: SecLinkStatistics.SecLinkScene, location: SecLinkStatistics.SecLinkLocation) {
        switch self {
        case .mail:
            return(SecLinkStatistics.SecLinkScene.email, SecLinkStatistics.SecLinkLocation.emailAttachmentPreview)
        case .calendar:
            return(SecLinkStatistics.SecLinkScene.calendar, SecLinkStatistics.SecLinkLocation.eventAttachmentPreview)
        }
    }
}
