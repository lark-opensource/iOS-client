//
//  File.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/6.
//

import UIKit
import LarkUIKit
import RxSwift
import Homeric
import EENavigator
import LarkKeyCommandKit
import Reachability
import LarkAlertController
import ESPullToRefresh
import RxRelay
import LarkSplitViewController
import UniverseDesignLoading
import UniverseDesignTheme

struct MailSearchConfig {}

protocol MailSearchViewControllerDelegate: AnyObject {
    func didCancelMailSearch()
}

public enum MailSearchScene {
    case inMailTab
    case inSearchTab // 邮箱搜索页嵌套进大搜
}

public final
class MailSearchViewController: MailBaseViewController, UITextFieldDelegate,
                                UITableViewDelegate, UITableViewDataSource,
                                MailSearchLongPressDelegate, MailSearchResultCellDelegate,
                                MailSearchHistoryViewDelegate, SearchBarTransitionTopVCDataSource,
                                MailSearchDataCenterDelegate, MailSearchHeaderViewDelegate,
                                MailSearchResultViewDelegate, MailLoadMoreRefreshDelegate,
                                MailMessageListExternalDelegate, MailCacheSettingDelegate {

    // data
    let disposeBag = DisposeBag()
    var mailThreadChangeBag = DisposeBag()
    var mailMultiThreadChangeBag = DisposeBag()
    let threadActionDataManager = ThreadActionDataManager()
    let factory: MailSearchResultFactory = MailSearchResultFactory()

    var selectedRows: [IndexPath] {
        selectedThreadIds.compactMap { searchViewModel.getCellIndexPath($0) }
    }
    var selectedThreadIds = [String]() {
        didSet {
            updateThreadActionBar()
        }
    }

    var markSelectedThreadId: String?
    var isShowingKeyboard = false
    var scene: MailSearchScene = .inMailTab

    // MARK: ViewModels
    lazy var searchViewModel: MailSearchViewModel = self.makeViewModel()
    let historyViewModel: MailSearchHistoryViewModel = MailSearchHistoryDataCenter()
    let page = SearchIntentionCapsulePage(lastInput: nil)
    let capsuleViewModel: SearchIntentionCapsuleViewModel


    // MARK: Views
    fileprivate var searchNaviBar: SearchNaviBar = {
        let bar = SearchNaviBar(style: .search)
        bar.backgroundColor = UIColor.ud.bgBody
        return bar
    }()
    var searchField: SearchUITextField { return searchNaviBar.searchbar.searchTextField }
    var historyView: MailSearchHistoryView = MailSearchHistoryView()
    let intentionCapsuleView: SearchIntentionCapsuleView
    lazy var moreMenuButton: UIButton = {
        let moreMenuButton = UIButton(frame: CGRect(x: 0, y: 0, width: 48, height: 40))
        moreMenuButton.layer.insertSublayer(moreMenuButtonGradientLayer, at: 0)
        moreMenuButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 12)
        moreMenuButton.setImage(UIImage(), for: UIControl.State.normal)
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

    // 搜索结果的view，tableview在里面
    lazy var resultView = MailSearchResultView(delegate: self, scene: self.scene, viewWidth: self.view.bounds.width)
    lazy var threadActionBar: ThreadActionsBar = {
        let actionBar = ThreadActionsBar(frame: .zero, accountContext: self.accountContext)
        actionBar.fromLabelID = searchLabel
        actionBar.actionDelegate = self
        return actionBar
    }()
    lazy var footer = MailLoadMoreRefreshAnimator(frame: CGRect(origin: .zero, size: .zero)) //CGSize(width: Display.width - 56, height: 30)))
    var fingerMoving = false
    lazy var searchHeaderView: MailSearchHeaderView = {
        let headerView = MailSearchHeaderView(reuseIdentifier: "MailSearchHeaderView")
        headerView.delegate = self
        return headerView
    }()
    var spinLoading: UDSpin?

    // MARK: Data
    weak var delegate: MailSearchViewControllerDelegate?
    lazy var commonSession: String = {
        let timeStamp = Date()
        let sessionID = Int.random(in: 0..<Int.max)
        let commonSession = String("\(Int(timeStamp.timeIntervalSince1970) + sessionID)_mail_search")
        searchViewModel.updateCommonSession(commonSession: commonSession)
        return commonSession
    }()
    var loadmorePages = [Int]()
    var remoteLoadmorePages = [Int]()
    var mixSearch: Bool {
        return Store.settingData.mailClient //&& scene == .inMailTab
    }
    var searchRemote = BehaviorRelay<Bool>(value: false)
    var searchRemoteDisposeBag = DisposeBag()
    var lastLocalResultIndex = 0
    var isMultiSelecting: Bool = false {
        didSet {
            MailLogger.info("[mail_search] isMultiSelecting: \(isMultiSelecting)")
            resultView.tableview.reloadData()
        }
    }
    var query: String?
    var loadMoreLock: Bool = false
    var priAccount: MailAccount?
    var searchLabel: String = Mail_LabelId_SEARCH
    var didConfigLoadMore = false

    let accountContext: MailAccountContext
    var senderBlocker: BlockSenderManager?

    // MARK: life Circle
    init(accountContext: MailAccountContext, config: MailSearchConfig, scene: MailSearchScene = .inMailTab) {
        self.accountContext = accountContext
        self.capsuleViewModel = SearchIntentionCapsuleViewModel(accountContext: accountContext, capsulePage: self.page)
        self.intentionCapsuleView = SearchIntentionCapsuleView(withViewModel: self.capsuleViewModel)
        super.init(nibName: nil, bundle: nil)
        self.scene = scene
    }

    init(accountContext: MailAccountContext, query: String?, searchNavBar: SearchNaviBar?) {
        self.accountContext = accountContext
        self.capsuleViewModel = SearchIntentionCapsuleViewModel(accountContext: accountContext, capsulePage: self.page)
        self.intentionCapsuleView = SearchIntentionCapsuleView(withViewModel: self.capsuleViewModel)
        super.init(nibName: nil, bundle: nil)
        self.scene = .inSearchTab
        if let searchBar = searchNavBar {
            self.searchNaviBar = searchBar
        }
        self.query = query
        self.shouldMonitorPermissionChanges = false

        NotificationCenter.default.rx
            .notification(Notification.Name.Mail.MAIL_SWITCH_ACCOUNT)
            .subscribe { [weak self] _ in
                self?.showDefaultSearchPage()
            }
            .disposed(by: disposeBag)

        Store.settingData
            .permissionChanges
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (permissionChange, needPopToMailHome) in
                guard let `self` = self else { return }
                MailLogger.info("[mail_search] permissionChange: \(permissionChange) needPopToMailHome: \(needPopToMailHome)")
                if needPopToMailHome { // TODO 对接UX最新交互
                    self.backToMailSearch(completion: { [weak self] in
                        guard let `self` = self else { return }
                        self.handlePermissChangeInLarkSearch(permissionChange)
                    })
                } else {
                    self.handlePermissChangeInLarkSearch(permissionChange)
                }
                self.showDefaultSearchPage()
        }).disposed(by: disposeBag)

        EventBus.accountChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                guard let `self` = self else { return }
                if case .shareAccountChange(let change) = push {
                    if change.isCurrent && !change.isBind {
                        self.backToMailSearch(completion: { [weak self] in
                            guard let `self` = self else { return }
                            let address = change.account.accountAddress
                            let alert = LarkAlertController()
                            alert.setContent(text: BundleI18n.MailSDK.Mail_PersonalAccountWithdrawn_Desc(address), alignment: .center)
                            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Common_OK_Button, dismissCompletion: nil)
                            accountContext.navigator.present(alert, from: self)
                        })
                        self.searchTextChanged(self.searchField.text)
                        if Display.pad {
                            accountContext.navigator.showDetail(SplitViewController.makeDefaultDetailVC(), wrap: LkNavigationController.self, from: self)
                        }
                    }
                } else if case .accountChange(let change) = push {
                    if self.priAccount?.mailSetting.userType != .noPrimaryAddressUser && change.account.isUnuse() {
                        self.priAccount = change.account
                        // 账号异常提示
                        let alert = LarkAlertController()
                        alert.setTitle(text: BundleI18n.MailSDK.Mail_SearchingMailError_Title)
                        let address = change.account.accountAddress
                        alert.setContent(text: BundleI18n.MailSDK.Mail_SearchingMailErrorContactAdmin_Desc(address), alignment: .center)
                        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Common_GotIt_Button, dismissCompletion: nil)
                        accountContext.navigator.present(alert, from: self)
                        self.searchTextChanged(self.searchField.text)
                    }
                }
            }).disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    func makeViewModel() -> MailSearchViewModel {
        /// 只有在邮箱Tab内打开搜索，并且确定是三方账号，开启了混合搜索fg才需要使用新接口
        if mixSearch {
            let center = MailClientSearchDataCenter()
            center.delegate = self
            return center
        } else {
            let settingConfig = accountContext.sharedServices.provider.settingConfig
            let preloadService = accountContext.sharedServices.preloadServices
            let center = MailSearchDataCenter(settingConfig: settingConfig,
                                              preloadServices: preloadService,
                                              useHistory: scene == .inMailTab)
            center.delegate = self
            return center
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        searchViewLog()
        addNotification()
        configUI()
        if mixSearch {
            bindMailClientData()
        } else {
            bindData()
        }
        if scene == .inMailTab {
            bindHistoryData()
            searchField.becomeFirstResponder() // 进入搜索页自动拉起键盘
        } else {
            trickSearchByQueryIfNeeded()
        }
    }

    func trickSearchByQueryIfNeeded() {
        if let query = query, !query.isEmpty, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.showSearchLoading()
            if let account = Store.settingData.getCachedCurrentAccount(), account.isValid() {
                self.priAccount = Store.settingData.getCachedPrimaryAccount()
                self.searchTextChanged(query)
            } else {
                if Store.settingData.ifNetSettingLoaded() {
                    self.hideLoading()
                    self.resultView.isHidden = false
                    self.resultView.status = .none
                } else {
                    Store.settingData
                        .netSettingPush
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] _ in
                            guard let `self` = self else { return }
                            self.priAccount = Store.settingData.getCachedPrimaryAccount()
                            guard let query = self.query else { return }
                            if query != self.searchField.text {
                                self.searchTextChanged(self.searchField.text)
                            } else {
                                self.searchTextChanged(query)
                            }
                    }).disposed(by: disposeBag)
                }
            }
        } else {
            showDefaultSearchPage()
        }
    }

    func showDefaultSearchPage() {
        self.hideLoading()
        self.resultView.isHidden = false
        self.resultView.status = .none
    }

    func backToMailSearch(completion: (() -> Void)? = nil) {
        if let presentingViewController = self.presentingViewController {
            if presentingViewController is MailSearchViewController {
                completion?()
                return
            }
            presentingViewController.dismiss(animated: true, completion: { [weak self] in
                self?.popToSearchVC()
                completion?()
            })
        } else if let presentedViewController = self.presentedViewController {
            presentedViewController.dismiss(animated: true, completion: { [weak self] in
                self?.popToSearchVC()
                completion?()
            })
        } else {
            popToSearchVC()
            completion?()
        }
    }

    func popToSearchVC() {
        let vcs = navigationController?.viewControllers ?? []
        for controller in vcs.reversed() {
            if needSkipPopDetect("\(controller.self)") {
                break
            } else {
                navigationController?.popViewController(animated: true)
            }
        }
    }

    func needSkipPopDetect(_ controllerStr: String) -> Bool {
        if Display.pad {
            return controllerStr.contains("LarkSearch.SearchMainContainerViewController")
        } else {
            return controllerStr.contains("LarkSearch.SearchRootViewController") || controllerStr.contains("LarkNavigation.MainTabbarController")
        }
    }

    func handlePermissChangeInLarkSearch(_ permissionChange: MailPermissionChangeStatus) {
        switch permissionChange {
        case .mailClientRevoke:
            self.alertHelper?.showRevokeMailClientConfirmAlert(confirmHandler: nil, fromVC: self)
        case .lmsRevoke:
            self.alertHelper?.showRevokeLMSConfirmAlert(confirmHandler: nil, fromVC: self)
        case .gcRevoke:
            self.alertHelper?.showRevokeGCConfirmAlert(confirmHandler: nil, fromVC: self)
        case .mailClientAdd:
            break
        case .lmsAdd(let emailAddress):
            self.alertHelper?.showLMSAddConfirmAlert(onboardEmail: emailAddress, fromVC: self)
        case .gcAdd:
            self.alertHelper?.showGCAddConfirmAlert(confirmHandler: nil, fromVC: self)
        case .apiMigration(let emailAddress):
            self.alertHelper?.showApiMigrationAlert(onboardEmail: emailAddress, confirmHandler: nil, fromVC: self)
        }
        if Display.pad {
            navigator?.showDetail(SplitViewController.makeDefaultDetailVC(), wrap: LkNavigationController.self, from: self)
        }
    }

    func updateSearchStatus(_ status: MailSearchHeaderStatus) {
        guard mixSearch else { return }
        self.searchHeaderView.status = status
        if status == .searching {
            self.showSearchHeaderView()
        } else {
            self.hideSearchHeaderView()
        }
    }

    func searchViewLog() {
        MailTracker.log(event: Homeric.ASL_SEARCH_VIEW, params: ["entry_action": "click", "search_bar": "email",
                                                                 "search_location": "emails",
                                                                 "search_session_id": commonSession,
                                                                 "request_timestamp": String(Int(Date().timeIntervalSince1970)),
                                                                 "scene_type": "component",
                                                                 "enter_type": self.apmEnterType()])
    }

    @objc
    func keyboardDidShow(_ note: Notification) {
        isShowingKeyboard = true
    }

    @objc
    func keyboardDidHide(_ note: Notification) {
        isShowingKeyboard = false
    }

    private func addNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        configListSyncObserve()
    }

    public override func viewDidTransition(to size: CGSize) {
        super.viewDidTransition(to: size)
        resultView.tableview.reloadData()
    }

    func updateThreadActionBar() {
        if selectedRows.count <= 0 {
            if isMultiSelecting {
                isMultiSelecting = false
            }
            threadActionBar.eraseThreadActions()
            threadActionBar.removeFromSuperview()
            if hasSearchFilter() {
                intentionCapsuleView.isHidden = false
                intentionCapsuleView.snp.updateConstraints { make in
                    make.height.equalTo(56)
                }
            }
            return
        }
        threadActionBar.eraseThreadActions()
        let searchResults = searchViewModel.allItems()
        // calculate thread actions here.
        var indexedActions = [MailIndexedThreadAction]()
        var allHasDraft = true

        for selectedRow in selectedRows {
            // must update every time because label always change when use operation.
            let fromLabelID: String = {
                if searchLabel == Mail_LabelId_SEARCH_TRASH_AND_SPAM,
                    let folder = MailTagDataManager.shared.getFolderModel(searchResults[selectedRow.row].viewModel.folders) {
                    return folder.id
                } else {
                    if let filter = capsuleViewModel.capsulePage.selectedFilters.first(where: { $0.tagID != nil }),
                       let tagID = filter.tagID {
                        return tagID
                    } else {
                        return Mail_LabelId_SEARCH
                    }
                    //return Mail_LabelId_SEARCH
                }
            }()
            let actions = MailThreadActionCalculator.calculateSearchThreadListThreadActions(cellViewModel: searchResults[selectedRow.row].viewModel,
                                                                                            fromLabel: fromLabelID)
            if searchResults[selectedRow.row].viewModel.hasDraft == false {
                allHasDraft = false
            }
            indexedActions.append(contentsOf: actions)
        }
        let needLimit = {
            if let filter = capsuleViewModel.capsulePage.selectedFilters.first(where: { $0.tagID != nil }),
               let tagID = filter.tagID {
                return ![Mail_LabelId_Trash, Mail_LabelId_Spam].contains(tagID)
            } else {
                return searchLabel == Mail_LabelId_SEARCH
            }
        }()
        if needLimit {
            indexedActions = MailThreadActionCalculator.getSearchMutilSelectThreadActions(indexedThreadActions: indexedActions) /// 搜索下的限制
        }
        if allHasDraft {
            indexedActions.removeAll { action in
                action.action == .emlAsAttachment
            }
        }
        threadActionBar.setThreadActions(indexedActions, scheduleSendCount: selectedRows.count, needUpdateUI: true)
        threadActionBar.updateTitle(selectedRows.count)
        updateActionsLabel()
        threadActionBar.threadIDs = selectedRows.map({ searchViewModel.getItem($0)?.viewModel.threadId ?? "" }).filter({ !$0.isEmpty })

        let models = selectedRows.compactMap({ searchViewModel.getItem($0)?.viewModel })
        let hasExtern = models.compactMap({$0.addressList}).flatMap({$0}).filter({$0.isExternal}).count > 0
        threadActionBar.spamAlertContent = SpamAlertContent(
            mailAddresses: models.compactMap({ $0.headFroms }).flatMap({$0}).filter({ !$0.isEmpty }),
            unauthorizedAddresses: models.compactMap({ $0.unauthorizedHeadFroms }).flatMap({$0}).filter({ !$0.isEmpty }),
            isAllAuthorized: false,
            shouldFetchUnauthorized: false,
            scene: .search,
            allInnerDomain: !hasExtern
        )
        // 取label的并集 待定 应该要用上了
        var flag = false
        let resultSet = selectedRows.reduce(Set<MailClientLabel>.init(), { (set, indexPath) -> Set<MailClientLabel> in
            var res: Set<MailClientLabel> = set
            let labels = searchViewModel.getItem(indexPath)?.viewModel.labels ?? []
            let tempSet = Set<MailClientLabel>(labels)
            if flag {
                res = res.union(tempSet)
            } else {
                res = tempSet
                flag = true
            }
            return res
        })
        threadActionBar.labelIds = Array(resultSet).map { $0.id }
    }

    // MARK: config
    func configUI() {
        view.backgroundColor = UIColor.ud.bgBody
        isNavigationBarHidden = true
        capsuleViewModel.superVC = self
        if scene == .inMailTab {
            view.addSubview(searchNaviBar)
            searchNaviBar.snp.makeConstraints { (make) in
                make.left.top.right.equalToSuperview()
            }
            // searchBar
            searchNaviBar.searchbar.cancelButton.rx.tap.asDriver()
                .drive(onNext: { [weak self] () in
                    guard let `self` = self else { return }
                    self.searchActionLog(.close)
                    self.searchViewModel.searchAbort()
                    if self.presentingViewController != nil {
                        self.dismiss(animated: true, completion: nil)
                    } else {
                        self.navigationController?.popViewController(animated: true)
                    }
                    self.delegate?.didCancelMailSearch()
                })
                .disposed(by: disposeBag)

            searchField.placeholder = BundleI18n.MailSDK.Mail_Search_SearchBarPlaceHolder
            searchField.delegate = self
            searchField.returnKeyType = .search
            searchField.enablesReturnKeyAutomatically = true
            searchField.rx.controlEvent([.editingChanged])
                .asObservable()
                .debounce(.milliseconds(200), scheduler: MainScheduler.instance).subscribe(onNext: { [weak self] _ in
                if let `self` = self {
                    self.searchTextChanged(self.searchField.text)
                }
                }).disposed(by: self.disposeBag)

            if hasSearchFilter() {
                view.addSubview(intentionCapsuleView)
                intentionCapsuleView.snp.makeConstraints({ make in
                    make.top.equalTo(searchNaviBar.snp.bottom)
                    make.left.right.equalToSuperview()
                    make.height.equalTo(56)
                })
            }

            // histryView
            historyView.delegate = self
            view.addSubview(historyView)
            historyView.snp.makeConstraints({ make in
                if hasSearchFilter() {
                    make.top.equalTo(intentionCapsuleView.snp.bottom)
                } else {
                    make.top.equalTo(searchNaviBar.snp.bottom)
                }
                make.left.right.bottom.equalToSuperview()
            })
//            let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapHandler))
//            tap.cancelsTouchesInView = false
//            historyView.addGestureRecognizer(tap)
        }

        // result
        resultView.isHidden = true
        resultView.tableview.delegate = self
        resultView.tableview.dataSource = self
        resultView.tableview.estimatedRowHeight = 67
        resultView.tableview.rowHeight = UITableView.automaticDimension
        resultView.tableview.alwaysBounceVertical = true
        resultView.tableview.contentInsetAdjustmentBehavior = .never // .automatic
        resultView.scene = scene
        self.view.addSubview(resultView)
        resultView.snp.makeConstraints({ make in
            if scene == .inMailTab {
                if hasSearchFilter() {
                    make.top.equalTo(intentionCapsuleView.snp.bottom)
                } else {
                    make.top.equalTo(searchNaviBar.snp.bottom)
                }
            } else {
                make.top.equalToSuperview()
            }
            make.left.right.bottom.equalToSuperview()
        })

        factory.createResultItems().forEach {
            resultView.tableview.register($1,
                                          forCellReuseIdentifier: $0)
        }
        let resultViewTap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapHandler))
        resultViewTap.cancelsTouchesInView = false
        resultView.addGestureRecognizer(resultViewTap)
    }

    func configLoadMoreIfNeeded() {
        guard !didConfigLoadMore else { return }
        footer.executeIncremental = 90 + view.safeAreaInsets.bottom
        footer.trigger = 90 + view.safeAreaInsets.bottom
        footer.delegate = self
        configLoadMore()
        didConfigLoadMore = true
    }

    func hideSearchHeaderView() {
        if !searchHeaderView.isHidden {
            self.searchHeaderView.isHidden = true
            self.searchHeaderView.isUserInteractionEnabled = false
            footer.isHidden = false
        }
    }

    func showSearchHeaderView() {
        if searchHeaderView.isHidden {
            self.searchHeaderView.isHidden = false
            self.searchHeaderView.isUserInteractionEnabled = true
            footer.isHidden = true
        }
    }

    func configLoadMore() {
        resultView.tableview.es.addInfiniteScrolling(animator: footer) { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.footer.isHidden {
                MailLogger.info("[mail_client_search] debugloadmore - addInfiniteScrolling block ⚠️")
                return
            }
            MailLogger.info("[mail_client_search] debugloadmore - addInfiniteScrolling remoteLoadmorePages: \(self.remoteLoadmorePages) nextBegin: \(self.searchViewModel.nextBegin)")
            // 这里有一个很坑的点，就是footer的滑动回调是比localResult最后一页返回结果要早的，就会导致错过触发在线搜索的机会
            if self.mixSearch {
                self.searchRemoteDisposeBag = DisposeBag()
                self.searchRemote.asObservable()
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] ready in
                        guard let `self` = self else { return }
                        if ready && self.clientCanSearchRemote() {
                            self.remoteLoadmorePages.append(self.searchViewModel.nextBegin)
                            self.searchViewModel.searchRemote(keyword: self.searchField.text ?? "",
                                                              begin: self.searchViewModel.nextBegin,
                                                              loadMore: true, debounceInterval: -1,
                                                              fromLabel: self.searchLabel)
                            self.searchRemote.accept(false)
                        }
                }).disposed(by: self.searchRemoteDisposeBag)
            }
            self.loadMoreIfNeeded()
        }
    }

    /// 绑定dataCenter数据
    func bindData() {
        capsuleViewModel.updatePullTabs()
        setupSubscribe()
        searchViewModel.refreshList.asDriver()
            .drive(onNext: { [weak self] (shouldRefresh) in
                if shouldRefresh {
                    self?.resultView.tableview.reloadData()
                }
        })
        searchViewModel.state.asDriver()
            .drive(onNext: { [weak self] (state) in
                guard let `self` = self else {
                    return
                }
                var hideLoading = true
                switch state {
                case .empty:
                    self.historyView.isHidden = true
                    self.resultView.isHidden = false
                    if !self.searchField.text.isEmpty && !(self.searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? false) {
                        hideLoading = false
                    }
                case .history:
                    if let reach = Reachability(), reach.connection == .none {
                        self.historyView.isHidden = true
                        self.showDefaultSearchPage()
                    } else {
                        self.historyView.isHidden = false
                        self.resultView.isHidden = true
                    }
                case .result(let state, let info):
                    self.historyView.isHidden = true
                    self.resultView.isHidden = false
                    switch state {
                    case .loading:
                        hideLoading = false
                        self.resultView.isHidden = true
                    case .result(let dataArray):
                        MailLogger.info("[mail_search] vc receive result dataArray \(dataArray.count) isLoadMore: \(info.isLoadMore) hasMore: \(info.hasMore) hasTrashOrSpam: \(info.hasTrashOrSpam)")
                        hideLoading = true
                        self.resultView.tableview.es.resetNoMoreData()
                        self.stopLoadingMore()
                        if !dataArray.isEmpty {
                            if !info.isLoadMore {
                                // new content search should scroll to top
                                self.resultView.tableview.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
                                MailTracker.log(event: Homeric.EMAIL_SEARCH_RESULT_SHOW, params: [MailTracker.searchSessionParamKey(): self.searchViewModel.searchSession.uuid])
                                self.searchShowLog(externalParmas: ["is_result": "True",
                                                                    "impr_id": self.searchViewModel.searchSession.uuid,
                                                                    "offset": self.searchViewModel.offset,
                                                                    "id_list": self.searchIDList(),
                                                                    "is_all_mail_loaded": !info.hasMore,
                                                                    "is_offline_search": info.offlineSearch,
                                                                    "search_type": self.scene == .inSearchTab ? "SEARCH" : "EMAIL_SEARCH",
                                                                    "is_trash_or_spam_show": info.hasTrashOrSpam ? "TRUE" : "FALSE",
                                                                    "is_trash_or_spam_list": self.searchLabel == Mail_LabelId_SEARCH_TRASH_AND_SPAM ? "TRUE" : "FALSE"])
                            }
                            self.resultView.status = .result
                            self.resultView.tableview.reloadData()
                        } else {
                            if info.hasMore && !self.loadmorePages.isEmpty {
                                /// 去除请求锁
                                self.loadmorePages.removeLast()
                            }
                        }
                        if !info.isLoadMore {
                            self.apmMarkSearchEnd(status: .status_success)
                        } else {
                            self.apmMarkSearchLoadMoreEnd(status: .status_success)
                        }
                        if info.offlineSearch {
                            self.resultView.status = .resultInOffline
                            self.configLoadMoreIfNeeded()
                            self.footer.canCacheMore = FeatureManager.open(.offlineCache, openInMailClient: false)
//                            self.footer.titleText = BundleI18n.MailSDK.Mail_OfflineSearch_NoMoreLocalMails_Text
                        } else {
                            self.configLoadMoreIfNeeded()
                            self.footer.canCacheMore = false
//                            self.footer.titleText = BundleI18n.MailSDK.Mail_ThreadList_NoMoreConversations
                        }
                        self.footer.checkTrashMail = info.hasTrashOrSpam
                        self.footer.canRetry = false
                        if !info.hasMore {
                            MailLogger.info("[mail_search] noticeNoMoreData ⚠️")
                            if self.scene == .inSearchTab && info.offlineSearch {
                                self.footer.hideNomoreTip()
                                //self.stopLoadingMore()
                            } else {
                                self.footer.showNoMore(animation: false)
                                self.resultView.tableview.es.noticeNoMoreData()
                            }
                        } else {
                            self.resultView.tableview.es.resetNoMoreData()
                        }
                        if info.hasMore && CGFloat(self.searchViewModel.allItems().count) * MailHomeControllerConst.CellHeight < self.view.bounds.height {
                            // 不满一屏自动触发一次
                            MailLogger.info("[mail_search] autoLoadMore ⚙️")
                            self.resultView.tableview.es.autoLoadMore()
                        }
                    case .noResult(let searchText):
                        MailLogger.info("[mail_search] vc receive noResult isLoadMore: \(info.isLoadMore) hasMore: \(info.hasMore) hasTrashOrSpam: \(info.hasTrashOrSpam) offlineSearch: \(info.offlineSearch) filters: \(capsuleViewModel.capsulePage.selectedFilters.count)")
                        hideLoading = true
                        // 展示无结果
                        if info.offlineSearch {
                            if info.hasTrashOrSpam {
                                self.resultView.status = .noNormalResultInOffline
                            } else {
                                self.resultView.status = capsuleViewModel.capsulePage.selectedFilters.isEmpty ?  .noResultInOffline : .noResultWithFilterInOffline
                            }
                        } else {
                            if info.hasTrashOrSpam {
                                self.resultView.status = .noNormalResult
                            } else {
                                self.resultView.status = capsuleViewModel.capsulePage.selectedFilters.isEmpty ? .noResult : .noResultWithFilter
                            }
                        }
                        if self.resultView.status != .noResultWithFilter && self.resultView.status != .noResultWithFilterInOffline {
                            self.resultView.refreshNoResultView(searchText)
                        }
                        self.searchShowLog(externalParmas: ["is_result": "False",
                                                            "impr_id": self.searchViewModel.searchSession.uuid,
                                                            "offset": self.searchViewModel.offset,
                                                            "id_list": self.searchIDList(),
                                                            "is_all_mail_loaded": !info.hasMore,
                                                            "is_offline_search": info.offlineSearch,
                                                            "search_type": self.scene == .inSearchTab ? "SEARCH" : "EMAIL_SEARCH",
                                                            "is_trash_or_spam_show": info.hasTrashOrSpam ? "TRUE" : "FALSE",
                                                            "is_trash_or_spam_list": self.searchLabel == Mail_LabelId_SEARCH_TRASH_AND_SPAM ? "TRUE" : "FALSE"])
                        if let account = Store.settingData.getCachedCurrentAccount(), account.isValid() {
                            self.apmMarkSearchEnd(status: .status_success)
                        }
                    case .fail(reason: _):
                        MailLogger.info("[mail_search] vc receive fail, info: \(info)")
                        hideLoading = true
                        if info.offlineSearch {
                            if !info.isLoadMore || self.searchViewModel.allItems().isEmpty {
                                self.resultView.status = .fail
                                self.resultView.tableview.es.stopLoadingMore()
                            } else {
                                self.resultView.status = .resultInOffline
                                self.footer.canRetry = true
                                self.resultView.tableview.es.noticeNoMoreData()
                            }
                        } else {
                            /// 在线搜过程中断网也要提示
                            if !info.isLoadMore {
                                self.resultView.status = .fail
                            } else {
                                if let reach = Reachability(), reach.connection == .none {
                                    self.footer.canRetry = true
                                    self.resultView.tableview.es.noticeNoMoreData()
                                } else {
                                    self.resultView.tableview.enableBottomLoadMore(true)
                                    self.resultView.tableview.es.stopLoadingMore()
                                }
                            }
                        }
                        if info.hasMore && !self.loadmorePages.isEmpty {
                            /// 去除请求锁
                            self.loadmorePages.removeLast()
                        }
                        self.apmMarkSearchEnd(status: .status_rust_fail)
                        self.apmMarkSearchLoadMoreEnd(status: .status_rust_fail)
                        InteractiveErrorRecorder.recordError(event: .search_error_page,
                                                             errorCode: .rust_error,
                                                             tipsType: .error_page)
                        MailTracker.log(event: "email_thread_list_load_error_view", params: ["search_type": self.scene == .inSearchTab ? "SEARCH" : "EMAIL_SEARCH"])
                    }
                case .clientResult(state: let state, info: let info):
                    break
                }
                self.loadingView.isHidden = hideLoading
                if hideLoading {
                    self.hideSearchLoading()
                } else {
                    self.showSearchLoading()
                }
                if !self.isMultiSelecting {
                    self.view.bringSubviewToFront(self.searchNaviBar)
                }
            }).disposed(by: disposeBag)
    }

    private func setupSubscribe() {
        capsuleViewModel.noticeSearchStart(input: SearcherInput(query: "", filters: []))
        // 选中筛选器发生变化
        capsuleViewModel.shouldChangeFilterToSearch
            .drive(onNext: { [weak self] filters in
                guard let self = self else { return }
                //self.filtersChangeSearch(filters: filters)
                MailLogger.info("[mail_search] shouldChangeFilterToSearch - filters: \(filters)")
                self.searchLabel = Mail_LabelId_SEARCH
                self._searchTextChanged(filters: filters)
            })
            .disposed(by: disposeBag)
        capsuleViewModel.shouldResignFirstResponder
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.searchField.resignFirstResponder()
            })
            .disposed(by: disposeBag)
