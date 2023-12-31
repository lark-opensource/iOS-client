//
//  MinutesHomePageViewController.swift
//  Minutes
//
//  Created by chenlehui on 2021/7/13.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignColor
import LarkUIKit
import EENavigator
import MinutesFoundation
import MinutesNetwork
import MinutesInterface
import UniverseDesignToast
import MinutesNavigator
import Reachability
import AppReciableSDK
import LarkAlertController
import LarkGuideUI
import LarkGuide
import UniverseDesignIcon
import LarkContainer
import LarkAccountInterface
import LarkGuide
import LarkStorage
import LarkSetting
import LarkAppConfig

public final class MinutesHomePageViewController: UIViewController, FilterInfoDelegate, UserResolverWrapper {
    public let userResolver: LarkContainer.UserResolver
    @ScopedProvider var passportUserService: PassportUserService?
    @ScopedProvider var guideService: NewGuideService?
    @ScopedProvider var featureGatingService: FeatureGatingService?

    public lazy var tabSearchButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.searchOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        button.addTarget(self, action: #selector(searchAction), for: .touchUpInside)
        return button
    }()

    private lazy var navigationBar: MinutesHomeNavigationBar = {
        let view = MinutesHomeNavigationBar()
        view.backButton.addTarget(self, action: #selector(backButtonAction), for: .touchUpInside)
        view.moreButton.addTarget(self, action: #selector(moreAction), for: .touchUpInside)
        view.closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        view.zoomButton.addTarget(self, action: #selector(zoomAction(_:)), for: .touchUpInside)
        view.splitButton.addTarget(self, action: #selector(splitAction), for: .touchUpInside)
        view.searchButton.addTarget(self, action: #selector(searchAction), for: .touchUpInside)
        return view
    }()

    private lazy var coverView: MinutesHomeCoverViewController = {
        let cv = MinutesHomeCoverViewController()
        cv.errorView.onClickRefreshButton = { [weak self] in
            self?.showLoading()
            self?.refreshFeed()
        }
        return cv
    }()

    let tableView: UITableView = UITableView(frame: CGRect.zero, style: .plain)

    private lazy var headerView: HeaderView = {
        let hv = HeaderView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 72))
        hv.myButton.addTarget(self, action: #selector(mySpaceAction), for: .touchUpInside)
        hv.shareButton.addTarget(self, action: #selector(shareSpaceAction), for: .touchUpInside)
        return hv
    }()

    public lazy var moreButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.moreOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        button.addTarget(self, action: #selector(moreAction), for: .touchUpInside)
        return button
    }()

    private let tracker = BusinessTracker()
    let viewModel: MinutesSpaceListViewModel

    private let showType: ShowType
    private let fromSource: MinutesHomeFromSource
    private var pageAliveDate = Date()
    private var shouldReportDuration: Bool = true
    private var isFirstLoad = true
    private var shouldScrollToTop = false

    let limitLength = 80 //重命名最大字数
    
    var recordEntranceManager: MinutesRecordEntranceManager?
    public var spaceType: MinutesSpaceType {
        return viewModel.spaceType
    }

    private var list: [MinutesSpaceListItem] {
        return viewModel.feedList?.list ?? []
    }

    var isInDemo: Bool {
        if let plistInfo = Bundle.main.infoDictionary, let displayName = plistInfo["CFBundleName"] as? String, displayName == "Minutes_Example" {
            return true
        } else {
            return false
        }
    }

    public init(resolver: UserResolver, showType: ShowType, spaceType: MinutesSpaceType, fromSource: MinutesHomeFromSource) {
        self.userResolver = resolver
        MinutesListReciableTracker.shared.startEnterList(listType: spaceType.listType)
        self.showType = showType
        self.fromSource = fromSource
        self.viewModel = MinutesSpaceListViewModel(resolver: resolver, spaceType: spaceType)
        super.init(nibName: nil, bundle: nil)
        configViewModel()
        trackerListClick()
        
        trackDev(spaceType: spaceType, isFinished: false, isError: 0)

        MinutesLogger.list.info("minutes home page vc init")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        addSubviews()
        if Display.phone {
            configRecordView()
        }
        addNotifications()
        showLoading()
        MinutesListReciableTracker.shared.finishPreProcess()
        refreshFeed()
        trackerListPageDisplay()

        supportSecondaryOnly = true
        supportSecondaryPanGesture = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            self.showTrashGuideIfNeeded()
        })
    }

    deinit {
        MinutesLogger.list.info("minutes home page vc deinit")
        recordEntranceManager?.popLast()
        NotificationCenter.default.removeObserver(self)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // YYLabel在不重新渲染的情况下，在系统中手动设置dark和light模式时候，无法自动变化
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                tableView.reloadData()
            }
        }
    }
  
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        layoutNavigationBar()
        navigationController?.setNavigationBarHidden(true, animated: false)
        pageAliveDate = Date()
        shouldReportDuration = true
        trackerPageAliveCycle()
        InnoPerfMonitor.shared.entry(scene: .minutesHome)
        InnoPerfMonitor.shared.update(extra: ["spaceType": spaceType.pageName])
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shouldReportDuration = false
        trackerPageAlive()
        InnoPerfMonitor.shared.leave(scene: .minutesHome)
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            self?.layoutNavigationBar()
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
    
    func trackDev(spaceType: MinutesSpaceType, isFinished: Bool, isError: Int, error: ResponseError? = nil) {
        let actionName = isFinished ? "finished" : "entry_page"
        var dict: [String: Any] = [:]
        dict["action_name"] = actionName
        
        switch spaceType {
        case .home:
            dict["page_name"] = "home_page"
        case .my:
            dict["page_name"] = "my_content"
        case .share:
            dict["page_name"] = "shared_with_me"
        case .trash:
            dict["page_name"] = "trash_box"
        }
        dict["is_error"] = isError
        if let code = error?.minutes.code {
            dict["server_error_code"] = "\(code)"
        }
        tracker.tracker(name: .minutesListViewDev, params: dict)
    }
}

// MARK: - private
extension MinutesHomePageViewController {

