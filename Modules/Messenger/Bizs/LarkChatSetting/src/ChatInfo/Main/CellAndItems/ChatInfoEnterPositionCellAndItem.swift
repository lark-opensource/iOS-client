//
//  ChatInfoEnterPositionCellAndItem.swift
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

// MARK: - 进入此会话默认定位到 - item
struct ChatInfoEnterPositionModel: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var isShowArrow: Bool = true
    var title: String
    var status: String
    var tapHandler: ChatInfoTapHandler
}

// MARK: - 进入此会话默认定位到 - cell
final class ChatInfoEnterPositionCell: ChatInfoCell {
    fileprivate var titleLabel: UILabel = .init()
    fileprivate var statusLabel: UILabel = .init()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview().inset(UIEdgeInsets(top: 12.5, left: 16, bottom: 0, right: 40))
            maker.height.equalTo(22.5)
        }

        statusLabel = UILabel()
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textColor = UIColor.ud.textPlaceholder
        statusLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 999), for: .vertical)
        statusLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .vertical)
        contentView.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 37, left: 16, bottom: 12, right: 40))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let position = item as? ChatInfoEnterPositionModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        arrow.isHidden = !position.isShowArrow
        titleLabel.text = position.title
        statusLabel.text = position.status
        layoutSeparater(position.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let positionItem = item as? ChatInfoEnterPositionModel {
            positionItem.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}
