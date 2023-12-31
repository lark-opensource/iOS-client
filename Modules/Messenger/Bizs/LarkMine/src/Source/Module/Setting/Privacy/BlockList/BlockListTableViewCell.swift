//
//  BlockListTableViewCell.swift
//  LarkMine
//
//  Created by 姚启灏 on 2020/7/22.
//

import UIKit
import Foundation
import LarkListItem
import LarkUIKit

final class BlockListTableViewCell: BaseSettingCell {
    private lazy var listItem: ListItem = ListItem()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(listItem)
        listItem.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setInfo(avatarKey: String,
                 avatarId: String,
                 name: String,
                 infoText: String = "") {
        listItem.avatarView.setAvatarByIdentifier(avatarId, avatarKey: avatarKey, scene: .Setting)
        listItem.nameLabel.text = name
        listItem.checkStatus = .invalid
        listItem.bottomSeperator.isHidden = true
        if !infoText.isEmpty {
            listItem.infoLabel.text = infoText
        }
    }
}
