//
//  CheckBoxViewController.swift
//  LarkUIKitDemo
//
//  Created by kkk on 2019/3/11.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit

class CheckBoxCell: UITableViewCell {
    var checkBox = Checkbox()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(checkBox)
        checkBox.snp.makeConstraints({ (maker) in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(24)
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CheckBoxViewController: UITableViewController {
    var types: [CheckboxType] = [.circle, .square, .concentric]

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(CheckBoxCell.self, forCellReuseIdentifier: CheckBoxCell.lu.reuseIdentifier)
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 200
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CheckBoxCell.lu.reuseIdentifier, for: indexPath)

        if let _cell = cell as? CheckBoxCell {
            _cell.checkBox.boxType = types[indexPath.row % types.count]
            _cell.checkBox.setOn(on: indexPath.item / 3 % 2 == 0)
            if _cell.checkBox.boxType == .concentric {
                _cell.checkBox.lineWidth = 1
            }
        }

        return cell
    }
}
