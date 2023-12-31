//
//  UniverseDesignTabsVC.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/12/8.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit

private let reusableIdentifier = "UniverseDesignTabsVC.Cell"

class UniverseDesignTabsVC: UITableViewController {
    @objc
    func injected() {
        dataSource = ["固定式页签", "滚动式页签", "Feed"]
        tableView.reloadData()
    }

    var dataSource: [String] = ["固定式页签", "滚动式页签"]

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reusableIdentifier)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reusableIdentifier, for: indexPath)
        cell.textLabel?.text = dataSource[indexPath.row]
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch dataSource[indexPath.row] {
        case "固定式页签":
            self.navigationController?.pushViewController(ScrollTabsVC(count: 3), animated: true)
        case "滚动式页签":
            self.navigationController?.pushViewController(ScrollTabsVC(count: 7), animated: true)
        case "Feed":
            self.navigationController?.pushViewController(FeedList(count: 7), animated: true)
        default:
            break
        }
    }
}
