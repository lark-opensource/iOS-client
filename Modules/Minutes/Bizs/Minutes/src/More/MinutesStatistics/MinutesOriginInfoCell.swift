//
//  MinutesOriginInfoCell.swift
//  Minutes
//
//  Created by sihuahao on 2021/7/6.
//

import Foundation
import MinutesFoundation
import MinutesNetwork

// MARK: - MinutesOriginInfoCell - 所有者、创建时间

class MinutesOriginInfoCell: UITableViewCell, MinutesStatisticsCell {
    private lazy var titleLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 1
        label.textAlignment = .left
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return label
    }()

    private lazy var leftImageView: UIImageView = {
        let imageView: UIImageView = UIImageView(frame: CGRect.zero)
        return imageView
    }()

    private lazy var leftClockImageView: UIImageView = {
        let imageView: UIImageView = UIImageView(frame: CGRect.zero)
        return imageView
    }()

    private lazy var rightLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 1
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        return label
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(titleLabel)
        contentView.addSubview(leftImageView)
        contentView.addSubview(leftClockImageView)
        contentView.addSubview(rightLabel)

        titleLabel.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.left.equalToSuperview().offset(16)
            maker.height.equalTo(20)
        }

        leftImageView.layer.cornerRadius = 14
        leftImageView.layer.masksToBounds = true
        leftImageView.snp.makeConstraints { (maker) in
            maker.top.equalTo(titleLabel.snp.bottom).offset(14)
            maker.left.equalToSuperview().offset(16)
            maker.height.width.equalTo(28)
        }

        leftClockImageView.layer.cornerRadius = 14
        leftClockImageView.layer.masksToBounds = true
        leftClockImageView.snp.makeConstraints { (maker) in
            maker.top.equalTo(titleLabel.snp.bottom).offset(14)
            maker.left.equalToSuperview().offset(16)
            maker.height.width.equalTo(28)
        }

        rightLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(leftImageView)
            maker.left.equalTo(leftImageView.snp.right).offset(12)
            maker.right.equalToSuperview()
        }
    }

    func setData(cellInfo: CellInfo) {
        if let item = cellInfo as? OriginCellInfo {
            titleLabel.text = item.titleLabelText
            rightLabel.text = item.rightLabelText

            if item.hasUrl {
                self.leftImageView.setAvatarImage(with: URL(string: item.leftImageName), placeholder: UIImage.dynamicIcon(.adsMobileAvatarCircle, dimension: 48, color: UIColor.ud.N300))
                leftImageView.isHidden = false
                leftClockImageView.isHidden = true
            } else {
                self.leftClockImageView.image = BundleResources.Minutes.minutes_more_details_clock
                leftImageView.isHidden = true
                leftClockImageView.isHidden = false
            }
        } else {
            MinutesLogger.detail.error("error get OriginCellInfo", additionalData: ["cellIdentifier": cellInfo.withIdentifier])
        }
    }
}
