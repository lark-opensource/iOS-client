//
//  SearchRootViewController.swift
//  LarkSearch
//
//  Created by Patrick on 2022/5/20.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignTabs
import LarkSearchCore
import LarkSDKInterface
import LarkMessengerInterface
import RxSwift
import RxCocoa
import EENavigator
import LarkContainer
import Swinject
import LarkKeyCommandKit
import LarkSearchFilter
import LarkAlertController
import LKCommonsLogging
import SuiteAppConfig

public final class SearchRootViewController: BaseUIViewController, UserResolverWrapper, SearchRootViewControllerProtocol {
    public weak var circleDelegate: SearchRootViewControllerCircleDelegate?
    private lazy var searchOuterService: SearchOuterService? = {
        let service = try? userResolver.resolve(assert: SearchOuterService.self)
        return service
    }()

    static let logger = Logger.log(SearchRootViewController.self, category: "Module.IM.Search")
    let searchNaviBar: SearchNaviBar
    var searchField: SearchUITextField { return searchNaviBar.searchbar.searchTextField }
    let initQuery: String?
    let sourceOfSearch: SourceOfSearch
    let searchSession: SearchSession
    let router: SearchRouter
    let historyStore: SearchQueryHistoryStore

    // MARK: container result state
    private lazy var segmentedView: UDTabsTitleView = {
        let tabs = UDTabsTitleView()
        let config = tabs.getConfig()
        config.isTitleColorGradientEnabled = false
        config.titleNormalFont = UIFont.systemFont(ofSize: 14)
        config.titleNormalColor = UIColor.ud.textCaption
        config.titleSelectedFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        config.titleSelectedColor = UIColor.ud.primaryContentDefault
        config.itemSpacing = 24
        config.itemWidthIncrement = 2

        tabs.setConfig(config: config)
        /// 配置指示器
        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2
        indicator.indicatorCornerRadius = 0
        indicator.indicatorColor = .ud.primaryContentDefault
        tabs.indicators = [indicator]
        return tabs
    }()

    private lazy var listContainerView: UDTabsListContainerView = {
        return UDTabsListContainerView(dataSource: self)
    }()

    let viewModel: SearchRootViewModel
    public let userResolver: UserResolver
    private let disposeBag = DisposeBag()

    init(userResolver: UserResolver,
         viewModel: SearchRootViewModel,
         searchNaviBar: SearchNaviBar,
         initQuery: String?,
         sourceOfSearch: SourceOfSearch,
         searchSession: SearchSession,
         router: SearchRouter,
         historyStore: SearchQueryHistoryStore) {
        self.userResolver = userResolver
        self.searchNaviBar = searchNaviBar
        self.viewModel = viewModel
        self.initQuery = initQuery
        self.sourceOfSearch = sourceOfSearch
        self.searchSession = searchSession
        self.router = router
        self.historyStore = historyStore
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - life cycle 方法
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupSubscribe()
        setupJump()
        viewModel.viewDidLoad()
    }

