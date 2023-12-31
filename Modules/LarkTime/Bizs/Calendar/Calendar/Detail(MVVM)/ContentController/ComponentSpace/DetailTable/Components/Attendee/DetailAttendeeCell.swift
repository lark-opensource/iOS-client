//
//  AttendeeCombo.swift
//  Calendar
//
//  Created by jiayi zou on 2018/2/4.
//  Copyright © 2018年 EE. All rights reserved.
//

import UniverseDesignIcon
import UIKit
import CalendarFoundation
protocol DetailAttendeeCellViewDataType {
    var countLabelText: String? { get }
    var statusLabelText: String? { get }
    var avatars: [(avatar: Avatar, statusImage: UIImage?)] { get }
    var withEllipsisIcon: Bool { get }
    var totalCount: Int32 { get }
}

// 完整的attendee
final class DetailAttendeeCell: EventBasicCellLikeView {
    var viewData: DetailAttendeeCellViewDataType? {
        didSet {
            guard let viewData = viewData else { return }
            countLabel.text = viewData.countLabelText
            statusLabel.text = viewData.statusLabelText
            avatarContainer.subviews.forEach { $0.removeFromSuperview() }
            guard viewData.avatars.count <= 6 else {
                assertionFailure("展示人数超限")
                return
            }
            viewData.avatars.forEach { (avatar, statusImage) in
                let avatarView = EventDetailAvatarView()
                avatarView.setStatusImage(statusImage)
                avatarContainer.addArrangedSubview(avatarView)
                avatarView.snp.makeConstraints {
                    $0.size.equalTo(CGSize(width: 32, height: 32))
                }
                avatarView.setAvatar(avatar, with: 32)
            }
            if viewData.withEllipsisIcon {
                let iconImage = UDIcon.getIconByKey(.moreBoldOutlined).renderColor(with: .n3)
                let ellipsisIcon = UIImageView(image: iconImage)
                let iconWrapper = UIView()
                iconWrapper.layer.cornerRadius = 16
                iconWrapper.addSubview(ellipsisIcon)
                iconWrapper.backgroundColor = UIColor.ud.bgBodyOverlay
                ellipsisIcon.snp.makeConstraints {
                    $0.size.equalTo(CGSize(width: 16, height: 16))
                    $0.centerX.centerY.equalToSuperview()
                }
                avatarContainer.addArrangedSubview(iconWrapper)
                iconWrapper.snp.makeConstraints {
                    $0.size.equalTo(CGSize(width: 32, height: 32))
                }
            }

            // dirty 不展示人数相关内容
            guard let countLabelText = countLabel.text, let statusLabelText = statusLabel.text,
                  !countLabelText.isEmpty, !statusLabelText.isEmpty else {
                countLabel.isHidden = true
                statusLabel.isHidden = true
                iconAlignment = .topByOffset(19)
                avatarContainer.snp.remakeConstraints {
                    $0.left.equalToSuperview()
                    $0.right.lessThanOrEqualToSuperview()
                    $0.height.equalTo(32)
                    $0.top.equalToSuperview().offset(10)  // countLabel、statusLabel 不显示时是 10，显示时是 14
                    $0.bottom.equalToSuperview().offset(-10)
                }
                oneAttendeeTip.text = BundleI18n.Calendar.Calendar_Plural_FullDetailStringOfGuests(number: viewData.totalCount)
                oneAttendeeTip.isHidden = viewData.totalCount != 1
                return
            }
            countLabel.isHidden = false
            statusLabel.isHidden = false
            avatarContainer.snp.remakeConstraints {
                $0.left.equalToSuperview()
                $0.right.lessThanOrEqualToSuperview()
                $0.height.equalTo(32)
                $0.top.equalTo(statusLabel.snp.bottom).offset(14)
                $0.bottom.equalToSuperview().offset(-10)
            }
            oneAttendeeTip.isHidden = true
        }
    }

    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.ud.body0(.fixed)
        return label
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 0
        label.font = UIFont.ud.body2(.fixed)
        return label
    }()

    private lazy var avatarContainer: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    private lazy var oneAttendeeTip: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.ud.body2(.fixed)
        return label
    }()
    private let image = UDIcon.getIconByKey(.rightOutlined, size: EventBasicCellLikeView.Style.rightIconSize).renderColor(with: .n2)

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        let contentView = setupContentView()
        content = .customView(contentView)

        icon = .customImage(UDIcon.getIconByKey(.groupOutlined, size: CGSize(width: 16, height: 16)).renderColor(with: .n3))
        iconAlignment = .topByOffset(13)

        accessory = .customImage(image)
        accessoryAlignment = .centerYEqualTo(refView: avatarContainer)
        backgroundColors = (UIColor.clear, UIColor.ud.fillHover)
    }

    private func setupContentView() -> UIView {
        let content = UIView()
        content.addSubview(countLabel)
        countLabel.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.height.equalTo(22)
            $0.top.equalToSuperview().offset(10)
        }

        content.addSubview(statusLabel)
        statusLabel.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.height.greaterThanOrEqualTo(20)
            $0.top.equalTo(countLabel.snp.bottom).offset(2)
        }

        content.addSubview(avatarContainer)
        avatarContainer.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.right.lessThanOrEqualToSuperview()
            $0.height.equalTo(32)
            $0.top.equalTo(statusLabel.snp.bottom).offset(14)
            $0.bottom.equalToSuperview().offset(-10)
        }

        content.addSubview(oneAttendeeTip)
        oneAttendeeTip.snp.makeConstraints {
            $0.right.equalToSuperview()
            $0.centerY.equalTo(avatarContainer)
        }

        oneAttendeeTip.isHidden = true

        return content
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// 拿不到参与者的
final class DetailCannotGetBookerInfoMeetingRoomCell: DetailSingleLineCell {
    override init() {
        super.init()
        self.setLeadingIcon(UDIcon.getIconByKeyNoLimitSize(.groupOutlined).renderColor(with: .n3))
        self.setText(BundleI18n.Calendar.Calendar_Detail_DetailHiddenTip)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// 设置了隐藏参与者的
final class DetailHiddenAttendeeCell: DetailSingleLineCell {
    override init() {
        super.init()
        self.setLeadingIcon(UDIcon.getIconByKeyNoLimitSize(.groupOutlined).renderColor(with: .n3))
        self.setText(BundleI18n.Calendar.Calendar_Detail_HiddenGuestList)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 组织者信息
protocol DetailContactAttendeeContent {
    var avatar: (avatar: Avatar, statusImage: UIImage?) { get }
    var contactCalendarId: String { get }
    var chatterID: String? { get }
    var isSingleLine: Bool { get }
    var tagStrings: [(tag: String, textColor: UIColor)] { get }
}

protocol DetailCreatorContent {
    var creatorInfo: String { get }
}

protocol DetailContactCell {
    var view: UIView { get }
    var tapAction: (() -> Void)? { get set }
    func updateContent(_ content: DetailContactAttendeeContent)
}
