//
//  TestTableController.swift
//  PageListTest
//
//  Created by kongkaikai on 2018/12/10.
//  Copyright © 2018 kongkaikai. All rights reserved.
//

import Foundation
import UIKit
import LarkPageController

class PageTestTableController: PageInnerTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        tableView.backgroundColor = UIColor(red: .random(in: 0.5...1),
                                            green: .random(in: 0.5...1),
                                            blue: .random(in: 0.5...1), alpha: 1)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int.random(in: 10...30)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self),
                                                 for: indexPath)
        cell.textLabel?.text = "\(pageIndex) - \(indexPath)"

        return cell
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        innerScrollViewDidScroll?(scrollView)
    }

    override func reloadData() {
        self.tableView.reloadData()
    }
}
