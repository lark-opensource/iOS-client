//
//  TeamEventViewController.swift
//  LarkTeam
//
//  Created by chaishenghua on 2022/9/1.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import UniverseDesignEmpty

final class TeamEventViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    let viewModel: TeamEventViewModel
    private let disposeBag: DisposeBag
    private let heightForHeader: CGFloat = 55
    let config = UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: BundleI18n.LarkTeam.Project_T_UpdatesShownHere_Empty), type: .noContent)
    private weak var emptyView = UDEmptyView(config: UDEmptyConfig(description:
                                                                    UDEmptyConfig.Description(descriptionText: BundleI18n.LarkTeam.Project_T_UpdatesShownHere_Empty), type: .noContent))

    private lazy var teamEventTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(TeamEventCellView.self, forCellReuseIdentifier: TeamEventCellView.identifier)
        tableView.register(TeamEventCellLoadingView.self, forCellReuseIdentifier: TeamEventCellLoadingView.identifier)
        tableView.register(TeamEventHeaderView.self, forHeaderFooterViewReuseIdentifier: TeamEventHeaderView.identifier)
        tableView.register(TeamEventHeaderLoadingView.self, forHeaderFooterViewReuseIdentifier: TeamEventHeaderLoadingView.identifier)
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.estimatedRowHeight = 92
        return tableView
    }()

    init(viewModel: TeamEventViewModel) {
        self.viewModel = viewModel
        disposeBag = DisposeBag()
        super.init(nibName: nil, bundle: nil)
        self.title = BundleI18n.LarkTeam.Project_T_Updates_Title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(teamEventTableView)
        teamEventTableView.delegate = self
        teamEventTableView.dataSource = self
        teamEventTableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        bind()
    }

    func bind() {
        viewModel.teamEventModelObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.teamEventTableView.removeBottomLoadMore()
                self.teamEventTableView.reloadData()
                if self.viewModel.state == .display {
                    if self.viewModel.teamEventModel.isEmpty {
                        self.showEmptyPage()
                    } else {
                        self.removeEmptyPage()
                    }
                }
            }).disposed(by: disposeBag)
    }

    func showEmptyPage() {
        let config = UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: BundleI18n.LarkTeam.Project_T_UpdatesShownHere_Empty), type: .noContent)
        let emptyView = UDEmptyView(config: config)
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }

    func removeEmptyPage() {
        guard let emptyView = emptyView else { return }
        emptyView.removeFromSuperview()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.state {
        case .loading:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TeamEventCellLoadingView.identifier, for: indexPath) as? TeamEventCellLoadingView
            else {
                return UITableViewCell()
            }
            return cell
        case .display:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TeamEventCellView.identifier, for: indexPath) as? TeamEventCellView
            else {
                return UITableViewCell()
            }
            if indexPath.section < viewModel.teamEventModel.count &&
                indexPath.row < viewModel.teamEventModel[indexPath.section].list.count {
                let isFirst = indexPath.row == 0
                let isLast = indexPath.row == (viewModel.teamEventModel[indexPath.section].list.count - 1)
                cell.setModel(model: viewModel.teamEventModel[indexPath.section].list[indexPath.row],
                              isHideUpLine: isFirst,
                              isHideDownLine: isLast,
                              vc: self,
                              width: view.frame.width)
            }
            return cell
        case .error:
            return UITableViewCell()
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.state == .loading ? viewModel.numberOfLoadingSections : viewModel.teamEventModel.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch viewModel.state {
        case .loading:
            return viewModel.numberOfLoadingRows
        case .display:
            guard section < viewModel.teamEventModel.count else { return 0 }
            return viewModel.teamEventModel[section].list.count
        case .error:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return heightForHeader
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch viewModel.state {
        case .loading:
            guard let headerLoadingView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TeamEventHeaderLoadingView.identifier) as?
                    TeamEventHeaderLoadingView else { return nil }
            return headerLoadingView
        case .display:
            guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TeamEventHeaderView.identifier) as?
                    TeamEventHeaderView else { return nil }
            if section < viewModel.teamEventModel.count {
                headerView.setTitle(title: viewModel.teamEventModel[section].title)
                return headerView
            } else {
                return nil
            }
        case .error:
            return nil
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if viewModel.hasMore {
            let scrollViewHeight = scrollView.bounds.height
            let scrollContentSizeHeight = scrollView.contentSize.height
            let bottomInset = scrollView.contentInset.bottom
            let scrollViewBottomOffset = scrollContentSizeHeight + bottomInset - scrollViewHeight

            if scrollView.contentOffset.y >= scrollViewBottomOffset && teamEventTableView.bottomLoadMoreView == nil {
                teamEventTableView.addBottomLoadMoreView(infiniteScrollActionImmediatly: false) { [weak self] in
                    self?.viewModel.pullMoreEvents()
                }
            }
        }
    }
}
