//
//  GroupSettingEditCellAndItem.swift
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

// MARK: - 编辑群信息权限 - item
struct GroupSettingEditItem: GroupSettingItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var detail: String
    var status: Bool
    var enabled: Bool = true
    var switchHandler: ChatInfoSwitchHandler
}

// MARK: - 编辑群信息权限 - cell
final class GroupSettingEditCell: GroupSettingCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 16, bottom: 0, right: 79))
        }

        detailLabel.numberOfLines = 0
        detailLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(titleLabel.snp.bottom).offset(4)
            maker.left.right.bottom.equalToSuperview().inset(UIEdgeInsets(top: 37, left: 16, bottom: 14, right: 79))
        }

        defaultLayoutSwitchButton()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? GroupSettingEditItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = item.title
        detailLabel.text = item.detail
        switchButton.isEnabled = item.enabled
        switchButton.isOn = item.status
        layoutSeparater(item.style)
    }

    override func switchButtonStatusChange(to status: Bool) {
        guard let item = item as? GroupSettingEditItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        item.switchHandler(switchButton, status)
    }
}

// MARK: - 分享群权限 - cell
typealias GroupSettingShareCell = GroupSettingEditCell

// MARK: - 群可被搜索 - item
typealias ConfigGroupSearchAbleItem = GroupSettingEditItem

// MARK: - 群可被搜索 - cell
typealias ConfigGroupSearchAbleCell = GroupSettingEditCell
