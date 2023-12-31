//
//  GuideDebugCell.swift
//  LarkGuide
//
//  Created by zhenning on 2020/12/10.
//

import UIKit
import Foundation
final class GuideDebugCell: UITableViewCell {
    let titleLabel = UILabel()
    let valueLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.accessoryType = .disclosureIndicator

        self.valueLabel.font = UIFont.systemFont(ofSize: 15)
        self.valueLabel.textColor = UIColor.ud.primaryContentDefault
        self.contentView.addSubview(self.valueLabel)
        self.valueLabel.snp.makeConstraints { (make) in
            make.right.centerY.equalToSuperview()
        }

        self.titleLabel.font = UIFont.systemFont(ofSize: 17)
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.numberOfLines = 0
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(5)
            make.right.lessThanOrEqualTo(self.valueLabel.snp.left)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
