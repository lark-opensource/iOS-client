//
//  SearchMainRootViewController.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/7/11.
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
import UniverseDesignTheme

public final class SearchMainRootViewController: BaseUIViewController, SearchRootViewControllerProtocol {
    public weak var circleDelegate: SearchRootViewControllerCircleDelegate?
    private lazy var searchOuterService: SearchOuterService? = {
        let service = try? userResolver.resolve(assert: SearchOuterService.self)
        return service
    }()

    static let logger = Logger.log(SearchMainRootViewController.self, category: "Module.IM.Search")

    let searchNaviBar: SearchNaviBar = SearchNaviBar(style: .search)
    var searchField: SearchUITextField { return searchNaviBar.searchbar.searchTextField }
    let intentionCapsuleView: SearchIntentionCapsuleView
    lazy var moreMenuButton: UIButton = {
        let moreMenuButton = UIButton(frame: CGRect(x: 0, y: 0, width: 48, height: 40))
        moreMenuButton.layer.insertSublayer(moreMenuButtonGradientLayer, at: 0)
        moreMenuButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 12)
        moreMenuButton.setImage(Resources.more_Tab_menu_icon, for: UIControl.State.normal)
        if let imageView = moreMenuButton.imageView {
            moreMenuButton.bringSubviewToFront(imageView)
        }
        return moreMenuButton
    }()
    let moreMenuButtonGradientLayer: CAGradientLayer = {
        if #available(iOS 13.0, *) {
            let correctStyle = UDThemeManager.userInterfaceStyle
            let correctTraitCollection = UITraitCollection(userInterfaceStyle: correctStyle)
            UITraitCollection.current = correctTraitCollection
        }
        let layer = CAGradientLayer()
        layer.frame = CGRect(x: 0, y: 0, width: 48, height: 40)
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.locations = [0, NSNumber(value: 14.0 / 48.0), 1]
        layer.colors = [UIColor.ud.bgBody.withAlphaComponent(0).cgColor,
                        UIColor.ud.bgBody.withAlphaComponent(1).cgColor,
                        UIColor.ud.bgBody.withAlphaComponent(1).cgColor]
        return layer
    }()
    let contentContainer: UIView = UIView()
    var advancedSyntaxView: SearchAdvancedSyntaxView?

    let initQuery: String?
    let sourceOfSearch: SourceOfSearch
    let searchSession: SearchSession
    let router: SearchRouter
    let historyStore: SearchQueryHistoryStore
    let resolver: Resolver
    let viewModel: SearchMainRootViewModel
    var capsuleViewModel: SearchIntentionCapsuleViewModel {
        return self.viewModel.capsuleViewModel
    }
    let userResolver: UserResolver
    private let disposeBag = DisposeBag()

    init(userResolver: UserResolver,
         viewModel: SearchMainRootViewModel,
         initQuery: String?,
         sourceOfSearch: SourceOfSearch,
         searchSession: SearchSession,
         router: SearchRouter,
         historyStore: SearchQueryHistoryStore,
         resolver: Resolver) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.initQuery = initQuery
        self.sourceOfSearch = sourceOfSearch
        self.searchSession = searchSession
        self.router = router
        self.historyStore = historyStore
        self.resolver = resolver
        self.intentionCapsuleView = SearchIntentionCapsuleView(withViewModel: self.viewModel.capsuleViewModel)
        if SearchFeatureGatingKey.enableAdvancedSyntax.isUserEnabled(userResolver: userResolver),
           let advancedSyntaxViewModel = viewModel.advancedSyntaxViewModel {
            advancedSyntaxView = SearchAdvancedSyntaxView(userResolver: userResolver, viewModel: advancedSyntaxViewModel)
        }
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

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateMoreButtonStyle()
            }
        }
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let searchOuterService = searchOuterService, searchOuterService.enableUseNewSearchEntranceOnPad() {
            if !searchOuterService.isCompactStatus() {
                searchBar.snp.updateConstraints { make in
                    make.left.equalToSuperview().offset(0)
                    make.right.equalToSuperview().offset(0)
                }
                if viewModel.currentTab != .main {
                    intentionCapsuleView.rightInsetValue = 0
                }
                intentionCapsuleView.leftInsetValue = 0
                intentionCapsuleView.capsuleCollectionView.reloadData()
            } else {
                searchBar.snp.updateConstraints { make in
                    make.left.equalToSuperview().offset(12)
                    make.right.equalToSuperview().offset(-12)
                }
                if viewModel.currentTab != .main {
                    intentionCapsuleView.rightInsetValue = 12
                }
                intentionCapsuleView.leftInsetValue = 12
                intentionCapsuleView.capsuleCollectionView.reloadData()
            }
        }
    }

    // MARK: - SearchRootViewControllerProtocol
    public func getContentContainerY() -> CGFloat {
        guard let searchOuterService = searchOuterService, searchOuterService.enableUseNewSearchEntranceOnPad() else { return 0 }
        return self.contentContainer.frame.origin.y
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
        view.backgroundColor = UIColor.ud.bgBody
        capsuleViewModel.superVC = self
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

        moreMenuButton.addTarget(self, action: #selector(moreTabClickAction), for: UIControl.Event.touchUpInside)

        // layout
        view.addSubview(searchNaviBar)
        view.addSubview(intentionCapsuleView)
        view.addSubview(moreMenuButton)
        view.addSubview(contentContainer)

        searchNaviBar.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }

        // resign KeyBoard when tap
        let resultViewTap = UITapGestureRecognizer(target: self, action: #selector(contentViewTap(gesture:)))
        resultViewTap.delegate = self
        contentContainer.addGestureRecognizer(resultViewTap)
        updateContentViewController(withTab: capsuleViewModel.capsulePage.searchTab, tabConfig: capsuleViewModel.capsulePage.tabConfig)
        if SearchFeatureGatingKey.enableAdvancedSyntax.isUserEnabled(userResolver: userResolver),
           let advancedSyntaxView = self.advancedSyntaxView {
            view.addSubview(advancedSyntaxView)
            advancedSyntaxView.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(searchNaviBar.snp.bottom)
            }
        }
    }

    private func updateMoreButtonStyle() {
        if #available(iOS 13.0, *) {
            let correctStyle = UDThemeManager.userInterfaceStyle
            let correctTraitCollection = UITraitCollection(userInterfaceStyle: correctStyle)
            UITraitCollection.current = correctTraitCollection
        }
        moreMenuButtonGradientLayer.colors = [UIColor.ud.bgBody.withAlphaComponent(0).cgColor,
                                              UIColor.ud.bgBody.withAlphaComponent(1).cgColor,
                                              UIColor.ud.bgBody.withAlphaComponent(1).cgColor]
        moreMenuButton.setImage(Resources.more_Tab_menu_icon, for: UIControl.State.normal)
    }

    private func updateContentViewController(withTab tab: SearchTab, tabConfig: SearchTabConfigurable?) {
        let subViews = contentContainer.subviews
        for subView in subViews {
            subView.removeFromSuperview()
        }
        currentController?.removeFromParent()
        let contentVC = getContentViewController(at: tab, tabConfig: tabConfig)
        currentController = contentVC
        addChild(contentVC)
        contentContainer.addSubview(contentVC.view)
        contentVC.view.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        intentionCapsuleView.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(searchNaviBar.snp.bottom)
        }
        if tab == .main {
            intentionCapsuleView.rightInsetValue = 48
            moreMenuButton.isHidden = false
            moreMenuButton.snp.remakeConstraints { make in
                make.size.equalTo(CGSize(width: 48, height: 40))
                make.centerY.equalTo(intentionCapsuleView)
                make.trailing.equalToSuperview()
            }
        } else {
            intentionCapsuleView.rightInsetValue = 12
            moreMenuButton.isHidden = true
        }

        contentContainer.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(intentionCapsuleView.snp.bottom)
        }
    }

    private func setupSubscribe() {
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
        viewModel.shouldUpdateTabs
            .drive(onNext: { [weak self] tabs in
                guard let self = self, !tabs.isEmpty else { return }
                self.capsuleViewModel.updatePullTabs(tabs: tabs)
            })
            .disposed(by: disposeBag)
        viewModel.shouldUpdateAvailableTabs
            .drive(onNext: { [weak self] tabs in
                guard let self = self, !tabs.isEmpty else { return }
                self.capsuleViewModel.updatePullAvailableTabs(tabs: tabs)
            })
            .disposed(by: disposeBag)

        viewModel.shouldNoticeSearchStart
            .drive(onNext: { [weak self] (tab, input) in
                guard let self = self, let _tab = tab, let _input = input else { return }
                self.capsuleViewModel.noticeSearchStart(tab: _tab, input: _input)
                if SearchFeatureGatingKey.enableAdvancedSyntax.isUserEnabled(userResolver: self.userResolver) {
                    self.viewModel.advancedSyntaxViewModel?.searchAdvancedSyntax(input: _input,
                                                                                 tab: capsuleViewModel.capsulePage.searchTab,
                                                                                 tabConfig: capsuleViewModel.capsulePage.tabConfig)
                }
            })
            .disposed(by: disposeBag)

        viewModel.shouldNoticeSearchEnd
            .drive(onNext: { [weak self] requestInfo in
                guard let self = self, let _requestInfo = requestInfo else { return }
                self.capsuleViewModel.noticeSearchEnd(withRequestInfo: _requestInfo)
            })
            .disposed(by: disposeBag)

        // 选中筛选器发生变化
        capsuleViewModel.shouldChangeFilterToSearch
            .drive(onNext: { [weak self] filters in
                guard let self = self else { return }
                self.filtersChangeSearch(filters: filters)
            })
            .disposed(by: disposeBag)
        // 点击tab切换垂类
        capsuleViewModel.shouldRouteTab
            .drive(onNext: { [weak self] targetTab in
                guard let self = self else { return }
                self.viewModel.trackTabChange(tab: targetTab, currentController: self.currentController)
                let query = self.getCurrentQuery()
                let input = SearcherInput(query: query)
                let routeParam = SearchRouteParam(type: targetTab, input: input)
                self.route(withParam: routeParam)
            })
            .disposed(by: disposeBag)
        capsuleViewModel.shouldResignFirstResponder
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.searchField.resignFirstResponder()
            })
            .disposed(by: disposeBag)
        capsuleViewModel.shouldTrackAdvancedSearchClick
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.trackAdvanceSearchClick()
            }).disposed(by: disposeBag)
        capsuleViewModel.shouldTrackCapsuleClick
            .drive(onNext: { [weak self] (pos, capsuleStatus) in
                guard let self = self else { return }
                self.trackCapsuleClick(pos: pos, capsuleStatus: capsuleStatus)
            })
            .disposed(by: disposeBag)
        capsuleViewModel.shouldShowMoreTabWithCurrentTab
            .drive(onNext: { [weak self] currentTab in
                guard let self = self else { return }
                self.showMoreTabView(showAdvancedSearch: false, currentTab: currentTab)
            })
            .disposed(by: disposeBag)

        capsuleViewModel.filterChange
            .drive(onNext: { [weak self] (isAdd, searchFilter) in
                guard let self = self else { return }
                guard SearchFeatureGatingKey.enableFilterEludeBot.isUserEnabled(userResolver: self.userResolver) else { return }
                guard let searchFilter = searchFilter else { return }
                self.viewModel.updateTabFilters(searchTab: self.viewModel.currentTab, filter: searchFilter, isAdd: isAdd, selectedFilters: self.capsuleViewModel.capsulePage.selectedFilters)
            })
            .disposed(by: disposeBag)

        capsuleViewModel.filterReset.drive(onNext: { [weak self] in
            guard let self = self else { return }
            guard SearchFeatureGatingKey.enableFilterEludeBot.isUserEnabled(userResolver: self.userResolver) else { return }
            self.viewModel.resetTabFilters()
        })
        .disposed(by: disposeBag)

        viewModel.advancedSyntaxViewModel?.didSelectedAdvancedSyntax
            .drive(onNext: { [weak self] selectedViewModel in
                guard let self = self, let _selectedViewModel = selectedViewModel else { return }
                guard _selectedViewModel.requestInfo.tab == self.viewModel.currentTab else { return }
                let query = self.getCurrentQuery().substring(to: _selectedViewModel.requestInfo.input.match.range.location)
                self.searchField.text = query
                self.queryChangeSearch()
                self.capsuleViewModel.selectedAdvancedSyntax(filter: _selectedViewModel.filter)
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

    private func trackAdvanceSearchClick() {
        var slashID: String?
        if case let .open(info) = self.viewModel.currentTab {
            slashID = info.id
        }
        var isCache: Bool?
        if let service = searchOuterService, service.enableUseNewSearchEntranceOnPad() {
            isCache = service.currentIsCacheVC()
        }
        SearchTrackUtil.trackAdvancedSearchClick(query: self.getCurrentQuery(),
                                                 sessionID: self.searchSession.capture().session,
                                                 imprID: self.searchSession.capture().imprID,
                                                 sceneType: "main",
                                                 searchLocation: self.capsuleViewModel.capsulePage.tabConfig?.searchLocation ?? "",
                                                 slashID: slashID,
                                                 isCache: isCache)
    }

    private func route(withParam routeParam: SearchRouteParam) {
        let targetTab = viewModel.tabService?.getCompleteSearchTab(type: routeParam.type) ?? routeParam.type
        capsuleViewModel.capsulePage.resetAllFilters()
        capsuleViewModel.capsulePage.lastInput = nil
        let capsulePage = viewModel.createCapsulePage(withTab: targetTab)
        let filters = viewModel.appendTabFilters(searchTabConfig: capsulePage.tabConfig, inputFilters: routeParam.input.filters)
        capsulePage.coverSelectedFilters(filters: filters)
        capsuleViewModel.updateCapsulePage(page: capsulePage)
        viewModel.currentTab = targetTab
        updateContentViewController(withTab: targetTab, tabConfig: capsulePage.tabConfig)
        let newInput = SearcherInput(query: routeParam.input.query,
                                     filters: capsuleViewModel.mergeSelectedAndSupportFilter(selected: capsulePage.selectedFilters,
                                                                                             supported: capsulePage.tabConfig?.supportedFilters ?? []))
        if let contentVC = currentController as? SearchContentViewController {
            contentVC.routeTo(withSearchInput: newInput, isCapsuleStyle: true)
        }
    }

    private func clearHistory(callback: @escaping (Bool) -> Void) {
        func presentAlert(alert: UIViewController) {
            Navigator.shared.present(alert, from: self)
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

    private func trackCapsuleClick(pos: Int, capsuleStatus: [String: Any]) {
        guard pos >= 0, !capsuleStatus.isEmpty else { return }
        var slashID: String?
        if case let .open(info) = viewModel.currentTab {
            slashID = info.id
        }
        var isCache: Bool?
        if let service = searchOuterService, service.enableUseNewSearchEntranceOnPad() {
            isCache = service.currentIsCacheVC()
        }
        SearchTrackUtil.trackCapsuleClick(query: getCurrentQuery(),
                                          sessionId: searchSession.capture().session,
                                          imprID: searchSession.capture().imprID,
                                          sceneType: "main",
                                          searchLocation: capsuleViewModel.capsulePage.tabConfig?.searchLocation ?? "",
                                          capsulePos: pos,
                                          capsuleStatus: capsuleStatus,
                                          slashID: slashID,
                                          isCache: isCache)
    }

    var currentController: AnyObject? {
        didSet {
            guard currentController !== oldValue else { return }
            queryChangeSearch()
        }
    }

    private func getContentViewController(at tab: SearchTab, tabConfig: SearchTabConfigurable?) -> SearchContentContainer {
        let contentVC = makeSearchContentViewController(for: tab, tabConfig: tabConfig)
        contentVC.listView().clipsToBounds = true
        return contentVC
    }

    private func makeSearchContentViewController(for tab: SearchTab, tabConfig: SearchTabConfigurable?) -> SearchContentContainer {
        do {
            if tab == .calendar {
                return (try userResolver.resolve(assert: SearchDependency.self)).eventChildViewController(searchNavBar: searchNaviBar)
            }
            if tab == .email {
                return (try userResolver.resolve(assert: SearchDependency.self)).getEmailSearchViewController(searchNavBar: searchNaviBar)
            }
            if let config = tabConfig {
                let container = try SearchContentDependencyContainer(userResolver: userResolver,
                                                                     sharedRootViewModel: viewModel,
                                                                     tab: tab,
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

    private func editMoretab() {
        Navigator.shared.present(
            SearchMainTabManagerViewController(userResolver: userResolver),
            wrap: LkNavigationController.self, from: self,
            prepare: { $0.modalPresentationStyle = .formSheet },
            animated: true)
    }

    // MARK: user interaction
    @objc
    private func moreTabClickAction() {
        var isCache: Bool?
        if let service = searchOuterService, service.enableUseNewSearchEntranceOnPad() {
            isCache = service.currentIsCacheVC()
        }
        SearchTrackUtil.trackCapsuleMoreTabClick(query: self.getCurrentQuery(),
                                                 sessionID: self.searchSession.capture().session,
                                                 imprID: self.searchSession.capture().imprID,
                                                 sceneType: "main",
                                                 searchLocation: self.capsuleViewModel.capsulePage.tabConfig?.searchLocation ?? "",
                                                 slashID: nil,
                                                 isCache: isCache)
        showMoreTabView(showAdvancedSearch: true, currentTab: .main)
    }

    private var searchPopupHelper: SearchPopupHelper?
    private func showMoreTabView(showAdvancedSearch: Bool, currentTab: SearchTab) {
        searchField.resignFirstResponder()
        let tabTypes = self.viewModel.tabTypes.filter { tab in
            switch tab {
            case .main:
                return false
            default:
                return true
            }
        }

        let contentView = SearchSelectTabView(frame: .zero,
                                              dataSource: tabTypes,
                                              filterCount: self.capsuleViewModel.capsulePage.selectedFilters.count,
                                              selectedTab: currentTab,
                                              showAdvancedSearch: showAdvancedSearch)
        let popupContainer = SearchPopupHelper()
        self.searchPopupHelper = popupContainer
        contentView.closeTapEvent.rx.event.asDriver()
            .drive(onNext: { [weak popupContainer] _ in
                popupContainer?.dismiss(completion: {})
            }).disposed(by: disposeBag)

        contentView.editButton.rx.controlEvent(.touchUpInside)
            .asDriver()
            .drive(onNext: { [weak self, weak popupContainer] (_) in
                guard let self = self, let container = popupContainer else { return }
                container.dismiss { [weak self] in
                    guard let innerSelf = self else { return }
                    innerSelf.editMoretab()
                }
            }).disposed(by: disposeBag)
        contentView.advancedSearchButton.rx.controlEvent(.touchUpInside)
            .asDriver()
            .drive(onNext: { [weak self, weak popupContainer] (_) in
                guard let self = self, let container = popupContainer else { return }
                self.trackAdvanceSearchClick()
                container.dismiss { [weak self] in
                    guard let innerSelf = self else { return }
                    innerSelf.capsuleViewModel.showAdvancedSearchVC()
                }
            })
            .disposed(by: disposeBag)
        contentView.itemSelect.drive(onNext: { [weak self, weak popupContainer] selectTab in
            guard let self = self, let targetTab = selectTab, let container = popupContainer else { return }
            if currentTab != .main {
                var capsuleStatus: [String: Any] = [:]
                capsuleStatus["capsule_type"] = "tab"
                capsuleStatus["capsule_value"] = ["tab_name": targetTab.trackRepresentation]
                self.trackCapsuleClick(pos: 0, capsuleStatus: capsuleStatus)
            }
            container.dismiss(completion: {})
            let query = self.getCurrentQuery()
            let input = SearcherInput(query: query)
            let routeParam = SearchRouteParam(type: targetTab, input: input)
            self.route(withParam: routeParam)
        }).disposed(by: disposeBag)

        popupContainer.show(sourceVC: self, contentView: contentView)
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

    private func filtersChangeSearch(filters: [SearchFilter]) {
        guard let current = currentController as? SearchContentContainer else { return }
        current.filtersChange(filters: filters)
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

extension SearchMainRootViewController {
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

extension SearchMainRootViewController: SearchBarTransitionTopVCDataSource {
    public var searchBar: SearchBar { return self.searchNaviBar.searchbar }
    public var bottomView: UIView { return contentContainer }
}

extension SearchMainRootViewController: UITextFieldDelegate {}
extension SearchMainRootViewController: UIGestureRecognizerDelegate {}
