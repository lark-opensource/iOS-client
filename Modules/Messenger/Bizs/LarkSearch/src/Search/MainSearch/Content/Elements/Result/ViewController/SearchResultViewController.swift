//
//  SearchResultController.swift
//  LarkSearch
//
//  Created by Patrick on 2022/5/19.
//

import UIKit
import Foundation
import LarkCore
import LarkSceneManager
import RxSwift
import LarkKeyCommandKit
import LarkStorage
import LarkSearchCore
import LarkSDKInterface
import LarkUIKit
import LKCommonsLogging
import EENavigator
import UniverseDesignIcon
import LarkContainer
import LarkAccountInterface
import SuiteAppConfig
import LarkPerf
import RustPB
import LarkMessengerInterface

protocol SearchResultViewModelFactory {
    func makeSearchResultViewModel() -> SearchResultViewModel
}

enum SearchResultViewState {
    case empty
    case loading
    case reloadData(Bool)
    case noResult(String, Bool)
    case noResultForYear(String, Bool)
    case spotlight(SpotlightState)
    case quotaExceed(Search_V2_SearchCommonResponseHeader.ErrorInfo)

    //spotlight搜索出现错误或空，在业务下层处理，状态不会抛到这里
    public enum SpotlightState {
        case spotlightFinishLoading     // spotlight搜索结束到网络搜索结束前到loading态
        case spotlightFinishSearchError //  spotlight搜索结束后网络搜索出现错误
    }
}

final class SearchResultViewController: NiblessViewController, MoreTableViewKeyBoardFocusHandler, UserResolverWrapper {
    static let logger = Logger.log(SearchResultViewController.self, category: "Module.IM.Search")
    let viewModel: SearchResultViewModel
    weak var container: UIViewController?
    private let disposeBag = DisposeBag()
    private var showTipCell: UITableViewCell?
    lazy var searchOuterService: SearchOuterService? = {
        let service = try? self.userResolver.resolve(assert: SearchOuterService.self)
        return service
    }()

    private lazy var resultView: SearchResultView = {
        let view = SearchResultView()
        view.tableview.dataSource = self
        view.tableview.delegate = self
        if SceneManager.shared.supportsMultipleScenes {
            view.tableview.dragDelegate = self
        }
        view.tableview.estimatedRowHeight = 67
        view.tableview.showsVerticalScrollIndicator = false
        view.tableview.rowHeight = UITableView.automaticDimension
        if viewModel.autoHideFilterEnabled {
            view.tableview.tag = SearchScrollView.scrollGestureSimultaneousTag
        }
        activityIndicatorView?.hidesWhenStopped = true
        activityIndicatorView?.frame = CGRect(x: 0, y: 0, width: view.tableview.bounds.width, height: 44)
        view.tableview.tableFooterView = activityIndicatorView
        return view
    }()

    private lazy var skeletonLoadingView: SearchResultSkeletonLoadingView = {
        let view = SearchResultSkeletonLoadingView(frame: .zero, userResolver: self.userResolver)
        view.setHidden(isHidden: true)
        return view
    }()

    var lowNetBannerHidden: Bool {
        return lowNetworkBanner.isHidden
    }

    var fullDivisionBtnHidden: Bool {
        return fullNameOfDivisionBanner.isHidden
    }
    private lazy var lowNetworkBanner: SearchLowNetworkBanner = {
        let param = SearchLowNetworkBanner.Param(title: BundleI18n.LarkSearch.Lark_ASLSearch_WeakNetworkNotice_InternetErrorLimitedSearch_NoticeMobile,
                                                 actionText: BundleI18n.LarkSearch.Lark_ASLSearch_WeakNetworkNotice_InternetErrorLimitedSearch_RetryMobile,
                                                 icon: UDIcon.cloudFailedOutlined.ud.withTintColor(.ud.iconN2),
                                                 showDivider: viewModel.tabType == .topResults ? true : false,
                                                 contentAlignmentType: viewModel.tabType == .topResults ? .bottom : .center,
                                                 showTopCorner: true)
        let view = SearchLowNetworkBanner(param: param)
        view.didTapHeader = { [weak self] in
            self?.viewModel.retrySearch()
        }
        view.isHidden = true
        return view
    }()

    private lazy var fullNameOfDivisionBanner: SearchDivisionFoldBanner = {
        let param = SearchDivisionFoldBanner.Param(title: BundleI18n.LarkSearch.Lark_Legacy_Contact,
                                                   actionText: BundleI18n.LarkSearch.Lark_ASLSearch_Contacts_ShowFullDepartment_Button,
                                                 icon: UDIcon.addnewOutlined.ud.withTintColor(.ud.iconN2))
        let view = SearchDivisionFoldBanner(param: param)
        view.didTapHeader = { [weak self] in
            self?.handleFullNameOfDivision()
        }
        view.isHidden = true
        return view
    }()

