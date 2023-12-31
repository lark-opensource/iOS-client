//
//  MeetingRoomHomeTableViewCell.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/5/8.
//

import UniverseDesignIcon
import UIKit
import SnapKit

final class MeetingRoomHomeTableViewCell: UITableViewCell {

    private lazy var infoView = InfoView(frame: .zero)
    private lazy var detailIndicatorView: UIImageView = {
        let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.rightOutlined).renderColor(with: .n3))
        return imageView
    }()

    private lazy var instancesView: MeetingRoomDayInstancesView = {
        let view = MeetingRoomDayInstancesView()
        return view
    }()

    var title = "" {
        didSet {
            infoView.titleLabel.text = title
        }
    }

    var needApproval = false {
        didSet {
            infoView.approveTag.isHidden = !needApproval
        }
    }

    var capacity: Int32 = 0 {
        didSet {
            infoView.capacityLabel.text = "\(capacity)"
        }
    }

    var equipment = "" {
        didSet {
            infoView.updateEquipment(text: equipment)
        }
    }

    var pathName = "" {
        didSet {
            infoView.updatePathName(text: pathName)
        }
    }

    var instances: [MeetingRoomDayInstancesView.SimpleInstance] {
        get { instancesView.instances }
        set { instancesView.instances = newValue }
    }

    var currentTime: Date? {
        get { instancesView.currentTime }
        set { instancesView.currentTime = newValue }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentTime = nil
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        contentView.addSubview(infoView)
        contentView.addSubview(detailIndicatorView)
        contentView.addSubview(instancesView)

        infoView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        detailIndicatorView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        infoView.snp.makeConstraints { make in
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.top.equalToSuperview().offset(12)
        }

        detailIndicatorView.snp.makeConstraints { make in
            make.centerY.equalTo(infoView)
            make.trailing.equalTo(contentView.snp.trailingMargin)
            make.leading.equalTo(infoView.snp.trailing).offset(10)
            make.size.equalTo(CGSize(width: 16, height: 16))
        }

        instancesView.snp.makeConstraints { make in
            make.leading.equalTo(contentView.snp.leadingMargin)
            make.trailing.equalTo(contentView.snp.trailingMargin)
            make.top.equalTo(infoView.snp.bottom).offset(12)
//            make.bottom.equalToSuperview().offset(-16)
        }

        backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MeetingRoomHomeTableViewCell {
    final class InfoView: UIView {
        private(set) lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.body0
            label.text = BundleI18n.Calendar.Calendar_Common_Close
            label.textColor = UIColor.ud.textTitle
            label.numberOfLines = 1
            return label
        }()

        private(set) lazy var approveTag: UIView = {
            TagViewProvider.needApproval
        }()

        private(set) lazy var icon: UIImageView = {
            let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.groupOutlined).renderColor(with: .n3))
            imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
            imageView.setContentHuggingPriority(.required, for: .horizontal)
            return imageView
        }()

        private(set) lazy var capacityLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.body3
            label.textColor = UIColor.ud.textPlaceholder
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            label.setContentHuggingPriority(.required, for: .horizontal)
            return label
        }()

        private(set) lazy var equipmentLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.body3
            label.textColor = UIColor.ud.textPlaceholder
            return label
        }()

        private(set) lazy var pathNameLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.body3
            label.textColor = UIColor.ud.textPlaceholder
            return label
        }()

        private(set) lazy var separatorView = UIView()
        private(set) lazy var pathNameSeparatorView = UIView()

        private(set) lazy var subInfoStackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [icon, capacityLabel, separatorView, equipmentLabel, pathNameSeparatorView, pathNameLabel])
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.distribution = .fill
            stackView.spacing = 8
            return stackView
        }()

        private var equipmentLabelMaxWidth: Constraint?
        
        override init(frame: CGRect) {
            super.init(frame: frame)

            addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.leading.top.equalToSuperview()
            }
            addSubview(approveTag)
            approveTag.snp.makeConstraints { make in
                make.centerY.equalTo(titleLabel)
                make.leading.equalTo(titleLabel.snp.trailing).offset(5)
                make.trailing.lessThanOrEqualToSuperview()
            }

            separatorView.backgroundColor = UIColor.ud.textPlaceholder
            separatorView.snp.makeConstraints { make in
                make.width.equalTo(1)
                make.height.equalTo(12)
            }
            pathNameSeparatorView.backgroundColor = UIColor.ud.textPlaceholder
            pathNameSeparatorView.snp.makeConstraints { make in
                make.width.equalTo(1)
                make.height.equalTo(12)
            }
            icon.snp.makeConstraints { make in
                make.width.height.equalTo(16)
            }

            addSubview(subInfoStackView)

            subInfoStackView.snp.makeConstraints { make in
                make.leading.bottom.equalToSuperview()
                make.top.equalTo(titleLabel.snp.bottom).offset(6)
                make.trailing.lessThanOrEqualToSuperview()
            }

            equipmentLabel.snp.remakeConstraints {
                equipmentLabelMaxWidth = $0.width.lessThanOrEqualTo(80).constraint
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func updateEquipment(text: String?) {
            defer {
                updateEquipmentLabelMaxWidth()
            }
            let isHidden = text?.isEmpty ?? true
            self.equipmentLabel.text = text
            self.separatorView.isHidden = isHidden
            self.equipmentLabel.isHidden = isHidden
        }

        func updatePathName(text: String?) {
            defer {
                updateEquipmentLabelMaxWidth()
            }
            let isHidden = text?.isEmpty ?? true
            self.pathNameLabel.text = text
            self.pathNameSeparatorView.isHidden = isHidden
            self.pathNameLabel.isHidden = isHidden
        }

        private func updateEquipmentLabelMaxWidth() {
            if pathNameLabel.isHidden {
                equipmentLabelMaxWidth?.deactivate()
            } else {
                equipmentLabelMaxWidth?.activate()
            }
        }
    }
}
