//
//  UserFollowListViewController.swift
//  Moment
//
//  Created by bytedance on 2021/3/9.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import LarkMessageCore
import UniverseDesignEmpty

final class UserFollowListViewController: BaseUIViewController,
                                    UITableViewDelegate,
                                    UITableViewDataSource {
    let viewModel: UserFollowListViewModel
    private let disposeBag: DisposeBag = DisposeBag()
    private var firstScreenDataLoading: Bool = true
    let backBtnClick: (() -> Void)?

    private lazy var emptyView: MomentsEmptyView = {
        let emptyView = MomentsEmptyView(frame: .zero, description: emptyTitle(), type: .noContact)
        emptyView.isHidden = true
        emptyView.isUserInteractionEnabled = false
        return emptyView
    }()

    private lazy var tableView: MomentsCommonTableView = {
        let table = MomentsCommonTableView()
        table.triggerOffSet = 28
        table.dataSource = self
        table.delegate = self
        table.tableFooterView = UIView(frame: .zero)
        table.enableTopPreload = false
        table.refreshDelegate = self
        table.separatorStyle = .none
        table.backgroundColor = UIColor.ud.bgBody
        table.register(UserFollowSkeletonCell.self, forCellReuseIdentifier: UserFollowSkeletonCell.identifier)
        table.register(UserFollowTableViewCell.self, forCellReuseIdentifier: UserFollowTableViewCell.identifier)
        return table
    }()

    init(viewModel: UserFollowListViewModel, backBtnClick: (() -> Void)?) {
        self.viewModel = viewModel
        self.backBtnClick = backBtnClick
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = viewModel.title
        setupView()
        observerMessageViewModel()
        viewModel.fetchFirstScreenData()
        MomentsTracer.trackMomentsFollowPageViewWith(circleId: viewModel.context.circleId,
                                                     isFollowUsers: viewModel.type == .followings)
    }

    func setupView() {
        self.view.backgroundColor = UIColor.ud.bgBody
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.right.bottom.equalToSuperview()
        }

        self.view.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalTo(tableView)
        }
    }

    private func observerMessageViewModel() {
        viewModel.tableRefreshDriver
            .drive(onNext: { [weak self] (refreshType) in
                switch refreshType {
                case .remoteFirstScreenDataRefresh(hasFooter: let hasFooter):
                    self?.update(hasFooter: hasFooter)
                    self?.tableView.hasHeader = true
                    self?.firstScreenDataLoading = false
                    self?.reloadData()
                case .refreshTable(needResetHeader: let needResetHeader, hasFooter: let hasFooter):
                    if needResetHeader {
                        self?.tableView.hasHeader = true
                    }
                    self?.update(hasFooter: hasFooter)
                    self?.reloadData()
                }
            }).disposed(by: disposeBag)

        viewModel.errorDri
            .drive(onNext: { [weak self] (errorType) in
                switch errorType {
                case .fetchFirstScreenDataFail:
                    self?.tableView.hasHeader = true
                    self?.update(hasFooter: false)
                    self?.firstScreenDataLoading = false
                    self?.reloadData()
                case .loadMoreFail:
                    self?.tableView.endBottomLoadMore(hasMore: true)
                case .refreshListFail:
                    self?.tableView.endTopLoadMore(hasMore: true)
                }
            }).disposed(by: disposeBag)
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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.firstScreenDataLoading {
            return tableView.dequeueReusableCell(withIdentifier: UserFollowSkeletonCell.identifier, for: indexPath)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: UserFollowTableViewCell.identifier, for: indexPath)
        if let userCell = cell as? UserFollowTableViewCell, indexPath.row < self.viewModel.uiDataSource.count {
            userCell.viewModel = self.viewModel.uiDataSource[indexPath.row]
        }
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.firstScreenDataLoading {
            return 20
        }
        return viewModel.uiDataSource.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil,
              indexPath.row < self.viewModel.uiDataSource.count else {
            return
        }
        let cellVM = self.viewModel.uiDataSource[indexPath.row]
        cellVM.didSelected()
    }
    func reloadData() {
        self.tableView.reloadData()
        self.emptyView.isHidden = !self.viewModel.uiDataSource.isEmpty
    }

    override func backItemTapped() {
        super.backItemTapped()
        self.backBtnClick?()
    }

    func emptyTitle() -> String {

        if !self.viewModel.isCurrentUser {
          return self.viewModel.type == .followings ? BundleI18n.Moment.Lark_Community_OtherUserNotFollowingEmptyState : BundleI18n.Moment.Lark_Community_OtherUserNoFollowersEmptyState
        }

        return self.viewModel.type == .followings ? BundleI18n.Moment.Lark_Community_FollowingEmptyState : BundleI18n.Moment.Lark_Community_FollowersEmptyState
    }
}
extension UserFollowListViewController: MomentTableViewRefreshDelegate {
    func refreshData(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        viewModel.refreshData(finish: finish)
    }
    func loadMoreData(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        viewModel.loadMoreData(finish: finish)
    }
}
