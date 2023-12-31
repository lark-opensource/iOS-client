//
//  SpaceHomeViewController.swift
//  SKECM
//
//  Created by Weston Wu on 2020/11/25.
//
// swiftlint:disable file_length
// swiftlint:disable function_body_length
import UIKit

import SnapKit
import RxSwift
import RxRelay
import RxCocoa
import ESPullToRefresh
import LarkContainer

import SKUIKit
import SKResource
import SKFoundation
import SKCommon

import UniverseDesignColor
import LarkUIKit
import UniverseDesignToast
import EENavigator
import LarkSceneManager
import LarkSplitViewController

import UniverseDesignBadge
import UniverseDesignDialog
import SpaceInterface
import SKInfra
import SKWorkspace

public var hideRefreshNumbers: Bool { !DocsConfigManager.isfetchFullDataOfSpaceList }

private extension SpaceHomeViewController {
    typealias RefreshAnimator = WikiHomePageRefreshAnimator
}

public class SpaceHomeViewController: UIViewController, SlideableSimultaneousGesture {
    
    // 导航栏模块
    public let naviBarCoordinator: SpaceNaviBarCoordinator
    private var refreshTipView: SpaceListRefreshTipView?
    private var previousTipShowDate: Date?
    public var tabBadgeVisableChanged: Observable<Bool> {
        homeViewModel.tabBadgeVisableChanged
    }
    
    // 允许单元格支持响应多个手势，默认不支持
    public var enableSimultaneousGesture:Bool = false
    var hasActionView: Bool = false

    // 布局模块
    private let homeUI: SpaceHomeUI
    private let keyboard = Keyboard()
    // 创建功能模块
    public let homeViewModel: SpaceHomeViewModel

