//
//  TypeButtonViewController.swift
//  LarkUIKitDemo
//
//  Created by KongKaikai on 2018/12/11.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkButton
import SnapKit

class TypeButtonCell: UITableViewCell {
    let button = TypeButton(type: .custom)

    override func layoutSubviews() {
        super.layoutSubviews()
        switch button.style {
        case .largeA, .largeB, .largeC:
            button.snp.remakeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.right.equalToSuperview().inset(16)
                maker.height.equalTo(button.defaultHeight)
            }
        case .normalA, .normalB, .normalC, . normalD, .textA, .textB:
            button.snp.remakeConstraints { (maker) in
                maker.center.equalToSuperview()
                maker.height.equalTo(button.defaultHeight)
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(button)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TypeButtonViewController: UITableViewController {
    var types: [TypeButton.Style] = [
        .largeA,
        .largeB,
        .largeC,
        .normalA,
        .normalB,
        .normalC,
        .normalD,
        .textA,
        .textB
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(TypeButtonCell.self, forCellReuseIdentifier: NSStringFromClass(TypeButtonCell.self))
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return types.count * 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TypeButtonCell.self), for: indexPath)

        if let button = (cell as? TypeButtonCell)?.button {
            let type = types[indexPath.row % types.count]
            button.style = type
            var isEnabled = true
            var isHighlighted = false

            switch indexPath.row / types.count {
            case 1:
                isEnabled = true
                isHighlighted = true
            case 2:
                isEnabled = false
                isHighlighted = false
            default:
                isEnabled = true
                isHighlighted = false
            }

            button.isEnabled = isEnabled
            button.isHighlighted = isHighlighted

            button.setTitle("「 \( isHighlighted ? "H: ": isEnabled ? "N: " : "D: ") - \(type) 」", for: .normal)
        }
        cell.selectedBackgroundView = nil

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
