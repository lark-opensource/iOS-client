//
//  DrivePDFViewController.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/12/4.

import UIKit
import SKUIKit
import EENavigator
import PDFKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import SKCommon
import SKFoundation
import SKResource
import SpaceInterface
import LarkDocsIcon
import LarkSetting
import SKInfra

// 记录PDF上次打开的位置
public enum PDFLocationCacheInfo {
    public static let pdfPageCacheKey = "drive.pdf.page.cache.number"
}


class DrivePDFViewController: SKPDFPreviewController,
                                PDFViewDelegate,
                                DriveBizeControllerProtocol,
                                UIGestureRecognizerDelegate {
    var openType: DriveOpenType {
        return .pdfView
    }
    var panGesture: UIPanGestureRecognizer? {
        pdfScrollView?.panGestureRecognizer
    }

    static let contextPresentationModeKey = "context-drive-ppt-presentation"

    typealias Config = DrivePDFViewModel.Config

    private let tapHandler = DriveTapEnterFullModeHandler()
    private let draggingHandler = DriveDraggingEnterFullModeHandler()
    weak var bizVCDelegate: DriveBizViewControllerDelegate?
    weak var screenModeDelegate: DrivePreviewScreenModeDelegate?
    private(set) weak var pdfScrollView: UIScrollView?
    
    var isScrolling: Bool = false
    var additionalStatisticParameters: [String: String]? {
        return driveViewModel.additionalStatisticParameters
    }

    // FollowState 更新
    let followStateSubject = PublishSubject<Void>()
    let driveViewModel: DrivePDFViewModel

    private var displayMode: DrivePreviewMode = .normal
    
    private var userID: String {
       return User.current.info?.userID ?? ""
    }
        
    init(viewModel: DrivePDFViewModel, displayMode: DrivePreviewMode) {
        driveViewModel = viewModel
        self.displayMode = displayMode
        super.init(viewModel: viewModel)
        self.isCompact = (displayMode == .card)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MAKR: - 生命周期事件
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPDFView()
        setupPlayMode()
        setupPermissionMonitor()
        
        if shouldCachePageNumber() {
            setupLoadingObserver()
        }
        driveViewModel.pageNumberChangedRelay?.skip(1)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] pageNumber in
            guard let self else { return }
            let result = self.go(to: pageNumber - 1)
            DocsLogger.driveInfo("AI pageNumber changed: \(pageNumber), result: \(result)")
        }.disposed(by: disposeBag)
        setupMenuObserver()
    }
    
    func setupPDFView() {
        pdfView.systemMenuInterceptor = self
        pdfView.delegate = self
        pdfView.hideSystemMenu = true
    }
    
    func setupMenuObserver() {

        // 文档复制到外部的权限
        driveViewModel.canCopyRelay
                      .subscribe(onNext: { [weak self] canCopy in
                          self?.driveViewModel.pdfInlineAIAction?.accept(.canCopyOutside(canCopy))
                      })
                      .disposed(by: disposeBag)
        
        // 单文档内复制权限
        driveViewModel.copyPermission
                      .subscribe(onNext: { [weak self] canCopy in
                          self?.driveViewModel.pdfInlineAIAction?.accept(.canCopyInside(canCopy))
                      })
                      .disposed(by: disposeBag)
        
        driveViewModel.pdfInlineAIAction?.subscribe(onNext: { [weak self] action in
            guard let self = self else { return }
            switch action {
            case let .updateMenus(menus):
                self.pdfView.customMenus.accept(menus)
                if !menus.isEmpty {
                    let config = SettingConfig.pdfInlineAIMenuConfig
                    self.pdfView.canSwizzleDocumentView = config?.swizzledEnable ?? false
                    self.pdfView.hiddenIdentifiers = config?.missingList ?? []
                }
            default:
                break
            }
        }).disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        let firstAppear = isFirstAppear
        super.viewDidAppear(animated)
        guard firstAppear else { return }
        if document == nil {
            DocsLogger.driveError("drive.pdfkit ---failed to init PDF Document")
            let errorMessage: String
            let path = SKFilePath(absUrl: driveViewModel.fileURL)
            if !path.exists {
                errorMessage = "pdf path not found"
            } else {
                errorMessage = "pdfKit not support"
            }
            DocsLogger.error("drive.pdfkit ---PDF render failed: \(errorMessage)")
            let extraInfo = ["error_message": errorMessage] as [String: Any]
            bizVCDelegate?.previewFailed(self, needRetry: false, type: openType, extraInfo: extraInfo)
            return
        }
        bizVCDelegate?.openSuccess(type: openType)
    }

    deinit {
        DocsLogger.driveInfo("drive.pdfkit --- DrivePDFViewController deinit")
    }
    
    override func additionSetup() {
        guard !isPDFLoaded else { return }
        super.additionSetup()
        // VC Follow State
        bindStateUpdated()

        for view in pdfView.subviews {
            if let scrollView = view as? UIScrollView {
                bindScrollViewState(scrollView)
                pdfScrollView = scrollView
                DocsLogger.debug("drive.pdfkit --- did find PDFScrollView for follow")
                break
            }
        }
        setupPDFViewGesture()
    }

    override func change(config: Config) {
        super.change(config: config)
        // nav
        if config.shouldShowPresentationSwitchBtn {
            bizVCDelegate?.append(leftBarButtonItems: [], rightBarButtonItems: [DriveNavBarItemData(type: .switchPresentationMode,
                                                                                                  enable: true,
                                                                                                  target: self,
                                                                                                  action: #selector(enterPresentation))])
        } else {
            bizVCDelegate?.append(leftBarButtonItems: [], rightBarButtonItems: [])
        }
        // landscape
        if config.shouldLandscape {
            screenModeDelegate?.changePreview(situation: .fullScreen)
            DriveStatistic.enterPresentation(actionType: config.source.rawValue,
                                             fileType: driveViewModel.originFileType,
                                             additionalParameters: additionalStatisticParameters)
            // mark in presentation state
            savePresentationModeInContext(true)
        } else {
            if !driveViewModel.isInVCFollow {
                screenModeDelegate?.changePreview(situation: .exitFullScreen)
            }
            // mark exit presentation state
            savePresentationModeInContext(false)
        }
        // iPad 下切换演示模式后，当前 PDF 内容会出现偏移，这里重新 Layout 内容
        pdfView.layoutDocumentView()
        setupPlayMode()
        // 在演示模式下才隐藏缩略图按钮
        if config.enablePresentationMask {
            setGridModeView(hidden: true)
        }
    }
    
    private func setupPermissionMonitor() {
        driveViewModel.needSecurityCopyDriver.drive(onNext: { [weak self] token in
            guard let self = self else { return }
            self.pdfView.pointId = token
        }).disposed(by: disposeBag)
    }
    
    // MARK: 记录PDF上次阅读位置
    func setupLoadingObserver() {
        loadingStateChanged.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            
            if self.isPDFLoaded {
                if let initPageNumber = self.driveViewModel.initPageNumber {
                    let result = self.go(to: initPageNumber - 1)
                    DocsLogger.driveInfo("pdf goto page with init page number: \(initPageNumber - 1), result: \(result) ")
                } else {
                    let pageNumber = self.getPageNumber() // 从0开始
                    let result = self.go(to: pageNumber)
                    DocsLogger.driveInfo("pdf goto page with cached number: \(pageNumber), result: \(result) ")
                }
            }
        }).disposed(by: disposeBag)
    }
    
    // 无需记录位置的场景：1. MS场景 2. 原文件不是PDF 3. Docx 附件Block态
    // 需要注意细节：缓存数据可以在飞书设置中清理
    private func shouldCachePageNumber() -> Bool {
        return (driveViewModel.originFileType.lowercased() == DriveFileType.pdf.rawValue)
        && !driveViewModel.isInVCFollow
        && !isCompact
        && UserScopeNoChangeFG.ZH.recoveryPDFReadingProgress
    }
    
    private func pageCacheKey() -> String {
        return PDFLocationCacheInfo.pdfPageCacheKey + (driveViewModel.fileToken ?? "")
    }
    
    private func savePageNumber(numberIndex: Int) {
        CCMKeyValue.userDefault(userID).set(numberIndex, forKey: pageCacheKey())
        DocsLogger.info("drive.pdfkit ---pdf save cached number: \(numberIndex) ")
    }
    
    private func getPageNumber() -> Int {
        let pageNumber = CCMKeyValue.userDefault(userID).integer(forKey: pageCacheKey())
        DocsLogger.info("drive.pdfkit ---get pdf page number cache success, pageNumber: \(pageNumber)")
        
        return pageNumber
    }
    
    // MARK: 卡片模式相关
    func willUpdateDisplayMode(_ mode: DrivePreviewMode) {
        self.displayMode = mode
        
        if mode == .card {
            /// 页码从1开始
            if let pageNumber = currentPageNumber, pageNumber > 0 {
                savePageNumber(numberIndex: pageNumber - 1)
            }
        }
        
    }
    
    func changingDisplayMode(_ mode: DrivePreviewMode) {
    }
    
    func updateDisplayMode(_ mode: DrivePreviewMode) {
        self.displayMode = mode
        // 卡片态和全屏态之间变化需更新缩略图的布局(因为页面宽度变化了)
        updateThumbnailGridViewLayout()
        setupPlayMode()
    }
    
    private func setupPlayMode() {
        setScrollBarView(hidden: (displayMode == .card))
        setGridModeView(hidden: (displayMode == .card))
        setPageLabel(hidden: (displayMode != .card))
        self.isCompact = (displayMode == .card)
        
        if displayMode == .card {
            _ = go(to: 0)
            DocsLogger.driveInfo("pdf goto page 0, in card Mode")
        } else if let initPageNumber = driveViewModel.initPageNumber {
            let result = go(to: initPageNumber - 1)
            DocsLogger.driveInfo("pdf goto page with init page number: \(initPageNumber - 1), result: \(result) ")
            
        } else if shouldCachePageNumber() { // Docx中附件全屏状态下需要记录上次位置
            let pageNumber = self.getPageNumber()
            let result = self.go(to: pageNumber)
            DocsLogger.driveInfo("pdf goto page with cached number: \(pageNumber), result: \(result) ")
        }
    }
    
    private func savePresentationModeInContext(_ isPresentationMode: Bool) {
        if var context = bizVCDelegate?.context {
            context[Self.contextPresentationModeKey] = isPresentationMode
            bizVCDelegate?.context = context
        } else {
            let context: [String: Any] = [Self.contextPresentationModeKey: isPresentationMode]
            bizVCDelegate?.context = context
        }
    }

    @objc
    private func enterPresentation() {
        driveViewModel.presentationModeChangedSubject.onNext((true, .click))
        
        let params: [String: Any] = ["click": DriveStatistic.DriveTopBarClickEventType.show.clickValue,
                                     "target": DriveStatistic.DriveTopBarClickEventType.show.targetValue]
        bizVCDelegate?.statistic(event: DocsTracker.EventType.navigationBarClick, params: params)
    }
    
    @objc
    fileprivate func handleTapGesture() {
        if !isScrolling {
            DocsLogger.driveInfo("drive.pdfkit --- handleTapGesture")
            
            // MS场景，主讲人&参与者默认进去全屏状态；参与者点击之后需要退出全屏状态
            // 非MS场景，FG 控制是否禁用沉浸态
            if !UserScopeNoChangeFG.ZH.disablePDFImmerise || driveViewModel.isInVCFollow {
                self.screenModeDelegate?.changeScreenMode()
            }
            
            self.bizVCDelegate?.statistic(action: .clickDisplay, source: .unknow)
        }
    }

    override func pageNumberChanged(from: Int?, to: Int) {
        if shouldCachePageNumber() {
            // index 是从1 开始，用于显示当前文档为第N页
           savePageNumber(numberIndex: to - 1)
        }

        super.pageNumberChanged(from: from, to: to)
        updatePresentationCount(to)
        followStateSubject.onNext(())
    }
    
    // MARK: PDFViewDelegate
    func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
        DocsLogger.driveInfo("drive.pdfkit --- did click HyperLink")
        /// secLink数据上报
        self.bizVCDelegate?.statistic(action: .secLink, source: .unknow)
        if driveViewModel.intercept(url: url) {
            // 转交给 viewModel 处理
            DocsLogger.driveInfo("drive.pdfkit --- url intercept by viewModel")
            return
        }
        Navigator.shared.push(url, from: self)
    }
    

    // MARK: DrivePDFViewController+Grid
    override func showThumbnailGrid() {
        _showThumbnailGrid()
    }

    override func hideThumbnailGrid() {
        _hideThumbnailGrid()
    }
    
    // MARK: UIGestureRecognizerDelegate
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: pdfView)
        guard let page = pdfView.page(for: point, nearest: true) else {
            return true
        }
        let location = pdfView.convert(point, to: page)
        if page.annotation(at: location) != nil {
            return false
        }
        return true
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    // MARK: - 此处选择性实现
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer,
            otherGestureRecognizer is UILongPressGestureRecognizer {
            return true
        }
        //避免双击事件无法生效
        if let gesture = otherGestureRecognizer as? UITapGestureRecognizer, gesture.numberOfTapsRequired == 2 {
            return true
        }
        return gestureRecognizer.shouldRequireFailure(of: otherGestureRecognizer)
    }
}