    private(set) lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionHeadersPinToVisibleBounds = true
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.alwaysBounceVertical = true
        view.backgroundColor = .clear
        view.delegate = self
        view.dataSource = self
        view.dragDelegate = self
        return view
    }()

    // 悬浮创建按钮
    public lazy var createButton = SKCreateButton()
    private lazy var disabledCreateMaskView = UIControl()

    private let useCircleRefreshAnimator: Bool

    private lazy var numberRefreshAnimator: RefreshView = {
        let animator = RefreshView(number: 0)
        return animator
    }()

    private lazy var circleRefreshAnimator: RefreshAnimator = {
        let animator = RefreshAnimator()
        animator.update(circleColor: UDColor.primaryPri500)
        return animator
    }()

    private lazy var footerAnimator = SpaceMoreRefreshAnimator()

    private let disposeBag = DisposeBag()

    // MARK: - NewUserGuide Onboarding
    private(set) var onboardingTargetRects: [OnboardingID: CGRect] = [:]
    private(set) var onboardingHostViewControllers = [OnboardingID: UIViewController]() // 这里是强持有，所以一定要在合适的地方 set nil
    private(set) var onboardingHints: [OnboardingID: String] = [
        .spaceHomeNewbieNavigation: BundleI18n.SKResource.CreationMobile_Onboarding_Tooltip3,
        .spaceHomeNewbieCreateTemplate: BundleI18n.SKResource.CreationMobile_Onboarding_Tooltip2,
        .spaceHomeNewShareSpace: BundleI18n.SKResource.CreationMobile_ECM_ShareWithMe_description,
        .spaceHomeCloudDrive: BundleI18n.SKResource.LarkCCM_NewCM_Onboarding_Drive_Description
    ]
    private(set) var onboardingIndexes: [OnboardingID: String] = [:]
    private(set) var onboardingAcknowledgedBlocks: [OnboardingID: (() -> Void)] = [:]
    private lazy var userGuideStepCount: Int = {
        if TemplateRemoteConfig.templateEnable {
            return 3
        } else {
            return 2
        }
    }()

    // 用于在 appear 的时候响应某些全局刷新的逻辑，如秘钥删除
    private var isAppear = false
    private var needRefreshWhenAppear = false
    private var refreshing = false
    var showingOnboarding = false
    
    var config: SpaceHomeViewControllerConfig
    
    public let userResolver: UserResolver
    
    public init(userResolver: UserResolver,
                naviBarCoordinator: SpaceNaviBarCoordinator,
                homeUI: SpaceHomeUI,
                homeViewModel: SpaceHomeViewModel,
                useCircleRefreshAnimator: Bool = hideRefreshNumbers,
                config: SpaceHomeViewControllerConfig = .default) {
        self.userResolver = userResolver
        self.naviBarCoordinator = naviBarCoordinator
        self.homeUI = homeUI
        self.homeViewModel = homeViewModel
        self.useCircleRefreshAnimator = useCircleRefreshAnimator
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init with coder not impl")
    }

    deinit {
        print("SpaceHomeViewController deinit")
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        guard UIApplication.shared.applicationState != .background else { return }
        DocsLogger.info("darkmode.service --- \(String(describing: type(of: self))) user interface style did change")
        NotificationCenter.default.post(name: Notification.Name.DocsThemeChanged, object: nil)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindUIEvents()
        setupVM()
        setupKeyboardMonitor()
        setupAppearEvent()
        homeViewModel.notifyViewDidLoad()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        homeViewModel.notifyViewDidAppear()
        homeUI.notifyViewDidAppear()
        isAppear = true
        if needRefreshWhenAppear {
            needRefreshWhenAppear = false
            DocsLogger.info("space.home.vc --- refresh when appear for previous notification")
            homeUI.notifyPullToRefresh()
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isAppear = false
        homeUI.notifyViewWillDisappear()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        homeUI.notifyViewDidLayoutSubviews(hostVCWidth: view.frame.width)
    }

    public func reloadHomeLayout() {
        view.layoutIfNeeded()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func setupUI() {
        view.backgroundColor = UDColor.bgBody
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview() // 为了iPad上列表内容延伸至 home indicator 下
        }

        // 注意要在添加 RefreshView 前处理好 HeaderView，避免 RefreshView 取 contentInset 不准
        if let headerSection = homeUI.headerSection {
            let headerView = headerSection.headerView
            let headerHeight = headerSection.headerViewHeight
            collectionView.addSubview(headerView)
            headerView.snp.makeConstraints { make in
                make.bottom.equalTo(collectionView.contentLayoutGuide.snp.top)
                make.left.right.equalTo(collectionView.frameLayoutGuide)
//                make.width.equalTo(collectionView.frameLayoutGuide)
                make.height.equalTo(headerHeight)
            }
            var contentInset = collectionView.contentInset
            contentInset.top += headerHeight
            collectionView.contentInset = contentInset
        }
        homeUI.setup(collectionView: collectionView)

        view.addSubview(createButton)
        createButton.snp.makeConstraints { make in
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right).inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
            make.width.height.equalTo(48)
        }
        createButton.layer.cornerRadius = 24

        view.addSubview(disabledCreateMaskView)
        disabledCreateMaskView.backgroundColor = .clear
        disabledCreateMaskView.isEnabled = false
        disabledCreateMaskView.snp.makeConstraints { make in
            make.edges.equalTo(createButton)
        }

        if useCircleRefreshAnimator {
            DocsLogger.info("using circle refresh animator")
            let headerView = collectionView.es.addPullToRefresh(animator: circleRefreshAnimator) { [weak self] in
                self?.refreshing = true
                self?.homeUI.notifyPullToRefresh()
            }
            headerView.frame.origin.y -= collectionView.contentInset.top
        } else {
            setupPullToRefreshNumberAnimator()
        }
        if config.canLoadMore {
            collectionView.es.addInfiniteScrollingOfDoc(animator: footerAnimator) { [weak self] in
                self?.homeUI.notifyPullToLoadMore()
            }
        }
    }

    private func setupPullToRefreshNumberAnimator() {
        DocsLogger.info("using refresh animator with numbers")
        numberRefreshAnimator.delegate = self
        numberRefreshAnimator.descriptionLabel.text = homeViewModel.refreshAnimatorDescrption
        view.addSubview(numberRefreshAnimator)
        view.sendSubviewToBack(numberRefreshAnimator)
        let refreshViewHeight = numberRefreshAnimator.frame.height
        numberRefreshAnimator.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(refreshViewHeight)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        let headerView = collectionView.es.addPullToRefreshOfDoc(animator: numberRefreshAnimator.refreshHeaderView) { [weak self] in
            self?.refreshing = true
            self?.homeUI.notifyPullToRefresh()
        }
        headerView.frame.origin.y -= collectionView.contentInset.top
    }

    private func bindUIEvents() {
        createButton.rx.tap
            .compactMap { [weak self] in
                guard let self else { return nil }
                return (FromSource.recent, .bottomRight, self.createButton)
            }
            .bind(to: homeViewModel.createIntentionTrigger)
            .disposed(by: disposeBag)
    }

    private func setupVM() {
        setupCreateDirector()
        homeViewModel.naviBarTitleDriver?.drive(onNext: { [weak self] title in
            self?.naviBarCoordinator.update(title: title)
        }).disposed(by: disposeBag)

        homeViewModel.naviBarItemsUpdated.drive(onNext: { [weak self] items in
            self?.naviBarCoordinator.update(items: items)
        }).disposed(by: disposeBag)

        homeUI.reloadSignal
            .emit(onNext: { [weak self] action in
                self?.handle(reloadAction: action)
            })
            .disposed(by: disposeBag)

        homeUI.actionSignal
            .emit(onNext: { [weak self] action in
                self?.handle(action: action)
            })
            .disposed(by: disposeBag)
        homeUI.prepare()
    }

    private func setupCreateDirector() {
        setupCreateButtonHiddenStatus()
        homeViewModel.createVisableDriver.map { !$0 }.drive(disabledCreateMaskView.rx.isHidden).disposed(by: disposeBag)
        homeViewModel.createEnableDriver.drive(createButton.rx.isEnabled).disposed(by: disposeBag)
        // 为了保证 disable 后点击创建按钮时不会穿透到列表，这里固定把 maskView 放出来，但是仅当 ViewModel 需要响应 disabledCreate 才真的发事件给 vm
        homeViewModel.createEnableDriver
            .map { !$0 }
            .drive(disabledCreateMaskView.rx.isEnabled)
            .disposed(by: disposeBag)
        if let disabledCreateTrigger = homeViewModel.disabledCreateTrigger {
            disabledCreateMaskView.rx.controlEvent(.touchUpInside)
                .map { () }
                .bind(to: disabledCreateTrigger)
                .disposed(by: disposeBag)
        }
        homeViewModel.actionSignal
            .emit(onNext: { [weak self] action in
                self?.handle(homeAction: action)
            })
            .disposed(by: disposeBag)
    }
    
    // 暴露给外部继承处理创建按钮的展示状态
    func setupCreateButtonHiddenStatus() {
        homeViewModel.createVisableDriver.map { !$0 }.drive(createButton.rx.isHidden).disposed(by: disposeBag)
    }

    func reloadData() {
        collectionView.reloadData()
    }
}

// MARK: Action Handler
// swiftlint:disable cyclomatic_complexity
private extension SpaceHomeViewController {
    
    func handle(homeAction: SpaceHomeAction) {
        switch homeAction {
        case let .create(intent, sourceView):
            create(with: intent, sourceView: sourceView ?? createButton)
        case let .createFolder(intent):
            createFolder(intent: intent)
        case let .push(viewController):
            userResolver.navigator.push(viewController, from: self)
        case let .present(viewController, popoverConfiguration):
            if SKDisplay.pad, isMyWindowRegularSize() {
                popoverConfiguration?(viewController)
            }
            userResolver.navigator.present(viewController, from: self)
        case let .showHUD(action):
            handle(action: action)
        case let .sectionAction(action):
            handle(action: action)
        }
    }
    
