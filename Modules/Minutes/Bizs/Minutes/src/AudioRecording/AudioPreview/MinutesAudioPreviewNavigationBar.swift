//
//  MinutesAudioPreviewNavigationBar.swift
//  Minutes
//
//  Created by panzaofeng on 2021/3/29.
//

import UIKit
import UniverseDesignColor
import UniverseDesignIcon

class MinutesAudioPreviewNavigationBar: UIView {
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBase
        addSubview(backButton)
        addSubview(titleLabel)

        backButton.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(10)
            maker.left.equalToSuperview().offset(20)
            maker.bottom.equalToSuperview().offset(-25)
            maker.size.equalTo(24)
        }
        titleLabel.snp.makeConstraints { (maker) in
            maker.left.greaterThanOrEqualTo(backButton.snp.right).offset(20)
            maker.centerX.equalToSuperview()
            maker.centerY.equalTo(backButton)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
