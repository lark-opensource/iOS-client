//
//  UrgentChatterCell.swift
//  LarkUrgent
//
//  Created by 李勇 on 2019/6/7.
//

import UIKit
import Foundation
import LarkUIKit
import LarkCore
import LarkTag
import LarkBizAvatar
import LarkListItem
import LarkBizTag

/// 加急选人cell所具备的能力
protocol UrgentChatterCellProtocol {
    var isCheckboxSelected: Bool { get set }
    var item: UrgentChatterModel? { get set }
    func set(_ item: UrgentChatterModel, filterKey: String?)
}

/// 加急选人cell
final class UrgentChatterCell: BaseTableViewCell, UrgentChatterCellProtocol {
    private var personInfoView = ListItem()

    var item: UrgentChatterModel?

    var isCheckboxSelected: Bool {
        get { return self.personInfoView.checkBox.isSelected }
        set { self.personInfoView.checkBox.isSelected = newValue }
    }
    private lazy var builder = ChatterTagViewBuilder()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.ud.bgBody
        self.contentView.addSubview(self.personInfoView)
        self.personInfoView.setNameTag(builder.build())
        personInfoView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(_ item: UrgentChatterModel, filterKey: String?) {
        self.item = item
        self.personInfoView.checkBox.isEnabled = (item.hitDenyReason == nil)
        /// 头像
        self.personInfoView.avatarView.setAvatarByIdentifier(item.chatter.id, avatarKey: item.chatter.avatarKey,
                                                             avatarViewParams: .init(sizeType: .size(personInfoView.avatarSize)))
        /// 名字
        if filterKey?.isEmpty == false {
            self.personInfoView.nameLabel.attributedText =
                item.itemName.lu.stringWithHighlight(
                    highlightText: filterKey ?? "",
                    pinyinOfString: item.chatter.namePinyin,
                    normalColor: UIColor.ud.N900)
        } else {
            self.personInfoView.nameLabel.text = item.itemName
        }
        /// 工作状态
        self.personInfoView.setDescription(NSAttributedString(string: ""), descriptionType: .onDefault)
        /// tags
        builder.update(with: item.itemTags ?? [])
        /// 时间
        self.personInfoView.timeLabel.timeString = nil
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        self.personInfoView.nameTag.clean()
    }
}
