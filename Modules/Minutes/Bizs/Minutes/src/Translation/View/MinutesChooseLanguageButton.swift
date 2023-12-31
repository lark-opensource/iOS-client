//
//  MinutesChooseLanguageButton.swift
//  Minutes
//
//  Created by yangyao on 2021/3/15.
//

import UIKit
import UniverseDesignIcon

class MinutesChooseLanguageButton: UIButton {
    lazy var leftImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = BundleResources.Minutes.minutes_speak_language
        return imageView
    }()

    lazy var middleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    lazy var rightImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKey(.expandDownFilled, iconColor: UIColor.ud.textTitle, size: CGSize(width: 24, height: 24))
        return imageView
    }()

    override var isHighlighted: Bool {
        didSet {
            let color = isHighlighted ? UIColor.ud.N400 : UIColor.ud.textTitle
            middleLabel.textColor = color
            leftImageView.image = BundleResources.Minutes.minutes_speak_language
            rightImageView.image = UDIcon.getIconByKey(.expandDownFilled, iconColor: color, size: CGSize(width: 24, height: 24))
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(leftImageView)
        addSubview(middleLabel)
        addSubview(rightImageView)

        leftImageView.snp.makeConstraints { (maker) in
            maker.left.top.bottom.equalToSuperview()
            maker.size.equalTo(14)
        }
        middleLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalTo(leftImageView.snp.right).offset(4)
        }
        rightImageView.snp.makeConstraints { (maker) in
            maker.left.equalTo(middleLabel.snp.right).offset(4)
            maker.right.equalToSuperview()
            maker.size.equalTo(12)
            maker.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
