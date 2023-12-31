//
//  FollowViewController.swift
//  ByteView
//
//  Created by huangshun on 2019/11/15.
//

import Foundation
import Action
import RxSwift
import RxCocoa
import UIKit
import ByteViewCommon
import ByteViewUI
import ByteViewMeeting

class FollowContainerViewController: VMViewController<InMeetFollowViewModel> {

    // MARK: 数据属性

    let disposeBag = DisposeBag()
    var appearDisposeBag = DisposeBag()

    // MARK: 容器&布局

    weak var container: InMeetViewContainer?
    // 是否作为 Cell 显示在 Pad 宫格视图
    var isGalleryCellMode: Bool = false {
        didSet {
            guard isGalleryCellMode != oldValue else {
                return
            }
            self.operationView.isHidden = isGalleryCellMode
            self.directionView.isHidden = isGalleryCellMode
        }
    }
    var meetingLayoutStyle: MeetingLayoutStyle = .tiled
    let contentLayoutGuide: UILayoutGuide = {
        let guide = UILayoutGuide()
        #if DEBUG
        guide.identifier = "follow-content-layout-guide"
        #endif
        return guide
    }()
    let bottomBarLayoutGuide = UILayoutGuide()
    private var shareBarGuideToken: MeetingLayoutGuideToken?

    // MARK: 子视图

    /// 文档视图
    let navigationWrapperView: UIView = {
        let view = UIView()
        return view
    }()
    /// 文档区域显示大小
    var navigationWrapperViewSize = CGSize(width: 0, height: 0)
    /// 文档嵌套容器的导航容器
    let navigationWrapperViewController: NavigationController = {
        let nav = NavigationController()
        nav.interactivePopDisabled = true
        nav.navigationBar.isHidden = true
        return nav
    }()

    /// 操作栏
    lazy var operationView: MagicShareOperationView = {
        let view = MagicShareOperationView()
        view.meetingLayoutStyle = meetingLayoutStyle
        return view
    }()

    /// 检测用户是否点击屏幕，跟随 -> 自由浏览
    let hitDetectView = MagicShareHitDetectView()

    /// 指示主讲人当前位置方向
    let directionView = MagicShareDirectionView()

    /// 用来禁用点击statusBar回到顶部的scrollToTop拦截视图
    let forbidenScrollToTopView = MagicShareForbiddenScrollToTopView()

    /// 用户引导
    var guideView: GuideView?
    lazy var msHideToolbarEnabled = viewModel.meeting.setting.isMSHideToolbarEnabled

    /// 投屏转妙享，首次进入提示
    var returnToShareScreenGuideView: GuideView?
    var returnToShareScreenGuideAnchorView: UIView?

    /// 水印
    private var watermarkView: UIView?

    private var menuFixer: MenuFixer?

    /// 复用WebView时，延时结束后进行的操作
    var dispatchAction: DispatchWorkItem?

