//
//  MomentsBaseRefreshViewController.swift
//  Moment
//
//  Created by liluobin on 2021/4/22.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import LarkMessageCore

class MomentsBaseRefreshViewController: BaseUIViewController,
                                        UITableViewDelegate,
                                        UITableViewDataSource,
                                        MomentTableViewRefreshDelegate {

    lazy var emptyView: MomentsEmptyView = {
        let emptyView = MomentsEmptyView(frame: .zero, description: "", type: .defaultPage)
        emptyView.isHidden = true
        emptyView.isUserInteractionEnabled = false
        return emptyView
    }()

    lazy var tableView: MomentsCommonTableView = {
        let table = MomentsCommonTableView()
        table.triggerOffSet = 28
        table.dataSource = self
        table.delegate = self
        table.tableFooterView = UIView(frame: .zero)
        table.enableTopPreload = false
        table.refreshDelegate = self
        table.backgroundColor = UIColor.ud.bgBody
        table.separatorStyle = .none
        self.registerCellForTableView(table)
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    func setupView() {
        self.view.backgroundColor = UIColor.ud.N00
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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        assertionFailure("子类需要重写该方法")
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        assertionFailure("子类需要重写该方法")
        return 0
    }

    func reloadData() {
        self.tableView.reloadData()
        self.emptyView.isHidden = !showEmptyView()
    }

    func registerCellForTableView(_ tableView: UITableView) {
        assertionFailure("子类需要重写该方法")
    }

    func showEmptyView() -> Bool {
        assertionFailure("子类需要重写该方法")
        return false
    }

    func refreshData(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {

    }

    func loadMoreData(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
    }

}
