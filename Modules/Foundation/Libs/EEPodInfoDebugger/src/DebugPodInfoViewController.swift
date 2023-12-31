//
//  DebugPodInfoViewController.swift
//  EEPodInfoDebugger
//
//  Created by tefeng liu on 2019/9/2.
//

import Foundation
import UIKit
import SnapKit
import LarkFoundation

protocol DebugInfoDataSource {
    var podVersionInfos: [(String, String)] { get }
}

fileprivate final class DebugPodInfoCell: UITableViewCell {
    let titleLabel = UILabel()
    let valueLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.valueLabel.font = UIFont.systemFont(ofSize: 15)
        self.contentView.addSubview(self.valueLabel)
        self.valueLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        self.titleLabel.font = UIFont.systemFont(ofSize: 17)
        self.titleLabel.numberOfLines = 0
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(5)
            make.right.lessThanOrEqualTo(self.valueLabel.snp.left)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class DebugPodsInfoViewController: UIViewController {
    private var viewTopConstraint: ConstraintItem {
        view.safeAreaLayoutGuide.snp.top
    }
    private var viewBottomConstraint: ConstraintItem {
        view.safeAreaLayoutGuide.snp.bottom
    }

    private let dataSource: DebugInfoDataSource = DebugPodInfoJsonDataSource()
    private let tableView = UITableView()
    private var filter: String = ""

    private lazy var dataItems: [(String, String)] = dataSource.podVersionInfos

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addBackItem()
        self.title = "PodInfo"
        let searchTextField = UISearchBar()
        searchTextField.placeholder = "过滤内容..."
        searchTextField.delegate = self
        searchTextField.returnKeyType = .search
        self.view.addSubview(searchTextField)
        searchTextField.snp.makeConstraints { make in
            make.top.equalTo(self.viewTopConstraint)
            make.right.left.equalToSuperview()
            make.height.equalTo(44)
        }
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.tableHeaderView = {
            let label = UILabel()
            label.numberOfLines = 0
            label.textColor = .red
            label.text = "Dev-Pod commits (Top 3): \n\(DebugPodInfoForwarding.buildCommits)"
            label.sizeToFit()
            label.textAlignment = .center
            return label
        }()

        self.tableView.tableFooterView = nil
        self.tableView.estimatedRowHeight = 40
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(DebugPodInfoCell.self, forCellReuseIdentifier: "DebugPodInfoCell")
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { make in
            make.top.equalTo(searchTextField.snp.bottom)
            make.right.left.equalToSuperview()
            make.bottom.equalTo(self.viewBottomConstraint)
        }
        self.tableView.reloadData()
    }

    @discardableResult
    private func addBackItem() -> UIBarButtonItem {
        let barItem = UIBarButtonItem(title: "back", style: .plain, target: self, action: #selector(backItemTapped))
        self.navigationItem.leftBarButtonItem = barItem
        return barItem
    }

    @objc
    private func backItemTapped() {
        self.navigationController?.popViewController(animated: true)
    }

    private func refreshDataSource() {
        let key = self.filter.lowercased()
        if key.isEmpty {
            dataItems = dataSource.podVersionInfos
        } else {
            dataItems = dataSource.podVersionInfos.compactMap { $0.0.lowercased().fuzzyMatch(key) ? $0 : nil }
        }
    }
}

extension DebugPodsInfoViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "DebugPodInfoCell",
            for: indexPath
            ) as? DebugPodInfoCell else {
                return UITableViewCell(style: .default, reuseIdentifier: nil)
        }

        let data = dataItems[indexPath.row]
        cell.titleLabel.text = data.0
        cell.valueLabel.text = data.1
        return cell
    }
}

extension DebugPodsInfoViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filter = searchText
        self.refreshDataSource()
        self.tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        self.filter = searchBar.text ?? ""
        self.refreshDataSource()
        self.tableView.reloadData()
    }
}
