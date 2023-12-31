//
//  GroupSettingDisbandCellAndItem.swift
//  Lark
//
//  Created by K3 on 2018/8/9.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkCore

// MARK: - 解散群 - item
typealias GroupSettingDisbandItem = GroupSettingTransferItem

// MARK: - 解散群 - cell
final class GroupSettingDisbandCell: GroupSettingCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.textColor = UIColor.ud.functionDangerContentDefault
        titleLabel.textAlignment = .center
        titleLabel.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
            maker.height.equalTo(48)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? GroupSettingDisbandItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = item.title
        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let item = item as? GroupSettingDisbandItem {
            item.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}