    private var shouldShowKeyboard = true // 第一次进来时弹起键盘
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.shouldShowKeyboard {
            self.shouldShowKeyboard = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.searchField.becomeFirstResponder()
            }
        }
        SearchTrackUtil.trackForStableWatcher(domain: "asl_general_search",
                                              message: "asl_search_enter",
                                              metricParams: [:],
                                              categoryParams: [:])
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.searchField.resignFirstResponder()
        if let searchOuterService = searchOuterService, searchOuterService.enableUseNewSearchEntranceOnPad() {
            self.circleDelegate?.searchQueryWhenWillDisappear(query: searchField.text)
        }
    }

    private var lastVCWidth: CGFloat = 0
    private var sepLineLayer: CALayer = CALayer()
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let height = 1.0 / UIScreen.main.scale
        var frame = segmentedView.bounds
        frame.origin.y = frame.height - height
        frame.size.height = height
        sepLineLayer.frame = frame

        let viewWidth = self.navigationController?.view.bounds.size.width ?? self.view.bounds.size.width
        if lastVCWidth != viewWidth {
            lastVCWidth = viewWidth
            // NOTE: reload会重新load list item, 导致重建VC, 可能导致UI和统计等问题
            // 但需要重新加载保证segment的位置和宽度正常
            segmentedView.reloadData()
        }
    }

    public func routTo(tab: SearchTab, query: String?, shouldForceOverwriteQueryIfEmpty: Bool) {
        var input: SearcherInput
        if let _query = query, !_query.isEmpty {
            input = SearcherInput(query: _query)
        } else {
            input = SearcherInput(query: shouldForceOverwriteQueryIfEmpty ? "" : getCurrentQuery())
        }
        let routParam: SearchRouteParam = SearchRouteParam(type: tab, input: input)
        route(withParam: routParam)
    }

    private var navigationWindowChangeObserveView: UIView?
    public override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if navigationWindowChangeObserveView == nil {
            guard let navigationController = parent as? UINavigationController else { return }
            let watcher = SearchObserveWindowUIView()
            watcher.base = self
            watcher.alpha = 0 // not hidden to observe window
            navigationController.view.insertSubview(watcher, at: 0)
            navigationWindowChangeObserveView = watcher
        } else {
            guard parent == nil else { return }
            navigationWindowChangeObserveView?.removeFromSuperview() // ensure clear marker view
            navigationWindowChangeObserveView = nil
        }
    }

    deinit {
        navigationWindowChangeObserveView?.removeFromSuperview()
    }
    // MARK: - setup functions
    private func setupViews() {
        isNavigationBarHidden = true
        self.view.backgroundColor = UIColor.ud.bgBody // overwrite super default backgroundColor
        // segmentedView setup
        segmentedView.titles = viewModel.tabTypes.map { $0.title }
        segmentedView.backgroundColor = UIColor.ud.bgBody
//        segmentedView.isContentScrollViewClickTransitionAnimationEnabled = false
        segmentedView.listContainer = listContainerView
        segmentedView.delegate = self

        if !AppConfigManager.shared.leanModeIsOn {
            let buttonSize: CGFloat = 40
            segmentedView.collectionView.contentInset = .init(top: 0, left: 0, bottom: 0, right: buttonSize) // moreButton space

            let moreButton = UIButton()
            moreButton.addTarget(self, action: #selector(clickMoreTab), for: .touchUpInside)
            moreButton.setImage(Resources.tab_more.withRenderingMode(.alwaysTemplate), for: .normal)
            moreButton.tintColor = UIColor.ud.iconN2
            moreButton.contentMode = .center

            segmentedView.collectionView.addSubview(moreButton)
            // NOTE: autolayout约束moreButton到
            segmentedView.collectionView.rx.observe(CGSize.self, "contentSize").bind(onNext: { (size) in
                guard let size = size else { return }
                // FIXME: 如果数目太少的话，还是在右边，不直接可见, 布局有一些问题
                // 因为目前内置tab不能删除，所有问题应该还好.
                // 如果以后需要展示少于内置的数量，再来做调整
                moreButton.frame = .init(x: size.width, y: (size.height - buttonSize) / 2, width: buttonSize, height: buttonSize)
            })
            .disposed(by: disposeBag)
        }
        segmentedView.layer.insertSublayer(sepLineLayer, at: 0) // indicator盖在sepLineLayer上
        sepLineLayer.ud.setBackgroundColor(UIColor.ud.lineDividerDefault)

        searchNaviBar.searchbar.cancelButton.rx.tap
            .bind(onNext: { [weak self] in self?.cancelPage() })
            .disposed(by: disposeBag)
        searchField.placeholder = BundleI18n.LarkSearch.Lark_Legacy_Search
        searchField.returnKeyType = .search
        searchField.autocapitalizationType = .none
        searchField.enablesReturnKeyAutomatically = true
        searchField.addTarget(self, action: #selector(queryEditingChange), for: .editingChanged)
        searchField.delegate = self
        searchField.autocorrectionType = .no
        // layout
        view.addSubview(searchNaviBar)
        view.addSubview(segmentedView)
        view.addSubview(listContainerView)

        searchNaviBar.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
        }
        segmentedView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(searchNaviBar.snp.bottom)
            make.height.equalTo(40)
        }
        listContainerView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.top.equalTo(segmentedView.snp.bottom)
        }

        lastVCWidth = self.navigationController?.view.bounds.size.width ?? self.view.bounds.size.width

        self.reloadSegmentedView()

        // resign KeyBoard when tap
        let resultViewTap = UITapGestureRecognizer(target: self, action: #selector(contentViewTap(gesture:)))
        resultViewTap.delegate = self
        listContainerView.addGestureRecognizer(resultViewTap)
    }

    private func setupSubscribe() {
        viewModel.shouldReloadTabsView
            .drive(onNext: { [weak self] shouldReloadTabsView in
                guard let self = self, shouldReloadTabsView else { return }
                if let oldTab = self.viewModel.lastSelectTabBeforeTabChange, let index = self.viewModel.tabTypes.firstIndex(of: oldTab) {
                    self.segmentedView.defaultSelectedIndex = index
                }
                self.segmentedView.titles = self.viewModel.tabTypes.map { $0.title }
                self.reloadSegmentedView()
            })
            .disposed(by: disposeBag)
        viewModel.shouldChangeQuery
            .drive(onNext: { [weak self] changedQuery in
                self?.searchField.text = changedQuery
            })
            .disposed(by: disposeBag)
        viewModel.shouldRoute
            .drive(onNext: { [weak self] routeParam in
                guard let self = self,
                      let routeParam = routeParam else {
                    return
                }
                self.route(withParam: routeParam)
            })
            .disposed(by: disposeBag)
        viewModel.shouldShowClearHistory
            .drive(onNext: { [weak self] callback in
                guard let self = self, let callback = callback else { return }
                self.clearHistory(callback: callback)
            })
            .disposed(by: disposeBag)
    }

    private func setupJump() {
        // Jump
        if let jumpTab = viewModel.jumpTab {
            let input = SearcherInput(query: initQuery ?? "")
            let routeParam = SearchRouteParam(type: jumpTab, input: input)
            route(withParam: routeParam)
        }
        // 设置 textField
        if let initQuery = initQuery {
            searchField.text = initQuery
            queryChangeSearch()
        }
    }

    private func route(withParam routeParam: SearchRouteParam) {
        func goToPage(routeParam: SearchRouteParam) {
            guard let index = viewModel.tabTypes.firstIndex(of: routeParam.type) else {
                Self.logger.error("[LarkSearch] routeTab error, tabName: " + routeParam.type.title)
                return
            }
            let targetTab = viewModel.tabService?.getCompleteSearchTab(type: routeParam.type) ?? routeParam.type
            let filters = viewModel.appendTabFilters(searchTab: targetTab, inputFilters: routeParam.input.filters)
            let query = routeParam.input.query

            segmentedView.selectItemAt(index: index)
            if let contentVC = currentController as? SearchContentViewController {
                contentVC.routeTo(withSearchInput: SearcherInput(query: query, filters: filters), isCapsuleStyle: false)
            }
        }
        if viewModel.tabTypes.contains(routeParam.type) {
            goToPage(routeParam: routeParam)
        } else {
            // 增加一个临时 tab
            viewModel.addTempTab(routeParam.type)
            segmentedView.titles = self.viewModel.tabTypes.map { $0.title }
            reloadSegmentedView()
            goToPage(routeParam: routeParam)
        }
    }

    private func reloadSegmentedView() {
        self.segmentedView.reloadData()
        // trigger set current controller and init search, vc set will avoid duplicate
        self.tabsView(self.segmentedView, didSelectedItemAt: self.segmentedView.selectedIndex)

        // 清空旧的缓存，只保留新的VC
        cachedControllers = listContainerView.validListDict.reduce(into: [:]) { (cached, kv) in
            guard kv.key >= 0, kv.key < viewModel.tabTypes.count, let vc = kv.value as? SearchContentContainer else { return }
            let type = viewModel.tabTypes[kv.key]
            cached[type] = vc
        }
    }

    private func clearHistory(callback: @escaping (Bool) -> Void) {
        func presentAlert(alert: UIViewController) {
            navigator.present(alert, from: self)
        }
        let alertController = LarkAlertController()
        alertController.setContent(text: BundleI18n.LarkSearch.Lark_Search_ClearAllHistory)
        alertController.addCancelButton(dismissCompletion: { callback(false) })
        alertController.addPrimaryButton(text: BundleI18n.LarkSearch.Lark_Legacy_Sure, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.viewModel.historyStore.deleteAllInfos(on: self.view.window, callback: callback)
        })
        presentAlert(alert: alertController)
    }
    // MARK: - tab 页面缓存
    #if DEBUG
    private var cachedControllers: [SearchTab: SearchContentContainer] = [:] {
        willSet { precondition(Thread.isMainThread, "should occur on main thread!") }
    }
    #else
    private var cachedControllers: [SearchTab: SearchContentContainer] = [:]
    #endif
    var currentController: AnyObject? {
        didSet {
            guard currentController !== oldValue else { return }
            queryChangeSearch()
        }
    }

    func childContentViewController(at index: Int) -> UDTabsListContainerViewDelegate {
        let type = viewModel.tabTypes[index]
        if let childVC = cachedControllers[type] as? SearchContentContainer { return childVC }

        let childVC = makeSearchContentViewController(for: type)
        childVC.listView().clipsToBounds = true
        cachedControllers[type] = childVC
        return childVC
    }

    // MARK: - SearchRootViewControllerProtocol
    public func getContentContainerY() -> CGFloat {
        guard let searchOuterService = searchOuterService, searchOuterService.enableUseNewSearchEntranceOnPad() else { return 0 }
        //筛选器底部有一个宽度有0.5的灰色线，需要减去
        return self.listContainerView.frame.origin.y - 0.5
    }

    public func enterCacheSearchVC() {
        guard let searchOuterService = searchOuterService, searchOuterService.enableUseNewSearchEntranceOnPad() else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.searchField.becomeFirstResponder()
        }
        let entryAction = searchOuterService.currentEntryAction()
        SearchTrackUtil.trackSearchView(session: viewModel.searchSession,
                                        searchLocation: viewModel.jumpTab?.trackRepresentation ?? "quick_search",
                                        sceneType: "main",
                                        applinkSource: viewModel.applinkSource,
                                        entryAction: entryAction?.rawValue,
                                        isCache: true)
    }

    // MARK: - UDTabsListContainerViewDataSource & UDTabsViewDelegate
    public func listContainerView(_ listContainerView: UDTabsListContainerView, initListAt index: Int) -> UDTabsListContainerViewDelegate {
        return childContentViewController(at: index)
    }

    public func numberOfLists(in listContainerView: UDTabsListContainerView) -> Int {
        return viewModel.tabTypes.count
    }
    public func tabsView(_ segmentedView: UDTabsView, didSelectedItemAt index: Int) {
        viewModel.didSelectedItem(at: index, currentController: currentController)
        currentController = listContainerView.validListDict[index]
    }
    public func scrollViewClass(in listContainerView: UDTabsListContainerView) -> AnyClass? {
        return ContainerScrollView.self
    }
    // MARK: - UITextFieldDelegate
    func getCurrentQuery() -> String {
        if let queryAttributed = searchField.attributedText {
            return queryAttributed.string
        } else {
            return searchField.text ?? ""
        }
    }

    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }

    // MARK: user interaction
    @objc
    private func clickMoreTab() {
        navigator.present(
            SearchMainTabManagerViewController(userResolver: userResolver),
            wrap: LkNavigationController.self, from: self,
            prepare: { $0.modalPresentationStyle = .formSheet },
            animated: true)
    }

    @objc
    private func cancelPage() {
        if let service = searchOuterService, service.enableUseNewSearchEntranceOnPad() {
            self.circleDelegate?.didTapCancelBtn()
            return
        }
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc
    private func queryEditingChange() {
        guard searchField.markedTextRange == nil else { return }
        queryChangeSearch()
    }

    private func queryChangeSearch() {
        guard let current = self.currentController as? SearchContentContainer else { return }
        current.queryChange(text: getCurrentQuery())
    }

    // MARK: - UIGestureRecognizerDelegate
    @objc
    private func contentViewTap(gesture: UITapGestureRecognizer) {
        assertionFailure("handle by delegate and never recognized")
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 滑动也禁掉，所以有touch就直接resign
        searchField.resignFirstResponder()
    }
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // always false, not interfere other gesture and touch event
        return false
    }

    // MARK: KeyBinding
    public override func keyCommandContainers() -> [KeyCommandContainer] {
        if let present = self.presentedViewController {
            return present.keyCommandContainers()
        }
        return [self] + (currentController?.keyCommandContainers() ?? [])
    }

    public override func keyBindings() -> [KeyBindingWraper] {
        super.keyBindings() + [
            // 大搜页面再按Cmd+K, 退出界面
            KeyCommandBaseInfo(
                input: "k",
                modifierFlags: .command
            ).binding(
                target: self,
                selector: #selector(cancelPage)
            ).wraper
        ]
    }
}

