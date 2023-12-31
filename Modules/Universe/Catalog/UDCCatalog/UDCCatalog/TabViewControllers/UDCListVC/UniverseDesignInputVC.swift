//
//  UniverseDesignInputVC.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/9/24.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignInput
import UIKit

private let reusableIdentifier = "UniverseDesignInputVC.Cell"

class UniverseDesignInputVC: UITableViewController {

    let dataSource: [String] = ["单行输入框", "多行单行输入框"]

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
        case "单行输入框":
            self.navigationController?.pushViewController(TextFieldVC(), animated: true)
        case "多行单行输入框":
            self.navigationController?.pushViewController(MultilineTextFieldVC(), animated: true)
        default:
            break
        }
    }
}
