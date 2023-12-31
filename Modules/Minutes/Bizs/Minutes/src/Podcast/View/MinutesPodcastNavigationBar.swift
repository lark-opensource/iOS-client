//
//  MinutesPodcastNavigationBar.swift
//  Minutes
//
//  Created by yangyao on 2021/4/3.
//

import UIKit
import UniverseDesignIcon

class MinutesPodcastNavigationBar: UIView {
    lazy var backButton: UIButton = {
        let button: UIButton = UIButton(type: .custom, padding: 20)
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill), for: .normal)
        return button
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        return label
    }()

    private lazy var speedLabel: UILabel = {
        let speedLabel = UILabel()
        speedLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        speedLabel.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
        speedLabel.text = "1.0x"
        speedLabel.layer.ud.setBackgroundColor(UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.2))
        speedLabel.layer.cornerRadius = 6
        speedLabel.textAlignment = .center
        return speedLabel
    }()

    lazy var speedButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(BundleResources.Minutes.minutes_dark_adjust, for: .normal)
        btn.addSubview(speedLabel)
        speedLabel.snp.makeConstraints { make in
            make.width.equalTo(29)
            make.height.equalTo(12)
            make.top.equalTo(6)
            make.right.equalTo(3)
        }
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(backButton)
        addSubview(titleLabel)
        addSubview(speedButton)

        backButton.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(10)
            maker.left.equalToSuperview().offset(20)
            maker.bottom.equalToSuperview().offset(-10)
            maker.size.equalTo(24)
        }
        titleLabel.snp.makeConstraints { (maker) in
            maker.left.greaterThanOrEqualTo(backButton.snp.right).offset(20)
            maker.right.lessThanOrEqualToSuperview().offset(-20)
            maker.centerX.equalToSuperview()
            maker.centerY.equalTo(backButton)
        }

        speedButton.snp.makeConstraints { make in
            make.width.height.equalTo(46)
            make.centerY.equalTo(titleLabel)
            make.right.equalTo(-12)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateSpeedButton(with text: String) {
        speedLabel.text = text
    }
}
