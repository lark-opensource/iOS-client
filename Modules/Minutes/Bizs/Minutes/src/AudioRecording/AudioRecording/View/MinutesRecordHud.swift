//
//  MinutesRecordHUD.swift
//  Minutes
//
//  Created by yangyao on 2021/3/30.
//

import UIKit
import UniverseDesignIcon

class MinutesRecordHUD: UIView {
    enum HUDType: Int {
        case tips = 10003
        case interrupt
        case network
    }

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.infoColorful
        return imageView
    }()

    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textColor = UIColor.ud.N900
        label.textAlignment = .left
        return label
    }()

    lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom, padding: 20)
        let image = UDIcon.getIconByKey(.closeOutlined, iconColor: UIColor.ud.iconN1)
        button.setImage(image, for: .normal)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.B100
        addSubview(imageView)
        addSubview(textLabel)
        addSubview(closeButton)

        imageView.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(16)
            maker.centerY.equalToSuperview()
            maker.size.equalTo(16)
        }
        textLabel.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(12)
            maker.bottom.equalToSuperview().offset(-12)
            maker.left.equalTo(imageView.snp.right).offset(8)
            maker.right.equalTo(closeButton.snp.left).offset(-8)
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview()
        }
        closeButton.snp.makeConstraints { (maker) in
            maker.size.equalTo(16)
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
