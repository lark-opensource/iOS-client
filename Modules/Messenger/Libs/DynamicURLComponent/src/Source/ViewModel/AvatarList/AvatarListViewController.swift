//
//  AvatarListViewController.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/7/29.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import EENavigator
import UniverseDesignEmpty
import LarkMessengerInterface

final class AvatarListViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    private let cellIdentify = "AvatarListCell"

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloat)
    }

    private let rowHeight: CGFloat = 66
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = rowHeight
        tableView.rowHeight = rowHeight
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.ud.bgFloat
        tableView.register(AvatarListCell.self, forCellReuseIdentifier: cellIdentify)
        return tableView
    }()

    private lazy var emptyView: UDEmptyView = {
        let emptyDesc = UDEmptyConfig.Description(descriptionText: BundleI18n.DynamicURLComponent.Lark_IM_NoMembersToDisplayHere_EmptyState)
        let emptyView = UDEmptyView(config: UDEmptyConfig(description: emptyDesc, type: .noContact))
        emptyView.backgroundColor = UIColor.clear
        return emptyView
    }()

    let viewModel: AvatarListViewModel
    let navigator: Navigatable

    init(viewModel: AvatarListViewModel, navigator: Navigatable) {
        self.viewModel = viewModel
        self.navigator = navigator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleString = viewModel.title
        self.titleColor = UIColor.ud.textTitle
        addCloseItem()
        view.backgroundColor = UIColor.ud.bgFloat
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        view.addSubview(emptyView)
        emptyView.useCenterConstraints = true
        emptyView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview().offset(-56) // 56 = naviBarHeight
            make.left.right.equalToSuperview()
        }
        emptyView.isHidden = true
        bindEvent()
        viewModel.loadFirstScreen()
    }

    private func bindEvent() {
        viewModel.viewStatusOb.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .loading:
                self.loadingPlaceholderView.isHidden = false
                self.retryLoadingView.isHidden = true
                self.emptyView.isHidden = true
            case .display:
                self.loadingPlaceholderView.isHidden = true
                self.retryLoadingView.isHidden = true
                if self.viewModel.getChatterInfos().isEmpty {
                    self.emptyView.isHidden = false
                    self.tableView.isHidden = true
                } else {
                    self.emptyView.isHidden = true
                    self.tableView.isHidden = false
                    self.tableView.removeBottomLoadMore()
                    self.tableView.reloadData()
                }
                if self.viewModel.hasMore {
                    self.tableView.addBottomLoadMoreView(infiniteScrollActionImmediatly: false) { [weak self] in
                        self?.viewModel.loadMoreForDynamic(isFirstScreen: false)
                    }
                }
            case .error:
                self.loadingPlaceholderView.isHidden = true
                self.emptyView.isHidden = true
                if self.viewModel.getChatterInfos().isEmpty {
                    self.retryLoadingView.isHidden = false
                    self.retryLoadingView.retryAction = { [weak self] in
                        self?.viewModel.loadFirstScreen()
                    }
                }
            }
        }).disposed(by: viewModel.disposeBag)
    }

    // MARK: - UITableViewDelegate & UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getChatterInfos().count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dataSource = viewModel.getChatterInfos()
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentify, for: indexPath) as? AvatarListCell,
              indexPath.row < dataSource.count else {
            return UITableViewCell()
        }
        let info = dataSource[indexPath.row]
        cell.update(info: info)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        let dataSource = viewModel.getChatterInfos()
        guard indexPath.row < dataSource.count else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        let info = dataSource[indexPath.row]
        guard info.type != .unknown else { return }
        let body = PersonCardBody(chatterId: info.chatterID,
                                  fromWhere: .chat,
                                  source: .chat)
        navigator.push(body: body, from: self)
    }
}
