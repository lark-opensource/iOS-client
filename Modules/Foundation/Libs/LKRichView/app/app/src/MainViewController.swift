//
//  MainViewController.swift
//  LKRichViewDev
//
//  Created by 李勇 on 2019/9/5.
//

import Foundation
import UIKit
import SnapKit

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private lazy var dataSource: [(String, (() -> UIViewController))] = self.createDataSource()
    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "实验室"
        self.view.backgroundColor = UIColor.white
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    private func createDataSource() -> [(String, (() -> UIViewController))] {
        var sources: [(String, (() -> UIViewController))] = []
        /// 测试一份超长字符串按指定份数创建CTFrame的总耗时
        sources.append(("测试长字符串创建CTFrame的耗时", { return LongStringTestController() }))
        return sources
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = self.dataSource[indexPath.row].0
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.navigationController?.pushViewController(self.dataSource[indexPath.row].1(), animated: true)
    }
}
