//
//  GroupSettingToNormalGroupCellAndItem.swift
//  LarkChat
//
//  Created by zoujiayi on 2019/6/12.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkCore

// MARK: - 会议群转普通群 - item
struct GroupSettingToNormalGroupModel: GroupSettingItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle = .none
    var attributedText: NSAttributedString
    var tapHandler: ChatInfoTapHandler
}

// MARK: - 会议群转普通群 - cell
final class GroupSettingToNormalGroupCell: GroupSettingCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
            maker.height.equalTo(52)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let toNormalGroupItem = item as? GroupSettingToNormalGroupModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.attributedText = toNormalGroupItem.attributedText
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let toNormalGroupItem = item as? GroupSettingToNormalGroupModel {
            toNormalGroupItem.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}
