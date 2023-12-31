//
//  AtListTableViewCell.swift
//  Moment
//
//  Created by zc09v on 2021/3/23.
//

import Foundation
import UIKit
import LarkListItem

final class AtListTableViewCell: UITableViewCell {
    static let indentify: String = "AtListTableViewCell"
    private let infoView: ListItem

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
        infoView.bottomSeperator.isHidden = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(user: MomentUser) {
        infoView.avatarView.setAvatarByIdentifier(user.userID,
                                                  avatarKey: user.avatarKey,
                                                  scene: .Moments,
                                                  avatarViewParams: .init(sizeType: .size(infoView.avatarSize)))
        infoView.nameLabel.text = user.displayName
        if user.momentLarkUser.fullDepartmentPath.isEmpty {
            infoView.infoLabel.text = ""
            infoView.infoLabel.isHidden = true
        } else {
            infoView.infoLabel.text = user.momentLarkUser.fullDepartmentPath
            infoView.infoLabel.isHidden = false
        }
    }
}