extension DrivePDFViewController: DriveDynamicPermissionProtocol {
    func update(permission: DrivePermissionInfo) {
        driveViewModel.canCopyRelay.accept(permission.canCopy)
    }
}

extension DrivePDFViewController: SKSystemMenuInterceptorProtocol {
    func canPerformSystemMenuAction(_ action: Selector, withSender sender: Any?) -> Bool? {
        if action == #selector(UIResponderStandardEditActions.selectAll(_:)) {
            // 屏蔽 UIMenuController 中的 "全选" 按钮
            // 全选是系统默认的按钮，无法通过设置 UIMenuController 屏蔽
            return false
        }

        return nil
    }

    // MARK: - UIMenu Interceptor
    func interceptCopy(_ sender: Any?) -> Bool {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let (allow, completion) = driveViewModel.checkCopyPermission()
            completion(self)
            return !allow
        } else {
            return legacyInterceptCopy()
        }
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func legacyInterceptCopy() -> Bool {
        let result = driveViewModel.needCopyIntercept()
        if let iscacIntercept = result.iscacIntercept, iscacIntercept {
            CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmCopy, fileBizDomain: .ccm, docType: .file, token: driveViewModel.fileToken)
        } else if let reason = result.reason, let type = result.type, result.needInterceptCopy {
            UDToast.docs.showMessage(reason, on: view.window ?? view, msgType: type)
        }
        return result.needInterceptCopy
    }
}