    private lazy var spotlightStatusView: SearchSpotlightStatusView = {
        let view = SearchSpotlightStatusView(userResolver: self.userResolver)
        view.didTapView = { [weak self] in
            self?.viewModel.retrySearch()
        }
        return view
    }()

    #if DEBUG || INHOUSE || ALPHA
    // debug悬浮按钮
    private let debugButton: ASLFloatingDebugButton = ASLFloatingDebugButton()
    #endif

    /// 点击展示更多数据时候加载动画
    var activityIndicatorView: UIActivityIndicatorView?
    let userResolver: UserResolver
    // MARK: - 生命周期
    init(userResolver: UserResolver, viewModel: SearchResultViewModel) {
        self.userResolver = userResolver
        self.viewModel = viewModel

        if #available(iOS 13.0, *) {
            self.activityIndicatorView = UIActivityIndicatorView(style: .medium)
        }
        super.init()
        resultView.containerVC = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupSubscriptions()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
            self.viewModel.resultViewWidth = {
                return size.width
            }
            self.resultView.tableview.reloadData()
            self.view.setNeedsLayout()
        })
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        skeletonLoadingView.updateDarkLightMode()
    }

    private(set) var bannerHeight: CGFloat?
    // 展示部门/折叠部门 的吸顶栏高度
    private(set) var divisionBannerHeight: CGFloat?

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bannerHeight = lowNetworkBanner.frame.height
        divisionBannerHeight = fullNameOfDivisionBanner.frame.height
        resultView.tableview.separatorStyle = .none
        var bottomInset = 0
        if case .topResults = viewModel.config.tabType, SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled {
            bottomInset = 20
        }
        resultView.tableview.contentInset = UIEdgeInsets(top: CGFloat(viewModel.tableViewTopOffset()), left: 0, bottom: CGFloat(bottomInset), right: 0)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let service = searchOuterService, service.enableUseNewSearchEntranceOnPad() {
            if !service.isCompactStatus() {
                resultView.tableview.snp.updateConstraints { make in
                    make.right.left.equalToSuperview().inset(0)
                }
                let isShowCapsule = SearchFeatureGatingKey.enableIntensionCapsule.isUserEnabled(userResolver: userResolver) && !AppConfigManager.shared.leanModeIsOn
                if !isShowCapsule {
                    view.backgroundColor = UIColor.ud.bgBody
                    resultView.backgroundColor = viewModel.resultViewBackgroundColor
                } else {
                    view.backgroundColor = UIColor.ud.bgBase
                    resultView.backgroundColor = UIColor.ud.bgBase
                }
            } else {
                if let resultTableViewHorizontalPadding = viewModel.resultTableViewHorzontalPadding {
                    resultView.tableview.snp.updateConstraints { make in
                        make.right.left.equalToSuperview().inset(resultTableViewHorizontalPadding)
                    }
                }
                view.backgroundColor = UIColor.ud.bgBody
                resultView.backgroundColor = viewModel.resultViewBackgroundColor
            }
        }
    }

    // MAKR: - Setup
    private func setupViews() {
        view.backgroundColor = UIColor.ud.bgBody
        resultView.backgroundColor = viewModel.resultViewBackgroundColor
        // track FPS
        resultView.tableview.trackFps(location: viewModel.config.searchLocation, disposeBag: disposeBag)

        view.addSubview(resultView)
        resultView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        if case .topResults = viewModel.config.tabType, SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled {
            resultView.tableview.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        }

        if let resultTableViewHorizontalPadding = viewModel.resultTableViewHorzontalPadding {
            var tableViewHorizontalPadding = resultTableViewHorizontalPadding
            if let service = searchOuterService, service.enableUseNewSearchEntranceOnPad(), !service.isCompactStatus() {
                tableViewHorizontalPadding = 0
            }
            resultView.tableview.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.right.left.equalToSuperview().inset(tableViewHorizontalPadding)
            }
        }

        view.addSubview(lowNetworkBanner)
        lowNetworkBanner.snp.makeConstraints { [weak self] make in
            guard let self = self else { return }
            let topPadding = self.viewModel.tabType == .topResults ? 8 : 0
            make.top.equalToSuperview().inset(topPadding)
            make.left.right.equalToSuperview().inset(self.viewModel.resultTableViewHorzontalPadding ?? 0)
        }

        view.addSubview(fullNameOfDivisionBanner)
        fullNameOfDivisionBanner.snp.makeConstraints { [weak self] make in
            guard let self = self else { return }
            make.top.equalToSuperview()
            make.left.right.equalToSuperview().inset(self.viewModel.resultTableViewHorzontalPadding ?? 0)
        }

        if viewModel.feedbackEnabled {
            resultFixedFeedBackView.frame.size.height = resultFixedFeedBackView.fixedHeight
            resultFixedFeedBackView.layer.cornerRadius = 8.0
            resultView.tableview.tableFooterView = resultFixedFeedBackView
        }

        if SearchFeatureGatingKey.enableIntensionCapsule.isUserEnabled(userResolver: userResolver) && !AppConfigManager.shared.leanModeIsOn {
            view.addSubview(skeletonLoadingView)
            skeletonLoadingView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        registerCells()
        setEmptyState()
        addBottomLoadMoreView()
        setupDebugButtonIfNeeded()
    }

    private func setupDebugButtonIfNeeded() {
    #if DEBUG || INHOUSE || ALPHA
        // 初始化时读取默认状态
        self.debugButton.isHidden = !KVStores.SearchDebug.globalStore[KVKeys.SearchDebug.contextIdShow]
        // 之后通过通知传值
        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(switchDebugButton(_:)),
                         name: NSNotification.Name(KVKeys.SearchDebug.contextIdShow.raw),
                         object: nil)
        resultView.addSubview(debugButton)
        debugButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(8)
        }
        viewModel.contextID
            .drive(onNext: { [weak self] aslContextID in
                self?.debugButton.updateTitle(ContextID: aslContextID)
            }).disposed(by: disposeBag)
    #endif
    }

    #if DEBUG || INHOUSE || ALPHA
    @objc
    private func switchDebugButton(_ notification: Notification) {
        if let isOn = notification.userInfo?["isOn"] as? Bool {
            self.debugButton.isHidden = !isOn
        }
    }
    #endif

    private func addBottomLoadMoreView() {
        if viewModel.supportLoadMore {
            resultView.tableview.addBottomLoadMoreView { [weak self] in
                self?.viewModel.loadMore()
            }
        }
    }

    private func registerCells() {
        for headerType in viewModel.headerTypes {
            resultView.tableview.register(headerType, forHeaderFooterViewReuseIdentifier: headerType.identifier)
        }
        for footerType in viewModel.footerTypes {
            resultView.tableview.register(footerType, forHeaderFooterViewReuseIdentifier: footerType.identifier)
        }
    }

    private func setupSubscriptions() {
        setupSubscriptionsForSearchResultViewState()

        if viewModel.supportLoadMore {
            viewModel.shouldAddBottomLoadMore
                .drive(onNext: { [weak self] shouldAddBottomLoadMore in
                    guard shouldAddBottomLoadMore else { return }
                    self?.addBottomLoadMoreView()
                })
                .disposed(by: disposeBag)
        }

        setupSubscriptionsForShouldShowLowNetworkBanner()

        viewModel.shouldShowDivisionBtn
            .drive(onNext: { [weak self] shouldshowDivisionBtn in
                self?.fullNameOfDivisionBanner.isHidden = !shouldshowDivisionBtn
            })
            .disposed(by: disposeBag)
        viewModel.resultViewWidth = { [weak self] in
            return self?.resultView.bounds.width
        }

        viewModel.currentTableView = { [weak self] in
            return self?.resultView.tableview
        }
        viewModel.bannerHeight = { [weak self] in
            return self?.bannerHeight
        }
        viewModel.divisionBannerHeight = { [weak self] in
            return self?.divisionBannerHeight
        }
        viewModel.shouldReconfigRows
            .drive(onNext: { [weak self] indexPath in
                guard let self = self, let indexPath = indexPath else { return }
//                if #available(iOS 15.0, *), indexPath.section < self.viewModel.numberOfSections, indexPath.row < self.viewModel.numberOfRows(in: indexPath.section) {
//                    self.resultView.tableview.reconfigureRows(at: [indexPath])
//                } else {
//                    self.resultView.tableview.reloadData()
//                }
                // 上面写法有crash，谨慎判断
                if indexPath.section < self.resultView.tableview.numberOfSections, indexPath.row < self.resultView.tableview.numberOfRows(inSection: indexPath.section) {
                    if self.resultView.tableview.cellForRow(at: indexPath) as? SearchCardTableViewCell != nil {
                        self.resultView.tableview.beginUpdates()
                        self.resultView.tableview.endUpdates()
                    }
                }
            })
            .disposed(by: disposeBag)
        viewModel.shouldReloadData
            .drive(onNext: { [weak self] shouldReloadData in
                guard let self = self, shouldReloadData else { return }
                self.resultView.tableview.reloadData()
            })
            .disposed(by: disposeBag)

        viewModel.goToTableViewContentOffset
            .drive(onNext: { [weak self] offSetInfo in
                guard let self = self, let (offset, animated) = offSetInfo else { return }
                self.resultView.tableview.setContentOffset(offset, animated: animated)
            })
            .disposed(by: disposeBag)

        if viewModel.feedbackEnabled {
            viewModel.showFixedFeedBackViewIfNeeded
                .drive(onNext: { [weak self] showFixedFeedBackViewIfNeeded in
                    guard let self = self, showFixedFeedBackViewIfNeeded else { return }
                    self.showFixedFeedBackViewIfNeeded()
                })
                .disposed(by: disposeBag)
            viewModel.shouldHideFloatFeedBackView
                .drive(onNext: { [weak self] shouldHideFloatFeedBackView in
                    guard let self = self, shouldHideFloatFeedBackView else { return }
                    self.floatFeedBackView.hide(animated: false)
                })
                .disposed(by: disposeBag)
        }
    }

    private func setupSubscriptionsForSearchResultViewState() {
        viewModel.searchResultViewState
            .drive(onNext: { [weak self] state in
                guard let self = self else { return }
                self.noResultFeedBackView?.hide(animated: false)
                self.updateDivisionBannerUI()
                self.updateTableViewTableFooterViewWith(state: nil)
                if SearchFeatureGatingKey.enableIntensionCapsule.isUserEnabled(userResolver: self.userResolver) && !AppConfigManager.shared.leanModeIsOn {
                    self.skeletonLoadingView.setHidden(isHidden: true)
                }
                switch state {
                case .empty:
                    self.setEmptyState()
                case .loading:
                    if SearchFeatureGatingKey.enableIntensionCapsule.isUserEnabled(userResolver: self.userResolver) && !AppConfigManager.shared.leanModeIsOn {
                        self.skeletonLoadingView.setHidden(isHidden: false)
                    }
                    self.resultView.status = .loading
                case let .reloadData(endBottomLoadMore):
                    if SearchFeatureGatingKey.enableIntensionCapsule.isUserEnabled(userResolver: self.userResolver) && !AppConfigManager.shared.leanModeIsOn {
                        self.skeletonLoadingView.setHidden(isHidden: true, animated: true)
                    }
                    self.resultView.status = .result
                    self.resultView.tableview.reloadData()
                    if endBottomLoadMore == true {
                        self.viewModel.shouldAddBottomLoadMoreSubject.onNext(true)
                    }
                    self.resultView.tableview.endBottomLoadMore(hasMore: endBottomLoadMore)
                    self.activityIndicatorView?.stopAnimating()
                case let .noResult(text, endBottomLoadMore):
                    self.resultView.status = .noResult(text)
                    self.resultView.tableview.endBottomLoadMore(hasMore: endBottomLoadMore)
                    self.activityIndicatorView?.stopAnimating()
                    self.noResultFeedBackView?.show(in: self.container?.view ?? self.view)
                case let .noResultForYear(text, endBottomLoadMore):
                    self.resultView.status = .noResultForAYear(text)
                    self.activityIndicatorView?.stopAnimating()
                    self.resultView.tableview.endBottomLoadMore(hasMore: endBottomLoadMore)
                    self.noResultFeedBackView?.show(in: self.container?.view ?? self.view)
                case let .spotlight(spotlightState):
                    switch spotlightState {
                    case .spotlightFinishLoading:
                        self.resultView.status = .spotlightStatus(.spotlightFinishLoading)
                        self.updateTableViewTableFooterViewWith(state: .spotlightFinishLoading)
                        if SearchFeatureGatingKey.enableIntensionCapsule.isUserEnabled(userResolver: self.userResolver) && !AppConfigManager.shared.leanModeIsOn {
                            self.skeletonLoadingView.setHidden(isHidden: true, animated: true)
                        }
                    case .spotlightFinishSearchError:
                        self.resultView.status = .spotlightStatus(.spotlightFinishSearchError)
                        self.updateTableViewTableFooterViewWith(state: .spotlightFinishSearchError)
                        if SearchFeatureGatingKey.enableIntensionCapsule.isUserEnabled(userResolver: self.userResolver) && !AppConfigManager.shared.leanModeIsOn {
                            self.skeletonLoadingView.setHidden(isHidden: true)
                        }
                    }
                    self.resultView.tableview.reloadData()
                    self.resultView.tableview.endBottomLoadMore(hasMore: false)
                    self.activityIndicatorView?.stopAnimating()
                case let .quotaExceed(errorInfo):
                    self.resultView.status = .quotaExceed(errorInfo)
                    self.resultView.tableview.reloadData()
                    self.resultView.tableview.endBottomLoadMore(hasMore: false)
                    self.activityIndicatorView?.stopAnimating()
                }
            })
            .disposed(by: disposeBag)
    }

    private func setupSubscriptionsForShouldShowLowNetworkBanner() {
        viewModel.shouldShowLowNetworkBanner
            .drive(onNext: { [weak self] shouldShowLowNetworkBanner in
                guard let self = self else { return }
                if shouldShowLowNetworkBanner {
                    self.resultView.tableview.roundCorners(corners: [.topLeft, .topRight], radius: 8.0)
                    if let resultTableViewHorizontalPadding = self.viewModel.resultTableViewHorzontalPadding {
                        var tableViewHorizontalPadding = resultTableViewHorizontalPadding
                        if let service = searchOuterService, service.enableUseNewSearchEntranceOnPad(), !service.isCompactStatus() {
                            tableViewHorizontalPadding = 0
                        }
                        self.resultView.tableview.snp.remakeConstraints { make in
                            make.top.equalToSuperview().inset(8)
                            make.bottom.equalToSuperview()
                            make.right.left.equalToSuperview().inset(tableViewHorizontalPadding)
                        }
                    }
                } else {
                    self.resultView.tableview.roundCorners(corners: [], radius: 0)
                    if let resultTableViewHorizontalPadding = self.viewModel.resultTableViewHorzontalPadding {
                        var tableViewHorizontalPadding = resultTableViewHorizontalPadding
                        if let service = searchOuterService, service.enableUseNewSearchEntranceOnPad(), !service.isCompactStatus() {
                            tableViewHorizontalPadding = 0
                        }
                        self.resultView.tableview.snp.remakeConstraints { make in
                            make.top.bottom.equalToSuperview()
                            make.right.left.equalToSuperview().inset(tableViewHorizontalPadding)
                        }
                    }
                }
                self.lowNetworkBanner.isHidden = !shouldShowLowNetworkBanner
            })
            .disposed(by: disposeBag)
    }
    private func setEmptyState() {
        if case let .placeholder(emptyTitle, emptyPlaceholderImage) = viewModel.config.emptyDiplayState {
            resultView.status = .empty(emptyTitle, emptyPlaceholderImage)
        }
    }

    // MARK: - tableView.tableFooterView update
    private func updateTableViewTableFooterViewWith(state: SearchResultViewState.SpotlightState?) {
        if let spotlightState = state {
            self.spotlightStatusView.frame = CGRect(x: 0, y: 0, width: self.resultView.tableview.bounds.width, height: 48)
            self.resultView.tableview.tableFooterView = self.spotlightStatusView
            if spotlightState == .spotlightFinishLoading {
                self.spotlightStatusView.updateStatus(.spotlightFinishLoading)
            } else if spotlightState == .spotlightFinishSearchError {
                self.spotlightStatusView.updateStatus(.spotlightFinishSearchError)
            }
        } else if self.viewModel.config.supportFeedback {
            self.resultView.tableview.tableFooterView = self.resultFixedFeedBackView
        } else {
            self.resultView.tableview.tableFooterView = self.activityIndicatorView
        }
    }

    // MARK: - Feedback
    /// 反馈view有多个入口... 都加上
    private lazy var noResultFeedBackView = { () -> SearchFeedTipView? in
        guard viewModel.feedbackEnabled else { return nil }
        return makeFeedBackView(false)
    }()
    private lazy var resultFixedFeedBackView = makeFeedBackView(true)
    private lazy var floatFeedBackView = makeFeedBackView(false)
    private func makeFeedBackView(_ isCenter: Bool) -> SearchFeedTipView {
        let v = SearchFeedTipView()
        if isCenter {
            v.tipLabel.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        } else {
            v.smallShadow(.up)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(jumpToFeedBack(_:)))
        v.addGestureRecognizer(tap)
        return v
    }
    private func showFloatFeedBackView() {
        guard self.resultView.tableview.tableFooterView == self.resultFixedFeedBackView else { return }
        guard viewModel.feedbackEnabled else { return }
        // 一次搜索只弹出一次提示
        viewModel.showFloatFeedBackView()
        resultFixedFeedBackView.alpha = 0
        floatFeedBackView.show(in: container?.view ?? view, animated: true, autoHide: 5) { [weak self] in
            self?.showFixedFeedBackViewIfNeeded()
        }
    }
    private func showFixedFeedBackViewIfNeeded() {
        guard viewModel.feedbackEnabled else { return }
        guard floatFeedBackView.state != .show else { return } // 防止 float 和 fixed 同时出现
        UIView.animate(withDuration: 0.25) {
            self.resultFixedFeedBackView.alpha = 1
        }
    }
    @objc
    private func jumpToFeedBack(_ sender: UIGestureRecognizer) {
        let entrance: String
        if sender.view == floatFeedBackView {
            entrance = "swipe"
        } else if sender.view == resultFixedFeedBackView {
            entrance = "below"
        } else {
            entrance = "no_results"
        }
        viewModel.feedbackStat(isSend: false, entrance: entrance)

        let vc = SearchFeedBackViewController(userResolver: userResolver, context: FeedbackContext(delegate: viewModel, entrance: entrance))
        navigator.present(
            vc, wrap: LkNavigationController.self, from: self,
            prepare: {
                $0.transitioningDelegate = vc
                $0.modalPresentationStyle = .custom
            },
            animated: true)
    }

    // MARK: - ScrollDelegate
    /// if user scroll after page load
    var onScreenType = OnScreenItemManager.Action.refresh
    var lastestOffsetY: CGFloat = 0
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        if scrollView == self.resultView.tableview {
            // 只有在 banner 出现的时候才会有 disable scroll 的情况
            if !lowNetBannerHidden {
                if offset <= CGFloat(0.0) {
                    scrollView.contentOffset.y = 0
                }
            }

            if offset <= CGFloat(0.0) {
                viewModel.changeFilterStyle(.dark)
            } else {
                viewModel.changeFilterStyle(.light)
            }
            onScreenType = .scroll

            guard SearchFeatureGatingKey.searchFeedback.isEnabled else { return }

            let y = scrollView.contentOffset.y
            defer { lastestOffsetY = y }

            if viewModel.canUpdateFeedbackVisibility {
                SearchFeedTipView.updateVisiblily(
                    in: scrollView, from: lastestOffsetY, to: y,
                    show: { showFloatFeedBackView() },
                    current: floatFeedBackView) { [weak self] in
                    self?.showFixedFeedBackViewIfNeeded()
                }
            }
        }
    }
    private let chatSearchScrollFPS = "chatSearchScrollFPS"
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard SearchTrackUtil.enablePostTrack() else { return }
        FPSMonitorHelper.shared.startTrackFPS(task: chatSearchScrollFPS, bind: self) { (result) in
            if result.fps <= 0 { return }
            var categoryParams: [String: Any] = ["tab_name": self.viewModel.config.tab.trackRepresentation]
            if case.open(let info) = self.viewModel.config.tab {
                categoryParams["search_app_id"] = info.id
            }
            if let lastRequestInfo = self.viewModel.lastRequestInfo {
                categoryParams["is_spotlight"] = lastRequestInfo.spotlightStatus == .spotlightResult || lastRequestInfo.spotlightStatus == .spotlightResultEmpty
                categoryParams["is_load_more"] = lastRequestInfo.isLoadMore
            }
            SearchTrackUtil.trackForStableWatcher(domain: "asl_general_search",
                                                  message: "asl_search_fps",
                                                  metricParams: ["fps": ceil(result.fps)],
                                                  categoryParams: categoryParams)
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard SearchTrackUtil.enablePostTrack() != false else { return }
        FPSMonitorHelper.shared.endTrackFPS(task: chatSearchScrollFPS, bind: self)
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard SearchTrackUtil.enablePostTrack() != false else { return }
        FPSMonitorHelper.shared.endTrackFPS(task: chatSearchScrollFPS, bind: self)
    }
    // MARK: - KeyBinding
    override func keyBindings() -> [KeyBindingWraper] { return super.keyBindings() + focusChangeKeyBinding() }
    func canFocus(info: TableFocusInfo) -> Bool { !resultView.isHidden && !kbTableView.isHidden }
    func canHandleKeyBoard(in responder: UIResponder) -> Bool {
        var enableCapsuleHandleKeyBoardFG = !SearchFeatureGatingKey.disableCapsuleSupportKeyboard.isUserEnabled(userResolver: self.userResolver)
        for next in Search.UIResponderIterator(start: responder) where next == self || next is SearchRootViewController || (enableCapsuleHandleKeyBoardFG && (next is SearchMainRootViewController)) {
            return true
        }
        return false
    }

    // MARK: KeyBoard Focus Handle
    var _currentKBFocus: FocusInfo?
    var kbTableView: UITableView { resultView.tableview }
    func showMore(section: Int) -> Bool {
        return viewModel.showMore(section: section)
    }
    func jumpMore(section: Int) {
        viewModel.jumpMore(section: section)
    }

    func handleFullNameOfDivision() {

        let actionType = viewModel.divisionInFoldStatus ? "department_unfold" : "department_fold"
        var isCache: Bool?
        if let service = searchOuterService, service.enableUseNewSearchEntranceOnPad() {
            isCache = service.currentIsCacheVC()
        }
        SearchTrackUtil.trackFullDivisionClick(query: viewModel.lastInput?.query ?? "", actionType: actionType, imprID: viewModel.currentCapturedSession?.imprID ?? "", isCache: isCache)

        viewModel.divisionInFoldStatus = !viewModel.divisionInFoldStatus
        updateDivisionBannerUI()
        self.resultView.tableview.reloadData()
    }
    func updateDivisionBannerUI() {
        if viewModel.divisionInFoldStatus {
            self.fullNameOfDivisionBanner.updateBannerUI(
                newIcon: UDIcon.addnewOutlined.ud.withTintColor(.ud.iconN2),
                newActionText: BundleI18n.LarkSearch.Lark_ASLSearch_Contacts_ShowFullDepartment_Button
            )
        } else {
            self.fullNameOfDivisionBanner.updateBannerUI(
                newIcon: UDIcon.noOutlined.ud.withTintColor(.ud.iconN2),
                newActionText: BundleI18n.LarkSearch.Lark_ASLSearch_Contacts_HideFullDepartment_Button
            )
        }
    }
}

