//
//  ResultTableViewCell.swift
//  LKRichViewDev
//
//  Created by 李勇 on 2019/9/5.
//

import Foundation
import UIKit
import SnapKit

class ResultTableViewCell: UITableViewCell {
    let leftLabel = UILabel()
    let centerLabel = UILabel()
    let rightLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(self.leftLabel)
        self.leftLabel.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.centerY.equalToSuperview()
        }
        self.contentView.addSubview(self.centerLabel)
        self.centerLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        self.contentView.addSubview(self.rightLabel)
        self.rightLabel.snp.makeConstraints { (make) in
            make.right.equalTo(10)
            make.centerY.equalToSuperview()
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
