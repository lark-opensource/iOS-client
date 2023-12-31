//
//  MomentsNoticeBaseVC.swift
//  Moment
//
//  Created by bytedance on 2021/2/22.
//

import UIKit
import Foundation
import LarkUIKit
import RxCocoa
import RxSwift
import LarkMessageCore
import UniverseDesignTabs
import UniverseDesignEmpty
import LKCommonsLogging
import LarkFeatureGating
import LarkSetting
import LarkContainer

class MomentsNoticeBaseVC: BaseUIViewController,
                           UniverseDesignTabs.UDTabsListContainerViewDelegate,
                           UITableViewDelegate,
                           UITableViewDataSource,
                           UserResolverWrapper {
    static let logger = Logger.log(MomentsNoticeBaseVC.self, category: "Module.Moments.MomentsNoticeBaseVC")
    let viewModel: MomentsUserNoticeViewModel
    private let disposeBag: DisposeBag = DisposeBag()
    /// 首次数据加载完成
    private var firstDataLoadFinsihed: Bool = false

    private var pageSize: CGSize = .zero

    private lazy var emptyView: MomentsEmptyView = {
        let emptyView = MomentsEmptyView(frame: .zero, description: BundleI18n.Moment.Lark_Community_NoNotifications, type: .noContent)
        emptyView.isHidden = true
        emptyView.backgroundColor = UIColor.ud.bgBase
        emptyView.isUserInteractionEnabled = false
        return emptyView
    }()

    private lazy var errorView: UIView = {
        let content = NSMutableAttributedString(string: BundleI18n.Moment.Lark_Community_UnableLoadNotifications)
        let retryText = NSMutableAttributedString(string: BundleI18n.Moment.Lark_Community_UnableLoadNotificationsLink)
        let operableRange = NSRange(location: content.length, length: retryText.length)
        content.append(retryText)

        let errorView = MomentsEmptyView(frame: .zero,
                                         description: content,
                                         type: .loadingFailure,
                                         operableRange: operableRange) { [weak self] in
            self?.reload()
        }
        errorView.backgroundColor = UIColor.ud.bgBase
        errorView.isHidden = true
        return errorView
    }()

    private lazy var cardTracker: NoticeCardTracker = {
        return NoticeCardTracker()
    }()

    let userResolver: UserResolver
    init(userResolver: UserResolver, viewModel: MomentsUserNoticeViewModel) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var tableView: MomentsCommonTableView = {
        let table = MomentsCommonTableView()
        table.triggerOffSet = 28
        table.dataSource = self
        table.delegate = self
        table.refreshDelegate = self
        table.tableFooterView = UIView(frame: .zero)
        table.estimatedRowHeight = 100
        table.rowHeight = UITableView.automaticDimension
        table.enableTopPreload = false
        table.backgroundColor = UIColor.clear
        table.separatorStyle = .none
        table.register(NoticeReactionSkeletonViewCell.self, forCellReuseIdentifier: NoticeReactionSkeletonViewCell.identifier)
        table.register(NoticeMessageSkeletonViewCell.self, forCellReuseIdentifier: NoticeMessageSkeletonViewCell.identifier)
        table.register(MomentUserNoticeTextCell.self, forCellReuseIdentifier: MomentUserNoticeTextCell.getCellReuseIdentifier())
        table.register(MomentUserNoticeImageCell.self, forCellReuseIdentifier: MomentUserNoticeImageCell.getCellReuseIdentifier())
        table.register(MomentUserNoticeFollowCell.self, forCellReuseIdentifier: MomentUserNoticeFollowCell.getCellReuseIdentifier())
        table.register(MomentNoticeUnknownCell.self, forCellReuseIdentifier: MomentNoticeUnknownCell.getCellReuseIdentifier())
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.pageSize = self.navigationController?.view.bounds.size ?? self.view.bounds.size
        setupUI()
        observerMessageViewModel()

        self.viewModel.momentsAccountService?.rxCurrentAccount
            .observeOn(MainScheduler.instance)
            .filter { account in
                account != nil
            }.subscribe { [weak self] _ in
                self?.loadFirstScreenData()
            }.disposed(by: disposeBag)
    }

    func loadFirstScreenData() {
        viewModel.getCurrentCircle { [weak self] circle in
            guard let self = self else {
                return
            }
            let fgValue = (try? self.userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "moments.follow.disable") ?? false

            self.viewModel.followable = !(fgValue &&
                                          (circle?.disableFollowing ?? true)) &&
            self.viewModel.momentsAccountService?.getCurrentOfficialUser() == nil
            self.viewModel.fetchFirstScreenData()
        }
    }

    func setupUI() {
        self.view.backgroundColor = UIColor.ud.bgBase
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        view.addSubview(errorView)
        errorView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func observerMessageViewModel() {
        viewModel.tableRefreshDriver
            .drive(onNext: { [weak self] (refreshType) in
                switch refreshType {
                case .remoteFirstScreenDataRefresh(hasFooter: let hasFooter):
                    self?.update(hasFooter: hasFooter)
                    self?.tableView.hasHeader = true
                    self?.firstDataLoadFinsihed = true
                    self?.reloadData()
                    self?.sendReadNotice()
                    self?.viewModel.endTrackShowNot()
                case .refreshTable(needResetHeader: let needResetHeader, hasFooter: let hasFooter):
                    if needResetHeader {
                        self?.tableView.hasHeader = true
                        self?.sendReadNotice()
                    }
                    self?.update(hasFooter: hasFooter)
                    self?.reloadData()
                case .onlyRefresh:
                    self?.reloadData()
                }
            }).disposed(by: disposeBag)

        viewModel.errorDri
            .drive(onNext: { [weak self] (errorType) in
                switch errorType {
                case .fetchFirstScreenDataFail(let error):
                    if self?.viewModel.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self) == true {
                        return
                    }
                    self?.tableView.hasHeader = true
                    self?.update(hasFooter: false)
                    self?.reloadDataOnError()
                case .loadMoreFail(let error):
                    self?.tableView.endBottomLoadMore(hasMore: true)
                    self?.viewModel.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self)
                case .refreshListFail(let error):
                    self?.tableView.endTopLoadMore(hasMore: true)
                    self?.viewModel.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self)
                }
            }).disposed(by: disposeBag)
    }

    func reloadDataOnError() {
        reloadData()
        emptyView.isHidden = true
        errorView.isHidden = false
    }

    func reloadData() {
        self.tableView.reloadData()
        self.errorView.isHidden = true
        self.emptyView.isHidden = !self.viewModel.uiDataSource.isEmpty
        DispatchQueue.main.async {
            self.cardTracker.trackNotificationCardView()
        }
    }
    func update(hasFooter: Bool) {
        self.tableView.hasFooter = hasFooter
        if !hasFooter {
            // 占位footer
            self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 80))
        } else {
            self.tableView.tableFooterView = UIView(frame: .zero)
        }
    }

    func sendReadNotice() {
        let notificationID = self.viewModel.uiDataSource.first?.noticeEntity.id ?? ""
        Self.logger.info("begin sendReadNotificationsRequest isMessageType: \(self.viewModel.sourceType == .message) -\(notificationID)")
        self.viewModel.noticeApi?
            .sendReadNotificationsRequest(category: self.viewModel.sourceType,
                                          notificationID: notificationID)
            .subscribe(onNext: { [weak self] in
                Self.logger.info("begin sendReadNotificationsRequest success -\(notificationID)")
                self?.updateBadgeForPustReadSuccess()
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                Self.logger.error("sendReadNotificationsRequest isMessageType: \(self.viewModel.sourceType == .message) error: \(error)")
                self.viewModel.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self)
            }).disposed(by: self.disposeBag)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if !firstDataLoadFinsihed {
            return self.dequeueReusableSkeletonCellWithTableView(tableView, indexPath: indexPath)
        }
        guard indexPath.row < viewModel.uiDataSource.count else {
            assert(false, "MomentsNoticeMessageVC 数组越界了")
            return UITableViewCell()
        }
        let cellVM = viewModel.uiDataSource[indexPath.row]
        let cellReuseIdentifier = cellVM.reuseIdentifier
        if let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as? MomentUserNotieBaseCell {
            cell.viewModel = cellVM
            return cell
        }
        assert(false, "MomentsNoticeMessageVC 数据出错了")
        return UITableViewCell()
    }

    func dequeueReusableSkeletonCellWithTableView(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: NoticeMessageSkeletonViewCell.identifier, for: indexPath)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !firstDataLoadFinsihed {
            return NoticeList.skeletonCellCount
        }
        return viewModel.uiDataSource.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil, firstDataLoadFinsihed else { return }
        viewModel.uiDataSource[indexPath.row].didSelected()
        tableView.deselectRow(at: indexPath, animated: false)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard self.firstDataLoadFinsihed, indexPath.row < self.viewModel.uiDataSource.count else {
            return
        }
        let entiy = self.viewModel.uiDataSource[indexPath.row].noticeEntity
        self.cardTracker.updateValue(key: entiy.id, value: entiy.noticeType)

        self.viewModel.uiDataSource[indexPath.row].willDisplay()
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard self.firstDataLoadFinsihed, indexPath.row < self.viewModel.uiDataSource.count else {
            return
        }
        let entiy = self.viewModel.uiDataSource[indexPath.row].noticeEntity
        self.cardTracker.displayMessage.removeValue(forKey: entiy.id)
        self.viewModel.uiDataSource[indexPath.row].didEndDisplay()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !firstDataLoadFinsihed {
            return
        }
        self.cardTracker.trackNotificationCardView()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate, firstDataLoadFinsihed {
            self.cardTracker.trackNotificationCardView()
        }
    }

    @objc
    private func reload() {
        if self.firstDataLoadFinsihed {
            self.tableView.topLoadMoreView?.beginRefresh()
        } else {
            self.errorView.isHidden = true
            self.emptyView.isHidden = true
            self.viewModel.fetchFirstScreenData()
        }
    }

    func listView() -> UIView {
        return self.view
    }

    private func updateBadgeForPustReadSuccess() {
        guard let badgeNoti = self.viewModel.badgeNoti else { return }
        if self.viewModel.sourceType == .message {
            badgeNoti.updateBadgeOnPutRead(messageCount: 0,
                                           reactionCount: Int32(badgeNoti.currentBadge.reactionCount))
        } else if self.viewModel.sourceType == .reaction {
            badgeNoti.updateBadgeOnPutRead(messageCount: Int32(badgeNoti.currentBadge.messageCount),
                                           reactionCount: 0)
        }
    }
    /// 可选实现，列表显示的时候调
    func listDidAppear() { }
}
extension MomentsNoticeBaseVC: MomentTableViewRefreshDelegate {
    func refreshData(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        viewModel.refreshNotices(finish: finish)
    }
    func loadMoreData(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        viewModel.loadMoreNotices(finish: finish)
    }
}

extension MomentsNoticeBaseVC: NoticePageAPI {
    /// 宿主页面宽度
    var hostSize: CGSize {
        return self.pageSize
    }
}
