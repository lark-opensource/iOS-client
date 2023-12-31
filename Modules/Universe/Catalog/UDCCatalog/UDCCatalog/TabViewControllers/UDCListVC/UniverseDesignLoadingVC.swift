//
//  UniverseDesignLoadingVC.swift
//  UDCCatalog
//
//  Created by Miaoqi Wang on 2020/11/12.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit

private let reusableIdentifier = "UniverseDesignLoadingVC.Cell"

class UniverseDesignLoadingVC: UITableViewController {

    let dataSource: [String] = ["Skeleton", "Loading Image", "Spin"]
    
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
        case "Spin":
            self.navigationController?.pushViewController(SpinViewController(), animated: true)
        case "Loading Image":
            self.navigationController?.pushViewController(LoadingImageViewController(), animated: true)
        case "Skeleton":
            self.navigationController?.pushViewController(SkeletonViewController(), animated: true)
        default:
            break
        }
    }
}
