//
//  SearchInChatViewController.swift
//  LarkSearch
//
//  Created by zc09v on 2018/8/17.
//

import UIKit
import Foundation
import Homeric
import LarkUIKit
import RxSwift
import RxCocoa
import LarkCore
import UniverseDesignToast
import LarkModel
import SnapKit
import LKCommonsTracker
import EENavigator
import LarkStorage
import LarkSearchFilter
import LarkSDKInterface
import LarkMessengerInterface
import LarkSegmentedView
import LarkKeyboardKit
import LarkFeatureGating
import LarkSearchCore
import LarkOpenChat
import UniverseDesignTabs
import LarkContainer
import LarkPerf

struct SearchInChatVCConifg {
    let type: SearchInChatType
    let searchWhenEmpty: Bool
    let defaultDataSearchScene: SearchScene?
    let placeHolderType: SearhInChatEmptyDataViewType
    let placeHolderText: String
    let searchScene: SearchScene
    let supportedFilters: [SearchFilter]
    let cellType: UITableViewCell.Type
}

final class SearchInChatViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate,
                                  UDTabsListContainerViewDelegate, SearchInChatFilterBarDelegate, TrackInfoRepresentable, UserResolverWrapper {
    private let config: SearchInChatVCConifg
    private let viewModel: SearchInChatViewModel

    // 埋点用
    var currentFilters: [SearchFilter] { return filterView?.filters ?? [] }
    private(set) var lastestSearchCapture: SearchSession.Captured
    private var isNewSearch = true
    private let resultShowTrackManager = SearchResultShowTrackMananger()
    private var currentPage = 1

    var currentQuery: String { return searchTextField.text ?? "" }

    var draggingDriver: Driver<Bool> {
        return draggingVariable.asDriver()
    }
    private var draggingVariable: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    private var didScrollSubject: PublishSubject<Void> = PublishSubject()

    let chatID: String
    let chatType: Chat.TypeEnum?
    let isThreadGroup: Bool? // 是否为话题群
    private let searchSession: SearchSession
    private let router: SearchInChatRouter
    let enableMindnote: Bool
    let enableBitable: Bool
    let disposeBag = DisposeBag()
    private var toastOff: Bool

    /// 是否隐藏搜索栏以及 FilterBar
    private let disableSearchAndFilterBar: Bool
    /// Search Bar以下的内容视图
    private let contentContainer = UIView()

    /// 点击展示更多数据时候加载动画
    var activityIndicatorView: UIActivityIndicatorView?
    /// search Bar之上的控制器
    weak var containerViewController: UIViewController?
    var contentTopMargin: CGFloat?
    /// 是否是独立页面
    private let isSingle: Bool
    // 独立展示时用naviBar, 嵌套入chatContainer时用Wrapper, 样式目前有细微差别
    private lazy var searchNaviBar = SearchNaviBar(style: .search)
    private lazy var searchWrapper = SearchUITextFieldWrapperView()
    private var searchTextField: SearchUITextField!
    private var filterView: SearchFilterBar?
    private let resultView = SearchResultView(tableStyle: .plain)
    private var dataTableView: UITableView { return resultView.tableview }
    private let placeHolderView: SearhInChatEmptyDataView
    private var isFirstAppear = true
//    private let emptyDataView: SearhInChatEmptyDataView
    private var currentInChatData = SearchInChatData(searchParam: SearchParam.empty,
                                                     cellViewModels: [],
                                                     hasMore: false) {
        didSet {
            for model in currentInChatData.cellViewModels {
                model.fromVC = self
            }
        }
    }

    private lazy var isHasThread = { () -> Bool in
        if currentInChatData != nil {
            return currentInChatData.cellViewModels
                    .hasThread
        } else {
            return false
        }
    }()

    #if DEBUG || INHOUSE || ALPHA
    // debug悬浮按钮
    private let debugButton: ASLFloatingDebugButton
    #endif

    let userResolver: UserResolver
    init(userResolver: UserResolver,
         config: SearchInChatVCConifg,
         chatId: String,
         chatType: Chat.TypeEnum?,
         searchSession: SearchSession,
         searchCache: SearchCache,
         isSingle: Bool = false,
         isMeetingChat: Bool,
         searchAPI: SearchAPI,
         chatAPI: ChatAPI,
         router: SearchInChatRouter,
         enableMindnote: Bool,
         enableBitable: Bool,
         disableSearchAndFilterBar: Bool = false,
         isThreadGroup: Bool? = nil) {
        self.userResolver = userResolver
        self.config = config
//        self.emptyDataView = SearhInChatEmptyDataView.searchStyle(
//            title: BundleI18n.LarkSearch.Lark_Legacy_PullEmptyResult,
//            type: config.placeHolderType)
        self.isSingle = isSingle
        self.chatID = chatId
        self.chatType = chatType
        self.isThreadGroup = isThreadGroup
        self.searchSession = searchSession
        self.router = router
        self.enableMindnote = enableMindnote
        self.enableBitable = enableBitable
        self.lastestSearchCapture = searchSession.capture()
        let context = SearchInChatViewModelContext(userResolver: userResolver, chatId: chatId, chatType: chatType)
        self.disableSearchAndFilterBar = disableSearchAndFilterBar
        viewModel = SearchInChatViewModel(userResolver: userResolver,
                                          chatId: chatId,
                                          config: config,
                                          searchSession: searchSession,
                                          searchCache: searchCache,
                                          isMeetingChat: isMeetingChat,
                                          searchAPI: searchAPI,
                                          chatAPI: chatAPI,
                                          router: router,
                                          context: context)
        placeHolderView = SearhInChatEmptyDataView.searchStyle(title: config.placeHolderText, type: config.placeHolderType)
        self.toastOff = SearchFeatureGatingKey.searchToastOff.isUserEnabled(userResolver: userResolver)
        #if DEBUG || INHOUSE || ALPHA
        self.debugButton = ASLFloatingDebugButton()
        #endif
        if #available(iOS 13.0, *) {
            self.activityIndicatorView = UIActivityIndicatorView(style: .medium)
        }

        super.init(nibName: nil, bundle: nil)

        self.viewModel.searchInChatWidthGetter = { [weak self] in
            return self?.view.frame.width ?? 0
        }
        context.clickInfo = { [weak self] in
            return SearchInChatViewModelContext.ClickInfo(sessionId: self?.viewModel.seqID.session,
                                                          imprId: self?.viewModel.seqID.imprID,
                                                          query: self?.searchTextField.text,
                                                          searchLocation: self?.config.type.trackRepresentation,
                                                          filters: self?.currentFilters ?? [],
                                                          tableView: self?.dataTableView)
        }

        if !config.supportedFilters.isEmpty {
            self.filterView = SearchInChatFilterBar(userResolver: userResolver, filters: config.supportedFilters, delegate: self)
        }

        searchNaviBar.searchbar.searchTextField.autocorrectionType = .no
        if isSingle {
            searchTextField = searchNaviBar.searchbar.searchTextField
        } else {
            searchTextField = searchWrapper.searchUITextField
        }

        if KeyboardKit.shared.keyboardType == .hardware {
            self.searchTextField.autoFocus = true
        }
        resultView.containerVC = self
    }

    deinit {
        resultShowTrackManager.track(searchLocation: config.type.trackRepresentation,
                                     query: searchTextField.text ?? "",
                                     sceneType: "chat",
                                     session: searchSession,
                                     filterStatus: currentFilters.withNoFilter ? .none : .some(currentFilters.convertToFilterStatusParam()),
                                     offset: currentPage,
                                     shouldShowIdList: false,
                                     chatId: chatID,
                                     chatType: chatType,
                                     isThreadGroup: isThreadGroup,
                                     isHasThread: isHasThread)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 只有占位图，且没有数据时，弹起键盘
        if currentInChatData.cellViewModels.isEmpty {
            if presentedViewController == nil,
                !self.disableSearchAndFilterBar,
                isFirstAppear,
                self.config.type == .message {
                searchTextField.becomeFirstResponder()
            }
        }
        // 加载缓存的场景，不进行空query加载
        /// single Tab刚进去需要重新发起一次搜索
        if (config.searchWhenEmpty && currentInChatData.cellViewModels.isEmpty) || isSingle {
            searchTextChanged()
        }
        isFirstAppear = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        searchTextField.resignFirstResponder()
        super.viewWillDisappear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        /// isSingle每次进入都重新发起一次搜索
        if !isSingle { viewModel.loadSearchCache() }

        view.backgroundColor = UIColor.ud.bgBody
        isNavigationBarHidden = isSingle

        searchTextField.canEdit = true
        searchTextField.placeholder = BundleI18n.LarkSearch.Lark_Legacy_SearchHint
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)

        #if DEBUG || INHOUSE || ALPHA
        // 初始化时读取默认状态
        self.debugButton.isHidden = !KVStores.SearchDebug.globalStore[KVKeys.SearchDebug.contextIdShow]
        // 之后通过通知传值
        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(swittchDebugButton(_:)),
                         name: NSNotification.Name(KVKeys.SearchDebug.contextIdShow.raw),
                         object: nil)
        resultView.addSubview(debugButton)
        viewModel
            .debugDataManager
            .getContextIDDriver()
            .drive(onNext: { [weak self] aslContextID in
                self?.debugButton.updateTitle(ContextID: aslContextID)
            }).disposed(by: disposeBag)
        #endif
        if disableSearchAndFilterBar {
            view.addSubview(contentContainer)
            contentContainer.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            resultView.loadingViewTopOffset = contentTopMargin ?? 0
            dataTableView.contentInset = UIEdgeInsets(top: contentTopMargin ?? 0, left: 0, bottom: 9, right: 0)

            self.didScrollSubject
                .throttle(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
                .asObservable()
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    if self.dataTableView.isDragging {
                        self.draggingVariable.accept(true)
                    }
                })
                .disposed(by: disposeBag)
        } else {
            let topView = setupTopView()
            view.addSubview(contentContainer)
            contentContainer.snp.makeConstraints {
                $0.left.right.bottom.equalToSuperview()
                $0.top.equalTo(topView.snp.bottom)
            }
        }

        let topConstraint = setupFilters()

        dataTableView.delegate = self
        dataTableView.dataSource = self
        dataTableView.estimatedRowHeight = 68
        dataTableView.rowHeight = UITableView.automaticDimension
        activityIndicatorView?.hidesWhenStopped = true
        activityIndicatorView?.frame = CGRect(x: 0, y: 0, width: dataTableView.bounds.width, height: 44)
        dataTableView.tableFooterView = activityIndicatorView
        let searchCellID = String(describing: config.cellType)
        dataTableView.register(config.cellType, forCellReuseIdentifier: searchCellID)
        contentContainer.addSubview(resultView)

        resultView.snp.makeConstraints { make in
            make.top.equalTo(topConstraint)
            make.left.right.bottom.equalToSuperview()
        }

        contentContainer.addSubview(placeHolderView)
        placeHolderView.snp.makeConstraints { (make) in
            make.top.equalTo(topConstraint)
            make.left.right.bottom.equalToSuperview()
        }

