//
//  WikiTreeViewController.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/9/23.
//  swiftlint:disable file_length

import Foundation
import RxSwift
import SnapKit
import UniverseDesignToast
import EENavigator
import LarkUIKit
import SKCommon
import SKSpace
import SKUIKit
import SKResource
import SKFoundation
import UniverseDesignColor
import UniverseDesignDialog
import UniverseDesignNotice
import SpaceInterface
import SKInfra
import SKWorkspace
import LarkContainer

// swiftlint:disable type_body_length
class WikiTreeDraggableViewController: DraggableViewController, UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate, UDNoticeDelegate {

    override public var gapState: DraggableViewController.GapState {
        didSet {
            if gapState != oldValue, gapState == .min {
                // 滑动到最大高度埋点
                WikiStatistic.fullExpandPage(wikiToken: viewModel.wikiToken)
            }
            updateSearchView(gapState: gapState)
        }
    }

    let viewModel: WikiTreeDraggableViewModel
    private let bag = DisposeBag()

    private lazy var titleView: WikiTreeTitleView = {
        if contentViewCanBeDragged {
            let titleView = WikiTreeDraggleTitleView()
            titleView.addGestureRecognizer(panGestureRecognizer)
            return titleView
        } else {
            let titleView = WikiTreeNormalTitleView()
            titleView.closeButton.addTarget(self, action: #selector(dismissByTitleView), for: .touchUpInside)
            return titleView
        }
    }()
    private let titleViewHeight: CGFloat = 65
    private(set) var swipeLeftOnboardingRect: CGRect = .zero

    weak var hostViewController: UIViewController?

    let treeView: TreeView
    let treeTableViewState = TreeTableViewState()

    // 是否处于屏幕上
    private var isShowInScreen = false

    private lazy var searchBar: DocsSearchBar = {
        let searchBar = DocsSearchBar()
        searchBar.textField.placeholder = BundleI18n.SKResource.Doc_Wiki_Tree_Search
        searchBar.tapBlock = { [weak self] _ in self?.onSelectSearch() }
        return searchBar
    }()
    private let searchBarHeight: CGFloat = 32

    private let bottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    private var searchController: UIViewController?

    private lazy var migrateNotice: UDNotice = {
        let title = NSAttributedString(string: BundleI18n.SKResource.CreationMobile_Wiki_Upgrade_UnableToProceedTree)
        var noticeConfig = UDNoticeUIConfig(type: .info, attributedText: title)
        noticeConfig.leadingButtonText = BundleI18n.SKResource.CreationMobile_Wiki_Upgrade_LearnMore
        let notice = UDNotice(config: noticeConfig)
        notice.delegate = self
        return notice
    }()
    
    private lazy var actuallyView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        return view
    }()
    
