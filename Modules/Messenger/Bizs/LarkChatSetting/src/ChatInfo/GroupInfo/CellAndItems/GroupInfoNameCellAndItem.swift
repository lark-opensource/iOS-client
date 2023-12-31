//
//  GroupInfoNameCellAndItem.swift
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

// MARK: - 群名称 - item
struct GroupInfoNameItem: GroupSettingItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var attributedTitle: NSAttributedString
    var name: String
    var hasAccess: Bool
    var isTapEnabled: Bool
    var tapHandler: ChatInfoTapHandler
}

// MARK: - 群名称 - cell
final class GroupInfoNameCell: GroupSettingCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.snp.makeConstraints { (maker) in
            maker.top.left.equalToSuperview().inset(UIEdgeInsets(top: 15, left: 16, bottom: 0, right: 0))
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
        guard let item = item as? GroupInfoNameItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        self.isUserInteractionEnabled = item.isTapEnabled
        titleLabel.attributedText = item.attributedTitle
        detailLabel.text = item.name
        arrow.isHidden = !item.hasAccess || !item.isTapEnabled
        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let item = self.item as? GroupInfoNameItem {
            item.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}
