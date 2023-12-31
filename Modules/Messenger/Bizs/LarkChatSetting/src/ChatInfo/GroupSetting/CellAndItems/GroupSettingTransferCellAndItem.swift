//
//  GroupSettingTransferCellAndItem.swift
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

// MARK: - 转让群 - item
struct GroupSettingTransferItem: GroupSettingItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var tapHandler: ChatInfoTapHandler
}

// MARK: - 转让群 - cell
final class GroupSettingTransferCell: GroupSettingCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 79))
        }

        defaultLayoutArrow()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? GroupSettingTransferItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = item.title
        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let item = item as? GroupSettingTransferItem {
            item.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}

// MARK: - group members join and leave history 群成员进退群历史
typealias JoinAndLeaveEntryItem = GroupSettingTransferItem
typealias JoinAndLeaveEntryCell = GroupSettingTransferCell

typealias AutomaticallyAddGroupItem = GroupSettingTransferItem
typealias AutomaticallyAddGroupItemCell = GroupSettingTransferCell

typealias GroupShareHistoryItem = GroupSettingTransferItem
typealias GroupShareHistoryCell = GroupSettingTransferCell
