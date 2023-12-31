//
//  BaseFeedsViewController+SetupViews.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/8/20.
//

import UIKit
import Foundation
import LarkSceneManager
import RxSwift
import RxCocoa
import LarkUIKit
import SnapKit
import UniverseDesignToast
import UniverseDesignEmpty
import LarkOpenFeed

extension BaseFeedsViewController {
    static let spareCell = "spareCell"
    func setupViews() {
        self.view.backgroundColor = UIColor.ud.bgBase
        FeedCardContext.registerCell?(tableView, userResolver)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.spareCell)
        tableView.delegate = self
        tableView.dataSource = self
        if SceneManager.shared.supportsMultipleScenes {
            tableView.dragDelegate = self
        }
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        configForPad(tableView: tableView)
    }

    func showOrRemoveEmptyView(_ showEmptyView: Bool) {
        guard showEmptyView else {
            emptyView?.removeFromSuperview()
            emptyView = nil
            return
        }
        guard emptyView == nil else { return }
        let desc = UDEmptyConfig.Description(descriptionText: feedsViewModel.emptyTitle)
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

    func getCell(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.spareCell, for: indexPath)
        return cell
    }

    // 如果tableView停止时，发现loadmore还处于loading状态，则终止掉
    func endBottomLoadMore() {
        if let bottomLoadMoreView = tableView.bottomLoadMoreView,
           bottomLoadMoreView.state == .loading {
            tableView.endBottomLoadMore(hasMore: feedsViewModel.hasMoreFeeds())
        }
    }
}
