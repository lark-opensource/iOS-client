//
//  MailContactsContentTableViewCell.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/8/27.
//

import Foundation
import UIKit
import SnapKit
import LarkCore
import LarkModel
import LarkUIKit
import LarkTag
import LarkAccountInterface
import LarkMessengerInterface
import LarkListItem
import LarkSDKInterface

final class MailContactsContentTableViewCell: UITableViewCell {
    private let _contentView = UIView()
    private let personInfoView = ListItem()

    // 用于选中时弹出不可选中toast
    var canSelect: Bool = true

    override public var contentView: UIView {
        return self._contentView
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.backgroundColor = UIColor.ud.bgBody

        self.selectedBackgroundView = BaseCellSelectView()

        self.addSubview(_contentView)
        _contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        contentView.addSubview(personInfoView)
        personInfoView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        personInfoView.avatarView.image = nil
    }

    typealias TimeStringFormatter = (_ timeZoneId: String) -> String?

    func updateSelected(isSelected: Bool) {
        personInfoView.checkBox.isSelected = isSelected
    }
}

// MARK: for MailContactsItemCellViewModel
extension MailContactsContentTableViewCell {
    func setCellViewModel(viewModel: MailContactsItemCellViewModel,
                          canSelect: Bool,
                          isSelected: Bool) {
        self.selectionStyle = canSelect ? .default : .none
        self.canSelect = canSelect

        personInfoView.checkBox.isHidden = false
        personInfoView.checkBox.isEnabled = true
        personInfoView.checkBox.isSelected = isSelected
        personInfoView.statusLabel.isHidden = true

        if !self.canSelect {
            if self.personInfoView.checkBox.isHidden == false {
                personInfoView.checkBox.isEnabled = false
            }
        }

        if !viewModel.avatarKey.isEmpty {
            personInfoView.avatarView.setAvatarByIdentifier(viewModel.entityId,
                                                            avatarKey: viewModel.avatarKey,
                                                            avatarViewParams: .init(sizeType: .size(personInfoView.avatarSize)))
        } else if let image = viewModel.customAvatar {
            personInfoView.avatarView.image = image
        } else {
            personInfoView.avatarView.image = MailGroupHelper.generateAvatarImage(withNameString: viewModel.title)
        }

        let titleAttr = NSAttributedString(string: viewModel.title)
        personInfoView.nameLabel.attributedText = titleAttr

        let subtitleAttr = NSAttributedString(string: viewModel.subTitle)
        personInfoView.infoLabel.attributedText = subtitleAttr
        personInfoView.infoLabel.isHidden = false

        // TODO: MAIL_CONTACT
        if let tag = viewModel.tag {
            personInfoView.nameTag.setElements([tag])
            personInfoView.nameTag.isHidden = false
        } else {
            personInfoView.nameTag.isHidden = true
        }
    }
}
