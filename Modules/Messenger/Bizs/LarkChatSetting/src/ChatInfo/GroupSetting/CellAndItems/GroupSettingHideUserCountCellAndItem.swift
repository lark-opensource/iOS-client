//
//  GroupSettingHideUserCountCellAndItem.swift
//  LarkChatSetting
//
//  Created by zhaojiachen on 2023/11/19.
//

import UIKit
import Foundation

// MARK: - 隐藏群人数 - item
struct HideUserCountItem: GroupSettingItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var detail: String
    var status: Bool
    var switchHandler: ChatInfoSwitchHandler
}

// MARK: - 隐藏群人数 - cell
final class HideUserCountCell: GroupSettingCell {
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
        guard let item = item as? HideUserCountItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = item.title
        detailLabel.text = item.detail
        switchButton.isOn = item.status
        layoutSeparater(item.style)
    }

    override func switchButtonStatusChange(to status: Bool) {
        guard let item = item as? HideUserCountItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        item.switchHandler(switchButton, status)
    }
}
