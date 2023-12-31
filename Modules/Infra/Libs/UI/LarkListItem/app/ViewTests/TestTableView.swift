//
//  TestTableView.swift
//  ViewTests
//
//  Created by Yuri on 2023/6/2.
//

import UIKit
import LarkModel
@testable import LarkListItem

class TestTableView: UIView, UITableViewDataSource, UITableViewDelegate {
    let tableView = UITableView(frame: .zero, style: .plain)

    var checkBoxState = ListItemNode.CheckBoxState(isShow: false)
    var item = PickerItem.empty() {
        didSet {
            tableView.reloadData()
        }
    }

    var cell: UITableViewCell {
        return tableView.visibleCells.first ?? UITableViewCell()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(ItemTableViewCell.self, forCellReuseIdentifier: "1")
        addSubview(tableView)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.frame = self.bounds
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "1", for: indexPath)
        if let cell = cell as? ItemTableViewCell {
            cell.context.statusService = StatusMockerService()
            cell.node = PickerItemTransformer.transform(indexPath: IndexPath(row: 0, section: 0), item: item)
            cell.contentView.backgroundColor = .white
        }
        return cell
    }
}


class NodeTestTableView: UIView, UITableViewDataSource, UITableViewDelegate {
    let tableView = UITableView(frame: .zero, style: .plain)

    var checkBoxState = ListItemNode.CheckBoxState(isShow: true)
    var node = ListItemNode(indexPath: IndexPath(row: 0, section: 0)) {
        didSet {
            tableView.reloadData()
        }
    }

    var cell: UITableViewCell {
        return tableView.visibleCells.first ?? UITableViewCell()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(ItemTableViewCell.self, forCellReuseIdentifier: "1")
        addSubview(tableView)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.frame = self.bounds
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "1", for: indexPath)
        if let cell = cell as? ItemTableViewCell {
            cell.context.statusService = StatusMockerService()
            cell.node = node
            cell.contentView.backgroundColor = .white
        }
        return cell
    }
}
