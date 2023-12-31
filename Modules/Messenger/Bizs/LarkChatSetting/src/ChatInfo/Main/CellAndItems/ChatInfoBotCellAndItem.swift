//
//  ChatInfoBotCellAndItem.swift
//  LarkChatSetting
//
//  Created by houjihu on 2021/3/9.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkCore

// MARK: - 群机器人 - item
struct ChatInfoBotModel: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var chatBotCount: Int
    var tapHandler: (_ hasBot: Bool) -> Void
}

// MARK: - 群机器人 - cell
final class ChatInfoBotCell: ChatInfoCell {
    private let titleLabel = UILabel()
    private let botCountLabel = UILabel()

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

        botCountLabel.font = UIFont.systemFont(ofSize: 14)
        botCountLabel.textColor = UIColor.ud.textPlaceholder
        botCountLabel.textAlignment = .right
        contentView.addSubview(botCountLabel)
        botCountLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(titleLabel)
            maker.right.equalToSuperview().offset(-31)
            maker.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(5)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? ChatInfoBotModel else {
            assertionFailure("\(self):item.Type error")
            return
        }

        titleLabel.text = item.title
        let hasBoot = hasBot(chatBotCount: item.chatBotCount)
        // 机器人个数大于0时显示个数，否则显示空文本
        botCountLabel.text = hasBoot ? item.chatBotCount.description : ""
        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let item = self.item as? ChatInfoBotModel {
            let hasBoot = hasBot(chatBotCount: item.chatBotCount)
            item.tapHandler(hasBoot)
        }
        super.setSelected(selected, animated: animated)
    }

    /// 根据机器人个数，判断是否有机器人
    private func hasBot(chatBotCount: Int) -> Bool {
        return chatBotCount > 0
    }
}
