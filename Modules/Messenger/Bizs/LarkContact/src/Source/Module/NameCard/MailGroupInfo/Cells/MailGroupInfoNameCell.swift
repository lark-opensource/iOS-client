//
//  MailGroupInfoNameCell.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/19.
//

import UIKit
import Foundation
import LarkUIKit
import LarkBizAvatar
import LarkTag

struct MailGroupInfoNameModel: GroupInfoCellItem {
    var type: GroupInfoItemType {
        return .name
    }

    var name: String
    var entityId: String
    var avatarKey: String
    var email: String
    var tags: [Tag]?
}

final class MailGroupInfoNameCell: MailGroupInfoCell {
    private var avatarImageView = BizAvatar()
    private let avatarSize: CGFloat = 48

    private var nameAndEmailStack = UIStackView()
    private var nameStack = UIStackView()

    private let tagView: TagWrapperView = {
        return TagWrapperView()
    }()

    private var nameLabel = UILabel()
    private var emailLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameAndEmailStack)

        nameStack.axis = .horizontal
        nameStack.spacing = 8
        nameStack.alignment = .leading
        nameStack.distribution = .fill
        nameStack.addArrangedSubview(nameLabel)
        nameStack.addArrangedSubview(tagView)

        nameAndEmailStack.axis = .vertical
        nameAndEmailStack.spacing = 1
        nameAndEmailStack.alignment = .leading
        nameAndEmailStack.distribution = .fill
        nameAndEmailStack.addArrangedSubview(nameStack)
        nameAndEmailStack.addArrangedSubview(emailLabel)

        nameAndEmailStack.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 18, left: 74, bottom: 18, right: 16))
        }

        avatarImageView.snp.makeConstraints { (maker) in
            maker.top.left.bottom.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 0))
            maker.width.height.equalTo(avatarSize)
        }
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                     action: #selector(avatarTap)))

        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.numberOfLines = 1

        emailLabel.font = UIFont.systemFont(ofSize: 14)
        emailLabel.textColor = UIColor.ud.textPlaceholder
        emailLabel.snp.makeConstraints { (maker) in
            maker.height.equalTo(20)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let nameItem = item as? MailGroupInfoNameModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        avatarImageView.image = MailGroupHelper
            .generateAvatarImage(withNameString: String(nameItem.name.prefix(2)).uppercased())
        nameLabel.text = nameItem.name

        emailLabel.text = nameItem.email

        if let tags = nameItem.tags {
            tagView.setElements(tags)
            tagView.isHidden = false
        } else {
            tagView.setElements([])
            tagView.isHidden = true
        }

        arrow.isHidden = true
        layoutSeparater(.auto)
    }

    @objc
    private func avatarTap() {
        // TODO: anything?
    }
}
