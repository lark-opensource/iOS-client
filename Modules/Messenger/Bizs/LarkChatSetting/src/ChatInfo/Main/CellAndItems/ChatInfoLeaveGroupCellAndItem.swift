//
//  ChatInfoLeaveGroupCellAndItem.swift
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

// MARK: - 离开群 - item
struct ChatInfoLeaveGroupModel: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle = .none
    var title: String
    var tapHandler: ChatInfoTapHandler
}

// MARK: - 离开群 - cell
final class ChatInfoLeaveGroupCell: ChatInfoCell {
    fileprivate var titleLabel: UILabel = .init()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.functionDangerContentDefault
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.bottom.centerX.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0))
            maker.height.equalTo(16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let leave = item as? ChatInfoLeaveGroupModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = leave.title
        arrow.isHidden = true
        layoutSeparater(leave.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let leaveItem = item as? ChatInfoLeaveGroupModel {
            leaveItem.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}
