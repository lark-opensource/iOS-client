//
//  MailGroupMemberManagedCell.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/27.
//

import Foundation
import UIKit
import SnapKit
import LarkTag
import RxSwift
import RxCocoa
import LarkUIKit
import LarkModel
import LarkFocus
import LarkListItem

protocol MailGroupMemberManagedCellProtocol {
    var isCheckboxHidden: Bool { get set }
    var isCheckboxSelected: Bool { get set }
    var item: GroupInfoMemberItem? { get }
    func set(_ item: GroupInfoMemberItem)
    func setCellSelect(canSelect: Bool,
                       isSelected: Bool,
                       isCheckboxHidden: Bool)
}

extension MailGroupMemberManagedCellProtocol {
    func setCellSelect(canSelect: Bool,
                       isSelected: Bool,
                       isCheckboxHidden: Bool) {
    }
}

protocol ChatChatterSectionHeaderProtocol {
    func set(_ item: GroupInfoMemberItem)
}

final class MailGroupMemberManagedCell: BaseTableViewCell, MailGroupMemberManagedCellProtocol {
    public private(set) var infoView: ListItem
    public var isCheckboxHidden: Bool {
        get { return infoView.checkBox.isHidden }
        set {
//            guard item?.isSelectedable ?? false else {
//                infoView.checkBox.isHidden = true
//                return
//            }
            infoView.checkBox.isHidden = newValue
        }
    }

    public func setCellSelect(canSelect: Bool,
                              isSelected: Bool,
                              isCheckboxHidden: Bool) {
        self.isCheckboxHidden = isCheckboxHidden
        infoView.checkBox.isSelected = isSelected
        infoView.checkBox.isEnabled = canSelect
        self.isUserInteractionEnabled = canSelect
    }

    public var isCheckboxSelected: Bool {
        get { return infoView.checkBox.isSelected }
        set { infoView.checkBox.isSelected = newValue }
    }

    public private(set) var item: GroupInfoMemberItem?

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        infoView = ListItem()
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(infoView)
        infoView.snp.makeConstraints { $0.edges.equalToSuperview() }

        infoView.checkBox.isHidden = true
        infoView.statusLabel.isHidden = true
        infoView.additionalIcon.isHidden = true
        infoView.additionalIcon.maxTagCount = 3
        infoView.nameTag.isHidden = true
        infoView.infoLabel.isHidden = true

        // 禁掉 UserInteractionEnabled 然后使用TableView的didselected回调
        infoView.checkBox.isUserInteractionEnabled = false
        backgroundColor = UIColor.ud.bgBody
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func timeStringFormatter(withTimeZoneId timeZoneId: String) -> String? {
        guard let chatterTimeZone = TimeZone(identifier: timeZoneId),
            chatterTimeZone.secondsFromGMT() != TimeZone.current.secondsFromGMT() else {
            return nil
        }
        return Date().lf.formatedOnlyTime(accurateToSecond: false, timeZone: chatterTimeZone)
    }

    public func set(_ item: GroupInfoMemberItem) {

        self.item = item

        if let img = item.avatarImage {
            infoView.avatarView.image = img
        } else if !item.itemAvatarKey.isEmpty && !item.itemId.isEmpty {
            infoView.avatarView.setAvatarByIdentifier(item.itemId, avatarKey: item.itemAvatarKey,
                                                      avatarViewParams: .init(sizeType: .size(infoView.avatarSize)))
        } else {
            infoView.avatarView.image = MailGroupHelper.generateAvatarImage(withNameString: String(item.itemName.prefix(2)).uppercased())
        }
        infoView.nameLabel.text = item.itemName

        infoView.bottomSeperator.isHidden = true

        if let tas = item.itemTags {
            infoView.nameTag.setElements(tas)
            infoView.nameTag.isHidden = false
        } else {
            infoView.nameTag.isHidden = true
        }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        infoView.avatarView.setAvatarByIdentifier("", avatarKey: "")
        infoView.avatarView.image = nil
        infoView.nameLabel.text = nil
        infoView.additionalIcon.isHidden = true
    }
}
