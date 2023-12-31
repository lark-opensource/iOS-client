//
//  GroupSettingAddNewCellAndItem.swift
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

// MARK: - 添加新成员权限 - item
struct GroupSettingAddNewItem: GroupSettingItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var status: Bool
    var switchHandler: ChatInfoSwitchHandler
}

// MARK: - 添加新成员权限 - cell
final class GroupSettingAddNewCell: GroupSettingCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        titleLabel.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 79))
        }

        defaultLayoutSwitchButton()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? GroupSettingAddNewItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = item.title
        switchButton.isOn = item.status
        layoutSeparater(item.style)
    }

    override func switchButtonStatusChange(to status: Bool) {
        guard let item = item as? GroupSettingAddNewItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        item.switchHandler(switchButton, status)
    }
}

// MARK: - @所有人权限 - cell
typealias GroupSettingAtAllCell = GroupSettingAddNewCell

// MARK: - 历史消息可见性 - item
typealias GroupSettingMessageVisibilityItem = GroupSettingEditItem

// MARK: - 历史消息可见性 - cell
typealias GroupSettingMessageVisibilityCell = GroupSettingEditCell

// MARK: - 群可搜索cell - cell
typealias GroupSettingAllowGroupSearchedItem = GroupSettingApproveItem

// MARK: - 群可搜索cell - item
typealias GroupSettingAllowGroupSearchedCell = GroupSettingApproveCell
