//
//  ChatSearchHistoryCellAndItem.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/2/3.
//

import UIKit
import Foundation

// MARK: - 搜索聊天记录 - item
struct ChatInfoSearchHistoryItem: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var tapHandler: ChatInfoTapHandler
}

// MARK: - 搜索聊天记录 - cell
final class ChatInfoSearchHistoryCell: ChatInfoCell {
    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(15)
            maker.left.equalTo(16)
            maker.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? ChatInfoSearchHistoryItem else {
            assert(false, "\(self):item.Type error")
            return
        }

        titleLabel.text = item.title
        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let item = self.item as? ChatInfoSearchHistoryItem {
            item.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}