    private func addSubviews() {
        var offset = 0
        if showType == .navigation {
            navigationBar.isHidden = false
            navigationBar.titleLabel.text = viewModel.spaceType.title
            navigationBar.backButton.isHidden = false
        } else {
            navigationBar.isHidden = true
            offset = Display.pad ? 0 : 16
        }

        view.addSubview(navigationBar)
        navigationBar.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(view.safeAreaLayoutGuide)
            maker.height.equalTo(Display.pad ? 60 : 44)
        }

        createTableView()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.top.equalTo(navigationBar.snp.bottom).offset(offset)
            maker.bottom.equalToSuperview()
            maker.left.right.equalToSuperview()
        }
    }
    
    func createTableView() {
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 84
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
#if swift(>=5.5)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
#endif
        if spaceType == .home {
            tableView.tableHeaderView = headerView
        }
        tableView.es.addPullToRefresh(animator: MinutesRefreshHeaderAnimator(frame: .zero)) { [weak self] in
            self?.refreshFeed()
        }
        tableView.es.addInfiniteScrolling(animator: MinutesRefreshFooterAnimator(frame: .zero)) { [weak self] in
            self?.loadMoreFeed()
        }
    }
    
    private func showCoverView() {
        if self.coverView.parent == nil {
            self.addChild(coverView)
        }
        tableView.insertSubview(coverView.view, at: 0)
        coverView.view.snp.makeConstraints { make in
            make.center.equalTo(tableView)
        }
    }

    private func removeCoverView() {
        coverView.view.removeFromSuperview()
        coverView.removeFromParent()
    }
    
    private func configRecordView() {
        if spaceType == .trash { return }
        if recordEntranceManager == nil {
            MinutesLogger.record.info("create minutes record entrance manager")
            recordEntranceManager = MinutesRecordEntranceManager(resolver: userResolver)
        }
        recordEntranceManager?.appendEntrance(withController: self)
        if let rv = recordEntranceManager?.recordView {
            view.addSubview(rv)
            let offset = showType == .tabbar ? -2 : -30
            rv.snp.makeConstraints { maker in
                maker.width.height.equalTo(96)
                maker.right.equalTo(0)
                maker.bottom.equalTo(view.safeAreaLayoutGuide).offset(offset)
            }
        }
    }

    private func layoutNavigationBar() {
        if spaceType == .home {
            navigationBar.moreButton.isHidden = false
            navigationBar.searchButton.isHidden = false

            let visible = featureGatingService?.staticFeatureGatingValue(with: .minutesSearchVisible) == true
            navigationBar.searchButton.isHidden = !visible
        } else {
            navigationBar.moreButton.isHidden = true
            navigationBar.searchButton.isHidden = true
        }
        if couldCloseScene {
            if navigationController?.viewControllers.first == self {
                navigationBar.backButton.isHidden = true
                navigationBar.closeButton.isHidden = false
            } else {
                navigationBar.backButton.isHidden = false
                navigationBar.closeButton.isHidden = true
            }
        } else {
            navigationBar.backButton.isHidden = false
            navigationBar.closeButton.isHidden = true
        }
        navigationBar.zoomButton.isHidden = !couldZoomInOut
        navigationBar.splitButton.isHidden = !couldOpenInScene
        navigationBar.zoomButton.isSelected = larkSplitViewController?.splitMode == .secondaryOnly
    }

    private func addNotifications() {
        if spaceType == .home {
            NotificationCenter.default.addObserver(self, selector: #selector(switchToHomeNotification), name: Notification.minutesHomeForTab, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(switchToMySpaceNotification), name: Notification.minutesHomeMeForTab, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(switchToShareSpaceNotification), name: Notification.minutesHomeShareForTab, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(switchToTrashSpaceNotification), name: Notification.minutesHomeTrashForTab, object: nil)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func showTrashGuideIfNeeded() {
        guard spaceType == .home else { return }
        guard let guide = guideService else { return }
        var targetView = navigationBar.moreButton
        if showType == .tabbar {
            targetView = moreButton
        }
        let target = TargetAnchor(targetSourceType: .targetView(targetView))
        let text = TextInfoConfig(detail: BundleI18n.Minutes.MMWeb_M_ViewTrashHere_Onboard_Tooltip)
        let config = BubbleItemConfig(guideAnchor: target, textConfig: text)
        guide.showBubbleGuideIfNeeded(guideKey: "vc_minutes_trash_box", bubbleType: .single(.init(bubbleConfig: config))) {
            MinutesLogger.list.info("trash guide has shown.")
        }
    }
}

// MARK: - tip view
extension MinutesHomePageViewController {

    private func showLoading() {
        showCoverView()
        coverView.show(type: .loading)
    }

    private func showEmptyViewIfNeeded() {
        guard list.isEmpty else { return }
        showCoverView()
        coverView.show(type: .empty, spaceType: spaceType, isFilter: viewModel.isFilterIconActived)
    }

    private func showErrorViewIfNeeded() {
        guard list.isEmpty else { return }
        showCoverView()
        coverView.show(type: .error)
    }

    private func hideCoverView() {
        coverView.hide()
        removeCoverView()
    }
}

// MARK: - refresh page
extension MinutesHomePageViewController {

    private func configViewModel() {
        viewModel.successHandler = { [weak self] in
            self?.fetchFeedListSuccessHandler()
        }
        viewModel.failureHandler = { [weak self] error in
            self?.fetchFeedListFailuerHandler(error)
        }
        viewModel.reloadDataOnly = { [weak self] in
            self?.reloadData()
            self?.showEmptyViewIfNeeded()
        }
        viewModel.removeCellSuccess = { [weak self] indexPath in
            self?.removeCellAt(indexPath)
        }
        viewModel.removeCellFailure = { [weak self] indexPath in
            self?.removeCellFailure(indexPath)
        }
    }

    private func refreshFeed() {
        viewModel.refreshFeedList()
    }

    private func loadMoreFeed() {
        viewModel.loadMoreFeedList()
    }

    private func fetchFeedListSuccessHandler() {
        if isFirstLoad {
            MinutesListReciableTracker.shared.finishNetworkReqeust()
            DispatchQueue.main.async {
                MinutesListReciableTracker.shared.endEnterList()
            }
        }
        recordEntranceManager?.showRecordView()
        if let hasMore = viewModel.feedList?.hasMore, !hasMore {
            tableView.es.noticeNoMoreData()
            tableView.es.stopPullToRefresh(ignoreDate: false, ignoreFooter: true)
        } else {
            tableView.es.stopPullToRefresh()
            tableView.es.stopLoadingMore()
        }
        reloadData()
        hideCoverView()
        trackDev(spaceType: spaceType, isFinished: true, isError: 0)
        
        showEmptyViewIfNeeded()
        if isFirstLoad {
            MinutesListReciableTracker.shared.finishDataProcess()
        }
        isFirstLoad = false
        if shouldScrollToTop {
            let indexpath = IndexPath(row: 0, section: 0)
            if tableView.indexPathExists(indexPath: indexpath) {
                tableView.scrollToRow(at: indexpath, at: .top, animated: true)
            }
            shouldScrollToTop = false
        }
    }

    private func fetchFeedListFailuerHandler(_ error: Error?) {
        if isFirstLoad {
            MinutesListReciableTracker.shared.finishNetworkReqeust()
            DispatchQueue.main.async {
                MinutesListReciableTracker.shared.endEnterList()
            }
            isFirstLoad = false
            recordEntranceManager?.showRecordViewIfNeeded()
        }
        tableView.es.stopPullToRefresh()
        tableView.es.stopLoadingMore()
        showErrorViewIfNeeded()
        
        if let error = error as? ResponseError {
            trackDev(spaceType: spaceType, isFinished: true, isError: 1, error: error)
        } else {
            trackDev(spaceType: spaceType, isFinished: true, isError: 1, error: nil)
        }
    }

    private func removeCellAt(_ indexPath: [IndexPath]) {
        tableView.deleteRows(at: indexPath, with: .automatic)
        showEmptyViewIfNeeded()
        if !viewModel.toast.isEmpty {
            UDToast.showTips(with: viewModel.toast, on: view)
        }
    }

    private func removeCellFailure(_ indexPath: [IndexPath]) {
        if !indexPath.isEmpty {
            removeCellAt(indexPath)
        }
    }

    private func reloadData() {
        if spaceType == .trash {
            trashReladData()
        } else {
            tableView.reloadData()
        }
    }

    private func trashReladData() {
        if tableView.isEditing, !viewModel.shouldForceReload {
            return
        }
        tableView.reloadData()
        viewModel.shouldForceReload = false
        if presentedViewController != nil {
            dismiss(animated: true, completion: nil)
        }
    }

    func confirmInfo(filterInfo: FilterInfo) {
        if filterInfo.rankType == viewModel.rankType && filterInfo.ownerType == viewModel.ownerType && filterInfo.schedulerType == viewModel.schedulerType && filterInfo.asc == viewModel.asc && filterInfo.isFilterIconActived == viewModel.isFilterIconActived {
            return
        }
        
        viewModel.schedulerType = filterInfo.schedulerType
        viewModel.rankType = filterInfo.rankType
        viewModel.ownerType = filterInfo.ownerType
        viewModel.isFilterIconActived = filterInfo.isFilterIconActived
        viewModel.asc = filterInfo.asc
        if let hv = tableView.headerView(forSection: 0) as? MinutesHomeSectionHeader {
            hv.config(with: viewModel)
        }
        refreshFeed()
        let rect = tableView.rectForHeader(inSection: 0)
        if tableView.contentOffset.y > rect.minY {
            shouldScrollToTop = true
        }
        
        storeFilter(filterInfo: filterInfo)
    }
    
    func storeFilter(filterInfo: FilterInfo) {
        guard let userId = passportUserService?.user.userID else {
            return
        }
        let store: KVStore = KVStores.udkv(
            space: .user(id: userId),
            domain: Domain.biz.minutes
        )

        var dict: [String: [String: [String: Int]]] = [:]
        if let dictionary: [String: [String: [String: Int]]] = store.value(forKey: PersistenceKey.newKey.rawValue) {
            dict = dictionary
        }

        var config: [String: [String: Int]] = [:]
        if let value = dict[userId] as? [String: [String: Int]] {
            config = value
        }
        let newConfigValue: [String: Int] = [PersistenceKey.schedulerType.rawValue: filterInfo.schedulerType.rawValue,
                     PersistenceKey.rankType.rawValue: filterInfo.rankType.rawValue,
                     PersistenceKey.ownerType.rawValue: filterInfo.ownerType.rawValue,
                                              PersistenceKey.isFilterIconActived.rawValue: filterInfo.isFilterIconActived.intValue,
                                              PersistenceKey.asc.rawValue: filterInfo.asc.intValue]
        config[filterInfo.spaceType.stringValue] = newConfigValue
        dict[userId] = config

        store.set(dict, forKey: PersistenceKey.newKey.rawValue)
        store.synchronize()
    }
}

// MARK: - actions
extension MinutesHomePageViewController {

    @objc private func backButtonAction() {
        if isInSplitDetail, navigationController?.viewControllers.first == self {
            larkSplitViewController?.cleanSecondaryViewController()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func closeAction() {
        exitScene()
    }

    @objc private func zoomAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            larkSplitViewController?.updateSplitMode(.secondaryOnly, animated: true)
        } else {
            larkSplitViewController?.updateSplitMode(.twoBesideSecondary, animated: true)
        }
    }

    @objc private func splitAction() {
        openInScene(localContext: nil, keepLayout: false) { [weak self]  _, _ in
            guard let `self` = self else { return }
            if self.isInSplitDetail, self.navigationController?.viewControllers.count == 1 {
                self.larkSplitViewController?.cleanSecondaryViewController()
                return
            }
            if self.navigationController?.topViewController == self {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.navigationController?.popToViewController(self, animated: false)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    @objc private func searchAction() {
        let host = DomainSettingManager.shared.currentSetting[.mpApplink]?.first ?? "applink.feishu.cn"
        let urlString = "https://" + host + "/client/search/open?target=OPEN_SEARCH&title=%E5%A6%99%E8%AE%B0&commandId=7140143302619480067"
        if let url = URL(string: urlString) {
            userResolver.navigator.open(url, from: self)
        }
    }

    @objc private func switchToHomeNotification() {
        if navigationController?.viewControllers.count == 1 { return }
        navigationController?.popToRootViewController(animated: false)
    }

    @objc private func switchToMySpaceNotification() {
        if let vc = navigationController?.topViewController as? MinutesHomePageViewController, vc.spaceType == .my { return }
        navigationController?.popToRootViewController(animated: false)
        mySpaceAction()
    }

    @objc private func switchToShareSpaceNotification() {
        if let vc = navigationController?.topViewController as? MinutesHomePageViewController, vc.spaceType == .share { return }
        navigationController?.popToRootViewController(animated: false)
        shareSpaceAction()
    }

    @objc private func switchToTrashSpaceNotification() {
        if let vc = navigationController?.topViewController as? MinutesHomePageViewController, vc.spaceType == .trash { return }
        navigationController?.popToRootViewController(animated: false)
        trashSpaceAction()
    }

    @objc private func mySpaceAction() {
        let controller = MinutesHomePageViewController(resolver: userResolver, showType: .navigation, spaceType: .my, fromSource: fromSource)
        controller.recordEntranceManager = recordEntranceManager
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func shareSpaceAction() {
        let controller = MinutesHomePageViewController(resolver: userResolver, showType: .navigation, spaceType: .share, fromSource: fromSource)
        controller.recordEntranceManager = recordEntranceManager
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func trashSpaceAction() {
        let controller = MinutesHomePageViewController(resolver: userResolver, showType: .navigation, spaceType: .trash, fromSource: fromSource)
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func moreAction() {
        let alert = MinutesHomeMoreAlertController()
        alert.completionBlock = { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.trashSpaceAction()
            }
        }
        if traitCollection.horizontalSizeClass == .regular {
            let frame = navigationBar.convert(navigationBar.moreButton.frame, to: view)
            alert.modalPresentationStyle = .popover
            alert.transitioningDelegate = nil
            alert.popoverPresentationController?.sourceRect = navigationBar.moreButton.bounds
            alert.popoverPresentationController?.sourceView = navigationBar.moreButton
            alert.popoverPresentationController?.permittedArrowDirections = .up
            alert.popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
            alert.preferredContentSize = CGSize(width: 132, height: 66)
        }
        present(alert, animated: true)
        trackerMoreActionClick()
        guard let guide = guideService else { return }
        guide.didShowedGuide(guideKey: "vc_minutes_trash_box")
    }

    @objc private func filterAction() {
        let minutesHomeFilterViewController = MinutesHomeFilterViewController(filterInfo: FilterInfo(spaceType: viewModel.spaceType, rankType: viewModel.rankType, ownerType: viewModel.ownerType,schedulerType:viewModel.schedulerType, isFilterIconActived: viewModel.isFilterIconActived, asc: viewModel.asc, isEnabled: viewModel.isEnabled))
        minutesHomeFilterViewController.delegate = self
        if traitCollection.horizontalSizeClass == .regular {
            minutesHomeFilterViewController.isRegular = true
            if let hv = tableView.headerView(forSection: 0) as? MinutesHomeSectionHeader {
                let frame = hv.filterButton.frame
                minutesHomeFilterViewController.modalPresentationStyle = .popover
                minutesHomeFilterViewController.transitioningDelegate = nil
                minutesHomeFilterViewController.popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
                minutesHomeFilterViewController.popoverPresentationController?.sourceView = hv.filterButton
                minutesHomeFilterViewController.popoverPresentationController?.sourceRect = hv.filterButton.bounds
                minutesHomeFilterViewController.popoverPresentationController?.permittedArrowDirections = .up
                minutesHomeFilterViewController.preferredContentSize = CGSize.init(width: 375, height: minutesHomeFilterViewController.viewHeight)
                present(minutesHomeFilterViewController, animated: true)
            }

        } else if traitCollection.horizontalSizeClass == .compact {
            minutesHomeFilterViewController.isRegular = false
            let nav = MinutesHomeFilterNavigationController(rootViewController: minutesHomeFilterViewController )
            userResolver.navigator.present(nav, from: self)
        }
    }

    @objc private func sortAction() {
        let alert = MinutesHomeSortAlertController(filterInfo: FilterInfo(spaceType: viewModel.spaceType, rankType: viewModel.rankType, ownerType: viewModel.ownerType, schedulerType: .none, isFilterIconActived: viewModel.isFilterIconActived, asc: viewModel.asc, isEnabled: viewModel.isEnabled))
        alert.completionBlock = { [weak self] info in
            self?.confirmInfo(filterInfo: info)
        }
        if traitCollection.horizontalSizeClass == .regular {
            if let hv = tableView.headerView(forSection: 0) as? MinutesHomeSectionHeader {
                let frame = hv.sortButton.frame
                alert.modalPresentationStyle = .popover
                alert.popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
                alert.popoverPresentationController?.sourceView = hv
                alert.popoverPresentationController?.sourceRect = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height - 6)
                alert.popoverPresentationController?.permittedArrowDirections = .up
                alert.preferredContentSize = CGSize.init(width: 300, height: alert.regularHeight)
            }
        } else {
            let bottom = view.frame.height - view.safeAreaLayoutGuide.layoutFrame.maxY
            alert.presentationManager.presentedSize = CGSize(width: view.bounds.width, height: alert.height + bottom)
        }
        present(alert, animated: true, completion: nil)
    }

    @objc private func willEnterForeground() {
        reloadData()
    }
}

// MARK: - TableViewDataSource
extension MinutesHomePageViewController: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < list.count else { return UITableViewCell() }
        let item = list[indexPath.row]
        if item.isEncryptKeyDeleted == true {
            return tableView.mins.dequeueReusableCell(with: MinutesHomeInvalidCell.self) { _ in
            }
        } else {
            return tableView.mins.dequeueReusableCell(with: MinutesHomeItemCell.self) { cell in
                cell.userResolver = userResolver
                cell.layoutWidth = view.bounds.width
                cell.config(with: item, spaceType: spaceType, rankType: viewModel.rankType, transProcess: viewModel.minutesTranscribeProcessCenter.localMinutesTranscribDict[item.objectToken]?.current)
            }
        }
    }
}

// MARK: - TableViewDelegate
extension MinutesHomePageViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.mins.dequeueReusableHeaderFooterView(with: MinutesHomeSectionHeader.self) { header in
            header.filterButton.addTarget(self, action: #selector(filterAction), for: .touchUpInside)
            header.sortButton.addTarget(self, action: #selector(sortAction), for: .touchUpInside)
            header.config(with: viewModel)
        }
    }

    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.row < list.count else { return false }
        let item = list[indexPath.row]
        if item.objectStatus == .audioRecording || item.isEncryptKeyDeleted == true {
            return false
        } else {
            return true
        }
    }

    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < list.count else { return nil }
        let item = list[indexPath.row]
        let removeAction = UIContextualAction(style: .destructive, title: BundleI18n.Minutes.MMWeb_G_Shared_Remove_Option) { [weak self] _, _, completion in
            self?.showRemoveAlert(with: item)
            self?.trackerListRemoveClick()
            completion(false)
        }
        removeAction.backgroundColor = UIColor.ud.functionDangerContentDefault
        let renameAction = UIContextualAction(style: .normal, title: BundleI18n.Minutes.MMWeb_G_Rename) { [weak self] _, _, completion in
            self?.showRenameAlert(item: item)
            completion(false)
        }
        renameAction.backgroundColor = UIColor.ud.N400
        let deleteAction = UIContextualAction(style: .destructive, title: BundleI18n.Minutes.MMWeb_G_Delete) { [weak self] _, _, completion in
            self?.showDeleteAlert(item: item, isLeftScrollToDelete: true)
            self?.trackerDeleteMyContentClick()
            completion(false)
        }
        deleteAction.backgroundColor = UIColor.ud.functionDangerContentDefault
        let restoredAction = UIContextualAction(style: .normal, title: BundleI18n.Minutes.MMWeb_G_Trash_Restore_Option) { [weak self] _, _, completion in
            self?.restoreItem(item)
            self?.trackerTrashRestoreClick()
            completion(false)
        }
        restoredAction.backgroundColor = UIColor.ud.N400
        let clearAction = UIContextualAction(style: .destructive, title: BundleI18n.Minutes.MMWeb_G_Trash_DeletePermanently_Option) { [weak self] _, _, completion in
            self?.showClearAlert(item: item)
            self?.trackerTrashClearClick()
            completion(false)
        }
        clearAction.backgroundColor = UIColor.ud.functionDangerContentDefault

        switch spaceType {
        case .home:
            if item.isOwner ?? false {
                return UISwipeActionsConfiguration(actions: [removeAction, renameAction])
            } else {
                return UISwipeActionsConfiguration(actions: [removeAction])
            }
        case .my:
            return UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
        case .share:
            return UISwipeActionsConfiguration(actions: [removeAction])
        case .trash:
            return UISwipeActionsConfiguration(actions: [clearAction, restoredAction])
        }
        return nil
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if spaceType == .trash || indexPath.row >= list.count { return }
        let item = list[indexPath.row]
        if item.isEncryptKeyDeleted == true {
            return
        }
        let listFilter = list.filter {$0.mediaType != .text}
        let tokenList: [URL] = listFilter.map { URL(string: $0.url) ?? MinutesAPI.buildURL(for: $0.objectToken) }
        if !MinutesInfoStatus.status(from: item.objectStatus).isValid {
            MinutesPodcast.shared.stopPodcast()
        }

        if item.objectStatus == .fileCorrupted {
            showCorruptedMinutesAlert(with: item)
            return
        }

        let url = MinutesAPI.buildURL(for: item.objectToken, base: URL(string: item.url))

        if Display.pad {
            if isInDemo { return }
            showDetail(url, from: self)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.viewModel.didOpenMinutes(withIndex: indexPath.row)
            }
            return
        }

        if item.objectStatus == .audioRecording {
            if item.isRecordingDevice == true {
                if let minutes = MinutesAudioRecorder.shared.minutes {
                    let body = MinutesAudioRecordingBody(minutes: minutes, source: .listPage)
                    userResolver.navigator.present(body: body, from: self, prepare: {$0.modalPresentationStyle = .fullScreen})
                }
            } else if let minutes = Minutes(url) {
                let body = MinutesAudioPreviewBody(minutes: minutes, topic: item.topic)
                userResolver.navigator.push(body: body, from: self)
            }
            return
        } else if item.objectType != .recording && item.objectStatus.minutesIsProcessing() {
            return
        }

        let customContext: [String: Any] = [Minutes.podcastTokenListKey: tokenList, Minutes.fromSourceKey: MinutesSource.listPage]
        showDetail(url, context: customContext, from: self)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.viewModel.didOpenMinutes(withIndex: indexPath.row)
        }
        trackerListDetailClick()
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.preLoadFeedList(with: indexPath)
    }
    
    public func showDetail(_ url: URL, context: [String: Any] = [:], forcePush: Bool? = nil, from: UIViewController, completion: EENavigator.Handler? = nil) {
        let navigatable: EENavigator.Navigatable = userResolver.navigator
        if Display.pad {
            let split = from.larkSplitViewController
            if split == nil || isInSplitDetail {
                navigatable.push(url, context: context, from: from, forcePush: nil, animated: true, completion: completion)
            } else {
                navigatable.showDetail(url, context: context, wrap: LkNavigationController.self, from: from, completion: completion)
            }
        } else {
            navigatable.push(url, context: context, from: from, forcePush: nil, animated: true, completion: completion)
        }
    }
}

