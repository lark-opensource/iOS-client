//
//  UniverseDesignBadgeVC.swift
//  UDCCatalog
//
//  Created by Meng on 2020/10/28.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import UIKit
import Foundation
import UniverseDesignBadge
import UniverseDesignColor

class UniverseDesignBadgeVC: UIViewController {
    private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)

    private let cells: [UniverseDesignBadgeBaseCell] = [
        UniverseDesignBadgeDotCell1(title: "点状徽标 - 颜色和尺寸"),
        UniverseDesignBadgeDotCell2(title: "点状徽标 - 组合使用"),
        UniverseDesignBadgeTextCell1(title: "字符徽标 - 单字符和多字符"),
        UniverseDesignBadgeTextCell2(title: "字符徽标 - 组合使用"),
        UniverseDesignBadgeIconCell(title: "图标徽标"),
        UniverseDesignBadgeUpdateCell(title: "徽标更新")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.N00

        self.title = "UniverseDesignBadge"

        self.view.addSubview(tableView)
        self.tableView.frame.origin.y = 88
        self.tableView.frame = CGRect(x: 0,
                                      y: 88,
                                      width: self.view.bounds.width,
                                      height: self.view.bounds.height - 88)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.contentInsetAdjustmentBehavior = .never
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "toastDemoCell")
    }

}

extension UniverseDesignBadgeVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return cells.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.section]
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cells[indexPath.section].height
    }
}
