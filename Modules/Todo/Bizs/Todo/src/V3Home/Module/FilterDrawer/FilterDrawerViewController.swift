//
//  FilterDrawerViewController.swift
//  Todo
//
//  Created by baiyantao on 2022/8/17.
//

import Foundation
import UIKit
import UniverseDesignIcon
import RxSwift
import RxCocoa
import AnimatedTabBar
import EENavigator
import LarkUIKit
import ESPullToRefresh
import LarkContainer

final class FilterDrawerViewController: V3HomeModuleController, UITableViewDataSource, UITableViewDelegate {

    // dependencies
    private let viewModel: FilterDrawerViewModel
    private let disposeBag = DisposeBag()

    // views
    private lazy var headerView = FilterDrawerHeaderView()
    private lazy var tableView = initTableView()

    // internal state
    private var isPopover: Bool { modalPresentationStyle == .popover }

    required init(resolver: UserResolver, context: V3HomeModuleContext) {
        self.viewModel = FilterDrawerViewModel(resolver: resolver, context: context)
        super.init(resolver: resolver, context: context)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindViewData()
        bindLoadMoreState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        HomeSidebar.Track.view()
    }

    private func setupView() {
        view.backgroundColor = UIColor.ud.bgBody

        view.addSubview(headerView)
        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.left.equalToSuperview().offset(8)
            $0.right.equalToSuperview().offset(-8)
            $0.height.equalTo(56)
        }
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.left.equalToSuperview()
            $0.right.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        // 分屏时 dismiss 掉自己
        NotificationCenter.default.rx
            .notification(AnimatedTabBarController.styleChangeNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.doDismiss()
            })
            .disposed(by: disposeBag)
    }

    private func bindViewData() {
        viewModel.reloadNoti
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                let contentOffset = self.tableView.contentOffset
                let contentSize = self.tableView.contentSize
                self.tableView.reloadData()
                self.tableView.layoutIfNeeded()
                var offset: CGFloat = 0
                if self.tableView.contentSize.height < contentSize.height {
                    offset = contentSize.height - self.tableView.contentSize.height
                }
                self.tableView.setContentOffset(
                    CGPoint(x: contentOffset.x, y: max(0, contentOffset.y - offset)),
                    animated: false
                )
            })
            .disposed(by: disposeBag)
        viewModel.loadMoreNoti
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                // 需要让 tableview 划到底部，并且稍微超出 contentSize heiht 一点，来触发 load more
                let bottomY = self.tableView.contentSize.height
                    + self.tableView.contentInset.bottom
                    - self.tableView.frame.height
                if bottomY >= 0 {
                    self.tableView.setContentOffset(
                        CGPoint(x: self.tableView.contentOffset.x, y: bottomY + 5),
                        animated: true
                    )
                } else {
                    // 如果当前 contentSize 小于 Frame，上面那个方式会失效，换一种方式触发 load more
                    self.tableView.es.autoLoadMore()
                }
            })
            .disposed(by: disposeBag)
    }

    private func initTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.ctf.register(cellType: FilterDrawerNormalCell.self)
        tableView.ctf.register(cellType: FilterDrawerSubItemCell.self)
        tableView.ctf.register(headerViewType: FilterDrawerSectionHeader.self)
        tableView.ctf.register(headerViewType: FilterDrawerSectionFooter.self)
        return tableView
    }

    @objc
    private func doDismiss(completion: (() -> Void)? = nil) {
        dismiss(animated: true, completion: completion)
    }

    // MARK: - UITableView

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfItems(in: section) ?? 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let info = viewModel.headerInfo(in: section),
              let header = tableView.ctf.dequeueReusableHeaderView(FilterDrawerSectionHeader.self) else {
            return nil
        }
        header.viewData = info
        header.clickHandler = { [weak self] in
            self?.viewModel.doToggleSection(section)
        }
        header.addBtnHandler = { [weak self] in
            guard let self = self else { return }
            HomeSidebar.Track.willCreateTasklist(with: nil, and: true)
            let vm = ListEditViewModel(scene: .create)
            let vc = ListEditViewController(viewModel: vm)
            vc.saveHandler = { [weak self] str in
                self?.viewModel.doCreateTaskList(title: str) { [weak self] res in
                    guard let self = self else { return }
                    switch res {
                    case .success:
                        self.doDismiss()
                    case .failure(let err):
                        Utils.Toast.showWarning(with: err.message, on: self.view)
                    }
                }
            }
            self.userResolver.navigator.present(
                vc,
                wrap: LkNavigationController.self,
                from: self,
                prepare: { $0.modalPresentationStyle = .formSheet }
            )
        }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return viewModel.headerInfo(in: section) != nil ? 60 : 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let info = viewModel.footerInfo(in: section),
              let footer = tableView.ctf.dequeueReusableHeaderView(FilterDrawerSectionFooter.self) else {
            return nil
        }
        footer.viewData = info
        footer.clickHandler = { [weak self] in
            self?.viewModel.doToggleArchivedBtn()
        }
        return footer
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return viewModel.footerInfo(in: section) != nil ? 44 : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let info = viewModel.cellInfo(in: indexPath) else {
            return UITableViewCell()
        }
        switch info {
        case .normal(let data):
            guard let cell = tableView.ctf.dequeueReusableCell(FilterDrawerNormalCell.self, for: indexPath) else {
                return UITableViewCell()
            }
            cell.viewData = data
            return cell
        case .subItem(let data):
            guard let cell = tableView.ctf.dequeueReusableCell(FilterDrawerSubItemCell.self, for: indexPath) else {
                return UITableViewCell()
            }
            cell.viewData = data
            cell.moreBtnHandler = { [weak self] (sourceView, containerGuid) in
                guard let self = self, let guid = containerGuid,
                      let container = self.viewModel.taskListContainers[guid] else {
                    FilterTab.logger.error("drawer more button no container")
                    return
                }
                self.context.bus.post(.tasklistMoreAction(
                    data: .init(container: container),
                    sourceView: sourceView,
                    sourceVC: self,
                    scene: .drawer
                ))
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        viewModel.cellInfo(in: indexPath)?.height ?? 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil,
              viewModel.cellInfo(in: indexPath) != nil else {
            return
        }
        viewModel.doSelect(at: indexPath)
        // 先等 UI 刷新一下再退出
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.doDismiss()
        }
    }
}

