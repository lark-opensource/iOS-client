//
//  HiddenChatListViewController+SetupViews.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/10/27.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import SnapKit
import UniverseDesignToast
import UniverseDesignEmpty

extension HiddenChatListViewController {
    func setupViews() {
        self.title = BundleI18n.LarkFeed.Project_MV_HideYourGroup
        let backgroundColor = UIColor.ud.bgBody
        view.backgroundColor = backgroundColor
        tableView.register(FeedTeamChatCell.self, forCellReuseIdentifier: FeedTeamChatCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = backgroundColor
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        let headerView = HiddenChatListHeader()
        let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        headerView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: self.tableView.bounds.size.width, height: height))
        tableView.tableHeaderView = headerView

        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func render() {
        tableView.reloadData()
    }

    func showOrRemoveEmptyView() {
        guard viewModel.teamUIModel.chatModels.isEmpty else {
            emptyView?.removeFromSuperview()
            emptyView = nil
            return
        }
        guard emptyView == nil else { return }
        let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkFeed.Lark_Legacy_CurrentPageEmpty)
        let config = UDEmptyConfig(description: desc, type: .defaultPage)
        let emptyView = UDEmptyView(config: config)
        emptyView.useCenterConstraints = true
        self.tableView.addSubview(emptyView)
        self.emptyView = emptyView
        emptyView.snp.makeConstraints { make in
            make.leading.trailing.height.width.equalToSuperview()
            make.top.equalToSuperview().offset(-100)
        }
    }

    func showOrHidenLoading() {
        guard self.loadingPlaceholderView.isHidden == viewModel.shouldLoading else { return }
        self.loadingPlaceholderView.isHidden = !viewModel.shouldLoading
    }
}
