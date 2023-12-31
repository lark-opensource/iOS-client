//
//  CalendarShareMemberCell.swift
//  Calendar
//
//  Created by Hongbin Liang on 8/22/23.
//

import Foundation
import UIKit
import LarkTag
import UniverseDesignIcon

protocol CalendarShareMemberCellDelegate: AnyObject {
    func cellDetail(from cell: CalendarShareMemberCell)
}

/// copy from CalendarEditMemberCell, 仅交互细节上有出入，复用成本较高，故 copy 一份
class CalendarShareMemberCell: EventBasicCellLikeView.BackgroundView {

    weak var delegate: CalendarShareMemberCellDelegate?

    private(set) var cellData: CalendarMemberCellDataType?

    func setUp(with data: CalendarMemberCellDataType) {
        avatar.setAvatar(data.avatar, with: 40)
        titleLabel.text = data.title
        roleLabel.text = data.role.cd.shareOption
        roleTag.text = data.ownerTagStr
        relationTag.text = data.relationTagStr

        roleTag.isHidden = data.ownerTagStr.isEmpty
        relationTag.isHidden = data.relationTagStr.isEmpty

        roleLabel.textColor = data.isEditable ? .ud.textTitle : .ud.textDisabled
        arrowIcon.image = arrowImage.renderColor(with: data.isEditable ? .n3 : .n4)

        backgroundColors = (UIColor.ud.bgBody, UIColor.ud.fillPressed)
        cellData = data
    }

    private let avatar = AvatarView()
    private let titleLabel = UILabel.cd.textLabel()
    private let relationTag = TagWrapperView.titleTagView(for: .external)
    private let roleTag = TagWrapperView.titleTagView(for: .external)
    private let subTitleLabel = UILabel.cd.subTitleLabel()

    private(set) var roleLabel = UILabel.cd.subTitleLabel()
    private let arrowIcon = UIImageView()

    private lazy var arrowImage: UIImage = {
        return UDIcon.getIconByKey(.rightBoldOutlined, size: CGSize(width: 12, height: 12))
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColors = (UIColor.ud.bgBody, UIColor.ud.fillPressed)

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
    }

    @objc
    private func cellTapped() {
        guard !arrowIcon.isHidden else { return }
        delegate?.cellDetail(from: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
