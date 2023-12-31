//
//  MeetTabViewController.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//

import RxCocoa
import RxSwift
import LKCommonsLogging
import Action
import SpriteKit
import RichLabel
import ByteViewCommon
import ByteViewNetwork
import UniverseDesignIcon
import ByteViewUI

final class MeetTabViewController: ByteViewBaseTabViewController {

    static let logger = Logger.tab

    // MARK: - Attribute Definition
    var isSelfAppear: Bool = false
    var isNavigationBarAnimating: Bool = false
    var shouldCheckNavigationBarVisibility = true
    var isLayoutUpdated: Bool = false
    var naviHeight: CGFloat {
        return larkMainViewController?.larkNavigationBarHeight ?? 0
    }

    var isRegular: Bool {
        MeetTabTraitCollectionManager.shared.isRegular
    }

    var isVCTabSelected: Bool {
        viewModel.globalDependency.isByteViewTabSelected(for: self)
    }

    enum ScrollState {
        case scrollViewCanScroll
        case tableViewCanScroll
    }
    var scrollState: ScrollState = .scrollViewCanScroll

    enum ScrollDirection {
        case unknown
        case up
        case down
    }
    var scrollDirection: ScrollDirection = .unknown

    enum UILayoutStyle {
        case compact
        case regular
    }
    /// 用于修复 scrollEnabled 相关崩溃
    var layoutStyle: UILayoutStyle = .compact

    let historyDataSource = MeetTabHistoryDataSource()
    var historyLoadMoreBag = DisposeBag()
    // 是否能进行下一次preload
    var preloadEnabled = true
    var preloadBag: DisposeBag = DisposeBag()
    var preloadWorkItem: DispatchWorkItem?
    var router: TabRouteDependency? { viewModel.router }

    //  获取view的即将更新的boundsSize，为header提供itemHeight的计算数据
    var newBoundsSize: CGSize?
    // MARK: - View Definition
    enum Layout {
        static let netHeight: CGFloat = 44.0
        static let headerHeight: CGFloat = 112.0
        static let masterWidth: CGFloat = 375.0
        static let statusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.height
    }