extension SearchResultViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - UITableViewDataSource & UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /// 处理提示信息
        if viewModel.isSearchTipCell(forIndexPath: indexPath) == true {
            guard let tipVM = viewModel.cellViewModel(forIndexPath: indexPath) as? SearchTipViewModel else {
                return ShowAllColdDataTipCell()
            }
            if tipVM.showHotTip {
                let cell = ShowAllHotDataTipCell()
                cell.updateView(model: tipVM)
                return cell
            } else if let errorInfo = tipVM.errorInfo {
                let cell = ShowTipCell()
                cell.updateView(model: tipVM,
                                btnTappedAction: {[weak self] in
                                    self?.requestForQuota(isNeedLoadingPage: false)
                })
                self.showTipCell = cell
                return cell
            } else {
                let cell = ShowAllColdDataTipCell()
                cell.updateView(model: tipVM)
                return cell
            }
        }
        guard let cellType = viewModel.cellType(forIndexPath: indexPath) else { return UITableViewCell() }
        guard let cellViewModel = viewModel.cellViewModel(forIndexPath: indexPath) else {
            return UITableViewCell()
        }
        var identifier = cellType.identifier
        if let customCardVM = cellViewModel as? StoreCardSearchViewModel,
            case let .customization(meta) = cellViewModel.searchResult.meta {
            identifier += meta.templateName
        }

        if viewModel.registeredCellTypes.insert(identifier).inserted {
            tableView.register(cellType, forCellReuseIdentifier: identifier)
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? SearchTableViewCellProtocol else {
            assertionFailure("Search cell type error")
            return UITableViewCell()
        }

        // Block cell 需要缓存下来
        if let blockCell = viewModel.makeAndCacheBlockCell(cellViewModel: cellViewModel, indexPath: indexPath) {
            return blockCell
        }

        if let cardCell = cell as? SearchCardTableViewCell {
            cardCell.analysisParams = [
                "session_id": viewModel.currentCapturedSession?.session ?? "",
                "query": SearchTrackUtil.encrypt(id: viewModel.lastInput?.query ?? ""), // lynx上报加密
                "pos": tableView.absolutePosition(at: indexPath),
                "location": "quick_search"
            ]
        }

        guard let currentAccount = (try? userResolver.resolve(assert: PassportUserService.self))?.user else {
            return cell
        }
        if let chatterTabVM = cellViewModel as? ChatterSearchViewModel {
            chatterTabVM.divisionInFoldStatus = self.viewModel.divisionInFoldStatus
            chatterTabVM.tableViewWidth = self.resultView.bounds.width
            cell.set(viewModel: chatterTabVM,
                     currentAccount: currentAccount,
                     searchText: viewModel.lastInput?.query ?? "")
        } else {
            cell.set(viewModel: cellViewModel,
                     currentAccount: currentAccount,
                     searchText: viewModel.lastInput?.query ?? "")
        }
        return cell
    }

    // Header
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerType = viewModel.headerType(in: section),
              let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerType.identifier) as? SearchHeaderProtocol,
              let headerViewModel = viewModel.headerViewModel(in: section) else {
            return nil
        }
        header.set(viewModel: headerViewModel)
        viewModel.setHeaderActionStatus(in: section, viewModel: headerViewModel)
        updateFocusForFooter(header, at: section)
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return viewModel.heightForHeader(in: section)
    }

    // Footer
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerType = viewModel.footerType(in: section),
              let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: footerType.identifier) as? SearchFooterProtocol else {
            return nil
        }
        let footerViewModel = viewModel.footerViewModel(in: section)
        footer.set(viewModel: footerViewModel)
        viewModel.setFooterActionStatus(in: section)
        updateFocusForFooter(footer, at: section)
        return footer
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return viewModel.heightForFooter(in: section)
    }

    // selection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        if viewModel.isSearchTipCell(forIndexPath: indexPath) == true {
            guard let tipVM = viewModel.cellViewModel(forIndexPath: indexPath) as? SearchTipViewModel else {
                return
            }
            guard let cell = tableView.cellForRow(at: indexPath) else { return }
            if tipVM.showHotTip {
                cell.isHidden = true
                activityIndicatorView?.startAnimating()
                viewModel.loadMore()
            } else {
                cell.selectionStyle = .none
            }
            return
        }

        endEditing()
        if Display.phone {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        viewModel.didSelect(at: indexPath, from: self)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplay(at: indexPath, in: tableView)
        updateFocusForWillDisplay(cell: cell, at: indexPath)
        if let _cell = cell as? SearchTableViewCellProtocol {
            _cell.cellWillDisplay()
        }
    }

    private func endEditing() {
        self.navigationController?.view.endEditing(false)
    }
}

