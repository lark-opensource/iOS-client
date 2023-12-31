//
//  FlagListViewController+SetupViews.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/20.
//

import UIKit
import Foundation
import UniverseDesignEmpty
import LarkSceneManager
import LarkSetting

extension FlagListViewController {
    func setupSubViews() {
        let backgroundColor = UIColor.ud.bgBody
        self.view.backgroundColor = backgroundColor
        let wrapperScrollView = UIScrollView()
        wrapperScrollView.backgroundColor = backgroundColor
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 4))
        self.tableView.tableHeaderView = headerView
        self.tableView.estimatedRowHeight = 64
        self.tableView.estimatedSectionHeaderHeight = 0
        self.tableView.estimatedSectionFooterHeight = 0
        self.tableView.delegate = self
        if SceneManager.shared.supportsMultipleScenes {
            self.tableView.dragDelegate = self
        }
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .none
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.backgroundColor = UIColor.clear
        self.view.addSubview(wrapperScrollView)
        wrapperScrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        wrapperScrollView.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.size.edges.equalToSuperview()
        }
        self.view.layoutIfNeeded()
    }

    func showOrRemoveEmptyView(_ showEmptyView: Bool) {
        guard showEmptyView else {
            emptyView?.removeFromSuperview()
            emptyView = nil
            return
        }
        guard emptyView == nil else { return }
        let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkFlag.Lark_IM_Marked_AllMarkedMessagesAndChatWillBeDisplayedHere_EmptyState)
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
}