    private lazy var badgeView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 6, height: 6))
        view.backgroundColor = UIColor.ud.functionDangerContentDefault.dynamicColor
        view.layer.cornerRadius = 3
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()

    lazy var searchButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.searchOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        button.addTarget(self, action: #selector(searchAction), for: .touchUpInside)
        return button
    }()

    private lazy var rightBarButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.settingOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
        button.addTarget(self, action: #selector(rightBarButtonAction), for: .touchUpInside)
        button.addInteraction(type: .highlight)
        button.addSubview(badgeView)
        badgeView.snp.makeConstraints {
            $0.centerX.equalTo(button.snp.right)
            $0.centerY.equalTo(button.snp.top)
            $0.size.equalTo(6)
        }
        return button
    }()

    lazy var padNaviBarView: MeetTabNaviPadView = {
        let padNaviBarView = MeetTabNaviPadView(frame: .zero)
        padNaviBarView.backgroundColor = .ud.bgBody
        padNaviBarView.badgeView.isHidden = true
        return padNaviBarView
    }()
    lazy var headerView: MeetTabHeaderView = {
        let headerView = MeetTabHeaderView(frame: view.frame, viewModel: self.viewModel)
        headerView.containerView.isScrollEnabled = false
        return headerView
    }()
    lazy var tableFooterView: UIView = {
        let tableFooterView = UIView()
        tableFooterView.translatesAutoresizingMaskIntoConstraints = true
        tableFooterView.autoresizingMask = .flexibleWidth
        return tableFooterView
    }()
    lazy var noInternetView = MeetTabNoInternetView()
    lazy var containerView: EmbeddableScrollView = {
        let scrollView = EmbeddableScrollView(frame: .zero)
        scrollView.backgroundColor = UIColor.ud.bgBody
        scrollView.delegate = historyDataSource
        scrollView.clipsToBounds = true
        scrollView.bounces = false
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delaysContentTouches = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentOffsetDidChange = { [weak self] in
            self?.scrollView($0, didChangeContentOffsetFrom: $1, to: $2) ?? false
        }
        return scrollView
    }()
    lazy var scrollToTopButton: MeetTabScrollToTopButton = MeetTabScrollToTopButton(frame: .zero)
    /// 处理 tableview 在顶部时的下拉事件丢失问题
    lazy var wrapperScrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.isScrollEnabled = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.backgroundColor = .ud.bgContentBase
        return scrollView
    }()
    /// histroy list
    lazy var tabResultView: MeetTabResultView = {
        let tabResultView = MeetTabResultView(frame: .zero)
        tabResultView.tableView.tableFooterView = tableFooterView
        tabResultView.tableView.contentOffsetDidChange = { [weak self] in
            self?.scrollView($0, didChangeContentOffsetFrom: $1, to: $2) ?? false
        }
        return tabResultView
    }()
    let historyRefreshAnimator = RefreshAnimator(frame: .zero)
    var historyLoadMoreAnimator: RefreshAnimator {
        return RefreshAnimator(frame: .zero)
    }
    /// guide view
    var guideView: GuideView?

    override var userId: String { viewModel.userId }

    // MARK: - Init
    let viewModel: MeetTabListViewModel

    init(viewModel: MeetTabListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        viewModel.hostViewController = nil
        viewModel.tabViewModel.removeObserver(self)
    }

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        MeetTabTraitCollectionManager.shared.isRegular = traitCollection.isRegular
        viewModel.hostViewController = self
        configViewControllers()
        setupHistory()
        setupViews()
        bindViewActions()
        bindClearVideoConferenceTabUnreadCount()
        bindTopButton()

        viewModel.loadTabData()
        bindRefreshheaderViewButtons()
        viewModel.tabViewModel.addObserver(self)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        MeetTabTraitCollectionManager.shared.isRegular = traitCollection.isRegular
        guard isViewLoaded else { return }
        self.newBoundsSize = size
        coordinator.animate { [weak self] _ in
            guard let self = self else { return }
            self.updateLayout(isRegular: self.isRegular)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        isSelfAppear = true
        MeetTabTracks.trackEnterMeetTab()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateLayout(isRegular: isRegular)
    }

    var isFirstAppear: Bool = true
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // layout 兜底
        if !isLayoutUpdated {
            updateLayout(isRegular: isRegular)
        }
        if isFirstAppear {
            isFirstAppear = false
            bindToTabService()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isSelfAppear = false
        if isRegular {
            isLayoutUpdated = false
        }
    }

    override var naviBarSearchButton: UIButton? {
        searchButton
    }

    override var naviBarButton: UIButton? {
        rightBarButton
    }

    // MARK: - UI Config
    func configViewControllers() {
        configLinkLabel()
        configTableView()
    }

    func configTableView() {
        MeetTabHistoryDataSource.configCell(tabResultView.tableView)
        MeetTabHistoryDataSource.configHeaderView(tabResultView.tableView)

        addHistoryLoadMore()
        addHistoryRefreshBar()
        addLoadError([viewModel.historyDataSource, viewModel.upcomingDataSource], result: tabResultView)
    }

    func setTableViewBinds(_ isBound: Bool) {
        if isBound {
            containerView.innerTableView = tabResultView.tableView
            tabResultView.tableView.outerScrollView = containerView
        } else {
            containerView.innerTableView = nil
            tabResultView.tableView.outerScrollView = nil
        }
    }

    func configLinkLabel() {
        tabResultView.linkHandler = { [weak self] in
            MeetTabTracks.trackMeetTabOperation(.clickTabLoadFailed)
            self?.viewModel.loadTabData()
        }
    }

    // MARK: - UI layout
    func setupViews() {
        addBarViews()
        padNaviBarView.searchButton.addTarget(self, action: #selector(searchAction), for: .touchUpInside)
        padNaviBarView.rightBarButton.addTarget(self, action: #selector(rightBarButtonAction), for: .touchUpInside)
    }

    func addBarViews() {
        view.addSubview(containerView)
        view.addSubview(scrollToTopButton)
        containerView.addSubview(padNaviBarView)
        containerView.addSubview(noInternetView)
        containerView.addSubview(headerView)
        containerView.addSubview(wrapperScrollView)
        wrapperScrollView.addSubview(tabResultView)
    }

    func updateLayout(isRegular: Bool) {
        layoutStyle = isRegular ? .regular : .compact
        larkMainViewController?.reloadLarkNavigationBar()
        setTableViewBinds(!isRegular)
        padNaviBarView.isHidden = !isRegular
        showNavigationBar(show: !isRegular || !isVCTabSelected)
        containerView.backgroundColor = isRegular ? .ud.bgContentBase : .ud.bgBody
        self.view.backgroundColor = containerView.backgroundColor
        tabResultView.tableView.backgroundColor = isRegular ? .ud.bgContentBase : .ud.bgBody
        containerView.isScrollEnabled = isRegular ? false : true
        resetContainerViewContentInset(isRegular: isRegular)
        if isRegular {
            updateRegularLayout()
            tabResultView.extensionView.snp.remakeConstraints { (make) in
                make.top.left.right.bottom.equalToSuperview()
            }
        } else {
            updateCompactLayout()
            tabResultView.extensionView.snp.remakeConstraints { (make) in
                make.top.left.right.equalToSuperview()
                make.bottom.equalTo(view.snp.bottom)
            }
        }

        DispatchQueue.main.async { // 确保能拿到最新的 frame
            self.tabResultView.tableView.reloadData()
            self.tabResultView.tableView.setNeedsLayout()
            self.tabResultView.tableView.layoutIfNeeded()
        }
        isLayoutUpdated = true
    }

    // disable-lint: duplicated code
    func updateRegularLayout() {
        let inset = view.window?.safeAreaInsets ?? view.safeAreaInsets
        containerView.snp.remakeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        padNaviBarView.snp.remakeConstraints { (make) in
            make.top.left.equalToSuperview()
            make.width.equalTo(Layout.masterWidth)
            make.height.equalTo(60.0 + inset.top)
        }
        noInternetView.snp.remakeConstraints { (make) in
            make.top.equalTo(padNaviBarView.snp.bottom)
            make.left.equalToSuperview()
            make.height.equalTo(0)
            make.width.equalTo(Layout.masterWidth)
        }
        headerView.snp.remakeConstraints { (make) in
            make.top.equalTo(noInternetView.snp.bottom)
            make.left.equalToSuperview()
            make.width.equalTo(Layout.masterWidth)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        wrapperScrollView.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().inset(inset.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.right.equalTo(view.snp.right)
            make.left.equalTo(headerView.snp.right)
        }
        tabResultView.snp.remakeConstraints { (make) in
            make.edges.height.width.equalToSuperview()
        }
        scrollToTopButton.snp.remakeConstraints { (make) in
            make.width.height.equalTo(48.0)
            make.right.equalToSuperview().inset(20.0)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(20.0)
        }
    }

    func updateCompactLayout() {
        containerView.snp.remakeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).offset(naviHeight)
            make.left.right.width.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        padNaviBarView.snp.removeConstraints()
        noInternetView.snp.remakeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        headerView.snp.remakeConstraints { (make) in
            make.top.equalTo(noInternetView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(headerView.estimatedHeight)
        }
        wrapperScrollView.snp.remakeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom)
            make.left.right.bottom.width.equalToSuperview()
            make.height.equalTo(containerView)
        }
        tabResultView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
            make.size.equalToSuperview()
        }
        scrollToTopButton.snp.remakeConstraints { (make) in
            make.width.height.equalTo(48.0)
            make.right.equalToSuperview().inset(16.0)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(20.0)
        }
    }
    // enable-lint: duplicated code

    func resetTableViewFooterView(isRegular: Bool) {
        tabResultView.tableView.tableFooterView?.backgroundColor = isRegular ? .ud.bgContentBase : .ud.bgBody
        tabResultView.tableView.tableFooterView?.frame.size.height = isRegular ? 20.0 : 6.0
    }

    func resetContainerViewContentInset(isRegular: Bool) {
        resetTableViewFooterView(isRegular: isRegular)
    }

    func resetContainerViewContentOffset(animated: Bool = false) {
        self.scrollTableToIndex(IndexPath(row: 0, section: 0), at: .top, animated: animated)
        containerView.setContentOffset(.zero, animated: animated)
    }

    func scrollTableToIndex(_ index: IndexPath, at scrollPosition: UITableView.ScrollPosition, animated: Bool = false) {
        if tabResultView.tableView.numberOfSections > 0, tabResultView.tableView.numberOfRows(inSection: 0) > 0 {
            tabResultView.tableView.scrollToRow(at: index, at: scrollPosition, animated: animated)
        } else {
            tabResultView.tableView.setContentOffset(.zero, animated: animated)
        }
    }

    // MARK: - Data binding
    func bindTopButton() {
        tabResultView.tableView.rx.contentOffset
            .map { [weak self] in
                guard let self = self,
                      self.tabResultView.tableView.contentSize.height > self.tabResultView.tableView.bounds.height else {
                    return true
                }
                return $0.y <= (self.isRegular ? 66.5 : 70)
            }
            .asDriver(onErrorJustReturn: true)
            .drive(scrollToTopButton.rx.isHidden)
            .disposed(by: rx.disposeBag)

        scrollToTopButton.button.rx.action = CocoaAction { [weak self] _ in
            self?.tableScrollToTop()
            return .empty()
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(tableScrollToTop),
                                               name: Notification.Name(rawValue: "statusBarTappedNotification"),
                                               object: nil)
    }

    // 由于isEnterpriseCallKeyPadEnabled是同步接口，数据更新不及时，因此多一次请求来刷新配置
    func bindRefreshheaderViewButtons() {
        viewModel.setting.refreshEnterpriseConfig(force: true) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let resp):
                    let isAuthorized = resp.authorized
                    let isScopyAny = resp.scopeAny
                    Self.logger.info("refreshPSTNInfo \(isAuthorized) \(isScopyAny)")
                    let (showPhoneButton, showGuide) = self.viewModel.tabViewModel.phoneCallConfig(isAuthorized: isAuthorized, isScopyAny: isScopyAny)
                    let isContainPhoneCall = self.headerView.buttons.contains(.phoneCall)

                    self.headerView.isShowGuideView = showGuide

                    if showPhoneButton && !isContainPhoneCall {
                        self.headerView.buttons.append(.phoneCall)
                    } else if !showPhoneButton && isContainPhoneCall {
                        guard let index = self.headerView.buttons.firstIndex(of: .phoneCall) else { return }
                        self.headerView.buttons.remove(at: index)
                    }

                    self.bindViewActions()
                    self.headerView.containerView.reloadData()
                    self.updateLayout(isRegular: self.isRegular)
                case .failure:
                    return
                }
            }
        }
        if viewModel.fg.isTabWebinarEnabled {
        self.viewModel.getSuiteQuota { [weak self] r in
            guard let self = self else {
                return
            }
            var isWebinarEnabled: Bool
            switch r {
            case .success(let rsp):
                isWebinarEnabled = self.viewModel.fg.isTabWebinarEnabled && rsp.webinar
            case .failure:
                isWebinarEnabled = false
            }
            let webinarBtnIndex = self.headerView.buttons.firstIndex(of: .webinarSchedule)
            if !isWebinarEnabled,
               let idx = webinarBtnIndex {
                self.headerView.buttons.remove(at: idx)
            } else if isWebinarEnabled && webinarBtnIndex == nil {
                if self.headerView.buttons.count >= 3 {
                    self.headerView.buttons.insert(.webinarSchedule, at: 3)
                } else {
                    self.headerView.buttons.append(.webinarSchedule)
                }
            } else {
                return
            }

            self.bindViewActions()
            self.headerView.containerView.reloadData()
            self.updateLayout(isRegular: self.isRegular)
        }
        }

    }

    func bindToTabService() {
        TabService.shared.scrollToHistoryID
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] historyID in
                guard let self = self else {
                    return
                }
                if let (indexPath, _) = self.historyDataSource.findHistoryID(historyID) {
                    self.scrollTableToIndex(indexPath, at: .middle, animated: true)
                }
            })
            .disposed(by: rx.disposeBag)
        TabService.shared.openMeetingID
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] meetingID, isFromBot in
                guard let self = self else {
                    return
                }
                self.gotoMeetingDetail(
                    queryID: meetingID,
                    tabListItem: {
                        if isFromBot {
                            return self.historyDataSource.findHistoryID(meetingID)?.1
                        } else {
                            return self.historyDataSource.findMeetingID(meetingID)?.1
                        }
                    }(),
                    source: isFromBot ? .bot : .call
                )
            })
            .disposed(by: rx.disposeBag)
    }

    func gotoMeetingDetail(queryID: String, tabListItem: TabListItem?, source: MeetingDetailViewModel.Source = .unknown) {
        let tabViewModel = self.viewModel.tabViewModel
        let viewModel = MeetingDetailViewModel(tabViewModel: tabViewModel,
                                               queryID: queryID,
                                               tabListItem: tabListItem,
                                               source: source)
        let vc = MeetingDetailViewController(viewModel: viewModel)
        if Display.pad {
            self.presentDynamicModal(vc,
                                     regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                     compactConfig: .init(presentationStyle: .fullScreen, needNavigation: true))
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc
    func tableScrollToTop() {
        // tab scroll to top
        resetContainerViewContentOffset(animated: true)
    }

    @objc
    func searchAction() {
        let host = viewModel.setting.domain(for: .mpApplink).first ?? "applink.feishu.cn"
        let urlString = "https://" + host + "/client/search/open?target=QUICK_JUMP"
        if let url = URL(string: urlString) {
            router?.pushOrPresentURL(url, from: self)
        }
    }

    @objc
    func rightBarButtonAction() {
        MeetTabTracks.trackClickMeetSetting()
        badgeView.isHidden = true
        padNaviBarView.badgeView.isHidden = true
        router?.gotoByteViewSetting(from: self) {
            MeetTabTracks.trackMeetSettingPopup()
        }
    }

    // MARK: - Tabbar protocol
    public override func handleTabbarItemDoubleTap() {
        Self.logger.debug("new VC Tab handleTabbarItemDoubleTap")
        loadDataIfNeeded()
    }

    public override func handleTabbarItemTap(_ isSameTab: Bool) {
        Self.logger.debug("new VC Tab handleTabbarItemTap: \(isSameTab)")
        loadDataIfNeeded()
    }

    override func willSwitchToTabBar() {
        Self.logger.debug("new VC Tab willSwitchToTabBar")
        let isPreLoad = tabResultView.tableView.visibleCells.isEmpty
        viewModel.loadTabData(isPreLoad)
    }

    override func didSwitchToTabBar() {
        Self.logger.debug("new VC Tab didSwitchToTabBar")
    }

    override func willSwitchOutTabBar() {
        Self.logger.debug("new VC Tab willSwitchOutTabBar")
        showNavigationBar(show: true)
    }

    override func didSwitchOutTabBar() {
        Self.logger.debug("new VC Tab didSwitchOutTabBar")
        viewModel.tabViewModel.closeGrootChannel(type: .vcTabListChannel)
    }

    override func clearTabBadgeUnreadCount() {
        clearVideoConferenceTabUnreadCount()
    }

    private func loadDataIfNeeded() {
        if tabResultView.tableView.isHidden {
            viewModel.loadTabData()
        }
    }

    override func didTapSearchButton() {
        viewModel.tabViewModel.router?.gotoSearch(from: self)
    }
}

extension MeetTabViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return Display.pad ? .all : .portrait
    }
}
