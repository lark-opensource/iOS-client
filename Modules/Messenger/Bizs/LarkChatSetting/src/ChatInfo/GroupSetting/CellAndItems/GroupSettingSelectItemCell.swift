//
//  GroupSettingSelectItemCell.swift
//  LarkChatSetting
//
//  Created by liluobin on 2022/11/29.
//

import UIKit
import Foundation
import SnapKit
import LarkUIKit
import LarkOpenChat
import UniverseDesignCheckBox
import UniverseDesignColor

struct GroupSettingSelectItem: CommonCellItemProtocol {
    var type: LarkOpenChat.ChatSettingCellType
    var cellIdentifier: String
    var style: SeparaterStyle
    var selected: Bool
    let key: String
    let description: String
    var callBack: ((String) -> Void)?
}

class GroupSettingSelectItemCell: GroupSettingCell {
    private let subtitleLabel = UILabel()
    private let checkBox = UDCheckBox(boxType: .single)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // not intercept the cell click event
        checkBox.isUserInteractionEnabled = false
        contentView.addSubview(checkBox)
        checkBox.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(16)
            make.size.equalTo(LKCheckbox.Layout.iconMidSize)
        }

        subtitleLabel.textColor = UIColor.ud.textTitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        self.contentView.addSubview(subtitleLabel)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(13)
            make.bottom.equalToSuperview().offset(-13)
            make.height.greaterThanOrEqualTo(22)
            make.left.equalTo(checkBox.snp.right).offset(12)
            make.right.equalToSuperview().offset(-16)
        }
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(tap))
        self.contentView.addGestureRecognizer(tapGes)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? GroupSettingSelectItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        subtitleLabel.text = item.description
        checkBox.isSelected = item.selected
        layoutSeparater(item.style)
    }

    @objc
    func tap() {
        guard let item = self.item as? GroupSettingSelectItem else { return }
        item.callBack?(item.key)
    }
}
