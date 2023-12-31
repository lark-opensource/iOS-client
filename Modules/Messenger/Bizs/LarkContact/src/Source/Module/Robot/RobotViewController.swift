//
//  RobotViewController.swift
//  LarkContact
//
//  Created by Sylar on 2018/3/19.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkUIKit
import UniverseDesignToast
import UniverseDesignEmpty
import LarkFeatureGating

final class RobotViewController: BaseUIViewController, UIScrollViewDelegate {
    // 别名 FG
    @FeatureGating("lark.chatter.name_with_another_name_p2") private var isSupportAnotherNameFG: Bool

    public var router: RobotViewControllerRouter?

    fileprivate var viewModel: RobotViewModel
    fileprivate var tableView: UITableView = .init(frame: .zero)
    fileprivate let reuseIdentifier = "\(UITableViewCell.self)"
    fileprivate let disposeBag = DisposeBag()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(viewModel: RobotViewModel, router: RobotViewControllerRouter? = nil) {
        self.router = router
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkContact.Lark_Legacy_StructureRobot
        self.initializeTableView()
        self.bindViewModel()
        self.loadRobotData()
        self.viewModel.trackEnterContactBots()
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.view.endEditing(true)
        super.viewWillDisappear(animated)
    }

    private func initializeTableView() {
        self.tableView = UITableView(frame: .zero, style: .plain)
        self.tableView.separatorColor = UIColor.ud.N50
        self.tableView.rowHeight = 68
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.contentInsetAdjustmentBehavior = .never

        self.tableView.register(ContactTableViewCell.self, forCellReuseIdentifier: self.reuseIdentifier)
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func bindViewModel() {
        // Data Binding
        self.viewModel
            .robotsObservable
            .bind(to: tableView.rx.items(
                cellIdentifier: self.reuseIdentifier,
                cellType: ContactTableViewCell.self
            )) { (_, element, cell) in
                cell.setProps(ContactTableViewCellProps(user: element, isSupportAnotherName: self.isSupportAnotherNameFG))
            }
            .disposed(by: self.disposeBag)

        // Status Binding
        self.viewModel
            .statusObservable
            .bind(onNext: { [weak self] (status) in
                guard let `self` = self else { return }
                switch status {
                case .empty:
                    self.showNoDataView()
                case .loading where self.viewModel.isEmpty():
                    self.loadingPlaceholderView.isHidden = false
                case .loadedMore:
                    self.tableView.addBottomLoadMoreView { [weak self] in
                        self?.loadRobotData()
                    }
                case .finish:
                    self.tableView.endBottomLoadMore(hasMore: false)
                case .error:
                    if self.viewModel.isEmpty() {
                        self.retryLoadingView.isHidden = false
                        self.retryLoadingView.retryAction = { [unowned self] in
                            self.retryLoadingView.isHidden = true
                            self.loadRobotData()
                        }
                    } else {
                        self.retryLoadingView.isHidden = true
                        UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Legacy_NetworkOrServiceError, on: self.view)
                        self.tableView.endBottomLoadMore()
                    }
                default: break
                }
                if status != .loading {
                    self.loadingPlaceholderView.isHidden = true
                }
            })
            .disposed(by: self.disposeBag)

        // Item Selectd
        self.tableView.rx
            .modelSelected(LarkModel.Chatter.self)
            .flatMap({ [weak self] (chatter) -> Observable<(chatter: Chatter, chatId: String?)> in
                guard let `self` = self else { return Observable.empty() }
                if let selectedRowIndexPath = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: selectedRowIndexPath, animated: true)
                }

                return self.viewModel.fetchLocalChatId(userId: chatter.id).map { (chatId) -> (chatter: Chatter, chatId: String?) in
                    return (chatter, chatId)
                }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chat) in
                guard let `self` = self else { return }
                self.router?.robotViewController(self, chatter: chat.chatter, chatId: chat.chatId)
            })
            .disposed(by: self.disposeBag)
    }

    private func loadRobotData() {
        self.viewModel.loadRobotData()
    }

    private func showNoDataView() {
        let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkContact.Lark_Legacy_RobotEmpty)
        let emptyDataView = UDEmptyView(config: UDEmptyConfig(description: desc, type: .noRobot))
        self.view.addSubview(emptyDataView)
        emptyDataView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    // MARK: - UIScrollViewDelegate
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return true
    }
}