    func handle(reloadAction: SpaceHomeUI.ReloadAction) {

        if showingOnboarding {
            if case let .update(_, _, _, _, _, willUpdate) = reloadAction {
                willUpdate()
            }
            return
        }

        switch reloadAction {
        case .fullyReload:
            collectionView.reloadData()
        case let .reloadSections(sections, animated):
            let sectionSet = IndexSet(sections)
            if animated {
                collectionView.reloadSections(sectionSet)
            } else {
                UIView.performWithoutAnimation {
                    collectionView.reloadSections(sectionSet)
                }
            }
        case let .reloadSectionCell(sectionIndex, animated):
            let sectionIndices = collectionView.indexPathsForVisibleItems.filter { $0.section == sectionIndex }
            guard !sectionIndices.isEmpty else { return }
            if animated {
                collectionView.reloadItems(at: sectionIndices)
            } else {
                UIView.performWithoutAnimation {
                    collectionView.reloadItems(at: sectionIndices)
                }
            }
        case let .update(sectionIndex, inserts, deletes, updates, moves, willUpdate):
            let indexToPathTransform: (Int) -> IndexPath = { IndexPath(item: $0, section: sectionIndex) }
            collectionView.performBatchUpdates({
                willUpdate()
                collectionView.deleteItems(at: deletes.map(indexToPathTransform))
                collectionView.insertItems(at: inserts.map(indexToPathTransform))
                collectionView.reloadItems(at: updates.map(indexToPathTransform))
                moves.forEach { (from, to) in
                    let fromPath = indexToPathTransform(from)
                    let toPath = indexToPathTransform(to)
                    collectionView.moveItem(at: fromPath, to: toPath)
                }
            }, completion: nil)
        case let .getVisableIndexPaths(callback):
            let indexPaths = collectionView.indexPathsForVisibleItems
            callback(indexPaths)
        case let .scrollToCell(indexPath, scrollPosition, animated):
            collectionView.scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
        }
    }

    func handle(action: SpaceHomeUI.Action) {
        switch action {
        case let .push(viewController):
            userResolver.navigator.push(viewController, from: self)
        case let .showDetail(viewController):
            userResolver.navigator.docs.showDetailOrPush(viewController, wrap: LkNavigationController.self, from: self)
        case let .present(viewController, popoverConfiguration, completion):
            if SKDisplay.pad, isMyWindowRegularSize() {
                popoverConfiguration?(viewController)
            }
            let from: UIViewController = self.presentedViewController ?? self
            userResolver.navigator.present(viewController, from: from, completion: completion)
        case let .showDeleteFailListView(files: files):
            showDeleteFailView(files: files)
        case let .showHUD(action):
            handle(action: action)
        case .hideHUD:
            UDToast.removeToast(on: view.window ?? view)
        case let .presentOrPush(viewController, popoverConfiguration):
            if SKDisplay.pad {
                popoverConfiguration?(viewController)
                userResolver.navigator.present(viewController, wrap: LkNavigationController.self, from: self)
                return
            }
            userResolver.navigator.push(viewController, from: self)
        case let .toast(content):
            UDToast.showTips(with: content, on: view.window ?? view)
        case let .startSpaceUserGuide(tracker, completion):
            startNewUserGuide(tracker: tracker, completion: completion)
        case .startCloudDriveOnboarding:
            showCloudDriveOnboarding()
        case let .open(entry, context):
            userResolver.navigator.docs.showDetailOrPush(body: entry, context: context, wrap: LkNavigationController.self, from: self, animated: true)
        case let .confirmDeleteAction(file, completion):
            showDeleteConfirmView(file: file, completion: completion)
        case let .stopPullToRefresh(total):
            guard refreshing else { return }
            if useCircleRefreshAnimator {
                collectionView.es.stopPullToRefresh()
                return
            }
            // 处理带数字的下拉刷新动画
            guard let total = total else {
                collectionView.es.stopPullToRefresh()
                return
            }
            // 这里需要判断是否需要展示数字，但是 RefreshView 目前没有方法提供判断，后续调整下
            numberRefreshAnimator.number = total
            numberRefreshAnimator.showDescriptionLabel(shouldShow: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) {
                self.collectionView.es.stopPullToRefresh()
                self.refreshing = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_1000) {
                self.numberRefreshAnimator.stopRolling()
            }
        case let .stopPullToLoadMore(hasMore):
            collectionView.es.stopLoadingMore()
            footerAnimator.hasMore = hasMore
            if hasMore {
                collectionView.es.resetNoMoreData()
            } else {
                collectionView.es.noticeNoMoreData()
            }
        case let .showRefreshTips(callback):
            showRefreshTipsIfNeed(callback: callback)
        case let .dismissRefreshTips(needScrollToTop):
            dismissRefreshTips()
            if needScrollToTop {
                forceScrollToTop()
            }
        case let .showManualOfflineSuggestion(completion):
            showManualOfflineSuggestion(completion: completion)
        case let .confirmRemoveManualOffline(completion):
            showDeleteConfirmForManualOfflineView(completion: completion)
        case let .showDriveUploadList(folderToken):
            DocsContainer.shared.resolve(DriveRouterBase.self)?.type()
                .showUploadListViewController(sourceViewController: self,
                                              folderToken: folderToken,
                                              scene: .workspace,
                                              params: [:])
        case let .create(intent, sourceView):
            create(with: intent, sourceView: sourceView)
        case let .newScene(scene):
            self.openNewScene(with: scene)
        case .exit:
            // 参考 BaseViewController 的 back 方法实现
            if let navigationController = navigationController {
                navigationController.popViewController(animated: true)
                if self.presentingViewController != nil {
                    dismiss(animated: true, completion: nil)
                }
            } else {
                dismiss(animated: true, completion: nil)
            }
        case let .openWithAnother(file, originName, popoverSourceView: popoverSourceView, arrowDirection: arrowDirection):
            // TODO: 待优化，more面板V2
            DocsContainer.shared.resolve(DriveVCFactoryType.self)!
                .openDriveFileWithOtherApp(file: file,
                                           originName: originName,
                                           sourceController: self,
                                           sourceRect: popoverSourceView.frame,
                                           arrowDirection: arrowDirection)
        case var .openShare(body):
            // TODO: 待优化，more面板V2
            let needPopover = SKDisplay.pad && (self.isMyWindowRegularSize())
            body.needPopover = needPopover
            userResolver.navigator.present(body: body, from: self, animated: needPopover)
        case var .exportDocument(body):
            // TODO: 待优化，more面板V2
            let needPopover = SKDisplay.pad && (self.isMyWindowRegularSize())
            body.hostSize = self.view.bounds.size
            body.needFormSheet = needPopover
            body.hostViewController = self
            userResolver.navigator.present(body: body, from: self, animated: true)
        case let .copyFile(completion):
            // TODO: 待优化，more面板V2
            completion(self)
        case let .saveToLocal(file, originName):
            DocsContainer.shared.resolve(DriveVCFactoryType.self)!
                .saveToLocal(file: file, originName: originName, sourceController: self)
        case let .openURL(url, context):

            if var newContext = context {
                newContext["showTemporary"] = false
                userResolver.navigator.docs.showDetailOrPush(url, context: newContext, from: self)
            } else {
                userResolver.navigator.docs.showDetailOrPush(url, context: ["showTemporary": false], from: self)
            }
        case let .showUserProfile(userID):
            let profileService = ShowUserProfileService(userId: userID, fromVC: self)
            HostAppBridge.shared.call(profileService)
        case .dismissPresentedVC:
            if let presentedViewController {
                presentedViewController.dismiss(animated: true)
            }
        }
    }