// MARK: - remove and delete
extension MinutesHomePageViewController {

    private func showCorruptedMinutesAlert(with item: MinutesSpaceListItem) {
        trackerDeleteViewDisplay()
        let isOwner = item.isOwner ?? false
        let alertController: LarkAlertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.Minutes.MMWeb_G_ContentUnavailable, color: UIColor.ud.textTitle, font: UIFont.boldSystemFont(ofSize: 17))
        alertController.setContent(text: BundleI18n.Minutes.MMWeb_G_ContentUnavailableCorruptedFile, color: UIColor.ud.textTitle, font: UIFont.systemFont(ofSize: 17))
        alertController.addSecondaryButton(text: BundleI18n.Minutes.MMWeb_G_Cancel, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            self.trackerDeleteCancelClick()
        })
        alertController.addDestructiveButton(text: BundleI18n.Minutes.MMWeb_G_Delete, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            if isOwner {
                self.viewModel.deleteItems(catchError: true, withObjectTokens: [item.objectToken])
            } else {
                self.viewModel.removeItems(withObjectTokens: [item.objectToken])
            }
            self.trackerDeleteConfirmClick()
        })
        self.present(alertController, animated: true)
    }

    private func showRemoveAlert(with item: MinutesSpaceListItem) {
        let isOwner = item.isOwner ?? false
        trackerRemoveViewDisplay(isOwner: isOwner)
        let alertController: LarkAlertController = LarkAlertController()
        alertController.setTitle(text: spaceType.removeTitle, color: UIColor.ud.textTitle, font: UIFont.boldSystemFont(ofSize: 17))
        let cv = MinutesRemoveContentView()
        if isOwner {
            alertController.setContent(view: cv)
        } else {
            alertController.setContent(text: spaceType.removeText, color: UIColor.ud.textTitle, font: UIFont.systemFont(ofSize: 17), alignment: .left)
        }
        alertController.addSecondaryButton(text: BundleI18n.Minutes.MMWeb_M_Home_SharedRemoveFromAllList_CancelButton, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.trackerRemoveViewCancelClick()
        })
        alertController.addDestructiveButton(text: BundleI18n.Minutes.MMWeb_M_Home_SharedRemoveFromAllList_ConfirmButton, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            let isSelected = cv.isSelected
            if isOwner && isSelected {
                self.viewModel.deleteItems(catchError: true, withObjectTokens: [item.objectToken])
                self.trackerRemoveViewConfirmClick(isOwner: isOwner, isSelected: true)
            } else {
                self.viewModel.removeItems(withObjectTokens: [item.objectToken])
                self.trackerRemoveViewConfirmClick(isOwner: isOwner, isSelected: false)
            }
        })
        self.present(alertController, animated: true)
    }

    private func showDeleteAlert(item: MinutesSpaceListItem, isLeftScrollToDelete: Bool) {
        trackerDeleteViewDisplay()
        let alertController: LarkAlertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.Minutes.MMWeb_G_My_DeleteFileName_PopupTItle, color: UIColor.ud.textTitle, font: UIFont.boldSystemFont(ofSize: 17))
        alertController.setContent(text: BundleI18n.Minutes.MMWeb_G_My_DeleteFileName_PopupText, color: UIColor.ud.textTitle, font: UIFont.systemFont(ofSize: 17), alignment: .left)
        alertController.addSecondaryButton(text: BundleI18n.Minutes.MMWeb_G_My_DeleteFileName_CancelButton, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.trackerDeleteCancelClick()
        })
        alertController.addDestructiveButton(text: BundleI18n.Minutes.MMWeb_G_My_DeleteFileName_DeleteBTN, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.viewModel.deleteItems(catchError: true, withObjectTokens: [item.objectToken])
            self.trackerDeleteConfirmClick()
        })
        self.present(alertController, animated: true)
    }

    private func showClearAlert(item: MinutesSpaceListItem) {
        trackerClearViewDisplay()
        let alertController: LarkAlertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.Minutes.MMWeb_G_Trash_DeleteThisFilePermanently_PopupTitle, color: UIColor.ud.textTitle, font: UIFont.boldSystemFont(ofSize: 17))
        alertController.setContent(text: BundleI18n.Minutes.MMWeb_G_Trash_DeleteThisFilePermanently_PopupText, color: UIColor.ud.textTitle, font: UIFont.systemFont(ofSize: 17), alignment: .left)
        alertController.addSecondaryButton(text: BundleI18n.Minutes.MMWeb_G_Trash_DeleteThisFilePermanently_CancelButton, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.trackerClearCancelClick()
        })
        alertController.addDestructiveButton(text: BundleI18n.Minutes.MMWeb_G_Trash_DeleteThisFilePermanently_DeleteButton, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.viewModel.deleteItems(catchError: true, withObjectTokens: [item.objectToken], isDestroyed: true)
            self.trackerClearConfirmClick()
        })
        self.present(alertController, animated: true)
    }

    private func restoreItem(_ item: MinutesSpaceListItem) {
        viewModel.restoreDeletedItems(withObjectTokens: [item.objectToken])
    }
}