extension DrivePDFViewController: DriveSupportAreaCommentProtocol {

    var commentSource: DriveCommentSource {
        return .pdf
    }

    var defaultCommentArea: DriveAreaComment.Area {
        /// 页码从1开始
        guard let currentPageNumber = currentPageNumber, currentPageNumber > 0 else {
            DocsLogger.error("currentPageNumber is nil!")
            return DriveAreaComment.Area.blankArea
        }
        /// 初始化为单页评论
        let singlePageArea = DriveAreaComment.Area(page: currentPageNumber - 1,
                                                   originX: 0,
                                                   originY: 0,
                                                   endX: 0,
                                                   endY: 0,
                                                   quads: nil,
                                                   text: nil)
        return singlePageArea
    }
}

// MARK: - DrivePDFViewController+Grid
extension DrivePDFViewController {
    func _showThumbnailGrid() {
        super.showThumbnailGrid()
        screenModeDelegate?.changePreview(situation: .exitFullScreen)
        bizVCDelegate?.statistic(action: .clickDisplay, source: .unknow)
        screenModeDelegate?.hideCommentBar(animated: false)
    }

    func _hideThumbnailGrid() {
        super.hideThumbnailGrid()
        screenModeDelegate?.showCommentBar(animated: false)
    }
}

extension DrivePDFViewController {
    private func setupPDFViewGesture() {
        tapHandler.addTapGestureRecognizer(targetView: pdfView) { [weak self] in
            guard let self = self else { return }
            DocsLogger.driveInfo("drive.pdfkit: did tap")
            self.handleTapGesture()
        }
        tapHandler.tapGesture?.delegate = self
        guard let scrollView = pdfScrollView else { return }
        
        //捏合不会触发willBeginDragging，只有滑动才出发
        scrollView.rx.willBeginDragging.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.draggingHandler.scrollHappen = true
            self.isScrolling = true
        }).disposed(by: disposeBag)
        
        let viewId = "\(ObjectIdentifier(self))"
        let scene = PowerConsumptionStatisticScene.docScroll(contextViewId: viewId)
        scrollView.setupScrollObserver(onStart: { [weak scrollView] in
            PowerConsumptionExtendedStatistic.markStart(scene: scene)
            let key1 = PowerConsumptionStatisticParamKey.docType
            let key2 = PowerConsumptionStatisticParamKey.fileType
            let key3 = PowerConsumptionStatisticParamKey.isUserScroll
            PowerConsumptionExtendedStatistic.updateParams(DocsType.file.name, forKey: key1, scene: scene)
            PowerConsumptionExtendedStatistic.updateParams(DriveFileType.pdf.rawValue, forKey: key2, scene: scene)
            let isTracking = scrollView?.isTracking ?? false
            PowerConsumptionExtendedStatistic.updateParams(isTracking, forKey: key3, scene: scene)
        }, onStop: {
            PowerConsumptionExtendedStatistic.markEnd(scene: scene)
        })
        
        scrollView.rx.didScroll.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.draggingHandler.draggingStatusSwitch(targetView: scrollView) { [weak self] _ in
                guard let self = self else { return }
                self.isScrolling = true
                DocsLogger.driveInfo("drive.pdfkit --- didScroll  \(self.isScrolling) ")
            }
        }).disposed(by: disposeBag)
        
        scrollView.rx.didEndDragging.subscribe { [weak self] decelerate in
            guard let self = self else { return }
            if !decelerate {
                self.isScrolling = false
                DocsLogger.driveInfo("drive.pdfkit --- didEndDragging  \(self.isScrolling) ")
            }
        }.disposed(by: disposeBag)
        
        scrollView.rx.didEndDecelerating.subscribe { [weak self] _ in
            guard let self = self else { return }
            self.isScrolling = false
            DocsLogger.driveInfo("drive.pdfkit --- didEndDecelerating  \(self.isScrolling) ")
        }.disposed(by: disposeBag)
    }
}
