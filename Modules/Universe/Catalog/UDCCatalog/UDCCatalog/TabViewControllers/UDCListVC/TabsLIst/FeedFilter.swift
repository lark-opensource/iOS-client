//
//  FeedFilter.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/12/18.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignTabs

class FeedFilter: UIViewController {
    private let headerView: UIView = UIView()

    private var posList: [Int: CGPoint] = [:]

    private var current = 0

    private let tabsView = FeedsTabsView()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.register(UniverseDesignSwitchCell.self, forCellReuseIdentifier: UniverseDesignSwitchCell.cellIdentifier)
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "FeedFilter"

        self.view.backgroundColor = .white

        headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 200)
        headerView.backgroundColor = .gray

        tableView.tableHeaderView = headerView
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(91)
        }

        tabsView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 40)
        let config = tabsView.getConfig()
        config.isShowGradientMaskLayer = true
        config.contentEdgeInsetLeft = 6
        config.itemSpacing = 24
        config.isTitleColorGradientEnabled = false
        tabsView.titles = ["页签1", "页签2", "页签3", "页签4", "页签5", "页签6", "页签7", "页签8", "···"]
        // 去除item之间的间距
        config.itemWidthIncrement = 0

        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2

        tabsView.backgroundColor = UIColor.white
        tabsView.indicators = [indicator]
        config.isContentScrollViewClickTransitionAnimationEnabled = true
        // 去除整体内容的左右边距
        config.contentEdgeInsetRight = 0
        config.isSelectedAnimable = true
        config.layoutStyle = .custom()
        tabsView.delegate = self

        tabsView.setConfig(config: config)

        tabsView.layer.shadowOpacity = 0.05
        tabsView.layer.shadowRadius = 2
        tabsView.layer.shadowOffset = CGSize(width: 0, height: 5)

        let line = UIView()
        tabsView.addSubview(line)
        line.snp.makeConstraints { (make) in
            make.height.equalTo(1)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        line.backgroundColor = .gray
    }
}

extension FeedFilter: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tabsView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        switch indexPath.row % 3 {
        case 0:
            return .none
        case 1:
            return .delete
        case 2:
            return .insert
        default:
            return .none
        }
    }

}

extension FeedFilter: FeedsTabsViewDelegate {
    func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) {
        print("yqh  选中: \(index + 1)")
    }

    func tabsView(_ tabsView: UDTabsView, doubleClick index: Int) {
        print("yqh  双击: \(index + 1)")
    }
}