    override func setupViews() {
        // add meeting state listener
        viewModel.meeting.addListener(self)
        GuideManager.shared.addListener(self)
        // config views and layout guides
        view.backgroundColor = UIColor.ud.N100
        isNavigationBarHidden = true
        view.addLayoutGuide(contentLayoutGuide)
        view.addLayoutGuide(bottomBarLayoutGuide)
        // add subviews
        view.addSubview(operationView)
        view.addSubview(navigationWrapperView)
        view.addSubview(hitDetectView)
        view.addSubview(directionView)
        view.addSubview(forbidenScrollToTopView)
        forbidenScrollToTopView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(-1)
            $0.left.right.equalToSuperview()
            $0.height.equalTo(1)
        }
        // layout operationView
        if Display.phone {
            operationView.snp.remakeConstraints {
                $0.left.right.equalToSuperview()
                $0.bottom.equalTo(bottomBarLayoutGuide.snp.top)
            }
        } else {
            operationView.snp.remakeConstraints {
                $0.left.right.equalToSuperview()
                $0.top.equalTo(contentLayoutGuide.snp.top)
            }
        }
        // layout navigationWrapperView
        navigationWrapperView.snp.remakeConstraints {
            $0.left.right.equalToSuperview()
            if isGalleryCellMode {
                $0.top.bottom.equalToSuperview()
                return
            }
            if Display.phone {
                $0.top.equalTo(contentLayoutGuide.snp.top)
                $0.bottom.equalTo(operationView.snp.top)
            } else {
                $0.top.equalTo(operationView.snp.bottom)
                $0.bottom.equalTo(contentLayoutGuide.snp.bottom)
            }
        }
        addChild(navigationWrapperViewController)
        navigationWrapperView.addSubview(navigationWrapperViewController.view)
        navigationWrapperViewController.view.snp.remakeConstraints {
            $0.edges.equalToSuperview()
        }
        navigationWrapperViewController.didMove(toParent: self)
        // layout hitDetectView
        hitDetectView.snp.remakeConstraints {
            $0.left.right.equalToSuperview()
            if Display.phone {
                $0.top.equalTo(contentLayoutGuide.snp.top)
                $0.bottom.equalTo(operationView.snp.top)
            } else {
                $0.top.equalTo(operationView.snp.bottom)
                $0.bottom.equalTo(contentLayoutGuide.snp.bottom)
            }
        }
        // layout directionView
        let edgeInsets = self.directionViewMovableEdgeInsets
        let isSharingPpt = viewModel.manager.currentRuntime?.documentInfo.shareSubType == .ccmPpt
        directionView.snp.remakeConstraints {
            if currentLayoutContext.layoutType.isPhoneLandscape {
                $0.right.equalToSuperview().inset(directionViewRightEdgeOffset)
            } else {
                $0.right.equalToSuperview().inset(edgeInsets.right)
            }
            $0.height.width.equalTo(Layout.directionViewSideLength)
            if currentLayoutContext.layoutType.isPhoneLandscape {
                $0.bottom.equalTo(operationView.snp.top).offset(isSharingPpt ? -107.0 : -113.0)
            } else {
                $0.centerY.equalTo(self.hitDetectView)
            }
        }
        setupDirectionViewAttachment()
        setupMenuFixer()
    }

    override func bindViewModel() {
        showGuideViewIfNeeded()
        bindOperationView()
        bindLoading()
        bindDirectionView()
        bindAuthorityTipsView()
        bindHitDetectView()
        viewModel.manager.addListener(self)
        setupWatermark()
        addEnterBackgroundObserver()
    }

    /// 监听App进入后台事件
    private func addEnterBackgroundObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    @objc
    /// 收到“App进入后台”通知后执行的操作
    private func didEnterBackground() {
        // 切后台时，如果没有上报过init_track，上报一次App进入后台导致文档init中断的埋点
        viewModel.manager.currentRuntime?.trackOnMagicShareInitFinished(dueTo: .isBackground)
        // 切后台时，FollowState不会应用，取消妙享跟随端告警，避免误报
        viewModel.manager.currentRuntime?.cancelFollowerNoValidFollowStatesTimeout()
    }

    deinit {
        handleExternalPermissionTips(show: false)
        if viewModel.manager.currentRuntime?.ownerID == ObjectIdentifier(viewModel) {
            viewModel.manager.currentRuntime?.stop()
        }
        if let returnToShareScreenGuide = returnToShareScreenGuideView {
            Util.runInMainThread {
                returnToShareScreenGuide.removeFromSuperview()
            }
        }
        if let returnToShareScreenGuideAnchor = returnToShareScreenGuideAnchorView {
            Util.runInMainThread {
                returnToShareScreenGuideAnchor.removeFromSuperview()
            }
        }
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // MagicShare 离开全屏事件内部自己管理
        viewModel.fullScreenDetector?.registerInterruptWhiteListView(self.view)
        if !isGalleryCellMode && !msHideToolbarEnabled {
            viewModel.fullScreenDetector?.forceAlwaysShowToolbar(true)

        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let layoutStyleChanged = viewModel.layoutStyleChangedTrigger.asObservable()
        let followStatusChanged = viewModel.status.asObservable().map { _ in Void() }
        let translationStatusChanged = viewModel.isTranslationOnRelay.asObservable().map { _ in Void() }

        Observable.merge(viewModel.onboardingGuideTrigger, layoutStyleChanged, followStatusChanged, translationStatusChanged)
            .startWith(Void())
            .filterByLatestFrom(viewModel.magicShareDocumentRelay.asObservable().map { $0 != nil })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.showGuideViewIfNeeded()
            })
            .disposed(by: appearDisposeBag)

        viewModel.magicShareDocumentRelay.asObservable()
            .map { $0 == nil }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.removeOnboardingGuide()
            })
            .disposed(by: disposeBag)

        viewModel.magicShareDocumentRelay.asObservable()
            .map { $0 != nil }
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.resetDirectionViewLayout()
            })
            .disposed(by: disposeBag)

        viewModel.isInterpreterComponentDisplayRelay.asObservable()
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.resetDirectionViewLayout()
            })
            .disposed(by: disposeBag)

        viewModel.isTranslationOnRelay.asObservable()
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.resetDirectionViewLayout()
            })
            .disposed(by: disposeBag)

        requestShowReturnToShareScreenGuide()
        handleExternalPermissionTips(show: viewModel.shouldShowExternalPermissionTips.value)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // MagicShare文档的显示区域大小变化时埋点
        if self.navigationWrapperViewSize != navigationWrapperView.frame.size {
            self.navigationWrapperViewSize = navigationWrapperView.frame.size
            guard let currentDocument = self.viewModel.remoteMagicShareDocument else {
                FollowContainerViewController.logger.info("current document is nil, tracking size change invalid")
                return
            }
            MagicShareTracks.trackOnNavigationWrapperSizeChange(
                size: self.navigationWrapperViewSize,
                isPresenter: currentDocument.user == viewModel.meeting.account,
                shareId: currentDocument.shareID ?? "",
                shareType: currentDocument.shareType)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.fullScreenDetector?.unregisterInterruptWhiteListView(self.view)
        if !isGalleryCellMode && !msHideToolbarEnabled {
            viewModel.fullScreenDetector?.forceAlwaysShowToolbar(false)
        }
        self.returnToShareScreenGuideView?.removeFromSuperview()
        self.returnToShareScreenGuideView = nil
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        handleExternalPermissionTips(show: false)
        appearDisposeBag = DisposeBag()
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if oldContext.layoutType != newContext.layoutType {
            requestShowReturnToShareScreenGuide()
        }
        if newContext.layoutChangeReason.isOrientationChanged {
            self.showGuideViewIfNeeded()
        }
        self.resetDirectionViewLayout()
    }

    private func setupMenuFixer() {
        self.menuFixer = MenuFixer(viewController: self)
    }

    override var shouldAutorotate: Bool {
        navigationWrapperViewController.shouldAutorotate
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        navigationWrapperViewController.supportedInterfaceOrientations
    }
}

