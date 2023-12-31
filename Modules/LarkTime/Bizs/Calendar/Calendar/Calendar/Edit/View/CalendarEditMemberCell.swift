//
//  CalendarEditMemberCell.swift
//  Calendar
//
//  Created by Hongbin Liang on 3/23/23.
//

import Foundation
import UIKit
import LarkTag
import UniverseDesignIcon

protocol CalendarEditMemberCellDelegate: AnyObject {
    func cellDetail(from cell: CalendarEditMemberCell)
    func profileTapped(from cell: CalendarEditMemberCell)
}

protocol CalendarMemberCellDataType {
    var avatar: AvatarImpl { get }
    var title: String { get }
    var isGroup: Bool { get }
    var ownerTagStr: String? { get }
    var relationTagStr: String? { get }
    var role: Rust.CalendarAccessRole { get }
    var highestRole: Rust.CalendarAccessRole? { get }
    var canJumpProfile: Bool { get }
    var isEditable: Bool { get }
}

class CalendarEditMemberCell: EventBasicCellLikeView.BackgroundView {

    weak var delegate: CalendarEditMemberCellDelegate?

    private(set) var cellData: CalendarMemberCellDataType?

    func setUp(with data: CalendarMemberCellDataType) {
        avatar.setAvatar(data.avatar, with: 40)
        titleLabel.text = data.title
        roleLabel.text = data.role.cd.shareOption
        roleTag.text = data.ownerTagStr
        relationTag.text = data.relationTagStr

        roleTag.isHidden = data.ownerTagStr.isEmpty
        relationTag.isHidden = data.relationTagStr.isEmpty
        arrowIcon.isHidden = !data.isEditable

        let highLightColor = data.isEditable ? UIColor.ud.fillPressed : UIColor.ud.panelBgColor
        backgroundColors = (UIColor.ud.panelBgColor, highLightColor)
        cellData = data
    }

    private let avatar = AvatarView()
    private let titleLabel = UILabel.cd.textLabel()
    private let relationTag = TagWrapperView.titleTagView(for: .external)
    private let roleTag = TagWrapperView.titleTagView(for: .external)
    private let subTitleLabel = UILabel.cd.subTitleLabel()

    private let roleLabel = UILabel.cd.subTitleLabel()
    private let arrowIcon = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColors = (UIColor.ud.panelBgColor, UIColor.ud.fillPressed)

        let nameStack = UIStackView(arrangedSubviews: [titleLabel, roleTag, relationTag])
        nameStack.spacing = 8
        nameStack.alignment = .center

        let wrapper = UIView()
        wrapper.addSubview(nameStack)
        nameStack.snp.makeConstraints {
            $0.left.top.bottom.equalToSuperview()
            $0.right.lessThanOrEqualToSuperview()
        }

        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let horizontalContainer = UIStackView(arrangedSubviews: [avatar, wrapper, roleLabel, arrowIcon])
        horizontalContainer.spacing = 12
        horizontalContainer.alignment = .center

        arrowIcon.image = UDIcon.getIconByKey(.rightBoldOutlined, size: CGSize(width: 12, height: 12)).renderColor(with: .n3)
        arrowIcon.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 12, height: 12))
        }

        addSubview(horizontalContainer)
        horizontalContainer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.bottom.centerY.equalToSuperview()
            $0.height.equalTo(70)
        }

        avatar.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 40, height: 40))
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        addGestureRecognizer(tapGesture)
        let avatarTapGes = UITapGestureRecognizer(target: self, action: #selector(avatarTapped))
        avatar.addGestureRecognizer(avatarTapGes)
    }

    @objc
    private func cellTapped() {
        guard !arrowIcon.isHidden else { return }
        delegate?.cellDetail(from: self)
    }

    @objc
    private func avatarTapped() {
        guard !avatar.isHidden, let cellData = cellData, cellData.canJumpProfile else { return }
        delegate?.profileTapped(from: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
