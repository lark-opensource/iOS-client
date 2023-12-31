//
//  SkeletonViewController.swift
//  UniverseDesignLoadingDev
//
//  Created by Miaoqi Wang on 2020/11/8.
//

import Foundation
import UIKit

private let cellReusableIdentifier = "SkeletonViewController.cell"

class SkeletonViewController: UITableViewController {
    let dataSource: [String] = ["TableView", "CollectionView"]

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isTranslucent = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReusableIdentifier)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReusableIdentifier, for: indexPath)
        cell.textLabel?.text = dataSource[indexPath.row]
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch dataSource[indexPath.row] {
        case "TableView":
            self.navigationController?.pushViewController(SkeletonTableViewController(), animated: true)
        case "CollectionView":
            self.navigationController?.pushViewController(SkeletonCollectionViewController(), animated: true)
        default:
            break
        }
    }
}
