//
//  PadFeatureSwitchTableViewCell.swift
//  LarkApp
//
//  Created by Chang Rong on 2019/9/3.
//

import Foundation
import UIKit

final class PadFeatureSwitchTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        self.accessoryType = .disclosureIndicator

        self.detailTextLabel?.font = UIFont.systemFont(ofSize: 15)

        self.textLabel?.font = UIFont.systemFont(ofSize: 17)
        self.textLabel?.textColor = UIColor.black
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
