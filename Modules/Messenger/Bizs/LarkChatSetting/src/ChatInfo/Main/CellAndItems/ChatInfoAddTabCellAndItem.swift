//
//  ChatInfoAddTabCell.swift
//  LarkChatSetting
//
//  Created by zhaojiachen on 2022/4/14.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignColor

final class ChatInfoAddTabCell: ChatInfoCell {
    private var titleLabel: UILabel

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        titleLabel = UILabel()

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(titleLabel)
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.snp.makeConstraints { (maker) in
            maker.height.equalTo(22)
            maker.top.equalTo(13)
            maker.left.equalTo(16)
            maker.bottom.equalTo(-13)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let shareItem = item as? ChatInfoAddTabModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        selectionStyle = shareItem.cellEnable ? .default : .none
        titleLabel.text = shareItem.title
        titleLabel.textColor = shareItem.cellEnable ? UIColor.ud.textTitle : UIColor.ud.textDisabled
        arrow.ud.withTintColor(shareItem.cellEnable ? UIColor.ud.iconN3 : UIColor.ud.iconDisabled)
        layoutSeparater(shareItem.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let addItem = self.item as? ChatInfoAddTabModel {
            addItem.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}

struct ChatInfoAddTabModel: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var cellEnable: Bool
    var tapHandler: ChatInfoTapHandler

    init(type: CommonCellItemType,
         cellIdentifier: String,
         style: SeparaterStyle,
         title: String,
         cellEnable: Bool,
         tapHandler: @escaping ChatInfoTapHandler) {
        self.type = type
        self.cellIdentifier = cellIdentifier
        self.style = style
        self.title = title
        self.cellEnable = cellEnable
        self.tapHandler = tapHandler
    }
}

typealias ChatInfoAddPinModel = ChatInfoAddTabModel
typealias ChatInfoAddPinCell = ChatInfoAddTabCell
