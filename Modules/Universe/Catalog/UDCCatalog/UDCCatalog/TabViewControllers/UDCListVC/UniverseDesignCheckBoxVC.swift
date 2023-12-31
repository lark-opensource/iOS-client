//
//  UniverseDesignCheckBoxVC.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/8/23.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UniverseDesignCheckBox
import UIKit
import SnapKit

class UniverseDesignCheckBoxCell: UITableViewCell {
    lazy var title: UILabel = UILabel()
    lazy var checkBox: UDCheckBox = UDCheckBox()

    var checkBoxIsSelected = false
    var checkBoxIsEnabled = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(title)
        self.contentView.addSubview(checkBox)
        checkBox.isUserInteractionEnabled = false

        checkBox.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(30)
            make.centerY.equalToSuperview()
        }

        title.snp.makeConstraints { (make) in
            make.left.equalTo(checkBox.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateStatus(isSelected: Bool, isEnabled: Bool) {
        self.checkBoxIsSelected = isSelected
        self.checkBoxIsEnabled = isEnabled
        self.checkBox.isSelected = isSelected
        self.checkBox.isEnabled = isEnabled
    }

    func updateUIConfig(boxType: UDCheckBoxType, config: UDCheckBoxUIConfig) {
        self.checkBox.updateUIConfig(boxType: boxType, config: config)
    }
}

class UniverseDesignCheckBoxVC: UIViewController {
    var tableView: UITableView = UITableView()

    var dataSource: [(String, UDCheckBoxType, Bool, Bool)] = [
        ("单选可点击", .single, true, false),
        ("单选选中不可点击", .single, false, true),
        ("单选未选中不可点击", .single, false, false),
        ("复选可点击", .multiple, true, false),
        ("复选选中不可点击", .multiple, false, true),
        ("复选未选中不可点击", .multiple, false, false),
        ("部分选择可点击", .mixed, true, false),
        ("部分选择选中不可点击", .mixed, false, true),
        ("部分选择未选中不可点击", .mixed, false, false),
        ("列表选择可点击", .list, true, false),
        ("列表选择未选中不可点击", .list, false, false)
    ]

    var isCircle : Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "UniverseDesignCheckBox"
        self.view.backgroundColor = UIColor.ud.bgBody

        let rightBar = UIBarButtonItem(title: "切换圆角",
                                       style: .plain,
                                       target: self,
                                       action: #selector(switchCircle))

        self.navigationItem.rightBarButtonItem = rightBar

        self.tableView = UITableView(frame: self.view.bounds, style: .plain)
        self.view.addSubview(tableView)
        self.tableView.frame.origin.y = 88
        self.tableView.frame = CGRect(x: 0,
                                      y: 88,
                                      width: self.view.bounds.width,
                                      height: self.view.bounds.height - 88)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = 68
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.contentInsetAdjustmentBehavior = .never
        self.tableView.register(UniverseDesignCheckBoxCell.self, forCellReuseIdentifier: "cell")
    }

    @objc
    private func switchCircle() {
        self.isCircle = !self.isCircle
        self.tableView.reloadData()
    }
}

extension UniverseDesignCheckBoxVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let cell = tableView.cellForRow(at: indexPath) as? UniverseDesignCheckBoxCell {
            if cell.checkBoxIsEnabled {
                cell.updateStatus(isSelected: !cell.checkBoxIsSelected,
                                  isEnabled: cell.checkBoxIsEnabled)
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = dataSource[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? UniverseDesignCheckBoxCell {
            var config = UDCheckBoxUIConfig()
            config.style = self.isCircle ? .circle : .square
            cell.updateUIConfig(boxType: item.1, config: config)
            cell.updateStatus(isSelected: item.3, isEnabled: item.2)
            cell.title.text = item.0
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
        }
    }
}