    private lazy var uploadView: DriveUploadContentView = {
        let view = DriveUploadContentView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(gotoUploaList))
        view.addGestureRecognizer(tap)
        return view
    }()
    
    private lazy var selectFileHelper = WikiSelectFileHelper(hostViewController: self, triggerLocation: .wikiTree)
    let userResolver: UserResolver
    
    init(userResolver: UserResolver, viewModel: WikiTreeDraggableViewModel) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.treeView = TreeView(dataBuilder: viewModel.treeViewModel)
        super.init(nibName: nil, bundle: nil)
        treeView.treeViewRouter = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DocsLogger.info("WikiTreeDraggableViewController -- deinit")
    }

    @objc
    func willDealloc() -> Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        _setupContentView()
        _setupTitleView()
        setupMigrateNotice()
        _setupSearchBar()
        _setupBottomLine()
        showSearchBar()
        showBottomLine()
        _setupTreeView()
        _bindAction()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapBackgroundView))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        WikiStatistic.treeView(spaceId: viewModel.treeViewModel.spaceID)
        self.navigationController?.navigationBar.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.prepareRisePanel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.afterRisePanel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 收起已展开的侧滑菜单
        treeView.tableView.setEditing(false, animated: false)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if SKDisplay.pad {
            self._dismiss()
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.viewModel.supportOrientation ?? .allButUpsideDown
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self._updateContentViewMaskLayer()
    }

    private func prepareRisePanel() {
        WikiStatistic.expandPage(wikiToken: viewModel.wikiToken)
        // 有缓存，走缓存逻辑
        if let currentNodeUID = viewModel.currentNodeUID {
            viewModel.treeViewModel.scrollByUIDInput.accept(currentNodeUID)
            treeTableViewState.currentContentOffset = treeView.tableView.contentOffset
            WikiPerformanceRecorder.shared.wikiPerformanceRecordEnd(event: .wikiOpenTreePerformance,
                                                                    stage: .total,
                                                                    wikiToken: viewModel.wikiToken,
                                                                    resultKey: .success,
                                                                    resultCode: "0")
        }
        treeTableViewState.isFirstScrollToTop = true
        treeTableViewState.lastPositionY = 0
        treeTableViewState.currentContentY = contentViewMaxY
    }

    private func afterRisePanel() {
        self.isShowInScreen = true
    }

    @objc
    private func tapBackgroundView() {
        // 收起页面树埋点
        WikiStatistic.closePage(wikiToken: viewModel.wikiToken)
        self._dismiss()
    }

    private func _setupContentView() {
        contentView = UIView()
        contentView.backgroundColor = UDColor.bgBody
        view.addSubview(contentView)
        if contentViewCanBeDragged {
            contentView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalTo(contentViewMaxY)
                make.height.equalTo(self.view.bounds.height - contentViewMaxY)
            }
            self.gapState = .bottom
            view.layoutIfNeeded()
        } else {
            contentView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }

    private func _setupTitleView() {
        contentView.addSubview(titleView)
        titleView.snp.makeConstraints { (make) in
            make.top.equalTo(contentView.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(contentView.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(contentView.safeAreaLayoutGuide.snp.right)
        }
    }

    private func updateUploadView(item: DriveStatusItem?) {
        if let uploadItem = item {
            actuallyView.frame.size = CGSize(width: view.bounds.size.width, height: 68)
            actuallyView.addSubview(uploadView)
            uploadView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.height.equalTo(48)
            }
            uploadView.update(uploadItem)
            if treeView.tableView.tableHeaderView == nil {
                treeView.tableView.tableHeaderView = actuallyView
            }
        } else {
            treeView.tableView.tableHeaderView = nil
        }
        view.setNeedsLayout()
    }
    
    @objc
    private func gotoUploaList() {
        let encrySpaceID = DocsTracker.encrypt(id: viewModel.treeViewModel.spaceID)
        let params: [String: Any] = ["container_id": encrySpaceID, "container_type": "wiki"]
        DocsContainer.shared.resolve(DriveRouterBase.self)?.type()
            .showUploadListViewController(sourceViewController: self,
                                          folderToken: self.viewModel.mountToken,
                                          scene: .workspace,
                                          params: params)
    }
    
    private func _updateContentViewMaskLayer() {
        guard contentViewCanBeDragged else { return }
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: contentView.bounds.width, height: self.view.bounds.height - contentViewMinY),
                                byRoundingCorners: UIRectCorner(rawValue: UIRectCorner.topLeft.rawValue | UIRectCorner.topRight.rawValue),
                                cornerRadii: CGSize(width: 10, height: 10))
        maskLayer.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: self.view.bounds.height - contentViewMinY)
        maskLayer.path = path.cgPath
        contentView.layer.mask = maskLayer
    }

    public override func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        super.handlePanGestureRecognizer(panGestureRecognizer)
        treeTableViewState.isFirstScrollToTop = false
    }

    private func setupMigrateNotice() {
        contentView.addSubview(migrateNotice)
        migrateNotice.snp.makeConstraints { (make) in
            make.top.equalTo(titleView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        migrateNotice.isHidden = true
    }

    private func _setupSearchBar() {
        contentView.addSubview(searchBar)
        searchBar.snp.makeConstraints { (make) in
            make.top.equalTo(migrateNotice.snp.bottom).offset(6)
            make.height.equalTo(0)
            make.left.equalTo(contentView.safeAreaLayoutGuide.snp.left)
            make.right.equalTo(contentView.safeAreaLayoutGuide.snp.right)
        }
    }

    private func _setupBottomLine() {
        contentView.addSubview(bottomLine)
        bottomLine.snp.makeConstraints { (make) in
            make.top.equalTo(searchBar.snp.bottom).offset(12.5)
            make.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
    }

    private func _setupTreeView() {
        contentView.addSubview(treeView)
        treeView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(bottomLine.snp.bottom)
        }
        treeView.tableView.rx.willBeginDragging.subscribe(onNext: {[weak self] in
            guard let self = self else { return }
            self.treeTableViewWillBeginDragging(self.treeView.tableView)
        }).disposed(by: bag)
        treeView.tableView.rx.didScroll.subscribe(onNext: {[weak self] in
            guard let self = self else { return }
            self.treeTableViewDidScroll(self.treeView.tableView)
        }).disposed(by: bag)

        viewModel.treeViewModel.setup()
        viewModel.uploadState.observeOn(MainScheduler.instance).subscribe(onNext: {[weak self] item in
            guard let self = self else { return }
            self.updateUploadView(item: item)
        }).disposed(by: bag)
        viewModel.treeViewModel.onUploadSignal.emit(onNext: { [weak self] (token, isImage, action) in
            guard let self = self else { return }
            if isImage {
                self.selectFileHelper.selectImages(wikiToken: token, completion: action)
            } else {
                self.selectFileHelper.selectFile(wikiToken: token, completion: action)
            }
        }).disposed(by: bag)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        treeView.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.view.safeAreaInsets.bottom, right: 0)
    }

    private func showSearchBar() {
        searchBar.snp.updateConstraints { make in
            make.height.equalTo(searchBarHeight)
        }
    }

    private func showBottomLine() {
        bottomLine.snp.updateConstraints { (make) in
            make.height.equalTo(0.5)
        }
    }

    private func _bindAction() {
        // 更新标题
        viewModel.treeViewModel.dataModel
            .spaceInfoUpdated
            .drive(onNext: { [weak self] spaceInfo in
                guard let self = self, let space = spaceInfo else { return }
                let title = space.displayTitle
                self.titleView.setTitle(title)
                // 显示搜索框
                self.showSearchBar()
                // 显示分割线
                self.showBottomLine()
                if space.migrateStatus == .migrating {
                    self.migrateNotice.isHidden = false
                    let height = self.migrateNotice.sizeThatFits(self.view.frame.size).height
                    self.migrateNotice.snp.updateConstraints { make in
                        make.height.equalTo(height)
                    }
                    self.migrateNotice.update()
                } else {
                    self.migrateNotice.isHidden = true
                    self.migrateNotice.snp.updateConstraints { make in
                        make.height.equalTo(0)
                    }
                }
            })
            .disposed(by: bag)
        viewModel.treeViewModel
            .reloadSuccessDriver
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                WikiPerformanceRecorder.shared.wikiPerformanceRecordEnd(event: .wikiOpenTreePerformance,
                                                                        stage: .total,
                                                                        wikiToken: self.viewModel.wikiToken,
                                                                        resultKey: .success,
                                                                        resultCode: "0")
            })
            .disposed(by: bag)

        viewModel.treeViewModel
            .reloadFailedDriver
            .drive(onNext: { [weak self] error in
                guard let self = self else { return }
                WikiPerformanceRecorder.shared.wikiPerformanceRecordEnd(event: .wikiOpenTreePerformance,
                                                                        stage: .total,
                                                                        wikiToken: self.viewModel.wikiToken,
                                                                        resultKey: .fail,
                                                                        resultCode: String((error as NSError).code))
            })
            .disposed(by: bag)

        // onboarding
        viewModel.treeViewModel
            .actionSignal
            .filter { action in
                guard case .scrollTo = action else {
                    return false
                }
                return true
            }
            .delay(DispatchQueueConst.MilliSeconds_500)
            .emit(onNext: {[weak self] _ in
                self?.showLeftSwipOnboardingIfNeeded()
            })
            .disposed(by: bag)
        // 点击节点后面板自动下去
        viewModel.treeViewModel
            .onClickNodeSignal
            .emit(onNext: { [weak self] _ in
                guard let self = self else { return }
                if self.isShowInScreen { self._dismiss() }
            })
            .disposed(by: bag)
        // 点击搜索结果
        viewModel
            .clickSearchResult
            .emit(onNext: { [weak self] _ in
                self?._dismiss()
            })
            .disposed(by: bag)
    }

    private func showLeftSwipOnboardingIfNeeded() {
        let wikiNewbiePageTreeHasFinished = OnboardingManager.shared.hasFinished(OnboardingID.wikiNewbiePageTree)
        let wikiNewbieSwipeLeftHasFinished = OnboardingManager.shared.hasFinished(OnboardingID.wikiNewbieSwipeLeft)
        if wikiNewbiePageTreeHasFinished && !wikiNewbieSwipeLeftHasFinished {
            //  判断是否在屏幕上
            guard isShowInScreen else {
                DocsLogger.info("需要展示左滑onboarding，但是当前面板不显示在屏幕，不展示onboarding")
                return
            }
            DocsLogger.info("命中条件，wikiNewbiePageTree：\(wikiNewbiePageTreeHasFinished)，wikiNewbieSwipeLeft: \(wikiNewbieSwipeLeftHasFinished)，展示左滑onboarding")
            // 获取高亮cell IndexPath
            var selectedIndexPath: IndexPath?
            for (index, section) in viewModel.treeViewModel.sectionRelay.value.enumerated() {
                if section.headerNode?.section == .mainRoot,
                   let nodeIndex = section.items.firstIndex(where: { $0.id == self.viewModel.wikiToken }) {
                    selectedIndexPath = IndexPath(item: nodeIndex, section: index)
                }
            }
            if let selectedIndexPath = selectedIndexPath,
               let cell = treeView.tableView.cellForRow(at: selectedIndexPath) as? TreeTableViewCell {
                // 实现cell自动左滑
                self.treeView.tableView.setEditing(true, animated: false)
                self.treeView.tableView.visibleCells.forEach({
                    if cell != $0 {
                        $0.setEditing(false, animated: false)
                    }
                })
                cell.autoLeftSwipe()
                // 获取onboarding位置
                let rectInTableView = self.treeView.tableView.rectForRow(at: selectedIndexPath)
                let rect = self.treeView.tableView.convert(rectInTableView, to: self.treeView)
                let treeRect = CGRect(x: self.treeView.bounds.width - 148, y: rect.minY, width: 148, height: rect.height)
                let rectInWindow = self.treeView.convert(treeRect, to: nil)
                self.swipeLeftOnboardingRect = rectInWindow
                // 展示onboarding
                OnboardingManager.shared.showFlowOnboarding(id: OnboardingID.wikiNewbieSwipeLeft, delegate: self, dataSource: self)
            } else {
                spaceAssertionFailure("cannot get right indexPath")
            }
        }
    }

    override func dragDismiss() {
        // 收起页面树埋点
        WikiStatistic.closePage(wikiToken: viewModel.wikiToken)
        self.viewModel.didDismiss.accept(())
        self.dismiss(animated: false, completion: {
            self.removeSearchView()
            self.isShowInScreen = false
        })
    }

    @objc
    private func dismissByTitleView() {
        _dismiss()
    }

    private func _dismiss(completion: (() -> Void)? = nil) {
        let completion: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.removeSearchView()
            self.isShowInScreen = false
            self.viewModel.didDismiss.accept(())
            completion?()
        }
        if let controller = presentingViewController {
            controller.dismiss(animated: true, completion: completion)
        } else {
            dismiss(animated: true, completion: completion)
        }
    }

    @objc
    func onSelectSearch() {
        setupSearchView()
        gapState = .min
    }

    private func reportDidClickSearchBar() {
        WikiStatistic.clickSearch(subModule: .wikiPages, source: .wikiPagesView, action: .searchButton)
    }

    private func setupSearchView() {
        guard let factory = try? userResolver.resolve(assert: WorkspaceSearchFactory.self) else {
            DocsLogger.error("can not get WorkspaceSearchFactory")
            return
        }

        let spaceID = viewModel.treeViewModel.spaceID
        let searchController = factory.createWikiTreeSearchController(spaceID: spaceID, delegate: self)

        addChild(searchController)
        contentView.addSubview(searchController.view)
        searchController.didMove(toParent: self)
        searchController.view.snp.makeConstraints { (make) in
            make.top.equalTo(titleView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        self.searchController = searchController
        // 点击搜索框埋点
        reportDidClickSearchBar()
    }

    private func removeSearchView() {
        guard let searchController else { return }
        searchController.willMove(toParent: nil)
        searchController.view.removeFromSuperview()
        searchController.removeFromParent()
        self.searchController = nil
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func updateSearchView(gapState: DraggableViewController.GapState) {
        // 不支持拖拽调整高度后，不再关注此方法
    }

    // MARK: - UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == view ? true : false
    }
    // MARK: - UIViewControllerTransitioningDelegate
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard contentViewCanBeDragged else { return nil }
        return DimmingPresentAnimation(animateDuration: self.viewModel.presentAnimationDuration)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard contentViewCanBeDragged else { return nil }
        return DimmingDismissAnimation(animateDuration: self.viewModel.dismissAnimationDuration)
    }

    // MARK: - UDNoticeDelegate
    /// 右侧文字按钮点击事件回调
    func handleLeadingButtonEvent(_ button: UIButton) {
        // 跳转到 learn more
        guard let hostVC = hostViewController else { return }
        _dismiss {
            WikiRouter.goToMigrationTip(userResolver: self.userResolver, from: hostVC)
        }
    }

    /// 右侧图标按钮点击事件回调
    func handleTrailingButtonEvent(_ button: UIButton) {}

    /// 文字按钮/文字链按钮点击事件回调
    func handleTextButtonEvent(URL: URL, characterRange: NSRange) {}
}

extension WikiTreeDraggableViewController: TreeViewRouter {
    func treeView(_ treeView: TreeView, openURL url: URL) {
        guard let hostViewController = hostViewController else {
            spaceAssertionFailure()
            return
        }
        _dismiss {
            self.userResolver.navigator.docs.showDetailOrPush(url, wrap: LkNavigationController.self, from: hostViewController, animated: true)
        }
    }
}

extension WikiTreeDraggableViewController: WikiTreeSearchDelegate {
    func searchControllerDidClickCancel(_ controller: UIViewController) {
        removeSearchView()
    }

    func searchController(_ controller: UIViewController, didClick item: WikiSearchResultItem) {
        guard case let .wikiNode(node) = item else { return }
        viewModel.didClickSearchResult.accept(node)
        // 更新目录树
        viewModel.updateData(node.wikiToken)
    }
}
