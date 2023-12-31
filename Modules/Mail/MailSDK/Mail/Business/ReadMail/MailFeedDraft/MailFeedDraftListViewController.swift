//
//  MailFeedDraftListViewController.swift
//  MailSDK
//
//  Created by ByteDance on 2023/11/9.
//

import Foundation
import LarkUIKit
import EENavigator
import Reachability
import LKCommonsLogging
import RxSwift
import Homeric
import LarkAlertController
import RustPB
import LarkKeyCommandKit
import LarkFoundation
import ESPullToRefresh
import RxRelay
import LarkGuideUI
import LarkInteraction
import LarkTraitCollection
import LarkSplitViewController
import LarkAppLinkSDK
import LarkSwipeCellKit
import UniverseDesignIcon
import UniverseDesignShadow
import AnimatedTabBar
import UniverseDesignTheme
import UniverseDesignDialog
import UniverseDesignToast

typealias mailFeedDraftListViewConst = MailFeedDraftListViewControllerConst
struct MailFeedDraftListViewControllerConst {
    static let CellHeight: CGFloat = 94
    static let CellWithReaction: CGFloat = CellHeight + 28
    static let CellPadding: CGFloat = 32
    static let titleLeftPadding: CGFloat = 16
}

class MailFeedDraftListViewController: MailBaseViewController,
                                       MailFeedDraftListCellDelegate,
                                       UITableViewDelegate,
                                       UITableViewDataSource {
    
    let footer = MailLoadMoreRefreshAnimator.init(frame: CGRect.zero)
    lazy var tableView: UITableView = self.makeTabelView()
    var status: MailFeedDraftListEmptyCell.EmptyCellStatus = .none
    var disposeBag = DisposeBag()
    let feedCardId: String
    weak var navbarBridge: MailNavBarBridge?
    var hasMore: Bool = false
    let threadActionDataManager = ThreadActionDataManager()
    let accountContext: MailAccountContext
    var firstEnter = true
    // MARK: - view models
    var viewModel: MailFeedDraftListViewModel
    private lazy var mailBaseLoadingView: MailBaseLoadingView = {
        let loading = MailBaseLoadingView()
        loading.backgroundColor = UIColor.ud.bgBase
        self.mailLayoutPlaceHolderView(placeholderView: loading)
        return loading
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        addObserver()
        // 适配iOS 15 bartintcolor颜色不生效问题
        updateNavAppearanceIfNeeded()
        bindViewModel(VM: self.viewModel)
        setupView()
        configTabelViewRefresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override var navigationBarTintColor: UIColor {
        var isDarkModeTheme: Bool = false
        if #available(iOS 13.0, *) {
            isDarkModeTheme = UDThemeManager.getRealUserInterfaceStyle() == .dark
        }
        return isDarkModeTheme ? UIColor.ud.bgBase : UIColor.ud.bgFloatBase
    }
    
    init(feedCardId: String, accountContext: MailAccountContext) {
        self.feedCardId = feedCardId
        self.accountContext = accountContext
        self.viewModel = MailFeedDraftListViewModel(feedCardID: feedCardId)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addObserver() {
        PushDispatcher
            .shared
            .$mailfeedChange
            .wrappedValue
            .observeOn(MainScheduler.instance)
            .subscribe({ [weak self] change in
                if let fromChange = change.element {
                    self?.handleDraftFrom(fromChange.fromResponse)
                }
            }).disposed(by: disposeBag)
        
        PushDispatcher
            .shared
            .mailChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                guard let self = self else { return }
                switch push {
                case .threadChange(let change):
                    self.handleThreadChange((change.threadId, change.labelIds))
                case .multiThreadsChange(let change):
                    self.handleThreadMultiThreadChange(change.label2Threads)
                default:
                    break
                }
            }).disposed(by: disposeBag)
    }
    
    func mailLayoutPlaceHolderView(placeholderView: UIView) {
        self.view.addSubview(placeholderView)
        placeholderView.snp.makeConstraints { (make) in
            make.center.width.height.equalToSuperview()
        }
    }
    
    // MARK: - Bind
    func bindViewModel(VM: MailFeedDraftListViewModel) {
        VM.dataState
            .observeOn(MainScheduler.instance)
            .subscribe(onNext:{ [weak self] (state) in
                guard let self = self else { return }
                switch state {
                case .loadMore:
                    self.handleLoadMore()
                case .failed:
                    self.handleDatasErrors()
                case .loading:
                    self.handleLoading()
                case .loadMoreFailure:
                    UDToast.showFailure(with: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_LoadFailWait_Error, on: self.view)
                case .deleteSuccess(indexPath: let indexPath):
                    self.handleDataDelete(indexPath: indexPath)
                case .deleteFailure:
                    UDToast.showFailure(with: BundleI18n.MailSDK.Mail_Shared_LargeAttachment_LoadFailWait_Error, on: self.view)
                case .refreshed:
                    self.handleRefreshedDatas()
                }
            }).disposed(by: disposeBag)
    }
    
    func handleDataDelete(indexPath: IndexPath) {
        UDToast.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_DiscardMultiDraftsSuccess, on: self.view)
    }
    
    func hiddenLoading() {
        // 关闭等待计时
        asyncRunInMainThread {
            MailLogger.info("[mail_settings] [mail_attachment] mail hide loading")
            self.mailBaseLoadingView.stop()
        }
    }
    
    // loading页面
    func handleLoading() {
        mailBaseLoadingView.play()
        mailBaseLoadingView.isHidden = false
    }
    
    // 错误页面
    func handleDatasErrors() {
        hiddenLoading()
        status = .canRetry
        viewModel.hasMore = false
        tableView.reloadData()
    }
    
    // 加载更多数据
    func handleLoadMore() {
        hiddenLoading()
        tableView.es.stopLoadingMore()
        if !viewModel.hasMore {
            tableView.es.noticeNoMoreData()
        }
        tableView.reloadData()
    }
                       
    // 刷新数据页面
    func handleRefreshedDatas() {
       firstEnter = false // 刷新成功之后标记不再是第一次进入
       self.hiddenLoading()
       tableView.es.resetNoMoreData()
       self.tableView.es.stopLoadingMore()
       self.tableView.reloadData()
    }
    
    private func setupView() {
        self.title = BundleI18n.MailSDK.Mail_Normal_Draft
        view.backgroundColor = UIColor.ud.bgBase
        view.addSubview(tableView)
        tableView.alwaysBounceHorizontal = false
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        view.addSubview(mailBaseLoadingView)
        mailBaseLoadingView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            let navHeight = navigationController?.navigationBar.frame.height ?? 0
            let navBarTopPadding = Display.pad ? 0 : UIApplication.shared.statusBarFrame.height
            make.centerY.equalToSuperview().offset(-(navHeight + navBarTopPadding) / 2)
        }
    }
    func handleThreadMultiThreadChange(_ label2Threads: Dictionary<String, (threadIds: [String], needReload: Bool)>) {
//        MailLogger.info("[mail feed draft list]  handleThreadMultiThreadChange \(threadIds)")
        // 所有推送变更的threadIds
        let needChangeThreadIds = Array(Set(label2Threads.values.flatMap { $0.threadIds }))
        let needChangeDraftIds = self.viewModel.dataSource.filter { needChangeThreadIds.contains($0.threadID)}.map { $0.draftID }

        self.handleDraftdiffchange(needChangeDraftIds: needChangeDraftIds)
    }
    
    func handleThreadChange(_ change: (threadId: String, labelIds: [String])) {
        guard !self.feedCardId.isEmpty else { return }
        let needChangeDraftIds = self.viewModel.dataSource.filter({ $0.threadID == change.threadId}).map({$0.draftID})
        self.handleDraftdiffchange(needChangeDraftIds: needChangeDraftIds)
    }
    
    func handleDraftdiffchange(needChangeDraftIds: [String]) {
        var updatedDraftItems = self.viewModel.dataSource
        MailDataSource.shared.getFromItem(feedCardId: self.feedCardId, messageOrDraftIds: needChangeDraftIds)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }
                let draftItems = result.draftItems
                for draftItem in draftItems {
                    if let existingIndex = updatedDraftItems.firstIndex(where: { $0.draftID == draftItem.item.id}) {
                        let cellViewModel = MailFeedDraftListCellViewModel(push: draftItem)
                        updatedDraftItems[existingIndex] = cellViewModel
                    }
                }
                self.viewModel.dataSource = updatedDraftItems
                tableView.reloadData()
            }).disposed(by: disposeBag)
    }
    
    func handleDraftFrom(_ fromChange: Email_Client_V1_MailFromChangeResponse ) {
        guard !fromChange.messageMetas.isEmpty && !self.feedCardId.isEmpty && fromChange.feedCardID == self.feedCardId else { return }
        let draftIds = fromChange.messageMetas.map { $0.messageID }
        MailDataSource.shared.getFromItem(feedCardId: self.feedCardId, messageOrDraftIds: draftIds)
            .observeOn(MainScheduler.instance)
            .subscribe (onNext: { [weak self] result in
                guard let self = self else { return }
                let draftItems = result.draftItems
                var minTimestamp: Int64 = .max
                var maxTimestamp: Int64 = .min
                for draftItem in self.viewModel.dataSource {
                    let timestamp = draftItem.lastmessageTime
                    minTimestamp = min(minTimestamp, timestamp)
                    maxTimestamp = max(maxTimestamp, timestamp)
                }
                var updatedDraftItems = self.viewModel.dataSource
                if draftIds.count > draftItems.count { //删除草稿
                    let deletedDraftIds = draftIds.filter { item in
                        !draftItems.contains { $0.item.id == item }
                    }
                    updatedDraftItems = updatedDraftItems.filter { item in
                        !deletedDraftIds.contains { $0 == item.draftID }
                    }
                }
                for draftItem in draftItems {
                    let updateTimestamp = draftItem.item.lastUpdatedTimestamp
                    let cellViewModel = MailFeedDraftListCellViewModel(push: draftItem)
                    if !updatedDraftItems.contains(where: { $0.draftID == draftItem.item.id}) {
                        if updateTimestamp >= minTimestamp && updateTimestamp <= maxTimestamp {
                            // Insert the new message item in chronological order
                            if !updatedDraftItems.contains(where: { $0.draftID == cellViewModel.draftID }) {
                                if let insertIndex = updatedDraftItems.firstIndex(where: { $0.draft.lastUpdatedTimestamp > updateTimestamp }) {
                                    updatedDraftItems.insert(cellViewModel, at: insertIndex)
                                } else {
                                    updatedDraftItems.append(cellViewModel)
                                }
                            }
                        } else if updateTimestamp < minTimestamp {
                            tableView.es.resetNoMoreData()
                        } else {
                            updatedDraftItems.insert(cellViewModel, at: 0)
                        }
                    }
                }
                if updatedDraftItems.isEmpty && firstEnter == false {
                    self.popSelf() // 退出草稿
                } else {
                    updatedDraftItems = updatedDraftItems.sorted {
                        $0.lastmessageTime > $1.lastmessageTime
                    }
                    self.viewModel.dataSource = updatedDraftItems
                    tableView.reloadData()
                }
            }).disposed(by: disposeBag)

    }

    func makeTabelView() -> UITableView {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.ud.bgBase
        tableView.estimatedRowHeight = 0
        tableView.separatorStyle = .none
        tableView.estimatedSectionHeaderHeight = 0
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)
        tableView.lu.register(cellSelf: MailFeedDraftListEmptyCell.self)
        tableView.lu.register(cellSelf: MailFeedDraftListCell.self)
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.alwaysBounceHorizontal = false
        tableView.showsHorizontalScrollIndicator = false
        return tableView
    }
    
    // MARK: - UITableViewDelegate & UITableViewDataSource
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.dataSource.isEmpty {
            return 0
        } else {
            let height = mailFeedDraftListViewConst.CellHeight
            return height
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  1
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 8
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if viewModel.dataSource.isEmpty {
            return  1
        } else {
            return viewModel.dataSource.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if viewModel.dataSource.isEmpty {
            if status == .none {
                let defaultCell = UITableViewCell()
                defaultCell.selectedBackgroundView = UIView()
                return defaultCell
            }
            if let cell = tableView.dequeueReusableCell(withIdentifier: MailFeedDraftListEmptyCell.lu.reuseIdentifier) as? MailFeedDraftListEmptyCell {
                cell.status = status
                cell.selectionStyle = .none
                cell.frame = tableView.bounds
                MailLogger.info("[MailFeedDraft] didShow empty cell")
                return cell
            }
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: MailFeedDraftListCell.lu.reuseIdentifier) as? MailFeedDraftListCell {
                // 这个可能为nil
                var cellVM: MailFeedDraftListCellViewModel?
                if viewModel.dataSource.count > indexPath.section {
                    cellVM = viewModel.dataSource[indexPath.section]
                    guard let cellVM = cellVM else { return UITableViewCell() }
                    cell.cellViewModel = cellVM
                }
                cell.rootViewWidth = self.view.bounds.width
                cell.frame.size.width = self.view.bounds.width - mailFeedDraftListViewConst.CellPadding
                cell.contentView.frame.size.width = self.view.bounds.width - mailFeedDraftListViewConst.CellPadding
                cell.contentView.layer.masksToBounds = true
                cell.contentView.layer.cornerRadius = 8
                cell.delegate = self
                cell.mailDelegate = self
                cell.rootSizeClassIsRegular = rootSizeClassIsRegular
                return cell
            }
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        if rootSizeClassIsSystemRegular, let selectedRows = tableView.indexPathsForSelectedRows {
            guard !selectedRows.isEmpty, selectedRows.count == 1 else {
                mailAssertionFailure("[mail_feed_draft] tableView indexPathsForSelectedRows is empty, but call willDeselectRowAt function")
                return indexPath
            }
            guard indexPath.row < viewModel.dataSource.count else {
                mailAssertionFailure("[mail_feed_draft] tableView indexPath.row >= viewModel.datasource.count willDeselectRowAt")
                return indexPath
            }
            return nil // iPad 已读选中后不允许反选
        } else {
            return indexPath
        }
    }


//    // 加载更多
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        if (indexPath.row == viewModel.dataSource.count - 10) && !viewModel.isLastPage() {
//            viewModel.loadMore()
//        }
//    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        if viewModel.dataSource.count < 1 {
            if status == .canRetry {
                self.viewModel.firstRefresh()
            }
            return
        }
        let cell = tableView.cellForRow(at: indexPath)
            if !(cell?.isSelected ?? true) {
                cell?.setSelected(true, animated: true)
            }
        enterDraftDetail(viewModel: viewModel.dataSource[indexPath.section])
    }
    
    func enterDraftDetail(viewModel: MailFeedDraftListCellViewModel) {
        let draft = MailDraft(with: viewModel.draft)
        if let vc = MailSendController.checkMailTab_makeSendNavController(accountContext: accountContext,
                                                                          threadID: viewModel.threadID,
                                                                          messageID: viewModel.draft.replyMessageID,
                                                                          action: .messagedraft,
                                                                          labelId: viewModel.labelID,
                                                                          draft: draft, 
                                                                          statInfo: MailSendStatInfo(from: .messageDraftClick, newCoreEventLabelItem: "none"),
                                                                          trackerSourceType: .feedDraftAction,
                                                                    feedCardId: self.feedCardId) {
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    
    // MARK: - MailThreadListCellDelegate
    func didClickFlag(_ cell: MailFeedDraftListCell, cellModel: MailFeedDraftListCellViewModel) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        var datasource = viewModel.dataSource
        let isFlag = datasource.changeFlagState(at: indexPath.section)
//        tableView.reloadSections([indexPath.section], with: .none)
        if isFlag {
            threadActionDataManager.flag(threadID: cellModel.threadID,
                                         fromLabel: cellModel.labelID,
                                         msgIds: [],
                                         sourceType: .feedDraftAction)
            
        } else {
            threadActionDataManager.unFlag(threadID: cellModel.threadID,
                                           fromLabel: cellModel.labelID,
                                           msgIds: [],
                                           sourceType: .feedDraftAction)
        }
    }
    
    func loadDraftListData() {
        
    }

}