// MARK: - LoadMore

extension FilterDrawerViewController {
    private func setupFooterIfNeeded() {
        if tableView.footer != nil { return }
        tableView.es.addInfiniteScrolling(animator: LoadMoreAnimationView()) { [weak self] in
            guard let self = self else { return }
            let state = self.viewModel.rxLoadMoreState.value
            guard state == .hasMore else {
                self.doUpdateLoadMoreState(state)
                return
            }
            FilterTab.logger.info("loadMore action triggerred")
            self.viewModel.doLoadMoreTaskLists()
        }
    }

    private func doUpdateLoadMoreState(_ loadMoreState: ListLoadMoreState) {
        FilterTab.logger.info("doUpdateLoadMoreState: \(loadMoreState)")
        switch loadMoreState {
        case .none:
            tableView.es.removeRefreshFooter()
        case .noMore:
            tableView.es.stopLoadingMore()
            tableView.es.noticeNoMoreData()
        case .loading:
            setupFooterIfNeeded()
            tableView.footer?.startRefreshing()
        case .hasMore:
            setupFooterIfNeeded()
            tableView.es.resetNoMoreData()
            tableView.es.stopLoadingMore()
        }
    }

    private func bindLoadMoreState() {
        viewModel.rxLoadMoreState.distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] loadMoreState in
                self?.doUpdateLoadMoreState(loadMoreState)
            })
            .disposed(by: disposeBag)
    }
}
