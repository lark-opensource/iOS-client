//
//  GroupFreeBusyChatterDatas.swift
//  LarkChat
//
//  Created by zoujiayi on 2019/7/30.
//

import UIKit
import Foundation
import LarkModel
import LarkTag
import LarkCore
import LarkUIKit
import LarkListItem
import LarkBizTag
import LarkContainer

public final class GroupFreeBusyChatterCell: UITableViewCell, ChatChatterCellProtocol {
    fileprivate var infoView: ListItem
    public var isCheckboxHidden: Bool {
        get { return infoView.checkBox.isHidden }
        set { infoView.checkBox.isHidden = item?.isSelectedable == false || newValue }
    }

    public var isCheckboxSelected: Bool {
        get { return infoView.checkBox.isSelected }
        set { infoView.checkBox.isSelected = newValue }
    }

    public var item: ChatChatterItem?

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        infoView = ListItem()
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = UIColor.ud.bgBody

        contentView.addSubview(infoView)
        infoView.snp.makeConstraints { $0.edges.equalToSuperview() }

        infoView.checkBox.isHidden = true
        infoView.statusLabel.isHidden = true
        infoView.nameTag.isHidden = true
        infoView.infoLabel.isHidden = true

        // 禁掉 UserInteractionEnabled 然后使用TableView的didselected回调
        infoView.checkBox.isUserInteractionEnabled = false

        selectedBackgroundView = BaseCellSelectView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(_ item: ChatChatterItem, filterKey: String?, userResolver: UserResolver) {

        self.item = item

        infoView.avatarView.setAvatarByIdentifier(item.itemId, avatarKey: item.itemAvatarKey,
                                                  avatarViewParams: .init(sizeType: .size(infoView.avatarSize)))
        infoView.nameLabel.text = item.itemName

        if filterKey?.isEmpty == false {
            infoView.nameLabel.attributedText = item.itemName.lu.stringWithHighlight(
                highlightText: filterKey ?? "",
                pinyinOfString: item.itemPinyinOfName,
                normalColor: UIColor.ud.N900)
        } else {
            infoView.nameLabel.text = item.itemName
        }

        if let description = item.itemDescription {
            infoView.statusLabel.isHidden = false
            infoView.setDescription(NSAttributedString(string: description.text), descriptionType: ListItem.DescriptionType(rawValue: description.type.rawValue))
        } else {
            infoView.statusLabel.isHidden = true
        }

        if let tags = item.itemTags {
            infoView.nameTag.setElements(tags)
            infoView.nameTag.isHidden = false
        }

        infoView.bottomSeperator.isHidden = item.isBottomLineHidden
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        infoView.avatarView.image = nil
        infoView.avatarView.setAvatarByIdentifier("", avatarKey: "")
        infoView.nameLabel.text = nil
        infoView.nameTag.isHidden = true
        infoView.statusLabel.isHidden = true
    }
}
