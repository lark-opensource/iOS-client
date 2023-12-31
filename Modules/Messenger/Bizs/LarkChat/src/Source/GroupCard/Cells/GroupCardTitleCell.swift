//
//  GroupCardTitleCell.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2017/10/20.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

final class GroupCardTitleCell: UITableViewCell {
    private(set) var nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        contentView.backgroundColor = UIColor.ud.bgBody

        nameLabel.textColor = UIColor.ud.N900
        nameLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        nameLabel.textAlignment = .left
        self.contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(48)
            make.left.equalTo(16)
            make.right.lessThanOrEqualTo(-16)
            make.bottom.equalTo(-6)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func set(groupName: String) {
        self.nameLabel.text = groupName
    }
}