// MARK: - UITextfiled
extension MinutesHomePageViewController: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else {
            return true
        }
        let newLength = text.count + string.count - range.length
        return newLength <= limitLength
    }
}

//MARK: rename
extension MinutesHomePageViewController {

    private func showRenameAlert(item: MinutesSpaceListItem) {
        let alert = UIAlertController(title: BundleI18n.Minutes.MMWeb_G_Rename, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: BundleI18n.Minutes.MMWeb_G_Cancel, style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: BundleI18n.Minutes.MMWeb_G_ConfirmButton, style: .default, handler: { [weak self] (_) in
            if let text = (alert.textFields?.first)?.text, text.isEmpty == false {
                self?.updateMyMinutesFeedItemTopic(item: item, objectToken: item.objectToken, newTopic: text)
            }
        }))
        alert.addTextField { (textField) in
            textField.text = item.topic
            textField.delegate = self
        }
        present(alert, animated: true, completion: nil)
    }

    func updateMyMinutesFeedItemTopic(item: MinutesSpaceListItem, objectToken: String, newTopic: String) {
        if let someMinutes = MinutesPodcast.shared.minutes, someMinutes.objectToken == objectToken {
            MinutesPodcast.shared.minutes?.info.updateTitle(catchError: false, topic: newTopic)
        }
        viewModel.updateItemTitle(catchError: true, objectToken: objectToken, newTopic: newTopic, completionHandler: { [weak self] success, error in
            if success {
                self?.reloadData()
                self?.trackerRenameListFinished(isChange: item.topic == newTopic)
            } else {
                guard let error = error else { return }
                let extra = Extra(isNeedNet: true, category: ["object_token": objectToken])

                MinutesReciableTracker.shared.error(scene: .MinutesList,
                                                    event: .minutes_edit_detail_error,
                                                    userAction: "rename",
                                                    error: error,
                                                    extra: extra)
                self?.trackerRenameListFinished(isChange: false)
            }
        })
    }
}

