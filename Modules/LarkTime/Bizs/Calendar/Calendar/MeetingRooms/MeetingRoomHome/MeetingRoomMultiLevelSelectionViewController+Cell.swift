//
//  MeetingRoomMultiLevelSelectionViewController+Cell.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/9/3.
//

import Foundation
import RxCocoa
import RxSwift
import UniverseDesignIcon
import UIKit
import SnapKit
import UniverseDesignCheckBox

extension MeetingRoomMultiLevelSelectionViewController {

    final class SectionHeaderCell: UITableViewCell {

        private let titleLabel = UILabel()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            isUserInteractionEnabled = false
        }

        var headerTitle: (title: String, hasTopSep: Bool)? {
            didSet {
                guard let headerTitle = headerTitle else { return }
                titleLabel.text = headerTitle.title
                titleLabel.textColor = .ud.textCaption
                titleLabel.font = .cd.regularFont(ofSize: 14)
                titleLabel.isHidden = headerTitle.title.isEmpty

                let placeHolder = contentView.addTopBorder(lineHeight: headerTitle.hasTopSep ? 8 : 0)
                placeHolder.backgroundColor = .ud.bgBase

                contentView.addSubview(titleLabel)
                titleLabel.snp.makeConstraints { make in
                    make.top.equalTo(placeHolder.snp.bottom).offset(8)
                    make.leading.trailing.equalToSuperview().inset(16)
                    make.bottom.equalToSuperview()
                }
            }
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            contentView.subviews.forEach { $0.removeFromSuperview() }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    final class LevelTableViewCell: UITableViewCell {
        private(set) lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.ud.title4(.fixed)
            label.textColor = UIColor.ud.textTitle
            label.numberOfLines = 1
            label.setContentHuggingPriority(.init(rawValue: 1), for: .horizontal)
            label.setContentCompressionResistancePriority(.init(rawValue: 1), for: .horizontal)
            return label
        }()

        private lazy var needsApprovalTagView: UIView = {
            TagViewProvider.needApproval
        }()

        private lazy var habitualUsedTag: UIView = {
            TagViewProvider.emailTag(with: I18n.Calendar_G_FrequentlyUsed)
        }()

        private lazy var meetingRoomIconView: UIImageView = {
            let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.roomOutlined).renderColor(with: .n3))
            imageView.snp.makeConstraints { $0.width.height.equalTo(16) }
            return imageView
        }()

        private lazy var levelIconView: UIImageView = {
            let imageView = UIImageView(image: UDIcon.organizationOutlined.renderColor(with: .n3))
            imageView.snp.makeConstraints { $0.width.height.equalTo(16) }
            return imageView
        }()

        private lazy var accessoryIcon: UIImageView = {
            let image = UIImageView()
            image.snp.makeConstraints { $0.width.height.equalTo(16) }
            return image
        }()

        private lazy var customAccessoryView: UIView = {
            let view = UIView()
            view.isUserInteractionEnabled = true
            view.addSubview(accessoryIcon)
            accessoryIcon.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.edges.equalToSuperview().inset(16)
            }
            return view
        }()

        fileprivate lazy var meetingRoomInfoTapGesture: UITapGestureRecognizer = {
            let tap = UITapGestureRecognizer()
            customAccessoryView.addGestureRecognizer(tap)
            return tap
        }()

        private lazy var titleStackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [levelIconView, titleLabel])
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.distribution = .fill
            stackView.spacing = 14
            stackView.setCustomSpacing(4, after: titleLabel)
            return stackView
        }()

        private(set) lazy var selectionButton: UDCheckBox = {
            let button = UDCheckBox()
            button.isUserInteractionEnabled = false
            return button
        }()

        private lazy var invisibleSelectionButton: UIButton = {
            let button = UIButton(type: .custom)
            button.setContentCompressionResistancePriority(.init(rawValue: 1), for: .horizontal)
            button.setContentCompressionResistancePriority(.init(rawValue: 1), for: .vertical)
            button.setContentHuggingPriority(.init(rawValue: 1), for: .horizontal)
            button.setContentHuggingPriority(.init(rawValue: 1), for: .vertical)
            return button
        }()

        private(set) lazy var icon: UIImageView = {
            let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.groupOutlined).renderColor(with: .n3))
            imageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            imageView.snp.makeConstraints { make in
                make.width.height.equalTo(12)
            }
            return imageView
        }()

        private(set) lazy var capacityLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.ud.body2(.fixed)
            label.textColor = UIColor.ud.textPlaceholder
            label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            return label
        }()

        private(set) lazy var equipmentLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.ud.body2(.fixed)
            label.textColor = UIColor.ud.textPlaceholder
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            label.setContentHuggingPriority(.defaultLow, for: .horizontal)
            return label
        }()

        private lazy var capacityEquipmentSeparatorView: UIView = {
            let separatorView = UIView()
            separatorView.backgroundColor = UIColor.ud.textPlaceholder
            separatorView.snp.makeConstraints { make in
                make.width.equalTo(1)
                make.height.equalTo(12)
            }
            return separatorView
        }()

        private lazy var meetingRoomInfosStackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [icon, capacityLabel, capacityEquipmentSeparatorView, equipmentLabel])
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.distribution = .fill
            stackView.spacing = 8
            return stackView
        }()

        var state: SelectType {
            get {
                levelDisplayItem.selectType
            }
            set {
                selectionButton.isEnabled = newValue != .disabled
                selectionButton.isSelected = newValue == .selected || newValue == .halfSelected
                selectionButton.updateUIConfig(boxType: newValue.boxType, config: UDCheckBoxUIConfig())
            }
        }

        var disposeBag = DisposeBag()
        private var bottomSepratorLeading: Constraint?
        fileprivate let stateDidChangeSubject = PublishSubject<Void>()

        var levelDisplayItem: LevelsDisplayItem! {
            didSet {
                if let level = levelDisplayItem.level {
                    bottomSepratorLeading?.update(offset: 0)
                    levelIconView.isHidden = false
                    titleLabel.text = level.title
                    titleLabel.textColor = UIColor.ud.textTitle
                    titleStackView.addArrangedSubview(habitualUsedTag)
                    habitualUsedTag.isHidden = !level.isHabitualUsed
                    meetingRoomInfosStackView.isHidden = true
                    accessoryIcon.image = UDIcon.rightOutlined.renderColor(with: .n3)
                    invisibleSelectionButton.isUserInteractionEnabled = true

                    // 极为特化的逻辑 hidden -> enableViewTap -> block cell response -> abort view action
                    customAccessoryView.isUserInteractionEnabled = level.accessaryHidden
                    accessoryIcon.isHidden = level.accessaryHidden
                } else if let meetingRoom = levelDisplayItem.meetingRoom {
                    bottomSepratorLeading?.update(offset: 17)
                    levelIconView.isHidden = true
                    titleLabel.text = meetingRoom.name
                    titleStackView.insertArrangedSubview(meetingRoomIconView, at: 0)
                    titleStackView.addArrangedSubview(needsApprovalTagView)
                    needsApprovalTagView.isHidden = !meetingRoom.needsApproval
                    meetingRoomInfosStackView.isHidden = false
                    accessoryIcon.image = UDIcon.infoOutlined.renderColor(with: .n3)
                    customAccessoryView.isUserInteractionEnabled = true

                    capacityLabel.text = String(meetingRoom.capacity)
                    equipmentLabel.text = meetingRoom.equipments.map(\.i18NName).joined(separator: "·")
                    capacityEquipmentSeparatorView.isHidden = meetingRoom.equipments.isEmpty

                    invisibleSelectionButton.isUserInteractionEnabled = false
                    refreshRoomStateUI(disable: levelDisplayItem.selectType == .disabled)
                } else {
                    assertionFailure()
                }
            }
        }

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            self.selectionStyle = .none
            setupView()
            _ = invisibleSelectionButton.rx.tap.asDriver()
                .drive(onNext: { [weak self] in
                    guard let self = self else { return }
                    switch self.state {
                    case .selected:
                        self.levelDisplayItem.selectType = .nonSelected
                    case .nonSelected, .halfSelected:
                        self.levelDisplayItem.selectType = .selected
                    case .disabled:
                        break
                    }
                    self.stateDidChangeSubject.onNext(())
                })
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupView() {
            contentView.addSubview(customAccessoryView)
            customAccessoryView.snp.makeConstraints { make in
                make.centerY.trailing.equalToSuperview()
            }

            contentView.addSubview(titleStackView)
            titleStackView.snp.makeConstraints { make in
                make.leading.equalToSuperview().inset(16)
                make.centerY.equalToSuperview()
                make.trailing.lessThanOrEqualTo(customAccessoryView.snp.leading)
                make.height.equalTo(22)
            }

            contentView.addSubview(meetingRoomInfosStackView)
            meetingRoomInfosStackView.snp.makeConstraints { make in
                make.leading.equalTo(titleLabel)
                make.top.equalTo(titleLabel.snp.bottom).offset(3.5)
                make.trailing.lessThanOrEqualToSuperview().inset(40)
            }
        }

        func layoutUI(withCheckBox: Bool) {
            if withCheckBox {
                contentView.addSubview(selectionButton)
                selectionButton.snp.makeConstraints { make in
                    make.width.height.equalTo(20)
                    make.centerY.equalToSuperview()
                    make.leading.equalToSuperview().inset(16)
                }

                titleStackView.snp.remakeConstraints { make in
                    make.centerY.equalToSuperview()
                    make.leading.equalTo(selectionButton.snp.trailing).offset(12)
                    make.trailing.lessThanOrEqualTo(customAccessoryView.snp.leading)
                    make.height.equalTo(22)
                }

                contentView.addSubview(invisibleSelectionButton)
                invisibleSelectionButton.snp.makeConstraints { make in
                    make.leading.top.bottom.equalToSuperview()
                    make.trailing.equalTo(customAccessoryView.snp.leading)
                }
            } else {
                selectionButton.removeFromSuperview()

                titleStackView.snp.remakeConstraints { make in
                    make.centerY.equalToSuperview()
                    make.leading.equalToSuperview().inset(16)
                    make.trailing.lessThanOrEqualTo(customAccessoryView.snp.leading)
                    make.height.equalTo(22)
                }

                invisibleSelectionButton.removeFromSuperview()
            }
        }

        private func refreshRoomStateUI(disable: Bool) {
            if disable {
                titleLabel.textColor = UIColor.ud.textDisabled
                capacityLabel.textColor = UIColor.ud.textDisabled
                equipmentLabel.textColor = UIColor.ud.textDisabled
                capacityEquipmentSeparatorView.backgroundColor = UIColor.ud.textDisabled
                icon.image = UDIcon.getIconByKeyNoLimitSize(.groupOutlined).renderColor(with: .n4)
                meetingRoomIconView.image = UDIcon.getIconByKeyNoLimitSize(.roomUnavailableOutlined).renderColor(with: .n4)
            } else {
                titleLabel.textColor = UIColor.ud.textTitle
                capacityLabel.textColor = UIColor.ud.textPlaceholder
                equipmentLabel.textColor = UIColor.ud.textPlaceholder
                capacityEquipmentSeparatorView.backgroundColor = UIColor.ud.textPlaceholder
                icon.image = UDIcon.getIconByKeyNoLimitSize(.groupOutlined).renderColor(with: .n3)
                meetingRoomIconView.image = UDIcon.getIconByKeyNoLimitSize(.roomOutlined).renderColor(with: .n3)
            }
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            meetingRoomInfosStackView.isHidden = true
            titleStackView.removeArrangedSubview(meetingRoomIconView)
            meetingRoomIconView.removeFromSuperview()
            titleStackView.removeArrangedSubview(needsApprovalTagView)
            needsApprovalTagView.removeFromSuperview()
            titleStackView.removeArrangedSubview(habitualUsedTag)
            habitualUsedTag.removeFromSuperview()
            disposeBag = DisposeBag()
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            var size = size
            if levelDisplayItem.level != nil {
                size.height = 64
            } else if levelDisplayItem.meetingRoom != nil {
                size.height = 64
            } else {
                assertionFailure()
            }
            return size
        }
    }
}

extension Reactive where Base == MeetingRoomMultiLevelSelectionViewController.LevelTableViewCell {
    var selectState: Observable<Void> {
        base.stateDidChangeSubject
    }

    var infoIconTapped: ControlEvent<Rust.MeetingRoom> {
        ControlEvent(events: base.meetingRoomInfoTapGesture.rx.event
        .filter { [weak base] (_) -> Bool in
            // abort level tapped
            guard base?.levelDisplayItem.meetingRoom != nil else {
                return false
            }
            return true
        }
        .map { [weak base] (_) -> Rust.MeetingRoom in
            base?.levelDisplayItem.meetingRoom ?? Rust.MeetingRoom()
        })
    }
}