    private func handle(action: SpaceHomeUI.Action.HUDAction) {
        switch action {
        case let .warning(content):
            UDToast.showWarning(with: content, on: toastDisplayView)
        case let .customLoading(content):
            UDToast.showDefaultLoading(with: content, on: toastDisplayView)
        case let .failure(content):
            UDToast.showFailure(with: content, on: toastDisplayView)
        case let .success(content):
            UDToast.showSuccess(with: content, on: toastDisplayView, delay: 2)
        case let .tips(content):
            UDToast.showTips(with: content, on: toastDisplayView)
        case let .custom(config, operationCallback):
            UDToast.showToast(with: config, on: toastDisplayView, delay: 2, operationCallBack: operationCallback)
        case let .tipsmanualOffline(text, buttonText):
            let opeartion = UDToastOperationConfig(text: buttonText, displayType: .horizontal)
            let config = UDToastConfig(toastType: .info, text: text, operation: opeartion)
            UDToast.showToast(with: config, on: view, delay: 2, operationCallBack: { [weak self]_ in
                guard let self = self else { return }
                NetworkFlowHelper.dataTrafficFlag = true
                UDToast.removeToast(on: self.view)
                })
        }
    }

    // 这里单独实现了noticeNoMoreData()的逻辑，ESPullToRefresh的源码被魔改了，结果与预期不对
    private func noticeNoMoreData() {
        collectionView.footer?.stopRefreshing()
        collectionView.footer?.noMoreData = true
        collectionView.footer?.isHidden = true
    }
    
    private var toastDisplayView: UIView {
        let theWindow: UIWindow?
        if let wd = view.window {
            theWindow = wd
        } else { // iOS 12 有可能获取不到所在window, 兜底
            theWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        }
        return theWindow ?? view
    }
}
// swiftlint:enable cyclomatic_complexity

extension SpaceHomeViewController: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        homeUI.numberOfSections
    }
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        homeUI.numberOfItems(in: section)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = homeUI.cell(for: indexPath, collectionView: collectionView)
        if let slideableCell = cell as? SlideableCell {
            slideableCell.enableSimultaneousGesture = self.enableSimultaneousGesture
            if self.enableSimultaneousGesture {
                slideableCell.simultaneousDelegate = self
            }
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        homeUI.supplymentaryElementView(kind: kind, indexPath: indexPath, collectionView: collectionView)
    }
}

extension SpaceHomeViewController: UICollectionViewDelegate {
    @available(iOS 13.0, *)
    public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        homeUI.contextMenuConfig(for: indexPath, sceneSourceID: self.currentSceneID(), collectionView: collectionView)
    }

    public func forceScrollToTop() {
        scrollToTop()
    }

    private func scrollToTop() {
        // 防止在手动刷新与推送的主动刷新事件冲突，导致刷新UI异常
        if refreshing { return }
        if let headerHeight = homeUI.headerSection?.headerViewHeight {
            collectionView.setContentOffset(CGPoint(x: 0, y: -headerHeight), animated: true)
        } else {
            collectionView.setContentOffset(.zero, animated: true)
        }
    }

    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if homeUI.headerSection != nil {
            // 有 header 时，滚动到顶部的偏移量需要调整一下
            scrollToTop()
            return false
        } else {
            return true
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let headerSection = homeUI.headerSection else {
            return
        }
        let headerHeight = headerSection.headerViewHeight
        if scrollView.contentOffset.y < -headerHeight {
            return // 下拉刷新区间
        } else if scrollView.contentOffset.y < 0 {
            scrollView.contentInset.top = -scrollView.contentOffset.y
        } else {
            scrollView.contentInset.top = 0
        }
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        homeUI.notifyDidEndDragging(willDecelerate: decelerate)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        homeUI.notifyDidEndDecelerating()
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        homeUI.didSelectItem(at: indexPath, collectionView: collectionView)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        homeUI.didEndDisplaying(at: indexPath, cell: cell, collectionView: collectionView)
    }
}

extension SpaceHomeViewController: UICollectionViewDragDelegate {
    public func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        homeUI.dragItem(for: indexPath, sceneSourceID: self.currentSceneID(), collectionView: collectionView)
    }

    public func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return nil }
        let params = UIDragPreviewParameters()
        params.visiblePath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 12)
        return params
    }

    public func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        self.collectionView.isScrollEnabled = true
    }
}

