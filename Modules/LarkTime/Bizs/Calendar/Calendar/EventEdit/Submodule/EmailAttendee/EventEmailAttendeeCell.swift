//
//  EventEmailAttendeeCell.swift
//  Calendar
//
//  Created by 张威 on 2020/6/5.
//

import UIKit
import UniverseDesignIcon
import LarkBizAvatar

protocol EventEmailAttendeeCellDataType {
    var avatar: Avatar { get }
    var address: String { get }
    var canDelete: Bool { get }
}

final class EventEmailAttendeeCell: UITableViewCell, ViewDataConvertible {

    var viewData: EventEmailAttendeeCellDataType? {
        didSet {
            if let avatar = viewData?.avatar {
                avatarView.setAvatar(avatar, with: 48)
            }
            titleLabel.text = viewData?.address
            deleteButton.isHidden = !(viewData?.canDelete ?? false)
        }
    }

    var deleteHandler: (() -> Void)?

    private var avatarView = AvatarView()
    private var titleLabel: UILabel = UILabel()
    private var deleteButton: UIButton = UIButton()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 48, height: 48))
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().offset(16)
        }

        deleteButton.setImage(UDIcon.getIconByKeyNoLimitSize(.closeOutlined).scaleInfoSize().renderColor(with: .n2), for: .normal)
        deleteButton.addTarget(self, action: #selector(didDeleteButtonClick), for: .touchUpInside)
        deleteButton.increaseClickableArea()
        contentView.addSubview(deleteButton)
        deleteButton.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 16, height: 16))
            $0.right.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }

        titleLabel.font = UIFont.cd.regularFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.left.equalTo(avatarView.snp.right).offset(16)
            $0.right.equalTo(deleteButton.snp.left).offset(-16)
            $0.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didDeleteButtonClick() {
        deleteHandler?()
    }

}