//        contentContainer.addSubview(emptyDataView)
//        emptyDataView.snp.makeConstraints { (make) in
//            make.top.equalTo(topConstraint)
//            make.left.right.bottom.equalToSuperview()
//        }

        viewModel.stateObservable
            .subscribe(onNext: { [weak self] (state) in
                guard let self = self else { return }
                self.configViewHidden(state: state)
                switch state {
                case .placeHolder:
                    break
                case .searching:
                    self.resultView.status = .loading
                case .result(let data, let text, let index, let info):
                    self.resultView.status = .result
                    if text == (self.searchTextField.text?.trimmingForSearch() ?? "") {
                        self.currentInChatData = data
                        self.dataTableView.reloadData()
                        // 只有从cache搜索过来index才会不为nil
                        if !self.disableSearchAndFilterBar, let lastVisitIndex = index, lastVisitIndex.row < self.currentInChatData.cellViewModels.count {
                            self.dataTableView.scrollToRow(at: lastVisitIndex, at: .top, animated: false)
                        }
                        // NOTE: load from cache will set state
                        self.filterView?.filters = data.searchParam.filters
                        self.searchTextField.text = data.searchParam.query
                        (self.containerViewController as? SearchInChatContainerViewController)?.searchQueryText = data.searchParam.query
                        if data.hasMore == true {
                            self.addBottomLoadMoreView()
                        }

                        self.dataTableView.endBottomLoadMore(hasMore: data.hasMore)
                        self.activityIndicatorView?.stopAnimating()
                        self.resultShowTrackManager.captured = self.viewModel.seqID
                        self.resultShowTrackManager.searchTimestamp = Int64(Date().timeIntervalSince1970 * 1000)
                        if let info = info, !info.isLoadMore, self.isNewSearch {
                            SearchTrackUtil.trackSearchReqeustClick(searchLocation: self.config.type.trackRepresentation,
                                                                    query: info.searchText, sceneType: "chat",
                                                                    sessionId: info.sessionID,
                                                                    filterStatus: info.filters.withNoFilter ? .none : .some(info.filters.convertToFilterStatusParam()),
                                                                    selectedRecFilter: info.filters.convertToSelectedRecommendFilterTrackingInfo(),
                                                                    imprID: self.viewModel.seqID.imprID, slashID: nil,
                                                                    chatId: self.chatID,
                                                                    chatType: self.chatType,
                                                                    isThreadGroup: self.isThreadGroup)
                        }
                        self.isNewSearch = false
                    }
                case .noResult(let text, let info):
                    self.resultView.status = .noResult(text)
                    if let info = info, !info.isLoadMore, self.isNewSearch {
                        SearchTrackUtil.trackSearchReqeustClick(searchLocation: self.config.type.trackRepresentation,
                                                                query: info.searchText, sceneType: "chat",
                                                                sessionId: info.sessionID,
                                                                filterStatus: info.filters.withNoFilter ? .none : .some(info.filters.convertToFilterStatusParam()),
                                                                selectedRecFilter: info.filters.convertToSelectedRecommendFilterTrackingInfo(),
                                                                imprID: self.viewModel.seqID.imprID,
                                                                slashID: nil,
                                                                chatId: self.chatID,
                                                                chatType: self.chatType,
                                                                isThreadGroup: self.isThreadGroup)
                    }
                    self.resultShowTrackManager.captured = self.viewModel.seqID
                    self.resultShowTrackManager.searchTimestamp = Int64(Date().timeIntervalSince1970 * 1000)
                    self.resultShowTrackManager.track(searchLocation: self.config.type.trackRepresentation,
                                                      query: self.searchTextField.text ?? "",
                                                      sceneType: "chat",
                                                      session: self.searchSession,
                                                      filterStatus: self.currentFilters.withNoFilter ? .none : .some(self.currentFilters.convertToFilterStatusParam()),
                                                      offset: self.currentPage,
                                                      isResult: false,
                                                      shouldShowIdList: false,
                                                      chatId: self.chatID,
                                                      chatType: self.chatType,
                                                      isThreadGroup: self.isThreadGroup,
                                                      isHasThread: self.isHasThread)
                    self.isNewSearch = false
                case .noResultForYear(let text):
                    self.resultView.status = .noResultForAYear(text)
                case .searchFail(let text, let isLoadMore):
                    if isLoadMore {
                        self.resultView.status = .result
                    } else {
                        self.resultView.status = .noResult(text)
                    }
                    if !self.toastOff {
                        UDToast.showFailure(with: BundleI18n.LarkSearch.Lark_Legacy_SearchFail, on: self.view)
                    }
                    self.resultShowTrackManager.captured = self.viewModel.seqID
                    self.resultShowTrackManager.searchTimestamp = Int64(Date().timeIntervalSince1970 * 1000)
                    self.resultShowTrackManager.track(searchLocation: self.config.type.trackRepresentation,
                                                      query: self.searchTextField.text ?? "",
                                                      sceneType: "chat",
                                                      session: self.searchSession,
                                                      filterStatus: self.currentFilters.withNoFilter ? .none : .some(self.currentFilters.convertToFilterStatusParam()),
                                                      offset: self.currentPage,
                                                      isResult: false,
                                                      shouldShowIdList: false,
                                                      chatId: self.chatID,
                                                      chatType: self.chatType,
                                                      isThreadGroup: self.isThreadGroup,
                                                      isHasThread: self.isHasThread)
                    self.dataTableView.endBottomLoadMore(hasMore: isLoadMore)
                    self.activityIndicatorView?.stopAnimating()
                }
            })
            .disposed(by: disposeBag)
    }

    private func setupTopView() -> UIView {
        if isSingle {
            searchNaviBar.searchbar.cancelButton.rx.tap
                .bind(onNext: { [weak self] in self?.cancelPage() })
                .disposed(by: disposeBag)
            view.addSubview(searchNaviBar)
            searchNaviBar.snp.makeConstraints { (make) in
                make.left.top.right.equalToSuperview()
            }
            return searchNaviBar
        } else {
            view.addSubview(searchWrapper)
            searchWrapper.snp.makeConstraints({ make in
                make.top.equalToSuperview().offset(8)
                make.left.right.equalToSuperview()
            })
            return searchWrapper
        }
    }
    /// return bottom ConstraintItem
    private func setupFilters() -> ConstraintItem {
        if self.disableSearchAndFilterBar { return self.contentContainer.snp.top }
        if isSingle && config.type == .file {
            let tipView = UIView()
            // TODO: 现在只有搜索all，以后加filter再来改
            let tipLabel = UILabel()
            tipLabel.text = BundleI18n.LarkSearch.Lark_Legacy_AllFilesTitle
            tipLabel.textColor = UIColor.ud.textCaption
            tipLabel.font = UIFont.systemFont(ofSize: 14.0)
            contentContainer.addSubview(tipView)
            tipView.addSubview(tipLabel)

            tipView.autoresizingMask = .flexibleWidth
            tipView.frame = contentContainer.bounds
            tipView.frame.size.height = 44

            tipLabel.snp.makeConstraints {
                $0.left.equalToSuperview().offset(16)
                $0.centerY.equalToSuperview()
            }

            let sepLine = UIView()
            sepLine.backgroundColor = UIColor.ud.lineDividerDefault

            let px = 1 / UIScreen.main.scale
            var frame = tipView.frame
            frame.origin.y = frame.size.height - px
            frame.size.height = px
            sepLine.frame = frame
            sepLine.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
            tipView.addSubview(sepLine)
            if let filterView = self.filterView {
                contentContainer.addSubview(filterView)
                filterView.snp.makeConstraints { (make) in
                    make.top.equalTo(tipView.snp.bottom)
                    make.left.right.equalToSuperview()
                    make.height.equalTo(50)
                }
                return filterView.snp.bottom
            }
            return tipView.snp.bottom
        } else if let filterView = self.filterView {
            contentContainer.addSubview(filterView)
            filterView.snp.makeConstraints { (make) in
                make.top.left.right.equalToSuperview()
                make.height.equalTo(50)
            }
            return filterView.snp.bottom
        } else {
            return contentContainer.snp.top
        }
    }

    private func configViewHidden(state: SearchInChatState) {
        switch state {
        case .searching, .result, .searchFail:
            resultView.isHidden = false
            placeHolderView.isHidden = true
//            emptyDataView.isHidden = true
        case .placeHolder:
            resultView.isHidden = true
            placeHolderView.isHidden = false
//            emptyDataView.isHidden = true
        case .noResult, .noResultForYear:
            resultView.isHidden = false
            placeHolderView.isHidden = true
//            emptyDataView.isHidden = false
        }
    }

    #if DEBUG || INHOUSE || ALPHA
    @objc
    private func swittchDebugButton(_ notification: Notification) {
        if let isOn = notification.userInfo?["isOn"] as? Bool {
            self.debugButton.isHidden = !isOn
        }
    }
    #endif

    /// 输入框文本变化以及筛选器变化都会调用到这里
    @objc
    private func searchTextChanged() {
        if searchTextField.markedTextRange == nil {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(search), object: nil)
            self.perform(#selector(search), with: nil, afterDelay: SearchRemoteSettings.shared.searchDebounce)
        }
    }

    @objc
    private func search() {
        let param = SearchParam(query: searchTextField.text?.trimmingForSearch() ?? "", filters: filterView?.filters ?? [])
        (self.containerViewController as? SearchInChatContainerViewController)?.searchQueryText = searchTextField.text?.trimmingForSearch() ?? ""
        if viewModel.lastSearchParam == param { return } // 防重过滤

        resultView.tableview.addBottomLoadMoreView { [weak self] in
            guard let self = self else { return }
            self.currentPage += 1
            self.viewModel.loadMore(param: param)
        }
        viewModel.search(param: param)
        isNewSearch = true
        lastestSearchCapture = searchSession.capture()
        resultShowTrackManager.track(searchLocation: config.type.trackRepresentation,
                                     query: searchTextField.text ?? "",
                                     sceneType: "chat",
                                     session: searchSession,
                                     filterStatus: currentFilters.withNoFilter ? .none : .some(currentFilters.convertToFilterStatusParam()),
                                     offset: currentPage,
                                     shouldShowIdList: false,
                                     chatId: chatID,
                                     chatType: chatType,
                                     isThreadGroup: isThreadGroup,
                                     isHasThread: isHasThread)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentInChatData.cellViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellVM = currentInChatData.cellViewModels[indexPath.row]
        if let data = cellVM.data {
            cellVM.indexPath = indexPath
            let searchCellID = String(describing: config.cellType)
            let cell = tableView.dequeueReusableCell(withIdentifier: searchCellID, for: indexPath)
            if let cell = cell as? BaseSearchInChatTableViewCellProtocol {
                cell.update(viewModel: cellVM, currentSearchText: searchTextField.text ?? "")
            }
            resultShowTrackManager.willDisplay(result: data)
            return cell
        } else {
            if cellVM.useHotData == true {
                return ShowAllHotDataTipCell()
            } else {
                return ShowAllColdDataTipCell()
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        let cellVM = currentInChatData.cellViewModels[indexPath.row]
        if let data = cellVM.data {
            tableView.deselectRow(at: indexPath, animated: true)
            self.viewModel.saveSearchCache(visitedIndex: indexPath)
            cellVM.goNextPage()
            SearchTrackUtil.trackSearchResultClick(viewModel: cellVM,
                                                   sessionId: lastestSearchCapture.session,
                                                   searchLocation: viewModel.config.type.trackRepresentation,
                                                   isSmartSearch: false,
                                                   isSuggested: false,
                                                   query: searchTextField.text ?? "",
                                                   sceneType: "chat",
                                                   filterStatus: currentFilters.withNoFilter ? .none : .some(currentFilters.convertToFilterStatusParam()),
                                                   selectedRecFilter: currentFilters.convertToSelectedRecommendFilterTrackingInfo(),
                                                   imprID: lastestSearchCapture.imprID,
                                                   at: indexPath,
                                                   in: tableView,
                                                   chatId: chatID,
                                                   chatType: chatType,
                                                   isThreadGroup: isThreadGroup,
                                                   resultType: config.type)
            resultShowTrackManager.track(searchLocation: config.type.trackRepresentation,
                                         query: searchTextField.text ?? "",
                                         sceneType: "chat",
                                         session: searchSession,
                                         filterStatus: currentFilters.withNoFilter ? .none : .some(currentFilters.convertToFilterStatusParam()),
                                         offset: currentPage,
                                         shouldShowIdList: false,
                                         chatId: chatID,
                                         chatType: chatType,
                                         isThreadGroup: isThreadGroup,
                                         isHasThread: isHasThread)
        } else {
            /// cell 是数据底部的提示
            let cell = tableView.cellForRow(at: indexPath)
            if cellVM.useHotData == true {
                cell?.isHidden = true
                activityIndicatorView?.startAnimating()
                let param = SearchParam(query: searchTextField.text?.trimmingForSearch() ?? "", filters: filterView?.filters ?? [])
                viewModel.loadMore(param: param)
            } else if cellVM.useHotData == false {
                cell?.selectionStyle = .none
            }
        }
    }

    private func addBottomLoadMoreView() {

        let param = SearchParam(query: searchTextField.text?.trimmingForSearch() ?? "", filters: filterView?.filters ?? [])
        resultView.tableview.addBottomLoadMoreView { [weak self] in
            self?.currentPage += 1
            self?.viewModel.loadMore(param: param)
        }

    }
    func listDidAppear() {
        let lastSearchText = searchTextField.text
        if SearchFeatureGatingKey.inChatCompleteFilter.isEnabled {
            if !viewModel.whetherLoadFromCache {
                searchTextField.text = (self.containerViewController as? SearchInChatContainerViewController)?.searchQueryText ?? ""
                if lastSearchText != searchTextField.text {
                    searchTextChanged()
                }
            } else {
                // 退出会话再次进入，从缓存加载页面
                viewModel.whetherLoadFromCache = false
            }

        } else {
            if config.searchWhenEmpty, currentInChatData.cellViewModels.isEmpty {
                // 加载缓存的场景，不进行空query加载
                searchTextChanged()
            }
        }
    }

    func listDidDisappear() {
        resultShowTrackManager.track(searchLocation: config.type.trackRepresentation,
                                     query: searchTextField.text ?? "",
                                     sceneType: "chat",
                                     session: searchSession,
                                     filterStatus: currentFilters.withNoFilter ? .none : .some(currentFilters.convertToFilterStatusParam()),
                                     offset: currentPage,
                                     shouldShowIdList: false,
                                     chatId: chatID,
                                     chatType: chatType,
                                     isThreadGroup: isThreadGroup,
                                     isHasThread: isHasThread)
    }

    public func listView() -> UIView {
        return view
    }

    func cancelPage() {
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    var filterPageLocation: String? { "chat_history_message" }
    func filterBarDidChangeByUser(_ view: SearchFilterBar, changedFilter: SearchFilter?) {
        searchTextField.resignFirstResponder()
        searchTextChanged()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.didScrollSubject.onNext(Void())
    }
    private let inChatSearchScrollFPS = "inChatSearchScrollFPS"
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.draggingVariable.accept(false)
        }
        if SearchTrackUtil.enablePostTrack() != false {
            FPSMonitorHelper.shared.endTrackFPS(task: inChatSearchScrollFPS, bind: self)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.draggingVariable.accept(false)
        if SearchTrackUtil.enablePostTrack() != false {
            FPSMonitorHelper.shared.endTrackFPS(task: inChatSearchScrollFPS, bind: self)
        }
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard SearchTrackUtil.enablePostTrack() else { return }
        FPSMonitorHelper.shared.startTrackFPS(task: inChatSearchScrollFPS, bind: self) { (result) in
            if result.fps <= 0 { return }
            var categoryParams: [String: Any] = ["tab_name": self.config.type.trackRepresentation]
            if let lastRequestInfo = self.viewModel.lastRequestInfo {
                categoryParams["is_load_more"] = lastRequestInfo.isLoadMore
            }
            SearchTrackUtil.trackForStableWatcher(domain: "asl_chat_search",
                                                  message: "asl_search_fps",
                                                  metricParams: ["fps": ceil(result.fps)],
                                                  categoryParams: categoryParams)
        }
    }
}
/// in chat viewController，可以做为独立的页面展示，复用代码
extension SearchInChatViewController: SearchBarTransitionTopVCDataSource {
    public var searchBar: SearchBar { return self.searchNaviBar.searchbar }
    public var bottomView: UIView { return contentContainer }
}

extension SearchInChatViewController: SearchFromColdDataDelegate {
    func requestColdData() {
        /// 不能重新发起请求，使用loadMore
        let param = SearchParam(query: searchTextField.text?.trimmingForSearch() ?? "", filters: filterView?.filters ?? [])
        viewModel.loadMore(param: param)
        self.resultView.status = .loading
    }
}
// swiftlint:disable all
extension Array where Element == SearchInChatCellViewModel {
    var hasThread: Bool {
        for viewModel in self {
            if viewModel.data?.hasThread == true { return true }
        }
        return false
    }
}
// swiftlint:enable all