extension SpaceHomeViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        homeUI.itemSize(at: indexPath, containerWidth: collectionView.frame.width)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        homeUI.insets(for: section, containerWidth: collectionView.frame.width)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        homeUI.minimumLineSpacing(at: section, containerWidth: collectionView.frame.width)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        homeUI.minimumInteritemSpacing(at: section, containerWidth: collectionView.frame.width)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let height = homeUI.headerHeight(in: section, containerWidth: collectionView.frame.width)
        return CGSize(width: 0, height: height)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let height = homeUI.footerHeight(in: section, containerWidth: collectionView.frame.width)
        return CGSize(width: 0, height: height)
    }
}

// MARK: - Action Handlers
extension SpaceHomeViewController {

    @discardableResult
    private func create(with intent: SpaceCreateIntent, sourceView: UIView) -> UIViewController? {
        let module = intent.context.module
        let isShareFoler = intent.context.folderType?.isShareFolder ?? false

        switch module {
        case .personalSubFolder, .sharedSubFolder:
            let parentToken = intent.context.mountLocationToken
            if !parentToken.isEmpty {
                let bizParamter = SpaceBizParameter(module: module, containerID: parentToken, containerType: .folder)
                DocsTracker.reportSpaceFolderClick(params: .create(isBlank: false,
                                                                   location: intent.createButtonLocation,
                                                                   isShareFolder: isShareFoler),
                                                   bizParms: bizParamter)
            }
        case .baseHomePage:
            //bitable Home页面新建按钮点击直接打开模版页面
            return bitableHomeCreate(with: intent, sourceView: sourceView)
        default:
            let bizParamter = SpaceBizParameter(module: module)
            DocsTracker.reportSpacePagePageClick(enumEvent: DocsTracker.clickEventType(for: intent.context.module), params: .create, bizParms: bizParamter)
        }
        if intent.context.createConfig.forceCreateFolder {
            createFolder(intent: intent)
            return nil
        }
        return createInLark(with: intent, sourceView: sourceView)
    }

    @discardableResult
    private func createInLark(with intent: SpaceCreateIntent, sourceView: UIView) -> UIViewController {

        var ccmOpenSource = intent.context.module.generateCCMOpenCreateSource()
        if intent.source == .fromOnboardingBanner {
            ccmOpenSource = .homeBanner
        }
        let trackParameters = DocsCreateDirectorV2.TrackParameters(source: intent.source,
                                                                   module: intent.context.module,
                                                                   ccmOpenSource: ccmOpenSource)
        let helper = SpaceCreatePanelHelper(trackParameters: trackParameters,
                                            mountLocation: intent.context.mountLocation,
                                            createDelegate: self,
                                            createRouter: self,
                                            createButtonLocation: intent.createButtonLocation)
        let reachableRelay = BehaviorRelay(value: true)
        let items = helper.generateItemsForLark(intent: intent, reachable: reachableRelay.asObservable())
        let templateViewModel = helper.generateTemplateViewModel()
        let createPanelVC = SpaceCreatePanelController(items: items, templateViewModel: templateViewModel)
        createPanelVC.cancelHandler = helper.createCancelHandler()
        DocsNetStateMonitor.shared.addObserver(createPanelVC) { (_, isReachable) in
            reachableRelay.accept(isReachable)
        }
        createPanelVC.setupPopover(sourceView: sourceView, direction: .any)
        createPanelVC.dismissalStrategy = [.larkSizeClassChanged]
        userResolver.navigator.present(createPanelVC, from: self)
        return createPanelVC
    }

    @discardableResult
    private func bitableHomeCreate(with intent: SpaceCreateIntent, sourceView: UIView) -> UIViewController {
        let ccmOpenSource = intent.context.module.generateCCMOpenCreateSource()
        let trackParameters = DocsCreateDirectorV2.TrackParameters(source: intent.source,
                                                                   module: intent.context.module,
                                                                   ccmOpenSource: ccmOpenSource)
        let helper = SpaceCreatePanelHelper(trackParameters: trackParameters,
                                            mountLocation: intent.context.mountLocation,
                                            createDelegate: self,
                                            createRouter: self,
                                            createButtonLocation: intent.createButtonLocation)

        return helper.createBitableAddButtonHandler(sourceView: sourceView)
    }

    private func showManualOfflineSuggestion(completion: @escaping (Bool) -> Void) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Doc_List_OfflineSetAvailable)
        dialog.setContent(text: BundleI18n.SKResource.Doc_List_OfflineDownloadTip,
                           color: UDColor.textTitle,
                           font: UIFont.systemFont(ofSize: 16),
                           alignment: .center,
                           lineSpacing: 3,
                           numberOfLines: 0)

        // 设置为手动离线
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_OfflineMakeAvailable, dismissCheck: {
            completion(true)
            return true
        })

        // 不用了
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_List_OfflineNeedNot, dismissCheck: {
            completion(false)
            return true
        })
        present(dialog, animated: true)
    }

    private func createFolder(intent: SpaceCreateIntent) {
        let ccmOpenSource = intent.context.module.generateCCMOpenCreateSource()
        let trackParameters = DocsCreateDirectorV2.TrackParameters(source: intent.source,
                                                                   module: intent.context.module,
                                                                   ccmOpenSource: ccmOpenSource)
        let helper = SpaceCreatePanelHelper(trackParameters: trackParameters,
                                            mountLocation: intent.context.mountLocation,
                                            createDelegate: self,
                                            createRouter: self,
                                            createButtonLocation: intent.createButtonLocation)
        helper.directlyCreateFolder()
    }
}

// MARK: - iPad Compatible
extension SpaceHomeViewController {
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    public override func splitSplitModeChange(splitMode: SplitViewController.SplitMode) {
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.layoutIfNeeded()
    }
}

// MARK: - New User Guide
extension SpaceHomeViewController {

