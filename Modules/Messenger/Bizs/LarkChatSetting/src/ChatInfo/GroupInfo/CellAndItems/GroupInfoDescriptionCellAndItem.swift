//
//  GroupInfoDescriptionCellAndItem.swift
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

// MARK: - 群描述 - item
struct GroupInfoDescriptionItem: GroupSettingItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var attributedTitle: NSAttributedString?
    var description: String
    var tapHandler: ChatInfoTapHandler
}

// MARK: - 群描述 - cell
final class GroupInfoDescriptionCell: GroupSettingCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview().inset(UIEdgeInsets(top: 14.5, left: 16, bottom: 0, right: 40))
            maker.height.equalTo(22.5).priority(.high)
        }

        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.numberOfLines = 0
        detailLabel.textColor = UIColor.ud.N500
        detailLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(titleLabel.snp.bottom).offset(2)
            maker.left.equalTo(titleLabel.snp.left)
            maker.right.equalTo(-16)
            maker.bottom.equalTo(-15)
        }

        arrow.isHidden = false
        arrow.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(titleLabel.snp.centerY)
            maker.right.equalToSuperview().offset(-16)
            maker.size.equalTo(CGSize(width: 12, height: 12))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? GroupInfoDescriptionItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.attributedText = item.attributedTitle
        detailLabel.text = item.description
        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let item = self.item as? GroupInfoDescriptionItem {
            item.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}

// MARK: - 群邮箱 - item
typealias GroupInfoMailAddressItem = GroupInfoDescriptionItem
// MARK: - 群邮箱 - cell
typealias GroupInfoMailAddressCell = GroupInfoDescriptionCell
