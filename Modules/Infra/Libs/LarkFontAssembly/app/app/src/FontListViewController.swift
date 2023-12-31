//
//  UniverseDesignFontVC.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/8/13.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UniverseDesignFont
import LarkFontAssembly
import UIKit

class FontListViewController: UIViewController {

    lazy var fontDataSource = UIFont.fontNames(forFamilyName: "Lark Circular")

    var tableView: UITableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBase

        self.title = "UniverseDesignFont"

        self.tableView = UITableView(frame: self.view.bounds, style: .plain)
        self.view.addSubview(tableView)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .singleLine
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.contentInsetAdjustmentBehavior = .never
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        tableView.snp.makeConstraints { make in
            make.top.left.right.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }
    }
}

extension FontListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fontDataSource.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else { return UITableViewCell() }
        cell.textLabel?.text = fontDataSource[indexPath.row] + "\n1234567890  abcdefg"
        cell.textLabel?.font = UIFont(name: fontDataSource[indexPath.row], size: 20)
        cell.textLabel?.numberOfLines = 0
        cell.selectionStyle = .none

        if indexPath.row % 2 == 0 {
            cell.contentView.backgroundColor = UIColor.ud.B100
        } else {
            cell.contentView.backgroundColor = .clear
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
}
