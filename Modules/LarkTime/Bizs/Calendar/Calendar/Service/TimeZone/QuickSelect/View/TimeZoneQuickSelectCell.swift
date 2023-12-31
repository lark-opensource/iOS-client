//
//  TimeZoneQuickSelectCell.swift
//  Calendar
//
//  Created by 张威 on 2020/1/16.
//

import UniverseDesignIcon
import UIKit

protocol TimeZoneQuickSelectCellDataType {
    var isLocal: Bool { get }
    var isSelected: Bool { get }
    var timeZoneName: String { get }
    var gmtOffsetDescription: String { get }
}

final class TimeZoneQuickSelectCell: UITableViewCell {

    var viewData: TimeZoneQuickSelectCellDataType? {
        didSet {
            nameLabel.text = viewData?.timeZoneName
            descLabel.text = viewData?.gmtOffsetDescription
            localMarkView.isHidden = !(viewData?.isLocal ?? false)
            selectedAccessoryView.isHidden = !(viewData?.isSelected ?? false)
            setNeedsLayout()
        }
    }

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var descLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private lazy var selectedAccessoryView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKeyNoLimitSize(.doneOutlined).ud.withTintColor(UIColor.ud.primaryContentDefault)
        imageView.isHidden = true
        return imageView
    }()

    private lazy var localMarkView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKeyNoLimitSize(.localFilled).renderColor(with: .n3)
        imageView.isHidden = true
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        contentView.addSubview(selectedAccessoryView)
        selectedAccessoryView.snp.makeConstraints {
            $0.size.equalTo(16)
            $0.right.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }

        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.height.equalTo(22)
            $0.top.equalToSuperview().inset(14)
        }

        contentView.addSubview(localMarkView)
        localMarkView.snp.makeConstraints {
            $0.size.equalTo(14)
            $0.left.equalTo(nameLabel.snp.right).offset(6)
            $0.centerY.equalTo(nameLabel)
            $0.right.lessThanOrEqualTo(selectedAccessoryView.snp.left).offset(-6)
        }

        contentView.addSubview(descLabel)
        descLabel.snp.makeConstraints {
            $0.left.equalTo(nameLabel)
            $0.height.equalTo(20)
            $0.bottom.equalToSuperview().inset(14)
        }
        self.contentView.backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