    private func startNewUserGuide(tracker: SpaceBannerTracker, completion: @escaping () -> Void) {
        guard let entranceFrame = calculateEntranceSectionFrame() else { return }
        showEntranceIntroduction(entranceFrame: entranceFrame, tracker: tracker, completion: completion)
    }

    private func calculateEntranceSectionFrame() -> CGRect? {
        guard let sectionIndex = homeUI.sectionIndex(for: SpaceEntranceSection.sectionIdentifier) else {
            DocsLogger.error("space.home.vc --- failed to get entrance section index when showing user guide")
            return nil
        }
        let numberOfItems = homeUI.numberOfItems(in: sectionIndex)
        guard numberOfItems > 0 else {
            DocsLogger.error("space.home.vc --- entrance items count is zero when showing  user guide")
            return nil
        }
        guard let firstItemFrame = collectionView.layoutAttributesForItem(at: IndexPath(item: 0, section: sectionIndex))?.frame,
              let lastItemFrame = collectionView.layoutAttributesForItem(at: IndexPath(item: numberOfItems - 1, section: sectionIndex))?.frame else {
            DocsLogger.error("space.home.vc --- failed to calculate section frame when showing user guide")
            return nil
        }
        let frame = CGRect(x: 0,
                           y: firstItemFrame.minY - 12,
                           width: collectionView.frame.width,
                           height: lastItemFrame.maxY - firstItemFrame.minY + 20)
        let result = collectionView.convert(frame, to: nil)
        DocsLogger.info("space.home.vc --- entrance section frame: \(frame), final result: \(result)")
        return result
    }

    private func showEntranceIntroduction(entranceFrame: CGRect, tracker: SpaceBannerTracker, completion: @escaping () -> Void) {
        guard let currentWindow = view.window else { return }
        let hostViewController = OnboardingManager.shared.generateFullScreenWindow(uponCurrentWindow: currentWindow).rootViewController!
        onboardingHostViewControllers[.spaceHomeNewbieNavigation] = hostViewController
        onboardingTargetRects[.spaceHomeNewbieNavigation] = entranceFrame
        onboardingIndexes[.spaceHomeNewbieNavigation] = "1/\(userGuideStepCount)"
        onboardingAcknowledgedBlocks[.spaceHomeNewbieNavigation] = { [weak self] in
            guard let self = self else { return }
            self.showCreateIntroduction(tracker: tracker, completion: completion)
            self.onboardingHostViewControllers[.spaceHomeNewbieNavigation] = nil
        }
        OnboardingManager.shared.showFlowOnboarding(id: .spaceHomeNewbieNavigation, delegate: self, dataSource: self)
        tracker.reportShowOnboardingGuide(step: 1)
    }

    private func showCreateIntroduction(tracker: SpaceBannerTracker, completion: @escaping () -> Void) {
        let intent = SpaceCreateIntent(context: .recent, source: .fromOnboardingBanner, createButtonLocation: .bottomRight)
        guard let createVC = create(with: intent, sourceView: createButton) as? SpaceCreatePanelOnboardingController else {
            DocsLogger.info("is in Lark docs App")
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) { [self] in
            guard let currentWindow = view.window else { return }
            onboardingHostViewControllers[.spaceHomeNewbieCreateDocument] = OnboardingManager.shared.generateFullScreenWindow(uponCurrentWindow: currentWindow).rootViewController!
            let targetRect = createVC.createOnboardingRect
            onboardingTargetRects[.spaceHomeNewbieCreateDocument] = targetRect
            /// 截止到3.7.0版本，只有mindnote，如果以后有新的，可以在这里维护，判断
            var fileNames = ""
            if DocsType.enableDocTypeDependOnFeatureGating(type: .mindnote) {
                fileNames = BundleI18n.SKResource.Doc_List_CreateAppendMindnote
            }
            onboardingHints[.spaceHomeNewbieCreateDocument] = BundleI18n.SKResource.Doc_List_CreateTips(fileNames)
            onboardingIndexes[.spaceHomeNewbieCreateDocument] = "2/\(userGuideStepCount)"
            onboardingAcknowledgedBlocks[.spaceHomeNewbieCreateDocument] = { [weak self, weak createVC] in
                guard let self = self, let createVC = createVC else { return }
                DocsTracker.log(enumEvent: .showOnboardingCreateMobile, parameters: ["action": "create"])
                if TemplateRemoteConfig.templateEnable {
                    self.showCreateByTemplateIntroduction(createVC: createVC, tracker: tracker, completion: completion)
                } else {
                    createVC.dismiss(animated: true, completion: completion)
                }
                self.onboardingHostViewControllers[.spaceHomeNewbieCreateDocument] = nil
            }
            OnboardingManager.shared.showFlowOnboarding(id: .spaceHomeNewbieCreateDocument, delegate: self, dataSource: self)
            tracker.reportShowOnboardingGuide(step: 2)
        }
    }

    private func showCreateByTemplateIntroduction(createVC: SpaceCreatePanelOnboardingController, tracker: SpaceBannerTracker, completion: @escaping () -> Void) {
        guard let currentWindow = view.window else { return }
        onboardingHostViewControllers[.spaceHomeNewbieCreateTemplate] = OnboardingManager.shared.generateFullScreenWindow(uponCurrentWindow: currentWindow).rootViewController!
        let targetRect = createVC.templateOnboardingRect
        onboardingTargetRects[.spaceHomeNewbieCreateTemplate] = targetRect
        onboardingIndexes[.spaceHomeNewbieCreateTemplate] = "\(userGuideStepCount)/\(userGuideStepCount)"
        onboardingAcknowledgedBlocks[.spaceHomeNewbieCreateTemplate] = { [weak self, weak createVC] in
            guard let self = self, let createVC = createVC else { return }
            createVC.dismiss(animated: true, completion: completion)
            self.onboardingHostViewControllers[.spaceHomeNewbieCreateTemplate] = nil
        }
        OnboardingManager.shared.showFlowOnboarding(id: .spaceHomeNewbieCreateTemplate, delegate: self, dataSource: self)
        tracker.reportShowOnboardingGuide(step: userGuideStepCount)
    }
}

