//
//  MailPermissionSettingCell.swift
//  LarkChatSetting
//
//  Created by tanghaojin on 2020/3/8.
//

import Foundation
import UIKit
import LarkUIKit
import UniverseDesignCheckBox

final class MailPermissionSettingCell: GroupSettingCell {
    let checkBox = UDCheckBox(boxType: .single)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        titleLabel.numberOfLines = 1
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(44)
            make.centerY.equalToSuperview()
        }
        contentView.addSubview(checkBox)
        checkBox.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(16)
            make.size.equalTo(LKCheckbox.Layout.iconMidSize)
        }
        checkBox.isSelected = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
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

}
