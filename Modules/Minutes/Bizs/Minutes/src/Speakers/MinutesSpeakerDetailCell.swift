//
//  MinutesSpeakerDetailCell.swift
//  Minutes
//
//  Created by ByteDance on 2023/9/6.
//

import UIKit
import UniverseDesignIcon
import UniverseDesignColor

class MinutesSpeakerNavigationView: UIView {
    lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.closeSmallOutlined, size: CGSize(width: 28, height: 28)), for: .normal)
        return button
    }()

    lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.textColor = UIColor.ud.textTitle
        textLabel.font = .systemFont(ofSize: 17, weight: .medium)
        textLabel.text = BundleI18n.Minutes.MMWeb_M_SpeakerSection_Title
        return textLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgBody
        addSubview(closeButton)
        addSubview(textLabel)

        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(28)
            make.left.equalToSuperview().offset(14)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
        }
        textLabel.snp.makeConstraints { make in
            make.left.greaterThanOrEqualTo(closeButton.snp.right).offset(8)
            make.centerX.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().offset(-8)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MinutesSpeakerDetailHeaderView: UIView {
    lazy var iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.layer.cornerRadius = 16
        iconView.layer.masksToBounds = true

        iconView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(tappedAvatar(_:)))
        tap.numberOfTapsRequired = 1
        iconView.addGestureRecognizer(tap)
        return iconView
    }()

    var openProfileBlock: (() -> Void)?

    @objc func tappedAvatar(_ sender: UITapGestureRecognizer) {
        openProfileBlock?()
    }

    lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.numberOfLines = 0
        textLabel.textColor = UIColor.ud.textPlaceholder
        textLabel.font = .systemFont(ofSize: 16, weight: .medium)
        return textLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(iconView)
        addSubview(textLabel)

        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(10)
        }
        textLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(8)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class MinutesSpeakerDetailCell: UITableViewCell {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    var fragmentInfo: SpeakerFragment? {
        didSet {
            guard let info = fragmentInfo else { return }
            titleLabel.text = info.name
            detailLabel.text = info.time

            titleLabel.textColor = info.isSelected ? UIColor.ud.functionInfoContentDefault : UIColor.ud.textTitle
            detailLabel.textColor = info.isSelected ? UIColor.ud.functionInfoContentDefault : UIColor.ud.textPlaceholder
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor.ud.bgBody
        selectionStyle = .none

        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)

        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
        detailLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(10)
            make.centerY.equalTo(titleLabel)
            make.right.equalToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

