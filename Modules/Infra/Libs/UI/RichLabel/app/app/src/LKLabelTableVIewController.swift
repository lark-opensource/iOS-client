//
//  LKLabelTableVIewController.swift
//  LarkUIKitDemo
//
//  Created by qihongye on 2018/12/4.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

class LKLabelTableviewController: UIViewController {
    struct DatasourceItem {
        var title: String
        var targetVC: () -> UIViewController
    }

    var tableView: UITableView!
    var datasource: [DatasourceItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupDatasource()
    }

    func setupTableView() {
        tableView = UITableView()
        tableView.tableFooterView = UIView()
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        tableView.delegate = self
        tableView.dataSource = self
        //        tableView.allowsMultipleSelection = false
        //        tableView.isMultipleTouchEnabled = false

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
    }

    func setupDatasource() {
        let lkLabelItem = DatasourceItem(title: "LKLabel") { () -> UIViewController in
            LKLabelDemoViewController()
        }

        let textAlignLabelItem = DatasourceItem(title: "TextAlignDemo") { () -> UIViewController in
            TextAlignDemoViewController()
        }

        let drawLastLineItem = DatasourceItem(title: "Draw Last Line") { () -> UIViewController in
            DrawLastLineDemoViewController()
        }

        let tapOutofRangeTextItem = DatasourceItem(title: "Out of range text demo") { () -> UIViewController in
            TapOutofRangeTextDemoViewController()
        }

        let selectionLabelItem = DatasourceItem(title: "Selection Demo") { () -> UIViewController in
            SelectionLKLabelDemoViewController()
        }

        let textMagnifierItem = DatasourceItem(title: "Text Magnifier") { () -> UIViewController in
            LKTextMagnifierDemoViewController()
        }

        let linksItem = DatasourceItem(title: "Links") { () -> UIViewController in
            LinksDemoViewController()
        }

        let underlineTestItem = DatasourceItem(title: "LKLabel Underline Demo") { () -> UIViewController in
            UnderlineTestController()
        }

        self.datasource = [
            lkLabelItem,
            textAlignLabelItem,
            drawLastLineItem,
            tapOutofRangeTextItem,
            selectionLabelItem,
            textMagnifierItem,
            linksItem,
            underlineTestItem
        ]
    }
}

extension LKLabelTableviewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = datasource[indexPath.row].targetVC()
        if vc is UINavigationController {
            self.present(vc, animated: true, completion: nil)
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension LKLabelTableviewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self), for: indexPath)
        cell.textLabel?.text = datasource[indexPath.row].title
        return cell
    }
}
