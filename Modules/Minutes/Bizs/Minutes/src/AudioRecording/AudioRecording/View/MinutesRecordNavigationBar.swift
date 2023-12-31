//
//  MinutesRecordNavigationBar.swift
//  Minutes
//
//  Created by yangyao on 2021/3/17.
//

import UIKit
import UniverseDesignIcon

class MinutesRecordNavigationBar: UIView {
    lazy var backButton: UIButton = {
        let button: UIButton = UIButton(type: .custom, padding: 20)
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        return button
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    lazy var titleEditButton: UIButton = {
        let button = UIButton(type: .custom, padding: 20)
        button.setImage(UDIcon.getIconByKey(.editOutlined, iconColor: UIColor.ud.N600), for: .normal)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(backButton)
        addSubview(titleLabel)
        addSubview(timeLabel)
        addSubview(titleEditButton)
        
        createConstraints()
    }
    
    func createConstraints() {
        backButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.left.equalToSuperview().offset(20)
            $0.bottom.equalToSuperview().offset(-25)
            $0.size.equalTo(24)
        }
        titleLabel.snp.makeConstraints {
            $0.left.greaterThanOrEqualTo(backButton.snp.right).offset(20)
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(backButton)
        }
        titleEditButton.snp.makeConstraints {
            $0.left.equalTo(titleLabel.snp.right).offset(6)
            $0.centerY.equalTo(backButton)
            $0.size.equalTo(16)
            $0.right.lessThanOrEqualToSuperview().offset(-20)
        }
        timeLabel.snp.makeConstraints {
            $0.top.equalTo(titleEditButton.snp.bottom).offset(5)
            $0.centerX.equalToSuperview()
            $0.left.greaterThanOrEqualTo(backButton.snp.right).offset(20)
            $0.right.lessThanOrEqualToSuperview().offset(-64)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