extension SearchResultViewController: UITableViewDragDelegate {
    // MARK: - UITableViewDragDelegate
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let cell = tableView.cellForRow(at: indexPath) as? SearchTableViewCellProtocol,
              let viewModel = cell.viewModel,
              let scene = viewModel.supportDragScene() else {
            return []
        }
        scene.sceneSourceID = self.currentSceneID()
        let activity = SceneTransformer.transform(scene: scene)
        let itemProvider = NSItemProvider()
        itemProvider.registerObject(activity, visibility: .all)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return nil
        }
        var supportPadStyle = false
        if let searchCell = cell as? SearchTableViewCellProtocol {
            supportPadStyle = searchCell.viewModel?.supprtPadStyle() ?? false
        }
        let parameters = UIDragPreviewParameters()
        var showRect = cell.bounds
        if supportPadStyle {
            showRect.size.height -= 12
        }
        parameters.visiblePath = UIBezierPath(roundedRect: showRect, cornerRadius: 12)
        return parameters
    }

    // MARK: - Route
    func openSearchTab(appId: String, tabName: String) {
        viewModel.openSearchTab(appId: appId, tabName: tabName)
    }
}
extension SearchResultViewController: SearchFromColdDataDelegate, SearchErrorClickDelegate {
    func requestColdData() {
        resultView.status = .loading
        viewModel.loadMore()
    }

    func requestForQuota(isNeedLoadingPage: Bool) {
        if isNeedLoadingPage {
            resultView.status = .loading
            viewModel.loadMore()
        } else if let showTipCell = self.showTipCell {
            showTipCell.isHidden = true
            activityIndicatorView?.startAnimating()
            viewModel.loadMore()
        }
        var slashID: String?
        if self.viewModel.config.tab.isOpenSearch, case let .open(info) = self.viewModel.config.tab {
            slashID = info.id
        }
        var isCache: Bool?
        if let service = searchOuterService, service.enableUseNewSearchEntranceOnPad() {
            isCache = service.currentIsCacheVC()
        }
        SearchTrackUtil.trackForSearchClick(click: "function",
                                            actionType: "keep_searching",
                                            query: viewModel.lastInput?.query ?? "",
                                            sessionID: viewModel.currentCapturedSession?.session ?? "",
                                            imprID: viewModel.currentCapturedSession?.imprID ?? "",
                                            sceneType: "main",
                                            searchLocation: viewModel.config.searchLocation,
                                            slashID: slashID,
                                            isCache: isCache)
    }
}