private extension SpaceHomeViewController {
    private func showDeleteConfirmView(file: SpaceEntry, completion: @escaping SpaceSectionAction.DeleteCompletion) {
        let ownerID = file.ownerID ?? ""
        var checkBoxTips = ""
        var canDeleteOriginFile = false
        var isNeedCheckBox = false
        if !file.isSingleContainerNode {
            if let userID = User.current.info?.userID, ownerID == userID, file.type != .folder, file.type != .wiki {
                canDeleteOriginFile = true
            }
            if canDeleteOriginFile {
                checkBoxTips = BundleI18n.SKResource.Doc_List_Delete_Source_Item
                isNeedCheckBox = true
            }
        }

        let config = UDDialogUIConfig()
        config.contentMargin = .zero
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: BundleI18n.SKResource.Doc_List_Remove_Recent_Dialog_Title, checkButton: isNeedCheckBox)
        dialog.setContent(text: BundleI18n.SKResource.Doc_List_Remove_Recent_Dialog_Content, checkButton: isNeedCheckBox)
        if isNeedCheckBox {
            dialog.setCheckButton(text: checkBoxTips)
        }
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCheck: { () -> Bool in
            completion(false, false)
            return true
        })
        dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_More_Remove, dismissCheck: { [weak dialog] () -> Bool in
            let shouldDeleteOriginFile = dialog?.isChecked ?? false
            if canDeleteOriginFile, shouldDeleteOriginFile {
                completion(true, true)
            } else {
                completion(true, false)
            }
            return true
        })
        present(dialog, animated: true, completion: nil)
    }

    private func showDeleteConfirmForManualOfflineView(completion: @escaping (Bool) -> Void) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Doc_List_OfflineRemoveTitle)
        dialog.setContent(text: BundleI18n.SKResource.Doc_List_OfflineRemoveContent)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCheck: { () -> Bool in
            completion(false)
            return true
        })
        dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_More_Remove, dismissCheck: { () -> Bool in
            completion(true)
            return true
        })
        present(dialog, animated: true, completion: nil)
    }
    private func showDeleteFailView(files: [SpaceEntry]) {
        typealias Parser = SpaceList.ItemDataParser

        let models = files.map { (entry) -> DeleteFailListItem in
            let title = Parser.mainTitle(file: entry, shouldShowNoPermBiz: true)
            let listIconType = Parser.listIconType(file: entry, shouldShowNoPermBiz: true, preferSquareDefaultIcon: false)
            var subtitle: String?
            if entry.hasPermission {
                if entry.isShortCut {
                    subtitle = BundleI18n.SKResource.CreationMobile_Wiki_Shortcuts_ShortcutLabel_Placeholder
                } else if let ownerName = entry.owner {
                    subtitle = BundleI18n.SKResource.Doc_Share_ShareOwner + ": " + ownerName
                } else {
                    subtitle = BundleI18n.SKResource.Doc_Share_ShareOwner
                }
            }

            let item = DeleteFailListItem(enable: true,
                                     title: title,
                                     subTitle: subtitle,
                                     isShortCut: entry.isShortCut,
                                     listIconType: listIconType,
                                     hasPermission: entry.hasPermission,
                                     entry: entry)

            return item
        }

        guard !models.isEmpty else {
            DocsLogger.info("fail item is empty")
            return
        }

        if SKDisplay.pad, isMyWindowRegularSize() {
            let viewController = IpadDeleteFailViewController(userResolver: userResolver, items: models)
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .formSheet
            userResolver.navigator.present(nav, from: self)
        } else {
            let viewController = DeleteFailViewController(userResolver: userResolver, items: models)
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .overFullScreen
            nav.transitioningDelegate = viewController.panelTransitioningDelegate
            userResolver.navigator.present(nav, from: self)
        }
    }
}

extension SpaceHomeViewController {
    public func visableIndicesHelper(sectionIndex: Int) -> () -> [Int] {
        return { [weak self] in
            guard let self = self else { return [] }
            let task: () -> [Int] = {
                let indices = self.collectionView.indexPathsForVisibleItems
                    .filter { $0.section == sectionIndex }
                    .map(\.item)
                return indices
            }
            if Thread.current.isMainThread {
                return task()
            } else {
                return DispatchQueue.main.sync(execute: task)
            }
        }
    }

    private func showRefreshTipsIfNeed(callback: @escaping () -> Void) {
        guard refreshTipView == nil else { return }
        let config = SettingConfig.spaceRustPushConfig ?? .default
        if let previousDate = previousTipShowDate {
            let timeInterval = Date().timeIntervalSince(previousDate) * 1000
            if timeInterval < config.minimumTipInterval { return }
        }
        previousTipShowDate = Date()
        let tipView = SpaceListRefreshTipView()
        refreshTipView = tipView
        tipView.alpha = 0
        view.addSubview(tipView)
        tipView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().inset(40)
            make.right.lessThanOrEqualToSuperview().inset(40)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(60)
        }
        UIView.animate(withDuration: 0.5) {
            tipView.alpha = 1
        }
        tipView.clickHandler = callback
        // ms 转换为 s
        tipView.set(timeout: config.refreshTipDuration / 1000) { [weak self] in
            self?.dismissRefreshTips()
        }
    }

    private func dismissRefreshTips() {
        guard let tipView = refreshTipView else { return }
        refreshTipView = nil
        UIView.animate(withDuration: 0.5) {
            tipView.alpha = 0
        } completion: { _ in
            tipView.removeFromSuperview()
        }

    }
}

extension SpaceHomeViewController: RefreshViewDelegate {
    public func stateDidChange(view: ESRefreshComponent, state: ESRefreshViewState) {

    }
}