extension FollowContainerViewController {

    func respondToMeetingLayoutStyleChange(container: InMeetViewContainer) {
        self.meetingLayoutStyle = container.meetingLayoutStyle
        operationView.meetingLayoutStyle = container.meetingLayoutStyle
        viewModel.layoutStyleChangedTrigger.accept(Void())
    }

}

extension FollowContainerViewController {

    func floatingWindowWillTransition(to frame: CGRect, isFloating: Bool) {
        if isFloating {
            // 切小窗时，如果没有上报过init_track，上报一次视图小窗导致文档init中断的埋点
            viewModel.manager.currentRuntime?.trackOnMagicShareInitFinished(dueTo: .isFloating)
        }
    }

    func floatingWindowWillChange(to isFloating: Bool) {
        if isFloating {
            viewModel.manager.currentRuntime?.willSetFloatingWindow()
            // 切小窗时，FollowState不会应用，取消妙享跟随端告警，避免误报
            viewModel.manager.currentRuntime?.cancelFollowerNoValidFollowStatesTimeout()
        }
    }

    func floatingWindowDidChange(to isFloating: Bool) {
        if !isFloating {
            viewModel.manager.currentRuntime?.finishFullScreenWindow()
        }
    }

}

extension FollowContainerViewController {
    func setupWatermark() {
        let selfTenantID = viewModel.meeting.myself.tenantId
        let combined = Observable.combineLatest(
            viewModel.service.larkUtil.getVCShareZoneWatermarkView(),
            viewModel.magicShareLocalDocumentsRelay.asObservable().distinctUntilChanged()) { (view, documents) -> (UIView?, Bool) in
                let showWatermark = documents.last?.showWatermark(selfTenantID: selfTenantID) ?? false
                Logger.ui.info("Follow watermark:\(documents.last)")
                return (view, showWatermark)
            }
        combined.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (view, showWatermark) in
                guard let self = self else { return }
                if showWatermark, let watermarkView = view {
                    watermarkView.frame = self.navigationWrapperView.bounds
                    watermarkView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    self.navigationWrapperView.addSubview(watermarkView)
                    watermarkView.layer.zPosition = .greatestFiniteMagnitude
                } else {
                    self.watermarkView?.removeFromSuperview()
                }
                self.watermarkView = view
            }).disposed(by: self.disposeBag)
    }
}

extension FollowContainerViewController: InMeetMeetingListener {
    func didReleaseInMeetMeeting(_ meeting: InMeetMeeting) {
        Util.runInMainThread { [weak self] in
            guard let self = self else {
                Logger.vcFollow.warn("self is nil during FollowContainerVC.meetingDidEnd")
                return
            }
            // 会议结束时主动dismiss掉文档中present的页面，避免打开图片/视频时结束会议导致内存泄漏
            if let currentDocumentVC = self.viewModel.manager.currentRuntime?.documentVC,
               currentDocumentVC.presentedViewController != nil {
                Logger.vcFollow.debug("currentDocumentVC.presentedVC valid, exec dismiss operation")
                currentDocumentVC.dismiss(animated: false)
            }
        }
    }
}

extension FollowContainerViewController: InMeetLayoutContainerAware {
    func didAttachToLayoutContainer(_ layoutContainer: InMeetLayoutContainer) {
        self.shareBarGuideToken?.invalidate()
        let token = layoutContainer.registerAnchor(anchor: Display.phone ? .bottomShareBar : .topShareBar)
        token.layoutGuide.snp.remakeConstraints { make in
            make.edges.equalTo(self.operationView)
        }
        self.shareBarGuideToken = token
    }

    func didDetachFromLayoutContainer(_ layoutContainer: InMeetLayoutContainer) {
        self.shareBarGuideToken?.invalidate()
        self.shareBarGuideToken = nil
    }
}
