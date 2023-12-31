//
//  GroupSettingLeaveNotifyCellAndItem.swift
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

// MARK: - 退出群通知设置 - item
struct GroupSettingLeaveNotifyItem: GroupSettingItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var detail: String
    var cellEnable: Bool
    var tapHandler: ChatInfoTapHandler

    init(type: CommonCellItemType,
         cellIdentifier: String,
         style: SeparaterStyle,
         title: String,
         detail: String,
         cellEnable: Bool = true,
         tapHandler: @escaping ChatInfoTapHandler) {
        self.type = type
        self.cellIdentifier = cellIdentifier
        self.style = style
        self.title = title
        self.detail = detail
        self.cellEnable = cellEnable
        self.tapHandler = tapHandler
    }
}

// MARK: - 退出群通知设置 - cell
final class GroupSettingLeaveNotifyCell: GroupSettingCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview().inset(UIEdgeInsets(top: 15, left: 16, bottom: 0, right: 38))
        }

        detailLabel.numberOfLines = 2
        detailLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(titleLabel.snp.bottom).offset(2)
            maker.left.equalTo(16)
            maker.right.equalTo(-38)
            maker.bottom.equalTo(-13)
        }

        defaultLayoutArrow()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? GroupSettingLeaveNotifyItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = item.title
        detailLabel.text = item.detail
        titleLabel.textColor = item.cellEnable ? UIColor.ud.textTitle : UIColor.ud.textDisabled
        detailLabel.textColor = item.cellEnable ? UIColor.ud.textPlaceholder : UIColor.ud.textDisabled
        if item.cellEnable {
            arrow.image = Resources.right_arrow
        } else {
            arrow.image = Resources.right_arrow.ud.withTintColor(UIColor.ud.iconDisabled)
        }
        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let item = item as? GroupSettingLeaveNotifyItem {
            item.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}

// MARK: - 进群通知设置 - item
typealias GroupSettingJoinNotifyItem = GroupSettingLeaveNotifyItem

// MARK: - 进群通知设置 - cell
typealias GroupSettingJoinNotifyCell = GroupSettingLeaveNotifyCell

// MARK: - 群发言权限设置 - item
typealias GroupSettingBanningItem = GroupSettingLeaveNotifyItem

// MARK: - 群发言权限设置 - cell
typealias GroupSettingBanningCell = GroupSettingLeaveNotifyCell

// MARK: - 群邮件发信权限设置 - item
typealias GroupSettingMailPermissionItem = GroupSettingLeaveNotifyItem

// MARK: - 群邮件发信权限设置 - cell
typealias GroupSettingMailPermissionCell = GroupSettingLeaveNotifyCell
