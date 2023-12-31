//
//  TimeZoneSearchResultCell.swift
//  Calendar
//
//  Created by 张威 on 2020/2/17.
//

import UIKit
import SnapKit

protocol TimeZoneSearchResultCellDataType {
    var timeZoneName: String { get }
    var cityIncludingDescription: String { get }
    var gmtOffsetDescription: String { get }
}

final class TimeZoneSearchResultCell: UITableViewCell {

    var viewData: TimeZoneSearchResultCellDataType? = nil {
        didSet {
            nameLabel.text = viewData?.timeZoneName
            includeLabel.text = viewData?.cityIncludingDescription
            descLabel.text = viewData?.gmtOffsetDescription
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

    private lazy var includeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none

        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16)
            $0.centerY.equalTo(contentView.snp.top).offset(22)
        }

        contentView.addSubview(descLabel)
        descLabel.snp.makeConstraints {
            $0.left.right.equalTo(nameLabel)
            $0.centerY.equalTo(contentView.snp.top).offset(47)
        }

        contentView.addSubview(includeLabel)
        includeLabel.snp.makeConstraints {
            $0.left.right.equalTo(nameLabel)
            $0.centerY.equalTo(contentView.snp.bottom).offset(-21)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
