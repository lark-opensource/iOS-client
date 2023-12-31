//
//  ChatInfoNickNameCellAndItem.swift
//  Action
//
//  Created by kongkaikai on 2018/11/12.
//

import UIKit
import Foundation
import Homeric
import LKCommonsTracker

// MARK: - 群昵称 - item
struct ChatInfoNickNameModel: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var name: String
    var tapHandler: ChatInfoTapHandler
}

// MARK: - 群昵称 - cell
final class ChatInfoNickNameCell: ChatInfoCell {
    private let titleLabel = UILabel()
    private let nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        // 设置水平方向抗压性
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .horizontal)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(13)
            maker.left.equalTo(16)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(22)
        }

        nameLabel.font = UIFont.systemFont(ofSize: 14)
        nameLabel.textColor = UIColor.ud.textPlaceholder
        nameLabel.textAlignment = .right
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(titleLabel)
            maker.right.equalToSuperview().offset(-31)
            maker.left.equalTo(titleLabel.snp.right).offset(5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? ChatInfoNickNameModel else {
            assert(false, "\(self):item.Type error")
            return
        }

        titleLabel.text = item.title
        nameLabel.text = item.name
        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let item = self.item as? ChatInfoNickNameModel {
            item.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}