//        capsuleViewModel.shouldTrackAdvancedSearchClick
//            .drive(onNext: { [weak self] _ in
//                guard let self = self else { return }
//                //self.trackAdvanceSearchClick()
//            }).disposed(by: disposeBag)
//        capsuleViewModel.shouldTrackCapsuleClick
//            .drive(onNext: { (_, capsuleStatus) in
//                //guard let self = self else { return }
//                //self.trackCapsuleClick(pos: pos, capsuleStatus: capsuleStatus)
//            })
//            .disposed(by: disposeBag)

//        capsuleViewModel.filterChange
//            .drive(onNext: { [weak self] (isAdd, searchFilter) in
//                guard let self = self else { return }
//                guard let searchFilter = searchFilter else { return }
//                //self.updateTabFilters(filter: searchFilter, isAdd: isAdd, selectedFilters: self.capsuleViewModel.capsulePage.selectedFilters)
//            })
//            .disposed(by: disposeBag)

//        capsuleViewModel.filterReset.drive(onNext: { [weak self] in
//            guard let self = self else { return }
////            self.viewModel.resetTabFilters()
//        })
//        .disposed(by: disposeBag)
    }


    func showSearchLoading() {
        if scene == .inSearchTab {
            if spinLoading == nil {
                spinLoading = UDLoading.presetSpin(color: .primary,
                                                   loadingText: BundleI18n.MailSDK.Mail_ASLMobile_Loading_Empty,
                                                   textDistribution: .horizonal)
                if let spinLoading = spinLoading {
                    view.addSubview(spinLoading)
                    spinLoading.snp.makeConstraints { (make) in
                        make.top.equalTo(35)
                        make.centerX.equalToSuperview()
                    }
                }
            }
        } else {
            showLoading()
        }
        if !self.isMultiSelecting {
            self.view.bringSubviewToFront(self.searchNaviBar)
            if intentionCapsuleView.isDescendant(of: view) {
                self.view.bringSubviewToFront(self.intentionCapsuleView)
            }
        }
    }

    func hideSearchLoading() {
        if scene == .inSearchTab {
            spinLoading?.removeFromSuperview()
            spinLoading = nil
        } else {
            hideLoading()
        }
        if !self.isMultiSelecting {
            self.view.bringSubviewToFront(self.searchNaviBar)
        }
    }
    
    func bindMailClientData() {
        MailLogger.info("[mail_client_search] bindMailClientData")
        searchViewModel.state.asDriver()
            .drive(onNext: { [weak self] (state) in
                guard let `self` = self else {
                    return
                }
                var hideLoading = true
                switch state {
                case .empty:
                    self.historyView.isHidden = true
                    self.resultView.isHidden = false
                case .history:
                    self.historyView.isHidden = false
                    self.resultView.isHidden = true
                case .result(let state, let info):
                    break
                case .clientResult(state: let state, info: let info):
                    self.historyView.isHidden = true
                    self.resultView.isHidden = false
                    self.updateSearchStatus(.searchFinish)
                    self.resultView.tableview.reloadData() //reloadSections([1], with: .none)
                    switch state {
                    case .loading:
                        MailLogger.info("[mail_client_search] vc receive clientResult state: loading")
                        if self.searchViewModel.strategy == .local {
                            hideLoading = false
                        } else {
                            hideLoading = true
                            self.updateSearchStatus(.searching)
                        }
                    case .localResult(let dataArray):
                        MailLogger.info("[mail_client_search] vc receive clientResult state: localResult, dataArray: \(dataArray.count) hasMore: \(info.hasMore) offlineSearch: \(info.offlineSearch)")
                        hideLoading = true
                        self.searchViewModel.removeAllRemoteResultItems()
                        self.updateSearchStatus(.search)
                        if !dataArray.isEmpty {
                            if !info.isLoadMore {
                                // new content search should scroll to top
                                self.resultView.tableview.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
                                MailTracker.log(event: Homeric.EMAIL_SEARCH_RESULT_SHOW, params: [MailTracker.searchSessionParamKey(): self.searchViewModel.searchSession.uuid])
                            }
                            self.searchShowLog(externalParmas: ["is_result": "True",
                                                                "impr_id": self.searchViewModel.searchSession.uuid,
                                                                "offset": self.searchViewModel.offset,
                                                                "id_list": self.searchIDList(),
                                                                "mail_search_type": "local_search",
                                                                "is_all_mail_loaded": !info.hasMore,
                                                                "is_offline_search": self.searchViewModel.strategy == .local,
                                                                "search_type": self.scene == .inSearchTab ? "SEARCH" : "EMAIL_SEARCH",
                                                                "is_trash_or_spam_show": info.hasTrashOrSpam ? "TRUE" : "FALSE",
                                                                "is_trash_or_spam_list": self.searchLabel == Mail_LabelId_SEARCH_TRASH_AND_SPAM ? "TRUE" : "FALSE"])
                            if info.offlineSearch {
                                self.resultView.status = .resultInOffline
                            } else {
                                self.resultView.status = .result
                            }
                            self.resultView.tableview.reloadData()
                            if !info.isLoadMore {
                                self.apmMarkSearchEnd(status: .status_success)
                            } else {
                                self.apmMarkSearchLoadMoreEnd(status: .status_success)
                            }
                        } else {
                            self.resultView.status = .result
                            self.resultView.tableview.reloadData()
                        }
                        self.stopLoadingMore()
                        if !info.hasMore {
                            // 记录本地结果最后一条是第几个
                            self.lastLocalResultIndex = self.searchViewModel.allItems().count - 1
                            // 不满一屏则直接发起，满一屏发起并加上debouce参数
                            if CGFloat(self.searchViewModel.allItems().count) * MailHomeControllerConst.CellHeight < self.view.bounds.height && self.clientCanSearchRemote() {
                                self.updateSearchStatus(.searching)
                                self.resultView.tableview.reloadData() //reloadSections([1], with: .none)
                                let debounceInterval = ProviderManager.default.commonSettingProvider?.IntValue(key: "auto_search_frequency") ?? 1000
                                self.searchViewModel.searchRemote(keyword: self.searchField.text ?? "",
                                                                  begin: self.searchViewModel.nextBegin,
                                                                  loadMore: true, debounceInterval: debounceInterval,
                                                                  fromLabel: self.searchLabel)
                            } else if self.clientCanSearchRemote() {
                                self.searchRemote.accept(true)// = true
                            } else {
                                // eas数据无更多
                                self.footer.checkTrashMail = info.hasTrashOrSpam
                                self.footer.canRetry = false
                                self.resultView.tableview.es.noticeNoMoreData()
                                self.footer.showNoMore(animation: true)
                            }
                        } else {
                            
                        }
                        self.configLoadMoreIfNeeded()
                    case .localNoResult(let searchText):
                        self.updateSearchStatus(.searchFinish)
                        MailLogger.info("[mail_client_search] vc receive clientResult state: localNoResult")
                        hideLoading = true
                        if self.searchViewModel.allItems().isEmpty {
                            self.resultView.tableview.reloadData()
                            if FeatureManager.open(.searchTrashSpam, openInMailClient: true) &&
                                Store.settingData.getCachedCurrentAccount()?.protocol == .exchange {
                                if info.offlineSearch {
                                    if info.hasTrashOrSpam {
                                        self.resultView.status = .noNormalResultInOffline
                                    } else {
                                        self.resultView.status = .noResultInOffline
                                    }
                                } else {
                                    if info.hasTrashOrSpam {
                                        self.resultView.status = .noNormalResult
                                    } else {
                                        self.resultView.status = .noResult
                                    }
                                }
                                self.resultView.refreshNoResultView(searchText)
                            } else {
                                if info.offlineSearch {
                                    self.resultView.status = .autoSearchRemoteInOffline
                                } else {
                                    self.resultView.status = .autoSearchRemote
                                }
                                self.searchViewModel.searchRemote(keyword: self.searchField.text ?? "",
                                                                  begin: self.searchViewModel.nextBegin,
                                                                  loadMore: true,
                                                                  debounceInterval: ProviderManager.default.commonSettingProvider?.IntValue(key: "auto_search_frequency") ?? 1000,
                                                                  fromLabel: self.searchLabel)
                            }
                        }
                    case .localFail(let reason):
                        MailLogger.info("[mail_client_search] vc receive clientResult state: localFail")
                        hideLoading = true
                        if !info.isLoadMore {
                            self.resultView.status = .retry
                        }
                        MailLogger.info("[mail_client_search] remoteResult noticeNoMoreData ⚠️")
                        self.footer.titleText = BundleI18n.MailSDK.Mail_ThirdClinet_NoMoreResults
                        self.footer.canRetry = false
                        self.resultView.tableview.es.noticeNoMoreData()
                        self.footer.showNoMore(animation: true)
                        
                        if info.offlineSearch {
                            if !info.isLoadMore || self.searchViewModel.allItems().isEmpty {
                                self.resultView.status = .failInOffline
                                self.resultView.tableview.es.stopLoadingMore()
                            } else {
                                self.resultView.status = .resultInOffline
                            }
                        } else {
                            self.resultView.status = .fail
                        }
                        self.apmMarkSearchEnd(status: .status_rust_fail)
                        self.apmMarkSearchLoadMoreEnd(status: .status_rust_fail)
                        InteractiveErrorRecorder.recordError(event: .search_error_page,
                                                             errorCode: .rust_error,
                                                             tipsType: .error_page)
                    case .remoteResult(let dataArray):
                        MailLogger.info("[mail_client_search] vc receive clientResult state: remoteResult, dataArray: \(dataArray.count) hasMore: \(info.hasMore)")
                        hideLoading = true
                        if !info.isLoadMore {
                            MailTracker.log(event: Homeric.EMAIL_SEARCH_RESULT_SHOW, params: [MailTracker.searchSessionParamKey(): self.searchViewModel.searchSession.uuid])
                        }
                        self.searchShowLog(externalParmas: ["is_result": "True",
                                                            "impr_id": self.searchViewModel.searchSession.uuid,
                                                            "offset": self.searchViewModel.offset,
                                                            "id_list": self.searchIDList(),
                                                            "mail_search_type": "online_search",
                                                            "is_all_mail_loaded": !info.hasMore,
                                                            "is_offline_search": self.searchViewModel.strategy == .local,
                                                            "search_type": self.scene == .inSearchTab ? "SEARCH" : "EMAIL_SEARCH",
                                                            "is_trash_or_spam_show": info.hasTrashOrSpam ? "TRUE" : "FALSE",
                                                            "is_trash_or_spam_list": self.searchLabel == Mail_LabelId_SEARCH_TRASH_AND_SPAM ? "TRUE" : "FALSE"])
                        if info.offlineSearch {
                            self.resultView.status = .resultInOffline
                        } else {
                            self.resultView.status = .result
                        }
                        self.resultView.tableview.reloadData()
                        if !info.hasMore {
                            self.footer.titleText = dataArray.isEmpty ? BundleI18n.MailSDK.Mail_ThirdClinet_NoMoreResults : BundleI18n.MailSDK.Mail_ThreadList_NoMoreConversations
                            MailLogger.info("[mail_client_search] remoteResult noticeNoMoreData ⚠️")
                            self.footer.checkTrashMail = info.hasTrashOrSpam
                            self.footer.canRetry = false
                            self.resultView.tableview.es.noticeNoMoreData()
                            self.footer.showNoMore(animation: true)
                        } else {
                            self.stopLoadingMore()
                        }
                        self.updateSearchStatus(.searchSuccess)
                        self.configLoadMoreIfNeeded()
                    case .remoteFail(let reason):
                        MailLogger.info("[mail_client_search] vc receive clientResult state: remoteFail")
                        hideLoading = true
                        self.updateSearchStatus(.searchFail)
                        if self.searchViewModel.allItems().isEmpty {
                            self.resultView.status = .noResult
                            self.resultView.refreshNoResultView(self.searchField.text ?? "")
                        } else {
                            self.stopLoadingMore()
                            if !info.hasMore {
                                self.footer.titleText = BundleI18n.MailSDK.Mail_ThirdClinet_NoMoreResults
                                self.footer.checkTrashMail = info.hasTrashOrSpam
                                self.footer.canRetry = false
                                //self.footer.showNoMore(animation: true)
                                self.resultView.tableview.es.noticeNoMoreData()
                                MailLogger.info("[mail_client_search] remoteFail noticeNoMoreData ⚠️")
                            } else {
                                if !self.remoteLoadmorePages.isEmpty {
                                    /// 去除请求锁
                                    self.remoteLoadmorePages.removeLast()
                                }
                            }
                        }
                    case .remoteNoResult:
                        MailLogger.info("[mail_client_search] vc receive clientResult state: remoteNoResult info: \(info)")
                        hideLoading = true
                        self.updateSearchStatus(.searchFinish)
                        if self.searchViewModel.allItems().isEmpty {
                            if info.offlineSearch {
                                if info.hasTrashOrSpam {
                                    self.resultView.status = .noNormalResultInOffline
                                } else {
                                    self.resultView.status = .noResultInOffline
                                }
                            } else {
                                if info.hasTrashOrSpam {
                                    self.resultView.status = .noNormalResult
                                } else {
                                    self.resultView.status = .noResult
                                }
                            }
                            self.resultView.refreshNoResultView(self.searchField.text ?? "")
                        } else {
                            self.stopLoadingMore()
                            self.resultView.tableview.es.resetNoMoreData()
                            self.footer.titleText = BundleI18n.MailSDK.Mail_ThirdClinet_NoMoreResults
                            self.footer.checkTrashMail = info.hasTrashOrSpam
                            self.footer.canRetry = false
                            self.resultView.tableview.es.noticeNoMoreData()
                            //self.footer.showNoMore(animation: true)
                            MailLogger.info("[mail_client_search] remoteNoResult noticeNoMoreData ⚠️")
                        }
                    }
                }
                self.loadingView.isHidden = hideLoading
                if hideLoading {
                    self.hideSearchLoading()
                } else {
                    self.showSearchLoading()
                }
            }).disposed(by: disposeBag)
    }

    // MARK: searchHistory
    func bindHistoryData() {
        historyViewModel.state.asDriver()
            .drive(onNext: { [weak self] (infos) in
                guard let `self` = self else { return }
                if infos.isEmpty {
                    self.historyView.bottomView.isHidden = true
                    self.historyView.backgroundColor = UIColor.ud.bgBody
                } else {
                    self.historyView.bottomView.isHidden = false
                    self.historyView.bottomView.set(historyInfos: Array(infos.prefix(10)))
                    self.historyView.backgroundColor = UIColor.ud.bgBase
                }
        }).disposed(by: disposeBag)

        historyViewModel.getSearchHistory()
    }
    
    func setNoNetBannerHidden(_ isHidden: Bool) {
//        lowNetworkBanner.isHidden = isHidden
        resultView.setNoNetBannerHidden(isHidden)
    }

    // MARK: ActionHandler
    @objc
    public func searchTextChanged(_ searchText: String? = nil) {
        if let text = searchText, text.isEmpty && capsuleViewModel.capsulePage.selectedFilters.isEmpty { // 大搜清空数据逻辑
            showDefaultSearchPage()
            searchViewModel.lastSearchText = ""
            return
        }
        guard !(searchText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? false) || !capsuleViewModel.capsulePage.selectedFilters.isEmpty else {
            return
        } // 空格搜索且没有筛选项才不处理
        searchLabel = Mail_LabelId_SEARCH
        _searchTextChanged(searchText)
    }

    func loadMoreCheckTrashMailHandler() {
        reloadTrashMailButtonHandler()
    }

    /// 支持已删除和垃圾邮件搜索
    func reloadTrashMailButtonHandler() {
        stopLoadingMore()
        resultView.tableview.es.resetNoMoreData()
        searchLabel = Mail_LabelId_SEARCH_TRASH_AND_SPAM
        // 再次请求
        self._searchTextChanged(self.searchField.text, forceResearch: true)
    }
    
    private func _searchTextChanged(_ searchText: String? = nil, filters: [MailSearchFilter]? = nil, forceResearch: Bool = false) {
        markSelectedThreadId = nil
        guard let account = Store.settingData.getCachedCurrentAccount(), account.isValid() else {
            if Store.settingData.clientStatus == .mailClient, scene == .inSearchTab {
                defaultSearchHandler(searchText ?? searchField.text)
            }
            return
        }
        if scene == .inSearchTab && (Store.settingData.getCachedPrimaryAccount()?.isUnuse() ?? false) {
            defaultSearchHandler(searchText ?? searchField.text)
            return
        }
        let originSearchText = searchField.text ?? ""
        let newSearchText = searchText ?? ""

        if searchField.markedTextRange == nil {
            if (!originSearchText.isEmpty || !newSearchText.isEmpty) ||
                !(filters ?? capsuleViewModel.capsulePage.selectedFilters).isEmpty {
                guard searchViewModel.lastSearchText != searchField.text ||
                        searchViewModel.lastSearchText != searchText || forceResearch ||
                        searchViewModel.scene != scene || filters != capsuleViewModel.capsulePage.selectedFilters else {
                    return
                }
                searchViewModel.scene = scene
                showSearchLoading()
                apmMarkSearchStart()
                resultView.isHidden = true
                if self.searchField.text == self.query {
                    self.query = nil
                }
            } else {
                resultView.isHidden = false
                resultView.status = .none
            }
            searchActionLog(.search_request,
                            externalParmas: ["is_trash_or_spam_list": searchLabel == Mail_LabelId_SEARCH_TRASH_AND_SPAM ? "True" : "False"])
            loadmorePages.removeAll()
            remoteLoadmorePages.removeAll()
            searchViewModel.removeAllResultItems()
            lastLocalResultIndex = 0
            resultView.tableview.reloadData()
            searchRemote.accept(false)
            footer.state = .pullToRefresh
            stopLoadingMore()
            resultView.tableview.es.resetNoMoreData()
            searchViewModel.search(keyword: searchText ?? searchField.text ?? "",
                                   filters: filters ?? capsuleViewModel.capsulePage.selectedFilters,
                                   begin: 0, loadMore: false,
                                   forceReload: forceResearch, fromLabel: searchLabel)
        }
    }
    
    func noNetworkBannerRetryHandler() {
        showSearchLoading()
        resultView.isHidden = true
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.large, execute: { [weak self] in
            guard let `self` = self else { return }
            self._searchTextChanged(self.searchField.text, forceResearch: true)
            if Display.pad {
                self.navigator?.showDetail(SplitViewController.makeDefaultDetailVC(), wrap: LkNavigationController.self, from: self)
            }
        })

    }
    
    func loadMoreRetryHandler() {
        MailLogger.info("[mail_search] loadMoreRetryHandler")
        footer.canRetry = false
        resultView.tableview.es.resetNoMoreData()
        resultView.tableview.es.autoLoadMore()
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.large, execute: { // 设计要求假loading一下
            self.loadMoreIfNeeded(canRetry: true)
        })
    }

    func loadMoreCacheMailHandler() {
        let cacheSettingVC: MailCacheSettingViewController = MailCacheSettingViewController(viewModel: MailSettingViewModel(accountContext: accountContext), accountContext: accountContext)
        cacheSettingVC.delegate = self
        cacheSettingVC.scene = .search
        let cacheSettingNav = LkNavigationController(rootViewController: cacheSettingVC)
        cacheSettingNav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        navigator?.present(cacheSettingNav, from: self)
    }
    
    func updateCacheRangeSuccess(accountId: String, expandPreload: Bool, offline: Bool, allowMobileTraffic: Bool) {
        MailCacheSettingViewController.changeCacheRangeSuccess(accountId: accountId, showProgrssBtn: false,
                                                               expandPreload: expandPreload, offline: offline,
                                                               allowMobileTraffic: allowMobileTraffic, view: self.view) { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    func defaultSearchHandler(_ searchText: String? = nil) {
        if let keyword = searchText, (!keyword.isEmpty || !capsuleViewModel.capsulePage.selectedFilters.isEmpty) {
            let reach = Reachability()
            let info = MailSearchInfo(offlineSearch: (reach?.connection ?? .wifi) == .none,
                                      isLoadMore: false, searchText: keyword, hasMore: false, hasTrashOrSpam: false)
            searchViewModel.removeAllResultItems()
            lastLocalResultIndex = 0
            resultView.tableview.reloadData()
            self.searchViewModel.state.accept(.result(state: .noResult(searchText: keyword), info: info))
        } else {
            showDefaultSearchPage()
        }
    }

    func stopLoadingMore() {
        MailLogger.info("[mail_search] debugloadmore stopLoadingMore ⏹")
        footer.isHidden = false
        resultView.tableview.es.stopLoadingMore()
        footer.hideLoading(animation: false)
    }

    @objc
    func backgroundTapHandler() {
        if isShowingKeyboard {
            self.searchField.resignFirstResponder()
        } else {
            let retryStatus = resultView.status == .retry
            if (resultView.status == .fail || retryStatus) && !resultView.isHidden {
                stopLoadingMore()
                searchActionLog(.search_request, externalParmas: ["is_trash_or_spam_list": searchLabel == Mail_LabelId_SEARCH_TRASH_AND_SPAM])
                loadmorePages.removeAll()
                remoteLoadmorePages.removeAll()
                if searchField.text != nil && !searchField.text!.isEmpty {
                    apmMarkSearchStart()
                }
                searchViewModel.search(keyword: searchField.text ?? "",
                                       filters: capsuleViewModel.capsulePage.selectedFilters,
                                       begin: 0, loadMore: false, forceReload: retryStatus, fromLabel: searchLabel)
            }
        }
    }

    func headerViewDidClickedSearch(_ headerView: MailSearchHeaderView, status: MailSearchHeaderStatus) {
        MailLogger.info("[mail_client_search] headerViewDidClickedSearch status: \(status)")
        switch status {
        case .search:
            if clientCanSearchRemote() {
                updateSearchStatus(.searching)
                searchViewModel.searchRemote(keyword: searchField.text ?? "", begin: searchViewModel.nextBegin, loadMore: false,
                                             debounceInterval: -1, fromLabel: searchLabel)
            }
        case .searchFail:
            if clientCanSearchRemote() {
                updateSearchStatus(.searching)
                searchViewModel.searchRemote(keyword: searchField.text ?? "", begin: searchViewModel.nextBegin, loadMore: true,
                                             debounceInterval: -1, fromLabel: searchLabel)
            }
        case .none, .searching, .searchSuccess, .searchFinish:
            break
        }
    }

    func clientCanSearchRemote() -> Bool {
        return !FeatureManager.open( .searchTrashSpam, openInMailClient: true) ||
        (FeatureManager.open( .searchTrashSpam, openInMailClient: true) &&
        Store.settingData.getCachedCurrentAccount()?.protocol != .exchange)
    }

    // MARK: UITextFieldDelegate
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let isOffline = (Reachability()?.connection ?? .wifi) == .none
        if searchViewModel.offlineSearch != isOffline {
            _searchTextChanged(searchField.text, forceResearch: true)
            if Display.pad {
                navigator?.showDetail(SplitViewController.makeDefaultDetailVC(), wrap: LkNavigationController.self, from: self)
            }
        }
        return true
    }

    // MARK: Tableview UITableViewDelegate
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !isMultiSelecting, let selectedRows = tableView.indexPathsForSelectedRows {
            for selectedRow in selectedRows where selectedRow != indexPath {
                tableView.deselectRow(at: selectedRow, animated: false)
            }
        }
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard let cell = tableView.cellForRow(at: indexPath) as? MailSearchTableViewCellProtocol else {
            return
        }

        MailTracker.log(event: Homeric.EMAIL_SEARCH_RESULT_SELECTED,
                        params: [
                            MailTracker.searchSessionParamKey(): self.searchViewModel.searchSession.uuid,
                            MailTracker.searchIndexParamKey(): indexPath.row])
        cell.setSelected(true, animated: true)
        if isMultiSelecting {
            let limitCount = 100
            if selectedRows.count >= limitCount {
                let text = BundleI18n.MailSDK.Mail_Toast_Select_more_label(limitCount)
                MailRoundedHUD.showTips(with: text, on: self.view)
                cell.setSelected(false, animated: false)
            } else {
                cell.setSelected(true, animated: false)
                if let selectedThreadId = searchViewModel.getItem(indexPath)?.viewModel.threadId {
                    selectedThreadIds.append(selectedThreadId)
                }
            }
        } else {
            // searchResultItems[indexPath.row].viewModel.isRead = true

            enterThread(indexPath, cell: cell)

            // history
            if let text = searchField.text, !text.isEmpty {
                historyViewModel.save(info: MailSearchHistoryView.HistoryItem(keyword: text))
            }
            if !rootSizeClassIsSystemRegular {
                cell.setSelected(false, animated: false)
            }
        }
    }

    func enterThread(_ indexPath: IndexPath, cell: MailSearchTableViewCellProtocol) {
        if let cellVM = cell.vm {
            markSelectedThreadId = cellVM.threadId
            let fromLabelID: String = {
                if let filter = capsuleViewModel.capsulePage.selectedFilters.first(where: { $0.tagID != nil }),
                   let tagID = filter.tagID {
                    return tagID
                } else {
                    return searchLabel
                }
            }()
            let labelItem = scene == .inSearchTab ? "SEARCH" : "EMAIL_SEARCH"
            if cellVM.msgNum == 0 {
                let mailSendVC =
                    MailSendController.makeSendNavController(
                        accountContext: accountContext,
                        threadID: cellVM.threadId,
                        action: .draft,
                        labelId: fromLabelID,
                        statInfo: MailSendStatInfo(from: .search, newCoreEventLabelItem: labelItem),
                        shouldMonitorPermissionChanges: false)
                navigator?.present(mailSendVC, from: self)
            } else {
                let searchList = searchViewModel.allItems().map { $0.viewModel }
                var statInfo = MessageListStatInfo(from: .search, newCoreEventLabelItem: labelItem)
                statInfo.fromString = labelItem
                let searchHintFrom = searchViewModel.getItem(indexPath)?.info.hintFromResult() ?? ""
                statInfo.searchHintFrom = searchHintFrom
                statInfo.isTrashOrSpamList = searchLabel == Mail_LabelId_SEARCH_TRASH_AND_SPAM ? "True" : "False"
                let keyword = cellVM.highlightString.reduce("") { (partialResult, temp) -> String in
                    return partialResult + " " + temp
                }
                let mailMessageVC = MailMessageListController.makeForSearch(accountContext: accountContext,
                                                                            searchList: searchList,
                                                                            threadId: cellVM.threadId,
                                                                            labelId: fromLabelID,
                                                                            keyword: keyword,
                                                                            subjects: cellVM.highlightSubject,
                                                                            statInfo: statInfo,
                                                                            externalDelegate: self)
                mailMessageVC.shouldMonitorPermissionChanges = false
                if fromLabelID == Mail_LabelId_SEARCH || fromLabelID == Mail_LabelId_SEARCH {
                    mailMessageVC.needRelocateCurrentLabel = true
                }
                let searchFolderTag: String = {
                    if searchLabel == Mail_LabelId_SEARCH_TRASH_AND_SPAM,
                        let folder = MailTagDataManager.shared.getFolderModel(cellVM.folders) {
                        return folder.id
                    } else {
                        return Mail_LabelId_SEARCH
                    }
                }()
                mailMessageVC.searchFolderTag = searchFolderTag
                mailMessageVC.backCallback = { [weak self] in
                    if self?.rootSizeClassIsRegular == false {
                        self?.markSelectedThreadId = nil
                    }
                }
                self.searchActionLog(.result_click, externalParmas: ["entity_id": cellVM.threadId,
                                                                     "label_items": searchViewModel.getItem(indexPath)?.viewModel.labelItems() ?? "",
                                                                     "pos": indexPath.row + 1,
                                                                     "result_hint_from": searchHintFrom,
                                                                     "search_type": self.scene == .inSearchTab ? "SEARCH" : "EMAIL_SEARCH",
                                                                     "is_offline_search": searchViewModel.offlineSearch,
                                                                     "is_trash_or_spam_list": searchLabel == Mail_LabelId_SEARCH_TRASH_AND_SPAM ? "True" : "False"])

                if Display.pad {
                    navigator?.showDetail(mailMessageVC, wrap: MailMessageListNavigationController.self, from: self)
                } else {
                    navigator?.push(mailMessageVC, from: self)
                }
            }
        }
    }

    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isMultiSelecting {
            if let selectedThreadId = searchViewModel.getItem(indexPath)?.viewModel.threadId {
                selectedThreadIds.lf_remove(object: selectedThreadId)
            }
            return
        }
    }

    public func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        if !isMultiSelecting, let selectedRows = tableView.indexPathsForSelectedRows {
            guard !selectedRows.isEmpty, selectedRows.count == 1 else {
                mailAssertionFailure("tableView indexPathsForSelectedRows is empty, but call willDeselectRowAt function")
                return indexPath
            }
            guard indexPath.row < searchViewModel.getResultItems().count else { return indexPath }
            if let isRead = searchViewModel.getItem(indexPath)?.viewModel.isRead, !isRead {
                guard let cell = tableView.cellForRow(at: indexPath) as? MailSearchTableViewCellProtocol else {
                    return indexPath
                }
                cell.setSelected(true, animated: true)
                enterThread(indexPath, cell: cell)
            }
            return nil // iPad 已读选中后不允许反选
        } else {
            return indexPath
        }
    }

    // 加载更多
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !mixSearch && searchViewModel.trickLoadMore(indexPath) {
            loadMoreIfNeeded()
        }
    }

    func loadMoreIfNeeded(canRetry: Bool = false) {
        MailLogger.info("[mail_search] debugloadmore - remoteLoadmorePages: \(remoteLoadmorePages) nextBegin: \(searchViewModel.nextBegin)")
        if !loadmorePages.contains(searchViewModel.nextBegin) && searchViewModel.hasMore && searchViewModel.nextBegin != 0 {
            loadmorePages.append(searchViewModel.nextBegin)
            apmMarkSearchLoadMoreStart()
            if searchViewModel.strategy == .local {
                searchViewModel.search(keyword: searchField.text ?? "",
                                       filters: capsuleViewModel.capsulePage.selectedFilters,
                                       begin: searchViewModel.nextBegin,
                                       loadMore: true, forceReload: false, fromLabel: searchLabel)
            } else {
                if clientCanSearchRemote() {
                    searchViewModel.searchRemote(keyword: searchField.text ?? "",
                                                 begin: searchViewModel.nextBegin,
                                                 loadMore: true, debounceInterval: -1, fromLabel: searchLabel)
                }
            }
        } else if !remoteLoadmorePages.contains(searchViewModel.nextBegin) && searchViewModel.remoteHasMore && searchViewModel.strategy == .remote {
            remoteLoadmorePages.append(searchViewModel.nextBegin)
            apmMarkSearchLoadMoreStart()
            if clientCanSearchRemote() {
                searchViewModel.searchRemote(keyword: searchField.text ?? "", begin: searchViewModel.nextBegin, loadMore: true, debounceInterval: -1, fromLabel: searchLabel)
            }
        } else {
            if remoteLoadmorePages.contains(searchViewModel.nextBegin) {
                MailLogger.info("[mail_search] debugloadmore - no need to stop")
                return
            } else if footer.state != .noMoreData && canRetry {
                /// 加载失败情况下点击了重新加载的loadmore，需要
                searchViewModel.search(keyword: searchField.text ?? "",
                                       filters: capsuleViewModel.capsulePage.selectedFilters,
                                       begin: searchViewModel.nextBegin,
                                       loadMore: true, forceReload: false, fromLabel: searchLabel)
            } else {
                //MailLogger.info("[mail_search] debugloadmore - stopLoadingMore")
                //stopLoadingMore()
                if resultView.tableview.contentOffset.y == 0 {
                    resultView.tableview.btd_scrollToTop()
                } // 兼容三方库停止动画后的与inset的冲突
            }
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let item = searchViewModel.getItem(indexPath) else {
            return 0.0
        }
        return factory.cellType(from: item).cellHeight(viewModel: item.viewModel)
    }

    // MARK: - UITableViewDataSource
    public func numberOfSections(in tableView: UITableView) -> Int {
        return searchViewModel.sectionData.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchViewModel.sectionData[section].searchResultItems.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let item = searchViewModel.getItem(indexPath),
            let viewModel = factory.createCellModel(from: item),
            let cell = tableView.dequeueReusableCell(withIdentifier: factory.cellIdentify(searchBack: item)),
            let searchCell = cell as? MailSearchTableViewCellProtocol else {
                return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
        }
        if isMultiSelecting && selectedRows.contains(indexPath) || (rootSizeClassIsRegular && !isMultiSelecting && markSelectedThreadId == viewModel.threadId) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        searchCell.set(viewModel: viewModel, searchText: item.info.searchText)
        if let searchTableCell = cell as? MailSearchResultCell {
            searchTableCell.isMultiSelecting = isMultiSelecting
            searchTableCell.enableLongPress = true
            searchTableCell.longPressDelegate = self
            searchTableCell.selectedIndexPath = indexPath
            searchTableCell.delegate = self
            searchTableCell.rootSizeClassIsRegular = rootSizeClassIsRegular
            searchTableCell.separatorInset = .zero
            searchTableCell.selectionStyle = .none
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 0.01
        if section == 1 {
            return mixSearch ? (searchHeaderView.status == .searching ? 52.0 : 0.01) : 0.01
        } else {
            return 0.01
        }
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            return mixSearch ? searchHeaderView : UITableViewHeaderFooterView()
        } else {
            return UIView()
        }
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func didMoveToNewFolder(toast: String, undoInfo: (String, String)) {
        exitMultiSelect()
        showMoveToNewFolderToast(toast)
    }

    func msgListManageStrangerThread(threadIDs: [String]?, status: Bool, isSelectAll: Bool, maxTimestamp: Int64?, fromList: [String]?) {
        
    }
    
    func showMoveToNewFolderToast(_ toast: String) {
        guard !toast.isEmpty else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) { // 因为连续dismiss，callback回调了但window还没回到主页，所以出toast时机需要延迟
            MailRoundedHUD.showSuccess(with: toast, on: self.view)
        }
    }

    // MARK: - MailSearchLongPressDelegate
    func cellLongPress(reconizer: MailLongPressGestureRecognizer) {
        enterMultiSelect(reconizer)
    }

    @objc
    func enterMultiSelect(_ reconizer: MailLongPressGestureRecognizer) {
        guard scene == .inMailTab else {
            return
        }
        if isMultiSelecting {
            return
        }
        let indexPath = reconizer.selectedIndexPath
        isMultiSelecting = true
        resultView.tableview.selectRow(at: indexPath, animated: true, scrollPosition: .none)

        view.addSubview(threadActionBar)
        if hasSearchFilter() {
            intentionCapsuleView.isHidden = true
            intentionCapsuleView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        }
        threadActionBar.snp.makeConstraints { (make) in
            make.left.width.equalToSuperview()
            if hasSearchFilter() {
                make.bottom.equalTo(intentionCapsuleView.snp.top)
            } else {
                make.bottom.equalTo(resultView.snp.top)
            }
            // make.edges.equalToSuperview()
        }
        let fromLabelID: String = {
            if let filter = capsuleViewModel.capsulePage.selectedFilters.first(where: { $0.tagID != nil }),
               let tagID = filter.tagID {
                return tagID
            } else {
                return searchLabel
            }
        }()
        threadActionBar.fromLabelID = fromLabelID
        if let selectedThreadId = searchViewModel.getItem(indexPath)?.viewModel.threadId {
            selectedThreadIds.append(selectedThreadId)
        }
    }

    func hasSearchFilter() -> Bool {
        return self.accountContext.featureManager.open(.searchFilter, openInMailClient: false) && scene == .inMailTab
    }

    func exitMultiSelect() {
        selectedThreadIds.removeAll()
        isMultiSelecting = false
        threadActionBar.eraseThreadActions()
        if hasSearchFilter() {
            intentionCapsuleView.isHidden = false
            intentionCapsuleView.snp.updateConstraints { make in
                make.height.equalTo(56)
            }
        }
        if rootSizeClassIsRegular, let selectedThreadId = markSelectedThreadId,
           let getCellIndexPath = searchViewModel.getCellIndexPath(selectedThreadId) {
            resultView.tableview.selectRow(at: getCellIndexPath, animated: true, scrollPosition: .none)
        }
    }

    func updateActionsLabel() {
        threadActionBar.searchResultItems = searchViewModel.allItems()
        threadActionBar.updateActionsLabel(selectedRows: selectedRows)
    }

    // MARK: MailSearchResultCellDelegate
    func didClickFlag(_ cell: MailSearchResultCell, cellModel: MailSearchResultCellViewModel) {
        guard let indexPath = resultView.tableview.indexPath(for: cell) else {
            return
        }
        guard var resultItem = searchViewModel.getItem(indexPath) else {
            return
        }
        let isFlagged = !resultItem.viewModel.isFlagged
        resultItem.viewModel.isFlagged = isFlagged
        searchViewModel.updateItem(indexPath, item: resultItem)
        UIView.performWithoutAnimation { [weak self] in
            self?.resultView.tableview.reloadRows(at: [indexPath], with: .none)
        }
        if let viewModel = searchViewModel.getItem(indexPath)?.viewModel {
            let threadId = viewModel.threadId
            let messageIds = viewModel.messageIds
            if isFlagged {
                threadActionDataManager.flag(threadID: threadId,
                                             fromLabel: searchLabel,
                                             msgIds: messageIds,
                                             sourceType: .threadItemAction)
            } else {
                threadActionDataManager.unFlag(threadID: threadId,
                                               fromLabel: searchLabel,
                                               msgIds: messageIds,
                                               sourceType: .threadItemAction)
            }
        }
    }

    // MARK: HistoryDelegate - MailSearchHistoryViewDelegate
    func historyView(_ historyView: MailSearchHistoryView, didSelect historyInfo: MailSearchHistoryInfo) {
        guard !historyInfo.keyword.isEmpty else { return }
        // 搜索关键词
        searchField.text = historyInfo.keyword
        searchField.resignFirstResponder()
        searchTextChanged()
    }
    func showAlert(alert: LarkAlertController) {
        navigator?.present(alert, from: self)
    }
    func historyViewDidClickBackground(_ historyView: MailSearchHistoryView) {
        backgroundTapHandler()
    }

    func clearHistoryInfo() {
        historyViewModel.deleteAllInfos()
    }

    // MARK: Transistion - SearchBarTransitionTopVCDataSource
    public var searchBar: SearchBar { return self.searchNaviBar.searchbar }
    public var bottomView: UIView { return historyView }

    // MARK: Result View Model DidUpdate - MailSearchDataCenterDelegate
    func resultViewModelDidUpdate(threadId: String, viewModel: MailSearchResultCellViewModel) {
        asyncRunInMainThread { [weak self] in
            guard let `self` = self else { return }
            if let indexPath = self.searchViewModel.getCellIndexPath(threadId) {
                if var newItem = self.searchViewModel.getItem(indexPath) {
                    newItem.viewModel = viewModel
                    self.searchViewModel.updateItem(indexPath, item: newItem)
                    self.resultView.tableview.reloadSections([indexPath.section], with: .none)
                }
            }
        }
    }

    public override func keyBindings() -> [KeyBindingWraper] {
        guard rootSizeClassIsRegular else { return super.keyBindings() }

        return super.keyBindings() + [
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputUpArrow,
                modifierFlags: .command,
                discoverabilityTitle: BundleI18n.MailSDK.Mail_ThreadList_IPadShortCutScrollUp
            ).binding(
                target: self,
                selector: #selector(preThread)
            ).wraper,
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputDownArrow,
                modifierFlags: .command,
                discoverabilityTitle: BundleI18n.MailSDK.Mail_ThreadList_IPadShortCutScrollDown
            ).binding(
                target: self,
                selector: #selector(nextThread)
            ).wraper
        ]
    }
    @objc
    func preThread() {
        guard !self.isMultiSelecting else { return }
        if let selectedId = self.markSelectedThreadId {
            if let selectedPath = searchViewModel.getCellIndexPath(selectedId), selectedPath.row - 1 >= searchViewModel.getSectionItems(selectedPath.section).count {
                let preIndexPath = IndexPath(item: selectedPath.row - 1, section: selectedPath.section)
                self.resultView.tableview.selectRow(at: preIndexPath, animated: true, scrollPosition: UITableView.ScrollPosition.middle)
                self.tableView(self.resultView.tableview, didSelectRowAt: preIndexPath)
            }
        }
    }
    @objc
    func nextThread() {
        guard !self.isMultiSelecting else { return }
        if let selectedId = self.markSelectedThreadId {
            if let selectedPath = searchViewModel.getCellIndexPath(selectedId), selectedPath.row + 1 >= searchViewModel.getSectionItems(selectedPath.section).count {
                let preIndexPath = IndexPath(item: selectedPath.row + 1, section: selectedPath.section)
                self.resultView.tableview.selectRow(at: preIndexPath, animated: true, scrollPosition: UITableView.ScrollPosition.middle)
                self.tableView(self.resultView.tableview, didSelectRowAt: preIndexPath)
            }
        }
    }
}