extension SearchRootViewController {
    final class ContainerScrollView: UIScrollView {
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            let v = super.hitTest(point, with: event)
            // 内部水平filter可能会停在半路中间，目前在ios 13.7真机上复现。iOS 14 OK
            // 好像是因为hittest返回了不在bounds里的scrollView.. hittest兼容处理一下
            // 进一步排查发现是因为child在size为非整数时，触发了_startDraggingParent, 但没有结束，导致hittest始终返回子scrollView
            // NOTE: 这里通过临时disable scroll，来屏蔽_startDraggingParent的状态调用
            // 但是这样同时导致了外部设置的isScrollEnabled无效
            var canScroll = true
            var nextView = v
            while let view = nextView, view != self {
                // 内部水平filter可能会停在半路中间，目前在ios 13.7真机上复现。没好的解决思路，直接过滤对应scrollView上的滑动
                // 感觉没解决问题，一样的会卡在对应的view上, 其他view接受不到点击事件
                if let scroll = view as? UIScrollView, scroll.contentSize.width > scroll.bounds.width {
                    canScroll = false
                    break
                }
                nextView = view.superview
            }
            if canScroll != self.isScrollEnabled {
                self.isScrollEnabled = canScroll
            }
            return v
        }
    }
}

extension SearchRootViewController {
    func makeSearchContentViewController(for tab: SearchTab) -> SearchContentContainer {
        let targetTab = viewModel.tabService?.getCompleteSearchTab(type: tab) ?? tab
        do {
            if targetTab == .calendar {
                return (try userResolver.resolve(assert: SearchDependency.self)).eventChildViewController(searchNavBar: searchNaviBar)
            }
            if targetTab == .email {
                return (try userResolver.resolve(assert: SearchDependency.self)).getEmailSearchViewController(searchNavBar: searchNaviBar)
            }
            if let config = SearchTabConfigFactory.createConfig(resolver: self.userResolver, tab: targetTab, sourceOfSearch: sourceOfSearch) {
                let container = try SearchContentDependencyContainer(userResolver: userResolver,
                                                                     sharedRootViewModel: viewModel,
                                                                     tab: targetTab,
                                                                     sourceOfSearch: sourceOfSearch,
                                                                     searchSession: searchSession,
                                                                     router: router,
                                                                     historyStore: historyStore,
                                                                     config: config)
                return container.makeSearchContentViewController()
            } else {
                return DemoUIViewController()
            }
        } catch {
            return DemoUIViewController()
        }
    }
}

final class DemoUIViewController: UIViewController, SearchContentContainer {
    func listView() -> UIView { UIView() }
    func queryChange(text: String) { }
}

extension SearchRootViewController: SearchBarTransitionTopVCDataSource {
    public var searchBar: SearchBar { return self.searchNaviBar.searchbar }
    public var bottomView: UIView { return listContainerView }
}

extension SearchRootViewController: UDTabsListContainerViewDataSource, UDTabsViewDelegate {}
extension SearchRootViewController: UITextFieldDelegate {}
extension SearchRootViewController: UIGestureRecognizerDelegate {}
