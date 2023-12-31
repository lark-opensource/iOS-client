//
//  PersonalCardHeaderviewCell.swift
//  Calendar
//
//  Created by harry zou on 2019/4/8.
//

import UIKit
import Foundation
import CalendarFoundation
import SnapKit

final class PersonalCardHeaderviewCell: UICollectionViewCell {
    static let height: CGFloat = 72
    private var model: ArrangementHeaderViewCellModel?

    private let avatarView: FreeBusyAvatarView = {
        let avatarView = FreeBusyAvatarView(displaySize: CGSize(width: 40, height: 40))
        return avatarView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = UIColor.ud.N800
        label.font = UIFont.cd.regularFont(ofSize: 12)
        label.textAlignment = .left
        return label
    }()

    private let timeLabel: TimeWithSunStateView = {
        return TimeWithSunStateView()
    }()

    private let weekLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.cd.regularFont(ofSize: 11)
        label.textAlignment = .left
        return label
    }()

    private var labelStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layout(avatarView: avatarView)
        layoutStackView(labelStackView,
                        nameLabel: nameLabel,
                        timeLabel: timeLabel,
                        weekLabel: weekLabel,
                        leftItem: avatarView.snp.right)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout(avatarView: UIView) {
        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.width.height.equalTo(40)
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    private func layoutStackView(_ stackView: UIStackView,
                                 nameLabel: UILabel,
                                 timeLabel: TimeWithSunStateView,
                                 weekLabel: UILabel,
                                 leftItem: ConstraintItem) {
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(leftItem).offset(12)
            make.right.equalToSuperview()
        }

        let timeStack = UIStackView(arrangedSubviews: [timeLabel, weekLabel])
        timeStack.axis = .horizontal
        timeStack.spacing = 4

        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(timeStack)
    }

    func update(with model: ArrangementHeaderViewCellModel) {
        self.model = model
        avatarView.avatar = model.avatar
        avatarView.setIconStatus(showBusyIcon: model.showBusyIcon,
                                 showNotWorkingIcon: model.showNotWorkingIcon)
        nameLabel.text = model.nameString
        if model.hasNoPermission {
            weekLabel.text = BundleI18n.Calendar.Calendar_UnderUser_PrivateCalendarGreyStatus
            timeLabel.isHidden = true
            weekLabel.isHidden = false
        } else if model.timeInfoHidden {
            weekLabel.text = I18n.Calendar_G_HideTimeZone
            timeLabel.isHidden = true
            weekLabel.isHidden = false
        } else {
            if let timeString = model.timeString, let weekString = model.weekString {
                timeLabel.updateTime(timeStr: timeString, atLight: model.atLight)
                weekLabel.text = weekString
            }
            timeLabel.isHidden = model.timeString == nil
            weekLabel.isHidden = model.weekString == nil
        }
    }
}