// Keyboard Show/Hide event
private extension SpaceHomeViewController {
    func setupKeyboardMonitor() {
        guard SKDisplay.pad else { return }
        keyboard.on(event: .willShow) { [weak self] opt in
            self?.updateCreateButtonIfNeed(keyboardFrame: opt.endFrame, animationDuration: opt.animationDuration)
        }
        keyboard.on(event: .didShow) { [weak self] opt in
            self?.updateCreateButtonIfNeed(keyboardFrame: opt.endFrame, animationDuration: opt.animationDuration)
        }
        keyboard.on(event: .willHide) { [weak self] opt in
            self?.resetCreateButton(animationDuration: opt.animationDuration)
        }
        keyboard.on(event: .didHide) { [weak self] _ in
            self?.resetCreateButton(animationDuration: nil)
        }
        keyboard.start()
    }

    func updateCreateButtonIfNeed(keyboardFrame: CGRect, animationDuration: Double?) {
        let safeAreaViewFrame = view.safeAreaLayoutGuide.layoutFrame
        let buttonX = safeAreaViewFrame.maxX - 16 - 48
        let buttonY = safeAreaViewFrame.maxY - 16 - 48
        let originButtonFrame = CGRect(x: buttonX, y: buttonY, width: 48, height: 48)
        let buttonFrameOnWindow = view.convert(originButtonFrame, to: nil)
        let accessoryViewHeight = UIResponder.sk.currentFirstResponder?.inputAccessoryView?.frame.height ?? 0
        let keyboardMinY = keyboardFrame.minY - accessoryViewHeight
        if buttonFrameOnWindow.intersects(keyboardFrame), keyboardMinY > buttonFrameOnWindow.minY {
            // 仅当键盘与创建按钮有交集，且键盘高度不足以完全遮挡创建按钮时，抬高创建按钮的高度
            let inset = buttonFrameOnWindow.maxY - keyboardFrame.origin.y - accessoryViewHeight + 16
            let realInset = max(inset, 16)
            createButton.snp.updateConstraints { make in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(realInset)
            }
        } else {
            createButton.snp.updateConstraints { make in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
            }
        }
        if let duration = animationDuration {
            UIView.animate(withDuration: duration) {
                self.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
    }

    func resetCreateButton(animationDuration: Double?) {
        createButton.snp.updateConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
        }
        if let duration = animationDuration {
            UIView.animate(withDuration: duration) {
                self.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
    }
}

// 密钥删除
private extension SpaceHomeViewController {
    func setupAppearEvent() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveKeyDeletedEvent), name: .Docs.cipherChanged, object: nil)
    }

    @objc
    func didReceiveKeyDeletedEvent() {
        DispatchQueue.main.async { [self] in
            if isAppear {
                DocsLogger.info("space.home.vc --- refresh immediately when isAppear for cipher changed")
                homeUI.notifyPullToRefresh()
            } else {
                DocsLogger.info("space.home.vc --- wait for appear for cipher changed")
                needRefreshWhenAppear = true
            }
        }
    }
}

// TODO: 研究一下如何把 onboarding 逻辑下沉到 section 或 viewModel 中
// MARK: - Cloud Drive onboarding
extension SpaceHomeViewController {

    private func showCloudDriveOnboarding() {
        guard let (sectionIndex, entranceIndex, entranceFrame) = calculateCloudDriveEntranceFrame() else {
            DocsLogger.error("failed to get cloud dirve entrance info when showing onboarding")
            return
        }
        showCloudDriveOnboarding(sectionIndex: sectionIndex, entranceIndex: entranceIndex, entranceFrame: entranceFrame)
    }
    // return: sectionIndex, cellIndex, cellFrame
    private func calculateCloudDriveEntranceFrame() -> (Int, Int, CGRect)? {
        guard let sectionIndex = homeUI.sectionIndex(for: SpaceEntranceSection.sectionIdentifier),
              let entranceSection = homeUI.section(for: SpaceEntranceSection.sectionIdentifier) as? SpaceEntranceSection else {
            DocsLogger.error("space.home.vc --- failed to get entrance section when showing cloud drive onboarding")
            return nil
        }
        let cloudDriveIndex = entranceSection.entranceIndex(for: SpaceEntranceSection.EntranceIdentifier.cloudDrive)
        let ipadCloudDriveIndex = entranceSection.entranceIndex(for: SpaceEntranceSection.EntranceIdentifier.ipadCloudDriver)
        
        guard let index = cloudDriveIndex ?? ipadCloudDriveIndex else {
            DocsLogger.error("space.home.vc --- failed to get cloud drive entrance index when showing ipad cloud drive onboarding")
            return nil
        }

        guard let entranceFrame = collectionView.layoutAttributesForItem(at: IndexPath(item: index, section: sectionIndex))?.frame else {
            DocsLogger.error("space.home.vc --- failed to calculate entrance frame when showing cloud drive guide")
            return nil
        }
        let result = collectionView.convert(entranceFrame, to: nil)
        DocsLogger.info("space.home.vc --- entrance section frame: \(entranceFrame), final result: \(result)")
        return (sectionIndex, index, result)
    }

    private func showCloudDriveOnboarding(sectionIndex: Int, entranceIndex: Int, entranceFrame: CGRect) {
        guard let currentWindow = view.window else { return }
        guard let hostViewController = OnboardingManager.shared.generateFullScreenWindow(uponCurrentWindow: currentWindow).rootViewController else {
            spaceAssertionFailure("create onboarding hostVC failed")
            return
        }
        let onboardingKey = OnboardingID.spaceHomeCloudDrive
        onboardingHostViewControllers[onboardingKey] = hostViewController
        onboardingTargetRects[onboardingKey] = entranceFrame
        OnboardingManager.shared.showFlowOnboarding(id: onboardingKey, delegate: self, dataSource: self)
    }
}

// 将文件夹容器与spaceHomeViewController的强依赖改为协议的方式处理
extension SpaceHomeViewController: SpaceFolderContentViewController {
    public var contentNaviBarCoordinator: SpaceNaviBarCoordinator? {
        return self.naviBarCoordinator
    }
}
