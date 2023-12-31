//
//  GroupSettingSingleCheckCell.swift
//  LarkChatSetting
//
//  Created by bytedance on 2021/10/26.
//

import UIKit
import Foundation
import LarkUIKit

final class GroupSettingSingleCheckCell: GroupSettingCell {
    let checkImage: UIImageView = UIImageView(image: Resources.listCheck)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        titleLabel.numberOfLines = 1
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        contentView.addSubview(checkImage)
        checkImage.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
            make.width.height.equalTo(24)
        }
        checkImage.isHidden = true
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
