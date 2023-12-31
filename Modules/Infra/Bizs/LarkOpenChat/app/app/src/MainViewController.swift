//
//  MainViewController.swift
//  LarkOpenChatDev
//
//  Created by 李勇 on 2020/12/9.
//

import Foundation
import UIKit
import SnapKit
import Swinject

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let dataSource: [String] = ["ModuleDemoViewController", "TaskDemoViewController"]
    private let container = Container()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "MainViewController"
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = UITableViewCell(style: .default, reuseIdentifier: nil)

        tableViewCell.textLabel?.text = self.dataSource[indexPath.row]

        return tableViewCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.row {
        /// ModuleDemo
        case 0:
            self.navigationController?.pushViewController(ModuleViewController(), animated: true)
        /// TaskDemo
        case 1:
            self.navigationController?.pushViewController(TaskDemoViewController(), animated: true)
        default:
            break
        }
    }
}