// MARK: - views
extension MinutesHomePageViewController {

    public enum ShowType {
        case tabbar
        case navigation
    }

    class HeaderView: UIView {

        lazy var myButton: HeaderButton = {
            let btn = HeaderButton()
            btn.iconView.icon.image = BundleResources.Minutes.minutes_home_myspace
            btn.iconView.titleLabel.text = BundleI18n.Minutes.MMWeb_G_MyContent
            return btn
        }()

        lazy var shareButton: HeaderButton = {
            let btn = HeaderButton()
            btn.iconView.icon.image = BundleResources.Minutes.minutes_home_share
            btn.iconView.titleLabel.text = BundleI18n.Minutes.MMWeb_G_SharedContent
            return btn
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = UIColor.ud.bgBase

            addSubview(myButton)
            myButton.snp.makeConstraints { maker in
                maker.top.left.equalToSuperview()
                maker.height.equalTo(64)
                maker.width.equalToSuperview().multipliedBy(0.5)
            }
            addSubview(shareButton)
            shareButton.snp.makeConstraints { maker in
                maker.top.right.equalToSuperview()
                maker.height.equalTo(64)
                maker.left.equalTo(myButton.snp.right)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class HeaderButton: UIControl {
        let iconView = InnerIconView()
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = UIColor.ud.bgBody
            addSubview(iconView)
            iconView.snp.makeConstraints { maker in
                maker.center.equalToSuperview()
                maker.left.greaterThanOrEqualToSuperview().offset(6)
                maker.right.lessThanOrEqualToSuperview().inset(6)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        class InnerIconView: UIView {
            lazy var titleLabel: UILabel = {
                let l = UILabel()
                l.font = .systemFont(ofSize: 14)
                l.textColor = UIColor.ud.textTitle
                return l
            }()

            lazy var icon: UIImageView = {
                let iv = UIImageView()
                return iv
            }()

            override init(frame: CGRect) {
                super.init(frame: frame)
                isUserInteractionEnabled = false
                addSubview(titleLabel)
                addSubview(icon)

                icon.snp.makeConstraints { maker in maker.left.top.bottom.equalToSuperview()
                    maker.centerY.equalTo(titleLabel)
                }
                titleLabel.snp.makeConstraints { maker in
                    maker.left.equalTo(icon.snp.right).offset(8)
                    maker.right.equalToSuperview()
                }
            }

            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
        }
    }
}

// MARK: - Tracker

extension MinutesHomePageViewController {

    func trackerListPageDisplay() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["page_name"] = viewModel.spaceType.pageName
        tracker.tracker(name: .listView, params: trackParams)
    }

    func trackerListClick() {
        if viewModel.spaceType == .home { return }
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["click"] = viewModel.spaceType.pageName
        trackParams["target"] = "vc_minutes_list_view"
        tracker.tracker(name: .listClick, params: trackParams)
    }

    func trackerListRemoveClick() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["click"] = "remove"
        trackParams["target"] = "vc_minutes_remove_view"
        trackParams["page_name"] = viewModel.spaceType.pageName
        trackParams["is_batch"] = "false"
        trackParams["batch_num"] = 1
        tracker.tracker(name: .listClick, params: trackParams)
    }

    func trackerListDetailClick() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["click"] = "object"
        trackParams["target"] = "vc_minutes_detail_view"
        trackParams["page_name"] = viewModel.spaceType.pageName
        tracker.tracker(name: .listClick, params: trackParams)
    }

