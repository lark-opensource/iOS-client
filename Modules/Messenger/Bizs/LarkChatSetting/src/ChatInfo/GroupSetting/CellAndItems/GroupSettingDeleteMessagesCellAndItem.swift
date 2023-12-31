//
//  GroupSettingDeleteMessagesCellAndItem.swift
//  LarkChatSetting
//
//  Created by zhaojiachen on 2022/7/6.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkCore

// MARK: - 转让群 - item
struct GroupSettingDeleteMessagesItem: GroupSettingItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var tapHandler: ChatInfoTapHandler
}

// MARK: - 转让群 - cell
final class GroupSettingDeleteMessagesCell: GroupSettingCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        titleLabel.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 79))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? GroupSettingDeleteMessagesItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = item.title
        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let item = item as? GroupSettingDeleteMessagesItem {
            item.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}