    func trackerTrashRestoreClick() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["click"] = "restore"
        trackParams["target"] = "vc_minutes_list_view"
        trackParams["page_name"] = "trash_box"
        trackParams["is_batch"] = "false"
        trackParams["batch_num"] = 1
        tracker.tracker(name: .listClick, params: trackParams)
    }

    func trackerTrashClearClick() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["click"] = "delete_permanently"
        trackParams["target"] = "vc_minutes_delete_view"
        trackParams["page_name"] = "trash_box"
        trackParams["is_batch"] = "false"
        trackParams["batch_num"] = 1
        tracker.tracker(name: .listClick, params: trackParams)
    }

    func trackerRemoveViewDisplay(isOwner: Bool) {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["include_original_file"] = "\(isOwner)"
        tracker.tracker(name: .removeView, params: trackParams)
    }

    func trackerRemoveViewConfirmClick(isOwner: Bool, isSelected: Bool) {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["click"] = "remove"
        trackParams["target"] = "vc_minutes_list_view"
        if isOwner {
            trackParams["delete_original_file"] = "\(isSelected)"
        } else {
            trackParams["delete_original_file"] = "none"
        }
        tracker.tracker(name: .removeClick, params: trackParams)
    }

    func trackerRemoveViewCancelClick() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["click"] = "cancel"
        trackParams["target"] = "vc_minutes_list_view"
        tracker.tracker(name: .removeClick, params: trackParams)
    }

    func trackerDeleteMyContentClick() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["click"] = "delete"
        trackParams["target"] = "vc_minutes_delete_view"
        trackParams["page_name"] = "my_content"
        trackParams["is_batch"] = "false"
        trackParams["batch_num"] = 1
        tracker.tracker(name: .listClick, params: trackParams)
    }

    func trackerDeleteViewDisplay() {
        let trackParams: [AnyHashable: Any] = [:]
        tracker.tracker(name: .deleteView, params: trackParams)
    }

    func trackerDeleteConfirmClick() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["click"] = "confirm"
        trackParams["target"] = "vc_minutes_list_view"
        tracker.tracker(name: .deleteClick, params: trackParams)
    }

    func trackerDeleteCancelClick() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["click"] = "cancel"
        trackParams["target"] = "vc_minutes_list_view"
        tracker.tracker(name: .deleteClick, params: trackParams)
    }

    func trackerMoreActionClick() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["click"] = "more"
        trackParams["target"] = "vc_minutes_list_view"
        tracker.tracker(name: .listClick, params: trackParams)
    }

    func trackerClearViewDisplay() {
        let trackParams: [AnyHashable: Any] = [:]
        tracker.tracker(name: .clearView, params: trackParams)
    }

    func trackerClearConfirmClick() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["click"] = "confirm"
        trackParams["target"] = "vc_minutes_list_view"
        tracker.tracker(name: .clearClick, params: trackParams)
    }

    func trackerClearCancelClick() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["click"] = "cancel"
        trackParams["target"] = "vc_minutes_list_view"
        tracker.tracker(name: .clearClick, params: trackParams)
    }

    func trackerRenameListFinished(isChange: Bool) {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["click"] = "header_title_edit"
        trackParams["target"] = "none"
        trackParams["is_change"] = "\(isChange)"
        trackParams["page_name"] = viewModel.spaceType.pageName
        tracker.tracker(name: .listClick, params: trackParams)
    }

    func trackerListPageDelete() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams.append(.delete)
        tracker.tracker(name: .listPage, params: trackParams)
    }

    func trackerStartRecording() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams.append(.startRecording)
        tracker.tracker(name: .listPage, params: trackParams)
    }

    func trackerPageAlive() {
        let now = Date()
        let duration = now.timeIntervalSince(pageAliveDate)
        pageAliveDate = now
        let trackParams: [AnyHashable: Any] = ["url": "https://bytedance.feishu.cn/minutes/\(spaceType.urlType)",
                                               "duration": Int(duration * 1000),
                                               "page_name": spaceType.pageName]
        tracker.tracker(name: .pageAlive, params: trackParams)
    }

    func trackerPageAliveCycle() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
            guard let `self` = self, self.shouldReportDuration else { return }
            self.trackerPageAlive()
            self.trackerPageAliveCycle()
        }
    }
}

public extension Notification {
    static let minutesHomeMeForTab = Notification.Name("Tab.minutes.home.me")
    static let minutesHomeShareForTab = Notification.Name("Tab.minutes.home.share")
    static let minutesHomeTrashForTab = Notification.Name("Tab.minutes.home.trash")
    static let minutesHomeForTab = Notification.Name("Tab.minutes.home")
}
